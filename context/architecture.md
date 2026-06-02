# Arquitectura del Sistema — Walvy

## Capas del sistema

```
FRONTEND (Expo / React Native)
  features/<nombre>/ui  →  hooks  →  data  →  api/
  store/ (AuthProvider, ThemeProvider)
         ↕ HTTPS/JSON REST
BACKEND (NestJS 10)
  Controller → Service → Repository/Entity
  Guards (JWT, Throttler) · Pipes · Filters
         ↕ TypeORM
DATOS (PostgreSQL 15)
  19 layers · status_domain · CQRS read models · vistas SQL
         ↕
EXTERNOS: Flow.cl · SMTP · [FCM/APNs pendiente]
```

## Backend — Module-per-feature

```
src/<modulo>/
├── <modulo>.module.ts
├── <modulo>.controller.ts   # solo orquesta request/response, cero lógica
├── <modulo>.service.ts      # TODA la lógica de negocio aquí
├── dto/
├── entities/
└── guards/ / strategies/    # solo si el módulo los define
```

### Módulos implementados
| Módulo | Ruta | Estado |
|--------|------|--------|
| `AuthModule` | `/auth` | ✅ Completo |
| `UsersModule` | `/users` | ✅ Completo |
| `CashflowModule` | `/cashflow` | ✅ Completo (backend) |
| `SubscriptionsModule` | `/subscriptions` | ✅ Completo |
| `HealthController` | `/health` | ✅ `{ ok: true }` sin auth |

### Módulos pendientes
| Módulo | Sprint | Estado |
|--------|--------|--------|
| `FinancialProfileModule` | M2 | ⚠️ Deuda técnica M2-DT-01 |
| `BudgetModule` | M4/Sprint 5 | Schema only |
| `DebtsModule` | M4/Sprint 6 | Schema only |
| `RecurringPaymentsModule` | Sprint 7 | Schema only |
| `AIAssistantModule` | Sprint 8 | Schema only |
| `AdminModule` | M7 | Vacío — deuda técnica M1-DT-01 |

## Frontend — Feature-First + Clean Architecture

```
features/<nombre>/
├── index.ts                    # contrato público — ÚNICO import desde fuera
├── data/<Nombre>Repository.ts  # wrappea api/<nombre>Service
├── hooks/use<Nombre>.ts        # estado, validación, mutations (CERO JSX)
└── ui/<Nombre>Screen.tsx       # JSX puro, delega lógica al hook
```

**Regla de dependencias (solo downward):**
```
app/ → features/ui/ → features/hooks/ → features/data/ → api/ → store/
```

**Regla de imports cross-feature:**
- PROHIBIDO: `import { X } from '../otra-feature/...'`
- PERMITIDO: `import { X } from '@/store/AuthProvider'`

### Sprint status frontend
| Sprint | Feature | Estado |
|--------|---------|--------|
| 1 | `features/auth/` | ✅ Completo |
| 2 | `features/profile/` | ✅ Completo |
| 3 | `features/home/` | ✅ Completo |
| 4 | `features/transactions/` | ❌ Pendiente |
| 5 | `features/budget/` | ❌ Pendiente |
| 6 | `features/debts/` | ❌ Pendiente |
| 7 | `features/payments/` | ❌ Pendiente |
| 8 | `features/assistant/` | ❌ Pendiente |

## Flujo de autenticación

```
POST /auth/register → OTP email (15min) → /auth/verify-otp
POST /auth/login → accessToken (15min) + refreshToken (7d, hasheado en DB)
POST /auth/refresh → token rotation (replay attack detection)
POST /auth/logout → revoca refreshToken en DB
```

## DB — 19 Capas semánticas

| Layer | Tablas clave |
|-------|-------------|
| 0–3 | country, currency, status_domain, role, financial_health_level |
| 4 | app_user, refresh_tokens, otp_tokens, biometric_preferences, user_onboarding_state |
| 5 | company (B2B, futuro) |
| 6 | user_financial_profile, user_goals, alert_preferences |
| 7 | category, cashflow_node, financial_institution |
| 8 | file_upload, import_line_items, movement_classification_suggestions |
| 9 | financial_movement, movement_review_queue |
| 10 | budget_plan, budget_plan_item |
| 11 | debt, debt_schedules, debt_payments, debt_snowball_plan |
| 12 | user_payment, recurring_payment_suggestions |
| 13 | plan, plan_price (bitemporal), subscription, payment_order |
| 14 | gamification_rules, gamification_events, user_gamification_stats |
| 15–16 | messaging, ai_conversation, ai_message, ai_context_snapshot |
| 17 | admin_users, admin_audit_log, audit_log |
| 18 | rm_monthly_diagnosis, rm_debt_summary, rm_expense_leaks (CQRS) |
| 19 | v_user_access, v_user_current_subscription, v_cashflow_summary (vistas SQL) |

## Principios irrenunciables

1. **Sin lógica en controllers** — solo orquestan request/response
2. **Sin imports cross-feature** — solo vía `store/` o `api/`
3. **Sin DELETE físico** de `app_user`, `financial_movement`, `debt`
4. **Sin tokens en logs** — nunca loguear accessToken, refreshToken, passwordHash
5. **Sin ENUMs para estados mutables** — usar `status_domain` pattern
6. **Sin `any` implícito** — TypeScript strict en todo
