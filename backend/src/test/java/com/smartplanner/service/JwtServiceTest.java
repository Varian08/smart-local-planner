package com.smartplanner.service;

import com.smartplanner.entity.User;
import com.smartplanner.service.impl.JwtServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("JwtService Unit Tests")
class JwtServiceTest {

    private static final String TEST_SECRET = "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970";
    private static final long ACCESS_EXPIRATION_MS = 1800000; // 30 minutes
    private static final long REFRESH_EXPIRATION_MS = 604800000; // 7 days

    private JwtServiceImpl jwtService;
    private User testUser;
    private UUID userId;

    @BeforeEach
    void setUp() {
        jwtService = new JwtServiceImpl(TEST_SECRET, ACCESS_EXPIRATION_MS, REFRESH_EXPIRATION_MS);

        userId = UUID.randomUUID();
        testUser = User.builder()
                .id(userId)
                .email("traveler@example.com")
                .passwordHash("$2a$10$hashedpasswordstringforuser")
                .fullName("Nguyen Van A")
                .role("ROLE_USER")
                .build();
    }

    @Test
    @DisplayName("generateAccessToken() with valid User produces well-formed JWT with expected claims")
    void generateAccessToken_producesWellFormedToken() {
        String token = jwtService.generateAccessToken(testUser);

        assertThat(token).isNotBlank();
        assertThat(token.split("\\.")).hasSize(3); // JWT consists of header.payload.signature

        assertThat(jwtService.extractUsername(token)).isEqualTo("traveler@example.com");
        assertThat(jwtService.extractEmail(token)).isEqualTo("traveler@example.com");
        assertThat(jwtService.extractUserId(token)).isEqualTo(userId);
        assertThat(jwtService.isTokenExpired(token)).isFalse();
        assertThat(jwtService.isTokenValid(token, testUser)).isTrue();
    }

    @Test
    @DisplayName("generateAccessToken() with extra claims preserves custom key-value pairs")
    void generateAccessToken_withExtraClaims_preservesClaims() {
        Map<String, Object> extraClaims = Map.of("city", "Da Nang", "tier", "VIP");

        String token = jwtService.generateAccessToken(extraClaims, testUser);

        assertThat(token).isNotBlank();
        String city = jwtService.extractClaim(token, claims -> claims.get("city", String.class));
        String tier = jwtService.extractClaim(token, claims -> claims.get("tier", String.class));

        assertThat(city).isEqualTo("Da Nang");
        assertThat(tier).isEqualTo("VIP");
    }

    @Test
    @DisplayName("isTokenValid() with mismatched user returns false")
    void isTokenValid_withMismatchedUser_returnsFalse() {
        String token = jwtService.generateAccessToken(testUser);

        User differentUser = User.builder()
                .id(UUID.randomUUID())
                .email("other@example.com")
                .fullName("Tran Thi B")
                .role("ROLE_USER")
                .build();

        assertThat(jwtService.isTokenValid(token, differentUser)).isFalse();
    }

    @Test
    @DisplayName("isTokenValid() with tampered token string returns false without crashing")
    void isTokenValid_withTamperedToken_returnsFalse() {
        String token = jwtService.generateAccessToken(testUser);
        String tamperedToken = token + "corrupted";

        assertThat(jwtService.isTokenValid(tamperedToken, testUser)).isFalse();
    }

    @Test
    @DisplayName("isTokenExpired() with expired token returns true and invalidates token")
    void isTokenExpired_withExpiredToken_returnsTrue() {
        // JwtService configured with negative expiration (already expired at generation)
        JwtServiceImpl expiredJwtService = new JwtServiceImpl(TEST_SECRET, -1000L, REFRESH_EXPIRATION_MS);

        String expiredToken = expiredJwtService.generateAccessToken(testUser);

        assertThat(expiredJwtService.isTokenExpired(expiredToken)).isTrue();
        assertThat(expiredJwtService.isTokenValid(expiredToken, testUser)).isFalse();
    }

    @Test
    @DisplayName("generateRefreshToken() produces unique cryptographically random token string")
    void generateRefreshToken_producesUniqueSecureTokens() {
        String token1 = jwtService.generateRefreshToken();
        String token2 = jwtService.generateRefreshToken();

        assertThat(token1).isNotBlank();
        assertThat(token2).isNotBlank();
        assertThat(token1).isNotEqualTo(token2);
    }

    @Test
    @DisplayName("Expiration accessor methods return correct lifetime in seconds")
    void expirationAccessors_returnCorrectSeconds() {
        assertThat(jwtService.getAccessTokenExpirationInSeconds()).isEqualTo(1800); // 30m = 1800s
        assertThat(jwtService.getRefreshTokenExpirationInSeconds()).isEqualTo(604800); // 7d = 604800s
    }
}

