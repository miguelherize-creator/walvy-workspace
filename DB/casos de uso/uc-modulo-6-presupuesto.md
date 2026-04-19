# Casos de Uso — Módulo 6: Presupuestos

**Tablas involucradas:** `budget_periods`, `budget_lines`, `categories`, `subcategories`, `ant_expense_rules`, `transactions`, `app_config`

---

## Actores

| Actor | Descripción |
|-------|-------------|
| **Usuario** | Crea y gestiona su presupuesto mensual |
| **Sistema (job diario)** | Recalcula cumplimiento y dispara alertas de sobreconsumo |
| **Sistema (M4)** | Sugiere presupuesto basado en cartola importada |

---

## UC-01: Crear período de presupuesto mensual

**Actor:** Usuario
**Precondición:** Usuario con perfil financiero configurado

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Abre sección "Presupuesto" (primer acceso del mes)
    FE->>BE: GET /budget/current
    BE->>DB: SELECT * FROM budget_periods\nWHERE user_id=$1\nAND year=EXTRACT(YEAR FROM NOW())\nAND month=EXTRACT(MONTH FROM NOW())
    DB-->>BE: (vacío — no existe período aún)

    BE->>BE: Genera período automáticamente
    BE->>DB: INSERT INTO budget_periods (user_id, year, month, currency='CLP')
    DB-->>BE: period { id }

    BE->>DB: SELECT * FROM categories WHERE is_system=true ORDER BY name
    DB-->>BE: categorías del sistema

    alt Usuario tiene cartola importada del mes anterior
        BE->>DB: SELECT category_id, SUM(amount) as avg_spend\nFROM transactions\nWHERE user_id=$1\nAND date >= NOW()-INTERVAL '3 months'\nGROUP BY category_id
        DB-->>BE: promedios por categoría
        BE->>BE: suggested_by_app=true, planned_amount=promedio*1.1
    else No tiene historial
        BE->>DB: SELECT monthly_income FROM user_financial_profile WHERE user_id=$1
        DB-->>BE: { monthly_income }
        BE->>BE: Aplica guía de producto (50/30/20 adaptada)
    end

    BE->>DB: INSERT INTO budget_lines (period_id, user_id, category_id, planned_amount, suggested_by_app=true)\nPOR CADA CATEGORÍA DEL SISTEMA
    DB-->>BE: lines creadas
    BE-->>FE: 200 { period, lines: [{ category, planned_amount, suggested_by_app }] }
    FE->>U: Muestra presupuesto sugerido con opción de ajustar montos
```

### Lógica de sugerencia de presupuesto

```mermaid
flowchart TD
    START([Nuevo período]) --> CHECK{¿Tiene historial\nde transacciones?}
    CHECK --> |≥3 meses| HISTORY[Promedio de gasto\npor categoría × 1.1]
    CHECK --> |Sin historial| INCOME[Lee monthly_income\nde user_financial_profile]
    INCOME --> RULE5030[Aplica regla 50/30/20:\n50% gastos fijos\n30% variables\n20% ahorro/deuda]
    HISTORY --> INSERT[INSERT budget_lines\nsuggested_by_app=true]
    RULE5030 --> INSERT
    INSERT --> USER[Usuario puede ajustar\ncada monto manualmente]
    USER --> |Ajusta| UPDATE[UPDATE budget_lines\nsuggested_by_app=false]
```

---

## UC-02: Ajustar líneas de presupuesto

**Actor:** Usuario
**Precondición:** Período de presupuesto activo

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    FE->>BE: GET /budget/current/lines
    BE->>DB: SELECT bl.*, c.name, c.color, c.icon,\n  COALESCE(SUM(t.amount),0) as spent\nFROM budget_lines bl\nJOIN categories c ON bl.category_id=c.id\nLEFT JOIN transactions t ON\n  t.category_id=bl.category_id\n  AND t.user_id=bl.user_id\n  AND DATE_TRUNC('month', t.date) = period_start\n  AND t.movement_type='expense'\n  AND t.flow_type != 'transfer'\nGROUP BY bl.id, c.id
    DB-->>BE: líneas con gasto real actualizado
    BE-->>FE: 200 { lines: [{ category, planned, spent, pct_used, status }] }
    FE->>U: Muestra lista de categorías con barras de progreso

    U->>FE: Cambia presupuesto de "Entretenimiento" de $80.000 a $60.000
    FE->>BE: PATCH /budget/lines/:id { planned_amount: 60000 }
    BE->>DB: UPDATE budget_lines\nSET planned_amount=60000,\n    suggested_by_app=false\nWHERE id=$1 AND user_id=$2
    DB-->>BE: OK
    BE-->>FE: 200 { updated_line }
    FE->>U: Actualiza barra de progreso instantáneamente

    U->>FE: Agrega subcategoría personalizada "Netflix" bajo "Entretenimiento"
    FE->>BE: POST /categories/subcategories { name: 'Netflix', category_id: 'entret-id', color: '#E50914' }
    BE->>DB: SELECT COUNT(*) FROM subcategories\nWHERE user_id=$1 AND category_id=$2 AND is_active=true
    DB-->>BE: { count: 3 }
    alt count < 5 (límite del MVP)
        BE->>DB: INSERT INTO subcategories (user_id, category_id, name, color, is_active=true)
        DB-->>BE: subcategory { id }
        BE-->>FE: 201 { subcategory }
    else count >= 5
        BE-->>FE: 422 "Límite de 5 subcategorías activas por categoría"
    end
```

---

## UC-03: Ver cumplimiento de presupuesto en tiempo real

**Actor:** Usuario
**Precondición:** Período activo con al menos 1 transacción

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Abre pantalla "Presupuesto → mes actual"
    FE->>BE: GET /budget/current/compliance
    BE->>DB: SELECT\n  bl.category_id,\n  c.name,\n  c.color,\n  bl.planned_amount,\n  COALESCE(SUM(t.amount),0) as spent,\n  ROUND(COALESCE(SUM(t.amount),0)/bl.planned_amount*100, 1) as pct_used\nFROM budget_lines bl\nJOIN categories c ON bl.category_id=c.id\nLEFT JOIN transactions t ON\n  t.category_id=bl.category_id\n  AND t.user_id=bl.user_id\n  AND DATE_TRUNC('month',t.date) = period_start\n  AND t.movement_type='expense'\n  AND t.flow_type != 'transfer'\nWHERE bl.user_id=$1 AND bl.period_id=$2\nGROUP BY bl.id, c.id\nORDER BY pct_used DESC
    DB-->>BE: compliance data
    BE->>DB: SELECT value FROM app_config\nWHERE key IN ('budget.threshold.yellow_pct', 'budget.threshold.red_pct')
    DB-->>BE: { yellow: 80, red: 100 }
    BE->>BE: Clasifica cada línea:\n- pct_used < 80 → 'green'\n- pct_used 80-100 → 'yellow'\n- pct_used > 100 → 'red'
    BE-->>FE: 200 { lines: [...], thresholds: { yellow: 80, red: 100 } }
    FE->>U: Muestra barras de progreso con colores\n🟢 Alimentación: 65% ($130k de $200k)\n🟡 Entretenimiento: 82% ($49k de $60k)\n🔴 Salud: 108% ($108k de $100k)
```

---

## UC-04: Recibir alerta de sobreconsumo

**Actor:** Sistema (job diario) + Usuario (recibe notificación)
**Precondición:** Una categoría supera el umbral configurado

```mermaid
sequenceDiagram
    participant JOB as Job Diario (00:01)
    participant DB as PostgreSQL
    participant NOTIF as Notification Worker

    JOB->>DB: Para cada usuario con budget_period activo:\nSELECT bl.id, bl.user_id, c.name,\n  bl.planned_amount, SUM(t.amount) as spent,\n  ROUND(SUM(t.amount)/bl.planned_amount*100,1) as pct\nFROM budget_lines bl\nJOIN transactions t ...\nGROUP BY bl.id
    DB-->>JOB: líneas por usuario

    JOB->>DB: SELECT value FROM app_config WHERE key='budget.threshold.yellow_pct'
    DB-->>JOB: 80

    loop Por cada budget_line
        JOB->>JOB: ¿pct >= 80 Y no notificado en últimas 24h?
        alt Umbral superado y sin notificación reciente
            JOB->>DB: SELECT is_active, channel FROM alert_preferences\nWHERE user_id=$1 AND alert_type='budget_threshold'
            DB-->>JOB: { is_active: true, channel: 'in_app' }
            JOB->>DB: INSERT INTO notification_queue (\n  user_id,\n  channel='in_app',\n  payload={"title":"Alerta de presupuesto",\n    "body":"Llevas el 82% en Entretenimiento",\n    "deepLink":"/(tabs)/budget"},\n  scheduled_for=NOW()\n)
        end
    end

    NOTIF->>DB: SELECT * FROM notification_queue\nWHERE sent_at IS NULL\nAND scheduled_for <= NOW()
    DB-->>NOTIF: notificaciones pendientes
    NOTIF->>NOTIF: Envía push/in-app por canal
    NOTIF->>DB: UPDATE notification_queue SET sent_at=NOW() WHERE id=$1
```

---

## UC-05: Detectar y reportar gasto hormiga

**Actor:** Sistema (al insertar transacción) + Usuario (ve el reporte)
**Precondición:** `ant_expense_rules` configurada (default max: 5.000 CLP)

```mermaid
sequenceDiagram
    participant BE as Backend
    participant DB as PostgreSQL

    Note over BE,DB: Al insertar cualquier transacción de egreso

    BE->>DB: SELECT max_amount FROM ant_expense_rules WHERE user_id=$1
    alt No tiene regla personalizada
        BE->>DB: SELECT value FROM app_config WHERE key='ant_expense.default_max'
        DB-->>BE: 5000
    end

    BE->>BE: ¿Es un gasto hormiga?\n- movement_type = 'expense'\n- flow_type ≠ 'transfer'\n- amount ≤ max_amount (5000 CLP)\n- subcategory no excluida

    alt Es gasto hormiga
        BE->>DB: UPDATE transactions SET is_ant_expense=true WHERE id=$1
    end

    Note over BE,DB: Vista de gastos hormiga del mes

    BE->>DB: SELECT\n  subcategory_id,\n  s.name as subcategory,\n  COUNT(*) as frequency,\n  SUM(amount) as total,\n  MIN(amount) as min_amount,\n  MAX(amount) as max_amount\nFROM transactions\nWHERE user_id=$1\nAND is_ant_expense=true\nAND DATE_TRUNC('month', date) = current_month\nGROUP BY subcategory_id, s.name\nORDER BY total DESC
    DB-->>BE: ranking de hormigas
    BE-->>FE: 200 { ant_expenses: [{ subcategory, frequency, total }], total_monthly }
```

---

## UC-06: Navegar a semana / día del presupuesto

**Actor:** Usuario
**Precondición:** Período mensual activo

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Selecciona vista "Semana actual"
    FE->>BE: GET /budget/weekly?week_start=2026-04-13
    BE->>DB: SELECT category_id, SUM(amount) as spent\nFROM transactions\nWHERE user_id=$1\nAND date BETWEEN $week_start AND $week_end\nAND movement_type='expense'\nAND flow_type != 'transfer'\nGROUP BY category_id
    DB-->>BE: gasto de la semana por categoría
    BE->>BE: Calcula meta semanal:\nplanned_amount / semanas_en_mes
    BE-->>FE: 200 { weekly: [{ category, week_spent, week_budget }] }
    FE->>U: Vista de semana con micro-barras de progreso
```

---

## Diagrama de relación entre tablas — M6

```mermaid
erDiagram
    budget_periods {
        uuid id PK
        uuid user_id FK
        int year
        int month
        varchar currency
    }
    budget_lines {
        uuid id PK
        uuid period_id FK
        uuid user_id FK
        uuid category_id FK
        numeric planned_amount
        numeric planned_min
        numeric planned_max
        boolean suggested_by_app
    }
    categories {
        uuid id PK
        uuid user_id FK
        varchar name
        varchar icon
        varchar color
        boolean is_system
    }
    subcategories {
        uuid id PK
        uuid category_id FK
        uuid user_id FK
        varchar name
        varchar color
        boolean is_active
    }
    ant_expense_rules {
        uuid id PK
        uuid user_id FK
        numeric max_amount
        text excluded_subcategories
    }
    transactions {
        uuid id PK
        uuid user_id FK
        uuid category_id FK
        uuid subcategory_id FK
        date date
        numeric amount
        varchar movement_type
        varchar flow_type
        boolean is_ant_expense
    }

    budget_periods }o--|| users : "período mensual"
    budget_lines }o--|| budget_periods : "líneas del período"
    budget_lines }o--|| categories : "para categoría"
    categories ||--o{ subcategories : "tiene subcategorías"
    transactions }o--|| categories : "clasificada en"
    transactions }o--o| subcategories : "subcategoría"
    ant_expense_rules ||--|| users : "regla por usuario"
```
