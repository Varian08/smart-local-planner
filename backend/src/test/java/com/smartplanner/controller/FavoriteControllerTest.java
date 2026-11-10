package com.smartplanner.controller;

import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.entity.User;
import com.smartplanner.exception.DuplicateResourceException;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.FavoriteService;
import com.smartplanner.service.JwtService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = FavoriteController.class)
@AutoConfigureMockMvc(addFilters = false)
@DisplayName("FavoriteController Web Slice Unit Tests")
class FavoriteControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private FavoriteService favoriteService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private UserRepository userRepository;

    private UUID userId;
    private UUID placeId;
    private User testUser;
    private PlaceResponse mockPlaceResponse;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        placeId = UUID.randomUUID();

        testUser = User.builder()
                .id(userId)
                .email("traveler@example.com")
                .fullName("Passionate Traveler")
                .role("ROLE_USER")
                .build();

        mockPlaceResponse = PlaceResponse.builder()
                .id(placeId)
                .name("Dragon Bridge")
                .description("Iconic bridge")
                .category("CULTURE")
                .address("Da Nang")
                .latitude(16.0611)
                .longitude(108.2272)
                .priceLevel(1)
                .openingHours("24/7")
                .imageUrl("https://example.com/bridge.jpg")
                .averageRating(BigDecimal.valueOf(4.8))
                .totalReviews(1500)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(testUser, null, testUser.getAuthorities())
        );
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("GET /api/v1/favorites returns 200 OK and list of favorite places")
    void getUserFavorites_returns200AndList() throws Exception {
        when(favoriteService.getUserFavorites(userId)).thenReturn(List.of(mockPlaceResponse));

        mockMvc.perform(get("/api/v1/favorites")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(placeId.toString()))
                .andExpect(jsonPath("$[0].name").value("Dragon Bridge"))
                .andExpect(jsonPath("$[0].category").value("CULTURE"))
                .andExpect(jsonPath("$[0].averageRating").value(4.8));
    }

    @Test
    @DisplayName("POST /api/v1/favorites/{placeId} returns 201 Created and success message")
    void addFavorite_returns201AndMessage() throws Exception {
        doNothing().when(favoriteService).addFavorite(userId, placeId);

        mockMvc.perform(post("/api/v1/favorites/{placeId}", placeId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message").value("Place added to favorites."));
    }

    @Test
    @DisplayName("POST /api/v1/favorites/{placeId} when already favorited returns 409 Conflict")
    void addFavorite_whenAlreadyFavorited_returns409Conflict() throws Exception {
        doThrow(new DuplicateResourceException("Place is already in favorites."))
                .when(favoriteService).addFavorite(userId, placeId);

        mockMvc.perform(post("/api/v1/favorites/{placeId}", placeId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.message").value("Place is already in favorites."));
    }

    @Test
    @DisplayName("POST /api/v1/favorites/{placeId} when place not found returns 404 Not Found")
    void addFavorite_whenPlaceNotFound_returns404NotFound() throws Exception {
        doThrow(new ResourceNotFoundException("Place not found with id: " + placeId))
                .when(favoriteService).addFavorite(userId, placeId);

        mockMvc.perform(post("/api/v1/favorites/{placeId}", placeId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.message").value("Place not found with id: " + placeId));
    }

    @Test
    @DisplayName("DELETE /api/v1/favorites/{placeId} returns 200 OK and success message")
    void removeFavorite_returns200AndMessage() throws Exception {
        doNothing().when(favoriteService).removeFavorite(userId, placeId);

        mockMvc.perform(delete("/api/v1/favorites/{placeId}", placeId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Place removed from favorites."));
    }

    @Test
    @DisplayName("DELETE /api/v1/favorites/{placeId} when favorite not found returns 404 Not Found")
    void removeFavorite_whenNotFound_returns404NotFound() throws Exception {
        doThrow(new ResourceNotFoundException("Favorite not found for place id: " + placeId))
                .when(favoriteService).removeFavorite(userId, placeId);

        mockMvc.perform(delete("/api/v1/favorites/{placeId}", placeId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.message").value("Favorite not found for place id: " + placeId));
    }
}
