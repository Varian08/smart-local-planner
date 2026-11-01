package com.smartplanner.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartplanner.dto.request.LoginRequest;
import com.smartplanner.entity.User;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers(disabledWithoutDocker = true)
@DisplayName("Security Access Control and Filter Chain Integration Tests")
class SecurityAccessControlTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JwtService jwtService;

    @MockBean
    private UserRepository userRepository;

    private User testUser;
    private String validJwt;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(UUID.randomUUID())
                .email("secure.traveler@example.com")
                .passwordHash("$2a$10$dummyhash")
                .fullName("Secure Traveler")
                .role("ROLE_USER")
                .build();

        validJwt = jwtService.generateAccessToken(testUser);
        when(userRepository.findByEmail("secure.traveler@example.com")).thenReturn(Optional.of(testUser));
    }

    @Test
    @DisplayName("Public endpoints (Actuator Health, Places) are accessible unauthenticated")
    void publicEndpoints_accessibleWithoutToken() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/places"))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Protected endpoints without token return 401 Unauthorized with standard ApiErrorResponse")
    void protectedEndpoints_withoutToken_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/favorites"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"))
                .andExpect(jsonPath("$.message").value("Full authentication is required to access this resource."))
                .andExpect(jsonPath("$.traceId").exists())
                .andExpect(jsonPath("$.path").value("/api/v1/favorites"));
    }

    @Test
    @DisplayName("Protected endpoints with valid Bearer token pass through authentication filter")
    void protectedEndpoints_withValidBearerToken_authenticatesUser() throws Exception {
        // Access protected endpoint with Bearer token: returns 404 Not Found (route unmapped) instead of 401 Unauthorized
        mockMvc.perform(get("/api/v1/favorites")
                        .header("Authorization", "Bearer " + validJwt))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Login rate limiting restricts requests to 5 per minute per IP and returns 429 on 6th request")
    void loginRateLimiting_restrictsToFivePerMinute() throws Exception {
        String testIp = "192.168.1.100";
        LoginRequest loginRequest = LoginRequest.builder()
                .email("traveler@example.com")
                .password("WrongPassword")
                .build();

        String payload = objectMapper.writeValueAsString(loginRequest);

        // Perform 5 consecutive login requests from testIp (all pass rate limiter)
        for (int i = 0; i < 5; i++) {
            mockMvc.perform(post("/api/v1/auth/login")
                            .header("X-Forwarded-For", testIp)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(payload))
                    .andExpect(status().isUnauthorized()); // Failed credentials, but allowed through
        }

        // The 6th request from testIp within 60s must be blocked with HTTP 429 Too Many Requests
        mockMvc.perform(post("/api/v1/auth/login")
                        .header("X-Forwarded-For", testIp)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.status").value(429))
                .andExpect(jsonPath("$.code").value("RATE_LIMIT_EXCEEDED"))
                .andExpect(jsonPath("$.message").value("Too many requests. Please wait a moment before trying again."))
                .andExpect(jsonPath("$.path").value("/api/v1/auth/login"))
                .andExpect(jsonPath("$.traceId").exists());
    }
}

