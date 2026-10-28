# CI/CD Evolution Roadmap & Quality Gate Architecture

> **Project:** Smart Local Planner  
> **Applies to:** `.github/workflows/ci.yml`  
> **Core Principle:** *CI/CD must evolve concurrently with the project maturity stage.* Avoid premature over-enforcement when initial code has not been authored, but progressively elevate quality gates across Sprints to achieve enterprise-grade stability (benchmarked against production-grade systems like `eform`).

---

## Sprint-by-Sprint CI Evolution Map

```text
[ Sprint 0: Foundation ] ──► [ Sprint 1: Dual Gate & Hardening ] ──► [ Sprint 2: Fullstack Auth ] ──► [ Sprint 3+: Release ]
  - Java 21 LTS Setup          - Backend Unit Tests (20/20)         - Integration Auth Tests     - Docker Build Verification
  - Maven Dependency Cache     - Flutter Analyze & Test (8/8)       - JWT Security Validation    - Sonatype / Trivy Security
  - mvn test-compile           - CI Timeouts & Concurrency Cancel   - Token Rotation Tests       - Multi-platform Quality Gate
```

---

## Phase 1: Sprint 0 (Infrastructure Foundation - Completed)

### Objective
Guarantee that Java 21 backend builds and compiles cleanly, dependencies are cached, line endings are normalized, and developers are not prematurely blocked before test suites exist.

### Active Workflow Configuration
* **Triggers:** `push` and `pull_request` targeting `develop` and `main`.
* **Runner:** `ubuntu-latest`.
* **Actions:** `actions/checkout@v4`, `actions/setup-java@v4` (Java 21 LTS, Eclipse Temurin, `cache: 'maven'`).
* **JVM Tuning:** `MAVEN_OPTS: "-Xmx2048m -XX:+TieredCompilation -XX:TieredStopAtLevel=1"`.
* **Verification Command:**
  ```bash
  mvn -B clean test-compile
  ```
* **Rationale:** Validates Maven POM dependencies and bytecode compilation without failing due to zero existing test cases.

---

## Phase 2: Sprint 1 (Dual Quality Gate & CI Hardening - Completed)

### Objective
Enforce strict 100% test pass rate across both Spring Boot 3 backend and Flutter mobile client on all Pull Requests targeting `develop`, bounded with execution timeouts and concurrency controls (`[SLP-4]`, `[SLP-6]`, `[SLP-14]`).

### Active Production Workflow Configuration (`.github/workflows/ci.yml`)
* **Concurrency:** `cancel-in-progress: true` keyed by `${{ github.workflow }}-${{ github.ref }}` (auto-cancels redundant runs).
* **Job 1: `backend-build-check`** (Java 21 Temurin, Maven cache, `timeout-minutes: 10`, `mvn -B clean test`).
* **Job 2: `mobile-build-check`** (Java 17 Temurin, Flutter stable SDK, pub cache, `timeout-minutes: 10`, `flutter analyze` + `flutter test`).

### Quality Gate Enforcement
* Any commit breaking unit tests, contracts, or Dart static analysis triggers **CI Failure ➔ Block Merge**.

---

## Phase 3: Sprint 2 (Authentication & Token Security Quality Gates)

### Objective
As stateless JWT authentication, refresh token rotation, and hardware keystore bookmarking are introduced: expand quality gates to enforce integration test coverage, secure storage tests, and auth error-mapping specifications.

---

## Phase 4: Sprint 3 & Production Quality Gate

### Objective
Achieve full parity with enterprise compliance standards across 5 architectural pillars: Backend, Mobile, DevSecOps Security, Infrastructure Containers, and Database Integrity.

---

## Five Pillars of Enterprise CI Architecture

```mermaid
graph TD
    Trigger[PR / Push to develop] --> P1[Pillar 1: Backend Java 21 Quality Gate]
    Trigger --> P2[Pillar 2: Mobile Flutter Quality Gate]
    Trigger --> P3[Pillar 3: DevSecOps Security Scan]
    Trigger --> P4[Pillar 4: Infra & Docker Verification]
    Trigger --> P5[Pillar 5: Database Migration Integrity]
```

### 1. Pillar 1: Backend Java 21 Quality Gate
* **Purpose:** Ensure clean 3-layer architecture, zero compiler warnings, and test coverage adherence.
* **Steps:**
  1. `actions/checkout@v4` & `actions/setup-java@v4` (Java 21 LTS, Temurin, Maven caching).
  2. `mvn spotless:check` or `checkstyle:check` (Google Java Format compliance, no unused imports).
  3. `mvn clean test` (Mocked Unit Tests via Mockito & JUnit 5).
  4. `jacoco:report` (Code coverage verification threshold: > 70%).

### 2. Pillar 2: Mobile Flutter Quality Gate
* **Purpose:** Verify cross-platform client integrity and BLoC state transition invariants.
* **Steps:**
  1. `subosito/flutter-action@v2` (`stable` channel, pub cache enabled).
  2. `flutter pub get` (Resolve dependency graphs).
  3. `flutter analyze` (Static analysis for null-safety, dead code, and lint rules).
  4. `flutter test --coverage` (Headless unit & widget tests; under 45 seconds).

### 3. Pillar 3: DevSecOps Security Scan
* **Purpose:** Prevent secret leaks and vulnerable third-party dependencies (analogous to Nancy in `eform`).
* **Steps:**
  1. **Secret Leak Detection (TruffleHog):** Scans git commit diffs for leaked `.env`, database credentials, Google Maps API keys, or JWT secrets.
  2. **Dependency Vulnerability Scan (Trivy / Dependabot):** Scans `pom.xml` and `pubspec.lock` against public CVE databases.

### 4. Pillar 4: Infrastructure & Container Verification
* **Purpose:** Ensure container definitions are production-hardened and secure.
* **Steps:**
  1. `hadolint`: Lints `backend/Dockerfile` (blocks root user execution, unpinned base images).
  2. `reviewdog/action-yamllint`: Validates syntax of `docker-compose.yml` and `.github/workflows/*.yml`.
  3. `docker build`: Smoke tests backend container packaging without deploying.

### 5. Pillar 5: Database Migration Integrity (Flyway Check)
* **Purpose:** Prevent production schema corruption caused by malformed SQL scripts or checksum alterations.
* **Steps:**
  1. Spin up ephemeral PostgreSQL 16 service container in GitHub Actions.
  2. Execute `mvn flyway:migrate` to verify that all historical scripts (`V1__...`, `V2__...`) execute idempotently.

---

## Risk & Trade-off Evaluation Matrix

| Inspection Step | Potential Pitfall If Misconfigured | Enterprise Best Practice Solution |
| :--- | :--- | :--- |
| **Dependency Vulnerability Scanning** | Traditional OWASP CLI downloads 2GB NVD database on every run ➔ **10-15 minute CI runtime and timeouts.** | Use **Trivy Action** or native **GitHub Dependabot** ➔ Scans complete in under 15 seconds. |
| **Flutter Mobile CI** | Compiling physical `.apk` or `.ipa` on every commit ➔ Consumes 8-10 minutes and exhausts monthly GitHub minutes. | Run only `flutter analyze` and `flutter test` in headless mode (40s). Build APKs exclusively on Release Tags. |
| **Linter / Static Analysis** | Overly pedantic styling rules (failing builds on minor whitespace or missing trivial javadoc) ➔ Frustrates engineers. | Enforce only critical defect prevention rules (Unused imports, Null safety, Code duplication). |
| **Backend Integration Tests** | Test suites attempting to connect to `localhost:5432` without an active database ➔ `Connection Refused` CI crashes. | Isolate: Unit Tests mock dependencies via Mockito (runs in 5s). Integration Tests use ephemeral PostgreSQL service containers. |

---

## Sprint Transition Checklist

When commencing a new Sprint, the Tech Lead performs:
- [ ] **Step 1:** Review this roadmap specification (`.github/CI_ROADMAP.md`).
- [ ] **Step 2:** Identify the target Sprint quality gate requirements.
- [ ] **Step 3:** Create a working branch: `feat/ci-sprint-<X>`.
- [ ] **Step 4:** Incorporate the corresponding job configurations into `.github/workflows/ci.yml`.
- [ ] **Step 5:** Validate green execution on the feature branch before opening PR into `develop`.
