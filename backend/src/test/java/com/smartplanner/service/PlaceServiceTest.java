package com.smartplanner.service;

import com.smartplanner.dto.request.PlaceFilterRequest;
import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.entity.Place;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.service.impl.PlaceServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for PlaceService implementation.
 * Uses pure Mockito & JUnit 5 to ensure sub-second execution without starting Spring Context.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("PlaceService Unit Tests")
class PlaceServiceTest {

    @Mock
    private PlaceRepository placeRepository;

    @InjectMocks
    private PlaceServiceImpl placeService;

    private Place mockPlace;
    private UUID placeId;

    @BeforeEach
    void setUp() {
        placeId = UUID.randomUUID();
        mockPlace = Place.builder()
                .id(placeId)
                .name("Cầu Rồng")
                .description("Cây cầu biểu tượng với khả năng phun lửa và nước")
                .category("CULTURE")
                .address("Đường Nguyễn Văn Linh, Hải Châu, Đà Nẵng")
                .latitude(16.0611)
                .longitude(108.2272)
                .priceLevel(1)
                .openingHours("24/7 (Phun lửa 21:00 T7 & CN)")
                .imageUrl("https://images.unsplash.com/photo-bridge")
                .averageRating(BigDecimal.valueOf(4.8))
                .totalReviews(1250)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();
    }

    @Test
    @DisplayName("getPlaces() with valid filters should return paged PlaceResponse")
    void getPlaces_withValidFilters_returnsPagedPlaces() {
        // Given
        PlaceFilterRequest request = PlaceFilterRequest.builder()
                .category("CULTURE")
                .page(0)
                .size(10)
                .sortBy("averageRating")
                .sortDirection("DESC")
                .build();

        Page<Place> placePage = new PageImpl<>(List.of(mockPlace));
        when(placeRepository.findAll(any(Specification.class), any(Pageable.class))).thenReturn(placePage);

        // When
        Page<PlaceResponse> responsePage = placeService.getPlaces(request);

        // Then
        assertThat(responsePage).isNotNull();
        assertThat(responsePage.getContent()).hasSize(1);
        PlaceResponse response = responsePage.getContent().get(0);
        assertThat(response.getId()).isEqualTo(placeId);
        assertThat(response.getName()).isEqualTo("Cầu Rồng");
        assertThat(response.getCategory()).isEqualTo("CULTURE");

        verify(placeRepository, times(1)).findAll(any(Specification.class), any(Pageable.class));
    }

    @Test
    @DisplayName("getPlaceById() with existing ID should return mapped PlaceResponse")
    void getPlaceById_whenFound_returnsPlaceResponse() {
        // Given
        when(placeRepository.findById(placeId)).thenReturn(Optional.of(mockPlace));

        // When
        PlaceResponse response = placeService.getPlaceById(placeId);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(placeId);
        assertThat(response.getName()).isEqualTo("Cầu Rồng");
        assertThat(response.getAverageRating()).isEqualTo(BigDecimal.valueOf(4.8));

        verify(placeRepository, times(1)).findById(placeId);
    }

    @Test
    @DisplayName("getPlaceById() with non-existent ID should throw ResponseStatusException NOT_FOUND")
    void getPlaceById_whenNotFound_throwsResponseStatusException() {
        // Given
        UUID nonExistentId = UUID.randomUUID();
        when(placeRepository.findById(nonExistentId)).thenReturn(Optional.empty());

        // When & Then
        assertThatThrownBy(() -> placeService.getPlaceById(nonExistentId))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> {
                    ResponseStatusException rse = (ResponseStatusException) ex;
                    assertThat(rse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
                    assertThat(rse.getReason()).contains("Place not found with id: " + nonExistentId);
                });

        verify(placeRepository, times(1)).findById(nonExistentId);
    }

    @Test
    @DisplayName("getTopPlacesByCategory() should return list of top rated places with case-insensitive category")
    void getTopPlacesByCategory_returnsTopPlacesList() {
        // Given
        when(placeRepository.findTop5ByCategoryIgnoreCaseOrderByAverageRatingDesc("culture"))
                .thenReturn(List.of(mockPlace));

        // When (passing lowercase with whitespace to verify trimming and case-insensitivity)
        List<PlaceResponse> result = placeService.getTopPlacesByCategory("  culture  ");

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Cầu Rồng");

        verify(placeRepository, times(1)).findTop5ByCategoryIgnoreCaseOrderByAverageRatingDesc("culture");
    }

    @Test
    @DisplayName("getTopPlacesByCategory() with null or blank category should return empty list")
    void getTopPlacesByCategory_withBlankCategory_returnsEmptyList() {
        assertThat(placeService.getTopPlacesByCategory(null)).isEmpty();
        assertThat(placeService.getTopPlacesByCategory("   ")).isEmpty();
    }

    @Test
    @DisplayName("getPlaces() with unwhitelisted sort field should safely fallback to averageRating")
    void getPlaces_withUnsafeSortField_safelyFallsBackToAverageRating() {
        // Given: client requests an arbitrary unwhitelisted field
        PlaceFilterRequest request = PlaceFilterRequest.builder()
                .sortBy("nonExistentField")
                .sortDirection("ASC")
                .build();

        Page<Place> placePage = new PageImpl<>(List.of(mockPlace));
        org.mockito.ArgumentCaptor<Pageable> pageableCaptor = org.mockito.ArgumentCaptor.forClass(Pageable.class);
        when(placeRepository.findAll(any(Specification.class), pageableCaptor.capture())).thenReturn(placePage);

        // When
        placeService.getPlaces(request);

        // Then: sort falls back to averageRating instead of throwing PropertyReferenceException
        Pageable capturedPageable = pageableCaptor.getValue();
        Sort.Order order = capturedPageable.getSort().getOrderFor("averageRating");
        assertThat(order).isNotNull();
        assertThat(order.getDirection()).isEqualTo(Sort.Direction.ASC);
    }

    @Test
    @DisplayName("getPlaces() with 'sort' parameter (e.g. name,asc) should parse field and direction")
    void getPlaces_withSortParameter_parsesFieldAndDirection() {
        // Given: client sends standard sort param per API spec
        PlaceFilterRequest request = PlaceFilterRequest.builder()
                .sort("name,asc")
                .build();

        Page<Place> placePage = new PageImpl<>(List.of(mockPlace));
        org.mockito.ArgumentCaptor<Pageable> pageableCaptor = org.mockito.ArgumentCaptor.forClass(Pageable.class);
        when(placeRepository.findAll(any(Specification.class), pageableCaptor.capture())).thenReturn(placePage);

        // When
        placeService.getPlaces(request);

        // Then
        Pageable capturedPageable = pageableCaptor.getValue();
        Sort.Order order = capturedPageable.getSort().getOrderFor("name");
        assertThat(order).isNotNull();
        assertThat(order.getDirection()).isEqualTo(Sort.Direction.ASC);
    }

    @Test
    @DisplayName("getPlaces() with excessive size should clamp defensively to 50")
    void getPlaces_withExcessiveSize_clampsToFifty() {
        // Given
        PlaceFilterRequest request = PlaceFilterRequest.builder()
                .size(1000)
                .build();

        Page<Place> placePage = new PageImpl<>(List.of(mockPlace));
        org.mockito.ArgumentCaptor<Pageable> pageableCaptor = org.mockito.ArgumentCaptor.forClass(Pageable.class);
        when(placeRepository.findAll(any(Specification.class), pageableCaptor.capture())).thenReturn(placePage);

        // When
        placeService.getPlaces(request);

        // Then
        Pageable capturedPageable = pageableCaptor.getValue();
        assertThat(capturedPageable.getPageSize()).isEqualTo(50);
    }

    @Test
    @DisplayName("PlaceFilterRequest resolves 'query' as effective keyword and preserves backward compatibility")
    void placeFilterRequest_resolvesEffectiveKeyword() {
        PlaceFilterRequest requestWithQuery = PlaceFilterRequest.builder().query("  Bà Nà  ").build();
        assertThat(requestWithQuery.getEffectiveKeyword()).isEqualTo("Bà Nà");

        PlaceFilterRequest requestWithKeyword = PlaceFilterRequest.builder().keyword("  Chợ Cồn  ").build();
        assertThat(requestWithKeyword.getEffectiveKeyword()).isEqualTo("Chợ Cồn");

        PlaceFilterRequest requestWithBoth = PlaceFilterRequest.builder().query("Sơn Trà").keyword("Old").build();
        assertThat(requestWithBoth.getEffectiveKeyword()).isEqualTo("Sơn Trà");
    }
}

