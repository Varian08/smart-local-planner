# Backend Engineering Rules (`backend/`)

> Scope: Applies to all Java, Spring Boot, configuration, and SQL files under `backend/`. Inherits monorepo rules from root [AGENTS.md](../AGENTS.md).

---

## 1. Runtime & Build

- **Stack:** Java 21 LTS, Spring Boot `3.3.4`, Spring Security 6, Spring Data JPA, Flyway Core, PostgreSQL `16`, Lombok, Springdoc OpenAPI (`2.6.0`), JJWT (`0.12.6`).
- **Verification Command:**
  - Windows PowerShell: `Set-Location backend; .\mvnw.cmd test`
  - Linux / macOS: `cd backend && ./mvnw test`
- **No Unbounded Memory Stores:** In-memory request trackers or rate limiters (e.g. `LoginRateLimitingFilter`) must be upgraded to bounded TTL caches (`maximumSize` + expiry) before production scale—never introduce new unbounded `ConcurrentHashMap` caches.

---

## 2. Clean Architecture & Transaction Discipline

1. **Strict 3-Layer Flow (`Controller -> Service -> Repository`):**
   - `@RestController` handles HTTP routing, `@Valid` DTO binding, and `ResponseEntity` status codes only. Never inject Repositories into Controllers.
   - Service interfaces live in `service/` and implementations in `service/impl/`. Never return JPA Entities across the Service boundary—map to immutable Response DTOs.
   - Keep `SecurityConfig` deny-by-default (`anyRequest().authenticated()`). Every user-owned resource (`Favorite`, `Itinerary`, `Review`) must verify ownership in the service/security layer before returning or mutating data.
2. **Transaction Boundaries & External I/O:**
   - Default Services to `@Transactional(readOnly = true)` at class level and override write methods with `@Transactional`.
   - **Never perform external network I/O inside `@Transactional`** (e.g. Cloudinary image uploads or third-party HTTP calls). Complete external I/O and input validation *before* opening a database transaction so HikariCP connections are never starved and DB rollbacks do not orphan remote files.
   - Keep `spring.jpa.open-in-view: false` so database connections close immediately after the Service layer returns.

---

## 3. JSON Contracts, Validation & Sorting Guardrails

1. **Boolean Naming Trap (`is...` Prefix):**
   - Primitive `boolean isPublic` causes Lombok to generate `isPublic()`, which Jackson serializes as `"public"` instead of `"isPublic"`.
   - **Mandatory Rule:** Use `Boolean` wrapper fields and annotate with explicit `@JsonProperty("is...")` whenever a JSON contract key starts with `is` (`isPublic`, `isFavorite`, `isActive`). Always pin the exact field name in MockMvc tests using `jsonPath("$.is...")`.
2. **Input & Query Validation:**
   - Annotate Request DTOs and query parameter objects with `@Valid` and Jakarta constraints (`@NotBlank`, `@Size`, `@Min`, `@Max`, `@DecimalMin`, `@DecimalMax`).
   - Whitelist every dynamic sort parameter (`?sort=` / `sortBy`) against an immutable `Set<String>` allowlist (see `PlaceServiceImpl.ALLOWED_SORT_FIELDS`). Never pass raw user strings straight into `Sort.by(...)`.
3. **Centralized Error Envelope:**
   - Let exceptions propagate to `GlobalExceptionHandler` (`@RestControllerAdvice`) so all 4xx/5xx responses conform to `ApiErrorResponse` (`timestamp`, `status`, `code`, `message`, `fieldErrors`, `path`, `traceId`). Never leak stack traces or internal SQL details.

---

## 4. Database, Migrations & Production Hygiene

- **Migrations (`backend/src/main/resources/db/migration/`):** Inspect existing files (`V1`–`V4`+) first; author only new `V<N+1>__<snake_case>.sql` files. Keep `spring.jpa.hibernate.ddl-auto: validate`.
- **Enum Storage:** Use `VARCHAR(N) CHECK (...)` constraints instead of PostgreSQL `ENUM` types (established in `V1__init_schema.sql`) so new enum values never require destructive `ALTER TYPE` migrations.
- **Production Profile (`application-prod.yml`):** Keep secrets env-driven (`JWT_SECRET`, DB credentials, CORS origins), enforce multipart size bounds, graceful shutdown, and disable public Swagger UI in production deployments.

---

## 5. Testing Requirements

Every backend change must include:
- **Controller Slice / MockMvc Tests:** Verify HTTP status codes, JSON contract key names (`jsonPath`), `@Valid` 400 validation errors, and 401/403 security/ownership rejections.
- **Service / Security Unit Tests:** Verify business rules, conflict cases (e.g. 409 duplicates), and ownership checks.
- **Integration Tests:** Ensure schema compatibility with Flyway + PostgreSQL (`ddl-auto: validate`).

