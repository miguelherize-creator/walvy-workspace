# Casos de Uso — Módulo 4: Motor de Deudas (Bola de Nieve)

**Tablas involucradas:** `debts`, `debt_schedules`, `debt_payments`, `debt_attachments`, `debt_snowball_plan`, `statement_imports`, `import_line_items`, `movement_classification_suggestions`, `transactions`, `funding_sources`

---

## Actores

| Actor | Descripción |
|-------|-------------|
| **Usuario** | Registra deudas, importa cartolas, clasifica movimientos |
| **Sistema (algoritmo)** | Calcula prioridades y el plan bola de nieve |
| **Sistema (job)** | Procesa archivos importados (pipeline async) |

---

## UC-01: Registrar deuda manualmente

**Actor:** Usuario
**Precondición:** Usuario autenticado, tiene al menos 1 deuda

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Llena formulario de deuda\n(nombre, saldo actual, pago mínimo, tasa interés, tipo)
    FE->>FE: Valida (current_balance > 0, minimum_payment > 0)
    FE->>BE: POST /debts {\n  name, debt_type, current_balance,\n  minimum_payment, apr, installments_remaining,\n  due_date, funding_source_id?\n}
    BE->>DB: INSERT INTO debts (\n  user_id, name, debt_type, current_balance,\n  minimum_payment, apr, installments_remaining,\n  due_date, status='active'\n)
    DB-->>BE: debt { id }
    BE->>BE: Recalcula plan bola de nieve completo
    BE->>DB: SELECT * FROM debts WHERE user_id=$1 AND status='active'\nORDER BY current_balance ASC
    DB-->>BE: todas las deudas activas ordenadas
    BE->>BE: Asigna snowball_priority (1=más urgente)
    BE->>DB: UPDATE debts SET snowball_priority=$1 WHERE id=$2\n(por cada deuda en el plan)
    BE->>DB: INSERT INTO debt_snowball_plan\n(user_id, ordered_debt_ids, extra_monthly_payment,\nestimated_completion, freed_capacity_projection)\nON CONFLICT (user_id) DO UPDATE SET ...
    BE->>DB: INSERT INTO gamification_events (event_type='register_debt', points_earned=10)
    BE->>DB: UPDATE user_gamification_stats SET total_points=total_points+10
    BE-->>FE: 201 { debt, snowball_plan }
    FE->>U: Muestra deuda agregada\ny plan actualizado
```

### Algoritmo Bola de Nieve (implementación)

```mermaid
flowchart TD
    START([Todas las deudas activas]) --> SORT[Ordenar por current_balance ASC\nMenor deuda = prioridad 1]
    SORT --> ASSIGN[Asignar snowball_priority\n1, 2, 3... N]

    ASSIGN --> CAPACITY[Leer estimated_payment_capacity\nde user_financial_profile]
    CAPACITY --> EXTRA[extra_monthly_payment =\ncapacity - SUM_ALL_minimums]

    EXTRA --> PLAN[Para deuda #1:\n  pago = minimum + extra\nPara deudas #2-N:\n  pago = solo minimum]

    PLAN --> SIMULATE[Simular mes a mes hasta\ncurrent_balance = 0]
    SIMULATE --> |Deuda #1 pagada| FREED[freed_minimum = minimum de #1\nSe suma al pago de #2]
    FREED --> SIMULATE2[Simular deuda #2\ncon nuevo pago aumentado]
    SIMULATE2 --> STORE[Guardar en debt_snowball_plan:\n- ordered_debt_ids\n- estimated_completion array\n- freed_capacity_projection]

    style EXTRA fill:#fff3cd
    style FREED fill:#d4edda
```

---

## UC-02: Importar cartola bancaria

**Actor:** Usuario
**Precondición:** Usuario tiene archivo PDF o CSV de su banco

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL
    participant Parser as Parser Service (async)

    U->>FE: Selecciona archivo de cartola (PDF/CSV)
    FE->>BE: POST /imports/statement (multipart: file, institution_id)
    BE->>DB: INSERT INTO statement_imports (\n  user_id, institution, file_name,\n  status='pending', file_size\n)
    DB-->>BE: import { id }
    BE-->>FE: 202 { import_id, status: 'pending' }
    FE->>U: Muestra "Procesando tu cartola..."

    BE->>Parser: Encola procesamiento async del archivo

    Parser->>DB: UPDATE statement_imports SET status='processing' WHERE id=$1
    Parser->>Parser: Parsea PDF/CSV → extrae filas de movimientos
    Parser->>DB: INSERT INTO import_line_items (import_id, date, description, amount, type)\nPOR CADA MOVIMIENTO DEL ARCHIVO
    Parser->>Parser: Aplica reglas de clasificación automática\n(keywords en description)
    Parser->>DB: INSERT INTO movement_classification_suggestions\n(user_id, import_line_item_id, suggested_target, confidence, rule_key)\nPARA MOVIMIENTOS QUE COINCIDEN CON REGLAS
    Parser->>DB: UPDATE statement_imports SET\nstatus='parsed', parsed_at=NOW(),\ntotal_rows, matched_rows WHERE id=$1

    FE->>BE: GET /imports/:id/status (polling o websocket)
    BE->>DB: SELECT status FROM statement_imports WHERE id=$1
    DB-->>BE: { status: 'parsed' }
    BE-->>FE: { status: 'parsed', total: 45, matched: 12 }
    FE->>U: "Importación lista: 45 movimientos, 12 clasificados automáticamente"
    FE->>U: Redirige a pantalla de revisión
```

### Estados del pipeline de importación

```mermaid
stateDiagram-v2
    [*] --> pending : Usuario sube archivo
    pending --> processing : Job inicia procesamiento
    processing --> parsed : Parsing exitoso
    processing --> failed : Error de formato/lectura
    parsed --> [*] : Usuario revisa y acepta movimientos
    failed --> [*] : Usuario reintenta con otro archivo
```

---

## UC-03: Revisar y clasificar movimientos importados

**Actor:** Usuario
**Precondición:** `statement_imports.status = 'parsed'`

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    FE->>BE: GET /imports/:id/review
    BE->>DB: SELECT ili.*, mcs.suggested_target, mcs.confidence\nFROM import_line_items ili\nLEFT JOIN movement_classification_suggestions mcs ON mcs.import_line_item_id=ili.id\nWHERE ili.import_id=$1
    DB-->>BE: movimientos con sugerencias
    BE-->>FE: lista de movimientos con sugerencias de clasificación
    FE->>U: Lista de movimientos:\n✅ = clasificado automáticamente\n⚠️ = sugerencia con baja confianza\n❓ = sin clasificar

    U->>FE: Acepta sugerencia "CARGO CUOTA" → debt_plan
    FE->>BE: PATCH /suggestions/:id { decision: 'accepted' }
    BE->>DB: UPDATE movement_classification_suggestions\nSET user_decision='accepted', decided_at=NOW() WHERE id=$1
    BE->>DB: INSERT INTO transactions\n(user_id, date, description, amount, movement_type,\nflow_type, category_id, import_id)
    DB-->>BE: OK

    U->>FE: Corrige sugerencia "TRASPASO" de debt_plan a bills_payable
    FE->>BE: PATCH /suggestions/:id { decision: 'corrected', corrected_target: 'bills_payable' }
    BE->>DB: UPDATE movement_classification_suggestions\nSET user_decision='corrected',\ncorrected_target='bills_payable',\ndecided_at=NOW() WHERE id=$1
    BE->>DB: INSERT INTO bills_payable\n(user_id, title, amount, due_date)

    U->>FE: Ignora un movimiento (transferencia personal)
    FE->>BE: PATCH /suggestions/:id { decision: 'ignored' }
    BE->>DB: UPDATE movement_classification_suggestions\nSET user_decision='ignored', decided_at=NOW() WHERE id=$1
```

### Reglas de clasificación automática (por keyword en descripción)

| Keyword en `description` | `suggested_target` | `confidence` |
|--------------------------|-------------------|-------------|
| "CUOTA", "CUOTAS" | `debt_plan` | 0.9 |
| "CREDITO CONSUMO" | `debt_plan` | 0.85 |
| "LINEA DE CREDITO" | `debt_plan` | 0.85 |
| "INTERES", "MORA" | `debt_plan` | 0.8 |
| "ARRIENDO" | `bills_payable` | 0.9 |
| "DIVIDENDO" | `bills_payable` | 0.85 |
| "NETFLIX", "SPOTIFY" | `bills_payable` | 0.8 |
| Glosa repetida ≥3 veces | `bills_payable` | 0.7 |

---

## UC-04: Ver plan Bola de Nieve

**Actor:** Usuario
**Precondición:** Al menos 2 deudas activas registradas

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Abre sección "Plan de deudas"
    FE->>BE: GET /debts/snowball-plan
    BE->>DB: SELECT * FROM debt_snowball_plan WHERE user_id=$1
    DB-->>BE: plan { ordered_debt_ids, estimated_completion, freed_capacity_projection }
    BE->>DB: SELECT d.*, d.snowball_priority\nFROM debts d\nWHERE d.user_id=$1 AND d.status='active'\nORDER BY d.snowball_priority ASC
    DB-->>BE: deudas ordenadas
    BE-->>FE: 200 {\n  debts_ordered: [\n    { name, current_balance, minimum_payment, months_to_payoff, estimated_date },\n    ...\n  ],\n  total_debt,\n  total_months,\n  freed_capacity_at_end\n}
    FE->>U: Muestra lista priorizada:\n🥇 Tarjeta Ripley ($180.000 — 8 meses)\n🥈 Crédito de Consumo ($850.000 — 24 meses)\nAl pagar #1 liberas $32.000/mes para #2
```

---

## UC-05: Simular pago extra (Bola de Nieve mejorada)

**Actor:** Usuario
**Precondición:** Plan de deudas activo

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Ingresa "¿Qué pasa si pago $50.000 extra/mes?"
    FE->>BE: POST /debts/simulate {\n  extra_monthly_payment: 50000,\n  lump_sum_payment: 0\n}
    BE->>DB: SELECT * FROM debts WHERE user_id=$1 AND status='active'\nORDER BY current_balance ASC
    DB-->>BE: deudas actuales
    BE->>BE: Ejecuta simulación con extra_monthly_payment=50000\nCalcula nueva fecha estimada de salida total
    BE-->>FE: 200 {\n  without_extra: { months: 36, total_interest: 380000 },\n  with_extra: { months: 24, total_interest: 210000 },\n  savings: { months_saved: 12, interest_saved: 170000 }\n}
    FE->>U: "Pagando $50.000 extra ahorras 12 meses y $170.000 en intereses"

    U->>FE: Decide guardar este escenario como plan activo
    FE->>BE: PATCH /debts/snowball-plan {\n  extra_monthly_payment: 50000,\n  lump_sum_payment: 0\n}
    BE->>DB: UPDATE debt_snowball_plan\nSET extra_monthly_payment=50000,\nlump_sum_payment=0,\nestimated_completion=updated_array\nWHERE user_id=$1
    DB-->>BE: OK
    BE-->>FE: 200 { updated_plan }
```

---

## UC-06: Registrar pago de deuda

**Actor:** Usuario
**Precondición:** Deuda activa en el plan

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Marca pago de deuda\n(ej: $180.000 abono a Tarjeta Ripley)
    FE->>BE: POST /debts/:id/payments { amount, paid_at, funding_source_id }
    BE->>DB: INSERT INTO debt_payments (debt_id, amount, paid_at, funding_source_id)
    BE->>DB: UPDATE debts\nSET current_balance = current_balance - $1,\n    installments_remaining = installments_remaining - 1\nWHERE id=$2
    DB-->>BE: new_balance

    alt Deuda completamente pagada (new_balance <= 0)
        BE->>DB: UPDATE debts SET status='paid', paid_at=NOW() WHERE id=$1
        BE->>DB: INSERT INTO gamification_events (event_type='debt_paid', points=50)
        BE->>DB: UPDATE user_gamification_stats SET total_points=total_points+50
        BE->>BE: Recalcula plan bola de nieve\n(deuda eliminada → surplus redistribuido)
        BE->>DB: UPDATE debts SET snowball_priority (rebased)\nWHERE user_id=$1 AND status='active'
        BE->>DB: UPDATE debt_snowball_plan SET ...\nWHERE user_id=$1
    end

    BE->>DB: INSERT INTO gamification_events (event_type='register_transaction', points=5)
    BE-->>FE: 200 { payment, updated_debt, snowball_plan? }
    FE->>U: Muestra nuevo saldo de la deuda\nSi fue pagada: ¡confetti! "¡Deuda saldada!"
```

---

## Diagrama de relación entre tablas — M4

```mermaid
erDiagram
    debts {
        uuid id PK
        uuid user_id FK
        varchar name
        varchar debt_type
        numeric current_balance
        numeric minimum_payment
        numeric apr
        int installments_remaining
        int snowball_priority
        varchar status
    }
    debt_payments {
        uuid id PK
        uuid debt_id FK
        numeric amount
        timestamp paid_at
        uuid funding_source_id FK
    }
    debt_snowball_plan {
        uuid id PK
        uuid user_id FK
        jsonb ordered_debt_ids
        numeric extra_monthly_payment
        numeric lump_sum_payment
        jsonb estimated_completion
        numeric freed_capacity_projection
    }
    statement_imports {
        uuid id PK
        uuid user_id FK
        varchar institution
        varchar status
        int total_rows
        int matched_rows
    }
    import_line_items {
        uuid id PK
        uuid import_id FK
        date date
        text description
        numeric amount
        varchar type
    }
    movement_classification_suggestions {
        uuid id PK
        uuid user_id FK
        uuid import_line_item_id FK
        varchar suggested_target
        numeric confidence
        varchar user_decision
        varchar corrected_target
    }

    debts }o--|| users : "pertenece a"
    debt_payments }o--|| debts : "abona a"
    debt_snowball_plan ||--|| users : "plan único"
    statement_imports }o--|| users : "importa"
    import_line_items }o--|| statement_imports : "filas de"
    movement_classification_suggestions }o--|| import_line_items : "clasifica"
    movement_classification_suggestions }o--|| users : "para usuario"
```
