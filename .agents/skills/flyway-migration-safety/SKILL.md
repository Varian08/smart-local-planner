---
name: flyway-migration-safety
description: >-
  Use when adding or modifying PostgreSQL tables, columns, constraints, indexes,
  or seed scripts under backend/src/main/resources/db/migration/ and JPA entities.
---

# Flyway Migration Safety Workflow

Follow this checklist for every database schema or seed change to prevent `FlywayValidateException` checksum crashes and PostgreSQL migration locks.

## Steps

1. **Determine Next Sequential Version:**
   - List `backend/src/main/resources/db/migration/` (currently `V1` through `V4__create_refresh_tokens.sql`) to confirm the highest version `N`.
   - **Never edit, rename, or reformat any existing `V1`..`V<N>` SQL file.** Always author a brand-new `V<N+1>__<snake_case_description>.sql`.

2. **Author Safe, Reversible PostgreSQL DDL:**
   - **No PostgreSQL `ENUM` Types:** Define status/role/category columns as `VARCHAR(N)` paired with named `CHECK (...)` constraints (`CONSTRAINT chk_<table>_<col> CHECK (...)`, matching `V1__init_schema.sql`), avoiding `ALTER TYPE ... ADD VALUE` transaction limitations.
   - Add explicit indexes for foreign keys and columns used in filter/sort specifications (`WHERE` / `ORDER BY`).
   - Follow **Expand & Contract**: when adding non-null columns to populated tables, supply safe `DEFAULT` values or backfill before adding `NOT NULL`.

3. **Align JPA Entities with `ddl-auto: validate`:**
   - Update or create matching `@Entity` classes under `backend/src/main/java/com/smartplanner/entity/` so column names, lengths, nullability, and precision match the SQL script 1:1.
   - Update `docs/ARCHITECTURE_BLUEPRINT.md` / `docs/API_SPECIFICATION.md` if domain fields or contracts changed.

4. **Verify Schema & Tests:**
   - Run `Set-Location backend; .\mvnw.cmd test` (`./mvnw test` on Linux/macOS) and verify `BUILD SUCCESS`.
   - If Docker Desktop is active, ensure `docker compose up -d` starts cleanly and repository integration tests pass against PostgreSQL 16.

