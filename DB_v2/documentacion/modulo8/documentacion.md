# Módulo 8 — Asistente IA y Soporte

**Layer cubierto:** 16 (Asistente IA y FAQ)  
**Corresponde a:** CSV Módulo 8 — Asistente Financiero IA  
**Estado MVP:** ✅ Incluido

---

## 1. Propósito del módulo

El Módulo 8 gestiona el **asistente financiero conversacional** de Walvy y la base de conocimiento de soporte. Es un diferenciador de producto clave: el usuario puede hacerle preguntas financieras al asistente y recibir respuestas contextualizadas con su situación real.

---

## 2. Diagrama de dependencias

```
app_user (M1) ──────────────────────► ai_conversations
                                              │
                                    ┌─────────┴─────────────────┐
                                    ▼                           ▼
                               ai_messages               ai_context_snapshots
                                    │                    (snapshot financiero al inicio)
                                    ▼
                          ai_tool_invocations
                          (herramientas llamadas por el IA)

faq_articles (base de conocimiento — sin FK a usuario)
```

---

## 3. Tablas del módulo

### 3.1 `ai_conversations`

Una conversación del usuario con el asistente. Agrupa todos los mensajes de esa sesión.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `title` | TEXT NULL | Título generado automáticamente (primeras palabras del primer mensaje) |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Índice:** `(user_id, updated_at DESC)`

---

### 3.2 `ai_messages`

Mensajes dentro de una conversación. Incluye mensajes del usuario, del asistente y mensajes de sistema.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `conversation_id` | UUID FK → ai_conversations | |
| `role` | VARCHAR(10) | `user`, `assistant`, `system` |
| `content` | TEXT NOT NULL | Contenido del mensaje |
| `token_usage` | JSONB NULL | `{ "input_tokens": 500, "output_tokens": 200 }` |
| `created_at` | TIMESTAMPTZ | |

**Índice:** `(conversation_id, created_at ASC)` — para leer el historial en orden cronológico

---

### 3.3 `ai_tool_invocations`

Registro de cada herramienta que el asistente llamó durante una respuesta. Permite auditar qué datos consultó el IA y qué retornó.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `message_id` | UUID FK → ai_messages | Mensaje del asistente que generó la invocación |
| `tool_name` | TEXT NOT NULL | Ej: `get_monthly_summary`, `list_debts`, `search_faq` |
| `args` | JSONB NULL | Parámetros pasados a la herramienta |
| `result` | JSONB NULL | Resultado retornado por la herramienta |
| `created_at` | TIMESTAMPTZ | |

---

### 3.4 `ai_context_snapshots`

Snapshot del contexto financiero del usuario capturado al iniciar una conversación. Permite que el IA tenga contexto sin consultar tablas operacionales en tiempo real durante el chat.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `conversation_id` | UUID FK → ai_conversations | |
| `snapshot_date` | DATE NOT NULL | Fecha del snapshot |
| `financial_summary` | JSONB DEFAULT '{}' | Resumen financiero: semáforo, balance, deudas, presupuesto |
| `created_at` | TIMESTAMPTZ | |

---

### 3.5 `faq_articles`

Base de conocimiento para el asistente. Artículos con búsqueda full-text en español.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `slug` | TEXT UNIQUE | URL-friendly. Ej: `como-registrar-deuda` |
| `title` | TEXT NOT NULL | |
| `body` | TEXT NOT NULL | Contenido del artículo |
| `locale` | TEXT DEFAULT 'es' | Idioma |
| `tags` | TEXT[] NULL | Etiquetas para filtrado |
| `sort_order` | INT DEFAULT 0 | |
| `is_active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Índice:** GIN full-text sobre `title || body` con diccionario `spanish`

---

## 4. Triggers del módulo

| Trigger | Tabla | Evento |
|---------|-------|--------|
| `trg_ai_conversations_updated_at` | `ai_conversations` | BEFORE UPDATE |
| `trg_faq_articles_updated_at` | `faq_articles` | BEFORE UPDATE |

---

## 5. Relaciones con otros módulos

| Módulo | Relación |
|--------|----------|
| Módulo 1 — Auth | `app_user` como FK base |
| Módulo 3 — Home | `ai_context_snapshots.financial_summary` incluye datos de los read models del home |
| Módulo 9 — Admin | Administradores gestionan `faq_articles` desde el backoffice |

---

## 6. Notas de diseño

- **`ai_context_snapshots`:** evita que el IA haga N queries a tablas operacionales durante el chat. Al iniciar la conversación, el backend genera un snapshot JSON y el IA lo usa como contexto.
- **`ai_tool_invocations`:** trazabilidad completa de qué datos accedió el IA. Útil para auditoría y para mejorar los prompts.
- **`token_usage`:** permite monitorear costos de API por conversación.
- **`faq_articles`:** el índice GIN full-text permite búsqueda semántica en español sin motor externo en el MVP. En fases posteriores puede reemplazarse por embeddings vectoriales.
