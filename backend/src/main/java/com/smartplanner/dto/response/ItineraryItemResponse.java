package com.smartplanner.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalTime;
import java.util.UUID;

/**
 * Response DTO representing an itinerary schedule item with nested Place details.
 * Complies with docs/API_SPECIFICATION.md § 4.3.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Response DTO representing an item in an itinerary with associated Place details")
public class ItineraryItemResponse {

    @Schema(description = "Unique UUID of the itinerary item", example = "d3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44")
    private UUID id;

    @Schema(description = "1-based day index", example = "1")
    private Integer dayNumber;

    @Schema(description = "0-based sequence order within the day", example = "0")
    private Integer orderIndex;

    @JsonFormat(pattern = "HH:mm:ss")
    @Schema(description = "Scheduled arrival or start time", example = "09:00:00")
    private LocalTime startTime;

    @Schema(description = "User notes for this visit", example = "Morning coffee meeting")
    private String notes;

    @Schema(description = "Associated place details")
    private PlaceResponse place;
}
