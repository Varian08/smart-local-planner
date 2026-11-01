package com.smartplanner.integration;

import com.smartplanner.entity.RefreshToken;
import com.smartplanner.entity.User;
import com.smartplanner.repository.RefreshTokenRepository;
import com.smartplanner.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration test verifying User and RefreshToken persistence, queries,
 * and database cascading behavior against real PostgreSQL container.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers(disabledWithoutDocker = true)
@DisplayName("UserRepository and RefreshTokenRepository Integration Tests (PostgreSQL)")
class UserRepositoryAndRefreshTokenIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @Test
    @DisplayName("Verify User and RefreshToken lifecycle, query methods and cascading delete")
    void testUserAndRefreshTokenLifecycle() {
        // 1. Create and persist User
        User user = User.builder()
                .email("test-traveler-" + UUID.randomUUID() + "@example.com")
                .passwordHash("$2a$10$hashedpasswordfore2e")
                .fullName("E2E Traveler")
                .role("ROLE_USER")
                .build();
        User savedUser = userRepository.save(user);

        assertThat(savedUser.getId()).isNotNull();
        assertThat(userRepository.existsByEmail(savedUser.getEmail())).isTrue();

        // 2. Create and persist RefreshToken
        RefreshToken token = RefreshToken.builder()
                .user(savedUser)
                .token("e2e-token-" + UUID.randomUUID())
                .expiresAt(OffsetDateTime.now().plusDays(7))
                .build();
        RefreshToken savedToken = refreshTokenRepository.save(token);

        assertThat(savedToken.getId()).isNotNull();
        assertThat(savedToken.isActive()).isTrue();

        // 3. Verify findByToken query
        Optional<RefreshToken> retrievedToken = refreshTokenRepository.findByToken(savedToken.getToken());
        assertThat(retrievedToken).isPresent();
        assertThat(retrievedToken.get().getUser().getId()).isEqualTo(savedUser.getId());

        // 4. Verify ON DELETE CASCADE from User to RefreshToken
        userRepository.delete(savedUser);
        assertThat(userRepository.findById(savedUser.getId())).isEmpty();
        assertThat(refreshTokenRepository.findById(savedToken.getId())).isEmpty();
    }
}

