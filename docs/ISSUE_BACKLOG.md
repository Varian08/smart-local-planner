# Smart Local Planner — Technical Issue Backlog

> **Purpose:** Track gaps between the planned architecture and the code currently present in the repository.
> 
> **Status:** The project is at the foundation/scaffold stage. Priorities below are ordered to reduce rework and security risk before feature development expands.

## Recommended implementation order

```text
API contract
  -> refresh-token session model
  -> database migration V2
  -> JWT security and authorization
  -> error handling and test gate
  -> Places vertical slice
  -> Flutter application integration
```

## P0 — Blockers

### `security: protect authenticated endpoints with JWT`

**Problem**

`SecurityConfig` currently uses `anyRequest().permitAll()`. Any future endpoint is public unless a developer remembers to change this rule.

**Scope**

- Implement JWT token parsing and authentication filter.
- Add authenticated-user lookup and authorization rules.
- Keep only the documented public endpoints public.
- Add controller/security tests for `401 Unauthorized` and `403 Forbidden`.

**Acceptance criteria**

- An unauthenticated request to Favorites or personal Itineraries returns `401`.
- A user cannot read, update, or delete another user's private itinerary.
- Swagger and health endpoints remain reachable as intended.

### `auth: persist refresh-token sessions and support revocation`

**Problem**

The API contract requires refresh-token rotation and logout token revocation, but the database has no refresh-token or user-session table. Stateless tokens alone cannot be immediately revoked at logout.

**Scope**

- Create a Flyway migration for `refresh_tokens` or `user_sessions`.
- Store only a token hash, expiry time, creation time, and revocation metadata.
- Rotate refresh tokens atomically: revoke the old token and issue the new one in one transaction.
- Define the behavior for expired, reused, and revoked tokens.

**Acceptance criteria**

- A rotated or logged-out refresh token cannot be used again.
- Multiple device sessions have defined behavior.
- Concurrent refresh requests cannot create two valid successor tokens.

### `test: establish backend test baseline`

**Problem**

`mvn test` currently succeeds with no tests executed. The GitHub workflow runs only `mvn clean compile`, so it cannot catch a behavioral regression.

**Scope**

- Add unit tests for service rules.
- Add controller tests for validation and security status codes.
- Add PostgreSQL integration tests for Flyway and transactional workflows.
- Change CI from `mvn -B clean compile` to `mvn -B clean verify`.

**Acceptance criteria**

- CI fails if a test fails.
- At least one test covers each implemented endpoint's success and failure path.
- Database migrations are exercised against PostgreSQL in automated tests.

## P1 — Resolve before feature expansion

### `docs: reconcile API contract inconsistencies`

**Problem**

- The README says there are 14 MVP endpoints, while the API specification describes 16.
- The architecture blueprint requires itinerary ownership for detail access; the API specification allows access to a public itinerary.
- The roadmap mentions geo search, while `GET /places` documents no latitude, longitude, or radius parameters.

**Scope**

- Use `API_SPECIFICATION.md` as the API source of truth.
- Decide and document the public-itinerary rule.
- Decide whether geo search is part of MVP and define its parameters if it is.
- Update README and architecture blueprint to match the decision.

**Acceptance criteria**

- Endpoint count and access rules are identical across all documents.
- Mobile implementation can be written without guessing request or response behavior.

### `db: enforce itinerary item ordering integrity`

**Problem**

`itinerary_items` permits multiple items with the same itinerary, day, and `order_index`. Drag-and-drop ordering can become ambiguous.

**Scope**

- Add a unique constraint for `(itinerary_id, day_number, order_index)` in a new Flyway migration.
- Implement reorder/update in a transaction.
- Define whether gaps in order indexes are allowed.

**Acceptance criteria**

- No itinerary day can have two items at the same order position.
- A failed reorder leaves the original schedule intact.

### `db: define timestamp update strategy`

**Problem**

The `updated_at` columns receive a default at insert time but do not automatically change on update.

**Scope**

- Choose one strategy: JPA auditing or PostgreSQL triggers.
- Apply it consistently to users, places, itineraries, and reviews.

**Acceptance criteria**

- Updating a record changes `updated_at` reliably.
- Timestamps use a documented timezone convention.

### `db: validate place and itinerary invariants`

**Problem**

The schema permits invalid latitude/longitude and a negative `total_reviews`. Itinerary dates are nullable even though API responses expose `totalDays`.

**Scope**

- Add coordinate and non-negative review-count constraints.
- Decide whether itinerary dates are required; document `totalDays` behavior when dates are absent.
- Validate the same rules in request DTOs.

**Acceptance criteria**

- Invalid geographical coordinates cannot be persisted.
- The API has deterministic `totalDays` behavior for every valid itinerary.

### `database: remove unsafe Flyway baseline default`

**Problem**

`baseline-on-migrate: true` can mark a non-empty database as baselined without running the initial migration. This setting is intended for intentionally adopting an existing schema, not normal greenfield startup.

**Scope**

- Disable the default setting for new environments.
- If legacy-database adoption is needed, place baseline settings in a dedicated, documented profile or runbook.

**Acceptance criteria**

- A fresh database always runs every migration in order.
- A non-empty database cannot silently bypass the initial schema without an explicit operation.

### `api: add standard error handling`

**Problem**

The API specification defines a standard error envelope with `traceId`, but no global exception handler or error DTO exists yet.

**Scope**

- Add `@RestControllerAdvice` and a single error-response DTO.
- Map validation, not-found, conflict, authentication, and authorization failures.
- Add request trace/correlation ID handling.

**Acceptance criteria**

- All expected errors follow the documented response shape.
- Validation errors identify invalid fields without leaking implementation details.

### `places: implement first vertical slice`

**Problem**

Sprint 1's planned Place entity, repository, service, DTOs, endpoints, and mobile screen are not implemented.

**Scope**

- Implement `GET /api/v1/places` with documented filters and pagination.
- Implement `GET /api/v1/places/{id}`.
- Add tests and Bruno requests for the two endpoints.
- Only then connect the Flutter Place list/detail UI.

**Acceptance criteria**

- Pagination response matches `API_SPECIFICATION.md`.
- Invalid parameters and unknown IDs return standard errors.
- Search behavior is covered by automated tests.

## P2 — Production and maintenance hardening

### `config: separate local and production configuration`

**Problem**

SQL logging is always enabled, and the project has no explicit production profile or startup validation for mandatory production secrets.

**Scope**

- Create local and production Spring profiles.
- Enable SQL logging only for local development.
- Fail fast in production if required database, JWT, or Cloudinary configuration is absent.

### `infra: add backend container and deployment definition`

**Problem**

The architecture describes Docker/Render deployment, but no backend Dockerfile, Render configuration, or deployment runbook exists.

**Scope**

- Add a multi-stage backend Dockerfile.
- Add deployment configuration and a health-check strategy.
- Document required production environment variables.

### `security: add rate limiting and CORS policy`

**Problem**

The blueprint specifies rate limiting and a CORS whitelist, but neither is implemented.

**Scope**

- Rate-limit login and registration requests.
- Configure allowed origins per environment when browser clients are supported.
- Add tests for rate-limit responses.

### `docs: eliminate duplicate schema source`

**Problem**

`docs/schema.sql` duplicates the Flyway V1 migration. Two independently edited schema sources will drift.

**Scope**

- Treat Flyway migrations as the only executable source of truth.
- Replace the duplicate schema file with generated output, a reference link, or a documented synchronization process.

### `api: define idempotency and conflict behavior`

**Problem**

The contract does not define what happens when a favorite already exists, a review already exists, or a referenced place does not exist.

**Scope**

- Define status codes and response bodies for duplicates and missing resources.
- Add matching service/controller tests.

## P3 — Client and API verification tooling

### `mobile: bootstrap real Flutter project`

**Problem**

The mobile directory currently contains only placeholder folders. There is no Flutter project, `pubspec.yaml`, application entrypoint, or executable screen.

**Scope**

- Initialize the Flutter application.
- Establish theme, routing, Dio client, secure storage, and error mapping.
- Implement the Places vertical slice only after its backend contract is tested.

### `bruno: expand API regression collection`

**Problem**

The Bruno collection has only an Actuator health-check request.

**Scope**

- Add environment variables for local and production base URLs.
- Add requests for every endpoint and representative error case.
- Chain authentication requests safely without committing real credentials.

## Review rule for every issue

```text
Reproduce the behavior
  -> add a failing automated test
  -> fix the root layer (contract, database, service, or security)
  -> run regression tests
  -> attach test/API evidence to the pull request
```

Do not solve backend authorization or integrity problems only in the Flutter UI. The backend and database must enforce the rules.
