package com.smartplanner.repository;

import com.smartplanner.entity.Itinerary;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Spring Data JPA Repository for Itinerary entities.
 * Provides optimized pagination and eager fetch-join queries eliminating N+1 queries.
 */
@Repository
public interface ItineraryRepository extends JpaRepository<Itinerary, UUID> {

    /**
     * Retrieve paginated personal itineraries owned by a user.
     *
     * @param userId ID of the user
     * @param pageable pagination parameters
     * @return page of Itinerary entities
     */
    Page<Itinerary> findByUserId(UUID userId, Pageable pageable);

    /**
     * Retrieve an itinerary by ID eagerly fetching all schedule items and linked places
     * in a single query, preventing N+1 queries under open-in-view: false policy.
     *
     * @param id ID of the itinerary
     * @return optional containing the Itinerary with items and places loaded
     */
    @Query("SELECT DISTINCT i FROM Itinerary i " +
           "LEFT JOIN FETCH i.items it " +
           "LEFT JOIN FETCH it.place " +
           "WHERE i.id = :id")
    Optional<Itinerary> findByIdWithItemsAndPlaces(@Param("id") UUID id);

    /**
     * Find an itinerary by ID and user ID for ownership-scoped lookups.
     *
     * @param id ID of the itinerary
     * @param userId ID of the user
     * @return optional containing the Itinerary if owned by user
     */
    Optional<Itinerary> findByIdAndUserId(UUID id, UUID userId);

    /**
     * Check if an itinerary with the given ID is owned by the specified user.
     *
     * @param id ID of the itinerary
     * @param userId ID of the user
     * @return true if exists and owned by user, false otherwise
     */
    boolean existsByIdAndUserId(UUID id, UUID userId);

    /**
     * Count total itineraries created by a user.
     *
     * @param userId ID of the user
     * @return total count
     */
    long countByUserId(UUID userId);
}
