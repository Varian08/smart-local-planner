# System Architecture & Engineering Blueprint — Smart Local Planner

> **Version:** 2.0 (Enterprise Standard — 100% Free Stack for Students)  
> **Target Audience:** Engineering Team (Engineer A - Backend, Engineer B - Mobile), Reviewers, and AI Agents  
> **Core Principles:** MVP-First, Contract-First, Zero Trust, $0 Infrastructure Cost, Strict Enterprise Standards  

---

## 1. Product Scope & Functional Boundaries

### 1.1. Project Overview
**Smart Local Planner** is a cross-platform mobile application that empowers travelers to discover local points of interest (dining, entertainment, sightseeing) and build customizable personal travel itineraries with intelligent suggestions.

### 1.2. Minimum Viable Product (In-Scope)
1. **Authentication:** User registration, credential login (JWT Access Token + Refresh Token), token rotation, and logout.
2. **Places Discovery:**
   - Search points of interest by keyword, geographic area, category, and price level.
   - View place details: address, high-resolution imagery (Cloudinary CDN), operating hours, and average user ratings.
   - Standardized pagination (`page`, `size`, `sort`).
3. **Favorites:** Add/remove places to/from the user's personal favorites collection.
4. **Itineraries Management (Personal Travel Plans):**
   - Full CRUD operations (Create, Read, Update, Delete) for personal multi-day itineraries.
   - Add, reorder, or remove itinerary place items mapped to specific days.
5. **Reviews & Rating:** Public review listing and authenticated review submission with numeric scoring.
6. **Smart Search Assistant (Stretch Goal):** Natural language keyword matching filtered strictly against backend database records.

### 1.3. Strictly Out-of-Scope (MVP Boundary Safeguards)
* ❌ Real-time payment gateway integration (Stripe / VNPay / MoMo).
* ❌ Real-time peer-to-peer chat or WebSockets.
* ❌ Complex social graph mechanics (Followers, Social Activity Feed, Likes).
* ❌ Distributed Microservices or heavy Message Queues (Kafka, RabbitMQ).
* ❌ Web scrapers / automated crawlers or unconstrained LLM hallucinations outside database inventory.

---

## 2. Final Technology Stack (100% Free & Production-Ready)

| Subsystem | Technology / Service | Deployment Specification | Cost | Primary Owner |
|---|---|---|:---:|:---:|
| **Mobile App** | **Flutter + Dart** | Material 3, Single codebase supporting Android & iOS | $0 | Engineer B |
| **State Management** | **`flutter_bloc`** | Unidirectional Event $\to$ State architecture, pure UI/Logic separation | $0 | Engineer B |
| **Mobile Networking** | **`dio` + Interceptors** | Request orchestration, automated `Bearer` header injection & 401 token refresh | $0 | Engineer B |
| **Secure Storage** | **`flutter_secure_storage`** | Hardware-backed AES-256 token encryption (Android Keystore / iOS Keychain) | $0 | Engineer B |
| **Backend API** | **Java 21 + Spring Boot 3.x** | RESTful API, DTO isolation pattern, strict 3-Layer architecture | $0 | Engineer A |
| **Server Security** | **Spring Security + JWT** | Access Token (30m) + Refresh Token (7d), BCrypt password hashing | $0 | Engineer A |
| **Database Migration** | **Flyway** | Version-controlled SQL scripts (`V1__init_schema.sql`, `V2__...`). Hibernate `ddl-auto=validate` | $0 | Engineer A |
| **Local Database** | **PostgreSQL 16 (Docker)** | Isolated containerized environment via `docker-compose.yml` | $0 | Engineer A |
| **Cloud Database** | **Neon.tech** | Managed Serverless PostgreSQL 16 with connection pooling (No credit card needed) | $0 | Engineer A |
| **Server Hosting** | **Render.com** | Automated Docker container build & continuous deployment from GitHub `main` branch | $0 | Engineer A |
| **Media CDN** | **Cloudinary** | Image asset storage, automated resizing, WebP compression, CDN distribution | $0 | Both |
| **API Documentation** | **Springdoc OpenAPI (Swagger)** | Interactive Swagger UI exposed at `/swagger-ui.html` | $0 | Engineer A |
| **API Testing** | **Bruno** | Git-friendly, plain-text API testing collections committed directly to repository | $0 | Both |
| **App Distribution** | **GitHub Releases** | Automated release APK artifact builds attached to tagged Git releases | $0 | Both |
| **CI Pipeline** | **GitHub Actions** | Automated linter verification, compile checks, and unit test execution on PRs | $0 | Both |

---

## 3. System Architecture & Layering Philosophy

The system strictly adheres to **Independent Layered Architecture** across both physical deployment tiers and logical software layers.

### 3.1. Physical 3-Tier Architecture

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 1. CLIENT / PRESENTATION TIER                                                          │
│    User Mobile Device (Android / iOS) — Running Flutter Client (Material 3)            │
└────────────────────────────────────────┬───────────────────────────────────────────────┘
                                         │ HTTPS / JSON + Bearer JWT
                                         ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 2. APPLICATION / LOGIC TIER                                                            │
│    Web Service: Spring Boot 3 on Render.com PaaS Container                            │
│    - Security Filter Chain: Spring Security, JWT Filter, Rate Limiter, CORS Whitelist │
│    - Business Engines: Places Discovery, Itineraries CRUD, Reviews Management          │
└───────────────────┬────────────────────────────────────────────┬───────────────────────┘
                    │ HikariCP Connection Pool (JDBC)            │ HTTPS REST API / SDK
                    ▼                                            ▼
┌───────────────────────────────────────────────┐ ┌──────────────────────────────────────┐
│ 3A. DATA TIER (Relational Database)           │ │ 3B. ASSET TIER (Object Storage / CDN)│
│     PostgreSQL 16 on Neon.tech (Local: Docker)│ │     Cloudinary Media CDN             │
│     Stores: Users, Places, Itineraries, Reviews│ │     Auto-Resize, WebP Optimization   │
└───────────────────────────────────────────────┘ └──────────────────────────────────────┘
```

---

### 3.2. Backend Source Code Architecture (Spring Boot N-Layer Pattern)

The dependency flow between layers is strictly **unidirectional**. Skip-calling or reverse dependency is strictly forbidden:

```text
  [ Client HTTP Request ]
             │
             ▼
┌──────────────────────────┐  • Receives HTTP request, deserializes JSON to Request DTO.
│     Controller Layer     │  • Triggers Jakarta Validation annotations (@Valid, @NotBlank).
└────────────┬─────────────┘  • Returns standard HTTP Status Codes (200, 201, 400, 401, 403, 404).
             │
             ▼
┌──────────────────────────┐  • Heart of the application: executes all business workflows.
│      Service Layer       │  • Enforces ownership checks (e.g., verifying user owns the itinerary).
└────────────┬─────────────┘  • Manages transactional boundaries (@Transactional).
             │
             ▼
┌──────────────────────────┐  • Encapsulates database communication via Spring Data JPA.
│     Repository Layer     │  • 100% Parameterized queries to eliminate SQL injection risks.
└────────────┬─────────────┘  • Never returns DTOs directly; communicates strictly with Entities.
             │
             ▼
┌──────────────────────────┐  • Relational database tables and constraints.
│      Database Layer      │  • Schema evolution strictly governed by Flyway SQL migrations.
└──────────────────────────┘
```

#### Backend Package Structure:
```text
src/main/java/com/smartplanner/
├── config/             # CORS configuration, Cloudinary client bean, Swagger OpenAPI config
├── security/           # JWT Token Provider, AuthTokenFilter, CustomUserDetailsService
├── common/             # GlobalExceptionHandler, ApiErrorResponse, BaseApiResponse<T>, Constants
├── auth/               # Controller, Service, DTOs (LoginRequest, RegisterRequest, AuthResponse)
├── place/              # Controller, Service, Repository, Entity, PlaceResponseDTO
├── favorite/           # Controller, Service, Repository, Entity (User - Place association)
├── itinerary/          # Controller, Service, Repository, Entity (User - Itinerary - Items)
└── review/             # Controller, Service, Repository, Entity, ReviewDTO
```

---

### 3.3. Mobile Source Code Architecture (Flutter Clean Layered Pattern)

The mobile subsystem combines **Feature-First modularity** with **3-Layer presentation isolation**:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 1. PRESENTATION LAYER                                                                  │
│    - Screens & Widgets: Pure UI declaration (StatelessWidget only).                    │
│    - Renders 4 explicit states: Initial, Loading, Success, Error (with Retry action).   │
└────────────────────────────────────────┬───────────────────────────────────────────────┘
                                         │ Dispatches Events & Listens to States
                                         ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 2. DOMAIN / STATE MANAGEMENT LAYER (flutter_bloc)                                      │
│    - Bloc / Cubit: Receives UI events $\to$ calls Data Repositories $\to$ emits States.│
│    - Completely decouples visual widgets from network clients and storage drivers.     │
└────────────────────────────────────────┬───────────────────────────────────────────────┘
                                         │ Invokes Asynchronous Data Methods (Future)
                                         ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 3. DATA / INFRASTRUCTURE LAYER                                                         │
│    - Data Sources: Dio Client (HTTP REST API), SecureStorageService (Token Keystore).  │
│    - Mappers / Models: Deserializes JSON payloads into immutable Dart Model classes.   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

#### Mobile Directory Structure:
```text
lib/
├── app/                # App entry (main.dart), App Router (go_router), Theme (Material 3)
├── core/
│   ├── network/        # Dio Client, AuthInterceptor (Token Rotation), ErrorMapper
│   ├── storage/        # Secure Storage Service (Keystore / Keychain Token management)
│   ├── widgets/        # Shared components: AppButton, AppLoading, ErrorRetry, CachedImage
│   └── constants/      # AppColors, ApiEndpoints, AssetPaths
└── features/           # Feature-First isolated modules
    ├── auth/           # presentation (login_screen), bloc (auth_bloc), data (auth_repo)
    ├── places/         # presentation (place_list, place_detail), bloc, data
    ├── favorites/      # presentation (favorite_list), bloc, data
    └── itineraries/    # presentation (itinerary_list, plan_editor), bloc, data
```

---

### 3.4. Architectural Invariants (Golden Rules)
1. **Unidirectional Dependency:** High-level layers depend on lower-level layers, never the reverse. Controllers must never invoke Repositories; Flutter UI widgets must never invoke `Dio.get()` directly.
2. **DTO Isolation:** JPA Entities must never leak out through Controller endpoints to prevent accidental data exposure and recursive JSON serialization loops.
3. **Single Responsibility Principle (SRP):** Each class owns exactly one responsibility: UI only paints widgets, Bloc only manages state, Service only processes business logic, Repository only performs queries.

---

## 4. API Contract & Data Standards

### 4.1. MVP Endpoint Catalog

| Method | Endpoint | Description | Authentication |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Register a new user account | Public |
| `POST` | `/api/v1/auth/login` | Authenticate credentials $\to$ returns Access + Refresh tokens | Public |
| `POST` | `/api/v1/auth/refresh-token` | Exchange valid Refresh Token for a new token pair | Public |
| `POST` | `/api/v1/auth/logout` | Terminate active user session / revoke token | Required |
| `GET` | `/api/v1/places` | Search, filter, and paginate points of interest | Public |
| `GET` | `/api/v1/places/{id}` | Retrieve detailed information for a specific place | Public |
| `GET` | `/api/v1/favorites` | Retrieve authenticated user's favorite places | Required |
| `POST` | `/api/v1/favorites/{placeId}` | Add place to user favorites | Required |
| `DELETE` | `/api/v1/favorites/{placeId}` | Remove place from user favorites | Required |
| `GET` | `/api/v1/itineraries` | Retrieve all personal itineraries owned by authenticated user | Required |
| `POST` | `/api/v1/itineraries` | Create a new personal travel itinerary | Required |
| `GET` | `/api/v1/itineraries/{id}` | View complete itinerary schedule and items | Required + Owner |
| `PUT` | `/api/v1/itineraries/{id}` | Update itinerary metadata or schedule items | Required + Owner |
| `DELETE` | `/api/v1/itineraries/{id}` | Delete a personal itinerary | Required + Owner |
| `GET` | `/api/v1/places/{id}/reviews` | Retrieve public reviews and ratings for a place | Public |
| `POST` | `/api/v1/places/{id}/reviews` | Submit user review and rating score | Required |

### 4.2. Unified Error Response Specification
All error responses from the backend adhere strictly to the following JSON structure accompanied by a distributed **`traceId`**:

```json
{
  "timestamp": "2026-10-18T10:00:00Z",
  "status": 400,
  "code": "VALIDATION_FAILED",
  "message": "Input validation error occurred.",
  "fieldErrors": {
    "email": "Email must be a valid formatted address.",
    "password": "Password must contain at least 8 characters."
  },
  "path": "/api/v1/auth/register",
  "traceId": "req-98f2b31a-4c2e"
}
```

### 4.3. Standardized Pagination Schema
Paginated queries (e.g., `GET /api/v1/places`) return a standardized envelope:

```json
{
  "content": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "The Coffee House - Landmark 81",
      "category": "CAFE",
      "address": "Floor B1, Landmark 81, Binh Thanh, HCMC",
      "imageUrl": "https://res.cloudinary.com/.../landmark.webp",
      "priceLevel": 2,
      "averageRating": 4.6,
      "totalReviews": 35
    }
  ],
  "pageNumber": 0,
  "pageSize": 10,
  "totalElements": 48,
  "totalPages": 5,
  "isLast": false
}
```

---

## 5. Quality Assurance & Quality Gates

### 5.1. Definition of Done (DoD)
A feature ticket is considered **DONE** only when:
- [ ] Unit tests pass and build succeeds cleanly in GitHub Actions CI.
- [ ] Backend: Jakarta validation is applied to all input DTOs and ownership checks are verified.
- [ ] Mobile: UI renders all 4 lifecycle states: `Loading`, `Success`, `Error` (with Retry), `Empty`.
- [ ] Zero secrets, `.env` files, or production credentials are committed to Git.
- [ ] Pull Request is reviewed and approved by the peer engineer before merging to `main`.

### 5.2. Mobile Edge Cases Verification Checklist
Before handing off a screen, Engineer B must test:
1. **Network Disruption:** Toggling Airplane mode $\to$ app displays a polite error banner with a retry action without crashing.
2. **Keyboard Overflow:** Opening the virtual keyboard produces zero yellow/black striped overflow errors (wrapped in `SingleChildScrollView`).
3. **Text Clipping:** Extra-long location titles (3+ lines) are cleanly handled with `maxLines` and `TextOverflow.ellipsis`.
4. **Debounced Actions:** Rapid double-clicking on submit buttons is prevented (button disables immediately upon tap).

---

## 6. Enterprise Security Shield

Security is designed in depth across 6 protective barriers:

```text
[ Mobile Client: Cleartext HTTP Blocked + Keystore/Keychain Hardware Encryption ]
                                     │ (HTTPS Only)
                                     ▼
[ Network Layer: Rate Limiting (Brute-Force Guard) + CORS Whitelist ]
                                     │
                                     ▼
[ Authentication: Spring Security JWT (Access 30m + Refresh Token Rotation 7d) ]
                                     │
                                     ▼
[ Application Layer: Ownership Authorization + Jakarta Input DTO Validation ]
                                     │
                                     ▼
[ Data Layer: 100% Parameterized JPA Queries + Flyway Versioned Migrations ]
                                     │
                                     ▼
[ Secrets Management: GitHub Actions Secrets & Render Environment Variables ]
```

1. **Rate Limiting:** Auth endpoints (`/login`, `/register`) are capped at 5 attempts per minute per IP to thwart brute-force password guessing (returns `429 Too Many Requests`).
2. **Zero Hardcoded Secrets:** Production credentials reside exclusively in **GitHub Repository Secrets** and **Render Environment Settings**.
3. **Hardware Storage:** Access and Refresh tokens on mobile devices are secured using hardware-backed AES-256 keys via `flutter_secure_storage`.
4. **Injection Immunity:** All SQL interaction is conducted through Spring Data JPA parameterized bindings. String concatenation in SQL statements is strictly prohibited.

---

## 7. Action Plan & Milestone Roadmaps

* **Sprint 0: Setup Foundation (Current)**
  - Engineer A: Spring Boot 3 initialization, `docker-compose.yml` for local PostgreSQL, initial Flyway migration script `V1__init_schema.sql`, global exception handler, Actuator healthcheck.
  - Engineer B: Flutter skeleton initialization, Material 3 theme, BLoC configuration, Dio `AuthInterceptor`, secure storage wrapper.
  - Both: GitHub Actions CI workflow setup, repository hygiene enforcement.
* **Sprint 1: The First Vertical Slice**
  - Implement full end-to-end Place Discovery flow:
    $$\text{Flutter PlaceScreen} \longleftrightarrow \text{Spring Boot GET /api/v1/places} \longleftrightarrow \text{PostgreSQL places table}$$
  - Install debug APK on physical Android device and verify pagination and image caching.
* **Sprint 2: Authentication & Favorites**
  - Implement User Registration, Login, Token Rotation, and Favorite places management.
* **Sprint 3: Personal Itineraries Management**
  - Implement multi-day itinerary CRUD with strict ownership verification.
* **Sprint 4: Cloud Deployment & Release**
  - Provision Neon.tech managed PostgreSQL database.
  - Deploy Spring Boot backend container to Render.com.
  - Trigger automated release build pipeline to produce downloadable `.apk` artifacts in GitHub Releases.
