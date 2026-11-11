package com.smartplanner.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartplanner.dto.request.ItineraryItemRequest;
import com.smartplanner.dto.request.ItineraryRequest;
import com.smartplanner.dto.response.ItineraryItemResponse;
import com.smartplanner.dto.response.ItineraryResponse;
import com.smartplanner.dto.response.ItinerarySummaryResponse;
import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.entity.User;
import com.smartplanner.exception.ForbiddenException;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.ItineraryService;
import com.smartplanner.service.JwtService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ItineraryController.class)
@AutoConfigureMockMvc(addFilters = false)
@DisplayName("ItineraryController Web Slice Unit Tests")
class ItineraryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ItineraryService itineraryService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private UserRepository userRepository;

    private UUID userId;
    private UUID itineraryId;
    private UUID placeId;
    private User testUser;
    private ItineraryResponse mockDetailResponse;
    private ItinerarySummaryResponse mockSummaryResponse;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        itineraryId = UUID.randomUUID();
        placeId = UUID.randomUUID();

        testUser = User.builder()
                .id(userId)
                .email("traveler@example.com")
                .fullName("Passionate Traveler")
                .role("ROLE_USER")
                .build();

        mockSummaryResponse = ItinerarySummaryResponse.builder()
                .id(itineraryId)
                .title("Saigon Weekend Highlights")
                .description("2-day discovery")
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 11, 22))
                .totalDays(3)
                .totalPlaces(1)
                .isPublic(false)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        PlaceResponse placeResponse = PlaceResponse.builder()
                .id(placeId)
                .name("The Coffee House - Landmark 81")
                .category("CAFE")
                .priceLevel(2)
                .build();

        ItineraryItemResponse itemResponse = ItineraryItemResponse.builder()
                .id(UUID.randomUUID())
                .dayNumber(1)
                .orderIndex(0)
                .startTime(LocalTime.of(9, 0))
                .notes("Morning coffee")
                .place(placeResponse)
                .build();

        mockDetailResponse = ItineraryResponse.builder()
                .id(itineraryId)
                .title("Saigon Weekend Highlights")
                .description("2-day discovery")
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 11, 22))
                .totalDays(3)
                .totalPlaces(1)
                .isPublic(false)
                .items(List.of(itemResponse))
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
    @DisplayName("GET /api/v1/itineraries returns 200 OK and paginated list")
    void getUserItineraries_Returns200AndList() throws Exception {
        when(itineraryService.getUserItineraries(eq(userId), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(mockSummaryResponse)));

        mockMvc.perform(get("/api/v1/itineraries")
                        .with(user(testUser))
                        .param("page", "0")
                        .param("size", "10")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].id").value(itineraryId.toString()))
                .andExpect(jsonPath("$.content[0].title").value("Saigon Weekend Highlights"))
                .andExpect(jsonPath("$.content[0].totalDays").value(3));
    }

    @Test
    @DisplayName("GET /api/v1/itineraries/{id} returns 200 OK and full schedule detail")
    void getItineraryDetail_Returns200AndDetail() throws Exception {
        when(itineraryService.getItineraryDetail(itineraryId, userId))
                .thenReturn(mockDetailResponse);

        mockMvc.perform(get("/api/v1/itineraries/" + itineraryId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(itineraryId.toString()))
                .andExpect(jsonPath("$.title").value("Saigon Weekend Highlights"))
                .andExpect(jsonPath("$.items[0].place.name").value("The Coffee House - Landmark 81"));
    }

    @Test
    @DisplayName("GET /api/v1/itineraries/{id} returns 404 NOT FOUND when itinerary does not exist")
    void getItineraryDetail_Returns404WhenNotFound() throws Exception {
        when(itineraryService.getItineraryDetail(itineraryId, userId))
                .thenThrow(new ResourceNotFoundException("Itinerary not found with id: " + itineraryId));

        mockMvc.perform(get("/api/v1/itineraries/" + itineraryId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("NOT_FOUND"));
    }

    @Test
    @DisplayName("GET /api/v1/itineraries/{id} returns 403 FORBIDDEN when accessed by non-owner")
    void getItineraryDetail_Returns403WhenForbidden() throws Exception {
        when(itineraryService.getItineraryDetail(itineraryId, userId))
                .thenThrow(new ForbiddenException("You do not possess permission to access or modify this itinerary."));

        mockMvc.perform(get("/api/v1/itineraries/" + itineraryId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("FORBIDDEN_ACCESS"));
    }

    @Test
    @DisplayName("POST /api/v1/itineraries returns 201 CREATED when request is valid")
    void createItinerary_Returns201Created() throws Exception {
        ItineraryItemRequest itemReq = ItineraryItemRequest.builder()
                .placeId(placeId)
                .dayNumber(1)
                .orderIndex(0)
                .startTime(LocalTime.of(9, 0))
                .notes("Morning coffee")
                .build();

        ItineraryRequest request = ItineraryRequest.builder()
                .title("Saigon Weekend Highlights")
                .description("2-day discovery")
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 11, 22))
                .items(List.of(itemReq))
                .build();

        when(itineraryService.createItinerary(eq(userId), any(ItineraryRequest.class)))
                .thenReturn(mockDetailResponse);

        mockMvc.perform(post("/api/v1/itineraries")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(itineraryId.toString()))
                .andExpect(jsonPath("$.title").value("Saigon Weekend Highlights"));
    }

    @Test
    @DisplayName("POST /api/v1/itineraries returns 400 BAD REQUEST when title is blank")
    void createItinerary_Returns400WhenTitleBlank() throws Exception {
        ItineraryRequest request = ItineraryRequest.builder()
                .title("   ")
                .build();

        mockMvc.perform(post("/api/v1/itineraries")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("PUT /api/v1/itineraries/{id} returns 200 OK when update succeeds")
    void updateItinerary_Returns200Ok() throws Exception {
        ItineraryRequest request = ItineraryRequest.builder()
                .title("Updated Highlights")
                .build();

        when(itineraryService.updateItinerary(eq(itineraryId), eq(userId), any(ItineraryRequest.class)))
                .thenReturn(mockDetailResponse);

        mockMvc.perform(put("/api/v1/itineraries/" + itineraryId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(itineraryId.toString()));
    }

    @Test
    @DisplayName("DELETE /api/v1/itineraries/{id} returns 204 NO CONTENT on deletion")
    void deleteItinerary_Returns204NoContent() throws Exception {
        doNothing().when(itineraryService).deleteItinerary(itineraryId, userId);

        mockMvc.perform(delete("/api/v1/itineraries/" + itineraryId)
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());
    }
}
