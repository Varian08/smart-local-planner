package com.smartplanner.specification;

import com.smartplanner.entity.Place;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;

/**
 * Dynamic JPA Specifications for filtering Place entities.
 */
public final class PlaceSpecification {

    private PlaceSpecification() {
        // Private constructor to prevent instantiation of utility class
    }

    /**
     * Filter by category (case-insensitive).
     */
    public static Specification<Place> hasCategory(String category) {
        return (root, query, criteriaBuilder) -> {
            if (category == null || category.isBlank()) {
                return criteriaBuilder.conjunction(); // No predicate applied
            }
            return criteriaBuilder.equal(
                    criteriaBuilder.lower(root.get("category")),
                    category.trim().toLowerCase()
            );
        };
    }

    /**
     * Filter by price level (1 to 4).
     */
    public static Specification<Place> hasPriceLevel(Integer priceLevel) {
        return (root, query, criteriaBuilder) -> {
            if (priceLevel == null) {
                return criteriaBuilder.conjunction();
            }
            return criteriaBuilder.equal(root.get("priceLevel"), priceLevel);
        };
    }

    /**
     * Filter by minimum rating (averageRating >= minRating).
     */
    public static Specification<Place> hasMinRating(BigDecimal minRating) {
        return (root, query, criteriaBuilder) -> {
            if (minRating == null) {
                return criteriaBuilder.conjunction();
            }
            return criteriaBuilder.greaterThanOrEqualTo(root.get("averageRating"), minRating);
        };
    }

    /**
     * Search across name, address, and description using keyword.
     */
    public static Specification<Place> containsKeyword(String keyword) {
        return (root, query, criteriaBuilder) -> {
            if (keyword == null || keyword.isBlank()) {
                return criteriaBuilder.conjunction();
            }
            String pattern = "%" + keyword.trim().toLowerCase() + "%";
            return criteriaBuilder.or(
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("name")), pattern),
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("address")), pattern),
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("description")), pattern)
            );
        };
    }
}
