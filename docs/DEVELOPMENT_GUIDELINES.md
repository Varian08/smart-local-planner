# Developer Guidelines & Engineering Standards

> **Project:** Smart Local Planner  
> **Target Audience:** Backend Engineer (Engineer A), Mobile Engineer (Engineer B), and AI Agents  
> **Language Standard:** English for code, commit messages, and technical documentation  

---

## 1. Project Principles & Greenfield Stage

Smart Local Planner is in **Greenfield, Pre-Production** stage.

* **Do it right the first time:** Never write shims, temporary hacks, or backward-compatibility fallbacks for schemas or endpoints that have not been released to real users.
* **Refactor over Patching:** If a model, table schema, or DTO contract is flawed, fix it at the root source rather than layering workarounds on top.
* **Architecture-First:** All features must align with [docs/ARCHITECTURE_BLUEPRINT.md](ARCHITECTURE_BLUEPRINT.md) and recorded [ADRs](adr/README.md).

---

## 2. Backend Engineering Standards (Spring Boot 3 + Java 21)

### 2.1. Strict 3-Layer Architecture
The dependency arrow is strictly **unidirectional**:

```text
HTTP Request
     │
     ▼
[ Controller Layer ]  ──► Receives DTO, triggers Jakarta Validation (@Valid), returns HTTP status
     │
     ▼
[  Service Layer   ]  ──► Core business logic, ownership checks, @Transactional boundaries
     │
     ▼
[ Repository Layer ]  ──► Spring Data JPA, parameterized queries, returns Entities to Service
     │
     ▼
[ Database Layer   ]  ──► PostgreSQL managed via Flyway SQL migrations
```

* **Golden Rule 1 (DTO Isolation):** Never expose JPA Entities directly via Controller endpoints. Always map between Entity and Request/Response DTOs.
* **Golden Rule 2 (No Skip-Calling):** Controllers must never call Repositories directly. Services must not return JPA Entities to Controllers.
* **Golden Rule 3 (Transaction Integrity):** Multi-table mutations must be enclosed in `@Transactional` to ensure atomic commit or rollback.

### 2.2. Unified Error Handling
All exceptions must be caught by `@RestControllerAdvice` and transformed into `ApiErrorResponse`:

```json
{
  "timestamp": "2026-10-18T10:00:00Z",
  "status": 400,
  "code": "VALIDATION_FAILED",
  "message": "Invalid request payload.",
  "fieldErrors": {
    "email": "Email must be a well-formed address."
  },
  "path": "/api/v1/auth/register",
  "traceId": "req-98f2b31a-4c2e"
}
```

---

## 3. Mobile Engineering Standards (Flutter + Dart)

### 3.1. Feature-First Layered Structure
Code under `lib/features/` must be partitioned into:
1. `presentation/`: Screens and Widgets (`StatelessWidget` only). Only renders state and dispatches events.
2. `bloc/`: `flutter_bloc` Bloc/Cubit handling state transitions (`UI -> Event -> Bloc -> State -> UI`).
3. `data/`: Repositories and Data Sources (Dio HTTP calls, JSON serialization `fromMap`/`toMap`).

### 3.2. Mandatory 4-State UI Contract
Every screen must handle 4 distinct states:
- **Loading:** Display non-blocking skeleton or spinner.
- **Success:** Display populated content.
- **Error:** Display actionable error message with a **Retry** button.
- **Empty:** Display descriptive empty-state artwork/message when data list has length 0.

### 3.3. Mobile Edge Cases Checklist
Before submitting a feature branch, Engineer B must verify:
- [ ] **Offline / Timeout:** App gracefully notifies user without crashing when internet is lost.
- [ ] **Keyboard Overflow:** No `Bottom overflowed by xx pixels` when virtual keyboard opens (wrap in `SingleChildScrollView`).
- [ ] **Text Overflow:** Long names or addresses are truncated with `TextOverflow.ellipsis`.
- [ ] **Double Click:** Action buttons disable during pending requests to prevent duplicate submission.

---

## 4. Database & Migration Standards (Flyway)

* Schema files live in `backend/src/main/resources/db/migration/`.
* Naming format: `V<Version>__<Description>.sql` (e.g., `V1__init_schema.sql`).
* **Immutability:** Once a migration script is merged and executed, **never modify it**. Always author a new incremental migration file (`V2__...`).
* Hibernate `ddl-auto` is set to `validate`.

---

## 5. Security & Zero-Trust Policy

1. **No Hardcoded Secrets:** Never commit passwords, JWT secrets, or API keys. Use `.env` locally (included in `.gitignore`) and environment variables in deployment.
2. **Token Rotation:** Access Token expires in 30 minutes; Refresh Token expires in 7 days. Dio `AuthInterceptor` automatically handles rotation upon HTTP `401`.
3. **Hardware Keystore:** Store tokens in Android Keystore / iOS Keychain via `flutter_secure_storage`.
4. **Injection Prevention:** Use 100% parameterized queries in JPA. Never concatenate SQL strings.

---

## 6. Git Workflow & Conventional Commits

### 6.1. Branching Strategy
* `main`: Production release branch. Protected.
* `develop`: Integration branch.
* `feature/backend-<task-name>`: Backend feature branch.
* `feature/flutter-<task-name>`: Mobile feature branch.

### 6.2. Commit Format
Format: `<type>(<scope>): <subject>`

* `feat(place)`: Add place search endpoint with pagination
* `fix(auth)`: Fix token refresh race condition on expired session
* `refactor(dio)`: Centralize network error mapping in Dio interceptor
* `test(itinerary)`: Add unit tests for itinerary ownership verification
* `docs(adr)`: Record ADR-0005 for cloud hosting architecture

### 6.3. Branch Hygiene
Once a feature Pull Request is approved and merged into `develop` or `main`, **delete the feature branch immediately** on both remote and local.
