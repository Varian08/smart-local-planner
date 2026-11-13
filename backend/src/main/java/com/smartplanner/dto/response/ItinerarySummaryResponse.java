package com.smartplanner.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Lightweight summary response DTO for paginated itinerary listings.
 * Complies with docs/API_SPECIFICATION.md § 4.1.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Summary DTO representing an itinerary in a paginated list")
public class ItinerarySummaryResponse {

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

    @JsonProperty("isPublic")
    @Schema(description = "Whether the itinerary is public", example = "false")
    private boolean isPublic;

    @Schema(description = "Creation timestamp")
    private OffsetDateTime createdAt;

    @Schema(description = "Last update timestamp")
    private OffsetDateTime updatedAt;

    @JsonProperty("isPublic")
    public boolean isPublic() {
        return isPublic;
    }

    @JsonProperty("isPublic")
    public void setPublic(boolean isPublic) {
        this.isPublic = isPublic;
    }
}
