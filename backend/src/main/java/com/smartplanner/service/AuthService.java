package com.smartplanner.service;

import com.smartplanner.dto.request.LoginRequest;
import com.smartplanner.dto.request.RefreshTokenRequest;
import com.smartplanner.dto.request.RegisterRequest;
import com.smartplanner.dto.response.AuthResponse;

/**
 * Service contract for Authentication business operations.
 * Defines account registration, credential login, token rotation, and logout.
 */
public interface AuthService {

    /**
     * Register a new user account with hashed password and return initial token pair.
     */
    AuthResponse register(RegisterRequest request);

    /**
     * Authenticate user credentials and return new token pair.
     */
    AuthResponse login(LoginRequest request);

    /**
     * Perform stateless token rotation: validate and revoke existing refresh token,
     * issuing a new access token and fresh refresh token pair.
     */
    AuthResponse refreshToken(RefreshTokenRequest request);

    /**
     * Revoke the user's refresh token session.
     */
    void logout(String refreshToken);
}
