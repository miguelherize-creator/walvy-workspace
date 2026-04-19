# DB — Módulo 6: Presupuestos

## Tablas propias (escribe principalmente)

| Tabla | Rol |
|-------|-----|
| `budget_periods` | Crear/abrir el período mensual |
| `budget_lines` | Definir metas por categoría dentro del período |
| `categories` | Crear subcategorías personalizadas |
| `subcategories` | Alta de subcategorías del usuario |
| `ant_expense_rules` | Reglas de gastos hormiga por usuario |

## Tablas que lee (sin escribir)

| Tabla | Para qué |
|-------|----------|
| `transactions` | Gasto real comparado contra `planned_amount` |
| `user_financial_profile` | `monthly_income_estimate` para sugerir presupuesto |
| `app_config` | Umbrales de alerta (50%, 80%, 100%) |
| `financial_health_snapshots` | Semáforo del período |

---

## Detalle por tabla

### `budget_periods`
Un registro por mes por usuario. Actúa como contenedor del presupuesto.

| Campo | Qué hace |
|-------|----------|
| `year` + `month` | Identifican el período (1–12) |
| `currency` | CLP por defecto |

**Índice único:** `(user_id, year, month)` — no puede haber dos presupuestos para el mismo mes.

**Se crea:**
- Durante onboarding cuando el usuario configura su primer presupuesto
- Automáticamente al iniciar un nuevo mes (job de rollover)

---

### `budget_lines`
Una fila por categoría (o subcategoría) dentro de un período.

| Campo | Qué hace |
|-------|----------|
| `planned_amount` | Meta mensual — el valor contra el que se mide el gasto real |
| `planned_min` / `planned_max` | Rango sugerido por producto (orientativo) |
| `suggested_by_app` | `true` = la app propuso el valor; `false` = el usuario lo ajustó |

**Cómo se genera el primer presupuesto:**
1. Si el usuario importó cartola → analizar gasto real por categoría del último mes → proponer como `planned_amount`
2. Si no importó → aplicar valores guía del producto (`app_config` con proporciones de `monthly_income_estimate`)

**Umbrales de alerta** (NO están en `budget_lines`; están en `app_config`):
```
budget.threshold.yellow_pct = 80
budget.threshold.red_pct    = 100
```

El cálculo de consumo al momento:
```sql
SELECT
  bl.category_id,
  bl.planned_amount,
  COALESCE(SUM(t.amount), 0) AS gastado,
  ROUND(COALESCE(SUM(t.amount), 0) / bl.planned_amount * 100, 1) AS pct_consumido
FROM budget_lines bl
LEFT JOIN transactions t
  ON t.category_id = bl.category_id
  AND t.user_id = bl_user_id
  AND t.occurred_on BETWEEN period_start AND period_end
  AND t.movement_type = 'expense'
  AND t.deleted_at IS NULL
WHERE bl.budget_period_id = ?
GROUP BY bl.category_id, bl.planned_amount;
```

---

### `categories`
El usuario NO puede crear categorías base — solo subcategorías dentro de las existentes.

| `is_system` | `user_id` | Significado |
|-------------|-----------|-------------|
| `true` | `null` | Categoría de producto: Alimentación, Transporte, Salud… |
| `false` | `≠null` | Subcategoría creada por el usuario |

**Categorías de sistema MVP (ejemplos para Chile/LATAM):**

| slug | Nombre |
|------|--------|
| `alimentacion` | Alimentación |
| `transporte` | Transporte |
| `salud` | Salud |
| `entretenimiento` | Entretenimiento |
| `educacion` | Educación |
| `vivienda` | Vivienda |
| `deuda` | Deuda / Financiero |
| `ahorro` | Ahorro |
| `otros` | Otros |

---

### `ant_expense_rules`
Define qué se considera "gasto hormiga" para un usuario.

| Campo | Qué hace |
|-------|----------|
| `max_amount` | Transacciones por debajo de este monto se marcan como `is_ant_expense` |
| `category_id` | Acotar la regla a una categoría específica (`null` = todas) |

**La regla base la define producto en `app_config`:**
```
ant_expense.default_max_amount = 5000  (CLP)
```
Esta tabla permite al usuario ajustar si quiere un umbral distinto.

---

## Flujos de datos principales

```
ABRIR PERÍODO MENSUAL
  → INSERT budget_periods (year, month)
  → [si onboarding o primer mes] generar budget_lines sugeridas
  → INSERT budget_lines (suggested_by_app=true)

AJUSTAR META POR CATEGORÍA
  → UPDATE budget_lines.planned_amount (suggested_by_app=false)

CREAR SUBCATEGORÍA
  → INSERT categories (user_id=me, is_system=false, parent a categoría base vía slug)
  O INSERT subcategories (category_id=base, user_id=me)

VER CUMPLIMIENTO
  → SELECT budget_lines + JOIN transactions → calcular pct_consumido por categoría
  → comparar con umbrales de app_config → determinar color semáforo por categoría

REGISTRAR REGLA GASTO HORMIGA
  → UPSERT ant_expense_rules
  → [job] re-evaluar transactions → UPDATE is_ant_expense
```

---

## Índices críticos

| Tabla | Índice | Motivo |
|-------|--------|--------|
| `budget_periods` | `(user_id, year, month)` UNIQUE | Un presupuesto por mes |
| `budget_lines` | `(budget_period_id)` | Todas las líneas de un período |
| `budget_lines` | `(budget_period_id, category_id)` | Línea específica de categoría |
| `transactions` | `(user_id, category_id, occurred_on)` | Gasto real por categoría y período |
| `categories` | `slug` | Lookup por slug en reglas |

---

## Dependencias cross-módulo

| Destino | Qué envía | Descripción |
|---------|-----------|-------------|
| M3 — Home | `budget_lines` + `transactions` | Gráfico cumplimiento presupuesto |
| M3 — Home | `categories` con `is_ant_expense` | Gráfico de gastos hormiga |
| M8 — IA | `budget_lines` + gasto real | Contexto para recomendaciones |
| M2 — Perfil | `budget_lines.planned_amount` | Metas por categoría visibles en perfil |
