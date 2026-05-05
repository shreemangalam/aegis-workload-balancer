# Aegis — Workload Balancer

> Priority-aware ticket dispatch engine for enterprise AMS environments.

## What It Does

In enterprise AMS teams, developers manage two competing workstreams:
implementation projects and support tickets. Manual assignment causes ticket
bouncing (knowledge mismatch), overloading (invisible project load), and
SLA drift (aging tickets ignored).

Aegis runs as a non-invasive backend middleware. Every 5 minutes it polls
ServiceNow for unassigned incidents, evaluates each ticket against a
four-constraint filter, and routes it to the most qualified available
developer, without touching the SNOW instance configuration.

## Architecture

SNOW Simulator → Polling Engine → Triage Engine → Assignment Engine → PostgreSQL (audit) → React Dashboard

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Java 21, Spring Boot 3.5 |
| Database | PostgreSQL 16, Flyway |
| Resilience | Resilience4j Circuit Breaker |
| Security | Spring Security + JWT |
| Frontend | React, Tailwind CSS |
| DevOps | Docker, Docker Compose, GitHub Actions |
| Testing | JUnit 5, Mockito, WireMock |

## Key Engineering Concepts

- **Constraint satisfaction** - four-filter routing (client mapping → keyword
  match → skill tier → capacity headroom)
- **Idempotency** - DB-level UNIQUE constraint prevents duplicate assignments
  across poll cycles
- **Circuit breaker** - Resilience4j three-state machine with probe-based recovery
- **Optimistic locking** - `@Version` on Developer entity prevents race conditions
- **Audit trail** - every decision logged as immutable JSONB snapshot

## Running Locally

```bash
# Start PostgreSQL and SNOW Simulator
docker-compose up -d

# Run the application
./mvnw spring-boot:run
```

Dashboard: `http://localhost:8080`  
API Docs: `http://localhost:8080/swagger-ui.html`  
Health: `http://localhost:8080/actuator/health`

## Documentation

Full Technical Design Document available in [`/docs`](./docs)

---

*Built as part of a portfolio of enterprise integration projects.  
See also: [Hermes](https://github.com/shreemangalam/hermes-integration-analyzer)
· [Chronos](https://github.com/shreemangalam/chronos-retry-orchestrator)*