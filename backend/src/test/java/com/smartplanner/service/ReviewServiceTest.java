package com.smartplanner.service;

import com.smartplanner.dto.request.ReviewRequest;
import com.smartplanner.dto.response.ReviewResponse;
import com.smartplanner.entity.Place;
import com.smartplanner.entity.Review;
import com.smartplanner.entity.User;
import com.smartplanner.exception.DuplicateResourceException;
import com.smartplanner.exception.ResourceNotFoundException;
import com.smartplanner.repository.PlaceRepository;
import com.smartplanner.repository.ReviewRepository;
import com.smartplanner.repository.UserRepository;
import com.smartplanner.service.impl.ReviewServiceImpl;
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
@DisplayName("ReviewService Unit Tests")
class ReviewServiceTest {

    @Mock
    private ReviewRepository reviewRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PlaceRepository placeRepository;

    @InjectMocks
    private ReviewServiceImpl reviewService;

    private UUID userId;
    private UUID placeId;
    private User testUser;
    private Place testPlace;
    private Review testReview;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        placeId = UUID.randomUUID();

        testUser = User.builder()
                .id(userId)
                .email("traveler@example.com")
                .fullName("Nguyen Van A")
                .avatarUrl("https://res.cloudinary.com/demo/image/upload/avatar.jpg")
                .build();

        testPlace = Place.builder()
                .id(placeId)
                .name("Ben Thanh Market")
                .averageRating(BigDecimal.valueOf(4.0))
                .totalReviews(5)
                .build();

        testReview = Review.builder()
                .id(UUID.randomUUID())
                .user(testUser)
                .place(testPlace)
                .rating(5)
                .comment("Vibrant atmosphere with delicious local street food!")
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();
    }

    @Test
    @DisplayName("getPlaceReviews returns paginated review responses when place exists")
    void getPlaceReviews_Success() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Review> reviewPage = new PageImpl<>(List.of(testReview), pageable, 1);

        when(placeRepository.existsById(placeId)).thenReturn(true);
        when(reviewRepository.findByPlaceIdWithUser(placeId, pageable)).thenReturn(reviewPage);

        Page<ReviewResponse> result = reviewService.getPlaceReviews(placeId, pageable);

        assertThat(result).isNotNull();
        assertThat(result.getTotalElements()).isEqualTo(1);
        ReviewResponse response = result.getContent().get(0);
        assertThat(response.getId()).isEqualTo(testReview.getId());
        assertThat(response.getUserId()).isEqualTo(userId);
        assertThat(response.getAuthorName()).isEqualTo("Nguyen Van A");
        assertThat(response.getAuthorAvatar()).isEqualTo("https://res.cloudinary.com/demo/image/upload/avatar.jpg");
        assertThat(response.getRating()).isEqualTo(5);
        assertThat(response.getComment()).isEqualTo("Vibrant atmosphere with delicious local street food!");

        verify(placeRepository).existsById(placeId);
        verify(reviewRepository).findByPlaceIdWithUser(placeId, pageable);
    }

    @Test
    @DisplayName("getPlaceReviews throws ResourceNotFoundException when place does not exist")
    void getPlaceReviews_PlaceNotFound_ThrowsException() {
        Pageable pageable = PageRequest.of(0, 10);
        when(placeRepository.existsById(placeId)).thenReturn(false);

        assertThatThrownBy(() -> reviewService.getPlaceReviews(placeId, pageable))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Place not found with id: " + placeId);

        verify(placeRepository).existsById(placeId);
        verify(reviewRepository, never()).findByPlaceIdWithUser(any(), any());
    }

    @Test
    @DisplayName("submitReview successfully saves review, updates rating and count atomically")
    void submitReview_Success() {
        ReviewRequest request = ReviewRequest.builder()
                .rating(5)
                .comment("Outstanding service and great coffee!")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(placeRepository.findById(placeId)).thenReturn(Optional.of(testPlace));
        when(reviewRepository.existsByUserIdAndPlaceId(userId, placeId)).thenReturn(false);
        when(reviewRepository.saveAndFlush(any(Review.class))).thenReturn(testReview);
        when(reviewRepository.calculateAverageRatingByPlaceId(placeId)).thenReturn(4.5);
        when(reviewRepository.countByPlaceId(placeId)).thenReturn(6);

        ReviewResponse response = reviewService.submitReview(userId, placeId, request);

        assertThat(response).isNotNull();
        assertThat(response.getRating()).isEqualTo(5);
        assertThat(testPlace.getAverageRating()).isEqualByComparingTo(BigDecimal.valueOf(4.5));
        assertThat(testPlace.getTotalReviews()).isEqualTo(6);

        verify(reviewRepository).saveAndFlush(any(Review.class));
        verify(reviewRepository).calculateAverageRatingByPlaceId(placeId);
        verify(reviewRepository).countByPlaceId(placeId);
        verify(placeRepository).save(testPlace);
    }

    @Test
    @DisplayName("submitReview correctly handles first review when average was null")
    void submitReview_FirstReview_Success() {
        testPlace.setAverageRating(BigDecimal.ZERO);
        testPlace.setTotalReviews(0);

        ReviewRequest request = ReviewRequest.builder()
                .rating(4)
                .comment("First review on this place.")
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(placeRepository.findById(placeId)).thenReturn(Optional.of(testPlace));
        when(reviewRepository.existsByUserIdAndPlaceId(userId, placeId)).thenReturn(false);
        when(reviewRepository.saveAndFlush(any(Review.class))).thenReturn(testReview);
        when(reviewRepository.calculateAverageRatingByPlaceId(placeId)).thenReturn(4.0);
        when(reviewRepository.countByPlaceId(placeId)).thenReturn(1);

        ReviewResponse response = reviewService.submitReview(userId, placeId, request);

        assertThat(response).isNotNull();
        assertThat(testPlace.getAverageRating()).isEqualByComparingTo(BigDecimal.valueOf(4.0));
        assertThat(testPlace.getTotalReviews()).isEqualTo(1);

        verify(placeRepository).save(testPlace);
    }

    @Test
    @DisplayName("submitReview throws ResourceNotFoundException when user is not found")
    void submitReview_UserNotFound_ThrowsException() {
        ReviewRequest request = ReviewRequest.builder().rating(5).build();
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reviewService.submitReview(userId, placeId, request))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("User not found with id: " + userId);

        verify(reviewRepository, never()).saveAndFlush(any());
        verify(placeRepository, never()).save(any());
    }

    @Test
    @DisplayName("submitReview throws ResourceNotFoundException when place is not found")
    void submitReview_PlaceNotFound_ThrowsException() {
        ReviewRequest request = ReviewRequest.builder().rating(5).build();
        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(placeRepository.findById(placeId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reviewService.submitReview(userId, placeId, request))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Place not found with id: " + placeId);

        verify(reviewRepository, never()).saveAndFlush(any());
        verify(placeRepository, never()).save(any());
    }

    @Test
    @DisplayName("submitReview throws DuplicateResourceException when user has already reviewed the place")
    void submitReview_DuplicateReview_ThrowsDuplicateResourceException() {
        ReviewRequest request = ReviewRequest.builder().rating(5).comment("Second review").build();
        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(placeRepository.findById(placeId)).thenReturn(Optional.of(testPlace));
        when(reviewRepository.existsByUserIdAndPlaceId(userId, placeId)).thenReturn(true);

        assertThatThrownBy(() -> reviewService.submitReview(userId, placeId, request))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessageContaining("You have already reviewed this place.");

        verify(reviewRepository, never()).saveAndFlush(any());
        verify(placeRepository, never()).save(any());
    }
}

