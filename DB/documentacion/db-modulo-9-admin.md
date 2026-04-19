# DB — Módulo 9: Administración

## Tablas propias (escribe principalmente)

| Tabla | Rol |
|-------|-----|
| `admin_users` | Cuentas del backoffice |
| `app_config` | Parámetros globales ajustables |
| `gamification_rules` | Puntos por evento — configurable |
| `faq_articles` | Contenido de preguntas frecuentes |
| `admin_audit_log` | Registro inmutable de acciones del admin |
| `report_snapshots` | Reportes pre-computados para el backoffice |

## Tablas que solo lee (para reportes)

| Tabla | Reporte |
|-------|---------|
| `users` | Total de usuarios, tasa de activación |
| `onboarding_state` | Funnel de onboarding |
| `debts` | Deuda promedio, distribución por tipo |
| `transactions` | Volumen de movimientos |
| `budget_lines` + `transactions` | Cumplimiento de presupuesto |
| `gamification_events` | Actividad de gamificación |
| `ai_conversations` | Uso del asistente |

---

## Detalle por tabla

### `admin_users`
**SEPARADO de `users`** — roles de usuarios finales y admins nunca se mezclan.

| Campo | Qué hace |
|-------|----------|
| `role` | `super_admin` (acceso total) \| `operator` (lectura + config acotada) |
| `is_active` | Desactivar acceso sin eliminar la cuenta |
| `last_login_at` | Auditoría de uso del backoffice |

**Operaciones permitidas por rol:**

| Acción | super_admin | operator |
|--------|-------------|----------|
| Ver reportes | ✅ | ✅ |
| Editar `app_config` | ✅ | ✅ (claves permitidas) |
| Editar `gamification_rules` | ✅ | ✅ |
| Crear/editar `faq_articles` | ✅ | ✅ |
| Crear otros `admin_users` | ✅ | ❌ |
| Ver `admin_audit_log` | ✅ | ✅ (solo lectura) |

---

### `app_config`
Tabla `key-value` que centraliza los parámetros del sistema. Clave → JSON value.

**Claves definidas para MVP:**

| Clave | Valor ejemplo | Qué controla |
|-------|---------------|--------------|
| `budget.threshold.yellow_pct` | `80` | Umbral amarillo del presupuesto (M6) |
| `budget.threshold.red_pct` | `100` | Umbral rojo del presupuesto (M6) |
| `ant_expense.default_max` | `5000` | Monto máximo gasto hormiga por defecto (M6) |
| `gamification.level_thresholds` | `[0,100,300,600,1000]` | Puntos necesarios para cada nivel (M3) |
| `gamification.enabled` | `true` | Activar/desactivar gamificación globalmente (M3) |
| `recommendation.rules` | `{…}` | Reglas del motor de recomendaciones (M8) |
| `traffic_light.criteria` | `{…}` | Criterios del semáforo financiero (M3) |
| `payment_reminder.days_before` | `[7,3,1]` | Cuándo enviar recordatorio de pago (M7) |
| `snowball.default_extra_payment` | `0` | Sugerencia inicial de pago extra (M4) |

**Cada cambio en `app_config`** genera automáticamente un registro en `admin_audit_log`.

---

### `gamification_rules`
Configura cuántos puntos otorga cada tipo de evento.

| Campo | Qué hace |
|-------|----------|
| `event_type` | Clave única del evento (ej: `"pay_on_time"`) |
| `points` | Puntos a otorgar |
| `label` | Texto visible al usuario en la notificación de logro |
| `is_active` | Desactivar una regla sin eliminarla |

**Eventos configurables MVP:**

| event_type | points sugeridos | label |
|------------|-----------------|-------|
| `register_transaction` | 5 | Registraste un movimiento |
| `pay_on_time` | 20 | Pagaste a tiempo |
| `stay_under_budget` | 30 | ¡Mes bajo presupuesto! |
| `register_debt` | 10 | Registraste una deuda |
| `debt_paid` | 50 | ¡Deuda saldada! |
| `complete_onboarding` | 25 | Completaste el onboarding |

---

### `report_snapshots`
Reportes pre-computados — generados por job periódico o bajo demanda.

| `report_type` | Qué mide |
|---------------|---------|
| `user_activation` | Usuarios registrados, con perfil completo, con metas |
| `usage_summary` | Transacciones, deudas, presupuestos activos en el período |
| `debt_overview` | Deuda total del sistema, distribución por tipo |
| `budget_compliance` | % de usuarios dentro de presupuesto por categoría |

**Estructura del `payload` (ejemplo `user_activation`):**
```json
{
  "total_registered": 245,
  "completed_onboarding": 198,
  "with_financial_profile": 180,
  "with_goals": 142,
  "activation_rate_pct": 80.8
}
```

---

### `admin_audit_log`
Registro inmutable de toda acción del admin. Se inserta en cada operación de escritura.

| Campo | Qué hace |
|-------|----------|
| `action` | `"CREATE"` \| `"UPDATE"` \| `"DELETE"` \| `"CONFIG_CHANGE"` |
| `entity` | Nombre de la tabla modificada |
| `before_data` / `after_data` | Estado anterior y posterior del registro |

**Cuándo se genera automáticamente:**
- Al modificar cualquier clave en `app_config`
- Al cambiar `gamification_rules.points` o `is_active`
- Al crear/desactivar `admin_users`
- Al publicar/despublicar `faq_articles`

---

## Flujos de datos principales

```
CREAR ADMIN
  → INSERT admin_users (role, is_active=true)
  → INSERT admin_audit_log (action='CREATE', entity='admin_users')

CAMBIAR CONFIGURACIÓN
  → UPDATE app_config.value
  → INSERT admin_audit_log (action='CONFIG_CHANGE', before_data, after_data)

AJUSTAR PUNTOS DE GAMIFICACIÓN
  → UPDATE gamification_rules.points
  → INSERT admin_audit_log

GENERAR REPORTE
  → [job] SELECT + aggregate desde tablas de datos
  → INSERT report_snapshots

VER MÉTRICAS EN BACKOFFICE
  → SELECT report_snapshots WHERE report_type = ? ORDER BY generated_at DESC LIMIT 1
```

---

## Índices críticos

| Tabla | Índice | Motivo |
|-------|--------|--------|
| `admin_users` | `email` (UNIQUE) | Login al backoffice |
| `admin_audit_log` | `(admin_id, created_at DESC)` | Ver historial de un admin |
| `admin_audit_log` | `(entity, entity_id)` | Ver cambios sobre un registro específico |
| `report_snapshots` | `(report_type, generated_at DESC)` | Último reporte de cada tipo |
| `gamification_rules` | `event_type` (UNIQUE) | Lookup por evento |

---

## Separación de entornos

El backoffice debe ser una aplicación o ruta **completamente separada** del frontend de usuarios finales:
- Autenticación independiente (`admin_users` ≠ `users`)
- Endpoints protegidos con middleware de rol de admin
- Las vistas de reportes NO exponen datos PII individuales — solo agregados
