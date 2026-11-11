package com.smartplanner.service;

import com.smartplanner.dto.request.ItineraryItemRequest;
import com.smartplanner.dto.request.ItineraryRequest;
import com.smartplanner.dto.response.ItineraryResponse;
import com.smartplanner.dto.response.ItinerarySummaryResponse;
import com.smartplanner.entity.Itinerary;
import com.smartplanner.entity.ItineraryItem;
import com.smartplanner.entity.Place;
import com.smartplanner.entity.User;
import com.smartplanner.exception.ForbiddenException;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.ItineraryRepository;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.security.ItinerarySecurityService;
import com.smartplanner.service.impl.ItineraryServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("ItineraryService Unit Tests")
class ItineraryServiceTest {

    @Mock
    private ItineraryRepository itineraryRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PlaceRepository placeRepository;

    @Mock
    private ItinerarySecurityService itinerarySecurityService;

    @InjectMocks
    private ItineraryServiceImpl itineraryService;

    private UUID userId;
    private UUID otherUserId;
    private UUID itineraryId;
    private UUID placeId;
    private User testUser;
    private Place testPlace;
    private Itinerary testItinerary;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        otherUserId = UUID.randomUUID();
        itineraryId = UUID.randomUUID();
        placeId = UUID.randomUUID();

        testUser = User.builder()
                .id(userId)
                .email("traveler@example.com")
                .fullName("Traveler")
                .build();

        testPlace = Place.builder()
                .id(placeId)
                .name("Landmark 81")
                .category("CAFE")
                .address("Binh Thanh, HCMC")
                .latitude(10.7951)
                .longitude(106.7218)
                .priceLevel(2)
                .build();

        testItinerary = Itinerary.builder()
                .id(itineraryId)
                .user(testUser)
                .title("Saigon Trip")
                .description("Highlights")
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 11, 22))
                .isPublic(false)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .items(new ArrayList<>())
                .build();
    }

    @Test
    @DisplayName("getUserItineraries returns paginated summary response successfully")
    void getUserItineraries_Success() {
        Pageable pageable = PageRequest.of(0, 10);
        when(userRepository.existsById(userId)).thenReturn(true);
        when(itineraryRepository.findByUserId(userId, pageable))
                .thenReturn(new PageImpl<>(List.of(testItinerary), pageable, 1));

        Page<ItinerarySummaryResponse> result = itineraryService.getUserItineraries(userId, pageable);

        assertThat(result).isNotNull();
        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getTitle()).isEqualTo("Saigon Trip");
        assertThat(result.getContent().get(0).getTotalDays()).isEqualTo(3);
    }

    @Test
    @DisplayName("getUserItineraries throws ResourceNotFoundException when user does not exist")
    void getUserItineraries_UserNotFound() {
        Pageable pageable = PageRequest.of(0, 10);
        when(userRepository.existsById(userId)).thenReturn(false);

        assertThatThrownBy(() -> itineraryService.getUserItineraries(userId, pageable))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("User not found with id: " + userId);
    }

    @Test
    @DisplayName("getItineraryDetail returns full schedule and place details successfully")
    void getItineraryDetail_Success() {
        ItineraryItem item = ItineraryItem.builder()
                .id(UUID.randomUUID())
                .itinerary(testItinerary)
                .place(testPlace)
                .dayNumber(1)
                .orderIndex(0)
                .startTime(LocalTime.of(9, 0))
                .notes("Morning coffee")
                .build();
        testItinerary.addItem(item);

        when(itineraryRepository.findByIdWithItemsAndPlaces(itineraryId))
                .thenReturn(Optional.of(testItinerary));
        doNothing().when(itinerarySecurityService).validateOwnership(testItinerary, userId);

        ItineraryResponse response = itineraryService.getItineraryDetail(itineraryId, userId);

        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(itineraryId);
        assertThat(response.getTitle()).isEqualTo("Saigon Trip");
        assertThat(response.getItems()).hasSize(1);
        assertThat(response.getItems().get(0).getPlace().getName()).isEqualTo("Landmark 81");
    }

    @Test
    @DisplayName("getItineraryDetail throws ResourceNotFoundException when itinerary does not exist")
    void getItineraryDetail_NotFound() {
        when(itineraryRepository.findByIdWithItemsAndPlaces(itineraryId))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> itineraryService.getItineraryDetail(itineraryId, userId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Itinerary not found with id: " + itineraryId);
    }

    @Test
    @DisplayName("getItineraryDetail throws ForbiddenException when accessed by non-owner")
    void getItineraryDetail_Forbidden() {
        when(itineraryRepository.findByIdWithItemsAndPlaces(itineraryId))
                .thenReturn(Optional.of(testItinerary));
        doThrow(new ForbiddenException("You do not possess permission to access or modify this itinerary."))
                .when(itinerarySecurityService).validateOwnership(testItinerary, otherUserId);

        assertThatThrownBy(() -> itineraryService.getItineraryDetail(itineraryId, otherUserId))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("permission");
    }

    @Test
    @DisplayName("createItinerary creates and persists new itinerary with items successfully")
    void createItinerary_WithItems_Success() {
        ItineraryItemRequest itemReq = ItineraryItemRequest.builder()
                .placeId(placeId)
                .dayNumber(1)
                .orderIndex(0)
                .startTime(LocalTime.of(9, 30))
                .notes("Explore Landmark 81")
                .build();

        ItineraryRequest request = ItineraryRequest.builder()
                .title("Weekend Escape")
                .description("Relaxing weekend")
                .startDate(LocalDate.of(2026, 11, 21))
                .endDate(LocalDate.of(2026, 11, 22))
                .items(List.of(itemReq))
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(placeRepository.findById(placeId)).thenReturn(Optional.of(testPlace));
        when(itineraryRepository.save(any(Itinerary.class))).thenAnswer(invocation -> {
            Itinerary saved = invocation.getArgument(0);
            saved.setId(itineraryId);
            return saved;
        });

        ItineraryResponse response = itineraryService.createItinerary(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.getTitle()).isEqualTo("Weekend Escape");
        assertThat(response.getItems()).hasSize(1);
        assertThat(response.getItems().get(0).getNotes()).isEqualTo("Explore Landmark 81");
    }

    @Test
    @DisplayName("createItinerary throws IllegalArgumentException when endDate is prior to startDate")
    void createItinerary_InvalidDates_ThrowsException() {
        ItineraryRequest request = ItineraryRequest.builder()
                .title("Invalid Date Trip")
                .startDate(LocalDate.of(2026, 11, 25))
                .endDate(LocalDate.of(2026, 11, 20))
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));

        assertThatThrownBy(() -> itineraryService.createItinerary(userId, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("End date cannot be prior to start date.");
    }

    @Test
    @DisplayName("updateItinerary executes atomic full-schedule replacement")
    void updateItinerary_AtomicReplacement_Success() {
        ItineraryItem oldItem = ItineraryItem.builder()
                .id(UUID.randomUUID())
                .itinerary(testItinerary)
                .place(testPlace)
                .dayNumber(1)
                .orderIndex(0)
                .notes("Old Schedule")
                .build();
        testItinerary.addItem(oldItem);

        UUID newPlaceId = UUID.randomUUID();
        Place newPlace = Place.builder()
                .id(newPlaceId)
                .name("Notre Dame Cathedral")
                .category("CULTURE")
                .build();

        ItineraryItemRequest newItemReq = ItineraryItemRequest.builder()
                .placeId(newPlaceId)
                .dayNumber(1)
                .orderIndex(0)
                .startTime(LocalTime.of(14, 0))
                .notes("New Schedule Item")
                .build();

        ItineraryRequest updateRequest = ItineraryRequest.builder()
                .title("Updated Saigon Highlights")
                .description("Updated description")
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 11, 22))
                .items(List.of(newItemReq))
                .build();

        when(itineraryRepository.findByIdWithItemsAndPlaces(itineraryId))
                .thenReturn(Optional.of(testItinerary));
        doNothing().when(itinerarySecurityService).validateOwnership(testItinerary, userId);
        when(placeRepository.findById(newPlaceId)).thenReturn(Optional.of(newPlace));
        when(itineraryRepository.save(any(Itinerary.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ItineraryResponse response = itineraryService.updateItinerary(itineraryId, userId, updateRequest);

        assertThat(response).isNotNull();
        assertThat(response.getTitle()).isEqualTo("Updated Saigon Highlights");
        assertThat(response.getItems()).hasSize(1);
        assertThat(response.getItems().get(0).getNotes()).isEqualTo("New Schedule Item");
        assertThat(response.getItems().get(0).getPlace().getName()).isEqualTo("Notre Dame Cathedral");
    }

    @Test
    @DisplayName("deleteItinerary deletes successfully when user is owner")
    void deleteItinerary_Success() {
        when(itineraryRepository.findById(itineraryId)).thenReturn(Optional.of(testItinerary));
        doNothing().when(itinerarySecurityService).validateOwnership(testItinerary, userId);

        itineraryService.deleteItinerary(itineraryId, userId);

        verify(itineraryRepository).delete(testItinerary);
    }
}
