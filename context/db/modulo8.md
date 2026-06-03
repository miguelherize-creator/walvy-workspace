# M8 — Asistente IA y Soporte

**Layer:** 16 (Asistente IA y FAQ)  
**Estado:** 📋 Referencia — abierto a cambios  
**Docs originales:** `legacy/DB_v2/documentacion/modulo8/`

---

## Propósito
Asistente financiero conversacional. El usuario hace preguntas y recibe respuestas contextualizadas con su situación financiera real. Diferenciador de producto clave de Walvy.

---

## Dependencias

```
app_user (M1) ──► ai_conversations
                         │
             ┌───────────┴──────────────────┐
             ▼                              ▼
        ai_messages                 ai_context_snapshots
             │                      (snapshot al inicio)
             ▼
    ai_tool_invocations
    (herramientas llamadas por el IA)

faq_articles (sin FK a usuario — base de conocimiento global)
```

---

## Tablas

### `ai_conversations`
| Columna | Notas |
|---------|-------|
| `id` UUID PK | |
| `user_id` UUID FK | |
| `title` TEXT NULL | Generado automáticamente de las primeras palabras |
| **Índice:** `(user_id, updated_at DESC)` | |

### `ai_messages`
| Columna | Notas |
|---------|-------|
| `id` UUID PK | |
| `conversation_id` UUID FK | |
| `role` VARCHAR(10) | `user`, `assistant`, `system` |
| `content` TEXT NOT NULL | |
| `token_usage` JSONB NULL | `{ "input_tokens": 500, "output_tokens": 200 }` |
| **Índice:** `(conversation_id, created_at ASC)` | Para historial cronológico |

### `ai_tool_invocations`
Auditoría de cada tool call del asistente — permite rastrear qué datos consultó.

| Columna | Notas |
|---------|-------|
| `message_id` UUID FK → ai_messages | Mensaje que generó la invocación |
| `tool_name` TEXT | `get_monthly_summary`, `list_debts`, `search_faq` |
| `args` JSONB NULL | Parámetros de la llamada |
| `result` JSONB NULL | Resultado retornado |

### `ai_context_snapshots`
Snapshot del contexto financiero del usuario al inicio de cada conversación.

| Columna | Notas |
|---------|-------|
| `conversation_id` UUID FK | |
| `snapshot` JSONB | `{ monthly_income, expenses, balance, health_score, debts, upcoming_payments }` |
| `created_at` TIMESTAMPTZ | |

### `faq_articles`
Base de conocimiento global. Sin FK a usuario.

| Columna | Notas |
|---------|-------|
| `id` UUID PK | |
| `title` TEXT | |
| `content` TEXT | Markdown |
| `tags` TEXT[] | Para búsqueda por etiquetas |
| `is_published` BOOLEAN | |

---

## Notas de diseño
- El snapshot se toma de los read models de M3 al iniciar la conversación (no en tiempo real)
- `ai_tool_invocations` es append-only — nunca se modifica
- Para el skill `/walvy-ai`: ver `context/specs/` para el diseño del módulo completo
