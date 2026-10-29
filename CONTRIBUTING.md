# Developer Playbook & Contribution Guide

> **Project:** Smart Local Planner  
> **Status:** Sprint 1 Hardening Complete ➔ Entering Sprint 2 (Authentication & Favorites)  
> **Target Audience:** All Contributing Engineers, Peer Reviewers, and AI Assistants  
> **Standard:** Enterprise Greenfield Guidelines & Zero-Tolerance Pitfall Prevention  
> **Operational Runbook:** See the comprehensive [Developer Workflow Playbook](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md) for step-by-step issue, board, and PR execution.

---

## 1. Engineering Philosophy

Welcome to **Smart Local Planner**! This repository is engineered following strict enterprise architectural patterns. To maintain velocity, code health, and zero merge headaches across the team, all contributors **must strictly comply** with this guide.

* **Project Governance & Red Lines:** Defined in this document (`CONTRIBUTING.md`).
* **Daily Sprint Execution & Board SOP:** Detailed step-by-step in [`docs/DEVELOPER_WORKFLOW_PLAYBOOK.md`](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md).
* **AI Coding Protocols & Prompt Templates:** Included in [`docs/DEVELOPER_WORKFLOW_PLAYBOOK.md §5`](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md#5-ai-pair-programming-protocol-prompting-guide).

---

## 2. Zero-Tolerance Engineering Constraints

Before writing any code, review these 5 non-negotiable rules. Violating any of these will cause GitHub CI or PR Review to reject your submission immediately.

> [!CAUTION]
> Breaking any of these constraints introduces technical debt and breaks continuous integration for the entire team.

| Pitfall | Root Risk | Mandatory Enterprise Rule |
| :--- | :--- | :--- |
| **1. Modifying Historical Migrations** | Causes `FlywayChecksumMismatch` and crashes peer databases. | **NEVER touch existing `V1__...` files.** Always create a new incremental `V2__...sql` file. |
| **2. Direct Push to Protected Branches** | Destroys branch integrity and bypasses automated tests. | **NEVER push directly to `develop` or `main`.** Always branch off `develop` via `<type>/<issue_number>-<short-description>` and submit a PR. |
| **3. Credential or Secret Leaks** | Compromises database credentials and API service keys. | **NEVER commit `.env`, passwords, or private keys.** Only `.env.example` with dummy placeholders is tracked. |
| **4. Architectural Layer Bleeding** | Couples storage layer with external HTTP transport. | **Backend:** Controllers must never return JPA Entities.<br>**Mobile:** UI must handle all 4 states (Loading, Success, Error, Empty). |
| **5. Uninformative Commit Messages** | Prevents automated changelog generation and commit auditing. | **Commits like "fix", "wip", "update" are blocked.** All commits must follow `<type>(<scope>): [SLP-X] <subject> (closes #<issue>)`. |

---

## 3. Database Migration Protocol (Flyway Immutability)

Flyway calculates a **cryptographic SHA-256 checksum** of every migration file upon first execution and records it in `flyway_schema_history`.

### Anti-Pattern: Modifying Existing Migrations
Modifying an already executed migration (e.g. editing `V1__init_schema.sql` to alter a column).  
**Consequence:** Next time the application starts, Flyway throws:
`FlywayValidateException: Migration checksum mismatch for migration version 1` and terminates the process.

### Standard: Add Incremental Migrations
1. Leave `V1__init_schema.sql` untouched forever.
2. Create a new file under `backend/src/main/resources/db/migration/`:
   ```text
   V2__add_phone_to_users.sql
   ```
3. Write standard DDL:
   ```sql
   ALTER TABLE users ADD COLUMN phone VARCHAR(20);
   ```

### Emergency Local Recovery (Resolving Local Checksum Discrepancies)
* **Option A (Revert Local File):**
  ```bash
  git restore backend/src/main/resources/db/migration/V1__init_schema.sql
  ```
* **Option B (Flyway Repair):**
  ```bash
  ./mvnw flyway:repair
  ```
* **Option C (Fresh Docker Reset - Takes 3 seconds):**
  ```bash
  docker compose down -v && docker compose up -d
  ```

---

## 4. Standard Daily Git Workflow

```mermaid
gitGraph
   commit id: "develop (stable)"
   branch feat/backend-places
   checkout feat/backend-places
   commit id: "feat(places): add entity & repo"
   commit id: "feat(places): add service & tests"
   checkout develop
   merge feat/backend-places id: "Squash & Merge (PR #5)"
```

### Step 1: Synchronize with integration baseline
```bash
git switch develop
git pull origin develop
```

### Step 2: Create a feature branch
```bash
# Branch format: <type>/<issue_number>-<short-description>
git switch -c feat/22-api-contract-alignment
# or for bug fixes / hardening:
git switch -c fix/24-android-network-readiness
```

### Step 3: Write code & test locally
Verify that your changes compile and pass tests before pushing:
```bash
# Backend verification (executes all unit tests and quality gate):
cd backend
./mvnw test

# Mobile verification (static analysis linter and test suite):
cd mobile
flutter analyze
flutter test
```

### Step 4: Commit with Conventional Commits
Format: `<type>(<scope>): [SLP-X] <subject> (closes #<issue_number>)`

```bash
git add .
git commit -m "feat(places): [SLP-2] add search endpoint with pagination (closes #22)"
git push -u origin feat/22-api-contract-alignment
```

### Step 5: Open Pull Request
* Base branch: `develop` ⬅️ Compare branch: `<type>/<issue_number>-<short-description>`.
* Use the standardized 3-section enterprise PR template:
  ```markdown
  ## Summary of Changes
  - **<Component> (`<files>`)**:
    - <Bullet item 1>
    - <Bullet item 2>

  ## Verification
  - <Test results / quality gate evidence>

  Closes #<issue_number>
  ```
* Wait for dual CI quality gate (`Spring Boot 3 Compile & Verification` and `Flutter Mobile Quality Gate`) to turn green.
* Merge PR into `develop`, delete feature branch, and sync local `develop`.

---

## 5. Troubleshooting Common Issues

| Issue / Error | Root Cause | Remediation Command |
| :--- | :--- | :--- |
| `bash: ./mvnw: Permission denied` | Git index missing Linux executable bit | Run `git update-index --chmod=+x backend/mvnw` and commit. |
| `Git LF will be replaced by CRLF` | Windows vs Linux line ending differences | Managed automatically via `.gitattributes`. |
| `Protected branch hook declined` | Attempted direct push to `develop` | Branch protection active. Create a `feat/...` branch and open a PR. |
| `Exit code 137 (OOM Killer)` | Maven process exceeded runner memory limit | `MAVEN_OPTS` is configured to `-Xmx2048m` in `ci.yml` to prevent exhaustion. |

---

## 6. Associated Documentation Links

* Step-by-Step Sprint Playbook: [docs/DEVELOPER_WORKFLOW_PLAYBOOK.md](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md)
* System Architecture: [docs/ARCHITECTURE_BLUEPRINT.md](docs/ARCHITECTURE_BLUEPRINT.md)
* Coding Guidelines: [docs/DEVELOPMENT_GUIDELINES.md](docs/DEVELOPMENT_GUIDELINES.md)
* API JSON Specification: [docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md)
* CI Roadmap & Evolution: [.github/CI_ROADMAP.md](.github/CI_ROADMAP.md)
* GitHub Workflow Audit: [personal/GitHub_Workflow_Checklist_and_Audit_Smart_Local_Planner.md](personal/GitHub_Workflow_Checklist_and_Audit_Smart_Local_Planner.md)
