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

import static org.assertj.core.api.Assertions.assertThat;
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
    @DisplayName("GET /api/v1/places should return 200 OK and paged JSON response matching API specification")
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
                .andExpect(jsonPath("$.content[0].averageRating").value(4.8))
                .andExpect(jsonPath("$.pageNumber").value(0))
                .andExpect(jsonPath("$.pageSize").value(1))
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.isLast").value(true));
    }

    @Test
    @DisplayName("GET /api/v1/places?query=cau+rong should bind query parameter to filterRequest")
    void getPlaces_withQueryParameter_bindsQuery() throws Exception {
        org.mockito.ArgumentCaptor<PlaceFilterRequest> captor = org.mockito.ArgumentCaptor.forClass(PlaceFilterRequest.class);
        when(placeService.getPlaces(captor.capture()))
                .thenReturn(new PageImpl<>(List.of(mockPlaceResponse)));

        mockMvc.perform(get("/api/v1/places")
                        .param("query", "cau rong")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());

        assertThat(captor.getValue().getQuery()).isEqualTo("cau rong");
        assertThat(captor.getValue().getEffectiveKeyword()).isEqualTo("cau rong");
    }

    @Test
    @DisplayName("GET /api/v1/places?sort=averageRating,desc should bind standard sort parameter")
    void getPlaces_withSortParameter_bindsSort() throws Exception {
        org.mockito.ArgumentCaptor<PlaceFilterRequest> captor = org.mockito.ArgumentCaptor.forClass(PlaceFilterRequest.class);
        when(placeService.getPlaces(captor.capture()))
                .thenReturn(new PageImpl<>(List.of(mockPlaceResponse)));

        mockMvc.perform(get("/api/v1/places")
                        .param("sort", "averageRating,desc")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());

        assertThat(captor.getValue().getSort()).isEqualTo("averageRating,desc");
    }

    @Test
    @DisplayName("GET /api/v1/places?size=100 should return 400 Bad Request and ApiErrorResponse due to @Max(50)")
    void getPlaces_withExcessiveSize_returns400BadRequest() throws Exception {
        mockMvc.perform(get("/api/v1/places")
                        .param("size", "100")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.size").value("Page size must not exceed 50"))
                .andExpect(jsonPath("$.traceId").exists());
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
    @DisplayName("GET /api/v1/places/{id} when not found should return 404 NOT_FOUND and ApiErrorResponse")
    void getPlaceById_whenNotFound_returns404() throws Exception {
        // Given
        UUID notFoundId = UUID.randomUUID();
        when(placeService.getPlaceById(notFoundId))
                .thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Place not found with id: " + notFoundId));

        // When & Then
        mockMvc.perform(get("/api/v1/places/{id}", notFoundId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.code").value("NOT_FOUND"))
                .andExpect(jsonPath("$.message").value("Place not found with id: " + notFoundId))
                .andExpect(jsonPath("$.traceId").exists());
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

    @Test
    @DisplayName("GET /api/v1/places/{id} with invalid UUID format should return 400 Bad Request and INVALID_ARGUMENT")
    void getPlaceById_withInvalidUuid_returns400BadRequest() throws Exception {
        mockMvc.perform(get("/api/v1/places/{id}", "not-a-valid-uuid")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.code").value("INVALID_ARGUMENT"))
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Failed to convert parameter 'id'")))
                .andExpect(jsonPath("$.traceId").exists());
    }

    @Test
    @DisplayName("GET /api/v1/places/top without required category parameter should return 400 Bad Request and MISSING_PARAMETER")
    void getTopPlacesByCategory_withoutCategoryParam_returns400BadRequest() throws Exception {
        mockMvc.perform(get("/api/v1/places/top")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.code").value("MISSING_PARAMETER"))
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Required request parameter 'category'")))
                .andExpect(jsonPath("$.traceId").exists());
    }
}
