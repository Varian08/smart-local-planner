package com.smartplanner.config;

import com.smartplanner.security.JwtAuthenticationEntryPoint;
import com.smartplanner.security.JwtAuthenticationFilter;
import com.smartplanner.security.LoginRateLimitingFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Spring Security configuration establishing stateless web security, CORS policies,
 * JWT authentication pipeline, rate limiting, and deny-by-default endpoint authorization.
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    @Value("${cors.allowed-origin-patterns:http://localhost:*,http://127.0.0.1:*,http://10.0.2.2:*}")
    private List<String> allowedOriginPatterns;

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
    private final LoginRateLimitingFilter loginRateLimitingFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Enable Cross-Origin Resource Sharing (CORS) with property-driven origin whitelist
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            // Disable CSRF protection as API communication relies on stateless tokens
            .csrf(AbstractHttpConfigurer::disable)
            // Enforce stateless session policy on the server
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            // Centralized RFC 7807 401 Unauthorized handling
            .exceptionHandling(ex -> ex.authenticationEntryPoint(jwtAuthenticationEntryPoint))
            // Endpoint-level authorization rules (Deny-by-default)
            .authorizeHttpRequests(auth -> auth
                // Public access to Swagger OpenAPI documentation and Actuator health check
                .requestMatchers(
                    "/v3/api-docs/**",
                    "/swagger-ui/**",
                    "/swagger-ui.html",
                    "/actuator/health"
                ).permitAll()
                // Public access to authentication endpoints (register, login, refresh-token, logout)
                .requestMatchers("/api/v1/auth/**").permitAll()
                // Public read-only access to place discovery and details
                .requestMatchers(HttpMethod.GET, "/api/v1/places/**").permitAll()
                // All other requests require valid JWT authentication (Deny-by-default)
                .anyRequest().authenticated()
            )
            // Register rate limiting filter before standard authentication
            .addFilterBefore(loginRateLimitingFilter, UsernamePasswordAuthenticationFilter.class)
            // Register JWT authentication filter
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(allowedOriginPatterns);
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept", "Origin", "X-Requested-With"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
