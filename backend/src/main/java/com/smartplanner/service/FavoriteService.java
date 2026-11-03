package com.smartplanner.service;

import com.smartplanner.dto.response.PlaceResponse;

import java.util.List;
import java.util.UUID;

/**
 * Service interface for Favorite business operations.
 * Defines the contract for managing user bookmarked favorite places.
 */
public interface FavoriteService {

    /**
     * Retrieve all favorite places bookmarked by a user.
     *
     * @param userId unique identifier of the user
     * @return list of PlaceResponse DTOs representing the favorited places
     */
    List<PlaceResponse> getUserFavorites(UUID userId);

    /**
     * Add a place to the user's favorites list.
     *
     * @param userId unique identifier of the user
     * @param placeId unique identifier of the place to bookmark
     */
    void addFavorite(UUID userId, UUID placeId);

    /**
     * Remove a place from the user's favorites list.
     *
     * @param userId unique identifier of the user
     * @param placeId unique identifier of the place to remove
     */
    void removeFavorite(UUID userId, UUID placeId);
}
