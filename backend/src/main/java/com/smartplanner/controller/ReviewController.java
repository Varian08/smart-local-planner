package com.smartplanner.controller;

import com.smartplanner.dto.request.ReviewRequest;
import com.smartplanner.dto.response.PageResponse;
import com.smartplanner.dto.response.ReviewResponse;
import com.smartplanner.entity.User;
import com.smartplanner.service.ReviewService;
import com.smartplanner.util.PaginationUtils;
import com.smartplanner.util.SecurityUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Set;
import java.util.UUID;

/**
 * REST controller for managing place reviews and ratings.
 * Complies with docs/API_SPECIFICATION.md § 5.
 */
@RestController
@RequestMapping("/api/v1/places/{placeId}/reviews")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Reviews", description = "Place Community Reviews and Ratings APIs")
public class ReviewController {

    private static final Set<String> ALLOWED_SORT_PROPERTIES = Set.of(
            "createdAt", "updatedAt", "rating"
    );

    private final ReviewService reviewService;

    /**
     * Publicly retrieve paginated reviews for a specific place.
     * GET /api/v1/places/{placeId}/reviews?page=0&size=10&sort=createdAt,desc
     */
    @GetMapping
    @Operation(summary = "List reviews for a place with pagination")
    public ResponseEntity<PageResponse<ReviewResponse>> getPlaceReviews(
            @PathVariable UUID placeId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort
    ) {
        log.debug("GET /api/v1/places/{}/reviews?page={}&size={}&sort={}", placeId, page, size, sort);

        Pageable pageable = PaginationUtils.buildPageable(
                page, size, sort, "createdAt", ALLOWED_SORT_PROPERTIES
        );
        Page<ReviewResponse> reviewPage = reviewService.getPlaceReviews(placeId, pageable);

        return ResponseEntity.ok(PageResponse.from(reviewPage));
    }

    /**
     * Submit a new review and rating for a place by an authenticated user.
     * POST /api/v1/places/{placeId}/reviews
     */
    @PostMapping
    @Operation(summary = "Submit a place review (1-5 stars + optional comment)")
    public ResponseEntity<ReviewResponse> submitReview(
            @PathVariable UUID placeId,
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody ReviewRequest request
    ) {
        UUID userId = SecurityUtils.resolveUserId(currentUser);
        log.info("POST /api/v1/places/{}/reviews by user {}", placeId, userId);

        ReviewResponse response = reviewService.submitReview(userId, placeId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}

