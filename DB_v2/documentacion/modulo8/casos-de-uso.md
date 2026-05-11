# Módulo 8 — Casos de Uso

**Módulo:** Asistente IA y Soporte  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 8

---

## CU-01 — Iniciar conversación con el asistente

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario navega a "Asistente" → "Nueva conversación".
2. App llama POST /ai/conversations.
3. Backend:
   a. Crea ai_conversations.
   b. Lee los read models del usuario (user_month_diagnosis_summary, etc.).
   c. Crea ai_context_snapshots con financial_summary serializado.
4. App muestra el chat vacío listo para el primer mensaje.
```

---

## CU-02 — Chat con el asistente

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario escribe "¿Cuánto gasté en delivery este mes?".
2. App llama POST /ai/conversations/{id}/messages { content: "..." }.
3. Backend:
   a. INSERT ai_messages { role: 'user', content: "..." }.
   b. Construye el payload para la API del modelo:
      - System: snapshot financiero del usuario + instrucciones de rol.
      - History: todos los ai_messages de la conversación.
      - User: el mensaje nuevo.
   c. Llama a la API del modelo (streaming).
   d. Si el modelo invoca tool 'get_category_spending':
      → Backend ejecuta la query real.
      → INSERT ai_tool_invocations con tool_name, args, result.
      → Retorna el resultado al modelo.
   e. INSERT ai_messages { role: 'assistant', content: respuesta, token_usage }.
4. App muestra la respuesta en streaming.
```

---

## CU-03 — Retomar conversación

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario navega a "Asistente" → ve el historial de conversaciones.
2. Toca una conversación anterior.
3. App llama GET /ai/conversations/{id}/messages.
4. Backend retorna todos los ai_messages ordenados por created_at ASC.
5. App renderiza el historial y el usuario puede continuar.
```

---

## CU-04 — Asistente consulta la base de conocimiento

**Actor principal:** Sistema (herramienta del asistente)

### Flujo principal

```
1. Usuario pregunta: "¿Cómo funciona la Bola de Nieve?".
2. El modelo decide invocar la herramienta search_faq.
3. Backend ejecuta: SELECT FROM faq_articles WHERE is_active = true
   AND to_tsvector('spanish', title || body) @@ plainto_tsquery('Bola de Nieve').
4. Retorna el artículo relevante al modelo.
5. El modelo responde citando el artículo.
```

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Iniciar conversación | Usuario | RF-01 | ✅ |
| CU-02 | Chat con el asistente | Usuario | RF-02 | ✅ |
| CU-03 | Retomar conversación | Usuario | RF-03 | ✅ |
| CU-04 | Búsqueda en base de conocimiento | Sistema | RF-04 | ✅ |
