# M2 — Perfil y Configuración

**Layer:** 6 (Perfil de usuario y alertas)  
**Estado:** ✅ Producción (schema) · ⚠️ Endpoints parciales (ver M2-DT-01, M2-DT-04)  
**Docs completos:** `back-walvy/DB/modulo2/`

---

## Dependencias

```
app_user (M1) ──► user_financial_profile
app_user (M1) ──► user_goals
app_user (M1) ──► alert_preferences ──► notification_queue
currency (M1) ──► user_financial_profile
```

---

## Tablas

### `user_financial_profile`
PK = `user_id` (1:1 con app_user, sin UUID propio)

| Columna | Tipo | Notas |
|---------|------|-------|
| `user_id` | UUID PK FK → app_user | |
| `monthly_income_estimate` | NUMERIC(19,4) NULL | Ingreso mensual declarado |
| `stable_expenses_note` | TEXT NULL | Nota libre sobre gastos fijos |
| `estimated_payment_capacity` | NUMERIC(19,4) NULL | **Calculado** por backend: ingreso − gastos fijos. Alimenta M4 (Bola de Nieve) |
| `currency_id` | BIGINT FK → currency NULL | |
| `updated_at` | TIMESTAMPTZ | Sin `created_at` propio |

> ⚠️ **M2-DT-01:** Endpoints `GET/PUT /profile/financial` pendientes — bloquea M1-DT-04 (onboarding nunca cierra)

---

### `user_goals`
Metas financieras. Un usuario puede tener múltiples activas simultáneamente.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK | |
| `goal_type` | VARCHAR(40) | `reduce_debt`, `save_amount`, `improve_savings_capacity`, `avoid_late_payments`, `meet_budget`, `other` |
| `target_value` | NUMERIC(19,4) NULL | NULL para metas cualitativas |
| `progress_cache` | JSONB NULL | **Solo escritura de backend** (jobs). Nunca en DTOs de entrada |
| `is_active` | BOOLEAN | Desactivar sin borrar |

> ⚠️ **M2-DT-02:** Endpoints pendientes

---

### `alert_preferences`
Sobreescrituras del usuario sobre los defaults de `app_config`.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK | |
| `alert_type` | TEXT | `budget_threshold`, `payment_due`, `weekly_reminder` |
| `channel` | VARCHAR(10) | `in_app`, `push`, `email` |
| `enabled` | BOOLEAN | DEFAULT true |
| `intensity` | TEXT NULL | `low`, `medium`, `high` |
| `cadence_days` | INT NULL | Días entre recordatorios |
| UNIQUE | `(user_id, alert_type, channel)` | |

> ⚠️ **M2-DT-03:** Endpoints pendientes. Sin efecto real hasta M2-DT-04 (worker)

---

### `notification_queue`
Cola de notificaciones. El backend produce; un worker consume y despacha.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK | |
| `channel` | VARCHAR(10) | `in_app`, `push`, `email` |
| `payload` | JSONB | `{ title, body, deep_link }` |
| `scheduled_for` | TIMESTAMPTZ | Momento de despacho |
| `sent_at` | TIMESTAMPTZ NULL | NULL = pendiente |
| `reference_type` / `reference_id` | TEXT / UUID NULL | Entidad origen |

**Índice worker:** `WHERE sent_at IS NULL` sobre `scheduled_for`

> ⚠️ **M2-DT-04:** Worker no implementado. Bloqueado hasta definir canales push (FCM/APNs)

---

## Relaciones salientes
- `estimated_payment_capacity` → M4 (Bola de Nieve)
- `user_goals` → M3 (Home dashboard)
- `notification_queue` → producida por M5, M6, M7 al disparar eventos
