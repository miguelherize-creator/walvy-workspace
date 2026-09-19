# M10 — Monetización

**Layer:** 13 (Monetización)  
**Estado:** ✅ Producción (parcial — Flow.cl activo)  
**Docs originales:** `legacy/DB_v2/documentacion/modulo10/`

---

## Propósito
Planes, precios por país/moneda, métodos de pago, suscripciones y órdenes de pago. Soporta B2C (free/mensual/anual), suscripciones regalo y B2B (desde módulo B2B).

---

## Dependencias

```
plan ──► plan_price (por país/moneda/fecha) ─────────────────────────┐
                                                                      ▼
app_user ──────────────────────────────────────────────────► subscription
company (B2B) ─────────────────────────────────────────────►

app_user / company ──► payment_method ──► payment_order
                                          (idempotencia webhooks)
```

---

## Tablas

### `plan`
| Columna | Notas |
|---------|-------|
| `plan_id` UUID PK | |
| `code` VARCHAR(50) UNIQUE | `monthly`, `annual`, `free` |
| `billing_period` VARCHAR(10) NULL | NULL para plan free |
| `is_active` BOOLEAN | |

### `plan_price` — Patrón bitemporal
| Columna | Notas |
|---------|-------|
| `plan_price_id` UUID PK | |
| `plan_id` FK, `country_id` FK, `currency_id` FK | |
| `price_amount` NUMERIC(19,4) ≥ 0 | |
| `valid_from` DATE NOT NULL | Inicio de vigencia |
| `valid_to` DATE NULL | NULL = precio vigente |
| UNIQUE | `(plan_id, country_id, currency_id)` WHERE `is_active=true AND valid_to IS NULL` |

**Precio vigente:** `valid_from <= now() AND (valid_to IS NULL OR valid_to >= now())`

### `payment_method`
Métodos de pago guardados. Multi-proveedor. **Sin datos PCI — solo tokens del proveedor.**

| Columna | Notas |
|---------|-------|
| `owner_type` VARCHAR(10) | `USER` · `COMPANY` |
| `user_id` UUID NULL FK | |
| `company_id` UUID NULL FK | |
| `provider` VARCHAR(50) | `stripe`, `mercadopago`, `flow` |
| `provider_customer_ref` VARCHAR(120) NULL | ID del cliente en el proveedor |
| `last4` CHAR(4) NULL | Últimos 4 dígitos (solo display) |
| `is_default` BOOLEAN | |

### `subscription`
| Columna | Notas |
|---------|-------|
| `subscription_id` UUID PK | |
| `user_id` FK (NULL si es B2B) | |
| `company_id` FK NULL | |
| `plan_id` FK | |
| `status_id` FK → status | Dominio: `subscription`. `trialing`, `active`, `past_due`, `cancelled`, `expired` |
| `started_at` / `ends_at` TIMESTAMPTZ | |
| `billed_amount` NUMERIC(19,4) NULL | Precio cobrado congelado al momento de activación |
| `gift_by_user_id` UUID NULL FK | Si fue suscripción regalo |
| `trial_ends_at` TIMESTAMPTZ NULL | |

### `payment_order`
| Columna | Notas |
|---------|-------|
| `payment_order_id` UUID PK | |
| `user_id` FK | |
| `plan_id` FK | |
| `subscription_id` FK NULL | Se vincula al activar |
| `payment_method_id` FK NULL | |
| `amount` NUMERIC(19,4) | |
| `commerce_order` TEXT UNIQUE | **Clave de idempotencia de webhooks** |
| `provider` VARCHAR(50) | `flow`, `stripe`, `mercadopago` |
| `provider_order_ref` TEXT NULL | Referencia del proveedor |
| `status_id` FK → status | Dominio: `payment_method`. `pending`, `paid`, `failed`, `refunded` |

---

## Notas de diseño
- `commerce_order UNIQUE` es la garantía de idempotencia ante webhooks duplicados de Flow.cl
- `billed_amount` en `subscription` congela el precio cobrado — independiente de cambios futuros en `plan_price`
- Variables de entorno requeridas: `FLOW_API_KEY`, `FLOW_SECRET_KEY`, `FLOW_API_URL`
