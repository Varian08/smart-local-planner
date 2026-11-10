package com.smartplanner.exception;

/**
 * Domain exception thrown when an entity creation or mutation conflicts with existing data
 * (e.g. unique constraint or duplicate bookmark/review).
 * Mapped to HTTP 409 CONFLICT with code 'DATA_CONFLICT'.
 */
public class DuplicateResourceException extends RuntimeException {

    public DuplicateResourceException(String message) {
        super(message);
    }
}
