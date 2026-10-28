package com.smartplanner.controller;

import com.smartplanner.dto.request.PlaceFilterRequest;
import com.smartplanner.dto.response.PageResponse;
import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.service.PlaceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * REST Controller exposing Tourist Place endpoints.
 * Provides APIs for filtering, searching, detail retrieval, and top attractions.
 */
@RestController
@RequestMapping("/api/v1/places")
@RequiredArgsConstructor
@Tag(name = "Places", description = "Tourist Places Discovery & Search APIs")
public class PlaceController {

    // SOLID Dependency Inversion: Controller depends exclusively on PlaceService abstraction
    private final PlaceService placeService;

    /**
     * Search and filter places dynamically with pagination.
     * GET /api/v1/places?category=CULTURE&minRating=4.0&page=0&size=10
     */
    @GetMapping
    @Operation(summary = "Search places with dynamic filters and pagination")
    public ResponseEntity<PageResponse<PlaceResponse>> getPlaces(@ParameterObject @Valid PlaceFilterRequest filterRequest) {
        Page<PlaceResponse> places = placeService.getPlaces(filterRequest);
        return ResponseEntity.ok(PageResponse.from(places));
    }

    /**
     * Get details of a single place by its UUID.
     * GET /api/v1/places/{id}
     */
    @GetMapping("/{id}")
    @Operation(summary = "Get place details by unique ID")
    public ResponseEntity<PlaceResponse> getPlaceById(@PathVariable UUID id) {
        PlaceResponse place = placeService.getPlaceById(id);
        return ResponseEntity.ok(place);
    }

    /**
     * Get top-rated places in a specific category.
     * GET /api/v1/places/top?category=CULTURE
     */
    @GetMapping("/top")
    @Operation(summary = "Get top-rated places in a specific category")
    public ResponseEntity<List<PlaceResponse>> getTopPlacesByCategory(@RequestParam String category) {
        List<PlaceResponse> topPlaces = placeService.getTopPlacesByCategory(category);
        return ResponseEntity.ok(topPlaces);
    }
}
