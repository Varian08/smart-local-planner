package com.smartplanner.exception;

/**
 * Domain exception thrown when an operation requires an authenticated user identity
 * that is absent or invalid.
 * Mapped to HTTP 401 UNAUTHORIZED with code 'UNAUTHORIZED'.
 */
public class UnauthorizedException extends RuntimeException {

    public UnauthorizedException(String message) {
        super(message);
    }
}
