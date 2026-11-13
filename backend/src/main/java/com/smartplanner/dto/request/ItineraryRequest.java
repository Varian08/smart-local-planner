package com.smartplanner.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Request payload for creating or updating an itinerary.
 * Complies with docs/API_SPECIFICATION.md § 4.2 and § 4.4.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Request DTO for creating or updating a multi-day itinerary")
public class ItineraryRequest {

    @NotBlank(message = "Title cannot be blank")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    @Schema(description = "Title of the itinerary", example = "Weekend in Saigon Highlights")
    private String title;

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    @Schema(description = "Summary or description of the trip", example = "2-day discovery of iconic landmarks and coffee culture.")
    private String description;

    @JsonFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "Start date of the itinerary", example = "2026-10-24")
    private LocalDate startDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    @Schema(description = "End date of the itinerary", example = "2026-10-25")
    private LocalDate endDate;

    @JsonProperty("isPublic")
    @Schema(description = "Whether the itinerary is publicly discoverable (private in Sprint 3)", example = "false")
    @Builder.Default
    private boolean isPublic = false;

    @Valid
    @Schema(description = "Ordered list of places to visit across itinerary days")
    @Builder.Default
    private List<ItineraryItemRequest> items = new ArrayList<>();

    @JsonProperty("isPublic")
    public boolean isPublic() {
        return isPublic;
    }

    @JsonProperty("isPublic")
    public void setPublic(boolean isPublic) {
        this.isPublic = isPublic;
    }
}
