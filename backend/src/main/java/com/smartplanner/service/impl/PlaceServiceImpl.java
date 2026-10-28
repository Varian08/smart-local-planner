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
import java.util.Set;
import java.util.UUID;

/**
 * Production-ready implementation of PlaceService.
 * Handles dynamic querying, pagination, and entity-to-DTO mapping.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PlaceServiceImpl implements PlaceService {

    private static final Set<String> ALLOWED_SORT_FIELDS = Set.of(
            "averageRating",
            "name",
            "priceLevel",
            "createdAt",
            "totalReviews"
    );

    private final PlaceRepository placeRepository;

    @Override
    public Page<PlaceResponse> getPlaces(PlaceFilterRequest request) {
        // 1. Defensively validate and sanitize pagination arguments (max size 50)
        int page = (request.getPage() != null && request.getPage() >= 0) ? request.getPage() : 0;
        int rawSize = (request.getSize() != null && request.getSize() > 0) ? request.getSize() : 10;
        int size = Math.min(rawSize, 50);

        // 2. Parse and resolve sort parameters (supports 'sort=name,asc' or 'sortBy' / 'sortDirection')
        String requestedSortBy = request.getSortBy();
        Sort.Direction direction = "ASC".equalsIgnoreCase(request.getSortDirection())
                ? Sort.Direction.ASC : Sort.Direction.DESC;

        if (request.getSort() != null && !request.getSort().isBlank()) {
            String[] parts = request.getSort().split(",");
            requestedSortBy = parts[0].trim();
            if (parts.length > 1 && "asc".equalsIgnoreCase(parts[1].trim())) {
                direction = Sort.Direction.ASC;
            } else if (parts.length > 1 && "desc".equalsIgnoreCase(parts[1].trim())) {
                direction = Sort.Direction.DESC;
            }
        }

        // Whitelist sort fields to guarantee stability and prevent PropertyReferenceException
        String sortBy = "averageRating";
        if (requestedSortBy != null && ALLOWED_SORT_FIELDS.contains(requestedSortBy)) {
            sortBy = requestedSortBy;
        }

        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));

        // 3. Compose dynamic query predicates via JPA Specification
        Specification<Place> spec = Specification.where(PlaceSpecification.hasCategory(request.getCategory()))
                .and(PlaceSpecification.hasPriceLevel(request.getPriceLevel()))
                .and(PlaceSpecification.hasMinRating(request.getMinRating()))
                .and(PlaceSpecification.containsKeyword(request.getEffectiveKeyword()));

        // 4. Execute dynamic query and map Entities to immutable Response DTOs
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
