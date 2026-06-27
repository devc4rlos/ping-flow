# PingFlow

> A portfolio project exploring the design of a resilient, multi-tenant uptime monitoring microservice using Clean Architecture and Domain-Driven Design.

![PHP](https://img.shields.io/badge/PHP-8.4%2B-777BB4?logo=php&logoColor=white)
![Laravel](https://img.shields.io/badge/Laravel-13-FF2D20?logo=laravel&logoColor=white)
![PHPStan](https://img.shields.io/badge/PHPStan-level%2010-8956FF)
![License](https://img.shields.io/badge/license-MIT-22c55e)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

---

## Overview

PingFlow is a portfolio project designed to explore the application of Clean Architecture and Domain-Driven Design in the context of a real-world SaaS microservice. The goal is to build a multi-tenant uptime monitoring service that periodically checks the availability of HTTP/HTTPS endpoints. The system tracks state transitions and delivers signed webhook alerts. This is achieved while maintaining a domain layer completely free of framework dependencies.

**The project is currently in its foundation phase.** The development environment, quality tooling, and CI pipeline are fully operational. The business implementation has not started yet..

The design principles guiding the implementation:

* **Domain-first:** Business rules will live in pure PHP under the `src/` directory with zero coupling to Laravel. The framework acts exclusively as the external orchestration shell.
* **Noise-resistant monitoring:** A monitor will only transition to `DOWN` after a configurable number of consecutive failures to avoid false alerts from transient network blips.
* **Multi-tenant by design:** Data isolation between accounts is applied at a logical level through a tenant discriminator and enforced across all layers via dependency inversion.
* **Verifiable alerts:** Outgoing webhook payloads will be cryptographically signed using a symmetric HMAC-SHA256 signature. This allows receivers to verify authenticity before acting.

---

## Planned Architecture

The project targets Clean Architecture layered with Domain-Driven Design. The core invariant dictates that inner layers have no knowledge of outer layers. The domain will be written in pure PHP without Eloquent, Laravel facades, or external I/O integrations.

```text
┌─────────────────────────────────────────────────────────────────┐
│  Entry Points (Laravel)                                         │
│  HTTP Controllers · Console Commands · Queue Workers            │
├─────────────────────────────────────────────────────────────────┤
│  Application Layer                                              │
│  Command Bus · Use Case Handlers · Port Contracts               │
├─────────────────────────────────────────────────────────────────┤
│  Domain Layer (pure PHP, zero external dependencies)            │
│  Monitor (Aggregate Root) · Value Objects · Domain Events       │
├─────────────────────────────────────────────────────────────────┤
│  Infrastructure Layer (Laravel)                                 │
│  Eloquent Repositories · HTTP Client Adapter · Webhook Notifier │
└─────────────────────────────────────────────────────────────────┘
```

### Designed Domain Model

`Monitor` is planned as the Aggregate Root and it holds the entire responsibility of managing and transitioning the availability states. No external entity can alter its state directly. The diagram below reflects the intended domain model rather than the current implementation.

```text
Monitor (Aggregate Root)
 ├── MonitorId          [UUID v4]
 ├── TenantId           [UUID v4 logical isolation boundary]
 ├── TargetUrl          [HTTP/HTTPS URI]
 ├── CheckInterval      [Enum: 1, 5, 10, 15, 30, 60 min]
 ├── ExpectedStatusCode [100 to 599, default 200]
 ├── TimeoutSeconds     [1 to 30s, default 10]
 ├── AlertThreshold     [1 to 10 consecutive failures, default 3]
 ├── MonitorStatus      [UNKNOWN, UP, DOWN, PAUSED]
 └── NotificationChannels[]
```

### Designed State Machine

The following state machine represents the intended business behavior and has not yet been implemented.

```text
          ┌──────────┐
    ─────►│ UNKNOWN  │
          └────┬─────┘
               │ first successful check
    ┌──────────▼──────────┐
    │          UP         │◄─────────────────────────────┐
    └──────────┬──────────┘                              │
               │ consecutive failures >= AlertThreshold  │ single success
    ┌──────────▼──────────┐                              │
    │         DOWN        │──────────────────────────────┘
    └─────────────────────┘

    Any state transitions via pause() to PAUSED (excluded from scheduling)
    PAUSED transitions via resume() to UNKNOWN (re-enters the check cycle)
```

Domain events will be fired on transition changes to decouple the alert dispatch logic from the core ping execution.

---

## Tech Stack

| Layer                | Technology                      |
|----------------------|---------------------------------|
| Language             | PHP 8.4+ (CI matrix: 8.4 & 8.5) |
| Framework            | Laravel 13                      |
| Environment          | Docker via Laravel Sail         |
| Static analysis      | PHPStan level 10 + Larastan     |
| Code style           | Laravel Pint                    |
| Testing              | PHPUnit                         |
| CI/CD                | GitHub Actions                  |

**Planned target stack for implementation:**

| Layer                | Technology      |
|----------------------|-----------------|
| Database             | MySQL 8.0       |
| Cache / Queues       | Redis           |
| Auth & Multi-tenancy | Laravel Sanctum |
| Queue management     | Laravel Horizon |

---

## Prerequisites

* [Docker](https://www.docker.com/) and Docker Compose
* [GNU Make](https://www.gnu.org/software/make/)

No local PHP or Composer installation is required since all commands run inside the Sail containers.

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/devc4rlos/ping-flow.git
cd ping-flow
```

### 2. Bootstrap the project

```bash
make setup
```

This single command will:

* Copy `.env.example` to `.env`
* Install Composer dependencies using the official Sail Docker image
* Start all containers in detached mode
* Generate the application key
* Run all database migrations

### 3. Verify the setup

```bash
make quality
```

This command runs the full Quality Assurance suite by checking the code style, running static analysis, and executing the test suite.

---

## Available Commands

All development tasks are centralized in the `Makefile`.

| Command          | Description                                        |
|------------------|----------------------------------------------------|
| `make setup`     | First-time project initialization                  |
| `make up`        | Start all Docker containers                        |
| `make down`      | Stop and remove all containers                     |
| `make shell`     | Open an interactive shell inside the app container |
| `make test`      | Execute the PHPUnit test suite                     |
| `make lint`      | Fix code style issues automatically using Pint     |
| `make lint-test` | Check code style violations without applying fixes |
| `make analyse`   | Run PHPStan static analysis on level 10            |
| `make quality`   | Full QA pipeline combining lint, analyse, and test |

---

## Project Structure

```text
ping-flow/
├── .github/
│   └── workflows/
│       └── ci.yml          # CI pipeline: lint, analyse, test
├── app/
│   ├── Http/Controllers/
│   ├── Models/
│   └── Providers/
├── database/
│   ├── migrations/
│   └── seeders/
├── routes/
│   ├── api.php
│   └── console.php
├── src/                    # Domain and Application layers (DDD)
│   ├── Domain/             # Pure PHP components: Aggregates, VOs, Events
│   └── Application/        # Commands, Handlers, Port contracts
├── tests/
│   ├── Feature/            # End-to-end API tests
│   └── Unit/               # Isolated domain tests
├── Makefile
├── phpstan.neon            # PHPStan level 10 and Larastan rules
└── pint.json               # Strict code style rules
```

The `src/` directory follows the `Src\` PSR-4 namespace and acts as the home for all domain and application logic. The `app/` directory remains the home for Laravel's infrastructure layer including controllers, models, and providers.

---

## CI Pipeline

Every push and pull request to the `main` branch triggers three independent jobs:

```text
push / pull_request to main
         │
         ├── lint        PHP 8.4 · Pint --test (no auto-fix)
         ├── analyse     PHP 8.4 · PHPStan level 10
         └── tests       PHP 8.4 and PHP 8.5 · PHPUnit · MySQL 8.0
```

Concurrent runs on the same branch are automatically cancelled to keep the Continuous Integration fast and resource-efficient.

---

## Roadmap

The project is currently in its foundation phase where the environment and tooling are fully operational but the codebase implementation has not started. Development will follow vertical slices so each slice delivers a working and end-to-end feature rather than an isolated technical layer.

| Slice                       | Delivers                                                                                                                                                    | Status    |
|-----------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------|
| **#1 Foundation**           | Reproducible Docker environment, automated quality pipeline (Pint, PHPStan, PHPUnit), and CI on every commit                                                | ✅ Done    |
| **#2 Monitor Management**   | Authenticated CRUD for monitors via REST API with data persisted via tenant isolation. The monitor state initialises as `UNKNOWN`                           | ⬜ Next    |
| **#3 Availability Checks**  | Scheduler dispatches due monitors every minute while HTTP checks run asynchronously via Horizon. Results are logged and state transitions to `UP` or `DOWN` | ⬜ Planned |
| **#4 State Change Alerts**  | Webhook dispatch is triggered on `UP` and `DOWN` transitions. Notification channels are created and linked to monitors to deliver signed payloads           | ⬜ Planned |
| **#5 History & Operations** | Paginated ping log endpoint setup, ability to pause or resume monitors, and automated daily log retention jobs                                              | ⬜ Planned |

---

## Contributing

Contributions are welcome. Please ensure your changes pass the full quality suite before opening a pull request:

```bash
make quality
```

This project follows [Conventional Commits](https://www.conventionalcommits.org/).

---

## License

This software is open source and licensed under the MIT License. See the [LICENSE](LICENSE) file for details.