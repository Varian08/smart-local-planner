-- ============================================================================
-- Migration: V3__fix_cham_museum_image.sql
-- Purpose: Update Da Nang Cham Sculpture Museum image URL with verified active artwork
-- Reason: Historical V2 seed contained an Unsplash URL that was retired (HTTP 404)
-- Enforces Flyway Immutability by leaving V1 and V2 migrations completely untouched
-- ============================================================================

UPDATE places
SET image_url = 'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?auto=format&fit=crop&w=1200&q=80',
    updated_at = CURRENT_TIMESTAMP
WHERE name = 'Bảo tàng Điêu khắc Chăm Đà Nẵng';
