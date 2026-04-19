# Casos de Uso — Módulo 7: Pagos

**Tablas involucradas:** `bills_payable`, `recurring_payment_suggestions`, `notification_queue`, `transactions`, `alert_preferences`, `funding_sources`

---

## Actores

| Actor | Descripción |
|-------|-------------|
| **Usuario** | Registra y gestiona sus cuentas por pagar |
| **Sistema (job diario)** | Actualiza semáforos, genera recordatorios y detecta vencidos |
| **M4 (clasificación)** | Sugiere movimientos como cuentas por pagar |

---

## UC-01: Registrar cuenta por pagar

**Actor:** Usuario
**Precondición:** Usuario autenticado

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Llena formulario\n(título, monto, fecha de vencimiento,\nes recurrente?, cada cuántos días)
    FE->>BE: POST /bills {\n  title, amount, due_date,\n  is_recurring, recurrence_interval_days?,\n  funding_source_id?\n}
    BE->>BE: Calcula traffic_light_state inicial\nSegún due_date vs TODAY
    BE->>DB: INSERT INTO bills_payable (\n  user_id, title, amount, due_date,\n  status='pending',\n  is_recurring,\n  recurrence_interval_days,\n  traffic_light_state\n)
    DB-->>BE: bill { id }

    BE->>DB: SELECT is_active, channel FROM alert_preferences\nWHERE user_id=$1 AND alert_type='payment_due'
    DB-->>BE: [{ channel:'push', is_active:true }, { channel:'email', is_active:true }]

    BE->>DB: SELECT value FROM app_config WHERE key='payment_reminder.days_before'
    DB-->>BE: [7, 3, 1]

    BE->>DB: INSERT INTO notification_queue (\n  user_id, channel, bills_payable_id,\n  payload, scheduled_for=due_date-7days\n),\n(\n  user_id, channel, bills_payable_id,\n  payload, scheduled_for=due_date-3days\n),\n(\n  user_id, channel, bills_payable_id,\n  payload, scheduled_for=due_date-1day\n)
    Note over BE,DB: 3 recordatorios × 2 canales = hasta 6 registros

    BE-->>FE: 201 { bill, reminders_scheduled: 6 }
    FE->>U: Muestra cuenta registrada con semáforo inicial
```

### Cálculo del `traffic_light_state`

```mermaid
flowchart TD
    TODAY([Fecha actual]) --> CALC{due_date vs TODAY}
    CALC --> |due_date > TODAY + 7 días| GREEN[🟢 green]
    CALC --> |due_date entre TODAY+1 y TODAY+6| YELLOW[🟡 yellow]
    CALC --> |due_date = TODAY o ya pasó| RED[🔴 red]

    style GREEN fill:#d4edda
    style YELLOW fill:#fff3cd
    style RED fill:#f8d7da
```

---

## UC-02: Marcar cuenta como pagada

**Actor:** Usuario
**Precondición:** `bills_payable.status = 'pending'`

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Hace swipe o click en "Marcar como pagada"
    FE->>BE: PATCH /bills/:id/pay { paid_at?, linked_transaction_id? }
    BE->>DB: UPDATE bills_payable\nSET status='paid',\n    paid_at=NOW(),\n    linked_transaction_id=$2\nWHERE id=$1 AND user_id=$2

    BE->>DB: UPDATE notification_queue\nSET sent_at=NOW()\nWHERE bills_payable_id=$1\nAND sent_at IS NULL
    Note over BE,DB: Cancela recordatorios pendientes

    BE->>BE: ¿Pagó antes del vencimiento?
    alt paid_at < due_date
        BE->>DB: INSERT INTO gamification_events\n(event_type='pay_on_time', points_earned=20)
        BE->>DB: UPDATE user_gamification_stats\nSET total_points=total_points+20
    end

    alt is_recurring = true
        BE->>BE: next_due_date = paid_at + recurrence_interval_days
        BE->>DB: INSERT INTO bills_payable (\n  user_id, title, amount,\n  due_date=next_due_date,\n  status='pending',\n  is_recurring=true,\n  recurrence_interval_days\n)
        BE->>DB: INSERT INTO notification_queue\n(nuevos recordatorios para siguiente instancia)
    end

    BE-->>FE: 200 { bill_updated, next_bill?, points_earned? }
    FE->>U: Marca como pagada con checkmark\nSi recurrente: muestra próxima fecha
```

---

## UC-03: Aceptar sugerencia de pago recurrente

**Actor:** Usuario
**Precondición:** El sistema detectó un pago recurrente (desde M4 clasificación o por patrón de transacciones)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    Note over BE,DB: El sistema detectó patrón recurrente
    BE->>DB: INSERT INTO recurring_payment_suggestions (\n  user_id,\n  source='movement_pattern',\n  suggested_payload={\n    title:'Netflix',\n    amount:9990,\n    due_date:'2026-05-05',\n    interval_days:30\n  },\n  status='pending_user_confirm'\n)

    U->>FE: Ve banner "Detectamos un pago recurrente: Netflix $9.990/mes"
    FE->>U: Opciones: "Agregar" | "Ignorar"

    U->>FE: Click "Agregar"
    FE->>BE: PATCH /recurring-suggestions/:id { status: 'accepted' }
    BE->>DB: UPDATE recurring_payment_suggestions\nSET status='accepted' WHERE id=$1
    BE->>DB: INSERT INTO bills_payable (\n  user_id,\n  title='Netflix',\n  amount=9990,\n  due_date='2026-05-05',\n  is_recurring=true,\n  recurrence_interval_days=30,\n  status='pending'\n)
    BE->>DB: INSERT INTO notification_queue (recordatorios automáticos)
    BE-->>FE: 200 { bill_created }
    FE->>U: "Netflix agregado a tus pagos"

    U->>FE: Click "Ignorar"
    FE->>BE: PATCH /recurring-suggestions/:id { status: 'dismissed' }
    BE->>DB: UPDATE recurring_payment_suggestions\nSET status='dismissed' WHERE id=$1
    BE-->>FE: 200
```

---

## UC-04: Job diario — actualizar semáforos y marcar vencidos

**Actor:** Sistema (cron job — corre a las 00:01 diariamente)

```mermaid
sequenceDiagram
    participant JOB as Job Diario (00:01)
    participant DB as PostgreSQL
    participant WORKER as Notification Worker

    JOB->>DB: UPDATE bills_payable\nSET traffic_light_state = CASE\n  WHEN due_date > NOW()+7 THEN 'green'\n  WHEN due_date BETWEEN NOW()+1 AND NOW()+6 THEN 'yellow'\n  ELSE 'red'\nEND\nWHERE user_id IN (activos) AND status='pending'

    JOB->>DB: UPDATE bills_payable\nSET status='overdue'\nWHERE due_date < NOW()\nAND status='pending'

    Note over JOB,DB: Procesamiento de notification_queue

    WORKER->>DB: SELECT nq.*, ap.channel\nFROM notification_queue nq\nJOIN alert_preferences ap ON\n  ap.user_id=nq.user_id AND ap.alert_type='payment_due'\nWHERE nq.sent_at IS NULL\nAND nq.scheduled_for <= NOW()

    DB-->>WORKER: notificaciones pendientes

    loop Por cada notificación
        WORKER->>DB: SELECT status FROM bills_payable WHERE id=$1
        alt bill ya fue pagada
            WORKER->>DB: UPDATE notification_queue SET sent_at=NOW()\n(cancelar sin enviar)
        else bill sigue pendiente
            WORKER->>WORKER: Envía push/email
            WORKER->>DB: UPDATE notification_queue SET sent_at=NOW()
        end
    end
```

---

## UC-05: Vincular pago con transacción importada

**Actor:** Usuario
**Precondición:** Existe `bills_payable` pendiente Y la cartola muestra el cargo correspondiente

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    FE->>BE: GET /bills?status=pending
    BE->>DB: SELECT * FROM bills_payable\nWHERE user_id=$1 AND status='pending'\nORDER BY due_date ASC
    DB-->>BE: lista de pagos pendientes
    BE-->>FE: bills
    FE->>U: Lista de cuentas pendientes

    U->>FE: Click en "Vincular transacción" en el bill "Aguas Andinas"
    FE->>BE: GET /transactions?description=aguas&amount_near=12500
    BE->>DB: SELECT * FROM transactions\nWHERE user_id=$1\nAND amount BETWEEN 11875 AND 13125\nAND date >= NOW()-INTERVAL '7 days'\nAND linked_bill_id IS NULL
    DB-->>BE: posibles transacciones coincidentes
    BE-->>FE: sugerencias de transacciones a vincular

    U->>FE: Selecciona la transacción correcta
    FE->>BE: PATCH /bills/:bill_id { linked_transaction_id: :tx_id }
    BE->>DB: UPDATE bills_payable\nSET linked_transaction_id=$1,\n    status='paid',\n    paid_at=(SELECT date FROM transactions WHERE id=$1)\nWHERE id=$2
    BE->>DB: UPDATE transactions SET linked_bill_id=$1 WHERE id=$2
    BE-->>FE: 200 { updated_bill }
    FE->>U: Pago vinculado y marcado como pagado
```

---

## Diagrama de relación entre tablas — M7

```mermaid
erDiagram
    bills_payable {
        uuid id PK
        uuid user_id FK
        varchar title
        numeric amount
        date due_date
        varchar status
        varchar traffic_light_state
        boolean is_recurring
        int recurrence_interval_days
        uuid linked_transaction_id FK
        timestamp paid_at
    }
    recurring_payment_suggestions {
        uuid id PK
        uuid user_id FK
        varchar source
        jsonb suggested_payload
        varchar status
    }
    notification_queue {
        uuid id PK
        uuid user_id FK
        uuid bills_payable_id FK
        varchar channel
        jsonb payload
        timestamp scheduled_for
        timestamp sent_at
    }
    alert_preferences {
        uuid user_id FK
        varchar alert_type
        varchar channel
        boolean is_active
        int cadence_days
    }
    transactions {
        uuid id PK
        uuid user_id FK
        numeric amount
        date date
    }

    bills_payable }o--|| users : "del usuario"
    bills_payable }o--o| transactions : "vinculado a"
    notification_queue }o--|| bills_payable : "recordatorio de"
    notification_queue }o--|| users : "para usuario"
    recurring_payment_suggestions }o--|| users : "sugerencia para"
    alert_preferences }o--|| users : "preferencias de"
```
