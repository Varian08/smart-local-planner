package com.smartplanner.service;

import com.smartplanner.dto.request.PlaceFilterRequest;
import com.smartplanner.dto.response.PlaceResponse;
import org.springframework.data.domain.Page;

import java.util.List;
import java.util.UUID;

/**
 * Service interface for Place business operations.
 * Defines the contract for place discovery, filtering, and retrieval.
 */
public interface PlaceService {

    /**
     * Get paginated places matching dynamic search and filter criteria.
     */
    Page<PlaceResponse> getPlaces(PlaceFilterRequest request);

    /**
     * Get place details by its unique identifier.
     */
    PlaceResponse getPlaceById(UUID id);

    /**
     * Get top-rated places in a specific category.
     */
    List<PlaceResponse> getTopPlacesByCategory(String category);
}
