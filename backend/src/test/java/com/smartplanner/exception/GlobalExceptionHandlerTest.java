package com.smartplanner.exception;

import com.smartplanner.dto.response.ApiErrorResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.mock.http.MockHttpInputMessage;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("GlobalExceptionHandler Unit Tests")
class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler exceptionHandler;
    private MockHttpServletRequest request;

    @BeforeEach
    void setUp() {
        exceptionHandler = new GlobalExceptionHandler();
        request = new MockHttpServletRequest();
        request.setRequestURI("/api/v1/places");
    }

    @Test
    @DisplayName("handleValidationException maps FieldErrors to ApiErrorResponse with 400 Bad Request")
    void handleValidationException_returns400WithFieldErrors() throws Exception {
        // Given
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new Object(), "request");
        bindingResult.addError(new FieldError("request", "size", "Page size must not exceed 50"));
        bindingResult.addError(new FieldError("request", "page", "Page index must not be negative"));

        MethodParameter parameter = new MethodParameter(
                this.getClass().getDeclaredMethod("setUp"), -1
        );
        MethodArgumentNotValidException ex = new MethodArgumentNotValidException(parameter, bindingResult);

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleValidationException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getStatus()).isEqualTo(400);
        assertThat(body.getCode()).isEqualTo("VALIDATION_FAILED");
        assertThat(body.getFieldErrors()).containsEntry("size", "Page size must not exceed 50");
        assertThat(body.getFieldErrors()).containsEntry("page", "Page index must not be negative");
        assertThat(body.getPath()).isEqualTo("/api/v1/places");
        assertThat(body.getTraceId()).startsWith("req-");
        assertThat(body.getTimestamp()).isNotNull();
    }

    @Test
    @DisplayName("handleResponseStatusException maps HttpStatus and reason to ApiErrorResponse")
    void handleResponseStatusException_returnsMatchingStatusAndMessage() {
        // Given
        ResponseStatusException ex = new ResponseStatusException(HttpStatus.NOT_FOUND, "Place not found");

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleResponseStatusException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getStatus()).isEqualTo(404);
        assertThat(body.getCode()).isEqualTo("NOT_FOUND");
        assertThat(body.getMessage()).isEqualTo("Place not found");
        assertThat(body.getTraceId()).isNotBlank();
    }

    @Test
    @DisplayName("handleNoResourceFoundException maps to 404 NOT_FOUND")
    void handleNoResourceFoundException_returns404() {
        // Given
        NoResourceFoundException ex = new NoResourceFoundException(org.springframework.http.HttpMethod.GET, "/api/v1/invalid");

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleNoResourceFoundException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getCode()).isEqualTo("NOT_FOUND");
    }

    @Test
    @DisplayName("handleIllegalArgumentException maps to 400 BAD_REQUEST")
    void handleIllegalArgumentException_returns400() {
        // Given
        IllegalArgumentException ex = new IllegalArgumentException("Invalid argument provided");

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleIllegalArgumentException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getCode()).isEqualTo("BAD_REQUEST");
        assertThat(body.getMessage()).isEqualTo("Invalid argument provided");
    }

    @Test
    @DisplayName("handleTypeMismatchException maps to 400 BAD_REQUEST with INVALID_ARGUMENT")
    void handleTypeMismatchException_returns400WithInvalidArgument() {
        // Given
        MethodArgumentTypeMismatchException ex = new MethodArgumentTypeMismatchException(
                "abc-xyz", UUID.class, "id", null, null
        );

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleTypeMismatchException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getStatus()).isEqualTo(400);
        assertThat(body.getCode()).isEqualTo("INVALID_ARGUMENT");
        assertThat(body.getMessage()).contains("Failed to convert parameter 'id'");
    }

    @Test
    @DisplayName("handleMissingParameterException maps to 400 BAD_REQUEST with MISSING_PARAMETER")
    void handleMissingParameterException_returns400WithMissingParameter() {
        // Given
        MissingServletRequestParameterException ex = new MissingServletRequestParameterException("category", "String");

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleMissingParameterException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getStatus()).isEqualTo(400);
        assertThat(body.getCode()).isEqualTo("MISSING_PARAMETER");
        assertThat(body.getMessage()).contains("Required request parameter 'category'");
    }

    @Test
    @DisplayName("handleMethodNotSupportedException maps to 405 METHOD_NOT_ALLOWED")
    void handleMethodNotSupportedException_returns405() {
        // Given
        HttpRequestMethodNotSupportedException ex = new HttpRequestMethodNotSupportedException("POST");

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleMethodNotSupportedException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.METHOD_NOT_ALLOWED);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getStatus()).isEqualTo(405);
        assertThat(body.getCode()).isEqualTo("METHOD_NOT_ALLOWED");
        assertThat(body.getMessage()).contains("HTTP method 'POST' is not supported");
    }

    @Test
    @DisplayName("handleHttpMessageNotReadableException maps to 400 BAD_REQUEST with MALFORMED_JSON")
    void handleHttpMessageNotReadableException_returns400() {
        // Given
        HttpMessageNotReadableException ex = new HttpMessageNotReadableException("Malformed JSON input", new MockHttpInputMessage(new byte[0]));

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleHttpMessageNotReadableException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getStatus()).isEqualTo(400);
        assertThat(body.getCode()).isEqualTo("MALFORMED_JSON");
        assertThat(body.getMessage()).contains("Malformed JSON request body");
    }

    @Test
    @DisplayName("handleGenericException catches unhandled errors and returns sanitized 500 INTERNAL_SERVER_ERROR")
    void handleGenericException_returnsSanitized500() {
        // Given
        RuntimeException ex = new RuntimeException("Sensitive database stacktrace");

        // When
        ResponseEntity<ApiErrorResponse> response = exceptionHandler.handleGenericException(ex, request);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        ApiErrorResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getStatus()).isEqualTo(500);
        assertThat(body.getCode()).isEqualTo("INTERNAL_SERVER_ERROR");
        assertThat(body.getMessage()).doesNotContain("Sensitive database stacktrace");
        assertThat(body.getMessage()).contains("traceId");
    }
}
