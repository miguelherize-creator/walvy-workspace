# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Extended guidance (`/ai/`)

For richer context, MVP product scope, day-to-day workflows, and **UI/UX tokens**, also read (when relevant):

- **`ai/context.md`** — Repo map, MVP modules, CSV as source of truth, sprint status, connectivity notes.
- **`ai/rules.md`** — Backend/frontend conventions, **Feature-First architecture rules**, **Walvy UI/UX (colors, spacing, typography)**, scope guardrails.
- **`ai/skills.md`** — Commands, Docker vs local API, Expo web vs device, env vars, checklist for adding new features.
- **`ai/decisions.md`** — Architecture/product decisions (ADR-style).

**MVP business scope** is defined in:

`utils/organizacion/docs/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`

---

## Project overview

**Walvy** is a personal finance (cash flow) app with a **NestJS** REST API and a **React Native (Expo)** frontend. Work happens in two main trees (often separate git repos checked out under the same parent folder):

| Part | Path (typical) |
|------|----------------|
| Backend | `Backend/backend/` |
| Frontend | `Frontend/rork-checkapp/expo/` — real `package.json` / `app.json` live here; parent `rork-checkapp/` may hold Rork metadata only |

---

## Backend (`Backend/backend`)

### Commands

```bash
npm install
npm run start:dev       # Dev server with hot reload (needs DATABASE_URL + .env)
npm run build
npm run start:prod
npm test
npm run test:e2e
npm run lint
npm run format
docker compose up --build    # PostgreSQL + API containers
docker compose up -d postgres   # Only DB — then run API locally with npm run start:dev
docker compose restart api      # Rebuild API without touching DB volume
```

### Architecture

NestJS **module-per-feature** under `src/`:

- **`auth/`** — Register, login, JWT access + refresh (rotation), password reset. Passport JWT. Throttling on `/auth/login` and `/auth/forgot-password`.
- **`users/`** — Profile, authenticated password change.
- **`cashflow/`** — Transactions, categories, subcategories, funding sources; seeds under `cashflow/data/`.
- **`mail/`** — Password reset emails.
- **`common/`** — Global exception filter, `@Auth()`, shared utils.
- **`health.controller.ts`** — `GET /` (info), `GET /health` (`{ ok: true }`) for liveness; no auth. Used by the Expo app probe.

**Entry point**: `src/main.ts` — CORS, Swagger at **`/api`**, global validation pipe & exception filter.

**Environment**: Copy `.env.example` → `.env`. Key vars: `DATABASE_URL`, `JWT_SECRET`, mail settings for reset flows, `CORS_ORIGIN` (include Expo web origins, e.g. `http://localhost:8081`). `SEED_*` / `SEED_CASHFLOW` control seeds. `DB_SYNC` can force schema sync in production only when explicitly needed.

**TypeORM**: `app.module.ts` — `synchronize` in dev (or when `DB_SYNC=true` in prod as a temporary measure). Prefer migrations for production long-term.

**Docker**: `docker-compose.yml` services `postgres` and `api`; volume `walvy_pg_data` persists DB. Do not use `docker compose down -v` unless you intend to wipe data.

---

## Frontend (`Frontend/rork-checkapp/expo`)

### Commands

```bash
cd Frontend/rork-checkapp/expo
bun i
bun run start           # Expo Metro (device / emulator)
bun run start-web       # Web preview (browser)
bun run lint
bun run test            # Jest unit tests
bun run test --watch    # Watch mode
bun run test --coverage # Coverage report
```

Use **Bun** inside `expo/` for all installs and scripts (not npm/yarn).

### Architecture — Feature-First + Clean Architecture

The frontend follows **Feature-First architecture**. Every business module lives in `features/<name>/` with four internal layers:

```
features/<name>/
├── index.ts                 ← Public contract — the only import other code uses
├── data/
│   └── <Name>Repository.ts  ← Wraps the api/ service; single point of change
├── hooks/
│   ├── index.ts
│   └── use<Name>.ts         ← State, validation, mutations — no JSX
└── ui/
    ├── index.ts
    └── <Name>Screen.tsx     ← JSX only; delegates all logic to hook
```

**Dependency rule — only downward:**
```
ui/ → hooks/ → data/ → api/
```
No layer imports the one above it. `api/` does not know `features/` exist.

### Routing (Expo Router)

- Route groups: **`(auth)/`** (unauthenticated) and **`(tabs)/`** (authenticated, with tab bar).
- All files in `app/` are **2-line delegates** — they import the Screen from `features/` and re-export it as default.
- Full navigation layout: `app/_layout.tsx` registers all Stack.Screen entries.
- `app/index.tsx` is the auth gate: redirects to `/(tabs)` or `/(auth)/login`.

### State

- **Auth**: `store/AuthProvider.tsx` — `user`, `login`, `logout`, tokens, biometric. Treated as shared infrastructure (not inside `features/auth/`).
- **Theme**: `store/ThemeProvider.tsx` — `theme`, `isDark`, `toggleTheme`.

### API and Mock Mode

- `api/client.ts` — Axios instance with token interceptors and 401 handling.
- `api/config.ts` — Resolves `BACKEND_BASE_URL` (platform defaults or env var). On startup, `probeBackendReachability()` calls `GET .../health`; if unreachable, activates **mock mode**.
- `EXPO_PUBLIC_USE_MOCK_MODE=true|false` overrides the probe result.
- `api/mocks/` — Mock implementations split by domain: `authMock.ts`, `profileMock.ts`, shared `mockMemory.ts`.

### Imports

Always use alias **`@/`** → project root (`expo/`). Inside a feature, short relative paths are fine:
```typescript
import { useAuth } from "@/store/AuthProvider";       // cross-feature: @/ alias
import { updateProfile } from "../data/profileRepository"; // same feature: relative
```

### UI / brand

Walvy uses a **warm sand + teal** palette. **Source of truth:** `constants/colors.ts` and `constants/theme.ts`. Full token table and rules: **`ai/rules.md` → UI y UX**.

### Web debugging

Expo **web** logs `console.*` in the **browser DevTools** (F12), not in the Metro terminal.

---

## Database (`DB/`)

- `schema.sql` — PostgreSQL DDL reference.
- `schema.dbml` — Diagram-friendly description.

Core tables: `users`, `refresh_tokens`, `password_reset_tokens`, `funding_sources`, `categories`, `subcategories`, `transactions`.

---

## Frontend sprint status

| Sprint | Feature | Status |
|--------|---------|--------|
| 1 | `features/auth/` | Complete — data + hooks + ui + utils |
| 2 | `features/profile/` | Complete — data + hooks + ui |
| 3 | `features/home/` | Complete — hooks + ui |
| 4 | `features/transactions/` | Pending |
| 5 | `features/budget/` | Pending |
| 6 | `features/debts/` | Pending |
| 7 | `features/payments/` | Pending |
| 8 | `features/assistant/` | Pending |

---

## Key conventions

- **Backend DTOs**: `class-validator` on inputs at the boundary, not ad-hoc validation only in services.
- **Password rules** (users DTOs): min 8 chars, upper, lower, number, special character.
- **JWT**: Short-lived access + refresh stored hashed, rotated on refresh.
- **Frontend mock**: Controlled via env and health probe — see `api/config.ts`.
- **Navigation**: `router.push` / `router.replace` from `expo-router`. Never hardcode paths that exist as constants.
- **New features go in `features/`**: Never add business logic directly to `app/` files — they must stay as 2-line delegates.
- **Validation utils**: `utils/validation.ts` for cross-cutting (email, password). Feature-specific logic stays in `features/<name>/hooks/` or `features/<name>/utils/`.
- **Product name**: **Walvy** everywhere user-facing and in docs; folder `rork-checkapp` is tooling legacy only.
