# Smart Local Planner — Workspace Agent Guidelines

> Engineering guardrails for **Smart Local Planner**, a `$0`-cost enterprise monorepo (Neon PostgreSQL + Render Docker + Cloudinary) pairing a **Spring Boot 3.3.4 / Java 21** REST backend with a **Flutter / Dart 3 BLoC** mobile application.

---

## 1. Repository Map & Hierarchical Rules

```text
smart-local-planner/
├── AGENTS.md                   # You are here (monorepo guardrails & verification)
├── backend/                    # Spring Boot 3.3.4, Java 21, Flyway, PostgreSQL 16 -> see backend/AGENTS.md
├── mobile/                     # Flutter 3, Dart ^3.13.7, flutter_bloc, Dio -> see mobile/AGENTS.md, PRODUCT.md, DESIGN.md
├── bruno/                      # Plain-text API test collections
├── docs/                       # Canonical architecture, API spec, workflow playbook & ADRs
└── .agents/skills/             # Progressive workflow skills (loaded on demand)
```

When working inside `backend/` or `mobile/`, also follow the nested `AGENTS.md` file in that subsystem (and `mobile/PRODUCT.md` + `mobile/DESIGN.md` for any Flutter UI work).

---

## 2. Non-Negotiable Red Lines

1. **Flyway Immutability:** Never modify any merged or existing migration file under `backend/src/main/resources/db/migration/` (`V1` through `V4`, etc.). Always create the next sequential `V<N+1>__<description>.sql` script. Hibernate `ddl-auto` is `validate`.
2. **Git & Branch Discipline ([CONTRIBUTING.md](CONTRIBUTING.md)):**
   - Never push application code, database migrations, or build/CI configs directly to `develop` or `main`.
   - Branch off `develop` using `<type>/<issue_number>-<short-description>`.
   - Commit with `<type>(<scope>): [SLP-X] <imperative subject>`. Keep `Closes #<issue_number>` strictly in the PR description (never in branch names or commit messages).
   - *(Pragmatic exemption in `CONTRIBUTING.md` applies only to pure `.md` documentation or typo fixes).*
3. **Zero-Trust Secrets:** Never commit `.env`, JWT secrets, database passwords, API keys, or keystores. Only sanitized placeholders belong in `.env.example`.
4. **Contract-First API Parity:** Never alter REST paths, JSON field names/types, or HTTP status codes without updating `docs/API_SPECIFICATION.md` and `bruno/` in the same change.
5. **Language Standard:** Write all source code, doc comments, commit messages, PR descriptions, and repo technical documentation in clear Technical English.

---

## 3. Local Quality Gates (Run Before Claiming Done)

Do not mark work complete or open a PR until every gate covering your changes passes locally:

- **Backend (`backend/`):**
  - Windows PowerShell: `.\mvnw.cmd test` (requires Java 21 / `JAVA_HOME` configured)
  - Linux / macOS: `./mvnw test`
  - Expected: `BUILD SUCCESS` with 0 failures/errors.
- **Mobile (`mobile/`):**
  - `flutter analyze` -> Expected: `No issues found!`
  - `flutter test` -> Expected: All tests pass.

---

## 4. AI Engineering Workflow & Tools

- **Design Before Coding:** Use `brainstorming` and `writing-plans` before implementing multi-file features, keeping scope aligned with `docs/ARCHITECTURE_BLUEPRINT.md` and `docs/adr/`.
- **Verify Live Framework Docs:** Use the **Context7** MCP (`resolve-library-id` -> `query-docs`) for Spring Boot 3.3, Spring Security 6, `flutter_bloc ^9.1.1`, `dio ^5.11.1`, and Cloudinary SDKs, plus the **Dart and Flutter** MCP for Dart/Flutter analysis—never guess deprecated APIs.
- **On-Demand Project Skills (`.agents/skills/`):**
  - `spring-boot-api-contract`: Adding/modifying REST endpoints, DTOs, validation, or MockMvc contract tests.
  - `flutter-bloc-feature`: Implementing mobile features, BLoCs, 4-state UI, and widget/bloc tests.
  - `flyway-migration-safety`: Authoring new SQL schema/seed migrations and matching JPA entities.
- **Pre-PR Audit:** Run `open-code-review-delegate` (`ocr delegate preview` + full diff audit against [docs/DEVELOPER_WORKFLOW_PLAYBOOK.md](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md) Section 7) before pushing or opening a Pull Request.

---

## 5. Canonical Documentation Index

- Governance & Red Lines: [CONTRIBUTING.md](CONTRIBUTING.md)
- Sprint SOP, Issue/PR Templates & Review Checklists: [docs/DEVELOPER_WORKFLOW_PLAYBOOK.md](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md)
- Clean Architecture & Coding Standards: [docs/DEVELOPMENT_GUIDELINES.md](docs/DEVELOPMENT_GUIDELINES.md)
- REST JSON Contracts: [docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md)
- System Design & Scope Boundaries: [docs/ARCHITECTURE_BLUEPRINT.md](docs/ARCHITECTURE_BLUEPRINT.md)
- Architecture Decision Records: [docs/adr/README.md](docs/adr/README.md)

