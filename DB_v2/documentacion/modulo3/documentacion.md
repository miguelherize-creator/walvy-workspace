# Módulo 3 — Home (Seguimiento, Visualización y Motivación)

**Layers cubiertos:** 14 (Gamificación) · 15 (Mensajería y Recomendaciones) · 18 (Read Models CQRS) · 19 (Vistas de negocio)  
**Corresponde a:** CSV Módulo 3 — Home  
**Estado MVP:** ✅ Incluido

---

## 1. Propósito del módulo

El Home es la pantalla central de Walvy. Muestra el estado financiero del mes, el semáforo, el avance de deudas, los pagos próximos, las fugas de liquidez, las recomendaciones contextuales y los logros de gamificación.

Este módulo es principalmente **de lectura**: no almacena movimientos ni deudas directamente. Sus tablas propias son:
- Los **read models** (snapshots pre-calculados) que evitan recalcular aggregaciones pesadas en cada request.
- El **motor de gamificación** que registra puntos y logros del usuario.
- El **motor de mensajería/recomendaciones** que decide qué cards contextuales se muestran y en qué pantalla.

---

## 2. Diagrama de dependencias

```
financial_movement (M5) ────────────────────────────────┐
budget_plan / budget_plan_item (M5) ────────────────────┤
debt / debt_schedules (M4) ─────────────────────────────┤
user_payment (M6) ──────────────────────────────────────┤
                                                        ▼
                                        user_month_diagnosis_summary
                                        user_month_debt_priority_summary
                                        user_upcoming_payments_summary
                                        user_month_leaks_summary
                                                        │
                                                        ▼
                                              Home dashboard

app_user (M1·L4) ──► gamification_rules ──► gamification_events ──► user_gamification_stats
                                                                              │
                                                                              ▼
                                                                    user_score_history

app_user (M1·L4) ──► message_rule ──► message_event ──► user_message_interaction
```

**Dependencias entrantes (tablas que alimentan los read models):**
- `financial_movement` (Módulo 5)
- `budget_plan` / `budget_plan_item` (Módulo 5)
- `debt` / `debt_schedules` (Módulo 4)
- `user_payment` (Módulo 6)

**Dependencias salientes:**
- `v_user_home_month` — vista que el backend consulta para construir el payload del home
- `message_event` — otras pantallas (presupuesto, deudas, pagos) filtran por `context` para sus propias recomendaciones

---

## 3. Diagrama ERD

Ver archivo: [`modulo3.dbml`](./modulo3.dbml)

---

## 4. Tablas del módulo

### 4.1 `gamification_rules`

Catálogo de eventos que suman puntos. Lo gestiona el administrador desde el backoffice.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `event_type` | TEXT UNIQUE | Código del evento. Ej: `debt_payment_registered`, `budget_met`, `login_streak_3` |
| `points` | INT | Puntos que otorga el evento |
| `label` | TEXT | Nombre visible. Ej: "Pago de deuda registrado" |
| `description` | TEXT NULL | Explicación para el backoffice |
| `is_active` | BOOLEAN | Desactivar sin borrar |
| `updated_by_admin_id` | UUID NULL | FK → admin_users |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

---

### 4.2 `gamification_events`

Log inmutable de cada vez que un usuario gana puntos. Una fila por evento, nunca se modifica.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `event_type` | TEXT | Debe existir en `gamification_rules` al momento del disparo |
| `points` | INT | Snapshot del valor en ese momento (no cambia si se edita la regla) |
| `reference_type` | TEXT NULL | Entidad que disparó el evento. Ej: `debt`, `budget_plan` |
| `reference_id` | UUID NULL | ID de la entidad |
| `created_at` | TIMESTAMPTZ | |

**Índice:** `(user_id, created_at DESC)` — para listar logros recientes del usuario.

---

### 4.3 `user_gamification_stats`

Cache 1:1 con `app_user`. Evita sumar todos los `gamification_events` en cada consulta del home.

| Columna | Tipo | Notas |
|---------|------|-------|
| `user_id` | UUID PK FK → app_user | |
| `total_points` | INT | Suma acumulada de todos los eventos |
| `level` | INT | Nivel calculado según `total_points` |
| `last_computed_at` | TIMESTAMPTZ | Última vez que el job actualizó el cache |

---

### 4.4 `user_score_history`

Historial de puntos por período (mes). Permite mostrar el gráfico de evolución de nivel.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `period_start` | DATE | Primer día del período |
| `period_end` | DATE | Último día del período |
| `points` | INT | Puntos acumulados en ese período |
| `level` | INT | Nivel al cierre del período |
| `created_at` | TIMESTAMPTZ | |

**Índice:** `(user_id, period_start DESC)`

---

### 4.5 `message_rule`

Catálogo de reglas de recomendación. Define qué mensaje mostrar, en qué pantalla y con qué prioridad.

| Columna | Tipo | Notas |
|---------|------|-------|
| `message_rule_id` | UUID PK | |
| `code` | VARCHAR(80) UNIQUE | Ej: `leaks_detected`, `pay_next`, `debt_idle`, `budget_overrun` |
| `name_es` | VARCHAR(150) | Nombre del mensaje en español |
| `description_es` | TEXT NULL | Explicación interna |
| `context` | VARCHAR(20) NULL | `home`, `budget`, `debt`, `payments`, `profile`, `global` |
| `deep_link` | TEXT NULL | Ruta de acción en la app al tocar el mensaje |
| `priority` | SMALLINT | 1 (más urgente) a 5 (informativo). Default: 3 |
| `is_active` | BOOLEAN | |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

---

### 4.6 `message_event`

Instancia de un mensaje generado para un usuario específico. Un job de análisis crea estos registros cuando detecta condiciones (ej: presupuesto superado, deuda sin movimiento).

| Columna | Tipo | Notas |
|---------|------|-------|
| `message_event_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `message_rule_id` | UUID FK → message_rule | |
| `context_period_month` | DATE NULL | Mes al que aplica (si el mensaje es mensual) |
| `payload` | JSONB | Evidencia/valores contextuales. Ej: `{ "overrun_pct": 120, "category": "Alimentación" }` |
| `message_event_status_id` | BIGINT FK → status | Dominio: `message_event`. Estados: `created`, `shown`, `suppressed` |
| `shown_at` | TIMESTAMPTZ NULL | Cuándo se mostró al usuario |
| `suppressed_until` | TIMESTAMPTZ NULL | No volver a mostrar hasta esta fecha |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

**Índice:** `(user_id, message_event_status_id, created_at DESC)`

---

### 4.7 `user_message_interaction`

Registra cómo respondió el usuario a cada mensaje. Alimenta el algoritmo de supresión y frecuencia.

| Columna | Tipo | Notas |
|---------|------|-------|
| `interaction_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `message_event_id` | UUID FK → message_event | |
| `action` | VARCHAR(20) | `opened`, `dismissed`, `snoozed`, `completed` |
| `action_at` | TIMESTAMPTZ | |
| `note` | TEXT NULL | Nota interna opcional |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

---

### 4.8 `user_month_diagnosis_summary` *(Read model)*

Snapshot mensual del estado financiero del usuario. Es el dato principal del semáforo del home.

| Columna | Tipo | Notas |
|---------|------|-------|
| `user_id` + `month` | PK compuesta | `month` = primer día del mes |
| `traffic_light_status` | VARCHAR(6) | `green`, `yellow`, `red` |
| `traffic_light_reason_codes` | TEXT[] | Códigos que justifican el color del semáforo |
| `visible_savings_capacity_amount` | NUMERIC(19,4) | Capacidad de ahorro visible del mes |
| `visible_savings_capacity_pct` | NUMERIC(10,4) NULL | En porcentaje sobre el ingreso |
| `uncategorized_movements_count` | INTEGER | Movimientos sin categoría (calidad de datos) |
| `data_quality_level` | VARCHAR(6) | `high`, `medium`, `low` |
| `data_source_mix` | VARCHAR(8) | `document`, `manual`, `both` |
| `next_action_type` | VARCHAR(15) NULL | `pay`, `debt`, `budget`, `categorize`, `import` |
| `next_action_ref_id` | UUID NULL | ID de la entidad relacionada con la acción sugerida |
| `rule_version` | VARCHAR(50) | Versión del algoritmo de cálculo |
| `source_watermark_at` | TIMESTAMPTZ | Timestamp del movimiento más reciente considerado |
| `computed_at` | TIMESTAMPTZ | Última vez que el job recalculó |

---

### 4.9 `user_month_debt_priority_summary` *(Read model)*

Ranking de deudas del mes según la Bola de Nieve. Una fila por deuda activa por mes.

| Columna | Tipo | Notas |
|---------|------|-------|
| `user_id` + `month` + `debt_id` | PK compuesta | |
| `priority_rank` | INTEGER | Orden en la lista (1 = mayor prioridad) |
| `priority_score` | NUMERIC(10,4) | Score numérico del algoritmo |
| `min_payment_amount` | NUMERIC(19,4) | Pago mínimo calculado |
| `estimated_payoff_date` | DATE NULL | Fecha estimada de liquidación |
| `released_cashflow_amount` | NUMERIC(19,4) NULL | Liquidez que se liberará al cerrar esta deuda |
| `rule_version` | VARCHAR(50) | |
| `source_watermark_at` | TIMESTAMPTZ | |

---

### 4.10 `user_upcoming_payments_summary` *(Read model)*

Pagos próximos del usuario en una ventana de fechas. Alimenta el bloque "Próximos vencimientos" del home.

| Columna | Tipo | Notas |
|---------|------|-------|
| `user_id` + `window_start` + `window_end` + `user_payment_id` | PK compuesta | |
| `due_date` | DATE | Fecha de vencimiento |
| `amount` | NUMERIC(19,4) | Monto |
| `user_payment_status_id` | BIGINT FK → status | Estado del pago |
| `rule_version` | VARCHAR(50) | |
| `source_watermark_at` | TIMESTAMPTZ | |

---

### 4.11 `user_month_leaks_summary` *(Read model)*

Fugas de liquidez del mes: gastos hormiga y categorías drenantes. Alimenta el gráfico de categorías del home.

| Columna | Tipo | Notas |
|---------|------|-------|
| `user_id` + `month` | PK compuesta | |
| `leaks_total_amount` | NUMERIC(19,4) | Total de fugas del mes |
| `leaks_count` | INTEGER | Cantidad de movimientos identificados como fuga |
| `ant_expense_total` | NUMERIC(19,4) | Subtotal de gastos hormiga |
| `top_categories` | JSONB NULL | Top categorías drenantes. Ej: `[{"category":"Delivery","amount":45000}]` |
| `rule_version` | VARCHAR(50) | |
| `source_watermark_at` | TIMESTAMPTZ | |

---

## 5. Vistas del módulo (Layer 19)

| Vista | Qué resuelve |
|-------|-------------|
| `v_user_home_month` | Consolida `user_month_diagnosis_summary` + `user_month_debt_priority_summary` + `user_upcoming_payments_summary` + `user_month_leaks_summary` en un único payload para el home |
| `v_user_access` | Determina si el usuario tiene acceso activo (suscripción, trial o ninguno) |
| `v_user_current_subscription` | Suscripción vigente del usuario |
| `v_subscription_effective_state` | Estado efectivo de la suscripción considerando fechas de inicio/fin |

---

## 6. Triggers del módulo

| Trigger | Tabla | Evento |
|---------|-------|--------|
| `trg_message_rule_updated_at` | `message_rule` | BEFORE UPDATE |
| `trg_message_event_updated_at` | `message_event` | BEFORE UPDATE |
| `trg_message_event_status_domain` | `message_event` | BEFORE INSERT OR UPDATE — valida dominio `message_event` |
| `trg_user_message_interaction_updated_at` | `user_message_interaction` | BEFORE UPDATE |
| `trg_user_month_diagnosis_summary_updated_at` | `user_month_diagnosis_summary` | BEFORE UPDATE |
| `trg_user_month_debt_priority_summary_updated_at` | `user_month_debt_priority_summary` | BEFORE UPDATE |
| `trg_user_upcoming_payments_summary_updated_at` | `user_upcoming_payments_summary` | BEFORE UPDATE |
| `trg_user_month_leaks_summary_updated_at` | `user_month_leaks_summary` | BEFORE UPDATE |

---

## 7. Patrón CQRS — cómo se actualizan los read models

Los 4 read models (`*_summary`) **no los escribe el usuario** — los actualiza un job de backend:

```
Usuario abre el home
        │
        ▼
Backend consulta read models (lectura instantánea)
        │
        ▼ (en paralelo, job periódico)
Job detecta cambios en movimientos/pagos/deudas
        │
        ▼
Job recalcula y hace UPSERT en los 4 _summary
        │
        ▼
Próxima apertura del home ya tiene datos frescos
```

`source_watermark_at` es el timestamp del evento más reciente considerado en el cálculo. El job lo compara con el watermark anterior para saber si necesita recalcular.

---

## 8. Relaciones con otros módulos

| Módulo origen | Tabla que alimenta el read model |
|---------------|----------------------------------|
| Módulo 1 — Auth | `app_user` (FK base en todas las tablas) |
| Módulo 4 — Motor de Deudas | `debt`, `debt_schedules` → `user_month_debt_priority_summary` |
| Módulo 5 — Ingesta y Movimientos | `financial_movement`, `budget_plan` → `user_month_diagnosis_summary`, `user_month_leaks_summary` |
| Módulo 6 — Pagos | `user_payment` → `user_upcoming_payments_summary` |
