# Developer Playbook & Contribution Guide

> **Project:** Smart Local Planner  
> **Status:** Sprint 0 Foundation Complete ➔ Entering Sprint 1  
> **Target Audience:** All Engineers (Backend, Mobile), AI Agents, and Code Reviewers  
> **Standard:** Enterprise Greenfield Guidelines & Zero-Tolerance Pitfall Prevention

---

## 📌 1. Welcome & Engineering Philosophy

Welcome to **Smart Local Planner**! This repository is engineered following strict enterprise architectural patterns. To maintain velocity, code health, and zero merge headaches across the team, all contributors **must strictly comply** with this guide.

---

## ⛔ 2. The 5 Zero-Tolerance Pitfalls (Critical Engineering Constraints)

Before writing any code, memorize these 5 non-negotiable rules. Violating any of these will cause GitHub CI or PR Review to reject your code immediately.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 🛑 5 ZERO-TOLERANCE ANTI-PATTERNS                                                      │
├────────────────────────────────┬───────────────────────────────────────────────────────┤
│ ❌ PITFALL                     │ 🛡️ MANDATORY RULE & CORRECT ACTION                     │
├────────────────────────────────┼───────────────────────────────────────────────────────┤
│ 1. Modifying Past Migrations   │ NEVER touch existing V1__... files! Always create a   │
│    (Flyway Checksum Mismatch)  │ new incremental V2__...sql script.                    │
├────────────────────────────────┼───────────────────────────────────────────────────────┤
│ 2. Direct Push to Protected    │ NEVER push directly to develop or main! Always branch │
│    Branches                    │ off develop via feat/<domain>-<task> and open a PR.   │
├────────────────────────────────┼───────────────────────────────────────────────────────┤
│ 3. Secret & Credential Leak    │ NEVER commit .env, passwords, or cloud API keys.      │
│                                │ Only .env.example with dummy values is tracked.       │
├────────────────────────────────┼───────────────────────────────────────────────────────┤
│ 4. Architectural Violation     │ Backend: Controllers must NEVER return JPA Entities.  │
│    (Layer Bleeding)            │ Mobile: UI must handle all 4 states (Loading/OK/Err/0)│
├────────────────────────────────┼───────────────────────────────────────────────────────┤
│ 5. Vague Git Commit Messages   │ Commits like "fix", "wip", "update" are forbidden!    │
│                                │ Must follow: <type>(<scope>): <subject>               │
└────────────────────────────────┴───────────────────────────────────────────────────────┘
```

---

## 🗄️ 3. Database Migration Protocol (Flyway Immutability)

Flyway calculates a **cryptographic SHA-256 checksum** of every migration file upon first execution and records it in `flyway_schema_history`.

### ❌ The Deadly Mistake
Modifying an already executed migration (e.g. editing `V1__init_schema.sql` to alter a column).  
**Consequence:** Next time the app starts, Flyway throws:
`FlywayValidateException: Migration checksum mismatch for migration version 1` and crashes.

### ✅ The Enterprise Standard
1. Leave `V1__init_schema.sql` untouched forever.
2. Create a new file under `backend/src/main/resources/db/migration/`:
   ```text
   V2__add_phone_to_users.sql
   ```
3. Write standard DDL:
   ```sql
   ALTER TABLE users ADD COLUMN phone VARCHAR(20);
   ```

### 🚨 Emergency Local Recovery (If you broke your local DB)
* **Option A (Revert file):**
  ```bash
  git restore backend/src/main/resources/db/migration/V1__init_schema.sql
  ```
* **Option B (Flyway repair):**
  ```bash
  ./mvnw flyway:repair
  ```
* **Option C (Fresh Docker Reset - Takes 3 seconds):**
  ```bash
  docker compose down -v && docker compose up -d
  ```

---

## 🌿 4. Standard Daily Git Workflow

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

### Step 1: Start your day with latest code
```bash
git switch develop
git pull origin develop
```

### Step 2: Create a feature branch
```bash
# For backend tasks:
git switch -c feat/backend-<task-name>

# For mobile tasks:
git switch -c feat/mobile-<task-name>
```

### Step 3: Write code & test locally
Verify that your changes compile and pass tests before pushing:
```bash
# Backend verification:
cd backend
./mvnw clean test-compile

# Mobile verification:
cd mobile
flutter analyze
```

### Step 4: Commit with Conventional Commits
Format: `<type>(<scope>): <subject>`

```bash
git add .
git commit -m "feat(places): add search endpoint with pagination"
git push -u origin feat/backend-<task-name>
```

### Step 5: Open Pull Request
* Go to GitHub: Base = `develop` ⬅️ Compare = `feat/backend-<task-name>`.
* Write a concise 2-sentence description of what was implemented.
* Attach a screenshot or test evidence if applicable.
* Request 1 review from your teammate.

---

## 🛠️ 5. Troubleshooting Common Issues

| Issue / Error | Root Cause | Instant Fix |
| :--- | :--- | :--- |
| `bash: ./mvnw: Permission denied` | Git lost the Linux executable bit | Run `git update-index --chmod=+x backend/mvnw` and push. |
| `Git LF will be replaced by CRLF` | Windows vs Linux line endings | Repository has `.gitattributes` configured; Git handles this automatically. |
| `Protected branch hook declined` | Attempted direct push to `develop` | You cannot push to `develop`. Create a `feat/...` branch and open a PR. |
| `Exit code 137 (OOM Killer)` | Maven exceeded runner memory limit | `MAVEN_OPTS` is configured to `-Xmx2048m` in `ci.yml` to prevent this. |

---

## 📖 6. Associated Documentation Links

* System Architecture: [docs/ARCHITECTURE_BLUEPRINT.md](docs/ARCHITECTURE_BLUEPRINT.md)
* Coding Guidelines: [docs/DEVELOPMENT_GUIDELINES.md](docs/DEVELOPMENT_GUIDELINES.md)
* API JSON Specification: [docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md)
* CI Roadmap & Evolution: [.github/CI_ROADMAP.md](.github/CI_ROADMAP.md)
* GitHub Workflow Audit: [personal/GitHub_Workflow_Checklist_and_Audit_Smart_Local_Planner.md](personal/GitHub_Workflow_Checklist_and_Audit_Smart_Local_Planner.md)
