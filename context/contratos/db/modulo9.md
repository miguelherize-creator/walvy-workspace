# M9 — Administración y Auditoría

**Layer:** 17 (Administración)  
**Estado:** 📋 Referencia — abierto a cambios  
**Docs originales:** `legacy/DB_v2/documentacion/modulo9/`

---

## Propósito
Backoffice de administración: operadores y super-admins gestionan reglas de gamificación, mensajería, catálogos e instituciones. Logs de auditoría para operaciones de admin y usuarios de alto impacto.

---

## Tablas

### `admin_users`
Separado de `app_user` por seguridad.

| Columna | Notas |
|---------|-------|
| `id` UUID PK | |
| `email` TEXT UNIQUE | |
| `password_hash` TEXT | Bcrypt |
| `role` VARCHAR(15) | `super_admin` (acceso total) · `operator` (lectura/edición catálogos) |
| `is_active` BOOLEAN | Desactivar sin borrar |

### `admin_audit_log`
Log inmutable de acciones de backoffice.

| Columna | Notas |
|---------|-------|
| `admin_id` UUID NULL FK → admin_users | NULL = acción automática del sistema |
| `action` TEXT | `UPDATE_GAMIFICATION_RULE`, `DEACTIVATE_USER` |
| `entity` TEXT | Tabla afectada |
| `entity_id` UUID NULL | |
| `before_data` / `after_data` JSONB NULL | Estado antes y después |

**Índices:**
- `(admin_id, created_at DESC)`
- `(entity, entity_id)` — para auditar cambios sobre un registro

### `audit_log`
Acciones de alto impacto de usuarios finales.

| Columna | Notas |
|---------|-------|
| `user_id` UUID NULL FK → app_user | |
| `action` TEXT | `DELETE_DEBT`, `CHANGE_NOTIFICATION_EMAIL` |
| `diff` JSONB NULL | Cambios realizados |

**Índice:** `(user_id, created_at DESC)`

### `report_snapshots`
Reportes pre-computados para métricas de backoffice.

| Columna | Notas |
|---------|-------|
| `report_type` TEXT | `dau`, `revenue`, `churn`, `health_distribution` |
| `period` DATE | Período del reporte |
| `data` JSONB | Métricas calculadas |
| `generated_at` TIMESTAMPTZ | |

---

## Notas de diseño
- `admin_users` nunca referencia `app_user` — son sistemas separados
- `admin_audit_log` es append-only — nunca se modifica ni se borra
- Relacionado con deuda técnica M1-DT-01 (AdminModule vacío en backend)
