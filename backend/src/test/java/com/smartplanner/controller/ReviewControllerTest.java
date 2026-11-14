package com.smartplanner.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartplanner.dto.request.ReviewRequest;
import com.smartplanner.dto.response.ReviewResponse;
import com.smartplanner.entity.User;
import com.smartplanner.exception.DuplicateResourceException;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.JwtService;
import com.smartplanner.service.ReviewService;
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

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ReviewController.class)
@AutoConfigureMockMvc(addFilters = false)
@DisplayName("ReviewController Web Slice Unit Tests")
class ReviewControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ReviewService reviewService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private UserRepository userRepository;

    private UUID userId;
    private UUID placeId;
    private UUID reviewId;
    private User testUser;
    private ReviewResponse mockReviewResponse;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        placeId = UUID.randomUUID();
        reviewId = UUID.randomUUID();

        testUser = User.builder()
                .id(userId)
                .email("traveler@example.com")
                .fullName("Tran Thi B")
                .avatarUrl("https://res.cloudinary.com/demo/image/upload/avatar.webp")
                .role("ROLE_USER")
                .build();

        mockReviewResponse = ReviewResponse.builder()
                .id(reviewId)
                .userId(userId)
                .authorName("Tran Thi B")
                .authorAvatar("https://res.cloudinary.com/demo/image/upload/avatar.webp")
                .rating(5)
                .comment("Wonderful atmosphere and delicious signature coffee!")
                .createdAt(OffsetDateTime.now())
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
    @DisplayName("GET /api/v1/places/{id}/reviews returns 200 OK with paginated envelope")
    void getPlaceReviews_Returns200Ok() throws Exception {
        when(reviewService.getPlaceReviews(eq(placeId), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(mockReviewResponse)));

        mockMvc.perform(get("/api/v1/places/" + placeId + "/reviews")
                        .param("page", "0")
                        .param("size", "10")
                        .param("sort", "createdAt,desc")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].id").value(reviewId.toString()))
                .andExpect(jsonPath("$.content[0].userId").value(userId.toString()))
                .andExpect(jsonPath("$.content[0].authorName").value("Tran Thi B"))
                .andExpect(jsonPath("$.content[0].rating").value(5))
                .andExpect(jsonPath("$.content[0].comment").value("Wonderful atmosphere and delicious signature coffee!"))
                .andExpect(jsonPath("$.pageNumber").value(0))
                .andExpect(jsonPath("$.pageSize").value(1))
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.isLast").value(true));
    }

    @Test
    @DisplayName("GET /api/v1/places/{id}/reviews returns 400 BAD REQUEST when sort parameter is invalid")
    void getPlaceReviews_Returns400WhenSortInvalid() throws Exception {
        mockMvc.perform(get("/api/v1/places/" + placeId + "/reviews")
                        .param("sort", "nonExistentField,asc"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("BAD_REQUEST"));
    }

    @Test
    @DisplayName("GET /api/v1/places/{id}/reviews returns 404 NOT_FOUND when place does not exist")
    void getPlaceReviews_Returns404NotFound() throws Exception {
        when(reviewService.getPlaceReviews(eq(placeId), any(Pageable.class)))
                .thenThrow(new ResourceNotFoundException("Place not found with id: " + placeId));

        mockMvc.perform(get("/api/v1/places/" + placeId + "/reviews")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("NOT_FOUND"))
                .andExpect(jsonPath("$.message").value("Place not found with id: " + placeId));
    }

    @Test
    @DisplayName("POST /api/v1/places/{id}/reviews returns 201 CREATED on valid review")
    void submitReview_Returns201Created() throws Exception {
        ReviewRequest request = ReviewRequest.builder()
                .rating(5)
                .comment("Wonderful atmosphere and delicious signature coffee!")
                .build();

        when(reviewService.submitReview(eq(userId), eq(placeId), any(ReviewRequest.class)))
                .thenReturn(mockReviewResponse);

        mockMvc.perform(post("/api/v1/places/" + placeId + "/reviews")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(reviewId.toString()))
                .andExpect(jsonPath("$.userId").value(userId.toString()))
                .andExpect(jsonPath("$.rating").value(5))
                .andExpect(jsonPath("$.comment").value("Wonderful atmosphere and delicious signature coffee!"));
    }

    @Test
    @DisplayName("POST /api/v1/places/{id}/reviews returns 400 VALIDATION_FAILED when rating is null")
    void submitReview_NullRating_Returns400BadRequest() throws Exception {
        ReviewRequest request = ReviewRequest.builder()
                .rating(null)
                .comment("Missing rating")
                .build();

        mockMvc.perform(post("/api/v1/places/" + placeId + "/reviews")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("POST /api/v1/places/{id}/reviews returns 400 VALIDATION_FAILED when rating is below 1")
    void submitReview_RatingBelowMin_Returns400BadRequest() throws Exception {
        ReviewRequest request = ReviewRequest.builder()
                .rating(0)
                .comment("Zero rating")
                .build();

        mockMvc.perform(post("/api/v1/places/" + placeId + "/reviews")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("POST /api/v1/places/{id}/reviews returns 400 VALIDATION_FAILED when rating exceeds 5")
    void submitReview_RatingAboveMax_Returns400BadRequest() throws Exception {
        ReviewRequest request = ReviewRequest.builder()
                .rating(6)
                .comment("Six stars rating")
                .build();

        mockMvc.perform(post("/api/v1/places/" + placeId + "/reviews")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("POST /api/v1/places/{id}/reviews returns 400 VALIDATION_FAILED when comment exceeds 1000 characters")
    void submitReview_CommentTooLong_Returns400BadRequest() throws Exception {
        ReviewRequest request = ReviewRequest.builder()
                .rating(5)
                .comment("a".repeat(1001))
                .build();

        mockMvc.perform(post("/api/v1/places/" + placeId + "/reviews")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("POST /api/v1/places/{id}/reviews returns 409 DATA_CONFLICT on duplicate review")
    void submitReview_DuplicateReview_Returns409Conflict() throws Exception {
        ReviewRequest request = ReviewRequest.builder()
                .rating(4)
                .comment("Second attempt review")
                .build();

        when(reviewService.submitReview(eq(userId), eq(placeId), any(ReviewRequest.class)))
                .thenThrow(new DuplicateResourceException("You have already reviewed this place."));

        mockMvc.perform(post("/api/v1/places/" + placeId + "/reviews")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("DATA_CONFLICT"))
                .andExpect(jsonPath("$.message").value("You have already reviewed this place."));
    }

    @Test
    @DisplayName("POST /api/v1/places/{id}/reviews returns 404 NOT_FOUND when place does not exist")
    void submitReview_PlaceNotFound_Returns404NotFound() throws Exception {
        ReviewRequest request = ReviewRequest.builder()
                .rating(5)
                .comment("Review on nonexistent place")
                .build();

        when(reviewService.submitReview(eq(userId), eq(placeId), any(ReviewRequest.class)))
                .thenThrow(new ResourceNotFoundException("Place not found with id: " + placeId));

        mockMvc.perform(post("/api/v1/places/" + placeId + "/reviews")
                        .with(user(testUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("NOT_FOUND"));
    }

    @Test
    @DisplayName("POST /api/v1/places/{id}/reviews returns 401 UNAUTHORIZED when no authenticated user is present")
    void submitReview_Unauthenticated_Returns401Unauthorized() throws Exception {
        SecurityContextHolder.clearContext();

        ReviewRequest request = ReviewRequest.builder()
                .rating(5)
                .comment("Unauthenticated submission")
                .build();

        mockMvc.perform(post("/api/v1/places/" + placeId + "/reviews")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
    }
}
