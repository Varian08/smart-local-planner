package com.smartplanner.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Data Transfer Object for Place responses.
 * Shields internal Entity structure from external consumers.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlaceResponse {

    private UUID id;
    private String name;
    private String description;
    private String category;
    private String address;
    private Double latitude;
    private Double longitude;
    private Integer priceLevel;
    private String openingHours;
    private String imageUrl;
    private BigDecimal averageRating;
    private Integer totalReviews;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
}
