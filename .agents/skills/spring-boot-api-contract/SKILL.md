---
name: spring-boot-api-contract
description: >-
  Use when creating or updating Spring Boot REST controllers, request/response DTOs,
  validation rules, dynamic sorting, or MockMvc contract tests under backend/.
---

# Spring Boot API Contract Workflow

Follow this checklist whenever adding or modifying an endpoint in `backend/` so API contracts stay synchronized with `docs/API_SPECIFICATION.md`, `bruno/`, and `mobile/`.

## Steps

1. **Sync the Contract First:**
   - Read the matching endpoint section in `docs/API_SPECIFICATION.md` and `bruno/` before writing Java code. If the payload, status code, or query param changes, update both in the same branch.
   - If you need exact Spring Boot `3.3.4` / Spring Security 6 / Jakarta Validation APIs, resolve `Spring Boot` via Context7 before coding.

2. **Enforce 3-Layer & Transaction Boundaries:**
   - Put routing + `@Valid` binding in `controller/`, business logic + authorization/ownership checks + DTO mapping in `service/impl/`, and queries in `repository/`.
   - Keep Controllers free of Repositories and JPA Entities.
   - Execute any external HTTP/network I/O (such as Cloudinary uploads) **before** opening `@Transactional`.

3. **Apply DTO & Query Guardrails:**
   - Validate Request DTOs and `@ParameterObject` query models with Jakarta Bean Validation (`@NotBlank`, `@Size`, `@Min`, `@Max`, `@DecimalMin`, `@DecimalMax`).
   - **Boolean Field Rule:** For any JSON field prefixed with `is` (e.g. `isPublic`, `isFavorite`), declare a `Boolean` wrapper field (never primitive `boolean`) and add `@JsonProperty("is...")` so Jackson + Lombok never emit `"public"` or `"favorite"`.
   - **Sort Allowlist:** Validate `?sort=` / `sortBy` strings against an explicit `Set<String>` allowlist (pattern: `PlaceServiceImpl.ALLOWED_SORT_FIELDS`) with a safe default.
   - Let errors flow to `GlobalExceptionHandler` (`@RestControllerAdvice`) to guarantee `ApiErrorResponse` formatting.

4. **Write Controller Contract & Service Tests:**
   - In `backend/src/test/java/com/smartplanner/controller/`, write MockMvc tests asserting:
     - Expected HTTP status (`200` / `201` / `204`) and exact JSON key names (`jsonPath("$.is...").exists()`).
     - `400 Bad Request` (`VALIDATION_FAILED` + `fieldErrors`) for invalid input.
     - `401 Unauthorized` / `403 Forbidden` / `404 Not Found` / `409 Conflict` for unauthenticated or unauthorized access and business conflicts.
   - In `backend/src/test/java/com/smartplanner/service/`, cover happy paths and edge/ownership cases.

5. **Verify Before Done:**
   - Run backend tests: `Set-Location backend; .\mvnw.cmd test` (or `./mvnw test` on Linux/macOS).
   - Confirm `BUILD SUCCESS` with zero test failures or skipped regressions.

