package com.smartplanner.service.impl;

import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.entity.Favorite;
import com.smartplanner.entity.Place;
import com.smartplanner.entity.User;
import com.smartplanner.exception.DuplicateResourceException;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.FavoriteRepository;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Implementation of FavoriteService providing business logic for managing
 * personal favorite places, entity conversion, and defensive validations.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class FavoriteServiceImpl implements FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final UserRepository userRepository;
    private final PlaceRepository placeRepository;

    @Override
    public List<PlaceResponse> getUserFavorites(UUID userId) {
        if (!userRepository.existsById(userId)) {
            log.warn("Favorites retrieval rejected: User not found with id: {}", userId);
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }

        List<Favorite> favorites = favoriteRepository.findByUserIdWithPlaceOrderByCreatedAtDesc(userId);
        log.debug("Found {} favorites for user {}", favorites.size(), userId);

        return favorites.stream()
                .map(favorite -> mapToPlaceResponse(favorite.getPlace()))
                .toList();
    }

    @Override
    @Transactional
    public void addFavorite(UUID userId, UUID placeId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> {
                    log.warn("Add favorite rejected: User not found with id: {}", userId);
                    return new ResourceNotFoundException("User not found with id: " + userId);
                });

        Place place = placeRepository.findById(placeId)
                .orElseThrow(() -> {
                    log.warn("Add favorite rejected: Place not found with id: {}", placeId);
                    return new ResourceNotFoundException("Place not found with id: " + placeId);
                });

        if (favoriteRepository.existsByUserIdAndPlaceId(userId, placeId)) {
            log.warn("Add favorite rejected: Place {} is already favorited by user {}", placeId, userId);
            throw new DuplicateResourceException("Place is already in favorites.");
        }

        Favorite favorite = Favorite.builder()
                .user(user)
                .place(place)
                .build();

        favoriteRepository.save(favorite);
        log.info("Place {} successfully added to favorites for user {}", placeId, userId);
    }

    @Override
    @Transactional
    public void removeFavorite(UUID userId, UUID placeId) {
        if (!userRepository.existsById(userId)) {
            log.warn("Remove favorite rejected: User not found with id: {}", userId);
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }

        if (!favoriteRepository.existsByUserIdAndPlaceId(userId, placeId)) {
            log.warn("Remove favorite rejected: Favorite not found for user {} and place {}", userId, placeId);
            throw new ResourceNotFoundException("Favorite not found for place id: " + placeId);
        }

        favoriteRepository.deleteByUserIdAndPlaceId(userId, placeId);
        log.info("Place {} successfully removed from favorites for user {}", placeId, userId);
    }

    /**
     * Map Place JPA Entity to standard PlaceResponse DTO.
     */
    private PlaceResponse mapToPlaceResponse(Place place) {
        return PlaceResponse.builder()
                .id(place.getId())
                .name(place.getName())
                .description(place.getDescription())
                .category(place.getCategory())
                .address(place.getAddress())
                .latitude(place.getLatitude())
                .longitude(place.getLongitude())
                .priceLevel(place.getPriceLevel())
                .openingHours(place.getOpeningHours())
                .imageUrl(place.getImageUrl())
                .averageRating(place.getAverageRating())
                .totalReviews(place.getTotalReviews())
                .createdAt(place.getCreatedAt())
                .updatedAt(place.getUpdatedAt())
                .build();
    }
}

