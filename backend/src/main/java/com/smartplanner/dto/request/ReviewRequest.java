package com.smartplanner.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Request payload for submitting a place review.
 * Complies with docs/API_SPECIFICATION.md § 5.2.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Request DTO for submitting a place review")
public class ReviewRequest {

    @NotNull(message = "Rating is required")
    @Min(value = 1, message = "Rating must be between 1 and 5")
    @Max(value = 5, message = "Rating must be between 1 and 5")
    @Schema(description = "Numeric star rating between 1 and 5", example = "5", minimum = "1", maximum = "5")
    private Integer rating;

    @Size(max = 1000, message = "Comment must not exceed 1000 characters")
    @Schema(description = "Optional traveler review comment or feedback", example = "Wonderful atmosphere and delicious signature coffee!")
    private String comment;
}

