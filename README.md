# Smart Local Planner

[![Java](https://img.shields.io/badge/Java-21%20LTS-orange.svg)](https://openjdk.org/projects/jdk/21/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.4-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Material%203-blue.svg)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16%20Alpine-blue.svg)](https://www.postgresql.org/)
[![Flyway](https://img.shields.io/badge/Flyway-Migration%20Enabled-red.svg)](https://flywaydb.org/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%26%20BLoC-purple.svg)](docs/ARCHITECTURE_BLUEPRINT.md)
[![License](https://img.shields.io/badge/License-MIT-success.svg)](LICENSE)

> **Enterprise-grade Intelligent Local Place Discovery & Travel Itinerary Planning Platform**  
> A collaborative fullstack system integrating **Backend (Spring Boot 3, Java 21)** and **Mobile (Flutter BLoC)** following rigorous enterprise architectural, security, and clean code standards.

---

## 📌 1. Architecture Blueprint & System Contracts

All architectural standards, engineering guidelines, API specifications, and Architecture Decision Records (ADRs) are documented in:

* 📐 **[docs/ARCHITECTURE_BLUEPRINT.md](docs/ARCHITECTURE_BLUEPRINT.md)** — Comprehensive System Architecture Specification (Technical English).
* 📖 **[docs/DEVELOPMENT_GUIDELINES.md](docs/DEVELOPMENT_GUIDELINES.md)** — Clean Coding Standards, 3-Layer Isolation, and Quality Gate Checklist.
* 📡 **[docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md)** — Complete Request/Response JSON Contract for all 14 MVP Endpoints.
* 🗄️ **[docs/schema.sql](docs/schema.sql)** — Production-ready PostgreSQL 16 DDL Schema (UUID v4, Foreign Keys, B-Tree & Spatial Indexes).
* 🏛️ **[docs/adr/README.md](docs/adr/README.md)** — Architecture Decision Records Index (ADR 0001 through 0005).

---

## 🛠️ 2. Core Technology Stack (100% Free & Production-Ready)

| Subsystem | Technology | Purpose & Responsibility | Assigned Role |
|---|---|---|:---:|
| **Mobile App** | **Flutter (Material 3) + Dart** | Cross-platform UI (Android & iOS) | Mobile Engineer (Engineer B) |
| **State Management** | **`flutter_bloc`** | Unidirectional State Management (`Event -> Bloc -> State`) | Mobile Engineer (Engineer B) |
| **Mobile Network** | **`dio` + Interceptors** | HTTP Client with automated Refresh Token Rotation | Mobile Engineer (Engineer B) |
| **Backend API** | **Java 21 + Spring Boot 3.3.x** | High-performance RESTful API, DTO isolation | Backend Engineer (Engineer A) |
| **Security Shield** | **Spring Security + JWT** | Stateless Auth: Access Token (30m) & Refresh Token (7d) | Backend Engineer (Engineer A) |
| **Database Migration**| **Flyway Core** | Version-controlled, idempotent Database-as-Code | Backend Engineer (Engineer A) |
| **Database Engine** | **PostgreSQL 16 Alpine** | Local (Docker Compose) & Production (Neon.tech Serverless) | Backend Engineer (Engineer A) |
| **Asset Storage** | **Cloudinary CDN** | Cloud asset optimization, format negotiation & compression | Joint Responsibility |
| **API Testing** | **Bruno + Swagger UI** | Git-versioned open-source API testing and living docs | Joint Responsibility |

---

## 👥 3. Responsibility Assignment Matrix (Work Breakdown by Sprint)

To ensure strict accountability and clear boundaries, responsibilities are partitioned by Sprint and functional domain:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ WORK BREAKDOWN & OWNERSHIP MATRIX                                                      │
├──────────┬──────────────────────────────────────────┬──────────────────────────────────┤
│ Milestone│ Backend Engineer (Engineer A)            │ Mobile Engineer (Engineer B)     │
├──────────┼──────────────────────────────────────────┼──────────────────────────────────┤
│ Sprint 0 │ - Docker Compose & PostgreSQL 16 Alpine  │ - Flutter SDK & Material 3 Theme │
│ (Done)   │ - Spring Boot 3 Skeleton & Actuator      │ - Clean Architecture Scaffolding │
│          │ - Flyway Schema Migrations (`V1`)        │ - Dio Network Client & Storage   │
│          │ - Security Config & CORS Whitelist       │ - Bruno API Collection Setup     │
├──────────┼──────────────────────────────────────────┼──────────────────────────────────┤
│ Sprint 1 │ - `Place` JPA Entity & Repository        │ - `PlaceListScreen` & Infinite   │
│ (Active) │ - Search, Category & Geo Filter Queries  │   Scroll Pagination UI           │
│          │ - Paginated DTOs (`PlaceResponseDto`)    │ - `PlaceBloc` (4-State Contract) │
│          │ - `GET /api/v1/places` & `places/{id}`   │ - Cloudinary Cached Image Widget │
├──────────┼──────────────────────────────────────────┼──────────────────────────────────┤
│ Sprint 2 │ - JWT Authentication Service             │ - `LoginScreen` & `RegisterScreen│
│          │ - Token Rotation (`refresh-token` flow)  │ - Hardware Keystore Integration  │
│          │ - User Favorites API (`/api/v1/favorites`)│ - Bookmark Toggle & State Sync  │
├──────────┼──────────────────────────────────────────┼──────────────────────────────────┤
│ Sprint 3 │ - Itinerary Multi-day CRUD Service       │ - `ItineraryScreen` & Timeline   │
│          │ - Strict Ownership Authorization Checks  │ - Drag-and-drop Schedule Editor  │
│          │ - Place Reviews & Rating Aggregation API │ - User Review Submission Modal   │
├──────────┼──────────────────────────────────────────┼──────────────────────────────────┤
│ Sprint 4 │ - Provision Managed Neon.tech PostgreSQL │ - Physical Android Device QA     │
│          │ - Containerize Backend to Render.com     │ - Offline & Edge Case Handling   │
│          │ - Continuous Deployment (CD Pipeline)    │ - GitHub Releases APK Build (.apk│
└──────────┴──────────────────────────────────────────┴──────────────────────────────────┘
```

---

## 🏛️ 4. Clean Architecture & Layer Decoupling

Following enterprise decoupling standards, both subsystems operate strictly with unidirectional dependencies:

### Backend 3-Tier Layer Boundaries
```
HTTP Request
     │
     ▼
[ Controller Layer ]  ──► Ingests Request DTOs, triggers Jakarta Validation (@Valid), returns HTTP Status
     │
     ▼
[  Service Layer   ]  ──► Core business logic, data transformation, @Transactional integrity
     │
     ▼
[ Repository Layer ]  ──► Spring Data JPA parameterized queries, returns Entities (Never leaks to Controller)
     │
     ▼
[  PostgreSQL 16   ]  ──► Managed strictly via Flyway Versioned Migrations
```

### Mobile Feature-First BLoC Architecture
```
[ Presentation (UI) ] ──( Dispatches Event )──► [      BLoC Layer      ]
          ▲                                             │
          │                                      ( Invokes Methods )
          │                                             ▼
          └───────( Emits Immutable State )───── [ Repository & Dio HTTP ]
```

---

## 📂 5. Repository Scaffolding & Directory Breakdown

```text
smart-local-planner/
├── .github/                           # GitHub Enterprise Standards
│   ├── PULL_REQUEST_TEMPLATE.md       # Mandatory Definition of Done (DoD) Checklist
│   └── workflows/
│       └── ci.yml                     # Automated Maven Compile & Verification Pipeline
├── docs/                              # Architecture Blueprints, API Contracts & ADRs
│   ├── ARCHITECTURE_BLUEPRINT.md      # Full system technical specification
│   ├── DEVELOPMENT_GUIDELINES.md      # Clean Code standards & Git rules
│   ├── API_SPECIFICATION.md           # 14 REST endpoint contracts
│   ├── schema.sql                     # Complete PostgreSQL 16 schema
│   └── adr/                           # Architecture Decision Records 0001 - 0005
├── backend/                           # Spring Boot 3 REST API Service
│   ├── src/main/java/com/smartplanner/
│   │   ├── config/                    # SecurityConfig, CorsConfig, SwaggerOpenApiConfig
│   │   ├── common/                    # GlobalExceptionHandler, Standard ErrorResponse DTOs
│   │   ├── modules/                   # auth, places, favorites, itineraries
│   │   │   ├── controller/            # REST API Endpoints receiving Request DTOs
│   │   │   ├── service/               # Domain Business Logic & @Transactional boundaries
│   │   │   ├── repository/            # Spring Data JPA Interfaces
│   │   │   ├── entity/                # JPA Database Entities (Isolated from presentation)
│   │   │   └── dto/                   # Immutable Request/Response Record DTOs
│   │   └── BackendApplication.java    # Application Entrypoint
│   ├── src/main/resources/
│   │   ├── application.yml            # Dynamic 12-Factor Configuration
│   │   └── db/migration/              # Flyway Versioned Migrations (V1, V2...)
│   └── pom.xml                        # Maven dependencies & build plugins
├── mobile/                            # Flutter Mobile Client (Clean Architecture)
│   ├── README.md                      # Dedicated Developer Onboarding Guide for Mobile
│   └── lib/
│       ├── app/                       # Router (go_router), Theme (Material 3), main.dart
│       ├── core/                      # Network (Dio + Interceptor), SecureStorage, Widgets
│       └── features/                  # Vertical modules: auth, places, favorites, itineraries
│           ├── presentation/          # Stateless Widgets & Screens (4-State Contract)
│           ├── bloc/                  # flutter_bloc Event, State & Bloc logic
│           └── data/                  # Feature Repositories, DataSources & JSON Mappers
├── bruno/                             # Git-native Bruno API Testing Collection
│   ├── README.md                      # Quickstart guide for executing Bruno requests
│   └── bruno.json                     # Collection configuration
├── docker-compose.yml                 # Local PostgreSQL 16 container definition
├── .env.example                       # Environment Variable Template (Zero Secrets Policy)
├── .dockerignore                      # Build cache and sensitive file exclusion
├── .gitignore                         # Comprehensive ignore rules for OS, IDE, and build caches
└── README.md                          # Repository Entrypoint & Engineering Manual
```

---

## ⚙️ 6. Twelve-Factor Configuration & Dynamic Environments

In alignment with [The Twelve-Factor App methodology (III. Config)](https://12factor.net/config), this platform enforces strict separation of configuration from code:

* **Zero Hardcoded Secrets:** Passwords, API keys, and connection strings are strictly injected via Environment Variables. No production credentials exist within Git.
* **Environment Agnostic:** The application reads from environment variables with sensible local fallback defaults defined in `backend/src/main/resources/application.yml`:
  ```yaml
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:smart_local_planner}
    username: ${DB_USER:postgres}
    password: ${DB_PASSWORD:postgres}
  ```
  - **Local Development:** When run locally, it effortlessly connects to Docker Compose on `localhost:5432`.
  - **Cloud Production (Sprint 4):** When deployed to Render.com and Neon.tech, the same compiled artifact seamlessly adapts to Cloud environment variables (`DB_HOST`, `DB_USER`, `DB_PASSWORD`) with **zero code modifications**.

---

## ⚡ 7. Developer Quickstart

### Prerequisites:
- **Docker Desktop** (or Docker Engine with Compose V2).
- **Java 21 LTS** (Eclipse Temurin or Oracle OpenJDK).
- **Maven 3.9+** (or use bundled `./mvnw` wrapper).
- **Flutter SDK 3.x** (for mobile development).
- **Bruno API Client** (optional, for direct API verification).

---

### Step 1: Start PostgreSQL Database (Docker)
From the project root `smart-local-planner/`, start the container in detached mode:
```bash
docker compose up -d
```
> Verify container status: `smart_local_planner_db` should report `healthy` on `localhost:5432`.

### Step 2: Start Spring Boot Backend
Open `backend/` in IntelliJ IDEA or launch via terminal:
```bash
cd backend
./mvnw spring-boot:run
```
*Flyway automatically executes pending migrations (`V1__init_schema.sql`) on startup.*

### Step 3: Verify API Health & Documentation
Once the server reports `Started BackendApplication in X seconds`:
* **Interactive Swagger UI:** [http://localhost:8080/swagger-ui/index.html](http://localhost:8080/swagger-ui/index.html)
* **Actuator Health Check:** [http://localhost:8080/actuator/health](http://localhost:8080/actuator/health) (Returns `{"status":"UP"}`)
* **Automated API Testing:** Open `bruno/` directory within Bruno to execute the test collection.

### Step 4: Run Flutter Mobile App
Refer to the dedicated mobile setup guide: **[mobile/README.md](mobile/README.md)**.

---

## 🌿 8. Git Branching Strategy & Collaboration Workflow

This project adheres strictly to **Trunk-Based / GitFlow Integration Branching**:

```
[main] ───────────────────────────────────────────────► Stable Production Releases (Protected)
   ▲
   │ (Sprint Review Pull Request)
[develop] ────────────────────────────────────────────► Integration Baseline (DEFAULT BRANCH)
   ▲                     ▲
   │ (PR Backend)        │ (PR Mobile)
[feature/backend-...] [feature/flutter-...]           ► Short-lived Feature Branches
```

### Collaboration Rules:
1. **Default Branch:** `develop` is the default integration branch. All feature branches must branch off `develop` and open Pull Requests against `develop`.
2. **Branch Naming Conventions:**
   - Backend Features: `feature/backend-<task-name>` (e.g., `feature/backend-places`)
   - Mobile Features: `feature/flutter-<task-name>` (e.g., `feature/flutter-places`)
   - Bugfixes: `fix/<issue-description>`
3. **Conventional Commits Standard:**
   - `feat(places): implement place search endpoint with pagination`
   - `fix(auth): prevent token race condition during refresh rotation`
   - `docs(readme): standardize documentation into technical english`
4. **Zero Direct Commits:** Never commit directly to `main` or `develop`. All changes require a Pull Request with an associated Definition of Done (DoD) checklist and test evidence.

---

## 👥 9. Engineering Roles & Core Ownership

* **Backend Software Engineer (Engineer A):** RESTful API Architecture, Database Schema Evolution, Security Implementation & Cloud Deployment.
* **Mobile Software Engineer (Engineer B):** Flutter UI/UX Engineering, BLoC State Management, Network Client Integration & Mobile Edge Cases.
