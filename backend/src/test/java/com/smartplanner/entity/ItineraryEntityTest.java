package com.smartplanner.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Itinerary & ItineraryItem Entity Unit Tests")
class ItineraryEntityTest {

    @Test
    @DisplayName("Itinerary entity creates and sets default items list")
    void itinerary_CreationAndDefaultList() {
        User user = User.builder().id(UUID.randomUUID()).email("user@example.com").fullName("User").build();

        Itinerary itinerary = Itinerary.builder()
                .title("Trip to Da Nang")
                .description("3-day beach and culinary journey")
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 11, 22))
                .user(user)
                .isPublic(false)
                .build();

        assertThat(itinerary.getTitle()).isEqualTo("Trip to Da Nang");
        assertThat(itinerary.getItems()).isNotNull().isEmpty();
        assertThat(itinerary.isPublic()).isFalse();

        itinerary.onCreate();
        assertThat(itinerary.getCreatedAt()).isNotNull();
        assertThat(itinerary.getUpdatedAt()).isNotNull();

        OffsetDateTime firstUpdate = itinerary.getUpdatedAt();
        itinerary.onUpdate();
        assertThat(itinerary.getUpdatedAt()).isAfterOrEqualTo(firstUpdate);
    }

    @Test
    @DisplayName("addItem, removeItem, and clearItems maintain bidirectional relationship integrity")
    void itinerary_BidirectionalItemHelpers() {
        Itinerary itinerary = Itinerary.builder()
                .id(UUID.randomUUID())
                .title("Saigon Discovery")
                .build();

        Place place = Place.builder()
                .id(UUID.randomUUID())
                .name("Ben Thanh Market")
                .address("District 1, HCMC")
                .category("MARKET")
                .priceLevel(2)
                .build();

        ItineraryItem item1 = ItineraryItem.builder()
                .place(place)
                .dayNumber(1)
                .orderIndex(0)
                .startTime(LocalTime.of(9, 0))
                .notes("Morning street food")
                .build();

        ItineraryItem item2 = ItineraryItem.builder()
                .place(place)
                .dayNumber(1)
                .orderIndex(1)
                .startTime(LocalTime.of(11, 30))
                .notes("Lunch")
                .build();

        itinerary.addItem(item1);
        itinerary.addItem(item2);

        assertThat(itinerary.getItems()).hasSize(2);
        assertThat(item1.getItinerary()).isSameAs(itinerary);
        assertThat(item2.getItinerary()).isSameAs(itinerary);

        itinerary.removeItem(item1);
        assertThat(itinerary.getItems()).hasSize(1);
        assertThat(item1.getItinerary()).isNull();

        itinerary.clearItems();
        assertThat(itinerary.getItems()).isEmpty();
        assertThat(item2.getItinerary()).isNull();
    }

    @Test
    @DisplayName("ItineraryItem entity initializes default values and PrePersist timestamp")
    void itineraryItem_CreationAndPrePersist() {
        ItineraryItem item = ItineraryItem.builder()
                .dayNumber(2)
                .orderIndex(1)
                .startTime(LocalTime.of(14, 0))
                .notes("Coffee break")
                .build();

        assertThat(item.getDayNumber()).isEqualTo(2);
        assertThat(item.getOrderIndex()).isEqualTo(1);
        assertThat(item.getStartTime()).isEqualTo(LocalTime.of(14, 0));
        assertThat(item.getNotes()).isEqualTo("Coffee break");

        item.onCreate();
        assertThat(item.getCreatedAt()).isNotNull();
    }
}
