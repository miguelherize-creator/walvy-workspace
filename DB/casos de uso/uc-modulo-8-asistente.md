# Casos de Uso — Módulo 8: Asistente IA y Soporte

**Tablas involucradas:** `ai_conversations`, `ai_messages`, `ai_tool_invocations`, `ai_context_snapshots`, `recommendation_events`, `faq_articles`, `financial_health_snapshots`

---

## Actores

| Actor | Descripción |
|-------|-------------|
| **Usuario** | Inicia conversaciones, hace preguntas financieras |
| **LLM externo** | Genera respuestas basadas en contexto y herramientas |
| **Sistema** | Captura snapshot financiero al iniciar cada sesión |

---

## UC-01: Iniciar una nueva conversación

**Actor:** Usuario
**Precondición:** Usuario autenticado

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Abre pantalla del Asistente
    FE->>BE: GET /assistant/conversations
    BE->>DB: SELECT id, title, updated_at\nFROM ai_conversations\nWHERE user_id=$1\nORDER BY updated_at DESC\nLIMIT 20
    DB-->>BE: historial de conversaciones
    BE-->>FE: 200 { conversations: [...] }
    FE->>U: Muestra historial de chats previos\n+ botón "Nueva conversación"

    U->>FE: Click "Nueva conversación"
    FE->>BE: POST /assistant/conversations
    BE->>DB: INSERT INTO ai_conversations (user_id, title='Nueva conversación')
    DB-->>BE: conversation { id }

    BE->>BE: Captura estado financiero actual (snapshot)
    par Consultas en paralelo para el snapshot
        BE->>DB: SELECT traffic_light, score FROM financial_health_snapshots\nWHERE user_id=$1 ORDER BY snapshot_date DESC LIMIT 1
    and
        BE->>DB: SELECT SUM(amount) as income, SUM(egreso) as expense\nFROM transactions WHERE user_id=$1 AND date >= month_start
    and
        BE->>DB: SELECT SUM(current_balance) as total_debt FROM debts\nWHERE user_id=$1 AND status='active'
    and
        BE->>DB: SELECT COUNT(*) as overdue FROM bills_payable\nWHERE user_id=$1 AND status='overdue'
    and
        BE->>DB: SELECT * FROM user_goals WHERE user_id=$1 AND is_active=true
    end

    DB-->>BE: datos financieros
    BE->>DB: INSERT INTO ai_context_snapshots (\n  conversation_id,\n  snapshot_date=NOW(),\n  financial_summary={\n    balance: ingreso-egreso,\n    total_debt: 4500000,\n    budget_used_pct: 73,\n    payments_overdue: 0,\n    traffic_light: 'green',\n    active_goals: 2\n  }\n)
    BE-->>FE: 201 { conversation_id }
    FE->>U: Abre pantalla de chat vacía
```

---

## UC-02: Enviar mensaje de texto y recibir respuesta

**Actor:** Usuario
**Precondición:** Conversación activa con snapshot disponible

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL
    participant LLM as LLM Service (externo)

    U->>FE: Escribe "¿Cuánto debo en total?"
    FE->>BE: POST /assistant/conversations/:id/messages { role:'user', content:'¿Cuánto debo en total?' }

    BE->>DB: INSERT INTO ai_messages (conversation_id, role='user', content)
    BE->>DB: UPDATE ai_conversations SET updated_at=NOW() WHERE id=$1

    BE->>DB: SELECT financial_summary FROM ai_context_snapshots\nWHERE conversation_id=$1
    DB-->>BE: snapshot financiero de esta sesión

    BE->>DB: SELECT role, content FROM ai_messages\nWHERE conversation_id=$1\nORDER BY created_at ASC
    DB-->>BE: historial de mensajes

    BE->>LLM: POST /chat {\n  system: "Eres Walvy, asistente financiero personal...\nContexto financiero del usuario: {snapshot}",\n  messages: [historial],\n  tools: [get_debts, get_upcoming_bills, ...]\n}

    LLM->>LLM: Evalúa si necesita herramientas
    LLM-->>BE: tool_call: { name:'get_debts', args:{} }

    BE->>DB: SELECT name, current_balance, minimum_payment, debt_type\nFROM debts WHERE user_id=$1 AND status='active'
    DB-->>BE: deudas activas
    BE->>DB: INSERT INTO ai_tool_invocations (\n  conversation_id, message_id,\n  tool_name='get_debts',\n  args={},\n  result={debts:[...]}\n)

    BE->>LLM: Retorna resultado de herramienta
    LLM-->>BE: response: "Tienes 3 deudas activas por un total de $4.500.000:\n1. Tarjeta Ripley: $180.000\n2. Crédito de Consumo: $850.000\n3. Hipotecario: $3.470.000"

    BE->>DB: INSERT INTO ai_messages (\n  conversation_id,\n  role='assistant',\n  content='Tienes 3 deudas...',\n  token_usage={prompt:245, completion:87, total:332}\n)
    BE-->>FE: 200 { message: { role:'assistant', content } }
    FE->>U: Muestra respuesta del asistente
```

### Herramientas disponibles para el LLM

| Tool | Query ejecutada | Datos retornados |
|------|----------------|-----------------|
| `get_financial_summary` | `financial_health_snapshots` + cálculo del mes | balance, deuda total, budget_used_pct |
| `get_debts` | `debts` WHERE status='active' | nombre, saldo, mínimo, tipo |
| `get_upcoming_bills` | `bills_payable` WHERE status='pending' ORDER BY due_date | título, monto, fecha, semáforo |
| `get_budget_status` | `budget_lines` + `transactions` del mes | categoría, planificado, gastado, % |
| `get_goals_progress` | `user_goals` + datos cross-módulo | tipo, descripción, progreso % |

---

## UC-03: Enviar mensaje de voz

**Actor:** Usuario
**Precondición:** Dispositivo con micrófono, permiso concedido

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant OS as Device (Speech-to-Text nativo)
    participant BE as Backend

    U->>FE: Mantiene presionado botón de micrófono
    FE->>OS: startRecording()
    U->>FE: Habla: "Registra un gasto de treinta mil pesos en supermercado"
    U->>FE: Suelta botón
    FE->>OS: stopRecording()
    OS-->>FE: transcript: "Registra un gasto de 30.000 pesos en supermercado"
    FE->>FE: Muestra texto transcrito en el input
    FE->>U: Confirma o edita el texto antes de enviar
    U->>FE: Toca "Enviar"
    FE->>BE: POST /messages { role:'user', content:'Registra un gasto de 30.000 pesos en supermercado' }
    Note over FE,BE: La BD NUNCA recibe audio\nSolo el texto transcrito por el OS
```

---

## UC-04: Consultar FAQ

**Actor:** Usuario
**Precondición:** El chat detecta una pregunta frecuente

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Escribe "¿Cómo funciona la bola de nieve?"
    FE->>BE: POST /assistant/conversations/:id/messages { content:'¿Cómo funciona la bola de nieve?' }

    BE->>DB: SELECT id, title, body, slug FROM faq_articles\nWHERE is_active=true\nAND (title ILIKE '%bola%nieve%'\n  OR body ILIKE '%bola%nieve%'\n  OR 'bola_de_nieve' = ANY(tags))\nORDER BY ts_rank(to_tsvector(title||' '||body),\n  plainto_tsquery('bola nieve')) DESC\nLIMIT 3

    DB-->>BE: artículos FAQ relevantes

    alt Hay artículo relevante con alta coincidencia
        BE->>LLM: {content, faq_context: artículo_faq}
        LLM-->>BE: respuesta apoyada en FAQ
        BE-->>FE: 200 { message, faq_articles: [{ title, slug }] }
        FE->>U: Respuesta del asistente + chip "Ver artículo completo"
    else Sin coincidencia en FAQ
        BE->>LLM: {content, snapshot} (sin contexto FAQ)
        LLM-->>BE: respuesta generada
        BE-->>FE: 200 { message }
    end
```

---

## UC-05: Ver historial de conversación previa

**Actor:** Usuario
**Precondición:** Al menos 1 conversación previa existente

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Selecciona conversación "Consulta sobre deudas - ayer"
    FE->>BE: GET /assistant/conversations/:id/messages
    BE->>DB: SELECT role, content, created_at\nFROM ai_messages\nWHERE conversation_id=$1\nORDER BY created_at ASC
    DB-->>BE: todos los mensajes de esa conversación
    BE-->>FE: 200 { messages: [...] }
    FE->>U: Renderiza historial completo del chat

    Note over U,FE: El usuario puede continuar esta conversación\nPero NO se crea un nuevo snapshot — se usa el original
    U->>FE: Escribe nuevo mensaje en la conversación vieja
    FE->>BE: POST /messages { content: '¿Y si pago $50.000 extra?' }
    BE->>DB: SELECT financial_summary FROM ai_context_snapshots\nWHERE conversation_id=$1
    Note over BE,DB: Usa el snapshot original de esa sesión\nNo recalcula para no perder el contexto
```

---

## UC-06: Mostrar recomendación contextual en pantalla

**Actor:** Sistema (al navegar entre pantallas)

Este flujo cruza con M3. El motor de recomendaciones evalúa reglas y registra en `recommendation_events`.

```mermaid
flowchart TD
    NAV([Usuario navega a pantalla]) --> CTX{¿Qué contexto?}
    CTX --> |home| HOME_REC[Evalúa reglas: home]
    CTX --> |budget| BUD_REC[Evalúa reglas: budget]
    CTX --> |debt| DEBT_REC[Evalúa reglas: debt]
    CTX --> |payments| PAY_REC[Evalúa reglas: payments]

    HOME_REC --> RULES[Lee app_config\nrecommendation.rules]
    BUD_REC --> RULES
    DEBT_REC --> RULES
    PAY_REC --> RULES

    RULES --> EVAL[Evalúa triggers vs\ndatos del usuario]
    EVAL --> DEDUP[Filtra reglas ya\nmostradas en últimas 24h\nDesde recommendation_events]
    DEDUP --> |Hay regla nueva| SHOW[INSERT recommendation_events\nMuestra banner al usuario]
    DEDUP --> |Todas ya mostradas| NONE[No muestra nada]

    SHOW --> ACTION{Usuario interactúa}
    ACTION --> |Click en acción| ACTIONED[UPDATE actioned_at]
    ACTION --> |Click X| DISMISSED[UPDATE dismissed_at]
    ACTION --> |Ignora| LOGGED[Solo queda registrado shown_at]
```

---

## Diagrama de relación entre tablas — M8

```mermaid
erDiagram
    ai_conversations {
        uuid id PK
        uuid user_id FK
        text title
        timestamp updated_at
    }
    ai_messages {
        uuid id PK
        uuid conversation_id FK
        varchar role
        text content
        jsonb token_usage
    }
    ai_tool_invocations {
        uuid id PK
        uuid conversation_id FK
        uuid message_id FK
        varchar tool_name
        jsonb args
        jsonb result
    }
    ai_context_snapshots {
        uuid id PK
        uuid conversation_id FK
        date snapshot_date
        jsonb financial_summary
    }
    faq_articles {
        uuid id PK
        varchar slug UK
        text title
        text body
        text[] tags
        varchar locale
        boolean is_active
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

    ai_conversations }o--|| users : "del usuario"
    ai_messages }o--|| ai_conversations : "mensajes de"
    ai_tool_invocations }o--|| ai_conversations : "llamadas de herramienta"
    ai_tool_invocations }o--|| ai_messages : "en mensaje"
    ai_context_snapshots ||--|| ai_conversations : "snapshot de sesión"
    recommendation_events }o--|| users : "mostrada a"
```
