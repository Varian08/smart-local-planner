package com.smartplanner.exception;

/**
 * Domain exception thrown when an authenticated user attempts to access or modify
 * a resource they do not own or lack permission for.
 * Mapped to HTTP 403 FORBIDDEN with code 'FORBIDDEN_ACCESS' per API Specification §6.3.
 */
public class ForbiddenException extends RuntimeException {

    public ForbiddenException(String message) {
        super(message);
    }
}
