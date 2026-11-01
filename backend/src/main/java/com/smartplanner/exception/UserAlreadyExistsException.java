package com.smartplanner.exception;

/**
 * Exception thrown when a user registration attempt fails due to an already registered email address.
 * Mapped to HTTP 409 Conflict in GlobalExceptionHandler.
 */
public class UserAlreadyExistsException extends RuntimeException {

    public UserAlreadyExistsException(String message) {
        super(message);
    }
}

