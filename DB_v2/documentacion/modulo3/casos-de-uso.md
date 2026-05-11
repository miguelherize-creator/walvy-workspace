# Módulo 3 — Casos de Uso

**Módulo:** Home (Seguimiento, Visualización y Motivación)  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 3

**Actores:**
- **Usuario** — persona que usa la app Walvy
- **Sistema** — job periódico de backend que recalcula read models y genera recomendaciones
- **Administrador** — opera reglas de gamificación y mensajería desde el backoffice

---

## CU-01 — Abrir el home

**Actor principal:** Usuario  
**Precondiciones:** Usuario autenticado con sesión activa.

### Flujo principal

```
1. Usuario abre la app o navega al tab Home.
2. App llama a GET /home (o equivalente).
3. Backend consulta v_user_home_month para el user_id y mes actual.
4. Backend consulta:
   a. user_month_diagnosis_summary → semáforo, capacidad de ahorro.
   b. user_month_debt_priority_summary → deuda prioritaria y fecha estimada de salida.
   c. user_upcoming_payments_summary → próximos 7 días de pagos.
   d. user_month_leaks_summary → fugas y gastos hormiga del mes.
   e. user_gamification_stats → puntaje y nivel.
   f. gamification_events WHERE created_at >= today → logros del día.
   g. message_event WHERE context = 'home' AND status = 'created' → recomendaciones.
5. Backend retorna payload consolidado.
6. App renderiza: semáforo, balance, gráficos, recomendaciones, puntaje.
```

### Flujo alternativo — Usuario nuevo sin datos

```
3. No existe registro en user_month_diagnosis_summary para este mes.
→ Backend retorna payload vacío con data_quality_level = 'low'.
→ App muestra estado vacío con dos CTAs:
   - "Importar cartola" → navega a flujo de importación (Módulo 5).
   - "Registrar movimiento manual" → navega al formulario de movimiento.
```

### Postcondiciones
- El usuario ve el estado de su mes sin esperas perceptibles (read models pre-calculados).

---

## CU-02 — Leer recomendación y navegar a la acción

**Actor principal:** Usuario  
**Precondiciones:** Existe al menos un `message_event` con `status = created` para el usuario.

### Flujo principal

```
1. El home muestra una card de recomendación.
   Ej: "Tu categoría Delivery superó el 80 % del presupuesto."
2. Usuario toca la card.
3. App registra: POST /recommendations/{id}/interact { action: 'opened' }
4. Backend crea user_message_interaction con action = 'opened'.
5. Backend actualiza message_event.shown_at = now().
6. App navega al deep_link de la regla
   (ej: /(tabs)/budget → pantalla de presupuesto con la categoría resaltada).
```

### Flujo alternativo — Usuario descarta la recomendación

```
2. Usuario toca "X" en la card.
3. App registra: { action: 'dismissed' }
4. Backend actualiza message_event.status → 'suppressed', suppressed_until = NULL.
5. La recomendación no vuelve a aparecer en el home para ese evento.
```

### Flujo alternativo — Usuario pospone la recomendación

```
2. Usuario toca "Recordar más tarde".
3. App registra: { action: 'snoozed' }
4. Backend actualiza message_event.suppressed_until = now() + 3 días.
5. La recomendación desaparece del home y reaparece en 3 días.
```

---

## CU-03 — Ver logros del día

**Actor principal:** Usuario  
**Precondiciones:** El usuario realizó al menos una acción valorada hoy (registró pago, cumplió presupuesto, etc.).

### Flujo principal

```
1. Home muestra widget de logros:
   Ej: "Hoy ganaste 50 puntos — Pago de deuda registrado ✓"
2. Usuario toca el widget.
3. App navega a pantalla de gamificación con:
   - total_points y level de user_gamification_stats.
   - Historial reciente de gamification_events.
   - user_score_history por período para el gráfico de evolución.
```

### Flujo alternativo — Sin logros hoy

```
→ El widget muestra el estado neutral:
  "Tu puntaje: X pts · Nivel Y"
  Sin eventos listados.
```

---

## CU-04 — Ganar puntos al completar acción (automático)

**Actor principal:** Sistema (disparado por acciones del usuario en otros módulos)  
**Precondiciones:** El usuario completa una acción valorada. Existe una `gamification_rules` activa con ese `event_type`.

### Ejemplos de eventos que disparan puntos

| Acción del usuario | event_type | Módulo que dispara |
|--------------------|------------|--------------------|
| Registra un pago de deuda | `debt_payment_registered` | Módulo 4 |
| Cumple presupuesto del mes | `budget_met_monthly` | Módulo 5 |
| Importa cartola exitosamente | `statement_imported` | Módulo 5 |
| Configura metas financieras | `goals_set` | Módulo 2 |
| Completa el onboarding | `onboarding_completed` | Módulo 1 |

### Flujo principal

```
1. El módulo correspondiente llama al servicio de gamificación.
2. Sistema busca la regla activa: SELECT * FROM gamification_rules
   WHERE event_type = :type AND is_active = true.
3. Si existe: INSERT INTO gamification_events con snapshot de points.
4. Sistema actualiza user_gamification_stats:
   total_points += points
   level = calcular_nivel(total_points)
   last_computed_at = now()
5. Si el nivel subió: el backend puede generar un message_event especial
   (ej: rule code = 'level_up') para celebrar el logro en el home.
```

---

## CU-05 — Recalcular read models (job periódico)

**Actor principal:** Sistema  
**Precondiciones:** Han ocurrido cambios en movimientos, pagos o deudas desde el último cálculo.

### Flujo principal

```
1. Job se ejecuta (ej: cada 30 minutos o disparado por eventos de escritura).
2. Por cada usuario activo con cambios:
   a. Compara source_watermark_at del snapshot con updated_at de tablas fuente.
   b. Si hay cambios: recalcula el read model correspondiente.
3. user_month_diagnosis_summary:
   - Evalúa reglas del semáforo.
   - Calcula visible_savings_capacity.
   - Determina next_action_type.
4. user_month_debt_priority_summary:
   - Aplica lógica Bola de Nieve.
   - Calcula priority_rank y estimated_payoff_date.
5. user_upcoming_payments_summary:
   - Busca user_payment con due_date en los próximos 7 días.
6. user_month_leaks_summary:
   - Suma gastos hormiga (is_ant_expense = true).
   - Agrupa top_categories drenantes.
7. UPSERT en cada tabla con el nuevo snapshot y source_watermark_at actualizado.
```

### Postcondiciones
- Los read models reflejan el estado más reciente de los datos del usuario.
- El home del usuario muestra información actualizada en la próxima apertura.

---

## CU-06 — Administrador gestiona reglas de mensajería (backoffice)

**Actor principal:** Administrador  
**Precondiciones:** Administrador autenticado en el backoffice.

### Flujo principal

```
1. Administrador accede a "Reglas de recomendación".
2. Ve listado de message_rule con code, context, priority e is_active.
3. Puede:
   a. Activar/desactivar una regla (is_active toggle).
   b. Cambiar la prioridad (1–5).
   c. Editar el deep_link o el texto.
   d. Crear una nueva regla con código único.
4. El cambio toma efecto en el próximo ciclo del job de análisis.
```

---

## CU-07 — Administrador gestiona reglas de gamificación (backoffice)

**Actor principal:** Administrador  
**Precondiciones:** Administrador autenticado.

### Flujo principal

```
1. Administrador accede a "Configuración de gamificación".
2. Ve listado de gamification_rules con event_type, points e is_active.
3. Puede ajustar points o desactivar una regla.
4. El sistema registra updated_by_admin_id = admin.id.
5. Los cambios aplican a eventos nuevos (no retroactivos sobre gamification_events ya creados).
```

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Abrir el home | Usuario | RF-01, RF-02, RF-03, RF-07 | ✅ |
| CU-02 | Leer recomendación y navegar a la acción | Usuario | RF-04, RF-05 | ✅ |
| CU-03 | Ver logros del día | Usuario | RF-07 | ✅ |
| CU-04 | Ganar puntos al completar acción | Sistema | RF-06 | ✅ |
| CU-05 | Recalcular read models | Sistema | RF-08 | ✅ |
| CU-06 | Gestionar reglas de mensajería | Administrador | RF-04, RNF-02 | ✅ |
| CU-07 | Gestionar reglas de gamificación | Administrador | RF-06, RNF-03 | ✅ |
