package com.smartplanner.security;

import com.smartplanner.entity.Itinerary;
import com.smartplanner.exception.ForbiddenException;
import com.smartplanner.exception.ResourceNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Domain security service responsible for evaluating and enforcing resource ownership
 * access control rules for Itineraries (docs/API_SPECIFICATION.md § 6.3).
 */
@Service
@Slf4j
public class ItinerarySecurityService {

    /**
     * Validate that the current authenticated user is the legitimate owner of the itinerary.
     * Throws ForbiddenException (mapped to 403 FORBIDDEN_ACCESS) if ownership check fails.
     *
     * @param itinerary the itinerary entity to inspect
     * @param currentUserId the ID of the authenticated user attempting access
     * @throws ForbiddenException if user is not the owner
     * @throws ResourceNotFoundException if itinerary is null
     */
    public void validateOwnership(Itinerary itinerary, UUID currentUserId) {
        if (itinerary == null) {
            throw new ResourceNotFoundException("Itinerary not found.");
        }

        if (itinerary.getUser() == null || !itinerary.getUser().getId().equals(currentUserId)) {
            UUID ownerId = itinerary.getUser() != null ? itinerary.getUser().getId() : null;
            log.warn("Cross-tenant access violation [itineraryId={}, ownerId={}, requestedBy={}]",
                    itinerary.getId(), ownerId, currentUserId);
            throw new ForbiddenException("You do not possess permission to access or modify this itinerary.");
        }
    }

    /**
     * Check whether the current user is the owner of the itinerary.
     *
     * @param itinerary the itinerary to check
     * @param currentUserId the ID of the user
     * @return true if owner, false otherwise
     */
    public boolean isOwner(Itinerary itinerary, UUID currentUserId) {
        return itinerary != null
                && itinerary.getUser() != null
                && itinerary.getUser().getId().equals(currentUserId);
    }
}
