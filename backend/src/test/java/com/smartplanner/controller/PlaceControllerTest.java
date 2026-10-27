package com.smartplanner.controller;

import com.smartplanner.dto.request.PlaceFilterRequest;
import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.service.PlaceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Web Slice Unit Tests for PlaceController.
 * Uses @WebMvcTest and MockMvc to test REST API contracts, HTTP status codes,
 * and JSON serialization in isolation without starting the full embedded server.
 */
@WebMvcTest(controllers = PlaceController.class)
@AutoConfigureMockMvc(addFilters = false)
@DisplayName("PlaceController Web Slice Unit Tests")
class PlaceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PlaceService placeService;

    private PlaceResponse mockPlaceResponse;
    private UUID placeId;

    @BeforeEach
    void setUp() {
        placeId = UUID.randomUUID();
        mockPlaceResponse = PlaceResponse.builder()
                .id(placeId)
                .name("Cầu Rồng")
                .description("Cây cầu biểu tượng Đà Nẵng")
                .category("CULTURE")
                .address("Đường Nguyễn Văn Linh, Hải Châu, Đà Nẵng")
                .latitude(16.0611)
                .longitude(108.2272)
                .priceLevel(1)
                .openingHours("24/7")
                .imageUrl("https://example.com/image.jpg")
                .averageRating(BigDecimal.valueOf(4.8))
                .totalReviews(1250)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();
    }

    @Test
    @DisplayName("GET /api/v1/places should return 200 OK and paged JSON response")
    void getPlaces_returns200AndJsonPage() throws Exception {
        // Given
        when(placeService.getPlaces(any(PlaceFilterRequest.class)))
                .thenReturn(new PageImpl<>(List.of(mockPlaceResponse)));

        // When & Then
        mockMvc.perform(get("/api/v1/places")
                        .param("category", "CULTURE")
                        .param("page", "0")
                        .param("size", "10")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].id").value(placeId.toString()))
                .andExpect(jsonPath("$.content[0].name").value("Cầu Rồng"))
                .andExpect(jsonPath("$.content[0].category").value("CULTURE"))
                .andExpect(jsonPath("$.content[0].averageRating").value(4.8));
    }

    @Test
    @DisplayName("GET /api/v1/places/{id} when found should return 200 OK and place details")
    void getPlaceById_whenFound_returns200AndPlaceDetails() throws Exception {
        // Given
        when(placeService.getPlaceById(placeId)).thenReturn(mockPlaceResponse);

        // When & Then
        mockMvc.perform(get("/api/v1/places/{id}", placeId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(placeId.toString()))
                .andExpect(jsonPath("$.name").value("Cầu Rồng"))
                .andExpect(jsonPath("$.category").value("CULTURE"));
    }

    @Test
    @DisplayName("GET /api/v1/places/{id} when not found should return 404 NOT_FOUND")
    void getPlaceById_whenNotFound_returns404() throws Exception {
        // Given
        UUID notFoundId = UUID.randomUUID();
        when(placeService.getPlaceById(notFoundId))
                .thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Place not found with id: " + notFoundId));

        // When & Then
        mockMvc.perform(get("/api/v1/places/{id}", notFoundId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("GET /api/v1/places/top should return 200 OK and list of top places")
    void getTopPlacesByCategory_returns200AndList() throws Exception {
        // Given
        when(placeService.getTopPlacesByCategory("CULTURE")).thenReturn(List.of(mockPlaceResponse));

        // When & Then
        mockMvc.perform(get("/api/v1/places/top")
                        .param("category", "CULTURE")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(placeId.toString()))
                .andExpect(jsonPath("$[0].name").value("Cầu Rồng"));
    }
}
