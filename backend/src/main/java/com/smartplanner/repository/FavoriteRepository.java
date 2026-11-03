package com.smartplanner.repository;

import com.smartplanner.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Spring Data JPA Repository for Favorite entities.
 * Provides optimized database query methods with fetch joins to avoid N+1 queries.
 */
@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, UUID> {

    /**
     * Retrieve all favorites bookmarked by a user, eagerly fetching the associated Place
     * to eliminate N+1 select queries, sorted by bookmark creation timestamp descending.
     *
     * @param userId ID of the user
     * @return list of Favorite entities with Place loaded
     */
    @Query("SELECT f FROM Favorite f JOIN FETCH f.place WHERE f.user.id = :userId ORDER BY f.createdAt DESC")
    List<Favorite> findByUserIdWithPlaceOrderByCreatedAtDesc(@Param("userId") UUID userId);

    /**
     * Check if a favorite entry exists for a specific user and place combination.
     *
     * @param userId ID of the user
     * @param placeId ID of the place
     * @return true if bookmarked, false otherwise
     */
    boolean existsByUserIdAndPlaceId(UUID userId, UUID placeId);

    /**
     * Find a single favorite entry by user ID and place ID.
     *
     * @param userId ID of the user
     * @param placeId ID of the place
     * @return optional containing the Favorite entity if found
     */
    Optional<Favorite> findByUserIdAndPlaceId(UUID userId, UUID placeId);

    /**
     * Delete a favorite entry by user ID and place ID.
     *
     * @param userId ID of the user
     * @param placeId ID of the place
     */
    @Modifying
    @Query("DELETE FROM Favorite f WHERE f.user.id = :userId AND f.place.id = :placeId")
    void deleteByUserIdAndPlaceId(@Param("userId") UUID userId, @Param("placeId") UUID placeId);
}
