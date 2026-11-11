package com.smartplanner.repository;

import com.smartplanner.entity.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

/**
 * Spring Data JPA Repository for Review entity.
 * Provides paginated queries with eager fetch to eliminate N+1 overhead,
 * duplicate checks, and atomic rating aggregation queries.
 */
@Repository
public interface ReviewRepository extends JpaRepository<Review, UUID> {

    /**
     * Check if a specific user has already submitted a review for a place.
     */
    boolean existsByUserIdAndPlaceId(UUID userId, UUID placeId);

    /**
     * Retrieve paginated reviews for a given place with eager-fetched author details.
     * countQuery is explicitly specified to avoid invalid JOIN FETCH in the pagination count step.
     */
    @Query(
            value = "SELECT r FROM Review r JOIN FETCH r.user WHERE r.place.id = :placeId",
            countQuery = "SELECT COUNT(r) FROM Review r WHERE r.place.id = :placeId"
    )
    Page<Review> findByPlaceIdWithUser(@Param("placeId") UUID placeId, Pageable pageable);

    /**
     * Compute the arithmetic average of all review ratings for a specific place.
     * Returns null if no reviews exist for the place.
     */
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.place.id = :placeId")
    Double calculateAverageRatingByPlaceId(@Param("placeId") UUID placeId);

    /**
     * Count total reviews submitted for a specific place.
     */
    int countByPlaceId(UUID placeId);
}

