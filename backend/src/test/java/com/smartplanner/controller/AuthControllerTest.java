package com.smartplanner.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartplanner.dto.request.LoginRequest;
import com.smartplanner.dto.request.RefreshTokenRequest;
import com.smartplanner.dto.request.RegisterRequest;
import com.smartplanner.dto.response.AuthResponse;
import com.smartplanner.dto.response.UserResponse;
import com.smartplanner.exception.InvalidTokenException;
import com.smartplanner.exception.UserAlreadyExistsException;
import com.smartplanner.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
@DisplayName("AuthController Web Slice Unit Tests")
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AuthService authService;

    private AuthResponse mockAuthResponse;
    private UUID userId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        UserResponse userResponse = UserResponse.builder()
                .id(userId)
                .email("traveler@example.com")
                .fullName("Nguyen Van A")
                .role("ROLE_USER")
                .build();

        mockAuthResponse = AuthResponse.builder()
                .accessToken("mock.access.token")
                .refreshToken("mock-refresh-token-uuid")
                .tokenType("Bearer")
                .expiresIn(1800L)
                .user(userResponse)
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/auth/register with valid payload returns 201 Created and AuthResponse")
    void register_withValidPayload_returns201Created() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("traveler@example.com")
                .password("SecurePassword123!")
                .fullName("Nguyen Van A")
                .build();

        when(authService.register(any(RegisterRequest.class))).thenReturn(mockAuthResponse);

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").value("mock.access.token"))
                .andExpect(jsonPath("$.refreshToken").value("mock-refresh-token-uuid"))
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresIn").value(1800))
                .andExpect(jsonPath("$.user.email").value("traveler@example.com"))
                .andExpect(jsonPath("$.user.fullName").value("Nguyen Van A"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/register with invalid email returns 400 Bad Request")
    void register_withInvalidEmail_returns400BadRequest() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("invalid-email-format")
                .password("SecurePassword123!")
                .fullName("Nguyen Van A")
                .build();

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.email").exists());
    }

    @Test
    @DisplayName("POST /api/v1/auth/register with duplicate email returns 409 Conflict")
    void register_withDuplicateEmail_returns409Conflict() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("duplicate@example.com")
                .password("SecurePassword123!")
                .fullName("Nguyen Van A")
                .build();

        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new UserAlreadyExistsException("Email address is already in use: duplicate@example.com"));

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("USER_ALREADY_EXISTS"))
                .andExpect(jsonPath("$.message").value("Email address is already in use: duplicate@example.com"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/login with valid credentials returns 200 OK and AuthResponse")
    void login_withValidCredentials_returns200Ok() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email("traveler@example.com")
                .password("SecurePassword123!")
                .build();

        when(authService.login(any(LoginRequest.class))).thenReturn(mockAuthResponse);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("mock.access.token"))
                .andExpect(jsonPath("$.refreshToken").value("mock-refresh-token-uuid"))
                .andExpect(jsonPath("$.user.id").value(userId.toString()));
    }

    @Test
    @DisplayName("POST /api/v1/auth/login with invalid password returns 401 Unauthorized")
    void login_withInvalidPassword_returns401Unauthorized() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email("traveler@example.com")
                .password("WrongPassword")
                .build();

        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new BadCredentialsException("Invalid email or password."));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"))
                .andExpect(jsonPath("$.message").value("Invalid email or password."));
    }

    @Test
    @DisplayName("POST /api/v1/auth/refresh-token with valid token returns 200 OK and fresh token pair")
    void refreshToken_withValidToken_returns200Ok() throws Exception {
        RefreshTokenRequest request = RefreshTokenRequest.builder()
                .refreshToken("valid-refresh-token")
                .build();

        AuthResponse freshResponse = AuthResponse.builder()
                .accessToken("new.access.token")
                .refreshToken("new-refresh-token")
                .tokenType("Bearer")
                .expiresIn(1800L)
                .build();

        when(authService.refreshToken(any(RefreshTokenRequest.class))).thenReturn(freshResponse);

        mockMvc.perform(post("/api/v1/auth/refresh-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("new.access.token"))
                .andExpect(jsonPath("$.refreshToken").value("new-refresh-token"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/refresh-token with expired token returns 401 Unauthorized")
    void refreshToken_withExpiredToken_returns401Unauthorized() throws Exception {
        RefreshTokenRequest request = RefreshTokenRequest.builder()
                .refreshToken("expired-token")
                .build();

        when(authService.refreshToken(any(RefreshTokenRequest.class)))
                .thenThrow(new InvalidTokenException("Invalid or expired refresh token."));

        mockMvc.perform(post("/api/v1/auth/refresh-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"))
                .andExpect(jsonPath("$.message").value("Invalid or expired refresh token."));
    }

    @Test
    @DisplayName("POST /api/v1/auth/logout revokes session and returns 200 OK")
    void logout_withToken_returns200Ok() throws Exception {
        RefreshTokenRequest request = RefreshTokenRequest.builder()
                .refreshToken("token-to-revoke")
                .build();

        doNothing().when(authService).logout("token-to-revoke");

        mockMvc.perform(post("/api/v1/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("User logged out successfully."));
    }
}
