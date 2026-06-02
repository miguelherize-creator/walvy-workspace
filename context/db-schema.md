# Esquema DB — Walvy (Referencia rápida)

**Motor:** PostgreSQL 15 · **Tablas:** ~55 · **Capas:** 19

> Schema completo: `legacy/DB_v2/schema.sql`

## Capas por dominio

### Layer 0-3 — Catálogos del sistema
```
country(id, name, code)
currency(id, code, symbol, name)
document_type(id, code, name, country_id)
status_domain(id, domain_name, status_value, label, is_active)
role(id, name)
permission(id, name, resource, action)
role_permission(role_id, permission_id)
financial_health_level(id, name, min_score, max_score, color_hex)
app_config(key, value, updated_at)
```

### Layer 4 — Identidad y autenticación
```sql
app_user(
  id UUID PK,
  email UNIQUE, rut UNIQUE, username UNIQUE,
  password_hash TEXT,
  email_verified BOOL DEFAULT false,
  onboarding_done BOOL DEFAULT false,
  role_id FK → role,
  status_id FK → status_domain('user_status'),
  deleted_at TIMESTAMPTZ,  -- soft delete
  created_at, updated_at
)

refresh_tokens(id, user_id FK, token_hash UNIQUE, expires_at, revoked_at)
otp_tokens(id, user_id FK, code_hash, type, expires_at, used_at)
biometric_preferences(id, user_id FK, device_id, enabled, created_at)
user_onboarding_state(id, user_id FK, step, completed_at)
```

### Layer 6 — Perfil financiero
```sql
user_financial_profile(
  id, user_id FK,
  monthly_income NUMERIC(12,2),
  monthly_expenses NUMERIC(12,2),
  savings_goal NUMERIC(12,2),
  currency_id FK,
  updated_at
)
user_goals(id, user_id FK, type, target_amount, deadline, status_id)
alert_preferences(id, user_id FK, alert_type, threshold, enabled)
```

### Layer 7 — Catálogo financiero
```sql
category(id, name, icon, color, type ENUM('income','expense'), is_system BOOL, user_id FK nullable)
cashflow_node(id, name, category_id FK, parent_id FK nullable)
financial_institution(id, name, country_id FK, logo_url)
```

### Layer 9 — Movimientos (Cashflow)
```sql
financial_movement(
  id UUID PK,
  user_id FK,
  amount NUMERIC(12,2),
  type ENUM('income','expense'),
  category_id FK,
  cashflow_node_id FK,
  description TEXT,
  movement_date DATE,
  source ENUM('manual','import','api'),
  status_id FK → status_domain('movement_status'),
  deleted_at TIMESTAMPTZ,  -- soft delete
  created_at
)
movement_review_queue(id, movement_id FK, reason, reviewed_at)
```

### Layer 10 — Presupuestos
```sql
budget_plan(id, user_id FK, month DATE, status_id, created_at)
budget_plan_item(id, budget_plan_id FK, category_id FK, amount NUMERIC(12,2), spent NUMERIC(12,2))
```

### Layer 11 — Deudas (Snowball)
```sql
debt(
  id, user_id FK,
  creditor_name, original_amount NUMERIC(12,2),
  current_balance NUMERIC(12,2), interest_rate NUMERIC(5,2),
  minimum_payment NUMERIC(12,2), due_day INT,
  status_id, deleted_at  -- soft delete
)
debt_schedules(id, debt_id FK, due_date, expected_amount)
debt_payments(id, debt_id FK, paid_amount, paid_at)
debt_snowball_plan(id, user_id FK, strategy ENUM('snowball','avalanche'), created_at)
```

### Layer 12 — Pagos recurrentes
```sql
user_payment(id, user_id FK, name, amount, frequency, next_due_date, category_id FK)
recurring_payment_suggestions(id, user_id FK, detected_pattern, suggested_amount)
```

### Layer 13 — Monetización
```sql
plan(id, name, features JSONB, is_active)
plan_price(id, plan_id FK, amount NUMERIC(10,2), currency_id FK, valid_from DATE, valid_until DATE)
subscription(id, user_id FK, plan_id FK, status_id, starts_at, ends_at)
payment_order(
  id, user_id FK, plan_id FK, amount NUMERIC(10,2),
  commerce_order TEXT UNIQUE,  -- idempotency key
  flow_token TEXT, status_id, created_at, confirmed_at
)
```

### Layer 16 — AI Assistant
```sql
ai_conversation(id, user_id FK, title, created_at, updated_at)
ai_message(
  id, conversation_id FK,
  role ENUM('user','assistant'),
  content TEXT,
  tokens_used INT,
  created_at
)
ai_context_snapshot(id, conversation_id FK, snapshot JSONB, created_at)
```

### Layer 18 — CQRS Read Models
```sql
rm_monthly_diagnosis(user_id, month, income, expenses, balance, health_score, updated_at)
rm_debt_summary(user_id, total_debt, monthly_minimum, next_payment_at, updated_at)
rm_expense_leaks(user_id, category_id, amount, detected_at)
```

### Layer 19 — Vistas SQL
```sql
v_user_access          -- user + role + subscription activa
v_user_current_subscription  -- subscription + plan + precio vigente
v_cashflow_summary     -- balance del mes por usuario
```

## Patrones clave

**Status Domain Pattern:** Los estados NO son ENUMs. Tabla `status_domain` + trigger `enforce_status_domain()` valida que el valor sea permitido para ese dominio. Permite agregar estados sin `ALTER TABLE`.

**Precios bitemporales:** `plan_price` con `valid_from` / `valid_until` mantiene historial sin perder datos históricos.

**Soft deletes:** `deleted_at TIMESTAMPTZ` en `app_user`, `financial_movement`, `debt`.

**Decimal transformer:** TypeORM convierte `NUMERIC(12,2)` → `number` JS (TypeORM retorna string por defecto).

**Idempotencia pagos:** `payment_order.commerce_order UNIQUE` previene duplicados en webhooks.
