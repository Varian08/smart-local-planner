# 0002. Flyway Database Migrations over Hibernate Auto-DDL

- Date: 2026-10-17
- Status: accepted
- Deciders: Engineer A (Backend)

## Context

Managing relational database schema changes across local environments (Docker PostgreSQL) and cloud environments (Neon.tech Serverless PostgreSQL) requires deterministic, reproducible, and verifiable version control. 

Using Hibernate's automatic schema generation (`spring.jpa.hibernate.ddl-auto=update`) is hazardous in team environments and production: it cannot safely handle column renames, data transformations, custom index creation, or rollback audits.

## Decision

We adopt **Flyway** for database migrations. All schema definitions, foreign keys, indexes, and initial reference data must be written in sequential SQL migration files under `src/main/resources/db/migration/` (e.g., `V1__init_schema.sql`, `V2__add_itinerary_indexes.sql`).

Hibernate `ddl-auto` is strictly set to `validate` in all environments.

## Options Considered

1. **Hibernate `ddl-auto=update`** — Fast in initial minutes of prototyping, but causes silent schema drifts, fails to delete obsolete constraints, and risks data loss or corruption in staging/production.
2. **Liquibase** — Powerful XML/YAML/JSON change-sets, but introduces unnecessary syntax complexity when native SQL is clearer and more direct for PostgreSQL.
3. **Flyway** — Plain SQL syntax, deterministic version ordering (`V<Version>__<Description>.sql`), immutable migration checksum verification, and native integration with Spring Boot. ✅

## Consequences

- **Positive:**
  - Absolute synchronization between local Docker PostgreSQL and Neon.tech cloud database.
  - Full audit trail of database evolution directly committed in Git.
  - Zero surprises during deployment: migrations execute automatically on application startup.
- **Negative:**
  - Developers must manually write SQL migration scripts instead of relying on JPA entity annotations to modify tables.
