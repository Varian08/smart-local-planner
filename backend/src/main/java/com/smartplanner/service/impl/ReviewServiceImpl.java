package com.smartplanner.service.impl;

import com.smartplanner.dto.request.ReviewRequest;
import com.smartplanner.dto.response.ReviewResponse;
import com.smartplanner.entity.Place;
import com.smartplanner.entity.Review;
import com.smartplanner.entity.User;
import com.smartplanner.exception.DuplicateResourceException;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.repository.ReviewRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.ReviewService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.UUID;

/**
 * Implementation of ReviewService handling review submissions, duplicate guards,
 * and transactional atomic place rating aggregation.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final PlaceRepository placeRepository;

    @Override
    public Page<ReviewResponse> getPlaceReviews(UUID placeId, Pageable pageable) {
        log.debug("Fetching reviews for place {} with pageable {}", placeId, pageable);
        if (!placeRepository.existsById(placeId)) {
            log.warn("Reviews retrieval rejected: Place not found with id: {}", placeId);
            throw new ResourceNotFoundException("Place not found with id: " + placeId);
        }

        Page<Review> reviews = reviewRepository.findByPlaceIdWithUser(placeId, pageable);
        return reviews.map(ReviewResponse::from);
    }

    @Override
    @Transactional
    public ReviewResponse submitReview(UUID userId, UUID placeId, ReviewRequest request) {
        log.debug("Submitting review from user {} for place {}", userId, placeId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> {
                    log.warn("Review submission rejected: User not found with id: {}", userId);
                    return new ResourceNotFoundException("User not found with id: " + userId);
                });

        Place place = placeRepository.findById(placeId)
                .orElseThrow(() -> {
                    log.warn("Review submission rejected: Place not found with id: {}", placeId);
                    return new ResourceNotFoundException("Place not found with id: " + placeId);
                });

        if (reviewRepository.existsByUserIdAndPlaceId(userId, placeId)) {
            log.warn("Review submission rejected: User {} has already reviewed place {}", userId, placeId);
            throw new DuplicateResourceException("You have already reviewed this place.");
        }

        Review review = Review.builder()
                .user(user)
                .place(place)
                .rating(request.getRating())
                .comment(request.getComment() != null ? request.getComment().trim() : null)
                .build();

        Review savedReview = reviewRepository.saveAndFlush(review);

        // Atomic recalculation of place rating and review count
        Double avgRating = reviewRepository.calculateAverageRatingByPlaceId(placeId);
        int totalReviews = reviewRepository.countByPlaceId(placeId);

        place.setTotalReviews(totalReviews);
        if (avgRating != null) {
            place.setAverageRating(BigDecimal.valueOf(avgRating).setScale(1, RoundingMode.HALF_UP));
        } else {
            place.setAverageRating(BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP));
        }
        placeRepository.save(place);

        log.info("Review {} submitted for place {}. Recalculated rating: {}, totalReviews: {}",
                savedReview.getId(), placeId, place.getAverageRating(), place.getTotalReviews());

        return ReviewResponse.from(savedReview);
    }
}

