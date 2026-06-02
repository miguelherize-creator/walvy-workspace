# Módulo 6 — Requerimientos

**Módulo:** Presupuesto  
**Layer:** 10  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 6

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Crear presupuesto mensual | ✅ Incluido |
| Definir límite por categoría | ✅ Incluido |
| Ver gráfico de cumplimiento (home) | ✅ Incluido |
| Sugerencia de presupuesto basada en historial | ✅ Incluido |
| Presupuestos compartidos (pareja/familia) | ❌ No incluido en MVP |
| Alertas configurables por umbral | ❌ No incluido en MVP |

---

## Requerimientos Funcionales

### RF-01 — Crear o editar presupuesto del mes

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Gestionar presupuesto mensual |
| **Descripción** | El usuario crea o edita el presupuesto del mes actual, definiendo límites por categoría. |
| **Inputs** | `period_month`, `currency_id`, lista de `{ category_id, amount_limit, notes }` |
| **Reglas** | - UPSERT en `budget_plan` por `(user_id, period_month)`. - Cada ítem → UPSERT en `budget_plan_item` por `(budget_plan_id, category_id)`. - Solo categorías `is_leaf = true` pueden usarse como ítems. - Si el usuario no tiene historial: la app puede sugerir límites marcados con `suggested_by_app = true`. |

---

### RF-02 — Ver cumplimiento de presupuesto

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | Consultar estado del presupuesto |
| **Descripción** | El usuario ve cuánto ha gastado vs. el límite definido por categoría. |
| **Reglas** | - El backend compara `budget_plan_item.amount_limit` con `SUM(financial_movement.amount_out)` agrupado por `category_id` y mes. - Si `gasto / amount_limit >= 0.8`: el motor de mensajería puede generar un `message_event` con regla `budget_overrun`. - El home muestra `visible_savings_capacity_pct` del read model (pre-calculado). |

---

### RF-03 — Copiar presupuesto del mes anterior

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | Reutilizar presupuesto anterior |
| **Descripción** | El usuario puede copiar los ítems del mes anterior como punto de partida. |
| **Reglas** | - El backend busca `budget_plan` del mes anterior del mismo usuario. - Crea nuevos `budget_plan_item` con los mismos `category_id` y `amount_limit`. - `suggested_by_app = false` (el usuario tomó la decisión de copiar). |

---

## Requerimientos No Funcionales

### RNF-01 — Un plan por mes
La constraint UNIQUE `(user_id, period_month)` garantiza que no haya dos planes del mismo mes.

### RNF-02 — Cálculo de cumplimiento
El porcentaje de cumplimiento se calcula en el job periódico de read models (Módulo 3). El endpoint de presupuesto puede calcularlo en tiempo de request para la pantalla de detalle, pero el home solo lee el read model.
