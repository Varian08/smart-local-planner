package com.smartplanner.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("PaginationUtils Unit Tests")
class PaginationUtilsTest {

    private static final Set<String> ALLOWED = Set.of("createdAt", "rating", "title");

    @Test
    @DisplayName("buildPageable clamps excessive page size to MAX_PAGE_SIZE (50) and adds id ASC tie-breaker")
    void buildPageable_clampsMaxSizeAndAddsTieBreaker() {
        Pageable pageable = PaginationUtils.buildPageable(1, 500, "rating,asc", "createdAt", ALLOWED);

        assertThat(pageable.getPageNumber()).isEqualTo(1);
        assertThat(pageable.getPageSize()).isEqualTo(PaginationUtils.MAX_PAGE_SIZE);
        assertThat(pageable.getSort().getOrderFor("rating"))
                .extracting(Sort.Order::getDirection)
                .isEqualTo(Sort.Direction.ASC);
        assertThat(pageable.getSort().getOrderFor("id"))
                .extracting(Sort.Order::getDirection)
                .isEqualTo(Sort.Direction.ASC);
    }

    @Test
    @DisplayName("buildPageable uses default sort property and DESC when sortParam is blank")
    void buildPageable_withBlankSort_usesDefaultDesc() {
        Pageable pageable = PaginationUtils.buildPageable(0, 10, "   ", "createdAt", ALLOWED);

        assertThat(pageable.getSort().getOrderFor("createdAt"))
                .extracting(Sort.Order::getDirection)
                .isEqualTo(Sort.Direction.DESC);
        assertThat(pageable.getSort().getOrderFor("id"))
                .extracting(Sort.Order::getDirection)
                .isEqualTo(Sort.Direction.ASC);
    }

    @Test
    @DisplayName("buildPageable defaults direction to DESC when omitted (e.g. 'title')")
    void buildPageable_withoutDirection_defaultsToDesc() {
        Pageable pageable = PaginationUtils.buildPageable(0, 10, "title", "createdAt", ALLOWED);

        assertThat(pageable.getSort().getOrderFor("title"))
                .extracting(Sort.Order::getDirection)
                .isEqualTo(Sort.Direction.DESC);
    }

    @Test
    @DisplayName("buildPageable rejects negative page index")
    void buildPageable_withNegativePage_throwsIllegalArgumentException() {
        assertThatThrownBy(() -> PaginationUtils.buildPageable(-1, 10, "createdAt,desc", "createdAt", ALLOWED))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Page index must not be negative.");
    }

    @Test
    @DisplayName("buildPageable rejects non-positive page size")
    void buildPageable_withZeroSize_throwsIllegalArgumentException() {
        assertThatThrownBy(() -> PaginationUtils.buildPageable(0, 0, "createdAt,desc", "createdAt", ALLOWED))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Page size must be at least 1.");
    }

    @Test
    @DisplayName("buildPageable rejects unwhitelisted sort property with deterministic sorted allowlist")
    void buildPageable_withUnsafeProperty_throwsIllegalArgumentException() {
        assertThatThrownBy(() -> PaginationUtils.buildPageable(0, 10, "passwordHash,asc", "createdAt", ALLOWED))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid sort property 'passwordHash'. Allowed sort properties: [createdAt, rating, title]");
    }

    @Test
    @DisplayName("buildPageable rejects invalid or empty sort direction instead of silent fallback")
    void buildPageable_withInvalidDirection_throwsIllegalArgumentException() {
        assertThatThrownBy(() -> PaginationUtils.buildPageable(0, 10, "createdAt,sideways", "createdAt", ALLOWED))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Invalid sort direction 'sideways'");

        assertThatThrownBy(() -> PaginationUtils.buildPageable(0, 10, "createdAt,", "createdAt", ALLOWED))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Invalid sort direction ''");

        assertThatThrownBy(() -> PaginationUtils.buildPageable(0, 10, "createdAt,asc,extra", "createdAt", ALLOWED))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid sort format. Expected 'property[,asc|desc]'.");
    }
}
