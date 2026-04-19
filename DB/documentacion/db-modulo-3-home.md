# DB — Módulo 3: Home (Seguimiento, visualización y motivación)

## Rol del módulo en la base de datos
El módulo Home es **principalmente lector** — agrega y presenta datos de otros módulos.
Escribe directamente solo en las tablas de gamificación y salud financiera.

## Tablas propias (escribe principalmente)

| Tabla | Rol |
|-------|-----|
| `financial_health_snapshots` | Genera/actualiza el semáforo financiero |
| `gamification_events` | Registra logros del usuario |
| `user_gamification_stats` | Acumula puntos y nivel |
| `user_score_history` | Guarda snapshot histórico de puntaje por período |
| `recommendation_events` | Log de recomendaciones mostradas en pantalla |

## Tablas que lee (sin escribir)

| Tabla | Vista que alimenta |
|-------|-------------------|
| `transactions` | Balance del mes, gráfico de ingresos/gastos |
| `budget_lines` + `transactions` | Gráfico cumplimiento de presupuesto |
| `categories` | Gráfico de gasto por categoría |
| `debts` | Gráfico de reducción de deudas |
| `debt_snowball_plan` | Proyección de capacidad liberada |
| `bills_payable` | Próximos vencimientos en el resumen |
| `user_goals` | Progreso de metas en el dashboard |
| `user_financial_profile` | Capacidad estimada de pago |
| `ant_expense_rules` | Identificar gastos hormiga en gráficos |

---

## Detalle por tabla

### `financial_health_snapshots`
El semáforo visible en el home.

| Campo | Qué hace aquí |
|-------|---------------|
| `traffic_light` | `green` / `yellow` / `red` — estado global del período |
| `score` | 0–100 para mostrar evolución gráfica |
| `payload` | JSON con: balance, total_debt, budget_used_pct, payments_overdue, days_since_last_import |

**Criterio de `traffic_light`:** definido en `app_config` por producto. Ejemplo:
- `green`: presupuesto < 80% y sin pagos vencidos y deuda estable
- `yellow`: presupuesto entre 80–100% o pago próximo en 3 días
- `red`: presupuesto > 100% o pago vencido

**Cuándo se genera:** job diario o al cerrar/abrir la app (triggered).

---

### `gamification_events`
Log inmutable de logros ganados.

| Campo | Qué hace aquí |
|-------|---------------|
| `event_type` | Clave de la regla disparada (debe existir en `gamification_rules`) |
| `points` | Snapshot de puntos al momento del evento |
| `reference_type` / `reference_id` | Trazabilidad: qué acción generó el logro |

**Eventos tipicos del MVP:**

| event_type | Cuándo |
|------------|--------|
| `register_transaction` | Usuario ingresa un movimiento |
| `pay_on_time` | Marca un `bills_payable` como pagado antes del vencimiento |
| `stay_under_budget` | Cierra el mes sin superar una categoría |
| `register_debt` | Agrega una deuda a la bola de nieve |
| `debt_paid` | Una deuda queda en `status = paid` |

---

### `user_gamification_stats`
Totales acumulados — se actualiza en cada `INSERT` en `gamification_events`.

| Campo | Qué hace aquí |
|-------|---------------|
| `total_points` | Suma de todos los eventos activos |
| `level` | Calculado desde `total_points` según tabla en `app_config` |

---

### `user_score_history`
Historial **personal** de puntaje — no hay rankings públicos en MVP.

| Campo | Qué hace aquí |
|-------|---------------|
| `period_start/end` | Semana o mes del snapshot |
| `points` / `level` | Valores del período para mostrar evolución |

---

### `recommendation_events`
Log de recomendaciones contextuales mostradas en el home.

| Campo | Qué hace aquí |
|-------|---------------|
| `context` | `home` — pantalla donde se mostró |
| `rule_key` | Qué regla disparó la recomendación |
| `dismissed_at` / `actioned_at` | Mide efectividad de la recomendación |

---

## Queries principales del dashboard

```sql
-- Balance del mes
SELECT
  SUM(CASE WHEN movement_type='income' THEN amount ELSE 0 END) AS ingresos,
  SUM(CASE WHEN movement_type='expense' THEN amount ELSE 0 END) AS gastos
FROM transactions
WHERE user_id = ? AND occurred_on BETWEEN ? AND ? AND deleted_at IS NULL;

-- Gasto por categoría (gráfico de fugas)
SELECT c.name, SUM(t.amount) AS total
FROM transactions t JOIN categories c ON t.category_id = c.id
WHERE t.user_id = ? AND t.movement_type = 'expense'
  AND t.occurred_on BETWEEN ? AND ? AND t.deleted_at IS NULL
GROUP BY c.name ORDER BY total DESC;

-- Cumplimiento de presupuesto por categoría
SELECT bl.category_id, bl.planned_amount,
       COALESCE(SUM(t.amount), 0) AS gastado
FROM budget_lines bl
LEFT JOIN transactions t ON t.category_id = bl.category_id
  AND t.user_id = ? AND t.occurred_on BETWEEN ? AND ?
  AND t.movement_type = 'expense' AND t.deleted_at IS NULL
WHERE bl.budget_period_id = ?
GROUP BY bl.category_id, bl.planned_amount;

-- Próximos vencimientos
SELECT title, amount, due_date, traffic_light_state
FROM bills_payable
WHERE user_id = ? AND status = 'pending'
ORDER BY due_date ASC LIMIT 5;
```

---

## Índices críticos

| Tabla | Índice | Motivo |
|-------|--------|--------|
| `transactions` | `(user_id, occurred_on DESC)` | Balance y gráficos del período |
| `transactions` | `(user_id, category_id)` | Desglose por categoría |
| `financial_health_snapshots` | `(user_id, snapshot_date DESC)` | Semáforo más reciente |
| `gamification_events` | `(user_id, created_at DESC)` | Logros recientes |
| `bills_payable` | `(user_id, due_date ASC)` | Próximos vencimientos |
