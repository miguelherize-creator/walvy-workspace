# DB — Módulo 4: Motor de Deudas (Bola de Nieve)

## Tablas propias (escribe principalmente)

| Tabla | Rol |
|-------|-----|
| `debts` | Registro central de deudas |
| `debt_schedules` | Cronograma de cuotas |
| `debt_payments` | Pagos realizados |
| `debt_attachments` | Cartolas y documentos adjuntos |
| `debt_snowball_plan` | Plan calculado de bola de nieve |
| `statement_imports` | Registro de importaciones de cartola |
| `import_line_items` | Filas individuales de cada importación |
| `movement_classification_suggestions` | Sugerencias de clasificación por reglas |

## Tablas que lee (sin escribir)

| Tabla | Para qué |
|-------|----------|
| `user_financial_profile` | `estimated_payment_capacity` como base para `extra_monthly_payment` |
| `transactions` | Vincular pagos reales a deudas |
| `funding_sources` | Asociar cuenta/tarjeta a cada deuda |
| `categories` + `subcategories` | Categorizar movimientos detectados |

---

## Detalle por tabla

### `debts`
Registro central. Campos mínimos para calcular bola de nieve:

| Campo | Obligatorio | Qué hace |
|-------|-------------|----------|
| `name` | ✅ | Label de la deuda para el usuario |
| `current_balance` | ✅ | Deuda actual — base del algoritmo |
| `minimum_payment` | ✅ | Pago mínimo exigido |
| `debt_type` | ✅ | Tipo: consumer, credit_card, line, mortgage, other |
| `creditor_label` | ◻ | Nombre del acreedor |
| `apr_annual` | ◻ | Tasa anual — si no se conoce, null |
| `installments_total` / `installments_remaining` | ◻ | Solo si es a cuotas |
| `due_day` / `next_due_date` | ◻ | Para alertas de vencimiento |
| `snowball_priority` | auto | Calculado: menor `current_balance` → prioridad 1 |
| `status` | auto | `active` → `paid` al saldar |

**Al crear:** se debe recalcular `debt_snowball_plan` del usuario.
**Al pagar:** `debt_payments INSERT` → decrementar `current_balance` → recalcular plan.
**Al saldar:** `UPDATE status = 'paid'` → liberar `minimum_payment` para siguiente deuda.

---

### `debt_snowball_plan`
Plan calculado. **No se sobreescribe** — cada recálculo genera un nuevo registro.

| Campo | Qué hace |
|-------|----------|
| `ordered_debt_ids` | Array con IDs en el orden bola de nieve |
| `extra_monthly_payment` | Monto adicional mensual disponible |
| `lump_sum_payment` | Pago único inicial (para simulador) |
| `estimated_completion` | `[{ debt_id, estimated_paid_date, freed_capacity }]` |

**Algoritmo V1 (bola de nieve):**
1. Ordenar deudas por `current_balance` ASC (menor primero)
2. Aplicar `minimum_payment` a todas las deudas excepto la prioritaria
3. Aplicar `extra_monthly_payment` + `minimum_payment` a la deuda #1
4. Al saldar deuda #1: su `minimum_payment` pasa a ser `extra` para deuda #2
5. `freed_capacity` = suma de mínimos liberados al ir cerrando deudas

---

### `statement_imports` + `import_line_items`
Pipeline de importación de cartolas.

```
statement_imports (status: pending → processing → parsed | failed)
  └── import_line_items (user_review_status: pending → accepted | rejected | edited)
        └── [al aceptar] → INSERT transactions
              └── [si corresponde] → movement_classification_suggestions
```

| Campo en `import_line_items` | Qué hace |
|------------------------------|----------|
| `raw_row` | Datos originales del archivo |
| `normalized` | `{ date, amount, description, type }` normalizado |
| `user_review_status` | El usuario aprueba/rechaza/edita cada fila |

---

### `movement_classification_suggestions`
Sugerencias automáticas de ruta para un movimiento.

| Campo | Qué hace |
|-------|----------|
| `suggested_target` | `debt_plan` → M4 / `bills_payable` → M7 |
| `rule_matched` | Clave de la regla que disparó (ej: `"cuota_tarjeta"`) |
| `confidence` | 0.0–1.0 — confianza de la regla |
| `user_decision` | `accepted` / `ignored` / `corrected` |

**Reglas MVP (por palabra clave en `description`):**

| Palabra clave | `suggested_target` |
|---------------|--------------------|
| "cuota", "cuotas" | `debt_plan` |
| "línea de crédito", "avance" | `debt_plan` |
| "interés", "mora", "recargo" | `debt_plan` |
| "arriendo", "dividendo" | `bills_payable` |
| Monto + periodicidad detectada | `bills_payable` |

---

## Flujos de datos principales

```
REGISTRAR DEUDA MANUALMENTE
  → INSERT debts (status='active')
  → recalcular debt_snowball_plan (INSERT nuevo plan)

SUBIR CARTOLA
  → INSERT statement_imports (status='pending')
  → [job] parsea archivo → UPDATE status='parsed'
  → INSERT import_line_items (status='pending' por fila)
  → [reglas] INSERT movement_classification_suggestions
  → [usuario revisa] UPDATE import_line_items.user_review_status
  → [aceptar fila] INSERT transactions
  → [si sugerencia debt] confirmar → INSERT debts o vincular existente
  → [si sugerencia bill] confirmar → INSERT bills_payable

REGISTRAR PAGO
  → INSERT debt_payments
  → UPDATE debts.current_balance, installments_remaining
  → [si current_balance=0] UPDATE debts.status='paid'
  → INSERT debt_snowball_plan (nuevo plan recalculado)

SIMULADOR (ajustar pago adicional)
  → No escribe — calcula en memoria y muestra resultado
  → Si usuario confirma extra: INSERT debt_snowball_plan con nuevo extra_monthly_payment
```

---

## Índices críticos

| Tabla | Índice | Motivo |
|-------|--------|--------|
| `debts` | `(user_id, status)` | Listar deudas activas |
| `debts` | `(user_id, snowball_priority ASC)` | Mostrar orden del plan |
| `debt_payments` | `(debt_id, paid_at DESC)` | Historial de pagos por deuda |
| `import_line_items` | `(import_id, user_review_status)` | Revisión de filas pendientes |
| `movement_classification_suggestions` | `(user_id, user_decision)` | Pendientes de decisión |
| `debt_snowball_plan` | `(user_id, computed_at DESC)` | Plan más reciente |

---

## Dependencias cross-módulo

| Destino | Campo | Origen |
|---------|-------|--------|
| M3 — Home | `debts.current_balance` | Gráfico de reducción de deuda |
| M3 — Home | `debt_snowball_plan.estimated_completion` | Proyección de capacidad liberada |
| M7 — Pagos | `movement_classification_suggestions` (target: bills_payable) | Crear `bills_payable` |
| M6 — Presupuesto | `transactions` (import + clasificación) | Alimentar gasto real |
