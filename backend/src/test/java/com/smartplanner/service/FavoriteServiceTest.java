package com.smartplanner.service;

import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.entity.Favorite;
import com.smartplanner.entity.Place;
import com.smartplanner.entity.User;
import com.smartplanner.exception.DuplicateResourceException;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.FavoriteRepository;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.impl.FavoriteServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("FavoriteService Unit Tests")
class FavoriteServiceTest {

    @Mock
    private FavoriteRepository favoriteRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PlaceRepository placeRepository;

    @InjectMocks
    private FavoriteServiceImpl favoriteService;

    private UUID userId;
    private UUID placeId;
    private User mockUser;
    private Place mockPlace;
    private Favorite mockFavorite;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        placeId = UUID.randomUUID();

        mockUser = User.builder()
                .id(userId)
                .email("traveler@example.com")
                .fullName("Passionate Traveler")
                .build();

        mockPlace = Place.builder()
                .id(placeId)
                .name("Dragon Bridge")
                .description("Iconic fire-breathing bridge in Da Nang")
                .category("CULTURE")
                .address("Nguyen Van Linh, Da Nang")
                .latitude(16.0611)
                .longitude(108.2272)
                .priceLevel(1)
                .openingHours("24/7")
                .imageUrl("https://example.com/bridge.jpg")
                .averageRating(BigDecimal.valueOf(4.8))
                .totalReviews(1500)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        mockFavorite = Favorite.builder()
                .id(UUID.randomUUID())
                .user(mockUser)
                .place(mockPlace)
                .createdAt(OffsetDateTime.now())
                .build();
    }

    @Test
    @DisplayName("getUserFavorites returns list of mapped PlaceResponse DTOs")
    void getUserFavorites_success_returnsListOfPlaceResponses() {
        when(userRepository.existsById(userId)).thenReturn(true);
        when(favoriteRepository.findByUserIdWithPlaceOrderByCreatedAtDesc(userId))
                .thenReturn(List.of(mockFavorite));

        List<PlaceResponse> responses = favoriteService.getUserFavorites(userId);

        assertThat(responses).hasSize(1);
        PlaceResponse placeResponse = responses.get(0);
        assertThat(placeResponse.getId()).isEqualTo(placeId);
        assertThat(placeResponse.getName()).isEqualTo("Dragon Bridge");
        assertThat(placeResponse.getCategory()).isEqualTo("CULTURE");
        assertThat(placeResponse.getAverageRating()).isEqualTo(BigDecimal.valueOf(4.8));

        verify(favoriteRepository).findByUserIdWithPlaceOrderByCreatedAtDesc(userId);
    }

    @Test
    @DisplayName("getUserFavorites when user does not exist throws ResourceNotFoundException")
    void getUserFavorites_whenUserNotFound_throwsNotFound() {
        when(userRepository.existsById(userId)).thenReturn(false);

        assertThatThrownBy(() -> favoriteService.getUserFavorites(userId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("User not found with id: " + userId);

        verify(favoriteRepository, never()).findByUserIdWithPlaceOrderByCreatedAtDesc(any());
    }

    @Test
    @DisplayName("addFavorite persists new favorite when user and place exist and not already favorited")
    void addFavorite_success() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(mockUser));
        when(placeRepository.findById(placeId)).thenReturn(Optional.of(mockPlace));
        when(favoriteRepository.existsByUserIdAndPlaceId(userId, placeId)).thenReturn(false);

        favoriteService.addFavorite(userId, placeId);

        ArgumentCaptor<Favorite> captor = ArgumentCaptor.forClass(Favorite.class);
        verify(favoriteRepository).save(captor.capture());
        Favorite saved = captor.getValue();
        assertThat(saved.getUser()).isEqualTo(mockUser);
        assertThat(saved.getPlace()).isEqualTo(mockPlace);
    }

    @Test
    @DisplayName("addFavorite when user not found throws ResourceNotFoundException")
    void addFavorite_whenUserNotFound_throwsNotFound() {
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> favoriteService.addFavorite(userId, placeId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("User not found with id: " + userId);

        verify(favoriteRepository, never()).save(any());
    }

    @Test
    @DisplayName("addFavorite when place not found throws ResourceNotFoundException")
    void addFavorite_whenPlaceNotFound_throwsNotFound() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(mockUser));
        when(placeRepository.findById(placeId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> favoriteService.addFavorite(userId, placeId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Place not found with id: " + placeId);

        verify(favoriteRepository, never()).save(any());
    }

    @Test
    @DisplayName("addFavorite when already favorited throws DuplicateResourceException")
    void addFavorite_whenAlreadyFavorited_throwsConflict() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(mockUser));
        when(placeRepository.findById(placeId)).thenReturn(Optional.of(mockPlace));
        when(favoriteRepository.existsByUserIdAndPlaceId(userId, placeId)).thenReturn(true);

        assertThatThrownBy(() -> favoriteService.addFavorite(userId, placeId))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessage("Place is already in favorites.");

        verify(favoriteRepository, never()).save(any());
    }

    @Test
    @DisplayName("removeFavorite deletes favorite when user exists and favorite entry exists")
    void removeFavorite_success() {
        when(userRepository.existsById(userId)).thenReturn(true);
        when(favoriteRepository.existsByUserIdAndPlaceId(userId, placeId)).thenReturn(true);

        favoriteService.removeFavorite(userId, placeId);

        verify(favoriteRepository).deleteByUserIdAndPlaceId(userId, placeId);
    }

    @Test
    @DisplayName("removeFavorite when user not found throws ResourceNotFoundException")
    void removeFavorite_whenUserNotFound_throwsNotFound() {
        when(userRepository.existsById(userId)).thenReturn(false);

        assertThatThrownBy(() -> favoriteService.removeFavorite(userId, placeId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("User not found with id: " + userId);

        verify(favoriteRepository, never()).deleteByUserIdAndPlaceId(any(), any());
    }

    @Test
    @DisplayName("removeFavorite when favorite entry not found throws ResourceNotFoundException")
    void removeFavorite_whenFavoriteNotFound_throwsNotFound() {
        when(userRepository.existsById(userId)).thenReturn(true);
        when(favoriteRepository.existsByUserIdAndPlaceId(userId, placeId)).thenReturn(false);

        assertThatThrownBy(() -> favoriteService.removeFavorite(userId, placeId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Favorite not found for place id: " + placeId);

        verify(favoriteRepository, never()).deleteByUserIdAndPlaceId(any(), any());
    }
}

