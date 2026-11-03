package com.smartplanner.integration;

import com.smartplanner.entity.Favorite;
import com.smartplanner.entity.Place;
import com.smartplanner.entity.User;
import com.smartplanner.repository.FavoriteRepository;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * End-to-End Integration tests verifying Favorite REST controller, access control,
 * JWT authentication flow, and PostgreSQL cascading deletes against real container.
 */
@SpringBootTest
@AutoConfigureMockMvc
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers(disabledWithoutDocker = true)
@DisplayName("Favorite REST Controller and Access Control Integration Tests")
class FavoriteIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PlaceRepository placeRepository;

    @Autowired
    private FavoriteRepository favoriteRepository;

    private User testUser;
    private Place testPlace;
    private String validJwt;

    @BeforeEach
    void setUp() {
        favoriteRepository.deleteAll();

        testUser = userRepository.save(User.builder()
                .email("fav-traveler-" + UUID.randomUUID() + "@example.com")
                .passwordHash("$2a$10$dummyhashedpasswordforfavtest")
                .fullName("Favorite Tester")
                .role("ROLE_USER")
                .build());

        testPlace = placeRepository.save(Place.builder()
                .name("Integration Favorite Place " + UUID.randomUUID())
                .description("Scenic mountain view")
                .category("NATURE")
                .address("Da Nang Highlands")
                .latitude(16.05)
                .longitude(108.20)
                .priceLevel(2)
                .openingHours("06:00 - 18:00")
                .imageUrl("https://example.com/mountain.jpg")
                .averageRating(BigDecimal.valueOf(4.7))
                .totalReviews(200)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build());

        validJwt = jwtService.generateAccessToken(testUser);
    }

    @Test
    @DisplayName("Unauthenticated requests to favorites endpoints return 401 Unauthorized")
    void unauthenticatedRequests_return401Unauthorized() throws Exception {
        UUID dummyPlaceId = UUID.randomUUID();

        mockMvc.perform(get("/api/v1/favorites"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"))
                .andExpect(jsonPath("$.path").value("/api/v1/favorites"));

        mockMvc.perform(post("/api/v1/favorites/{placeId}", dummyPlaceId))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));

        mockMvc.perform(delete("/api/v1/favorites/{placeId}", dummyPlaceId))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
    }

    @Test
    @DisplayName("End-to-End favorite lifecycle: Add, Retrieve, Duplicate Check, and Remove with JWT")
    void endToEnd_favoriteLifecycle_withValidJwtToken() throws Exception {
        String authHeader = "Bearer " + validJwt;

        // 1. Initial list should be empty
        mockMvc.perform(get("/api/v1/favorites")
                        .header("Authorization", authHeader))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        // 2. Add place to favorites
        mockMvc.perform(post("/api/v1/favorites/{placeId}", testPlace.getId())
                        .header("Authorization", authHeader))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message").value("Place added to favorites."));

        // 3. Retrieve list and verify added place
        mockMvc.perform(get("/api/v1/favorites")
                        .header("Authorization", authHeader))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(testPlace.getId().toString()))
                .andExpect(jsonPath("$[0].name").value(testPlace.getName()));

        // 4. Adding same place again returns 409 Conflict
        mockMvc.perform(post("/api/v1/favorites/{placeId}", testPlace.getId())
                        .header("Authorization", authHeader))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.message").value("Place is already in favorites."));

        // 5. Remove place from favorites
        mockMvc.perform(delete("/api/v1/favorites/{placeId}", testPlace.getId())
                        .header("Authorization", authHeader))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Place removed from favorites."));

        // 6. Verify list is empty again
        mockMvc.perform(get("/api/v1/favorites")
                        .header("Authorization", authHeader))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    @DisplayName("Database cascading delete: deleting a Place automatically cascades to favorites table")
    void cascadingDelete_placeDeletionRemovesFavorite() {
        Favorite favorite = favoriteRepository.save(Favorite.builder()
                .user(testUser)
                .place(testPlace)
                .build());

        assertThat(favoriteRepository.existsByUserIdAndPlaceId(testUser.getId(), testPlace.getId())).isTrue();

        // Delete place directly from repository
        placeRepository.delete(testPlace);

        // Verify favorite record is removed via foreign key ON DELETE CASCADE
        assertThat(favoriteRepository.existsById(favorite.getId())).isFalse();
    }
}
