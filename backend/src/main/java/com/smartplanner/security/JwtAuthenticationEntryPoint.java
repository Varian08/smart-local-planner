package com.smartplanner.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartplanner.dto.response.ApiErrorResponse;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Custom AuthenticationEntryPoint returning structured RFC 7807 problem details (ApiErrorResponse)
 * on unauthorized HTTP 401 challenges, aligned with docs/API_SPECIFICATION.md §6.2.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper;

    @Override
    public void commence(
            HttpServletRequest request,
            HttpServletResponse response,
            AuthenticationException authException
    ) throws IOException, ServletException {
        String traceId = "req-" + UUID.randomUUID().toString().substring(0, 12);
        log.warn("Unauthorized access [traceId={}] on path {}: {}", traceId, request.getRequestURI(), authException.getMessage());

        ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                .timestamp(OffsetDateTime.now())
                .status(HttpStatus.UNAUTHORIZED.value())
                .code("UNAUTHORIZED")
                .message("Full authentication is required to access this resource.")
                .path(request.getRequestURI())
                .traceId(traceId)
                .build();

        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
    }
}
