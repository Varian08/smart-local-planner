package com.smartplanner.util;

import com.smartplanner.entity.User;
import com.smartplanner.exception.UnauthorizedException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("SecurityUtils Unit Tests")
class SecurityUtilsTest {

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("resolveUserId returns ID directly from non-null User principal")
    void resolveUserId_withValidPrincipal_returnsId() {
        UUID userId = UUID.randomUUID();
        User user = User.builder().id(userId).email("user@example.com").build();

        assertThat(SecurityUtils.resolveUserId(user)).isEqualTo(userId);
    }

    @Test
    @DisplayName("resolveUserId falls back to SecurityContextHolder when parameter is null")
    void resolveUserId_whenParamNull_fallsBackToSecurityContext() {
        UUID userId = UUID.randomUUID();
        User contextUser = User.builder().id(userId).email("ctx@example.com").build();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(contextUser, null, List.of())
        );

        assertThat(SecurityUtils.resolveUserId(null)).isEqualTo(userId);
    }

    @Test
    @DisplayName("resolveUserId throws UnauthorizedException when no valid User principal exists")
    void resolveUserId_whenUnauthenticated_throwsUnauthorizedException() {
        SecurityContextHolder.clearContext();

        assertThatThrownBy(() -> SecurityUtils.resolveUserId(null))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessage("User authentication required.");
    }

    @Test
    @DisplayName("resolveUserId throws UnauthorizedException when principal ID is null")
    void resolveUserId_whenUserIdNull_throwsUnauthorizedException() {
        User incompleteUser = User.builder().email("noid@example.com").build();
        SecurityContextHolder.clearContext();

        assertThatThrownBy(() -> SecurityUtils.resolveUserId(incompleteUser))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessage("User authentication required.");
    }
}
