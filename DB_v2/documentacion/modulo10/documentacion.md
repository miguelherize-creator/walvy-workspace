# Módulo 10 — Monetización

**Layer cubierto:** 13 (Monetización)  
**Corresponde a:** CSV Módulo 10 — Suscripciones y Pagos  
**Estado MVP:** ✅ Incluido

---

## 1. Propósito del módulo

El Módulo 10 gestiona la **monetización** de Walvy: planes, precios por país/moneda, métodos de pago, suscripciones y órdenes de pago. Soporta el modelo B2C con planes free/mensual/anual, suscripciones regalo (gift) y la posibilidad de suscripciones B2B (desde módulo B2B).

---

## 2. Diagrama de dependencias

```
plan ──── plan_price (por país/moneda/fecha) ──────────────────────────────┐
                                                                            ▼
app_user ──────────────────────────────────────────────────────────► subscription
company (moduloB2B) ───────────────────────────────────────────────►       │
                                                                            │
app_user / company ─────────────────────────────────────────► payment_method
                                                                            │
                                                                            ▼
                                                                  payment_order
                                                               (idempotencia webhooks)
```

---

## 3. Tablas del módulo

### 3.1 `plan`

Catálogo de planes de suscripción. Administrado por el equipo de Walvy.

| Columna | Tipo | Notas |
|---------|------|-------|
| `plan_id` | UUID PK | |
| `code` | VARCHAR(50) UNIQUE | `monthly`, `annual`, `free` |
| `name_es` | VARCHAR(120) NOT NULL | Nombre visible. Ej: "Plan Mensual" |
| `billing_period` | VARCHAR(10) NULL | `monthly`, `annual`. NULL para plan free |
| `is_active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

---

### 3.2 `plan_price`

Precio versionado por país y moneda. Patrón bitemporal: `valid_from`/`valid_to` permite historizar cambios de precio sin perder datos.

| Columna | Tipo | Notas |
|---------|------|-------|
| `plan_price_id` | UUID PK | |
| `plan_id` | UUID FK → plan | |
| `country_id` | BIGINT FK → country | |
| `currency_id` | BIGINT FK → currency | |
| `price_amount` | NUMERIC(19,4) NOT NULL (≥ 0) | |
| `valid_from` | DATE NOT NULL | Inicio de vigencia del precio |
| `valid_to` | DATE NULL | NULL = precio vigente. CHECK `valid_to > valid_from` |
| `is_active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Índice único:** `(plan_id, country_id, currency_id)` WHERE `is_active = true AND valid_to IS NULL` — solo un precio vigente activo por combinación

---

### 3.3 `payment_method`

Métodos de pago guardados. Multi-proveedor (Stripe, MercadoPago, Flow). Sin datos de PCI — solo tokens/refs del proveedor.

| Columna | Tipo | Notas |
|---------|------|-------|
| `payment_method_id` | UUID PK | |
| `owner_type` | VARCHAR(10) | `USER` · `COMPANY` |
| `user_id` | UUID NULL FK → app_user | Obligatorio si `owner_type = USER` |
| `company_id` | UUID NULL FK → company | Obligatorio si `owner_type = COMPANY` |
| `provider` | VARCHAR(50) NOT NULL | `stripe`, `mercadopago`, `flow` |
| `provider_customer_ref` | VARCHAR(120) NULL | ID del cliente en el proveedor |
| `provider_payment_method_ref` | VARCHAR(120) NOT NULL | Token de pago en el proveedor |
| `card_brand` | VARCHAR(30) NULL | Ej: `visa`, `mastercard` |
| `card_last4` | VARCHAR(4) NULL | Últimos 4 dígitos |
| `card_exp_month` / `card_exp_year` | SMALLINT NULL | Expiración |
| `is_default` | BOOLEAN DEFAULT false | Método predeterminado del usuario |
| `payment_method_status_id` | BIGINT FK → status | Dominio: `payment_method`. Estados: `active`, `expired`, `revoked` |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Constraint:** `(owner_type='USER' AND user_id IS NOT NULL AND company_id IS NULL) OR (owner_type='COMPANY' AND company_id IS NOT NULL AND user_id IS NULL)` — exclusividad USER/COMPANY

---

### 3.4 `subscription`

Suscripción activa o histórica de un usuario/empresa a un plan. Soporta B2C, B2B y suscripciones regalo (gift).

| Columna | Tipo | Notas |
|---------|------|-------|
| `subscription_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `company_id` | UUID NULL FK → company | Solo si `origin = 'B2B'` |
| `origin` | VARCHAR(3) | `B2B` · `B2C` |
| `plan_id` | UUID FK → plan | |
| `plan_price_id` | UUID NULL FK → plan_price | Snapshot del precio al suscribir |
| `billed_amount` | NUMERIC(19,4) NULL | Monto facturado (snapshot inmutable tras el pago) |
| `billed_currency_id` | BIGINT NULL FK → currency | |
| `subscription_status_id` | BIGINT FK → status | Dominio: `subscription`. Estados: `active`, `cancelled`, `expired`, `paused` |
| `starts_at` | TIMESTAMPTZ NOT NULL | |
| `ends_at` | TIMESTAMPTZ NULL | NULL = sin fecha de expiración (hasta cancelación) |
| `provider` | VARCHAR(50) DEFAULT 'manual' | Proveedor de pago o `manual` |
| `external_subscription_ref` | VARCHAR(120) NULL | ID de suscripción en el proveedor |
| `external_payment_ref` | VARCHAR(120) NULL | |
| `renew_at` | TIMESTAMPTZ NULL | Próxima fecha de renovación |
| `cancelled_at` | TIMESTAMPTZ NULL | |
| **Gift subscription** | | |
| `is_gift` | BOOLEAN DEFAULT false | |
| `gift_sender_name` | VARCHAR(120) NULL | |
| `gift_sender_email` | VARCHAR(320) NULL | |
| `gift_recipient_email` | VARCHAR(320) NULL | |
| `gift_message` | VARCHAR(250) NULL | |
| `gift_token` | VARCHAR(120) NULL UNIQUE | Token de redención |
| `gift_redeemed_at` | TIMESTAMPTZ NULL | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Constraints:**
- `origin = 'B2B'` → `company_id IS NOT NULL`
- `is_gift = true` → `origin = 'B2C'` (los regalos son siempre B2C)
- Si `is_gift = true`: `gift_sender_name`, `gift_recipient_email` y `gift_token` son obligatorios

---

### 3.5 `payment_order`

Órdenes de pago para mantener idempotencia ante webhooks duplicados del proveedor de pago.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `subscription_id` | UUID NULL FK → subscription | |
| `commerce_order` | TEXT UNIQUE NOT NULL | ID único de la orden (idempotencia) |
| `provider` | VARCHAR(50) NOT NULL | |
| `provider_token` | TEXT NULL | Token del proveedor |
| `provider_order_ref` | TEXT NULL | Referencia de la orden en el proveedor |
| `amount` | NUMERIC(19,4) NOT NULL (> 0) | |
| `currency_id` | BIGINT FK → currency | |
| `status` | VARCHAR(20) | `pending`, `paid`, `failed`, `expired`, `refunded` |
| `provider_response` | JSONB NULL | Respuesta completa del webhook |
| `paid_at` | TIMESTAMPTZ NULL | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Índices:**
- `(user_id, created_at DESC)`
- `(provider_token)` WHERE `provider_token IS NOT NULL`

---

## 4. Vistas relacionadas (Layer 19)

| Vista | Qué resuelve |
|-------|-------------|
| `v_user_access` | Determina si el usuario tiene acceso activo (subscription activa o trial vigente) |
| `v_user_current_subscription` | Suscripción vigente del usuario |
| `v_subscription_effective_state` | Estado efectivo considerando fechas de inicio/fin |

---

## 5. Triggers del módulo

| Trigger | Tabla | Evento |
|---------|-------|--------|
| `trg_plan_updated_at` | `plan` | BEFORE UPDATE |
| `trg_plan_price_updated_at` | `plan_price` | BEFORE UPDATE |
| `trg_payment_method_updated_at` | `payment_method` | BEFORE UPDATE |
| `trg_payment_method_status_domain` | `payment_method` | BEFORE INSERT OR UPDATE — valida dominio `payment_method` |
| `trg_subscription_updated_at` | `subscription` | BEFORE UPDATE |
| `trg_subscription_status_domain` | `subscription` | BEFORE INSERT OR UPDATE — valida dominio `subscription` |
| `trg_payment_order_updated_at` | `payment_order` | BEFORE UPDATE |

---

## 6. Relaciones con otros módulos

| Módulo | Relación |
|--------|----------|
| Módulo 1 — Auth | `app_user`, `country`, `currency` como FK base. `v_user_access` determina acceso |
| Módulo 9 — Admin | Admins pueden ver/gestionar suscripciones desde el backoffice |
| Módulo B2B | `company` como FK en `subscription` y `payment_method` |

---

## 7. Notas de diseño

- **Idempotencia de webhooks:** `payment_order.commerce_order` es UNIQUE. Si Flow o Stripe envía el mismo webhook dos veces, el segundo INSERT falla con 409 y el backend ignora el duplicado.
- **Snapshot de precio:** `subscription.billed_amount` se copia desde `plan_price` al momento del pago y nunca cambia, aunque el precio del plan suba después.
- **Trial en `app_user`:** el trial se maneja con `app_user.trial_started_at`/`trial_ends_at` (Layer 4), no con una `subscription` separada. `v_user_access` une ambos para determinar el acceso.
- **Gift subscriptions:** `gift_token` permite al receptor redimir la suscripción sin necesidad de pasar por el flujo de pago.
