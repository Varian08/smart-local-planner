package com.smartplanner.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * Request DTO encapsulating optional filtering and pagination criteria for Places.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlaceFilterRequest {

    // Optional filter criteria
    private String category;
    private Integer priceLevel;
    private BigDecimal minRating;
    private String keyword;

    // Pagination and sorting parameters
    @Builder.Default
    private Integer page = 0;

    @Builder.Default
    private Integer size = 10;

    @Builder.Default
    private String sortBy = "averageRating";

    @Builder.Default
    private String sortDirection = "DESC";
}
