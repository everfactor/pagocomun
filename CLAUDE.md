# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pagocomun is a bill payment and collection platform for residential communities in Chile. Organizations manage units (apartments/properties), generate monthly bills, and process automatic recurring payments via Transbank Oneclick. Economic indicators (UF/IPC) are fetched daily for inflation adjustments.

## Tech Stack

Ruby 3.4.7, Rails 8.1.1, PostgreSQL, Hotwire (Turbo + Stimulus), Tailwind CSS, Propshaft. Background jobs, caching, and WebSockets all use database-backed Solid adapters (Solid Queue, Solid Cache, Solid Cable). Deployment via Kamal.

## Commands

```bash
bin/dev                                    # Start dev server (Puma + Tailwind watcher)
bin/rails test                             # Run all tests (Minitest)
bin/rails test test/models/user_test.rb    # Run single test file
bin/rails test test/models/user_test.rb:25 # Run test at specific line
bin/rails test:system                      # System tests (Capybara/Selenium)
bundle exec standardrb                     # Lint (Ruby Standard Style)
bin/brakeman                               # Security static analysis
bin/setup                                  # Full setup (install deps, prepare DB, start server)
bin/setup --reset                          # Reset database during setup
bin/setup --skip-server                    # Setup without starting server
bin/rails db:prepare                       # Create and migrate DB (idempotent)
bin/rails credentials:edit                 # Edit encrypted credentials (set EDITOR env var)
```

## Architecture

### Controller Namespaces

Three route namespaces with distinct authorization levels:
- **`Admin::`** (`/admin`) — Super admin: full system management (organizations, users, billing)
- **`Manage::`** (`/manage`) — Org admins/managers: manage their organization's units, bills, payments
- **Root** — Residents: dashboard, payment method enrollment

### Authentication & Authorization

Custom auth using `has_secure_password` and `Current.user` (ActiveSupport::CurrentAttributes). Role-based authorization via enum roles: `super_admin`, `org_admin`, `org_manager`, `resident`. Permission logic in `User::Permissions` concern.

### Service Objects

Complex business logic lives in `ApplicationService` subclasses (in both `app/services/` and `app/models/`). They use the `.call` class method pattern that delegates to `new(...).call`.

Services can be nested within models for domain-specific operations (e.g., `Bill::Charger`, `ChargeAttempt::Processor`, `Unit::Importer`, `ChargeRun::Exporter`).

Key service: `PaymentService` handles the full Transbank Oneclick payment flow (find payer → find payment method → authorize → create payment record → update bill status).

### Background Jobs (Solid Queue)

Recurring jobs defined in `config/recurring.yml`:
- `GenerateMonthlyBillsJob` — 1st of month at midnight
- `CMF::IndicatorFetcher` — Daily 6:00 AM (fetches UF/IPC from CMF API)
- `DailyChargeJob` — Daily 8:00 AM (processes auto-charge bills via ChargeRun → ChargeAttempts)

### Key Domain Models

- **Organization** → has many Units → has many Bills
- **User** → UnitUserAssignments (with date ranges) → Units
- **User** → PaymentMethods (tokenized Transbank cards)
- **Bill** → can trigger PaymentService → creates Payment
- **ChargeRun** → ChargeAttempts (batch billing with tracking/retry)
- **EconomicIndicator** — stores UF/IPC rates, provides `.snapshot` for payment records

### Shared Partials

Reusable UI components in `app/views/shared/` (e.g., `bills_table`, `economic_indicators`). Use these across namespaces for consistent UI.

## Development Environment

### Email Testing

Mailcatcher is configured for local email previews. In dev containers, it's included automatically. Otherwise, run via Docker:
```bash
docker run --rm -p 1025:1025 -p 1080:1080 dockage/mailcatcher:0.8.2
```
View emails at `http://localhost:1080`.

## Code Conventions

- **Linter**: Ruby Standard Style — run `bundle exec standardrb` before committing
- **Strings**: Double quotes by default
- **Model organization**: Macros first (`belongs_to`, `validates`, `enum`), then public methods, then `private`
- **Controllers**: `before_action` for setup/auth, `private` for helpers and strong params
- **No empty lines** after `class`/`module` definitions
- **Database migrations**: `bigint` IDs, enforce foreign keys, `null: false` and indexes where appropriate
- **Frontend**: Tailwind utilities in markup, Stimulus controllers follow `name_controller.js` → `data-controller="name"` convention
- **Testing**: Minitest with fixtures (`test/fixtures/*.yml`), tests run in parallel
- **Locale**: Spanish (`es`), timezone `America/Santiago`
