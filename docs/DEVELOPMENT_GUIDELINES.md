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
All branch management strictly aligns with the [Developer Workflow Playbook](DEVELOPER_WORKFLOW_PLAYBOOK.md) and [CONTRIBUTING.md](../CONTRIBUTING.md):
* `main`: Production release branch. Strictly protected.
* `develop`: Active integration branch. Direct pushes blocked.
* Feature branches: `feat/<issue_number>-<short-description>` (e.g. `feat/46-jwt-architecture`)
* Bugfix branches: `fix/<issue_number>-<short-description>` (e.g. `fix/44-place-card-null-image-fallback`)
* Documentation / Refactoring branches: `docs/...`, `refactor/...`, `chore/...`

### 6.2. Conventional Commits Standard

All commit messages across the team must follow the industry-standard **Conventional Commits** specification:

```text
<type>(<scope>): <subject>
```

#### Commit Types Quick Reference

| Type | Purpose & Scope | Real Project Example |
| :--- | :--- | :--- |
| **`feat`** | Introduces a new feature or user-facing capability | `feat(places): add API to search tourist spots with pagination` |
| **`fix`** | Patches a bug or resolves unintended behavior | `fix(auth): fix token refresh race condition on expired session` |
| **`docs`** | Updates documentation, ADRs, or API specifications | `docs(readme): update local development setup instructions` |
| **`refactor`** | Restructures code without changing behavior or adding features | `refactor(service): simplify calculate distance algorithm` |
| **`test`** | Adds or refactors unit, integration, or widget tests | `test(places): add mock tests for PlaceService repository layer` |
| **`ci`** | Updates CI/CD workflows, build scripts, or GitHub Actions | `ci: optimize maven test-compile quality gate` |
| **`chore`** | Maintenance, dependencies, config files, or cleanup | `chore: clean up unused assets and remove legacy template` |

#### Permitted Scopes
* **Backend:** `auth`, `places`, `itineraries`, `database`, `security`, `flyway`
* **Mobile:** `ui`, `bloc`, `dio`, `storage`, `theme`, `widget`
* **Shared/Infrastructure:** `ci`, `docker`, `docs`, `config`

#### Best Practices
* **Imperative mood:** Use "add", "fix", "update" instead of "added", "fixed", "updating".
* **No period at the end:** Keep the subject concise (under 72 characters).
* **Bad:** `fixed bug`, `update code`, `wip`, `test1`
* **Good:** `feat(mobile): implement place card widget with skeleton loading`

### 6.3. Branch Hygiene
Once a feature Pull Request is approved and merged into `develop` or `main`, **delete the feature branch immediately** on both remote and local.
