package com.smartplanner.repository;

import com.smartplanner.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Spring Data JPA Repository for User entity operations.
 */
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    /**
     * Find a user by their unique email address.
     */
    Optional<User> findByEmail(String email);

    /**
     * Check if a user with the given email address already exists.
     */
    boolean existsByEmail(String email);
}

