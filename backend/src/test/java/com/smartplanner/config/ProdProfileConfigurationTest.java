package com.smartplanner.config;

import com.smartplanner.BackendApplication;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@DisplayName("Production Profile Hardening Configuration Tests")
class ProdProfileConfigurationTest {

    @Nested
    @DisplayName("YAML Property Resolution Tests")
    class YamlPropertyResolutionTests {

        @Test
        @DisplayName("application.yml configures dynamic PORT binding and default sslmode=disable")
        void baseYaml_configuresPortAndSslMode() {
            YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
            yaml.setResources(new ClassPathResource("application.yml"));
            Properties props = yaml.getObject();

            assertThat(props).isNotNull();
            assertThat(props.getProperty("server.port")).isEqualTo("${PORT:${SERVER_PORT:8080}}");
            assertThat(props.getProperty("spring.datasource.url"))
                    .contains("sslmode=${DB_SSL_MODE:disable}");
        }

        @Test
        @DisplayName("application-prod.yml overrides properties for Render, Neon TLS, Hikari, and disables Swagger")
        void prodYaml_resolvesProductionOverrides() {
            YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
            yaml.setResources(
                    new ClassPathResource("application.yml"),
                    new ClassPathResource("application-prod.yml")
            );
            Properties props = yaml.getObject();

            assertThat(props).isNotNull();

            // 1. Graceful shutdown
            assertThat(props.getProperty("server.shutdown")).isEqualTo("graceful");
            assertThat(props.getProperty("spring.lifecycle.timeout-per-shutdown-phase")).isEqualTo("20s");

            // 2. Swagger / OpenAPI lockdown
            assertThat(props.getProperty("springdoc.api-docs.enabled")).isEqualTo("false");
            assertThat(props.getProperty("springdoc.swagger-ui.enabled")).isEqualTo("false");

            // 3. Multipart bounds
            assertThat(props.getProperty("spring.servlet.multipart.max-file-size")).isEqualTo("5MB");
            assertThat(props.getProperty("spring.servlet.multipart.max-request-size")).isEqualTo("6MB");

            // 4. HikariCP bounds
            assertThat(props.getProperty("spring.datasource.hikari.maximum-pool-size")).isEqualTo("10");
            assertThat(props.getProperty("spring.datasource.hikari.minimum-idle")).isEqualTo("2");

            // 5. Cloud Neon TLS requirement
            assertThat(props.getProperty("spring.datasource.url")).contains("sslmode=${DB_SSL_MODE:require}");

            // 6. Strict CORS without localhost fallback
            assertThat(props.getProperty("cors.allowed-origin-patterns")).isEqualTo("${CORS_ALLOWED_ORIGIN_PATTERNS}");
        }
    }

    @Nested
    @SpringBootTest(
            classes = BackendApplication.class,
            properties = {
                    "JWT_SECRET=404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970",
                    "CORS_ALLOWED_ORIGIN_PATTERNS=https://smartplanner.com"
            }
    )
    @ActiveProfiles("prod")
    @AutoConfigureMockMvc
    @AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
    @Testcontainers(disabledWithoutDocker = true)
    @DisplayName("Prod Profile Endpoints Lockdown Integration Tests (Testcontainers)")
    class ProdProfileEndpointsIntegrationTest {

        @Container
        @ServiceConnection
        static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

        @Autowired
        private MockMvc mockMvc;

        @Test
        @DisplayName("swagger-ui.html returns 404 Not Found in prod profile")
        void swaggerUi_returns404InProd() throws Exception {
            mockMvc.perform(get("/swagger-ui.html"))
                    .andExpect(status().isNotFound());
        }

        @Test
        @DisplayName("v3/api-docs returns 404 Not Found in prod profile")
        void apiDocs_returns404InProd() throws Exception {
            mockMvc.perform(get("/v3/api-docs"))
                    .andExpect(status().isNotFound());
        }
    }
}
