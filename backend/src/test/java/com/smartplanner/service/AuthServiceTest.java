package com.smartplanner.service;

import com.smartplanner.dto.request.LoginRequest;
import com.smartplanner.dto.request.RefreshTokenRequest;
import com.smartplanner.dto.request.RegisterRequest;
import com.smartplanner.dto.response.AuthResponse;
import com.smartplanner.entity.RefreshToken;
import com.smartplanner.entity.User;
import com.smartplanner.exception.InvalidTokenException;
import com.smartplanner.exception.UserAlreadyExistsException;
import com.smartplanner.repository.RefreshTokenRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.impl.AuthServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthService Unit Tests")
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @InjectMocks
    private AuthServiceImpl authService;

    private User mockUser;
    private UUID userId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        mockUser = User.builder()
                .id(userId)
                .email("traveler@example.com")
                .passwordHash("hashedPassword123")
                .fullName("Nguyen Van A")
                .role("ROLE_USER")
                .build();
    }

    @Test
    @DisplayName("register() with new email encodes password, persists User, and returns AuthResponse")
    void register_withNewEmail_savesUserAndIssuesTokens() {
        RegisterRequest request = RegisterRequest.builder()
                .email("traveler@example.com")
                .password("RawPassword123!")
                .fullName("Nguyen Van A")
                .build();

        when(userRepository.existsByEmail("traveler@example.com")).thenReturn(false);
        when(passwordEncoder.encode("RawPassword123!")).thenReturn("hashedPassword123");
        when(userRepository.save(any(User.class))).thenReturn(mockUser);
        when(jwtService.generateAccessToken(any(User.class))).thenReturn("access.jwt.token");
        when(jwtService.generateRefreshToken()).thenReturn("random-refresh-token");
        when(jwtService.getAccessTokenExpirationInSeconds()).thenReturn(1800L);
        when(jwtService.getRefreshTokenExpirationInSeconds()).thenReturn(604800L);

        AuthResponse response = authService.register(request);

        assertThat(response).isNotNull();
        assertThat(response.getAccessToken()).isEqualTo("access.jwt.token");
        assertThat(response.getRefreshToken()).isEqualTo("random-refresh-token");
        assertThat(response.getUser().getEmail()).isEqualTo("traveler@example.com");

        verify(userRepository, times(1)).save(any(User.class));
        verify(refreshTokenRepository, times(1)).save(any(RefreshToken.class));
    }

    @Test
    @DisplayName("register() with already registered email throws UserAlreadyExistsException")
    void register_withExistingEmail_throwsUserAlreadyExistsException() {
        RegisterRequest request = RegisterRequest.builder()
                .email("existing@example.com")
                .password("Password123!")
                .fullName("Existing User")
                .build();

        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(UserAlreadyExistsException.class)
                .hasMessageContaining("Email address is already in use: existing@example.com");

        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    @DisplayName("login() with correct credentials returns AuthResponse with token pair")
    void login_withCorrectCredentials_returnsAuthResponse() {
        LoginRequest request = LoginRequest.builder()
                .email("traveler@example.com")
                .password("RawPassword123!")
                .build();

        when(userRepository.findByEmail("traveler@example.com")).thenReturn(Optional.of(mockUser));
        when(passwordEncoder.matches("RawPassword123!", "hashedPassword123")).thenReturn(true);
        when(jwtService.generateAccessToken(mockUser)).thenReturn("access.jwt.token");
        when(jwtService.generateRefreshToken()).thenReturn("random-refresh-token");
        when(jwtService.getAccessTokenExpirationInSeconds()).thenReturn(1800L);
        when(jwtService.getRefreshTokenExpirationInSeconds()).thenReturn(604800L);

        AuthResponse response = authService.login(request);

        assertThat(response).isNotNull();
        assertThat(response.getAccessToken()).isEqualTo("access.jwt.token");
        assertThat(response.getRefreshToken()).isEqualTo("random-refresh-token");

        verify(refreshTokenRepository, times(1)).save(any(RefreshToken.class));
    }

    @Test
    @DisplayName("login() with unknown email throws BadCredentialsException")
    void login_withUnknownEmail_throwsBadCredentialsException() {
        LoginRequest request = LoginRequest.builder()
                .email("unknown@example.com")
                .password("Password123!")
                .build();

        when(userRepository.findByEmail("unknown@example.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(BadCredentialsException.class)
                .hasMessageContaining("Invalid email or password.");
    }

    @Test
    @DisplayName("login() with incorrect password throws BadCredentialsException")
    void login_withIncorrectPassword_throwsBadCredentialsException() {
        LoginRequest request = LoginRequest.builder()
                .email("traveler@example.com")
                .password("WrongPassword!")
                .build();

        when(userRepository.findByEmail("traveler@example.com")).thenReturn(Optional.of(mockUser));
        when(passwordEncoder.matches("WrongPassword!", "hashedPassword123")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(BadCredentialsException.class)
                .hasMessageContaining("Invalid email or password.");
    }

    @Test
    @DisplayName("refreshToken() with valid active token revokes old token and issues fresh pair")
    void refreshToken_withActiveToken_revokesOldAndReturnsNewPair() {
        RefreshTokenRequest request = RefreshTokenRequest.builder()
                .refreshToken("old-token")
                .build();

        RefreshToken existingToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .user(mockUser)
                .token("old-token")
                .expiresAt(OffsetDateTime.now().plusDays(5))
                .revoked(false)
                .build();

        when(refreshTokenRepository.findByToken("old-token")).thenReturn(Optional.of(existingToken));
        when(jwtService.generateAccessToken(mockUser)).thenReturn("new.access.token");
        when(jwtService.generateRefreshToken()).thenReturn("new-refresh-token");
        when(jwtService.getAccessTokenExpirationInSeconds()).thenReturn(1800L);
        when(jwtService.getRefreshTokenExpirationInSeconds()).thenReturn(604800L);

        AuthResponse response = authService.refreshToken(request);

        assertThat(response).isNotNull();
        assertThat(response.getAccessToken()).isEqualTo("new.access.token");
        assertThat(response.getRefreshToken()).isEqualTo("new-refresh-token");
        assertThat(existingToken.isRevoked()).isTrue();

        // 1st save is revoking old token, 2nd save is persisting new token
        verify(refreshTokenRepository, times(2)).save(any(RefreshToken.class));
    }

    @Test
    @DisplayName("refreshToken() with non-existent token throws InvalidTokenException")
    void refreshToken_withNonExistentToken_throwsInvalidTokenException() {
        RefreshTokenRequest request = RefreshTokenRequest.builder()
                .refreshToken("non-existent")
                .build();

        when(refreshTokenRepository.findByToken("non-existent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.refreshToken(request))
                .isInstanceOf(InvalidTokenException.class)
                .hasMessageContaining("Invalid or expired refresh token.");
    }

    @Test
    @DisplayName("refreshToken() with revoked token throws InvalidTokenException")
    void refreshToken_withRevokedToken_throwsInvalidTokenException() {
        RefreshTokenRequest request = RefreshTokenRequest.builder()
                .refreshToken("revoked-token")
                .build();

        RefreshToken revokedToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .user(mockUser)
                .token("revoked-token")
                .expiresAt(OffsetDateTime.now().plusDays(5))
                .revoked(true)
                .build();

        when(refreshTokenRepository.findByToken("revoked-token")).thenReturn(Optional.of(revokedToken));

        assertThatThrownBy(() -> authService.refreshToken(request))
                .isInstanceOf(InvalidTokenException.class)
                .hasMessageContaining("Invalid or expired refresh token.");
    }

    @Test
    @DisplayName("logout() revokes matching refresh token in database")
    void logout_withExistingToken_revokesToken() {
        RefreshToken existingToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .user(mockUser)
                .token("token-to-revoke")
                .expiresAt(OffsetDateTime.now().plusDays(2))
                .revoked(false)
                .build();

        when(refreshTokenRepository.findByToken("token-to-revoke")).thenReturn(Optional.of(existingToken));

        authService.logout("token-to-revoke");

        assertThat(existingToken.isRevoked()).isTrue();
        verify(refreshTokenRepository, times(1)).save(existingToken);
    }
}

