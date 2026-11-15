package com.smartplanner.util;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * Shared utility for defensive pagination bounds and strict sort-parameter parsing.
 * Enforces property whitelisting, strict sort-direction validation, and deterministic tie-breaking.
 */
public final class PaginationUtils {

    public static final int MAX_PAGE_SIZE = 50;

    private PaginationUtils() {
        // Utility class
    }

    /**
     * Validate pagination parameters, cap page size at {@link #MAX_PAGE_SIZE}, and parse sort specification.
     *
     * @param page                  zero-based page index ({@code >= 0})
     * @param size                  requested page size ({@code >= 1}, capped at {@value #MAX_PAGE_SIZE})
     * @param sortParam             raw sort query string (e.g. {@code "createdAt,desc"})
     * @param defaultSortProperty   default property used when {@code sortParam} is null or blank
     * @param allowedSortProperties whitelist of permitted entity properties
     * @return validated {@link Pageable} with deterministic {@code id ASC} tie-breaker
     * @throws IllegalArgumentException if page/size bounds are invalid or sort field/direction is invalid
     */
    public static Pageable buildPageable(
            int page,
            int size,
            String sortParam,
            String defaultSortProperty,
            Set<String> allowedSortProperties
    ) {
        if (page < 0) {
            throw new IllegalArgumentException("Page index must not be negative.");
        }
        if (size < 1) {
            throw new IllegalArgumentException("Page size must be at least 1.");
        }

        int boundedSize = Math.min(size, MAX_PAGE_SIZE);
        Sort sort = parseSort(sortParam, defaultSortProperty, allowedSortProperties);
        return PageRequest.of(page, boundedSize, sort);
    }

    /**
     * Parse and validate a {@code property[,asc|desc]} sort expression against an explicit whitelist.
     * Appends a secondary {@code id ASC} order when sorting by any non-{@code id} field for stable pagination.
     */
    public static Sort parseSort(
            String sortParam,
            String defaultSortProperty,
            Set<String> allowedSortProperties
    ) {
        String property;
        Sort.Direction direction;

        if (sortParam == null || sortParam.isBlank()) {
            property = defaultSortProperty;
            direction = Sort.Direction.DESC;
        } else {
            String[] parts = sortParam.split(",", -1);
            if (parts.length > 2) {
                throw new IllegalArgumentException("Invalid sort format. Expected 'property[,asc|desc]'.");
            }

            property = parts[0].trim();
            if (property.isEmpty() || !allowedSortProperties.contains(property)) {
                List<String> sortedAllowed = allowedSortProperties.stream().sorted().toList();
                throw new IllegalArgumentException(
                        "Invalid sort property '" + property + "'. Allowed sort properties: " + sortedAllowed
                );
            }

            if (parts.length == 2) {
                String rawDirection = parts[1].trim();
                if ("asc".equalsIgnoreCase(rawDirection)) {
                    direction = Sort.Direction.ASC;
                } else if ("desc".equalsIgnoreCase(rawDirection)) {
                    direction = Sort.Direction.DESC;
                } else {
                    throw new IllegalArgumentException(
                            "Invalid sort direction '" + rawDirection + "'. Allowed directions: asc, desc."
                    );
                }
            } else {
                direction = Sort.Direction.DESC;
            }
        }

        List<Sort.Order> orders = new ArrayList<>();
        orders.add(new Sort.Order(direction, property));
        if (!"id".equals(property)) {
            orders.add(Sort.Order.asc("id"));
        }
        return Sort.by(orders);
    }
}
