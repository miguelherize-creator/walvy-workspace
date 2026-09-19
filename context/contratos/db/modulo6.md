# M6 — Presupuesto

**Layer:** 10 (Presupuesto)  
**Estado:** 📋 Referencia — abierto a cambios  
**Docs originales:** `legacy/DB_v2/documentacion/modulo6/`

---

## Propósito
Módulo de **configuración**: el usuario define límites de gasto por categoría para el mes. El Home (M3) muestra el gráfico de cumplimiento cruzando estos límites con los `financial_movement` reales.

---

## Dependencias

```
app_user (M1) ──────────────────────► budget_plan (uno por mes)
currency (M1) ──────────────────────►
category (M5, is_leaf=true) ────────► budget_plan_item

financial_movement (M5) + category ─► user_month_diagnosis_summary (M3 read model)
```

---

## Tablas

### `budget_plan`
Un registro por mes por usuario.

| Columna | Tipo | Notas |
|---------|------|-------|
| `budget_plan_id` | UUID PK | |
| `user_id` | UUID FK | |
| `period_month` | DATE NOT NULL | Primer día del mes: `2026-05-01` |
| `currency_id` | BIGINT FK | |
| UNIQUE | `(user_id, period_month)` | Solo un plan por mes |

### `budget_plan_item`
Límite por categoría dentro de un plan.

| Columna | Tipo | Notas |
|---------|------|-------|
| `budget_plan_item_id` | UUID PK | |
| `budget_plan_id` | UUID FK | |
| `category_id` | UUID FK → category | Solo `is_leaf = true` |
| `amount_limit` | NUMERIC(19,4) NOT NULL ≥ 0 | Límite máximo de gasto |
| `planned_min` | NUMERIC(19,4) NULL | Rango mínimo (opcional) |
| `planned_max` | NUMERIC(19,4) NULL | Rango máximo (opcional) |
| `suggested_by_app` | BOOLEAN | Si el límite fue sugerido por el algoritmo |
| `notes` | TEXT NULL | |
| UNIQUE | `(budget_plan_id, category_id)` | |

---

## Notas de diseño
- No existe columna `spent` en el schema — el gasto real se calcula en runtime desde `financial_movement` (o desde los read models de M3)
- Meses pasados no son editables (lógica en servicio, no constraint en DB)
- Las alertas de umbral (80%, 100%) se calculan en el worker de M2 cruzando este módulo con M5
