# DB — Módulo 8: Asistente IA y Soporte

## Tablas propias (escribe principalmente)

| Tabla | Rol |
|-------|-----|
| `ai_conversations` | Sesiones de chat |
| `ai_messages` | Mensajes individuales (texto y voz transcrita) |
| `ai_tool_invocations` | Llamadas a herramientas del LLM |
| `ai_context_snapshots` | Snapshot financiero al iniciar conversación |
| `recommendation_events` | Log de recomendaciones contextuales por pantalla |

## Tablas que solo lee

| Tabla | Para qué |
|-------|----------|
| `faq_articles` | Responder preguntas frecuentes |
| `financial_health_snapshots` | Contexto del semáforo en las respuestas |
| `debts` + `debt_snowball_plan` | Contexto de deudas para respuestas |
| `budget_lines` + `transactions` | Contexto de presupuesto para respuestas |
| `bills_payable` | Contexto de pagos próximos para respuestas |
| `user_goals` | Contexto de metas del usuario |
| `app_config` | Reglas de recomendaciones (`recommendation.rules`) |

## Tablas que administra (solo backoffice)

| Tabla | Rol |
|-------|-----|
| `faq_articles` | Contenido de FAQ — se gestiona desde M9 |

---

## Detalle por tabla

### `ai_conversations`
Una sesión por "hilo de chat". El usuario puede tener varias conversaciones.

| Campo | Qué hace |
|-------|----------|
| `title` | Primer mensaje truncado o título generado — visible en historial |
| `updated_at` | Permite mostrar conversaciones ordenadas por recencia |

---

### `ai_messages`
Registro inmutable de cada mensaje en una conversación.

| Campo | Qué hace |
|-------|----------|
| `role` | `user` \| `assistant` \| `system` |
| `content` | Texto del mensaje. Si fue voz → ya convertido a texto en el cliente |
| `token_usage` | `{ prompt_tokens, completion_tokens, total }` — para tracking de costo si se usa LLM externo |

**Flujo de voz:**
```
[Cliente] captura audio → convierte a texto (speech-to-text nativo del OS)
[Cliente] envía texto como si fuera mensaje de usuario
[API] INSERT ai_messages (role='user', content=texto_transcrito)
```
La BD nunca almacena audio — solo el texto resultante.

---

### `ai_tool_invocations`
Function calling del LLM para consultar contexto financiero.

| Campo | Qué hace |
|-------|----------|
| `tool_name` | Herramienta invocada (ej: `"get_balance"`, `"get_debts"`, `"get_budget_status"`) |
| `args` | Parámetros enviados (ej: `{ period: "2026-04" }`) |
| `result` | Datos retornados al LLM para formular respuesta |

**Herramientas MVP recomendadas:**

| Tool | Qué consulta |
|------|-------------|
| `get_financial_summary` | Balance, deuda total, presupuesto del mes |
| `get_debts` | Lista de deudas activas con prioridad |
| `get_upcoming_bills` | Pagos próximos a vencer |
| `get_budget_status` | Cumplimiento por categoría |
| `get_goals_progress` | Estado de metas globales |

---

### `ai_context_snapshots`
Se crea al iniciar una conversación — captura el estado financiero en ese momento.

| Campo | Qué hace |
|-------|----------|
| `financial_summary` | `{ balance, total_debt, budget_used_pct, payments_overdue, traffic_light, active_goals }` |

**Por qué existe:** evita que el LLM haga queries en tiempo real durante la conversación. El snapshot es la fuente de verdad del contexto financiero de esa sesión.

---

### `recommendation_events`
Log de recomendaciones contextuales mostradas en cualquier pantalla de la app.

| Campo | Qué hace |
|-------|----------|
| `context` | Pantalla: `home`, `budget`, `debt`, `payments`, `profile` |
| `rule_key` | Identifica qué regla disparó (definida en `app_config`) |
| `payload` | `{ text, action_label, action_deep_link }` |
| `dismissed_at` | Usuario descartó explícitamente |
| `actioned_at` | Usuario hizo click en la acción sugerida |

**Uso del log:**
- Evitar mostrar la misma recomendación dos veces en el mismo día
- Medir qué reglas generan más acción (input para ajuste de `app_config`)

---

### `faq_articles`
Contenido estático/semiestático de preguntas frecuentes.

| Campo | Qué hace |
|-------|----------|
| `slug` | Identificador único para deep link y búsqueda |
| `tags` | Etiquetas (ej: `["deuda","bola_de_nieve"]`) para sugerir FAQs relevantes en el chat |
| `locale` | `"es"` \| `"es-CL"` |
| `is_active` | Activar/desactivar sin eliminar |

**Integración con chat:** cuando el usuario pregunta algo, el asistente puede sugerir artículos FAQ relevantes usando `tags` y búsqueda por texto en `title` + `body`.

---

## Flujos de datos principales

```
INICIAR CONVERSACIÓN
  → INSERT ai_conversations
  → INSERT ai_context_snapshots (snapshot financiero del usuario)

ENVIAR MENSAJE (texto o voz)
  → INSERT ai_messages (role='user')
  → [si LLM necesita datos] INSERT ai_tool_invocations
  → INSERT ai_messages (role='assistant', response)

MOSTRAR RECOMENDACIÓN EN PANTALLA
  → evaluar reglas desde app_config vs datos del usuario
  → INSERT recommendation_events (context, rule_key, payload)

USUARIO ACTÚA SOBRE RECOMENDACIÓN
  → UPDATE recommendation_events.actioned_at = now()

USUARIO DESCARTA RECOMENDACIÓN
  → UPDATE recommendation_events.dismissed_at = now()
```

---

## Motor de recomendaciones (reglas MVP)

Las reglas viven en `app_config` bajo la clave `recommendation.rules`. Ejemplo:

```json
{
  "budget_80pct": {
    "context": ["home", "budget"],
    "trigger": "budget_used_pct >= 80",
    "text": "Llevas el {pct}% de tu presupuesto en {category}. Considera revisar gastos.",
    "action": { "label": "Ver presupuesto", "deepLink": "/(tabs)/budget" }
  },
  "payment_due_3d": {
    "context": ["home", "payments"],
    "trigger": "days_until_due <= 3",
    "text": "Tu pago de {title} vence en {days} días.",
    "action": { "label": "Ver pagos", "deepLink": "/(tabs)/payments" }
  },
  "snowball_idle": {
    "context": ["home", "debt"],
    "trigger": "has_debts AND days_since_last_payment > 30",
    "text": "¿Cuándo fue tu último pago extra a tu deuda prioritaria?",
    "action": { "label": "Ver plan", "deepLink": "/(tabs)/debt" }
  }
}
```

---

## Índices críticos

| Tabla | Índice | Motivo |
|-------|--------|--------|
| `ai_conversations` | `(user_id, updated_at DESC)` | Historial de chats ordenado |
| `ai_messages` | `(conversation_id, created_at ASC)` | Cargar conversación en orden |
| `recommendation_events` | `(user_id, context, shown_at DESC)` | Evitar repetir la misma regla |
| `faq_articles` | `slug` (UNIQUE) | Lookup directo |
| `faq_articles` | `is_active` | Filtrar activos |
