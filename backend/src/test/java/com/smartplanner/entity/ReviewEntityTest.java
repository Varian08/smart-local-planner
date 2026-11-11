package com.smartplanner.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.OffsetDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Review Entity Unit Tests")
class ReviewEntityTest {

    @Test
    @DisplayName("Review entity creation and lifecycle callbacks populate timestamps")
    void review_LifecycleAndTimestamps() {
        User user = User.builder().id(UUID.randomUUID()).email("traveler@example.com").fullName("Traveler A").build();
        Place place = Place.builder().id(UUID.randomUUID()).name("Notre-Dame Cathedral Basilica").build();

        Review review = Review.builder()
                .user(user)
                .place(place)
                .rating(5)
                .comment("Stunning architecture and rich history.")
                .build();

        assertThat(review.getUser()).isEqualTo(user);
        assertThat(review.getPlace()).isEqualTo(place);
        assertThat(review.getRating()).isEqualTo(5);
        assertThat(review.getComment()).isEqualTo("Stunning architecture and rich history.");
        assertThat(review.getCreatedAt()).isNull();
        assertThat(review.getUpdatedAt()).isNull();

        review.onCreate();
        assertThat(review.getCreatedAt()).isNotNull();
        assertThat(review.getUpdatedAt()).isNotNull();

        OffsetDateTime initialUpdate = review.getUpdatedAt();
        review.onUpdate();
        assertThat(review.getUpdatedAt()).isAfterOrEqualTo(initialUpdate);
    }
}

