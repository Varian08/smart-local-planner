package com.smartplanner.service;

import com.smartplanner.dto.request.ItineraryRequest;
import com.smartplanner.dto.response.ItineraryResponse;
import com.smartplanner.dto.response.ItinerarySummaryResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

/**
 * Service contract for managing multi-day personal travel itineraries.
 * Enforces ownership access rules and atomic schedule mutations.
 */
public interface ItineraryService {

    /**
     * Retrieve a paginated list of itinerary summaries owned by the specified user.
     *
     * @param userId ID of the user
     * @param pageable pagination parameters
     * @return page of ItinerarySummaryResponse DTOs
     */
    Page<ItinerarySummaryResponse> getUserItineraries(UUID userId, Pageable pageable);

    /**
     * Retrieve the detailed itinerary including full schedule items and place details.
     * Enforces ownership access control (403 FORBIDDEN_ACCESS on cross-tenant access).
     *
     * @param id ID of the itinerary
     * @param currentUserId ID of the authenticated user requesting access
     * @return ItineraryResponse with loaded schedule
     */
    ItineraryResponse getItineraryDetail(UUID id, UUID currentUserId);

    /**
     * Create a new itinerary with optional schedule items.
     *
     * @param userId ID of the creator
     * @param request payload containing title, dates, and items
     * @return created ItineraryResponse
     */
    ItineraryResponse createItinerary(UUID userId, ItineraryRequest request);

    /**
     * Update itinerary metadata and perform atomic full-schedule replacement.
     * Enforces ownership verification (403 FORBIDDEN_ACCESS).
     *
     * @param id ID of the itinerary to update
     * @param currentUserId ID of the authenticated user
     * @param request payload with updated metadata and schedule items
     * @return updated ItineraryResponse
     */
    ItineraryResponse updateItinerary(UUID id, UUID currentUserId, ItineraryRequest request);

    /**
     * Delete an itinerary and cascade-delete all its schedule items.
     * Enforces ownership verification (403 FORBIDDEN_ACCESS).
     *
     * @param id ID of the itinerary to delete
     * @param currentUserId ID of the authenticated user
     */
    void deleteItinerary(UUID id, UUID currentUserId);
}
