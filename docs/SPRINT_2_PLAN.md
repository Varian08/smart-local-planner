# Sprint 2 Plan — Authentication & Favorites

> **Status:** Active  
> **Delivery model:** Full-stack engineers working in **work packages** separated by **milestone gates**.  
> **Execution SOP:** [DEVELOPER_WORKFLOW_PLAYBOOK.md](DEVELOPER_WORKFLOW_PLAYBOOK.md)  
> **Contract source of truth:** [API_SPECIFICATION.md](API_SPECIFICATION.md)

---

## 1. Goal

Deliver secure user authentication (JWT access + rotating refresh tokens) and a personal favorites collection, end to end (backend + mobile).

## 2. Glossary

| Term | Meaning |
| :--- | :--- |
| **Auth** | Proving who the user is (register, login) and keeping the session alive (token refresh, logout). |
| **Contract** | The agreed request/response shape of every endpoint in `API_SPECIFICATION.md`. Backend and mobile both code against it, so it must not change silently. |
| **Work package** | A small group of tickets that together produce a testable capability. |
| **Gate** | A checkpoint where the lead verifies a work package before the next one starts. |

## 3. Work Packages & Tickets

| WP | Ticket | Scope | Depends on |
| :-: | :--- | :--- | :--- |
| **1 — Backend Auth** | `[SLP-22]` #49 | Flyway `V4` (refresh tokens), `User`/`RefreshToken` entities, repositories, `JwtService` | — |
| | `[SLP-23]` #50 | `AuthController`: register, login, refresh-token, logout; 409 on duplicate email | SLP-22 |
| | `[SLP-24]` #51 | Spring Security deny-by-default, `JwtAuthenticationFilter`, rate limit 5 req/min on auth endpoints | SLP-23 |
| **2 — Mobile Auth** | `[SLP-25]` | `flutter_secure_storage`, Dio `QueuedInterceptor` auto-refresh on 401 | WP1 gate |
| | `[SLP-26]` | `AuthBloc`, `LoginScreen`, `RegisterScreen` (4-state UI contract) | SLP-25 |
| **3 — Favorites** | `[SLP-27]` | Backend favorites APIs (add/remove/list, ownership enforced) | WP1 gate |
| | `[SLP-28]` | `FavoriteBloc`, heart toggle with optimistic UI | SLP-27, WP2 gate |

Tickets for a work package are created together; tickets for the next package are created only after its gate passes.

## 4. Milestone Gates

| Gate | Passes when |
| :-: | :--- |
| **Gate 1** (after WP1) | All three PRs merged with green CI; manually verified via Swagger/Bruno: register, login, refresh rotation, logout, 401 on protected route, 429 after 5 attempts. |
| **Gate 2** (after WP2) | App registers, logs in, survives token expiry (silent refresh), and logs out on a real run. |
| **Gate 3** (after WP3) | Favorite toggle persists across app restarts; a user cannot read or modify another user's favorites. |

## 5. Contract Rules (Backend ↔ Mobile)

1. **Contract first:** change `API_SPECIFICATION.md` in the same PR as the code that changes behavior.
2. **No silent payload changes** once a package's gate has passed; breaking changes need a new ticket and a spec update.
3. **Error shape is fixed:** every failure returns `ApiErrorResponse` (`status`, `code`, `message`, `fieldErrors`, `path`, `traceId`).
4. **Token lifetimes:** access token 30 minutes, refresh token 7 days, refresh rotates on every use.

## 6. Security Invariants

- Passwords hashed with BCrypt; never logged or returned.
- JWT secret supplied via environment variable; never committed.
- Refresh tokens stored server-side so logout can revoke them.
- Tokens stored on device only via `flutter_secure_storage`.

## 7. Definition of Done (Sprint)

- All 7 tickets Done on the Sprint Board.
- `./mvnw test` and `flutter test` / `flutter analyze` green on `develop`.
- `API_SPECIFICATION.md` matches implemented behavior.
