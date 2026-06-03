# M3 — Home (Dashboard, Gamificación, Recomendaciones)

**Layers:** 14 (Gamificación) · 15 (Mensajería) · 18 (Read Models CQRS) · 19 (Vistas)  
**Estado:** 📋 Referencia — abierto a cambios  
**Docs originales:** `legacy/DB_v2/documentacion/modulo3/`

---

## Propósito
Módulo principalmente de **lectura**. No almacena movimientos ni deudas directamente. Sus tablas son:
- **Read models** (Layer 18): snapshots pre-calculados para evitar joins costosos en cada request del Home
- **Gamificación** (Layer 14): puntos y logros del usuario
- **Mensajería/Recomendaciones** (Layer 15): motor de cards contextuales

---

## Dependencias

```
financial_movement (M5) ─────────────────────────────┐
budget_plan / budget_plan_item (M6) ─────────────────┤
debt / debt_schedules (M4) ──────────────────────────┤──► Read Models (Layer 18)
user_payment (M7) ───────────────────────────────────┘         │
                                                               ▼
                                                     Home dashboard (API)

app_user ──► gamification_rules ──► gamification_events ──► user_gamification_stats
app_user ──► message_rule ──────────► message_event ──────► user_message_interaction
```

---

## Layer 14 — Gamificación

### `gamification_rules`
Catálogo de eventos que suman puntos. Administrado desde backoffice.

| Columna | Notas |
|---------|-------|
| `event_type` TEXT UNIQUE | `debt_payment_registered`, `budget_met`, `login_streak_3` |
| `points` INT | Puntos que otorga |
| `is_active` BOOLEAN | Desactivar sin borrar |

### `gamification_events`
Registro inmutable de cada evento disparado por un usuario.

| Columna | Notas |
|---------|-------|
| `user_id` FK, `rule_id` FK | |
| `triggered_at` TIMESTAMPTZ | |
| `metadata` JSONB NULL | Contexto del evento |

### `user_gamification_stats`
Totales acumulados por usuario (1:1 con app_user).

| Columna | Notas |
|---------|-------|
| `total_points` INT | |
| `current_streak_days` INT | |
| `last_activity_date` DATE | |

### `user_score_history`
Historial de puntos para gráficos de evolución.

---

## Layer 15 — Mensajería y Recomendaciones

### `message_rule`
Reglas que definen cuándo mostrar una card de recomendación.

| Columna | Notas |
|---------|-------|
| `trigger_event` TEXT | Condición de disparo |
| `context` TEXT | Pantalla donde aplica: `home`, `budget`, `debts`, `payments` |
| `message_template` TEXT | Plantilla con variables `{nombre}`, `{monto}` |
| `priority` INT | Orden cuando hay múltiples cards |
| `is_active` BOOLEAN | |

### `message_event`
Instancias de mensajes generados para un usuario específico.

| Columna | Notas |
|---------|-------|
| `user_id` FK, `rule_id` FK | |
| `rendered_message` TEXT | Mensaje ya renderizado con datos reales |
| `context` TEXT | Pantalla destino |
| `expires_at` TIMESTAMPTZ NULL | |

### `user_message_interaction`
Registro de si el usuario vio/descartó/accionó el mensaje.

| Columna | Notas |
|---------|-------|
| `action` TEXT | `viewed`, `dismissed`, `actioned` |

---

## Layer 18 — Read Models CQRS

Tablas desnormalizadas actualizadas por jobs batch. Las pantallas leen de aquí.

| Tabla | Contenido | Alimentado por |
|-------|-----------|----------------|
| `user_month_diagnosis_summary` | balance, income, expenses, health_score del mes | M5 movements + M6 budget |
| `user_month_debt_priority_summary` | deudas ordenadas por prioridad snowball | M4 debt |
| `user_upcoming_payments_summary` | próximos pagos en 30 días | M7 user_payment |
| `user_month_leaks_summary` | fugas de liquidez detectadas | M5 movements |

---

## Layer 19 — Vistas SQL

| Vista | Uso |
|-------|-----|
| `v_user_home_month` | Payload principal del home — une todos los read models |
| `v_user_access` | user + role + subscription activa |
| `v_user_current_subscription` | subscription + plan + precio vigente |
| `v_cashflow_summary` | balance del mes por usuario |
