package com.smartplanner.util;

import com.smartplanner.entity.User;
import com.smartplanner.exception.UnauthorizedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/**
 * Shared utility methods for resolving authenticated principal identity across controllers.
 */
public final class SecurityUtils {

    private SecurityUtils() {
        // Utility class
    }

    /**
     * Resolve the authenticated user's UUID defensively from {@code @AuthenticationPrincipal}
     * or fallback to {@link SecurityContextHolder}.
     *
     * @param currentUser injected principal (nullable in unauthenticated or slice contexts)
     * @return authenticated user UUID
     * @throws UnauthorizedException when no valid authenticated {@link User} principal is present
     */
    public static UUID resolveUserId(User currentUser) {
        if (currentUser != null && currentUser.getId() != null) {
            return currentUser.getId();
        }
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof User user && user.getId() != null) {
            return user.getId();
        }
        throw new UnauthorizedException("User authentication required.");
    }
}
