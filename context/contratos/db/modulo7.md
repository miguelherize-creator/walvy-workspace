# M7 — Pagos y Agenda

**Layer:** 12 (Pagos y Agenda)  
**Estado:** 📋 Referencia — abierto a cambios  
**Docs originales:** `legacy/DB_v2/documentacion/modulo7/`

---

## Propósito
Agenda de compromisos de pago con fecha de vencimiento. Incluye pagos manuales, pagos vinculados a deudas (M4), pagos recurrentes y motor de sugerencias de recurrencia. Los próximos pagos se proyectan en el Home via `user_upcoming_payments_summary` (M3).

---

## Dependencias

```
app_user (M1) ──────────────────► user_payment
currency (M1) ───────────────────►
debt (M4) ───────────────────────► user_payment.debt_id (FK NULL)
financial_movement (M5) ─────────► user_payment.movement_id (FK NULL)
status (M1) ─────────────────────►

app_user ──► recurring_payment_suggestions
```

---

## Tablas

### `user_payment`
| Columna | Tipo | Notas |
|---------|------|-------|
| `user_payment_id` | UUID PK | |
| `user_id` | UUID FK | |
| `debt_id` | UUID NULL FK → debt | Si es abono a deuda |
| `movement_id` | UUID NULL FK → financial_movement | Evidencia del pago realizado |
| `title` | VARCHAR(200) | "Arriendo mayo", "Cuenta luz" |
| `amount` | NUMERIC(19,4) > 0 | |
| `due_date` | DATE NOT NULL | |
| `source` | VARCHAR(10) | `user` (manual) · `system` (generado por job) |
| `traffic_light_state` | VARCHAR(10) NULL | `green`, `yellow`, `red` — urgencia |
| `is_recurring` | BOOLEAN | |
| `recurrence_interval_days` | INT NULL | Si `is_recurring = true` |
| `user_payment_status_id` | BIGINT FK → status | Dominio: `user_payment`. `pending`, `paid`, `overdue`, `cancelled` |
| `paid_at` / `cancelled_at` | TIMESTAMPTZ NULL | |

**Índices:**
- `(user_id, user_payment_status_id)`
- `(user_id, due_date ASC)`
- UNIQUE `(user_id, due_date, amount, debt_id)` WHERE `source='system' AND debt_id IS NOT NULL` — deduplicación de pagos del sistema

### `recurring_payment_suggestions`
Sugerencias de recurrencia detectadas por análisis de patrones en movimientos.

| Columna | Notas |
|---------|-------|
| `user_id` FK | |
| `source` VARCHAR(20) | `movement_pattern`, `import` |
| `suggested_payload` JSONB | `{ "title": "Netflix", "amount": 17990, "day_of_month": 15 }` |
| `status` VARCHAR(25) | `pending_user_confirm`, `accepted`, `dismissed` |

---

## Notas de diseño
- `traffic_light_state` calculado en servicio: verde = >7 días, amarillo = 3-7 días, rojo = <3 días o vencido
- El worker de recurrencia crea nuevas filas en `user_payment` con `source='system'` cuando llega el siguiente período
- Requiere M2-DT-04 (worker de notificaciones) para alertas de vencimiento
