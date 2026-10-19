# Smart Local Planner

[![Java](https://img.shields.io/badge/Java-21%20LTS-orange.svg)](https://openjdk.org/projects/jdk/21/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.4-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Material%203-blue.svg)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16%20Alpine-blue.svg)](https://www.postgresql.org/)
[![Flyway](https://img.shields.io/badge/Flyway-Migration%20Enabled-red.svg)](https://flywaydb.org/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%26%20BLoC-purple.svg)](docs/ARCHITECTURE_BLUEPRINT.md)

> **Enterprise-grade Intelligent Local Place Discovery & Travel Itinerary Planning Platform**  
> A collaborative fullstack system integrating **Backend (Spring Boot 3, Java 21)** and **Mobile (Flutter BLoC)** following rigorous enterprise architectural and security standards.

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

## 📂 3. Repository Scaffolding

```text
smart-local-planner/
├── .github/                           # GitHub Enterprise Standards
│   ├── PULL_REQUEST_TEMPLATE.md       # Mandatory Definition of Done (DoD) Checklist
│   └── workflows/
│       └── ci.yml                     # Automated Maven Compile & Verification Pipeline
├── docs/                              # Architecture Blueprints, API Contracts & ADRs
├── backend/                           # Spring Boot 3 REST API Service
│   ├── src/main/resources/db/migration/ # Flyway Migration Scripts (V1, V2...)
│   └── pom.xml                        # Maven dependencies & plugins
├── mobile/                            # Flutter Mobile Client (Clean Architecture)
│   ├── README.md                      # Dedicated Developer Onboarding Guide for Mobile
│   └── lib/                           # app/, core/, features/ (auth, places, itineraries)
├── bruno/                             # Git-native Bruno API Testing Collection
│   ├── README.md                      # Quickstart guide for executing Bruno requests
│   └── bruno.json
├── docker-compose.yml                 # Local PostgreSQL 16 container definition
├── .env.example                       # Environment Variable Template (Zero Secrets Policy)
├── .dockerignore                      # Build cache and sensitive file exclusion
├── .gitignore                         # Comprehensive ignore rules for OS, IDE, and build caches
└── README.md                          # Repository Entrypoint & Engineering Manual
```

---

## ⚡ 4. Developer Quickstart

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

## 🌿 5. Git Branching Strategy & Collaboration Workflow

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

## 👥 6. Engineering Roles & Ownership

* **Backend Software Engineer (Engineer A):** RESTful API Architecture, Database Schema Evolution, Security Implementation & Cloud Deployment.
* **Mobile Software Engineer (Engineer B):** Flutter UI/UX Engineering, BLoC State Management, Network Client Integration & Mobile Edge Cases.
