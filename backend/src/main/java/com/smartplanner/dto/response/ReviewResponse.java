package com.smartplanner.dto.response;

import com.smartplanner.entity.Review;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Response DTO for a place review.
 * Complies with docs/API_SPECIFICATION.md § 5.1 and § 5.2.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Response DTO representing a place review")
public class ReviewResponse {

    @Schema(description = "Unique UUID of the review", example = "e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55")
    private UUID id;

    @Schema(description = "UUID of the authoring user", example = "a1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
    private UUID userId;

    @Schema(description = "Display name of the author", example = "Tran Thi B")
    private String authorName;

    @Schema(description = "Avatar URL of the author", example = "https://res.cloudinary.com/.../avatar.webp")
    private String authorAvatar;

    @Schema(description = "Star rating from 1 to 5", example = "5")
    private Integer rating;

    @Schema(description = "Traveler review feedback comment", example = "Wonderful atmosphere and delicious signature coffee!")
    private String comment;

    @Schema(description = "Timestamp when the review was submitted")
    private OffsetDateTime createdAt;

    /**
     * Map a Review JPA entity to ReviewResponse DTO defensively.
     */
    public static ReviewResponse from(Review review) {
        if (review == null) {
            return null;
        }

        UUID authorId = null;
        String authorName = null;
        String authorAvatar = null;

        if (review.getUser() != null) {
            authorId = review.getUser().getId();
            authorName = review.getUser().getFullName();
            authorAvatar = review.getUser().getAvatarUrl();
        }

        return ReviewResponse.builder()
                .id(review.getId())
                .userId(authorId)
                .authorName(authorName)
                .authorAvatar(authorAvatar)
                .rating(review.getRating())
                .comment(review.getComment())
                .createdAt(review.getCreatedAt())
                .build();
    }
}

