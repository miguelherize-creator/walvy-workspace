# Módulo 7 — Requerimientos

**Módulo:** Pagos y Agenda  
**Layer:** 12  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 7

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Registrar pago próximo | ✅ Incluido |
| Ver agenda de pagos | ✅ Incluido |
| Marcar pago como realizado | ✅ Incluido |
| Pagos recurrentes | ✅ Incluido |
| Sugerencias de recurrencia automáticas | ✅ Incluido |
| Pagos vinculados a deudas | ✅ Incluido |
| Pagos compartidos (split) | ❌ No incluido en MVP |
| Integración con calendario del sistema | ❌ No incluido en MVP |

---

## Requerimientos Funcionales

### RF-01 — Registrar pago próximo

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Crear pago en la agenda |
| **Descripción** | El usuario registra un compromiso de pago futuro. |
| **Inputs** | `title`, `amount`, `currency_id`, `due_date`, `debt_id` (opt), `is_recurring`, `recurrence_interval_days` (opt), `notes` (opt) |
| **Reglas** | - `source = 'user'`. - `user_payment_status = pending`. - Si `debt_id` indicado: vincula a la deuda (el pago de la agenda puede luego abonarse a la deuda). - Si `is_recurring = true`: el job generará el siguiente pago al marcar este como `paid`. |

---

### RF-02 — Ver agenda de pagos

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | Listar pagos próximos |
| **Descripción** | El usuario ve sus pagos pendientes ordenados por fecha de vencimiento. |
| **Reglas** | - Filtra `user_payment` por `user_id + status = pending` ORDER BY `due_date ASC`. - El home (Módulo 3) muestra los próximos 7 días vía read model `user_upcoming_payments_summary`. - La pantalla de pagos muestra todos los pendientes con más contexto. |

---

### RF-03 — Marcar pago como realizado

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | Confirmar pago |
| **Descripción** | El usuario confirma que realizó un pago. Puede asociarlo a un movimiento importado. |
| **Inputs** | `user_payment_id`, `paid_at` (opt), `movement_id` (opt) |
| **Reglas** | - `user_payment_status → paid`, `paid_at = now()`. - Si `movement_id` indicado: vincula el pago al movimiento financiero. - Si `debt_id` está vinculado: el backend puede sugerir registrar el abono en `debt_payments`. - Si `is_recurring = true`: job genera el siguiente `user_payment` con `due_date = paid_at + recurrence_interval_days`. |

---

### RF-04 — Confirmar sugerencia de recurrencia

| Campo | Detalle |
|-------|---------|
| **ID** | RF-04 |
| **Nombre** | Aceptar pago recurrente sugerido |
| **Descripción** | El sistema detecta un patrón de gasto recurrente y sugiere añadirlo a la agenda. |
| **Reglas** | - El backend crea `recurring_payment_suggestions` con `status = pending_user_confirm`. - Si el usuario acepta: `status → accepted` + INSERT en `user_payment` con `is_recurring = true`. - Si descarta: `status → dismissed`. La sugerencia no vuelve a aparecer. |

---

## Requerimientos No Funcionales

### RNF-01 — Deduplicación de pagos del sistema
La constraint UNIQUE `(user_id, due_date, amount, debt_id)` WHERE `source = 'system'` previene que el job genere el mismo pago varias veces.

### RNF-02 — Notificaciones de vencimiento
`notification_queue.user_payment_id` permite enviar recordatorios de pago vía la cola de notificaciones (Módulo 2). El trigger de `notification_queue` se activa al crear un `user_payment` pendiente.
