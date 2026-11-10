package com.smartplanner.controller;

import com.smartplanner.dto.response.MessageResponse;
import com.smartplanner.dto.response.PlaceResponse;
import com.smartplanner.entity.User;
import com.smartplanner.exception.UnauthorizedException;
import com.smartplanner.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * REST controller managing personal favorite places for authenticated users.
 * Endpoints comply with docs/API_SPECIFICATION.md § 3.
 */
@RestController
@RequestMapping("/api/v1/favorites")
@RequiredArgsConstructor
@Slf4j
public class FavoriteController {

    private final FavoriteService favoriteService;

    /**
     * Retrieve all favorite places bookmarked by the currently authenticated user.
     *
     * @param currentUser authenticated user extracted from SecurityContext
     * @return list of favorite PlaceResponse DTOs
     */
    @GetMapping
    public ResponseEntity<List<PlaceResponse>> getUserFavorites(
            @AuthenticationPrincipal User currentUser
    ) {
        UUID userId = resolveUserId(currentUser);
        log.debug("GET /api/v1/favorites requested by user {}", userId);
        List<PlaceResponse> favorites = favoriteService.getUserFavorites(userId);
        return ResponseEntity.ok(favorites);
    }

    /**
     * Add a place to the authenticated user's favorites list.
     *
     * @param currentUser authenticated user extracted from SecurityContext
     * @param placeId ID of the place to bookmark
     * @return confirmation message with HTTP 201 Created
     */
    @PostMapping("/{placeId}")
    public ResponseEntity<MessageResponse> addFavorite(
            @AuthenticationPrincipal User currentUser,
            @PathVariable UUID placeId
    ) {
        UUID userId = resolveUserId(currentUser);
        log.info("POST /api/v1/favorites/{} requested by user {}", placeId, userId);
        favoriteService.addFavorite(userId, placeId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new MessageResponse("Place added to favorites."));
    }

    /**
     * Remove a place from the authenticated user's favorites list.
     *
     * @param currentUser authenticated user extracted from SecurityContext
     * @param placeId ID of the place to remove
     * @return confirmation message with HTTP 200 OK
     */
    @DeleteMapping("/{placeId}")
    public ResponseEntity<MessageResponse> removeFavorite(
            @AuthenticationPrincipal User currentUser,
            @PathVariable UUID placeId
    ) {
        UUID userId = resolveUserId(currentUser);
        log.info("DELETE /api/v1/favorites/{} requested by user {}", placeId, userId);
        favoriteService.removeFavorite(userId, placeId);
        return ResponseEntity.ok(new MessageResponse("Place removed from favorites."));
    }

    /**
     * Defensive resolution of authenticated user ID from principal or SecurityContextHolder.
     */
    private UUID resolveUserId(User currentUser) {
        if (currentUser != null && currentUser.getId() != null) {
            return currentUser.getId();
        }
        org.springframework.security.core.Authentication auth =
                org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof User user && user.getId() != null) {
            return user.getId();
        }
        throw new UnauthorizedException("User authentication required.");
    }
}
