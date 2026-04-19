# Casos de Uso — Módulo 3: Home, Seguimiento y Motivación

**Tablas involucradas:** `financial_health_snapshots`, `gamification_events`, `user_gamification_stats`, `user_score_history`, `recommendation_events`, `gamification_rules`, `transactions`, `budget_lines`, `debts`, `bills_payable`, `user_goals`

---

## Actores

| Actor | Descripción |
|-------|-------------|
| **Usuario** | Visualiza su estado financiero diario |
| **Sistema (job diario)** | Genera snapshots del semáforo y score |
| **Sistema (evento)** | Otorga puntos al detectar acciones del usuario |

---

## UC-01: Ver dashboard del Home

**Actor:** Usuario
**Precondición:** Usuario autenticado, al menos 1 transacción o deuda registrada

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Abre la app → pantalla Home
    FE->>BE: GET /home/summary
    BE->>DB: SELECT * FROM financial_health_snapshots\nWHERE user_id=$1\nORDER BY snapshot_date DESC LIMIT 1
    DB-->>BE: snapshot { traffic_light, score, payload }

    par Consultas en paralelo
        BE->>DB: SELECT SUM(amount) as ingreso,\n  SUM(egreso) as egreso\nFROM transactions\nWHERE user_id=$1\nAND date >= date_trunc('month', NOW())
    and
        BE->>DB: SELECT b.category_id,\n  b.planned_amount,\n  COALESCE(SUM(t.amount),0) as spent\nFROM budget_lines b\nLEFT JOIN transactions t ON ...\nWHERE b.user_id=$1 AND b.period_id = current_period\nGROUP BY b.id
    and
        BE->>DB: SELECT SUM(current_balance) as total_debt\nFROM debts\nWHERE user_id=$1 AND status='active'
    and
        BE->>DB: SELECT * FROM bills_payable\nWHERE user_id=$1\nAND status='pending'\nAND due_date <= NOW()+INTERVAL '7 days'\nORDER BY due_date ASC LIMIT 3
    end

    DB-->>BE: balance, budget_compliance, total_debt, upcoming_bills
    BE->>BE: Arma resumen del mes
    BE-->>FE: 200 {\n  traffic_light: 'yellow',\n  balance_month: { ingreso, egreso, capacidad_ahorro },\n  budget: [{ category, pct_used }],\n  total_debt,\n  upcoming_bills: [...]\n}
    FE->>U: Renderiza dashboard con semáforo, balance,\ngráficos y próximos vencimientos
```

---

## UC-02: Calcular y actualizar semáforo financiero (job diario)

**Actor:** Sistema (cron job — corre diariamente a las 00:01)
**Precondición:** Existen usuarios con transacciones del mes actual

```mermaid
flowchart TD
    CRON([Job diario 00:01]) --> USERS[Obtiene lista de user_ids activos]
    USERS --> LOOP{Por cada usuario}

    LOOP --> Q1[Calcular budget_used_pct\nSUM egreso / SUM presupuesto del mes]
    LOOP --> Q2[Detectar pagos vencidos\nbills_payable WHERE status='overdue']
    LOOP --> Q3[Calcular capacidad de ahorro\ningreso - egreso del mes]

    Q1 --> CRITERIA{Aplicar criterios\nde app_config}
    Q2 --> CRITERIA
    Q3 --> CRITERIA

    CRITERIA --> |presupuesto < 80%\nAND sin vencidos\nAND deuda estable| GREEN[traffic_light = 'green']
    CRITERIA --> |presupuesto 80-100%\nOR pago próximo ≤ 3 días| YELLOW[traffic_light = 'yellow']
    CRITERIA --> |presupuesto > 100%\nOR pago vencido| RED[traffic_light = 'red']

    GREEN --> SCORE[Calcular score 0-100]
    YELLOW --> SCORE
    RED --> SCORE

    SCORE --> |score >= score_anterior + 5| BADGE[INSERT gamification_events\nevent_type='traffic_light_improved']
    SCORE --> INSERT_SNAP[INSERT financial_health_snapshots\ntraffic_light, score, payload JSON]
    BADGE --> INSERT_SNAP
    INSERT_SNAP --> LOOP
```

### Estructura del `payload` del snapshot

```json
{
  "budget_used_pct": 73.5,
  "total_debt": 4500000,
  "active_goals": 2,
  "payments_overdue": 0,
  "savings_capacity": 280000,
  "top_expense_category": "Hogar",
  "alerts_active": ["budget_threshold"]
}
```

---

## UC-03: Otorgar puntos de gamificación

**Actor:** Sistema (evento disparado por acciones del usuario)
**Precondición:** Módulo de gamificación activo (`app_config.gamification.enabled = true`)

```mermaid
sequenceDiagram
    participant BE as Backend
    participant DB as PostgreSQL

    Note over BE,DB: Este flujo se ejecuta internamente\ncuando ocurre una acción del usuario

    BE->>DB: SELECT points, label FROM gamification_rules\nWHERE event_type=$1 AND is_active=true
    DB-->>BE: { points: 20, label: "Pagaste a tiempo" }

    alt Regla activa y tiene puntos
        BE->>DB: INSERT INTO gamification_events\n(user_id, event_type, points_earned, reference_id)
        BE->>DB: UPDATE user_gamification_stats\nSET total_points = total_points + $1,\n    level = CASE WHEN total_points+$1 >= threshold THEN level+1 ELSE level END\nWHERE user_id=$2
        BE->>DB: SELECT level_thresholds FROM app_config\nWHERE key='gamification.level_thresholds'
        DB-->>BE: [0, 100, 300, 600, 1000]
        BE->>BE: ¿Subió de nivel?
        alt Nuevo nivel alcanzado
            BE->>DB: INSERT INTO notification_queue\n(user_id, channel='in_app',\npayload={title:'¡Subiste de nivel!', body:'Nivel X alcanzado'})
        end
    end
```

### Eventos configurables y cuándo se disparan

| `event_type` | `points` | Cuándo se dispara en el backend |
|-------------|---------|--------------------------------|
| `register_transaction` | 5 | Después de `POST /transactions` exitoso |
| `pay_on_time` | 20 | Al marcar `bills_payable` como `paid` ANTES de `due_date` |
| `stay_under_budget` | 30 | Job mensual detecta que todos los budget_lines < 100% |
| `register_debt` | 10 | Después de `POST /debts` exitoso |
| `debt_paid` | 50 | Al cambiar `debts.status = 'paid'` |
| `complete_onboarding` | 25 | Al completar todos los flags de `onboarding_state` |

---

## UC-04: Mostrar recomendación contextual

**Actor:** Usuario (al abrir cualquier pantalla)
**Precondición:** Existen reglas en `app_config.recommendation.rules`

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Abre pantalla "Presupuesto"
    FE->>BE: GET /recommendations?context=budget
    BE->>DB: SELECT payload FROM app_config WHERE key='recommendation.rules'
    DB-->>BE: { budget_80pct: { trigger, text, action }, ... }

    BE->>DB: Consulta estado del usuario para evaluar reglas:\n- budget_used_pct por categoría\n- días hasta próximo vencimiento\n- días desde último pago de deuda
    DB-->>BE: datos del usuario

    BE->>BE: Evalúa cada regla del contexto 'budget'
    BE->>DB: SELECT rule_key FROM recommendation_events\nWHERE user_id=$1\nAND context='budget'\nAND shown_at >= NOW() - INTERVAL '1 day'
    DB-->>BE: ['budget_80pct'] ← ya mostrada hoy

    BE->>BE: Filtra reglas ya mostradas hoy\nSelecciona la de mayor prioridad restante
    alt Hay recomendación nueva
        BE->>DB: INSERT INTO recommendation_events\n(user_id, context, rule_key, payload, shown_at=NOW())
        DB-->>BE: recommendation_event { id }
        BE-->>FE: 200 { recommendation: { text, action_label, action_deep_link, event_id } }
        FE->>U: Muestra banner de recomendación
    else No hay recomendación nueva para mostrar
        BE-->>FE: 200 { recommendation: null }
    end

    U->>FE: Hace click en la acción de la recomendación
    FE->>BE: PATCH /recommendations/:id { actioned_at: now() }
    BE->>DB: UPDATE recommendation_events SET actioned_at=NOW() WHERE id=$1

    U->>FE: Descarta la recomendación (X)
    FE->>BE: PATCH /recommendations/:id { dismissed_at: now() }
    BE->>DB: UPDATE recommendation_events SET dismissed_at=NOW() WHERE id=$1
```

### Regla de no-repetición

```mermaid
flowchart TD
    NEW_REC[Nueva visita a pantalla] --> CHECK[Consulta recommendation_events\nWHERE shown_at >= hace 24h\nAND context = pantalla_actual]
    CHECK --> |Regla A ya mostrada hoy| SKIP_A[Omite regla A]
    CHECK --> |Regla B no mostrada| SHOW_B[Muestra regla B]
    SHOW_B --> INSERT[INSERT recommendation_events]
    SKIP_A --> NEXT[Evalúa siguiente regla]
```

---

## UC-05: Ver historial de score personal

**Actor:** Usuario
**Precondición:** Al menos 1 mes con snapshot generado

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Abre sección "Mi progreso"
    FE->>BE: GET /home/score-history?months=6
    BE->>DB: SELECT period_start, score, traffic_light\nFROM user_score_history\nWHERE user_id=$1\nORDER BY period_start DESC\nLIMIT 6
    DB-->>BE: historial de 6 meses
    BE->>DB: SELECT total_points, level, badges_earned\nFROM user_gamification_stats WHERE user_id=$1
    DB-->>BE: stats actuales
    BE-->>FE: 200 {\n  current: { points, level },\n  history: [{ period, score, traffic_light }]\n}
    FE->>U: Gráfico de línea con evolución del score\n+ nivel y puntos actuales
```

---

## UC-06: Ver gráfico de gastos por categoría

**Actor:** Usuario
**Precondición:** Al menos 1 transacción del mes actual

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Selecciona período en el home (Mes actual)
    FE->>BE: GET /home/expense-breakdown?year=2026&month=4
    BE->>DB: SELECT c.name, c.color, SUM(t.amount) as total\nFROM transactions t\nJOIN categories c ON t.category_id = c.id\nWHERE t.user_id=$1\nAND t.movement_type='expense'\nAND t.flow_type != 'transfer'\nAND DATE_TRUNC('month', t.date) = '2026-04-01'\nGROUP BY c.id\nORDER BY total DESC
    DB-->>BE: [{ name:'Hogar', color:'#4A90D9', total:320000 }, ...]
    BE->>BE: Calcula % de cada categoría sobre total
    BE-->>FE: 200 { categories: [{name, color, total, pct}], total_egreso }
    FE->>U: Renderiza gráfico de dona con colores por categoría
```

---

## Diagrama de relación entre tablas — M3

```mermaid
erDiagram
    financial_health_snapshots {
        uuid id PK
        uuid user_id FK
        date snapshot_date
        varchar traffic_light
        int score
        jsonb payload
    }
    gamification_events {
        uuid id PK
        uuid user_id FK
        varchar event_type
        int points_earned
        uuid reference_id
    }
    user_gamification_stats {
        uuid id PK
        uuid user_id FK
        int total_points
        int level
    }
    user_score_history {
        uuid id PK
        uuid user_id FK
        date period_start
        date period_end
        int score
        varchar traffic_light
    }
    recommendation_events {
        uuid id PK
        uuid user_id FK
        varchar context
        varchar rule_key
        jsonb payload
        timestamp shown_at
        timestamp dismissed_at
        timestamp actioned_at
    }
    gamification_rules {
        uuid id PK
        varchar event_type UK
        int points
        text label
        boolean is_active
    }

    financial_health_snapshots }o--|| users : "pertenece a"
    gamification_events }o--|| users : "registra acción"
    user_gamification_stats ||--|| users : "acumula"
    user_score_history }o--|| users : "historial"
    recommendation_events }o--|| users : "mostrada a"
    gamification_events }o--|| gamification_rules : "usa regla"
```
