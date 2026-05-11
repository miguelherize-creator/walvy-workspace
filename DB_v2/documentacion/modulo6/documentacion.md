# Módulo 6 — Presupuesto

**Layer cubierto:** 10 (Presupuesto)  
**Corresponde a:** CSV Módulo 6 — Presupuesto  
**Estado MVP:** ✅ Incluido

---

## 1. Propósito del módulo

El Módulo 6 gestiona el **presupuesto mensual** del usuario. Permite definir un límite de gasto por categoría para un mes específico y compararlo con los movimientos reales del mes.

Este módulo es principalmente de **configuración**: el usuario define sus límites y el home (Módulo 3) muestra el gráfico de cumplimiento a partir de los `financial_movement` categorizados.

---

## 2. Diagrama de dependencias

```
app_user (M1) ──────────────────────► budget_plan (uno por mes)
currency (M1) ──────────────────────►       │
                                            │
category (M5) ──────────────────────► budget_plan_item
                                       (límite por categoría)

financial_movement (M5) ──────────────────────────────────────────────────────────┐
category (M5) ────────────────────────────────────────────────────────────────────┤
                                                                                   ▼
                                          user_month_diagnosis_summary (M3 — read model)
                                          visible_savings_capacity_pct = (income - spent) / income
```

---

## 3. Tablas del módulo

### 3.1 `budget_plan`

Presupuesto mensual del usuario. Un registro por mes (UNIQUE `user_id + period_month`).

| Columna | Tipo | Notas |
|---------|------|-------|
| `budget_plan_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `period_month` | DATE NOT NULL | Primer día del mes. Ej: `2026-05-01` |
| `currency_id` | BIGINT FK → currency | Moneda del presupuesto |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Constraint:** UNIQUE `(user_id, period_month)`

---

### 3.2 `budget_plan_item`

Límite de gasto por categoría dentro de un presupuesto mensual. Un registro por categoría en el plan (UNIQUE `budget_plan_id + category_id`).

| Columna | Tipo | Notas |
|---------|------|-------|
| `budget_plan_item_id` | UUID PK | |
| `budget_plan_id` | UUID FK → budget_plan | |
| `category_id` | UUID FK → category | Solo categorías `is_leaf = true` |
| `amount_limit` | NUMERIC(19,4) NOT NULL (≥ 0) | Límite máximo de gasto para esta categoría en el mes |
| `planned_min` | NUMERIC(19,4) NULL | Gasto mínimo planificado (para presupuestos de ingresos) |
| `planned_max` | NUMERIC(19,4) NULL | Gasto máximo planificado (rango) |
| `suggested_by_app` | BOOLEAN DEFAULT false | Si el límite fue sugerido por el algoritmo de la app |
| `notes` | TEXT NULL | Notas del usuario |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Constraint:** UNIQUE `(budget_plan_id, category_id)`

---

## 4. Triggers del módulo

| Trigger | Tabla | Evento |
|---------|-------|--------|
| `trg_budget_plan_updated_at` | `budget_plan` | BEFORE UPDATE |
| `trg_budget_plan_item_updated_at` | `budget_plan_item` | BEFORE UPDATE |

---

## 5. Vistas relacionadas (Layer 19)

El cumplimiento del presupuesto **no se expone como vista separada en Layer 19** — se calcula en tiempo de request comparando:
- `budget_plan_item.amount_limit` (límite configurado)
- `SUM(financial_movement.amount_out)` filtrado por `category_id + period_month`

Para el home, `user_month_diagnosis_summary.visible_savings_capacity_pct` es el read model pre-calculado.

---

## 6. Relaciones con otros módulos

| Módulo | Relación |
|--------|----------|
| Módulo 1 — Auth | `app_user` como FK base |
| Módulo 3 — Home | `budget_plan` + `financial_movement` alimentan `user_month_diagnosis_summary.visible_savings_capacity_pct` |
| Módulo 5 — Movimientos | `category_id` de `budget_plan_item` debe coincidir con categorías de `financial_movement` |

---

## 7. Notas de diseño

- **Un plan por mes:** la constraint UNIQUE garantiza que no pueda haber dos presupuestos del mismo mes para el mismo usuario.
- **`suggested_by_app`:** el primer presupuesto del usuario puede ser generado por el sistema basándose en los 3 meses anteriores de gastos. El flag distingue qué ítems el usuario configuró vs. los que la app sugirió.
- **Presupuestos de ingresos:** `planned_min`/`planned_max` permiten modelar rangos (útil para ingresos variables, como freelancers).
