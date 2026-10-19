-- =============================================================================
-- Database Schema Definition: Smart Local Planner
-- Dialect: PostgreSQL 16+
-- Encoding: UTF-8
-- Purpose: Complete reference DDL for local Docker & cloud Neon.tech environments
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. Table: users
-- Stores registered accounts, authentication credentials, and user profiles.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    avatar_url TEXT,
    role VARCHAR(32) NOT NULL DEFAULT 'ROLE_USER',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_users_role CHECK (role IN ('ROLE_USER', 'ROLE_ADMIN'))
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- -----------------------------------------------------------------------------
-- 2. Table: places
-- Stores points of interest (attractions, cafes, restaurants, historical sites).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(64) NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    price_level INT NOT NULL DEFAULT 1,
    opening_hours VARCHAR(128),
    image_url TEXT,
    average_rating NUMERIC(2, 1) NOT NULL DEFAULT 0.0,
    total_reviews INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_places_price_level CHECK (price_level BETWEEN 1 AND 4),
    CONSTRAINT chk_places_rating CHECK (average_rating BETWEEN 0.0 AND 5.0)
);

CREATE INDEX IF NOT EXISTS idx_places_category ON places(category);
CREATE INDEX IF NOT EXISTS idx_places_price_level ON places(price_level);
CREATE INDEX IF NOT EXISTS idx_places_rating ON places(average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_places_coordinates ON places(latitude, longitude);

-- -----------------------------------------------------------------------------
-- 3. Table: favorites
-- Many-to-many relationship mapping users to their bookmarked favorite places.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    place_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_favorites_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_favorites_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT uq_favorites_user_place UNIQUE (user_id, place_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_place_id ON favorites(place_id);

-- -----------------------------------------------------------------------------
-- 4. Table: itineraries
-- Stores multi-day travel itineraries authored by users.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS itineraries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_itineraries_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_itineraries_dates CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS idx_itineraries_user_id ON itineraries(user_id);
CREATE INDEX IF NOT EXISTS idx_itineraries_public ON itineraries(is_public) WHERE is_public = TRUE;

-- -----------------------------------------------------------------------------
-- 5. Table: itinerary_items
-- Maps individual scheduled places to specific days and positions within an itinerary.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS itinerary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    itinerary_id UUID NOT NULL,
    place_id UUID NOT NULL,
    day_number INT NOT NULL DEFAULT 1,
    order_index INT NOT NULL DEFAULT 0,
    start_time TIME,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_itinerary_items_itinerary FOREIGN KEY (itinerary_id) REFERENCES itineraries(id) ON DELETE CASCADE,
    CONSTRAINT fk_itinerary_items_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT chk_itinerary_items_day CHECK (day_number >= 1),
    CONSTRAINT chk_itinerary_items_order CHECK (order_index >= 0)
);

CREATE INDEX IF NOT EXISTS idx_itinerary_items_itinerary_id ON itinerary_items(itinerary_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_items_day_order ON itinerary_items(itinerary_id, day_number, order_index);

-- -----------------------------------------------------------------------------
-- 6. Table: reviews
-- User reviews and numeric star ratings submitted for points of interest.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    place_id UUID NOT NULL,
    rating INT NOT NULL,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT uq_reviews_user_place UNIQUE (user_id, place_id),
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_reviews_place_id ON reviews(place_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
