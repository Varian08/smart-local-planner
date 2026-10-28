package com.smartplanner.exception;

import com.smartplanner.dto.response.ApiErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Centralized REST API Exception Handler.
 * Intercepts framework and application exceptions, transforming them into standardized
 * RFC 7807 problem details responses defined in docs/DEVELOPMENT_GUIDELINES.md §2.2.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Handle Jakarta Bean Validation errors on Request DTOs (@Valid).
     * Returns 400 BAD REQUEST with specific field-level validation errors.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiErrorResponse> handleValidationException(
            MethodArgumentNotValidException ex,
            HttpServletRequest request
    ) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.put(error.getField(), error.getDefaultMessage());
        }

        String traceId = generateTraceId();
        log.warn("Validation failure [traceId={}] on path {}: {}", traceId, request.getRequestURI(), fieldErrors);

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .code("VALIDATION_FAILED")
                .message("Invalid request payload or query parameters.")
                .fieldErrors(fieldErrors)
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle explicit Spring ResponseStatusException (e.g. 404 Not Found).
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiErrorResponse> handleResponseStatusException(
            ResponseStatusException ex,
            HttpServletRequest request
    ) {
        HttpStatus status = HttpStatus.resolve(ex.getStatusCode().value());
        String code = status != null ? status.name() : "ERROR";
        String message = ex.getReason() != null ? ex.getReason() : ex.getMessage();
        String traceId = generateTraceId();

        log.info("ResponseStatusException [traceId={}] status {} on path {}: {}",
                traceId, ex.getStatusCode(), request.getRequestURI(), message);

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(ex.getStatusCode().value())
                .code(code)
                .message(message)
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(ex.getStatusCode()).body(errorResponse);
    }

    /**
     * Handle unmapped routes or missing static resources (Spring 6 / Boot 3.2+).
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNoResourceFoundException(
            NoResourceFoundException ex,
            HttpServletRequest request
    ) {
        String traceId = generateTraceId();
        log.info("NoResourceFoundException [traceId={}] on path {}", traceId, request.getRequestURI());

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.NOT_FOUND.value())
                .code("NOT_FOUND")
                .message("The requested endpoint was not found: " + request.getRequestURI())
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    /**
     * Handle illegal argument or business precondition failures.
     */
    @ExceptionHandler({IllegalArgumentException.class, IllegalStateException.class})
    public ResponseEntity<ApiErrorResponse> handleIllegalArgumentException(
            RuntimeException ex,
            HttpServletRequest request
    ) {
        String traceId = generateTraceId();
        log.warn("Illegal argument [traceId={}] on path {}: {}", traceId, request.getRequestURI(), ex.getMessage());

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .code("BAD_REQUEST")
                .message(ex.getMessage())
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle method argument type mismatch (e.g. invalid UUID in path or non-numeric query param).
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiErrorResponse> handleTypeMismatchException(
            MethodArgumentTypeMismatchException ex,
            HttpServletRequest request
    ) {
        String traceId = generateTraceId();
        String requiredType = ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "unknown";
        String message = String.format("Failed to convert parameter '%s' with value '%s' to required type '%s'.",
                ex.getName(), ex.getValue(), requiredType);
        log.warn("Method argument type mismatch [traceId={}] on path {}: {}", traceId, request.getRequestURI(), message);

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .code("INVALID_ARGUMENT")
                .message(message)
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle missing required query parameters (e.g. missing @RequestParam).
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiErrorResponse> handleMissingParameterException(
            MissingServletRequestParameterException ex,
            HttpServletRequest request
    ) {
        String traceId = generateTraceId();
        String message = String.format("Required request parameter '%s' of type '%s' is not present.",
                ex.getParameterName(), ex.getParameterType());
        log.warn("Missing request parameter [traceId={}] on path {}: {}", traceId, request.getRequestURI(), message);

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .code("MISSING_PARAMETER")
                .message(message)
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle unsupported HTTP methods (e.g. POST on GET-only endpoint).
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiErrorResponse> handleMethodNotSupportedException(
            HttpRequestMethodNotSupportedException ex,
            HttpServletRequest request
    ) {
        String traceId = generateTraceId();
        String message = String.format("HTTP method '%s' is not supported for this endpoint.", ex.getMethod());
        log.warn("HTTP method not supported [traceId={}] on path {}: {}", traceId, request.getRequestURI(), message);

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.METHOD_NOT_ALLOWED.value())
                .code("METHOD_NOT_ALLOWED")
                .message(message)
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(errorResponse);
    }

    /**
     * Handle malformed or unreadable HTTP request bodies (e.g. invalid JSON payload).
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiErrorResponse> handleHttpMessageNotReadableException(
            HttpMessageNotReadableException ex,
            HttpServletRequest request
    ) {
        String traceId = generateTraceId();
        String message = "Malformed JSON request body or unparseable input payload.";
        log.warn("Malformed HTTP message body [traceId={}] on path {}: {}", traceId, request.getRequestURI(), ex.getMessage());

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .code("MALFORMED_JSON")
                .message(message)
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Catch-all fallback for uncaught system exceptions.
     * Prevents internal infrastructure details and stack traces from leaking to clients.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGenericException(
            Exception ex,
            HttpServletRequest request
    ) {
        String traceId = generateTraceId();
        log.error("Unhandled internal server exception [traceId={}] on path {}: ", traceId, request.getRequestURI(), ex);

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                .code("INTERNAL_SERVER_ERROR")
                .message("An unexpected internal server error occurred. Please contact support with traceId: " + traceId)
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }

    private String generateTraceId() {
        return "req-" + UUID.randomUUID().toString().substring(0, 12);
    }
}
