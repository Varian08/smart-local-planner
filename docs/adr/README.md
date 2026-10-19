# Architecture Decision Records (ADR)

Numbered, immutable records of significant architectural decisions in **Smart Local Planner**. An ADR records the **why**, not the minute code implementation details.

## Writing an ADR

1. Copy `template.md` to `NNNN-slug.md`.
   - `NNNN` = next unused number (zero-padded, 4 digits: `0001`, `0002`...).
   - `slug` = short kebab-case title (e.g., `flyway-database-migrations`).
2. Fill in **Context**, **Decision**, **Options Considered**, and **Consequences**.
3. Add a row to the **Index** below.
4. **Immutability rule:** ADRs are never edited after acceptance. To reverse or modify a decision, write a new ADR that supersedes the old one (updating the old status to `superseded by [NNNN](NNNN-slug.md)`).

## When to Write an ADR

Write an ADR whenever making a decision that introduces a new dependency, alters data flow, shifts architectural patterns, establishes security protocols, or answers a question a future engineer would ask: *"Why was it designed this way?"*.

---

## Index

| ADR | Title | Status | Date | Deciders |
| :---: | :--- | :---: | :---: | :---: |
| [0001](0001-spring-boot-3-and-java-21.md) | Spring Boot 3.x and Java 21 for Backend Service | accepted | 2026-10-17 | Engineer A |
| [0002](0002-flyway-database-migrations.md) | Flyway Database Migrations over Hibernate Auto-DDL | accepted | 2026-10-17 | Engineer A |
| [0003](0003-flutter-bloc-state-management.md) | Flutter BLoC Pattern for Presentation State Isolation | accepted | 2026-10-17 | Engineer B |
| [0004](0004-dio-with-auto-token-rotation.md) | Dio Interceptors for JWT Refresh Token Rotation | accepted | 2026-10-17 | Engineer A & B |
| [0005](0005-neon-and-render-zero-cost-hosting.md) | Zero-Cost Cloud Infrastructure: Render PaaS & Neon Serverless PostgreSQL | accepted | 2026-10-17 | Engineer A & B |
