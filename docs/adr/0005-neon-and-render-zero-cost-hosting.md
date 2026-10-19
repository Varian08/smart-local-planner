# 0005. Zero-Cost Cloud Infrastructure: Render PaaS & Neon Serverless PostgreSQL

- Date: 2026-10-17
- Status: accepted
- Deciders: Engineer A (Backend), Engineer B (Mobile)

## Context

The project operates under a strict **$0 budget constraint** while aiming for enterprise-grade continuous deployment, automated HTTPS certification, and high database reliability. 

Self-hosting on virtual private servers (VPS) introduces server provisioning overhead, monthly subscription costs, manual Linux security patch maintenance, and Nginx reverse proxy configuration.

## Decision

We adopt a zero-cost, cloud-native managed architecture:
1. **Render.com (PaaS):** Hosts the containerized Spring Boot 3 web service via automated GitHub webhook triggers on merge to `main`.
2. **Neon.tech:** Provides a managed Serverless PostgreSQL 16 database with automated connection pooling and zero credit-card requirement.
3. **Cloudinary:** Serves as the Content Delivery Network (CDN) for place media and user avatars (25 GB free monthly bandwidth).

## Options Considered

1. **Self-hosted VPS (Linode / DigitalOcean / eBiz)** — Requires monthly payment and ongoing OS maintenance (firewall, Nginx, certbot renewals), which exceeds the project's zero-cost boundary.
2. **AWS Free Tier (EC2 + RDS)** — Complex IAM configuration, risk of accidental overage billing, and expires after 12 months.
3. **Render PaaS + Neon.tech Serverless + Cloudinary** — Truly free, permanent student-friendly tier, automated CI/CD deployment, managed automated backups, and built-in HTTPS. ✅

## Consequences

- **Positive:**
  - $0 total infrastructure cost for the entire development and evaluation lifecycle.
  - Zero server maintenance: fully managed OS, automatic SSL renewal, and managed PostgreSQL updates.
  - Production parity: local Docker PostgreSQL runs the identical Postgres 16 engine as cloud Neon.tech.
- **Negative:**
  - Render free tier instances spin down after 15 minutes of inactivity, causing an initial cold-start delay (~30-50s) on the first request (acceptable for demo and MVP evaluation).
