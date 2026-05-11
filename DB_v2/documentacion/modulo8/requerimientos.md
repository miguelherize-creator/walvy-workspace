# Módulo 8 — Requerimientos

**Módulo:** Asistente IA y Soporte  
**Layer:** 16  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 8

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Chat con asistente financiero | ✅ Incluido |
| Historial de conversaciones | ✅ Incluido |
| Contexto financiero personalizado | ✅ Incluido |
| Búsqueda en base de conocimiento (FAQ) | ✅ Incluido |
| Auditoría de herramientas usadas por el IA | ✅ Incluido |
| IA proactiva (notificaciones automáticas del IA) | ❌ No incluido en MVP |
| Fine-tuning de modelos propios | ❌ No incluido en MVP |
| Análisis predictivo con ML | ❌ No incluido en MVP |

---

## Requerimientos Funcionales

### RF-01 — Iniciar conversación con el asistente

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Crear conversación |
| **Descripción** | El usuario inicia una nueva conversación con el asistente financiero. |
| **Reglas** | - Crea `ai_conversations`. - Backend genera `ai_context_snapshots` con el resumen financiero actual del usuario (leeendo read models del home). - El IA recibe el snapshot como contexto del sistema antes del primer mensaje. |

---

### RF-02 — Enviar mensaje al asistente

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | Chat con el asistente |
| **Descripción** | El usuario escribe un mensaje y recibe respuesta contextualizada. |
| **Reglas** | - INSERT `ai_messages` con `role = user`. - Backend llama a la API del modelo con el historial de la conversación + el snapshot de contexto. - La respuesta se inserta como `ai_messages` con `role = assistant`. - Si el IA invoca herramientas: INSERT en `ai_tool_invocations` por cada herramienta. - `token_usage` se registra en el mensaje del asistente. |

---

### RF-03 — Ver historial de conversaciones

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | Listar conversaciones pasadas |
| **Descripción** | El usuario puede ver y retomar sus conversaciones anteriores con el asistente. |
| **Reglas** | - Lista `ai_conversations` por `user_id` ORDER BY `updated_at DESC`. - Al retomar: carga todos los `ai_messages` de esa conversación en orden cronológico. |

---

### RF-04 — Buscar en la base de conocimiento

| Campo | Detalle |
|-------|---------|
| **ID** | RF-04 |
| **Nombre** | Búsqueda en FAQ |
| **Descripción** | El asistente o el usuario puede buscar artículos en la base de conocimiento. |
| **Reglas** | - Búsqueda full-text sobre `faq_articles` WHERE `is_active = true`. - El IA puede invocar la herramienta `search_faq` automáticamente. - Los artículos se pueden leer desde la pantalla de soporte de la app. |

---

## Requerimientos No Funcionales

### RNF-01 — Contexto sin queries en tiempo real
El asistente **no consulta tablas operacionales durante el chat**. Todo el contexto financiero se carga una vez al iniciar la conversación en `ai_context_snapshots`. Esto garantiza latencia <2 segundos por mensaje.

### RNF-02 — Trazabilidad
Todas las invocaciones de herramientas quedan registradas en `ai_tool_invocations`. Permite auditar qué datos accedió el IA y detectar respuestas incorrectas.

### RNF-03 — Sin datos sensibles en ai_messages
El historial de chat no debe contener información financiera literal (números de cuenta, contraseñas). El contexto se pasa vía `ai_context_snapshots` en forma agregada.
