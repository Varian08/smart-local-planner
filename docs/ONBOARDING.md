# Onboarding & Troubleshooting Guide

> **Audience:** New engineers and AI assistants joining Smart Local Planner.  
> **Read first:** [CONTRIBUTING.md](../CONTRIBUTING.md) (rules) → [DEVELOPER_WORKFLOW_PLAYBOOK.md](DEVELOPER_WORKFLOW_PLAYBOOK.md) (how to work) → [GitHub Projects Sprint Board](https://github.com/Varian08/smart-local-planner/projects) (what to work on).

---

## 1. Prerequisites

| Tool | Version | Check |
| :--- | :--- | :--- |
| Git | any recent | `git --version` |
| Docker Desktop | running | `docker ps` |
| JDK | 21 (Temurin) | `java -version` |
| Flutter | 3.x stable | `flutter --version` |
| IDE | IntelliJ IDEA or VS Code | — |

## 2. First-Time Setup

```bash
git clone git@github.com:Varian08/smart-local-planner.git
cd smart-local-planner
git checkout develop
cp .env.example .env        # keep real values out of Git

docker compose up -d        # PostgreSQL 16 on localhost:5432
```

Backend (Windows PowerShell):

```powershell
$env:JAVA_HOME = "C:\Users\<user>\.jdks\temurin-21.0.12.1"
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path
cd backend
.\mvnw.cmd spring-boot:run
```

Mobile:

```bash
cd mobile
flutter pub get
flutter run -d edge          # or chrome / an Android emulator
```

Smoke checks: `http://localhost:8080/actuator/health` returns `{"status":"UP"}`, and `http://localhost:8080/api/v1/places` returns places.

## 3. Daily Rhythm

1. `git checkout develop && git pull origin develop`
2. Pick your ticket from the Sprint Board; drag it **Todo → In Progress** (the only manual drag).
3. `git checkout -b feat/<issue_number>-<short-description>`
4. Code, then run the quality gates (`./mvnw test`, `flutter test`, `flutter analyze`).
5. Push, open a PR with the template, wait for green CI and review.

## 4. Troubleshooting

### 4.1 `FlywayValidateException: Migration checksum mismatch for migration version N`

| | |
| :--- | :--- |
| **Meaning** | An already-applied migration file was edited. Flyway compares each file's checksum with the one stored in `flyway_schema_history` on every startup and refuses to run on a mismatch. |
| **Find it** | Scroll to the last `Caused by: ...FlywayValidateException`; it names the version and shows `Applied to database` vs `Resolved locally`. |
| **Fix** | `git restore backend/src/main/resources/db/migration/V<N>__*.sql`, then restart. To change data or schema, add a **new** `V<N+1>__*.sql`. |
| **Never** | Edit an applied migration, or run `flyway repair` just to silence the error on a shared database. |

### 4.2 Flutter web shows "Cannot establish connection to backend service"

- Confirm the backend is running: open `http://localhost:8080/api/v1/places` in a browser.
- If it works there, check CORS: the backend allows `http://localhost:*`, `http://127.0.0.1:*`, and `http://10.0.2.2:*` (property `cors.allowed-origin-patterns`). Restart the backend after changing it.
- Android emulator uses `10.0.2.2` to reach the host; this is handled in `ApiEndpoints`.

### 4.3 `Unable to find suitable Visual Studio toolchain` (Flutter Windows desktop)

Windows desktop builds need Visual Studio's C++ workload. It is not required for this project: run on `edge`, `chrome`, or an Android emulator instead.

### 4.4 Backend cannot connect to the database

- `docker ps` must list `smart_local_planner_db` as healthy.
- Start it with `docker compose up -d`.
- Closing Docker Desktop or shutting down the computer only stops the container; the data volume survives.

### 4.5 Reset the local database (destroys local data)

```bash
docker compose down -v      # -v deletes the data volume
docker compose up -d
```

Local development only. Never do this on a shared or production database.

### 4.6 Integration tests are skipped

Testcontainers tests are skipped when Docker is not running (`disabledWithoutDocker = true`). Start Docker to run them locally; CI always runs them.

## 5. Working With an AI Assistant

Paste the system prompt from [DEVELOPER_WORKFLOW_PLAYBOOK.md §5](DEVELOPER_WORKFLOW_PLAYBOOK.md#5-ai-pair-programming-protocol-prompting-guide) at the start of every session, and always review AI-generated diffs before committing.

