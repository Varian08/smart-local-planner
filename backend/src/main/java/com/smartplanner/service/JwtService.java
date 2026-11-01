package com.smartplanner.service;

import com.smartplanner.entity.User;
import io.jsonwebtoken.Claims;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Date;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

/**
 * Service contract for JWT token operations including signing, claims extraction,
 * and cryptographic validation.
 */
public interface JwtService {

    /**
     * Generate a signed HMAC-SHA256 JWT access token for the given User.
     */
    String generateAccessToken(User user);

    /**
     * Generate a signed JWT access token with custom extra claims.
     */
    String generateAccessToken(Map<String, Object> extraClaims, User user);

    /**
     * Generate a cryptographically secure, random refresh token string.
     */
    String generateRefreshToken();

    /**
     * Extract the username (subject / email) from the token.
     */
    String extractUsername(String token);

    /**
     * Extract user email from token subject.
     */
    String extractEmail(String token);

    /**
     * Extract user UUID from custom claims.
     */
    UUID extractUserId(String token);

    /**
     * Extract token expiration timestamp.
     */
    Date extractExpiration(String token);

    /**
     * Extract a specific claim using a custom resolver function.
     */
    <T> T extractClaim(String token, Function<Claims, T> claimsResolver);

    /**
     * Validate whether the token matches the user and has not expired.
     */
    boolean isTokenValid(String token, UserDetails userDetails);

    /**
     * Check whether the token has passed its expiration time.
     */
    boolean isTokenExpired(String token);

    /**
     * Return access token lifetime in seconds (e.g. 1800 for 30 minutes).
     */
    long getAccessTokenExpirationInSeconds();

    /**
     * Return refresh token lifetime in seconds (e.g. 604800 for 7 days).
     */
    long getRefreshTokenExpirationInSeconds();
}

