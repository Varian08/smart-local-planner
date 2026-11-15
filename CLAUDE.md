# Smart Local Planner — Claude & Multi-Agent Context Bridge

> This file bridges Claude Code, Cursor, and other `CLAUDE.md`-aware coding assistants to Smart Local Planner's hierarchical `AGENTS.md` engineering kit.

## Mandatory Reading Before Modifying Code

1. **Monorepo Guardrails & Quality Gates:** Read [AGENTS.md](AGENTS.md) first (Flyway immutability `V1`–`V4`+, GitFlow & commit rules, zero-trust secrets, contract parity with `docs/API_SPECIFICATION.md` & `bruno/`, and local verification commands).
2. **Backend (`backend/` — Spring Boot 3.3.4, Java 21, PostgreSQL 16):** Read [backend/AGENTS.md](backend/AGENTS.md) and `.agents/skills/spring-boot-api-contract/SKILL.md` (or `.agents/skills/flyway-migration-safety/SKILL.md` for SQL/Entity changes).
3. **Mobile (`mobile/` — Flutter 3.47.8, Dart ^3.13.7, `flutter_bloc`):** Read [mobile/AGENTS.md](mobile/AGENTS.md), [mobile/PRODUCT.md](mobile/PRODUCT.md), [mobile/DESIGN.md](mobile/DESIGN.md), and `.agents/skills/flutter-bloc-feature/SKILL.md`.
4. **Canonical Specifications:** See [CONTRIBUTING.md](CONTRIBUTING.md), [docs/DEVELOPER_WORKFLOW_PLAYBOOK.md](docs/DEVELOPER_WORKFLOW_PLAYBOOK.md), [docs/ARCHITECTURE_BLUEPRINT.md](docs/ARCHITECTURE_BLUEPRINT.md), and [docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md).
