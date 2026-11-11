package com.smartplanner.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalTime;
import java.util.UUID;

/**
 * Request payload for a schedule item within an itinerary.
 * Complies with docs/API_SPECIFICATION.md § 4.2.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Request DTO representing a scheduled visit to a place")
public class ItineraryItemRequest {

    @NotNull(message = "Place ID cannot be null")
    @Schema(description = "UUID of the place to visit", example = "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22")
    private UUID placeId;

    @NotNull(message = "Day number cannot be null")
    @Min(value = 1, message = "Day number must be at least 1")
    @Schema(description = "1-based day index of the itinerary", example = "1")
    private Integer dayNumber;

    @NotNull(message = "Order index cannot be null")
    @Min(value = 0, message = "Order index must be at least 0")
    @Schema(description = "0-based sequence index within the designated day", example = "0")
    private Integer orderIndex;

    @JsonFormat(pattern = "HH:mm:ss")
    @Schema(description = "Planned arrival or start time", example = "09:00:00")
    private LocalTime startTime;

    @Size(max = 500, message = "Notes must not exceed 500 characters")
    @Schema(description = "User notes or reminders for this visit", example = "Morning coffee meeting")
    private String notes;
}
