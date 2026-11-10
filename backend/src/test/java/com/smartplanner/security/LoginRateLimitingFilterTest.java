package com.smartplanner.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@DisplayName("LoginRateLimitingFilter Unit Tests")
class LoginRateLimitingFilterTest {

    private LoginRateLimitingFilter filter;
    private FilterChain filterChain;

    @BeforeEach
    void setUp() {
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());
        filter = new LoginRateLimitingFilter(objectMapper);
        filterChain = mock(FilterChain.class);
    }

    @Test
    @DisplayName("Allows first 5 POST /api/v1/auth/login requests and blocks the 6th with HTTP 429")
    void loginEndpoint_blocksSixthRequestWithinMinute() throws Exception {
        for (int i = 0; i < 5; i++) {
            MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/v1/auth/login");
            req.addHeader("X-Forwarded-For", "10.0.0.1");
            MockHttpServletResponse res = new MockHttpServletResponse();

            filter.doFilter(req, res, filterChain);
            assertThat(res.getStatus()).isEqualTo(200);
        }

        MockHttpServletRequest sixthReq = new MockHttpServletRequest("POST", "/api/v1/auth/login");
        sixthReq.addHeader("X-Forwarded-For", "10.0.0.1");
        MockHttpServletResponse sixthRes = new MockHttpServletResponse();

        filter.doFilter(sixthReq, sixthRes, filterChain);

        assertThat(sixthRes.getStatus()).isEqualTo(429);
        assertThat(sixthRes.getContentAsString()).contains("RATE_LIMIT_EXCEEDED");
        verify(filterChain, times(5)).doFilter(
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any()
        );
    }

    @Test
    @DisplayName("Allows first 5 POST /api/v1/auth/register requests and blocks the 6th with HTTP 429")
    void registerEndpoint_blocksSixthRequestWithinMinute() throws Exception {
        for (int i = 0; i < 5; i++) {
            MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/v1/auth/register");
            req.addHeader("X-Forwarded-For", "10.0.0.2");
            MockHttpServletResponse res = new MockHttpServletResponse();

            filter.doFilter(req, res, filterChain);
            assertThat(res.getStatus()).isEqualTo(200);
        }

        MockHttpServletRequest sixthReq = new MockHttpServletRequest("POST", "/api/v1/auth/register");
        sixthReq.addHeader("X-Forwarded-For", "10.0.0.2");
        MockHttpServletResponse sixthRes = new MockHttpServletResponse();

        filter.doFilter(sixthReq, sixthRes, filterChain);

        assertThat(sixthRes.getStatus()).isEqualTo(429);
        assertThat(sixthRes.getContentAsString()).contains("RATE_LIMIT_EXCEEDED");
    }

    @Test
    @DisplayName("Isolates rate limit buckets between /login and /register for the same IP")
    void loginAndRegister_haveIsolatedRateLimitBucketsPerIp() throws Exception {
        String clientIp = "10.0.0.3";

        // Exhaust all 5 register requests
        for (int i = 0; i < 5; i++) {
            MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/v1/auth/register");
            req.addHeader("X-Forwarded-For", clientIp);
            MockHttpServletResponse res = new MockHttpServletResponse();
            filter.doFilter(req, res, filterChain);
            assertThat(res.getStatus()).isEqualTo(200);
        }

        // Subsequent login request from the same IP should still be allowed
        MockHttpServletRequest loginReq = new MockHttpServletRequest("POST", "/api/v1/auth/login");
        loginReq.addHeader("X-Forwarded-For", clientIp);
        MockHttpServletResponse loginRes = new MockHttpServletResponse();

        filter.doFilter(loginReq, loginRes, filterChain);
        assertThat(loginRes.getStatus()).isEqualTo(200);
    }
}

