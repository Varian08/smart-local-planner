package com.smartplanner.service;

import com.smartplanner.dto.request.ReviewRequest;
import com.smartplanner.dto.response.ReviewResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

/**
 * Service interface managing community place reviews, conflict validation,
 * and atomic venue rating aggregation.
 * Complies with docs/API_SPECIFICATION.md § 5.
 */
public interface ReviewService {

    /**
     * Retrieve paginated reviews for a specific place with eager author fetching.
     *
     * @param placeId ID of the place
     * @param pageable pagination and sorting parameters
     * @return paginated reviews
     */
    Page<ReviewResponse> getPlaceReviews(UUID placeId, Pageable pageable);

    /**
     * Submit a new review for a place by an authenticated user.
     * Enforces one review per user per place (throws DuplicateResourceException on duplicate).
     * Atomically recalculates the place's average rating and review count in the same transaction.
     *
     * @param userId ID of the authenticated user
     * @param placeId ID of the place being reviewed
     * @param request review payload containing rating and optional comment
     * @return the created ReviewResponse
     */
    ReviewResponse submitReview(UUID userId, UUID placeId, ReviewRequest request);
}

