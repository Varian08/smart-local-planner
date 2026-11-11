package com.smartplanner.security;

import com.smartplanner.entity.Itinerary;
import com.smartplanner.entity.User;
import com.smartplanner.exception.ForbiddenException;
import com.smartplanner.exception.ResourceNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("ItinerarySecurityService Unit Tests")
class ItinerarySecurityServiceTest {

    private ItinerarySecurityService securityService;
    private UUID ownerId;
    private UUID otherUserId;
    private User owner;
    private Itinerary itinerary;

    @BeforeEach
    void setUp() {
        securityService = new ItinerarySecurityService();
        ownerId = UUID.randomUUID();
        otherUserId = UUID.randomUUID();

        owner = User.builder()
                .id(ownerId)
                .email("owner@example.com")
                .fullName("Itinerary Owner")
                .passwordHash("hashed")
                .build();

        itinerary = Itinerary.builder()
                .id(UUID.randomUUID())
                .user(owner)
                .title("Saigon Weekend Highlights")
                .build();
    }

    @Test
    @DisplayName("validateOwnership succeeds when authenticated user is the legitimate owner")
    void validateOwnership_Succeeds_WhenUserIsOwner() {
        assertThatCode(() -> securityService.validateOwnership(itinerary, ownerId))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("validateOwnership throws ForbiddenException (403) when user ID does not match owner")
    void validateOwnership_ThrowsForbiddenException_WhenUserIsNotOwner() {
        assertThatThrownBy(() -> securityService.validateOwnership(itinerary, otherUserId))
                .isInstanceOf(ForbiddenException.class)
                .hasMessage("You do not possess permission to access or modify this itinerary.");
    }

    @Test
    @DisplayName("validateOwnership throws ResourceNotFoundException (404) when itinerary is null")
    void validateOwnership_ThrowsResourceNotFoundException_WhenItineraryIsNull() {
        assertThatThrownBy(() -> securityService.validateOwnership(null, ownerId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Itinerary not found.");
    }

    @Test
    @DisplayName("isOwner returns true when user is owner and false otherwise")
    void isOwner_ReturnsCorrectBoolean() {
        assertThat(securityService.isOwner(itinerary, ownerId)).isTrue();
        assertThat(securityService.isOwner(itinerary, otherUserId)).isFalse();
        assertThat(securityService.isOwner(null, ownerId)).isFalse();
    }
}
