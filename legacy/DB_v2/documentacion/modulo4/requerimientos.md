# Módulo 4 — Requerimientos

**Módulo:** Motor de Deudas (Bola de Nieve)  
**Layer:** 11  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 4

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Registrar deuda manualmente | ✅ Incluido |
| Ver listado de deudas activas | ✅ Incluido |
| Registrar abono a deuda | ✅ Incluido |
| Ver cronograma de cuotas | ✅ Incluido |
| Simulación de payoff (Bola de Nieve) | ✅ Incluido |
| Adjuntar documentos a deuda | ✅ Incluido |
| Importación automática de deudas desde banco | ❌ No incluido en MVP |
| Motor de negociación de deudas | ❌ No incluido en MVP |
| Historial multi-simulación comparativo | ❌ No incluido en MVP |

---

## Requerimientos Funcionales

### RF-01 — Registrar deuda

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Crear deuda |
| **Descripción** | El usuario registra una deuda indicando acreedor, tipo, saldo actual y condiciones. |
| **Inputs** | `name`, `debt_type`, `debt_source_type`, `current_balance`, `currency_id`, `apr_annual`, `minimum_payment`, `installments_total`, `installments_remaining`, `due_day`, `financial_instrument_id` (opt) |
| **Reglas** | - `current_balance >= 0`. - Si se indica `installments_total` y `due_day`, el sistema puede pre-generar `debt_schedules`. - `debt_status_id` → `active` al crear. - `snowball_priority` se asigna al final de la cola; el job de cálculo lo reordena según el algoritmo. |
| **Output** | `debt` creado. `debt_schedules` pre-generados si corresponde. `gamification_events` con `event_type = debt_registered`. |

---

### RF-02 — Editar deuda

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | Actualizar deuda |
| **Descripción** | El usuario actualiza el saldo, condiciones o estado de una deuda existente. |
| **Reglas** | - Solo el dueño (`user_id`) puede editar. - Cambiar `current_balance` manualmente registra el cambio en `debt.updated_at` y puede invalidar el read model. - Cambiar a `debt_status = settled` marca la deuda como pagada; no se borra. - `deleted_at` se usa solo cuando el usuario quiere "archivar" la deuda del historial visible. |

---

### RF-03 — Registrar abono

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | Registrar pago/abono a deuda |
| **Descripción** | El usuario registra un abono. Puede asociarlo a un movimiento financiero importado. |
| **Inputs** | `debt_id`, `amount`, `paid_at`, `movement_id` (opt), `notes` (opt) |
| **Reglas** | - INSERT en `debt_payments` (inmutable — nunca se modifica). - `debt.current_balance -= amount`. - Si `amount >= current_balance`: el sistema sugiere marcar la deuda como `settled`. - El abono dispara `gamification_events` con `event_type = debt_payment_registered`. |
| **Output** | `debt_payments` creado. `debt.current_balance` actualizado. |

---

### RF-04 — Ver cronograma de cuotas

| Campo | Detalle |
|-------|---------|
| **ID** | RF-04 |
| **Nombre** | Consultar cronograma de cuotas |
| **Descripción** | El usuario ve el cronograma de cuotas planificado para su deuda. |
| **Reglas** | - Lee `debt_schedules` filtrado por `debt_id`. - Read-only; no editable directamente. - Si no existe cronograma (deuda registrada sin `installments_total`), se muestra mensaje informativo. |

---

### RF-05 — Simulación de payoff

| Campo | Detalle |
|-------|---------|
| **ID** | RF-05 |
| **Nombre** | Crear simulación Bola de Nieve |
| **Descripción** | El usuario configura un escenario de payoff indicando cuánto puede abonar extra cada mes. El sistema calcula el orden óptimo y las fechas de liquidación. |
| **Inputs** | `start_date`, `extra_monthly_payment`, `initial_lump_sum` |
| **Reglas** | - Una simulación `active` por usuario a la vez. Crear una nueva archiva la anterior. - El algoritmo Bola de Nieve ordena deudas por saldo menor primero (prioridad = menor saldo → mayor motivación). - El resultado se escribe en `debt_payoff_schedule` (una fila por deuda). - El job de read models lee la simulación `active` para poblar `user_month_debt_priority_summary`. |
| **Output** | `debt_payoff_simulation` creado. `debt_payoff_schedule` con una fila por deuda activa. |

---

### RF-06 — Adjuntar documento a deuda

| Campo | Detalle |
|-------|---------|
| **ID** | RF-06 |
| **Nombre** | Subir archivo adjunto |
| **Descripción** | El usuario adjunta un documento (cartola, contrato) a una deuda. Opcionalmente el backend hace OCR para extraer el saldo. |
| **Reglas** | - Crea `debt_attachments` con `storage_key` apuntando a S3. - Si OCR disponible: `parsed_summary` se rellena con el JSON resultado. - `debt_id` puede ser NULL si el usuario subió el archivo antes de asociarlo a una deuda. |

---

## Requerimientos No Funcionales

### RNF-01 — Inmutabilidad de abonos
`debt_payments` nunca se modifica ni elimina. Es el registro de auditoría de todos los abonos de la deuda.

### RNF-02 — Consistencia de `current_balance`
El campo `debt.current_balance` se actualiza síncronamente al registrar un abono. El sistema no recalcula desde el historial de `debt_payments` en cada request.

### RNF-03 — Una simulación activa
Solo puede haber una `debt_payoff_simulation` con `simulation_status = active` por usuario. El sistema archiva automáticamente la anterior al activar una nueva.

### RNF-04 — Borrado lógico
Las deudas se archivan con `deleted_at`, no se borran físicamente. Los `debt_payments` y `debt_schedules` asociados se conservan.
