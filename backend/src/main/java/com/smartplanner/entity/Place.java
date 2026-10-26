package com.smartplanner.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Place JPA Entity.
 * Maps to table 'places' in PostgreSQL database.
 */
@Entity
@Table(name = "places")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Place {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @NotBlank(message = "Place name cannot be blank")
    @Size(max = 255, message = "Place name must not exceed 255 characters")
    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @NotBlank(message = "Category cannot be blank")
    @Size(max = 64, message = "Category must not exceed 64 characters")
    @Column(name = "category", nullable = false, length = 64)
    private String category;

    @NotBlank(message = "Address cannot be blank")
    @Column(name = "address", nullable = false, columnDefinition = "TEXT")
    private String address;

    @NotNull(message = "Latitude is required")
    @Column(name = "latitude", nullable = false)
    private Double latitude;

    @NotNull(message = "Longitude is required")
    @Column(name = "longitude", nullable = false)
    private Double longitude;

    @Min(value = 1, message = "Price level must be between 1 and 4")
    @Max(value = 4, message = "Price level must be between 1 and 4")
    @Column(name = "price_level", nullable = false)
    @Builder.Default
    private Integer priceLevel = 1;

    @Size(max = 128, message = "Opening hours must not exceed 128 characters")
    @Column(name = "opening_hours", length = 128)
    private String openingHours;

    @Column(name = "image_url", columnDefinition = "TEXT")
    private String imageUrl;

    @DecimalMin(value = "0.0", message = "Rating must be at least 0.0")
    @DecimalMax(value = "5.0", message = "Rating cannot exceed 5.0")
    @Column(name = "average_rating", nullable = false, precision = 2, scale = 1)
    @Builder.Default
    private BigDecimal averageRating = BigDecimal.ZERO;

    @Min(value = 0, message = "Total reviews cannot be negative")
    @Column(name = "total_reviews", nullable = false)
    @Builder.Default
    private Integer totalReviews = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
        if (this.priceLevel == null) {
            this.priceLevel = 1;
        }
        if (this.averageRating == null) {
            this.averageRating = BigDecimal.ZERO;
        }
        if (this.totalReviews == null) {
            this.totalReviews = 0;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }
}
