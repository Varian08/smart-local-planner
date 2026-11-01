package com.smartplanner.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartplanner.dto.response.ApiErrorResponse;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.OffsetDateTime;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory sliding-window rate limiting filter restricting login attempts to 5 requests per minute per IP address.
 * Aligned with docs/API_SPECIFICATION.md §1.2 & §6.4.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LoginRateLimitingFilter extends OncePerRequestFilter {

    private static final int MAX_REQUESTS_PER_MINUTE = 5;
    private static final long WINDOW_MS = 60_000L; // 1 minute

    private final ObjectMapper objectMapper;
    private final Map<String, Deque<Long>> requestLogMap = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        String path = request.getRequestURI();
        String method = request.getMethod();

        // Rate limit only POST /api/v1/auth/login
        if ("POST".equalsIgnoreCase(method) && path.endsWith("/api/v1/auth/login")) {
            String clientIp = resolveClientIp(request);
            long currentTime = System.currentTimeMillis();

            Deque<Long> timestamps = requestLogMap.computeIfAbsent(clientIp, k -> new ArrayDeque<>());
            boolean rateExceeded;

            synchronized (timestamps) {
                // Evict timestamps older than 60 seconds
                while (!timestamps.isEmpty() && currentTime - timestamps.peekFirst() > WINDOW_MS) {
                    timestamps.pollFirst();
                }

                if (timestamps.size() >= MAX_REQUESTS_PER_MINUTE) {
                    rateExceeded = true;
                } else {
                    timestamps.addLast(currentTime);
                    rateExceeded = false;
                }
            }

            if (rateExceeded) {
                String traceId = "req-" + UUID.randomUUID().toString().substring(0, 12);
                log.warn("Rate limit exceeded for IP {} on path {} [traceId={}]", clientIp, path, traceId);

                ApiErrorResponse errorResponse = ApiErrorResponse.builder()
                        .timestamp(OffsetDateTime.now())
                        .status(HttpStatus.TOO_MANY_REQUESTS.value())
                        .code("RATE_LIMIT_EXCEEDED")
                        .message("Too many requests. Please wait a moment before trying again.")
                        .path(path)
                        .traceId(traceId)
                        .build();

                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr() != null ? request.getRemoteAddr() : "unknown";
    }
}
