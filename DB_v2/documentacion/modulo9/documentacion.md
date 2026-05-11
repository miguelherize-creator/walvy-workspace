# Módulo 9 — Administración y Auditoría

**Layer cubierto:** 17 (Administración)  
**Corresponde a:** CSV Módulo 9 — Backoffice  
**Estado MVP:** ✅ Incluido

---

## 1. Propósito del módulo

El Módulo 9 cubre el **backoffice de administración** de Walvy: operadores y super-administradores que gestionan reglas de gamificación, reglas de mensajería, catálogos de instituciones, artículos de FAQ y configuración general. Incluye logs de auditoría para operaciones de admin y de usuarios.

---

## 2. Tablas del módulo

### 2.1 `admin_users`

Usuarios del backoffice de Walvy. Separado de `app_user` por razones de seguridad y separación de responsabilidades.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `email` | TEXT UNIQUE NOT NULL | |
| `password_hash` | TEXT NOT NULL | Bcrypt |
| `name` | TEXT NOT NULL | Nombre del operador |
| `role` | VARCHAR(15) | `super_admin`, `operator` |
| `is_active` | BOOLEAN DEFAULT true | Desactivar sin borrar |
| `last_login_at` | TIMESTAMPTZ NULL | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Roles:**
- `super_admin`: acceso total. Puede crear/desactivar otros admin_users.
- `operator`: acceso de lectura y edición de catálogos/reglas; no puede gestionar usuarios admin.

---

### 2.2 `admin_audit_log`

Log inmutable de todas las acciones realizadas por administradores en el backoffice.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `admin_id` | UUID NULL FK → admin_users | NULL si la acción fue automática (sistema) |
| `action` | TEXT NOT NULL | Ej: `UPDATE_GAMIFICATION_RULE`, `DEACTIVATE_USER` |
| `entity` | TEXT NOT NULL | Tabla/entidad afectada. Ej: `gamification_rules` |
| `entity_id` | UUID NULL | ID del registro afectado |
| `before_data` | JSONB NULL | Estado anterior |
| `after_data` | JSONB NULL | Estado posterior |
| `created_at` | TIMESTAMPTZ | |

**Índices:**
- `(admin_id, created_at DESC)`
- `(entity, entity_id)` — para auditar cambios sobre un registro específico

---

### 2.3 `audit_log`

Log de acciones relevantes de usuarios finales (no todas las operaciones — solo las de alto impacto).

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID NULL FK → app_user | |
| `action` | TEXT NOT NULL | Ej: `DELETE_DEBT`, `CHANGE_NOTIFICATION_EMAIL` |
| `entity` | TEXT NOT NULL | |
| `entity_id` | UUID NULL | |
| `diff` | JSONB NULL | Cambios realizados |
| `created_at` | TIMESTAMPTZ | |

**Índice:** `(user_id, created_at DESC)`

---

### 2.4 `report_snapshots`

Reportes pre-computados para el backoffice. Permite a los admins ver métricas sin impactar la BD operacional.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `report_type` | TEXT NOT NULL | Ej: `monthly_active_users`, `churn_rate`, `revenue_mrr` |
| `period_start` | DATE NOT NULL | |
| `period_end` | DATE NOT NULL | |
| `payload` | JSONB DEFAULT '{}' | Datos del reporte |
| `generated_at` | TIMESTAMPTZ | |
| `generated_by_admin_id` | UUID NULL FK → admin_users | |

**Índice:** `(report_type, period_start DESC)`

---

## 3. FKs diferidas (declaradas después de crear admin_users)

Tras crear `admin_users`, el schema añade:

```sql
ALTER TABLE app_config ADD CONSTRAINT fk_app_config_admin
  FOREIGN KEY (updated_by_admin_id) REFERENCES admin_users(id) ON DELETE SET NULL;

ALTER TABLE gamification_rules ADD CONSTRAINT fk_gr_admin
  FOREIGN KEY (updated_by_admin_id) REFERENCES admin_users(id) ON DELETE SET NULL;
```

---

## 4. Triggers del módulo

| Trigger | Tabla | Evento |
|---------|-------|--------|
| `trg_admin_users_updated_at` | `admin_users` | BEFORE UPDATE |

---

## 5. Relaciones con otros módulos

| Módulo | Relación |
|--------|----------|
| Módulo 1 — Auth | `audit_log.user_id` → `app_user` |
| Módulo 3 — Home | `admin_users.id` → `gamification_rules.updated_by_admin_id` |
| Módulo 8 — IA | Admins gestionan `faq_articles` desde el backoffice |
| Módulo 10 — Monetización | Admins pueden ver y gestionar subscripciones |

---

## 6. Notas de diseño

- **Separación admin/usuario:** `admin_users` y `app_user` son tablas completamente separadas. No existe un rol "admin" en `app_user`.
- **Logs inmutables:** `admin_audit_log` y `audit_log` nunca se modifican ni borran.
- **`report_snapshots`:** desacopla los reportes del backoffice de las tablas operacionales. Los jobs nocturnos calculan y persisten los reportes; los admins leen el snapshot, no ejecutan queries pesadas en tiempo real.
