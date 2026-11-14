package com.smartplanner.dto;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.smartplanner.dto.request.ItineraryRequest;
import com.smartplanner.dto.response.ItineraryResponse;
import com.smartplanner.dto.response.ItinerarySummaryResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Itinerary DTO Jackson isPublic Contract Tests")
class ItineraryDtoJsonTest {

    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());
    }

    @Test
    @DisplayName("ItineraryRequest serializes and deserializes isPublic JSON field strictly as 'isPublic'")
    void itineraryRequest_JsonContract() throws Exception {
        ItineraryRequest request = ItineraryRequest.builder()
                .title("Trip to Da Nang")
                .isPublic(true)
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 11, 22))
                .build();

        String json = objectMapper.writeValueAsString(request);
        JsonNode jsonNode = objectMapper.readTree(json);

        assertThat(jsonNode.has("isPublic")).isTrue();
        assertThat(jsonNode.has("public")).isFalse();
        assertThat(jsonNode.get("isPublic").asBoolean()).isTrue();

        String incomingJson = """
                {
                    "title": "Trip to Da Nang",
                    "isPublic": true
                }
                """;
        ItineraryRequest deserialized = objectMapper.readValue(incomingJson, ItineraryRequest.class);
        assertThat(deserialized.isPublic()).isTrue();

        String incomingJsonFalse = """
                {
                    "title": "Trip to Da Nang",
                    "isPublic": false
                }
                """;
        ItineraryRequest deserializedFalse = objectMapper.readValue(incomingJsonFalse, ItineraryRequest.class);
        assertThat(deserializedFalse.isPublic()).isFalse();
    }

    @Test
    @DisplayName("ItineraryResponse serializes and deserializes isPublic JSON field strictly as 'isPublic'")
    void itineraryResponse_JsonContract() throws Exception {
        ItineraryResponse response = ItineraryResponse.builder()
                .id(UUID.randomUUID())
                .title("Da Nang Tour")
                .isPublic(true)
                .totalDays(2)
                .totalPlaces(4)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        String json = objectMapper.writeValueAsString(response);
        JsonNode jsonNode = objectMapper.readTree(json);

        assertThat(jsonNode.has("isPublic")).isTrue();
        assertThat(jsonNode.has("public")).isFalse();
        assertThat(jsonNode.get("isPublic").asBoolean()).isTrue();

        String incomingJson = """
                {
                    "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
                    "title": "Da Nang Tour",
                    "isPublic": true
                }
                """;
        ItineraryResponse deserialized = objectMapper.readValue(incomingJson, ItineraryResponse.class);
        assertThat(deserialized.isPublic()).isTrue();
    }

    @Test
    @DisplayName("ItinerarySummaryResponse serializes and deserializes isPublic JSON field strictly as 'isPublic'")
    void itinerarySummaryResponse_JsonContract() throws Exception {
        ItinerarySummaryResponse summary = ItinerarySummaryResponse.builder()
                .id(UUID.randomUUID())
                .title("Summary Tour")
                .isPublic(true)
                .totalDays(3)
                .totalPlaces(5)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        String json = objectMapper.writeValueAsString(summary);
        JsonNode jsonNode = objectMapper.readTree(json);

        assertThat(jsonNode.has("isPublic")).isTrue();
        assertThat(jsonNode.has("public")).isFalse();
        assertThat(jsonNode.get("isPublic").asBoolean()).isTrue();

        String incomingJson = """
                {
                    "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
                    "title": "Summary Tour",
                    "isPublic": true
                }
                """;
        ItinerarySummaryResponse deserialized = objectMapper.readValue(incomingJson, ItinerarySummaryResponse.class);
        assertThat(deserialized.isPublic()).isTrue();
    }
}
