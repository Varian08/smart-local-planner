# 0001. Spring Boot 3.x and Java 21 for Backend Service

- Date: 2026-10-17
- Status: accepted
- Deciders: Engineer A (Backend)

## Context

The Smart Local Planner backend must support RESTful API endpoints for user authentication, place discovery, personal itinerary management, and review operations. It needs robust enterprise-grade security (Spring Security + JWT), compile-time type safety, strong ecosystem support, and zero licensing cost.

## Decision

We adopt **Java 21 (LTS)** and **Spring Boot 3.x** as the core backend web service framework, structured with standard 3-layer architecture (`Controller -> Service -> Repository`).

## Options Considered

1. **Node.js (Express / NestJS)** — Highly dynamic and rapid for prototyping, but lacks the out-of-the-box maturity of Spring Security and requires manual setup for comprehensive transaction boundaries.
2. **Golang (Gin / Fiber)** — Extremely lightweight and high performance, but lacks an all-in-one ecosystem for automated DTO validation, JPA transaction management, and unified OpenAPI documentation without heavy boilerplate.
3. **Java 21 + Spring Boot 3.x** — Native Virtual Threads (Project Loom), robust declarative transactions (`@Transactional`), Jakarta Validation (`@Valid`), mature Spring Security JWT filter chain, and wide enterprise adoption. ✅

## Consequences

- **Positive:**
  - Robust ecosystem for security, validation, database integration, and API documentation.
  - Strong compile-time safety and self-documenting code.
  - Seamless deployment on Render.com using standard Docker multi-stage builds.
- **Negative:**
  - Higher cold-start time and baseline memory footprint compared to Go or Node.js (mitigated by configuring lightweight JVM options: `-XX:+UseSerialGC -Xmx384m`).
