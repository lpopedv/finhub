# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Finhub is a personal finance web application built as an Elixir umbrella project with two apps:

- **`apps/core`** — Business logic, Ecto schemas, and database access (PostgreSQL)
- **`apps/finhub_web`** — Phoenix 1.8 web layer (LiveView, controllers, templates)

## Commands

```bash
# First-time setup (runs in all child apps)
mix setup

# Start the dev server
mix phx.server

# Run all tests
mix test

# Run a single test file
mix test apps/core/test/my_test.exs

# Run previously failed tests
mix test --failed

# Pre-commit check (compile + format + test, runs in :test env)
mix precommit

# Generate a migration (always use this, not manual file creation)
mix ecto.gen.migration migration_name_using_underscores

# Reset the database
mix ecto.reset
```

**Always run `mix precommit` when done with changes** and fix any issues before considering work complete.

## Architecture

### Command/Service Pattern

Business logic in `apps/core` follows a command/service pattern, organized by domain:

```
apps/core/lib/core/
  schemas/          # Ecto schemas (User, Category, Transaction, FixedTransaction)
  <domain>/
    commands/       # Input structs (e.g., CreateTransactionCommand)
    services/       # Business logic modules with a single execute/1 function
    workers/        # Oban workers (only in fixed_transaction domain)
```

Each service module has one `execute/1` function that takes a command struct and returns `{:ok, result}` or `{:error, changeset}`.

**Commands** use `Core.EmbeddedSchema` (not `Core.Schema`), which adds `build/1` and `build!/1` helpers. Commands have no primary key.

### Domains

| Domain | Commands | Services |
|---|---|---|
| `auth` | AuthenticateUserCommand | AuthenticateUserService |
| `user` | CreateUserCommand | CreateUserService, DeleteUserService, ListUsersService, UpdateUserService |
| `category` | CreateCategoryCommand | CreateCategoryService, DeleteCategoryService, ListCategoriesService, UpdateCategoryService |
| `transaction` | CreateTransactionCommand, ListTransactionsCommand, GetTransactionsTotalsByMonthCommand | CreateTransactionService, DeleteTransactionService, ListTransactionsService, UpdateTransactionService, GetTransactionsTotalsByMonthService |
| `fixed_transaction` | CreateFixedTransactionCommand | CreateFixedTransactionService, DeleteFixedTransactionService, ListFixedTransactionsService, UpdateFixedTransactionService + **ScheduleFixedTransactionsWorker** (Oban, daily 06:00 UTC) |
| `dashboard` | — | GetDashboardSummaryService |
| `projection` | GetProjectionsByMonthCommand | GetProjectionsByMonthService |

### Schemas

All schemas use `Core.Schema` (not `Ecto.Schema` directly), which sets:
- UUID v7 primary keys via `Uniq.UUID`
- `utc_datetime_usec` timestamps
- UUID foreign key type

Money values are stored as **integers in cents** (`value_in_cents`) to avoid floating-point issues. Formatting to display strings happens only in the UI via `FinhubWeb.Helpers.Currency`.

Transaction types are defined in `Core.TransactionType` as `:income` or `:expense`.

### Background Jobs

Oban 2.19 handles background jobs backed by PostgreSQL. The `ScheduleFixedTransactionsWorker` runs daily at 06:00 UTC on the `:default` queue (concurrency 10). When adding new workers, follow the idempotency pattern in that worker — check for existing records before inserting.

### Authentication

- **`RequireAuthPlug`** — Plug that checks `user_id` in session; redirects to `/sign-in` if missing
- **`FinhubWeb.Live.Hooks.UserAuth`** — `on_mount` hook used on all authenticated LiveView routes; assigns `:current_user`
- Session deletion broadcasts to `users_socket:#{user_id}` via PubSub to force LiveView disconnect on logout
- Password hashing uses `Argon2` (`argon2_elixir`); test env uses reduced cost (`t_cost: 1, m_cost: 8`)
- This project uses `@current_user`, not `current_scope` (ignore any `current_scope` references in AGENTS.md)

### Routes

```
GET  /sign-in   → SessionController.sign_in_form
POST /sign-in   → SessionController.create
DEL  /sign-out  → SessionController.delete

# Authenticated (RequireAuthPlug + UserAuth on_mount):
GET /                    → DashboardLive
GET /categories          → CategoryLive.Index
GET /transactions        → TransactionLive.Index
GET /fixed-transactions  → FixedTransactionLive.Index
GET /monthly-report      → MonthlyReportLive
GET /projections         → ProjectionLive
GET /oban                → Oban job dashboard
```

### Web Layer

`apps/finhub_web` calls `Core` services directly. The web layer must not contain business logic — delegate to services in `apps/core`. Core has no HTTP or Phoenix dependencies.

## Key Conventions

- **HTTP client**: Use `Req` — never `:httpoison`, `:tesla`, or `:httpc`
- **HTTP adapter**: Bandit (not Cowboy)
- **Programmatic fields** (e.g., `user_id`): Must **not** be in `cast/2` calls; set explicitly when building the struct
- **Specs**: Required on all public functions in `apps/core` (Credo enforces this)
- **Module layout**: Strict ordering enforced by Credo — aliases before `@moduledoc`, etc.
- Max line length: 120 characters
- **Test factories**: Use `ExMachina` (`apps/core/test/support/factory.ex`) — excluded from Credo

## Phoenix/LiveView Notes

See `AGENTS.md` for detailed Phoenix 1.8, LiveView, HEEx, and Ecto guidelines. Key points:

### UI Components — always use CoreComponents

**Never write raw HTML when a component exists.** All components are imported automatically via `use FinhubWeb, :html` and `use FinhubWeb, :live_view`.

| Need | Use |
|---|---|
| Text/email/password/select/textarea input | `<.input field={f[:field]} type="..." label="..." />` |
| Button or link-as-button | `<.button variant="primary">Label</.button>` |
| Page/section title | `<.header>Title</.header>` |
| Data table | `<.table id="..." rows={...}>` |
| Data list (key/value) | `<.list>` |
| Heroicon | `<.icon name="hero-...">` — never use `Heroicons` module |
| Flash toast | `put_flash(socket, :info, "msg")` — appears automatically via `Layouts.app` |

This project uses daisyUI for component styling (overrides the AGENTS.md note about avoiding it).

### Layouts

- **Flash in LiveView**: the root layout is NOT re-diffed in `handle_event`. The `flash_group` is inside `Layouts.app`, which re-renders on every event. Always pass `flash={@flash}` to `<Layouts.app flash={@flash}>`.
- **Flash in controllers**: use `<.flash kind={:error} flash={@flash} />` directly in the template (e.g. sign-in).
- **Controller templates**: content only — the root layout is applied automatically by the pipeline
- **LiveView templates**: start with `<Layouts.app flash={@flash}>` (includes nav and flash)
- For pages without nav (e.g. sign-in): use controller + template, without `<Layouts.app>`

### Other

- Use LiveView streams for all collections
- Tailwind CSS v4 — no `tailwind.config.js`, use `@import "tailwindcss"` syntax in `app.css`
- Never use `@apply` in CSS; never write inline `<script>` tags in templates
