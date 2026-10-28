package com.smartplanner.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.Map;

/**
 * Standardized REST API Error Envelope aligned with docs/DEVELOPMENT_GUIDELINES.md §2.2
 * and RFC 7807 Problem Details specification.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiErrorResponse {

    private OffsetDateTime timestamp;
    private int status;
    private String code;
    private String message;
    private Map<String, String> fieldErrors;
    private String path;
    private String traceId;
}
