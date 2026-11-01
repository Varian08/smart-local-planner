package com.smartplanner.service.impl;

import com.smartplanner.dto.request.LoginRequest;
import com.smartplanner.dto.request.RefreshTokenRequest;
import com.smartplanner.dto.request.RegisterRequest;
import com.smartplanner.dto.response.AuthResponse;
import com.smartplanner.dto.response.UserResponse;
import com.smartplanner.entity.RefreshToken;
import com.smartplanner.entity.User;
import com.smartplanner.exception.InvalidTokenException;
import com.smartplanner.exception.UserAlreadyExistsException;
import com.smartplanner.repository.RefreshTokenRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.AuthService;
import com.smartplanner.service.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

/**
 * Production-ready implementation of AuthService.
 * Coordinates user management, password hashing, JWT token generation,
 * and persistent refresh token rotation.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();

        // 1. Guard against duplicate email addresses
        if (userRepository.existsByEmail(normalizedEmail)) {
            log.warn("Registration rejected: Email already exists: {}", normalizedEmail);
            throw new UserAlreadyExistsException("Email address is already in use: " + normalizedEmail);
        }

        // 2. Hash password with BCrypt and persist User entity
        User user = User.builder()
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName().trim())
                .role("ROLE_USER")
                .build();
        User savedUser = userRepository.save(user);
        log.info("Registered new user with id: {}", savedUser.getId());

        // 3. Issue initial token pair
        return issueTokenPair(savedUser);
    }

    @Override
    @Transactional
    public AuthResponse login(LoginRequest request) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();

        // 1. Retrieve user and verify credentials with BCrypt
        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> {
                    log.warn("Login failed: User not found for email: {}", normalizedEmail);
                    return new BadCredentialsException("Invalid email or password.");
                });

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            log.warn("Login failed: Password mismatch for email: {}", normalizedEmail);
            throw new BadCredentialsException("Invalid email or password.");
        }

        log.info("User successfully authenticated: {}", user.getId());

        // 2. Issue fresh token pair
        return issueTokenPair(user);
    }

    @Override
    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String rawToken = request.getRefreshToken().trim();

        // 1. Validate refresh token existence and active state
        RefreshToken existingToken = refreshTokenRepository.findByToken(rawToken)
                .orElseThrow(() -> {
                    log.warn("Token refresh rejected: Token not found.");
                    return new InvalidTokenException("Invalid or expired refresh token.");
                });

        if (!existingToken.isActive()) {
            log.warn("Token refresh rejected: Token expired or revoked for user: {}", existingToken.getUser().getId());
            throw new InvalidTokenException("Invalid or expired refresh token.");
        }

        User user = existingToken.getUser();

        // 2. Token Rotation: Revoke previous refresh token immediately
        existingToken.setRevoked(true);
        refreshTokenRepository.save(existingToken);

        // 3. Issue fresh tokens
        String newAccessToken = jwtService.generateAccessToken(user);
        String newRefreshTokenStr = jwtService.generateRefreshToken();

        RefreshToken newRefreshToken = RefreshToken.builder()
                .user(user)
                .token(newRefreshTokenStr)
                .expiresAt(OffsetDateTime.now().plusSeconds(jwtService.getRefreshTokenExpirationInSeconds()))
                .revoked(false)
                .build();
        refreshTokenRepository.save(newRefreshToken);

        log.info("Token rotation successful for user: {}", user.getId());

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshTokenStr)
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessTokenExpirationInSeconds())
                .user(mapToUserResponse(user))
                .build();
    }

    @Override
    @Transactional
    public void logout(String refreshToken) {
        if (refreshToken != null && !refreshToken.isBlank()) {
            refreshTokenRepository.findByToken(refreshToken.trim()).ifPresent(token -> {
                token.setRevoked(true);
                refreshTokenRepository.save(token);
                log.info("Revoked refresh token on logout for user: {}", token.getUser().getId());
            });
        }
    }

    /**
     * Issues and persists a fresh token pair for the user.
     */
    private AuthResponse issueTokenPair(User user) {
        String accessToken = jwtService.generateAccessToken(user);
        String refreshTokenStr = jwtService.generateRefreshToken();

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(refreshTokenStr)
                .expiresAt(OffsetDateTime.now().plusSeconds(jwtService.getRefreshTokenExpirationInSeconds()))
                .revoked(false)
                .build();
        refreshTokenRepository.save(refreshToken);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshTokenStr)
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessTokenExpirationInSeconds())
                .user(mapToUserResponse(user))
                .build();
    }

    private UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build();
    }
}
