package com.smartplanner.service.impl;

import com.smartplanner.dto.request.PlaceFilterRequest;
import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.entity.Place;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.service.PlaceService;
import com.smartplanner.specification.PlaceSpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

/**
 * Production-ready implementation of PlaceService.
 * Handles dynamic querying, pagination, and entity-to-DTO mapping.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PlaceServiceImpl implements PlaceService {

    private final PlaceRepository placeRepository;

    @Override
    public Page<PlaceResponse> getPlaces(PlaceFilterRequest request) {
        // 1. Defensively validate and sanitize pagination & sorting arguments
        int page = (request.getPage() != null && request.getPage() >= 0) ? request.getPage() : 0;
        int size = (request.getSize() != null && request.getSize() > 0) ? request.getSize() : 10;

        Sort.Direction direction = "ASC".equalsIgnoreCase(request.getSortDirection())
                ? Sort.Direction.ASC : Sort.Direction.DESC;

        // Whitelist sort fields to ensure SQL query stability
        String sortBy = "averageRating";
        if (request.getSortBy() != null && !request.getSortBy().isBlank() && !"string".equalsIgnoreCase(request.getSortBy())) {
            sortBy = request.getSortBy();
        }

        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));

        // 2. Compose dynamic query predicates via JPA Specification
        Specification<Place> spec = Specification.where(PlaceSpecification.hasCategory(request.getCategory()))
                .and(PlaceSpecification.hasPriceLevel(request.getPriceLevel()))
                .and(PlaceSpecification.hasMinRating(request.getMinRating()))
                .and(PlaceSpecification.containsKeyword(request.getKeyword()));

        // 3. Execute dynamic query and map Entities to immutable Response DTOs
        return placeRepository.findAll(spec, pageable).map(this::mapToResponse);
    }

    @Override
    public PlaceResponse getPlaceById(UUID id) {
        Place place = placeRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Place not found with id: " + id
                ));
        return mapToResponse(place);
    }

    @Override
    public List<PlaceResponse> getTopPlacesByCategory(String category) {
        return placeRepository.findTop5ByCategoryOrderByAverageRatingDesc(category)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    /**
     * Map Place JPA Entity to PlaceResponse DTO.
     * Prevents internal persistence metadata from leaking to external clients.
     */
    private PlaceResponse mapToResponse(Place place) {
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
