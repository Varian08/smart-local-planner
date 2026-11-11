package com.smartplanner.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Detailed response DTO for an itinerary including full schedule items and places.
 * Complies with docs/API_SPECIFICATION.md § 4.3.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Detailed response DTO for an itinerary including full schedule items")
public class ItineraryResponse {

    @Schema(description = "Unique UUID of the itinerary", example = "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33")
    private UUID id;

    @Schema(description = "Title of the itinerary", example = "Weekend in Saigon Highlights")
    private String title;

    @Schema(description = "Description or overview", example = "2-day discovery of iconic landmarks and coffee culture.")
    private String description;

    @JsonFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "Start date", example = "2026-10-24")
    private LocalDate startDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "End date", example = "2026-10-25")
    private LocalDate endDate;

    @Schema(description = "Total scheduled days", example = "2")
    private int totalDays;

    @Schema(description = "Total places in the schedule", example = "4")
    private int totalPlaces;

    @Schema(description = "Whether the itinerary is public", example = "false")
    private boolean isPublic;

    @Schema(description = "Full list of ordered schedule items")
    @Builder.Default
    private List<ItineraryItemResponse> items = new ArrayList<>();

    @Schema(description = "Creation timestamp")
    private OffsetDateTime createdAt;

    @Schema(description = "Last update timestamp")
    private OffsetDateTime updatedAt;
}
