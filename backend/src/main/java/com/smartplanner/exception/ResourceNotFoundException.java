package com.smartplanner.exception;

/**
 * Domain exception thrown when a requested resource is not found.
 * Mapped to HTTP 404 NOT_FOUND with code 'NOT_FOUND'.
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}
