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

## 1. Documentation & Technical Specifications

To ensure architectural integrity and frictionless developer onboarding, all system specifications are maintained as living contracts:

| Domain | Document | Target Audience & Purpose |
| :--- | :--- | :--- |
| **System Design** | **[Architecture Blueprint](docs/ARCHITECTURE_BLUEPRINT.md)** | Full system architecture, layer decoupling & concurrency model |
| **API Contract** | **[API Specification](docs/API_SPECIFICATION.md)** | Single Source of Truth for all REST JSON request/response contracts |
| **Decisions** | **[Architecture Decision Records](docs/adr/README.md)** | Formal ADR history (ADR-0001 through ADR-0005) |
| **Onboarding** | **[Onboarding Runbook](docs/ONBOARDING.md)** | 5-minute local environment setup & battle-tested troubleshooting |
| **Process** | **[Workflow Playbook](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md)** | 7-step sprint lifecycle, branch naming, PR conventions & checklist |
| **Governance** | **[Contributing Guidelines](CONTRIBUTING.md)** | Zero-tolerance engineering red lines, code rules & [Security Policy](SECURITY.md) |

---

## 2. Core Technology Stack

| Subsystem | Technology & Runtime | Purpose & Scope | Architectural Rationale & Standards |
|---|---|---|---|
| **Mobile App** | **Flutter 3.x + Dart 3.x** | Cross-platform UI (Android & iOS) | Single codebase, declarative Material 3 design system |
| **State Management** | **`flutter_bloc`** | Reactive presentation state flow | Strict unidirectional data flow (`Event -> Bloc -> State`) |
| **Mobile Network** | **`dio` + Interceptors** | Resilient HTTP network client | Automated JWT Refresh Token Rotation on HTTP 401 |
| **Backend API** | **Java 21 LTS + Spring Boot 3.3.x** | Enterprise RESTful API services | Virtual Threads, DTO isolation, compile-time safety |
| **Security Shield** | **Spring Security 6 + JWT** | Stateless authentication pipeline | Access Token (30m) + Refresh Token (7d), BCrypt hashing |
| **Database Migration**| **Flyway Core** | Idempotent Database-as-Code | Sequential versioned SQL scripts (`V1__...`), zero auto-ddl |
| **Database Engine** | **PostgreSQL 16 Alpine** | Relational data persistence tier | Local Docker container parity with Cloud Neon Serverless |
| **Asset Storage** | **Cloudinary CDN** | Cloud media storage & optimization | On-the-fly image resizing, WebP delivery, edge caching |
| **API Testing** | **Bruno + Swagger UI** | Contract validation & living docs | Git-versioned plain text collections & interactive UI |

---

## 3. Product Milestone Roadmap (Sprint Deliverables)

The platform follows an iterative **Agile / Scrum delivery lifecycle** partitioned into five sequential milestones:

| Sprint | Focus Area | Status | Shipped Capabilities & Key Artifacts |
| :--- | :--- | :---: | :--- |
| **Sprint 0** | **Foundation & Scaffolding** | ![Done](https://img.shields.io/badge/Status-Done-brightgreen) | • Docker Compose with PostgreSQL 16 Alpine<br/>• Spring Boot 3 Skeleton & Actuator Health<br/>• Flyway Baseline Schema Migration (V1)<br/>• Flutter SDK, Material 3 Theme & BLoC Setup<br/>• Bruno Collection & GitHub Actions CI Gate |
| **Sprint 1** | **Place Discovery & Search**<br/>*(First Vertical Slice)* | ![Done](https://img.shields.io/badge/Status-Done-brightgreen) | • `places` JPA Entity, Repository & Spatial Queries<br/>• Search, Category & Price Level Filter APIs<br/>• Infinite Scroll Pagination UI (`PlaceListScreen`)<br/>• Cloudinary Cached Image Component with Fallback |
| **Sprint 2** | **Authentication & Favorites** | ![Active](https://img.shields.io/badge/Status-Active-blue) | • Stateless JWT Auth Service & Refresh Token Rotation<br/>• Spring Security Filter Chain & Rate Limiting (5 req/min)<br/>• User Favorites Collection CRUD APIs<br/>• Secure Hardware Keystore Integration (`FlutterSecureStorage`)<br/>• Bookmark Toggle with Optimistic UI Sync & `FavoriteListScreen` |
| **Sprint 3** | **Multi-Day Itineraries & Reviews** | ![Planned](https://img.shields.io/badge/Status-Planned-lightgrey) | • Multi-Day Travel Itinerary CRUD Engine<br/>• Strict Resource Ownership Guards & Access Control<br/>• Itinerary Schedule Timeline & Place Ordering<br/>• Community Reviews & Star Ratings Service |
| **Sprint 4** | **Production Release & Cloud Deploy** | ![Planned](https://img.shields.io/badge/Status-Planned-lightgrey) | • Provision Managed Neon.tech Cloud PostgreSQL<br/>• Containerized Backend Deploy on Render.com<br/>• Automated Release APK Packaging via CI/CD<br/>• End-to-End Latency & Offline UX Audit |

---

## 4. Clean Architecture & Layer Decoupling

Following enterprise decoupling standards, both subsystems operate strictly with unidirectional dependencies:

### Backend 3-Tier Layer Boundaries

```mermaid
flowchart TD
    Client["Mobile & Web<br/>Client Apps    "] -->|"HTTP / JSON"| Controller

    subgraph BackendApp ["Spring Boot 3.3.4 (Backend Application Tier)"]
        Controller["Controller Layer<br/>(REST APIs & DTOs)    "]
        Service["Service Layer<br/>(Business Logic & TX)    "]
        Repository["Repository Layer<br/>(Spring Data JPA)    "]
        
        Controller -->|"Validated DTO"| Service
        Service -->|"Invoke Operations"| Repository
    end

    subgraph PersistenceTier ["Persistence Infrastructure"]
        Postgres[("PostgreSQL 16 Alpine<br/>(Flyway Database)    ")]
    end

    Repository -->|"JDBC / SQL"| Postgres
```

| Layer | Core Responsibilities | Key Technologies & Patterns |
| :--- | :--- | :--- |
| **Controller** | Ingests request DTOs, triggers Jakarta validation (`@Valid`), enforces HTTP status codes & RFC 7807 error envelopes | `@RestController`, `@Valid`, RFC 7807 |
| **Service** | Executes core business workflows, domain authorization, DTO ↔ Entity conversion, manages transaction boundaries | `@Service`, `@Transactional` |
| **Repository** | Database communication, parameterized queries, entity isolation (never leaks entities to controllers) | Spring Data JPA, Parameterized SQL |
| **Persistence** | Relational data persistence, schema versioning, foreign keys, cascades & automated database migrations | PostgreSQL 16 Alpine, Flyway Core |

### Mobile Feature-First BLoC Architecture

```mermaid
flowchart LR
    subgraph UI_Layer ["Presentation Layer"]
        UI["UI Components<br/>(Screens & Widgets)    "]
    end

    subgraph BLoC_Layer ["State Management Layer"]
        Bloc["BLoC State Machine<br/>(Event to State)    "]
    end

    subgraph Data_Layer ["Data Infrastructure Layer"]
        Repo["Feature Repository<br/>(Domain & Cache)    "]
        Network["Dio HTTP Client<br/>(JWT & Interceptor)    "]
    end

    UI -->|"1. Dispatch Event"| Bloc
    Bloc -->|"2. Domain Request"| Repo
    Repo -->|"3. HTTP Call"| Network
    Network -->|"4. Response DTO"| Repo
    Repo -->|"5. Domain Model"| Bloc
    Bloc -->|"6. Emit State"| UI
```

| Layer | Core Responsibilities | Key Technologies & Patterns |
| :--- | :--- | :--- |
| **Presentation** | Pure declarative UI, reactive rebuilds, strictly renders the 4 mandatory states (Loading, Success, Empty, Error) | Material 3, `BlocBuilder`, `BlocListener` |
| **BLoC** | Unidirectional state machine, event handling, concurrency guard, optimistic UI updates & rollback | `flutter_bloc`, `Bloc<Event, State>` |
| **Repository** | Aggregates local cache & remote endpoints, deserializes JSON into immutable domain models | Feature Repositories, In-Memory Cache |
| **Network & Storage** | Resilient HTTP network client, automated JWT refresh token rotation on 401, hardware keystore encryption | `Dio`, `QueuedInterceptor`, `FlutterSecureStorage` |

---

## 5. Repository Structure

```text
smart-local-planner/
├── .github/                           # GitHub Enterprise Standards
│   ├── ISSUE_TEMPLATE/                # Automated Enterprise Issue Templates (Feature & Bug)
│   ├── pull_request_template.md       # Standard 3-Section PR Submission Template
│   ├── CI_ROADMAP.md                  # Evolution Guide & Multi-Sprint Quality Gates
│   └── workflows/
│       └── ci.yml                     # Automated Maven Compile & Verification Pipeline
├── docs/                              # Architecture Blueprints, API Contracts & ADRs
│   ├── ARCHITECTURE_BLUEPRINT.md      # Full system technical specification
│   ├── DEVELOPMENT_GUIDELINES.md      # Clean Code standards & Git rules
│   ├── API_SPECIFICATION.md           # REST API JSON contracts (single source of truth)
│   ├── ONBOARDING.md                  # Local setup, run & troubleshooting guide
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

## 6. Twelve-Factor Configuration & Dynamic Environments

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

## 7. Developer Quickstart

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

### Step 4: Run Flutter Mobile App (Quick Smoke Test)
Launch the client in a new terminal for fast UI validation:
```bash
cd mobile
flutter pub get

# 1. Quick smoke test on browser (Fastest UI testing, no heavy emulator required):
flutter run -d chrome    # Or Microsoft Edge: flutter run -d edge

# 2. (Optional) Launch on connected Android Emulator or Physical Device:
# flutter run -d android

# Tip: List all detected runtime devices on your machine:
# flutter devices
```
> For complete mobile engineering guides (Android Studio Emulator, Physical Device USB/Wi-Fi debugging) and network loopback details, refer to the dedicated guide: **[mobile/README.md](mobile/README.md)**.

---

## 8. Git Branching Strategy & Collaboration Workflow

This project adheres strictly to **Trunk-Based / GitFlow Integration Branching**:

```mermaid
flowchart LR
    subgraph ProtectedBases ["Protected Baseline Branches"]
        Main["main branch<br/>(Production)    "]
        Develop["develop branch<br/>(Integration)    "]
    end

    subgraph FeatureBranches ["Short-lived Topic Branches"]
        FeatBranch["feat/issue-id<br/>(Features)    "]
        FixBranch["fix/issue-id<br/>(Bugfixes)    "]
    end

    FeatBranch -->|"Squash & Merge PR"| Develop
    FixBranch -->|"Squash & Merge PR"| Develop
    Develop -->|"Sprint Release PR"| Main
```

### Collaboration Standards & Git Rules

| Discipline | Specification & Policy | Standard Pattern / Example |
| :--- | :--- | :--- |
| **Integration Baseline** | Trunk-Based flow; all feature and bugfix branches merge into `develop` | `develop` (Default) & `main` (Production) |
| **Branch Naming** | GitHub-native format linked to Issue ID (no `close` or `closes`) | `feat/<id>-<desc>` & `fix/<id>-<desc>` |
| **Commit Discipline** | Conventional Commits standard with explicit component scope | `<type>(<scope>): [SLP-X] <imperative>` |
| **PR Quality Gate** | Mandatory Lead review, dual-stack CI (Backend + Mobile) green | Code/DB mandate PRs; pure `.md` exempt |

> Detailed branch lifecycle, Red/Yellow safety lines, and emergency runbooks are documented in **[Developer Workflow Playbook](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md)**.

---

## 9. Core Engineering Domains & Governance

* **Backend Systems & Platform:** RESTful API Architecture, Database Schema Evolution (Flyway), Spring Security Pipeline, Cloud Deployment & Observability.
* **Mobile Client Engineering:** Flutter Material 3 UI/UX, BLoC State Machine, Resilient Network Interceptors, Offline Caching & Mobile Edge Cases.
* **Cross-Functional Collaboration:** API Contract Governance (Bruno/OpenAPI), Schema Reviews, and Automated CI/CD Gates.
