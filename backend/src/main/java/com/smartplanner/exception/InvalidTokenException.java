package com.smartplanner.exception;

/**
 * Exception thrown when a refresh token or JWT is invalid, expired, or revoked.
 * Mapped to HTTP 401 Unauthorized in GlobalExceptionHandler.
 */
public class InvalidTokenException extends RuntimeException {

    public InvalidTokenException(String message) {
        super(message);
    }
}

