package com.smartplanner.repository;

import com.smartplanner.entity.ItineraryItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Spring Data JPA Repository for ItineraryItem entities.
 */
@Repository
public interface ItineraryItemRepository extends JpaRepository<ItineraryItem, UUID> {

    /**
     * Retrieve all items belonging to an itinerary ordered chronologically by day and sequence.
     *
     * @param itineraryId ID of the parent itinerary
     * @return ordered list of ItineraryItem entities
     */
    @Query("SELECT it FROM ItineraryItem it " +
           "JOIN FETCH it.place " +
           "WHERE it.itinerary.id = :itineraryId " +
           "ORDER BY it.dayNumber ASC, it.orderIndex ASC")
    List<ItineraryItem> findByItineraryIdWithPlace(@Param("itineraryId") UUID itineraryId);

    /**
     * Delete all items for a given itinerary.
     *
     * @param itineraryId ID of the itinerary
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM ItineraryItem it WHERE it.itinerary.id = :itineraryId")
    void deleteByItineraryId(@Param("itineraryId") UUID itineraryId);
}
