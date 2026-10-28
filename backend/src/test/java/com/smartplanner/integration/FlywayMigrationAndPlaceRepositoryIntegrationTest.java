package com.smartplanner.integration;

import com.smartplanner.entity.Place;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.specification.PlaceSpecification;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * End-to-End Integration Test Harness executing against a real PostgreSQL 16 instance.
 * Validates Flyway database migrations (V1, V2, V3) and dynamic JPA Specifications.
 *
 * Configured with disabledWithoutDocker = true to gracefully skip on developer machines
 * where Docker daemon is inactive while strictly executing inside CI Ubuntu runners.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers(disabledWithoutDocker = true)
@DisplayName("Flyway Migrations and PlaceRepository Integration Test (PostgreSQL)")
class FlywayMigrationAndPlaceRepositoryIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private PlaceRepository placeRepository;

    @Test
    @DisplayName("Verify Flyway migrations V1, V2, V3 executed cleanly and seed places exist")
    void verifyMigrationsAndSeedData() {
        List<Place> places = placeRepository.findAll();
        assertThat(places).isNotEmpty();
        assertThat(places.size()).isGreaterThanOrEqualTo(7);

        // Verify Cầu Rồng was seeded and contains expected attributes
        Place dragonBridge = places.stream()
                .filter(p -> p.getName().contains("Cầu Rồng"))
                .findFirst()
                .orElse(null);
        assertThat(dragonBridge).isNotNull();
        assertThat(dragonBridge.getCategory()).isEqualTo("ATTRACTION");
        assertThat(dragonBridge.getAverageRating()).isGreaterThanOrEqualTo(BigDecimal.valueOf(4.5));

        // Verify V3 patch updated Bảo tàng Điêu khắc Chăm image URL
        Place chamMuseum = places.stream()
                .filter(p -> p.getName().contains("Bảo tàng Điêu khắc Chăm"))
                .findFirst()
                .orElse(null);
        assertThat(chamMuseum).isNotNull();
        assertThat(chamMuseum.getImageUrl()).contains("photo-1582555172866-f73bb12a2ab3");
    }

    @Test
    @DisplayName("Verify PlaceSpecification dynamic query on PostgreSQL")
    void verifyPlaceSpecificationQueries() {
        // Query category CULTURE
        Specification<Place> cultureSpec = PlaceSpecification.hasCategory("CULTURE");
        Page<Place> culturePlaces = placeRepository.findAll(cultureSpec, PageRequest.of(0, 10));
        assertThat(culturePlaces.getContent()).isNotEmpty();
        assertThat(culturePlaces.getContent()).allMatch(p -> "CULTURE".equalsIgnoreCase(p.getCategory()));

        // Query keyword search matching accents and casing
        Specification<Place> keywordSpec = PlaceSpecification.containsKeyword("Cầu Rồng");
        Page<Place> searchResults = placeRepository.findAll(keywordSpec, PageRequest.of(0, 10));
        assertThat(searchResults.getContent()).isNotEmpty();
        assertThat(searchResults.getContent().get(0).getName()).contains("Cầu Rồng");

        // Verify keyword search with escaped wildcard characters (%) doesn't match all records or throw SQL error
        Specification<Place> wildcardSpec = PlaceSpecification.containsKeyword("%");
        Page<Place> wildcardResults = placeRepository.findAll(wildcardSpec, PageRequest.of(0, 10));
        assertThat(wildcardResults.getContent()).isEmpty();
    }

    @Test
    @DisplayName("Verify findTop5ByCategoryIgnoreCaseOrderByAverageRatingDesc executes case-insensitively on PostgreSQL")
    void verifyTopPlacesCaseInsensitive() {
        List<Place> cultureTopPlaces = placeRepository.findTop5ByCategoryIgnoreCaseOrderByAverageRatingDesc("culture");
        assertThat(cultureTopPlaces).isNotEmpty();
        assertThat(cultureTopPlaces).allMatch(p -> "CULTURE".equalsIgnoreCase(p.getCategory()));
    }
}

