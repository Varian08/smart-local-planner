package com.smartplanner.repository;

import com.smartplanner.entity.Place;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Place Repository Interface.
 * Provides CRUD operations, pagination, and dynamic query capabilities.
 */
@Repository
public interface PlaceRepository extends JpaRepository<Place, UUID>, JpaSpecificationExecutor<Place> {

    /**
     * Find places by category with case-insensitive matching and pagination.
     */
    Page<Place> findByCategoryIgnoreCase(String category, Pageable pageable);

    /**
     * Find top 5 places in a category ordered by highest rating.
     */
    List<Place> findTop5ByCategoryOrderByAverageRatingDesc(String category);

    /**
     * Check if a place with this exact name already exists (case-insensitive).
     */
    boolean existsByNameIgnoreCase(String name);
}
