package com.smartplanner.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * Request DTO encapsulating optional filtering, pagination, and sorting criteria for Places.
 * Aligned with docs/API_SPECIFICATION.md with defensive validation bounds.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlaceFilterRequest {

    // Filter criteria
    private String category;

    @Min(value = 1, message = "Price level must be at least 1")
    @Max(value = 4, message = "Price level must not exceed 4")
    private Integer priceLevel;

    private BigDecimal minRating;

    // Search query parameter matching API specification (e.g. ?query=cau+rong)
    private String query;

    // Legacy parameter preserved for backward compatibility
    private String keyword;

    // Pagination parameters with defensive bounds
    @Min(value = 0, message = "Page index must not be negative")
    @Builder.Default
    private Integer page = 0;

    @Min(value = 1, message = "Page size must be at least 1")
    @Max(value = 50, message = "Page size must not exceed 50")
    @Builder.Default
    private Integer size = 10;

    // Standard sort parameter matching API specification (e.g. ?sort=averageRating,desc)
    private String sort;

    // Explicit sort parameters for flexibility
    @Builder.Default
    private String sortBy = "averageRating";

    @Builder.Default
    private String sortDirection = "DESC";

    /**
     * Resolves the effective keyword search term from 'query' (preferred) or 'keyword'.
     */
    public String getEffectiveKeyword() {
        if (query != null && !query.isBlank()) {
            return query.trim();
        }
        if (keyword != null && !keyword.isBlank()) {
            return keyword.trim();
        }
        return null;
    }
}

