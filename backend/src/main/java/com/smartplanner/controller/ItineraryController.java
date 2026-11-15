package com.smartplanner.controller;

import com.smartplanner.dto.request.ItineraryRequest;
import com.smartplanner.dto.response.ItineraryResponse;
import com.smartplanner.dto.response.ItinerarySummaryResponse;
import com.smartplanner.dto.response.PageResponse;
import com.smartplanner.entity.User;
import com.smartplanner.service.ItineraryService;
import com.smartplanner.util.PaginationUtils;
import com.smartplanner.util.SecurityUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Set;
import java.util.UUID;

/**
 * REST controller managing personal multi-day itineraries for authenticated users.
 * Endpoints comply with docs/API_SPECIFICATION.md § 4.
 */
@RestController
@RequestMapping("/api/v1/itineraries")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Itineraries", description = "Personal Multi-Day Travel Planning APIs")
public class ItineraryController {

    private static final Set<String> ALLOWED_SORT_PROPERTIES = Set.of(
            "createdAt", "updatedAt", "title", "startDate", "endDate"
    );

    private final ItineraryService itineraryService;

    /**
     * Retrieve paginated itineraries owned by the currently authenticated user.
     * GET /api/v1/itineraries?page=0&size=10
     */
    @GetMapping
    @Operation(summary = "List personal itineraries with pagination")
    public ResponseEntity<PageResponse<ItinerarySummaryResponse>> getUserItineraries(
            @AuthenticationPrincipal User currentUser,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort
    ) {
        UUID userId = SecurityUtils.resolveUserId(currentUser);
        log.debug("GET /api/v1/itineraries requested by user {}", userId);

        Pageable pageable = PaginationUtils.buildPageable(
                page, size, sort, "createdAt", ALLOWED_SORT_PROPERTIES
        );
        Page<ItinerarySummaryResponse> pageResult = itineraryService.getUserItineraries(userId, pageable);

        return ResponseEntity.ok(PageResponse.from(pageResult));
    }

    /**
     * Retrieve detailed itinerary by ID with full schedule items and places.
     * GET /api/v1/itineraries/{id}
     */
    @GetMapping("/{id}")
    @Operation(summary = "Get itinerary details with schedule items")
    public ResponseEntity<ItineraryResponse> getItineraryDetail(
            @AuthenticationPrincipal User currentUser,
            @PathVariable UUID id
    ) {
        UUID userId = SecurityUtils.resolveUserId(currentUser);
        log.debug("GET /api/v1/itineraries/{} requested by user {}", id, userId);

        ItineraryResponse response = itineraryService.getItineraryDetail(id, userId);
        return ResponseEntity.ok(response);
    }

    /**
     * Create a new itinerary with optional schedule items.
     * POST /api/v1/itineraries
     */
    @PostMapping
    @Operation(summary = "Create a new multi-day itinerary")
    public ResponseEntity<ItineraryResponse> createItinerary(
            @AuthenticationPrincipal User currentUser,
            @Valid @RequestBody ItineraryRequest request
    ) {
        UUID userId = SecurityUtils.resolveUserId(currentUser);
        log.info("POST /api/v1/itineraries requested by user {} with title: {}", userId, request.getTitle());

        ItineraryResponse response = itineraryService.createItinerary(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Update itinerary metadata and perform atomic full-schedule replacement.
     * PUT /api/v1/itineraries/{id}
     */
    @PutMapping("/{id}")
    @Operation(summary = "Update itinerary metadata and replace schedule")
    public ResponseEntity<ItineraryResponse> updateItinerary(
            @AuthenticationPrincipal User currentUser,
            @PathVariable UUID id,
            @Valid @RequestBody ItineraryRequest request
    ) {
        UUID userId = SecurityUtils.resolveUserId(currentUser);
        log.info("PUT /api/v1/itineraries/{} requested by user {}", id, userId);

        ItineraryResponse response = itineraryService.updateItinerary(id, userId, request);
        return ResponseEntity.ok(response);
    }

    /**
     * Delete an itinerary and cascade-delete its items.
     * DELETE /api/v1/itineraries/{id}
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "Delete an itinerary")
    public ResponseEntity<Void> deleteItinerary(
            @AuthenticationPrincipal User currentUser,
            @PathVariable UUID id
    ) {
        UUID userId = SecurityUtils.resolveUserId(currentUser);
        log.info("DELETE /api/v1/itineraries/{} requested by user {}", id, userId);

        itineraryService.deleteItinerary(id, userId);
        return ResponseEntity.noContent().build();
    }
}
