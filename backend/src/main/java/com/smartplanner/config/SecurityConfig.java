package com.smartplanner.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Tắt CSRF vì API sử dụng JWT stateless
            .csrf(AbstractHttpConfigurer::disable)
            // Không lưu session trên server (Stateless)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            // Cấu hình phân quyền đường dẫn
            .authorizeHttpRequests(auth -> auth
                // Cho phép tự do xem tài liệu Swagger UI & Actuator Health
                .requestMatchers(
                    "/v3/api-docs/**",
                    "/swagger-ui/**",
                    "/swagger-ui.html",
                    "/actuator/health"
                ).permitAll()
                // Tất cả các request khác tạm thời cho phép để phát triển MVP
                .anyRequest().permitAll()
            );

        return http.build();
    }
}
