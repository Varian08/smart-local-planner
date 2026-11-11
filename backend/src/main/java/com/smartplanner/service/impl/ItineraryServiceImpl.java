package com.smartplanner.service.impl;

import com.smartplanner.dto.request.ItineraryItemRequest;
import com.smartplanner.dto.request.ItineraryRequest;
import com.smartplanner.dto.response.ItineraryItemResponse;
import com.smartplanner.dto.response.ItineraryResponse;
import com.smartplanner.dto.response.ItinerarySummaryResponse;
import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.entity.Itinerary;
import com.smartplanner.entity.ItineraryItem;
import com.smartplanner.entity.Place;
import com.smartplanner.entity.User;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.ItineraryRepository;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.security.ItinerarySecurityService;
import com.smartplanner.service.ItineraryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

/**
 * Implementation of ItineraryService managing personal multi-day schedules.
 * Enforces ownership access control and atomic schedule replacement.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class ItineraryServiceImpl implements ItineraryService {

    private final ItineraryRepository itineraryRepository;
    private final UserRepository userRepository;
    private final PlaceRepository placeRepository;
    private final ItinerarySecurityService itinerarySecurityService;

    @Override
    public Page<ItinerarySummaryResponse> getUserItineraries(UUID userId, Pageable pageable) {
        if (!userRepository.existsById(userId)) {
            log.warn("Itineraries retrieval rejected: User not found with id: {}", userId);
            throw new ResourceNotFoundException("User not found with id: " + userId);
        }

        Page<Itinerary> page = itineraryRepository.findByUserId(userId, pageable);
        log.debug("Found {} itineraries on page {} for user {}",
                page.getNumberOfElements(), page.getNumber(), userId);

        return page.map(this::mapToSummaryResponse);
    }

    @Override
    public ItineraryResponse getItineraryDetail(UUID id, UUID currentUserId) {
        Itinerary itinerary = itineraryRepository.findByIdWithItemsAndPlaces(id)
                .orElseThrow(() -> {
                    log.warn("Itinerary detail retrieval rejected: Itinerary not found with id: {}", id);
                    return new ResourceNotFoundException("Itinerary not found with id: " + id);
                });

        itinerarySecurityService.validateOwnership(itinerary, currentUserId);
        log.debug("Itinerary {} detail successfully retrieved by owner {}", id, currentUserId);

        return mapToDetailResponse(itinerary);
    }

    @Override
    @Transactional
    public ItineraryResponse createItinerary(UUID userId, ItineraryRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> {
                    log.warn("Itinerary creation rejected: User not found with id: {}", userId);
                    return new ResourceNotFoundException("User not found with id: " + userId);
                });

        validateDates(request.getStartDate(), request.getEndDate());

        Itinerary itinerary = Itinerary.builder()
                .user(user)
                .title(request.getTitle().trim())
                .description(request.getDescription())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .isPublic(request.isPublic())
                .build();

        if (request.getItems() != null && !request.getItems().isEmpty()) {
            for (ItineraryItemRequest itemReq : request.getItems()) {
                Place place = placeRepository.findById(itemReq.getPlaceId())
                        .orElseThrow(() -> {
                            log.warn("Itinerary creation item rejected: Place not found with id: {}", itemReq.getPlaceId());
                            return new ResourceNotFoundException("Place not found with id: " + itemReq.getPlaceId());
                        });

                ItineraryItem item = ItineraryItem.builder()
                        .place(place)
                        .dayNumber(itemReq.getDayNumber())
                        .orderIndex(itemReq.getOrderIndex())
                        .startTime(itemReq.getStartTime())
                        .notes(itemReq.getNotes())
                        .build();

                itinerary.addItem(item);
            }
        }

        Itinerary saved = itineraryRepository.save(itinerary);
        log.info("Itinerary {} created with {} items by user {}",
                saved.getId(), saved.getItems().size(), userId);

        return mapToDetailResponse(saved);
    }

    @Override
    @Transactional
    public ItineraryResponse updateItinerary(UUID id, UUID currentUserId, ItineraryRequest request) {
        Itinerary itinerary = itineraryRepository.findByIdWithItemsAndPlaces(id)
                .orElseThrow(() -> {
                    log.warn("Itinerary update rejected: Itinerary not found with id: {}", id);
                    return new ResourceNotFoundException("Itinerary not found with id: " + id);
                });

        itinerarySecurityService.validateOwnership(itinerary, currentUserId);
        validateDates(request.getStartDate(), request.getEndDate());

        itinerary.setTitle(request.getTitle().trim());
        itinerary.setDescription(request.getDescription());
        itinerary.setStartDate(request.getStartDate());
        itinerary.setEndDate(request.getEndDate());
        itinerary.setPublic(request.isPublic());

        // Atomic full-schedule replacement
        itinerary.clearItems();

        if (request.getItems() != null && !request.getItems().isEmpty()) {
            for (ItineraryItemRequest itemReq : request.getItems()) {
                Place place = placeRepository.findById(itemReq.getPlaceId())
                        .orElseThrow(() -> {
                            log.warn("Itinerary update item rejected: Place not found with id: {}", itemReq.getPlaceId());
                            return new ResourceNotFoundException("Place not found with id: " + itemReq.getPlaceId());
                        });

                ItineraryItem item = ItineraryItem.builder()
                        .place(place)
                        .dayNumber(itemReq.getDayNumber())
                        .orderIndex(itemReq.getOrderIndex())
                        .startTime(itemReq.getStartTime())
                        .notes(itemReq.getNotes())
                        .build();

                itinerary.addItem(item);
            }
        }

        Itinerary updated = itineraryRepository.save(itinerary);
        log.info("Itinerary {} atomically updated with {} items by owner {}",
                id, updated.getItems().size(), currentUserId);

        return mapToDetailResponse(updated);
    }

    @Override
    @Transactional
    public void deleteItinerary(UUID id, UUID currentUserId) {
        Itinerary itinerary = itineraryRepository.findById(id)
                .orElseThrow(() -> {
                    log.warn("Itinerary deletion rejected: Itinerary not found with id: {}", id);
                    return new ResourceNotFoundException("Itinerary not found with id: " + id);
                });

        itinerarySecurityService.validateOwnership(itinerary, currentUserId);

        itineraryRepository.delete(itinerary);
        log.info("Itinerary {} successfully deleted by owner {}", id, currentUserId);
    }

    private void validateDates(LocalDate startDate, LocalDate endDate) {
        if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
            throw new IllegalArgumentException("End date cannot be prior to start date.");
        }
    }

    private int calculateTotalDays(Itinerary itinerary) {
        if (itinerary.getStartDate() != null && itinerary.getEndDate() != null) {
            long days = ChronoUnit.DAYS.between(itinerary.getStartDate(), itinerary.getEndDate()) + 1;
            return (int) Math.max(1, days);
        }
        if (itinerary.getItems() != null && !itinerary.getItems().isEmpty()) {
            return itinerary.getItems().stream()
                    .mapToInt(ItineraryItem::getDayNumber)
                    .max()
                    .orElse(1);
        }
        return 1;
    }

    private int calculateTotalPlaces(Itinerary itinerary) {
        return itinerary.getItems() != null ? itinerary.getItems().size() : 0;
    }

    private ItinerarySummaryResponse mapToSummaryResponse(Itinerary itinerary) {
        return ItinerarySummaryResponse.builder()
                .id(itinerary.getId())
                .title(itinerary.getTitle())
                .description(itinerary.getDescription())
                .startDate(itinerary.getStartDate())
                .endDate(itinerary.getEndDate())
                .totalDays(calculateTotalDays(itinerary))
                .totalPlaces(calculateTotalPlaces(itinerary))
                .isPublic(itinerary.isPublic())
                .createdAt(itinerary.getCreatedAt())
                .updatedAt(itinerary.getUpdatedAt())
                .build();
    }

    private ItineraryResponse mapToDetailResponse(Itinerary itinerary) {
        List<ItineraryItemResponse> itemResponses = itinerary.getItems() != null
                ? itinerary.getItems().stream()
                    .map(this::mapToItemResponse)
                    .toList()
                : Collections.emptyList();

        return ItineraryResponse.builder()
                .id(itinerary.getId())
                .title(itinerary.getTitle())
                .description(itinerary.getDescription())
                .startDate(itinerary.getStartDate())
                .endDate(itinerary.getEndDate())
                .totalDays(calculateTotalDays(itinerary))
                .totalPlaces(itemResponses.size())
                .isPublic(itinerary.isPublic())
                .items(itemResponses)
                .createdAt(itinerary.getCreatedAt())
                .updatedAt(itinerary.getUpdatedAt())
                .build();
    }

    private ItineraryItemResponse mapToItemResponse(ItineraryItem item) {
        return ItineraryItemResponse.builder()
                .id(item.getId())
                .dayNumber(item.getDayNumber())
                .orderIndex(item.getOrderIndex())
                .startTime(item.getStartTime())
                .notes(item.getNotes())
                .place(mapToPlaceResponse(item.getPlace()))
                .build();
    }

    private PlaceResponse mapToPlaceResponse(Place place) {
        if (place == null) {
            return null;
        }
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
