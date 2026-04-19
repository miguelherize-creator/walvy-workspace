# DB — Módulo 7: Pagos

## Tablas propias (escribe principalmente)

| Tabla | Rol |
|-------|-----|
| `bills_payable` | Panel de cuentas por pagar |
| `recurring_payment_suggestions` | Pagos recurrentes detectados |
| `notification_queue` | Cola de recordatorios de vencimiento |

## Tablas que lee (sin escribir)

| Tabla | Para qué |
|-------|----------|
| `transactions` | Detectar pagos ya realizados para sugerir vinculación |
| `alert_preferences` | Saber qué canales y cadencia configuró el usuario |
| `funding_sources` | Asociar la cuenta desde la que se paga |
| `movement_classification_suggestions` | Recibir movimientos sugeridos como cuentas por pagar |

---

## Detalle por tabla

### `bills_payable`
Registro central del panel de pagos. NO ejecuta pagos — solo registra y alerta.

| Campo | Qué hace |
|-------|----------|
| `title` | Nombre de la obligación (ej: "Arriendo", "Luz", "Netflix") |
| `amount` | Monto a pagar |
| `due_date` | Fecha límite de pago |
| `status` | `pending` → `paid` (manual) / `overdue` (por job) |
| `is_recurring` | `true` = pago periódico |
| `recurrence_interval_days` | `30` = mensual, `7` = semanal |
| `traffic_light_state` | Calculado vs `due_date` — recalculado por job diario |
| `linked_transaction_id` | Vincula el pago real registrado en `transactions` |
| `paid_at` | Cuándo el usuario marcó como pagada |

**Criterio `traffic_light_state`:**
```
green  → due_date > hoy + 7 días
yellow → due_date entre hoy+1 y hoy+6
red    → due_date = hoy o ya pasó (overdue)
```

**Recurrencia:** si `is_recurring = true`, al marcar como pagada se crea automáticamente la siguiente instancia:
```
nueva due_date = paid_at + recurrence_interval_days
```

---

### `recurring_payment_suggestions`
Pagos recurrentes detectados por el sistema.

| Campo | Qué hace |
|-------|----------|
| `source` | `movement_pattern` (patrón en transactions) \| `import` (cartola) |
| `suggested_payload` | `{ title, amount, due_date, interval_days }` |
| `status` | `pending_user_confirm` → `accepted` \| `dismissed` |

**Al aceptar:**
```
INSERT bills_payable (is_recurring=true, recurrence_interval_days=suggested_payload.interval_days)
UPDATE recurring_payment_suggestions.status = 'accepted'
```

---

### `notification_queue`
Cola de notificaciones de vencimiento a enviar.

| Campo | Qué hace |
|-------|----------|
| `channel` | `in_app` \| `push` \| `email` — según `alert_preferences` del usuario |
| `payload` | JSON con título, cuerpo y deep link a la cuenta |
| `scheduled_for` | Cuándo enviar (ej: `due_date - 3 días`) |
| `sent_at` | `null` = pendiente; el worker lo completa |
| `bills_payable_id` | FK al pago que originó la alerta |

**Reglas de recordatorio** (valores desde `app_config`):
```
payment_reminder.days_before = [7, 3, 1]   → crea 3 registros por pago
payment_reminder.channels    = [push, email]
```

---

## Flujos de datos principales

```
CREAR CUENTA POR PAGAR
  → INSERT bills_payable (status='pending')
  → [si is_recurring] INSERT para las próximas N instancias
  → INSERT notification_queue (según alert_preferences del usuario)

MARCAR COMO PAGADA
  → UPDATE bills_payable.status = 'paid', paid_at = now()
  → [opcional] UPDATE linked_transaction_id si hay transacción asociada
  → [si is_recurring] INSERT nueva instancia del mes siguiente
  → INSERT gamification_events ('pay_on_time') si fue antes del vencimiento

ACEPTAR SUGERENCIA RECURRENTE
  → UPDATE recurring_payment_suggestions.status = 'accepted'
  → INSERT bills_payable (is_recurring=true)

JOB DIARIO
  → UPDATE bills_payable.traffic_light_state según due_date vs CURRENT_DATE
  → UPDATE bills_payable.status = 'overdue' WHERE due_date < CURRENT_DATE AND status = 'pending'

VINCULAR TRANSACCIÓN
  → UPDATE bills_payable.linked_transaction_id = transaction_id
  → [movimiento vino de M4 clasificación] aceptar classification_decision
```

---

## Índices críticos

| Tabla | Índice | Motivo |
|-------|--------|--------|
| `bills_payable` | `(user_id, status)` | Panel filtrado por estado |
| `bills_payable` | `(user_id, due_date ASC)` | Ordenar por vencimiento próximo |
| `notification_queue` | `(scheduled_for) WHERE sent_at IS NULL` | Worker de envío de alertas |
| `notification_queue` | `(user_id, bills_payable_id)` | Evitar duplicar recordatorios |
| `recurring_payment_suggestions` | `(user_id, status)` | Pendientes de confirmación |

---

## Dependencias cross-módulo

| Origen | Qué recibe | Descripción |
|--------|-----------|-------------|
| M4 — Deudas | `movement_classification_suggestions` (target: `bills_payable`) | Movimientos sugeridos como cuentas por pagar |
| M2 — Perfil | `alert_preferences` | Determina canal y cadencia de `notification_queue` |
| M3 — Home | `bills_payable` con `due_date` | Próximos vencimientos en el dashboard |
| M6 — Presupuesto | `bills_payable.linked_transaction_id` | La transacción de pago alimenta el gasto real del presupuesto |

---

## Garantías de integridad

- Un `bills_payable` con `status='paid'` siempre debe tener `paid_at ≠ null`.
- `linked_transaction_id` es opcional — se puede marcar pagada sin vincular movimiento.
- Los recordatorios en `notification_queue` se cancelan lógicamente si `bills_payable.status` cambia a `paid` antes de `scheduled_for`.
