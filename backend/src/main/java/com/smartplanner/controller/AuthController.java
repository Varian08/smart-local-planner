package com.smartplanner.controller;

import com.smartplanner.dto.request.LoginRequest;
import com.smartplanner.dto.request.RefreshTokenRequest;
import com.smartplanner.dto.request.RegisterRequest;
import com.smartplanner.dto.response.AuthResponse;
import com.smartplanner.dto.response.MessageResponse;
import com.smartplanner.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST Controller exposing User Authentication endpoints.
 * Provides APIs for registration, login, token rotation, and logout.
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "User registration, login, and session token rotation")
public class AuthController {

    private final AuthService authService;

    /**
     * Register a new traveler account.
     * POST /api/v1/auth/register
     */
    @PostMapping("/register")
    @Operation(summary = "Register a new user account")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Authenticate with email and password.
     * POST /api/v1/auth/login
     */
    @PostMapping("/login")
    @Operation(summary = "Authenticate with credentials and obtain token pair")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Refresh access token via rotating refresh token.
     * POST /api/v1/auth/refresh-token
     */
    @PostMapping("/refresh-token")
    @Operation(summary = "Rotate refresh token and obtain fresh access token")
    public ResponseEntity<AuthResponse> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Logout and revoke refresh token.
     * POST /api/v1/auth/logout
     */
    @PostMapping("/logout")
    @Operation(summary = "Logout user and revoke refresh token session")
    public ResponseEntity<MessageResponse> logout(@RequestBody(required = false) RefreshTokenRequest request) {
        String token = request != null ? request.getRefreshToken() : null;
        authService.logout(token);
        return ResponseEntity.ok(new MessageResponse("User logged out successfully."));
    }
}
