# Módulo 7 — Pagos y Agenda

**Layer cubierto:** 12 (Pagos y Agenda)  
**Corresponde a:** CSV Módulo 7 — Agenda de Pagos  
**Estado MVP:** ✅ Incluido

---

## 1. Propósito del módulo

El Módulo 7 gestiona la **agenda de pagos** del usuario: compromisos de pago con fecha de vencimiento, monto y estado. Incluye pagos manuales, pagos vinculados a deudas, pagos recurrentes, y el motor de sugerencias de recurrencia.

Los próximos pagos se proyectan en el home a través del read model `user_upcoming_payments_summary` (Módulo 3).

---

## 2. Diagrama de dependencias

```
app_user (M1) ──────────────────────────────────────► user_payment
currency (M1) ──────────────────────────────────────►     │
debt (M4) ──────────────────────────────────────────►     │ (FK opcional)
financial_movement (M5) ────────────────────────────►     │ (FK opcional)
status (M1) ────────────────────────────────────────►     │

app_user ──────────────────────────► recurring_payment_suggestions
                                       (sugerencias de recurrencia detectadas)
```

---

## 3. Tablas del módulo

### 3.1 `user_payment`

Agenda de pagos del usuario. Cada fila es un compromiso de pago con fecha, monto y estado.

| Columna | Tipo | Notas |
|---------|------|-------|
| `user_payment_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `debt_id` | UUID NULL FK → debt | Deuda asociada (si el pago es un abono a deuda) |
| `movement_id` | UUID NULL FK → financial_movement | Movimiento que evidencia el pago real |
| `title` | VARCHAR(200) NOT NULL | Descripción del pago. Ej: "Arriendo mayo", "Cuenta luz" |
| `amount` | NUMERIC(19,4) NOT NULL (> 0) | Monto a pagar |
| `currency_id` | BIGINT FK → currency | |
| `due_date` | DATE NOT NULL | Fecha de vencimiento |
| `source` | VARCHAR(10) | `user` (creado por el usuario) · `system` (generado por job) |
| `traffic_light_state` | VARCHAR(10) NULL | `green`, `yellow`, `red` — urgencia del pago |
| `is_recurring` | BOOLEAN DEFAULT false | Si el pago se repite periódicamente |
| `recurrence_interval_days` | INT NULL | Intervalo de recurrencia en días (si `is_recurring = true`) |
| `notes` | TEXT NULL | Notas del usuario |
| `user_payment_status_id` | BIGINT FK → status | Dominio: `user_payment`. Estados: `pending`, `paid`, `overdue`, `cancelled` |
| `paid_at` | TIMESTAMPTZ NULL | Cuando el usuario confirmó el pago |
| `cancelled_at` | TIMESTAMPTZ NULL | Cuando el usuario canceló el pago |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Índices:**
- `(user_id, user_payment_status_id)`
- `(user_id, due_date ASC)`
- UNIQUE `(user_id, due_date, amount, debt_id)` WHERE `source='system' AND debt_id IS NOT NULL` — deduplicación de pagos generados por el sistema

---

### 3.2 `recurring_payment_suggestions`

Sugerencias de pagos recurrentes detectados automáticamente por análisis de patrones en movimientos. El usuario confirma o descarta cada sugerencia.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `source` | VARCHAR(20) | `movement_pattern` · `import` |
| `suggested_payload` | JSONB NOT NULL | Datos de la sugerencia: `{ "title": "Netflix", "amount": 17990, "day_of_month": 15 }` |
| `status` | VARCHAR(25) | `pending_user_confirm`, `accepted`, `dismissed` |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

---

## 4. Triggers del módulo

| Trigger | Tabla | Evento |
|---------|-------|--------|
| `trg_user_payment_updated_at` | `user_payment` | BEFORE UPDATE |
| `trg_user_payment_status_domain` | `user_payment` | BEFORE INSERT OR UPDATE — valida dominio `user_payment` |
| `trg_recurring_payment_suggestions_updated_at` | `recurring_payment_suggestions` | BEFORE UPDATE |

---

## 5. Relaciones con otros módulos

| Módulo | Relación |
|--------|----------|
| Módulo 1 — Auth | `app_user`, `currency`, `status` como FK base |
| Módulo 3 — Home | `user_payment` alimenta `user_upcoming_payments_summary` (read model) |
| Módulo 4 — Deudas | `user_payment.debt_id` → `debt` (pagos de deuda en la agenda) |
| Módulo 5 — Movimientos | `user_payment.movement_id` → `financial_movement` (confirmación de pago) |
| Módulo 2 — Perfil | `notification_queue` usa `user_payment_id` para enviar recordatorios de vencimiento |

---

## 6. Notas de diseño

- **`source = 'system'`:** el job de deudas genera automáticamente pagos futuros para deudas activas. La constraint UNIQUE `(user_id, due_date, amount, debt_id)` previene duplicados si el job corre varias veces.
- **`traffic_light_state`:** calculado por el job de read models. `red` = vence en ≤ 3 días o ya venció; `yellow` = vence en ≤ 7 días; `green` = resto.
- **Recurrencia:** `is_recurring = true` + `recurrence_interval_days` permite al job generar el siguiente pago automáticamente al marcar el actual como `paid`.
- **Confirmación de pago:** el usuario puede asociar un `movement_id` al marcar un pago como pagado, enlazando la agenda con el movimiento real importado.
