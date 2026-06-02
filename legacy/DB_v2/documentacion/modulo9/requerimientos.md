# Módulo 9 — Requerimientos

**Módulo:** Administración y Auditoría  
**Layer:** 17  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 9

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Login de administrador | ✅ Incluido |
| Gestionar reglas de gamificación | ✅ Incluido |
| Gestionar reglas de mensajería | ✅ Incluido |
| Gestionar catálogo de instituciones | ✅ Incluido |
| Ver logs de auditoría | ✅ Incluido |
| Gestionar artículos FAQ | ✅ Incluido |
| Reportes de backoffice (snapshots) | ✅ Incluido |
| Gestión de roles RBAC granular | ❌ No incluido en MVP (solo super_admin/operator) |
| Dashboard analítico en tiempo real | ❌ No incluido en MVP |

---

## Requerimientos Funcionales

### RF-01 — Autenticación de administrador

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Login de backoffice |
| **Descripción** | El administrador se autentica con email y contraseña. |
| **Reglas** | - Flujo de autenticación separado del de usuarios finales (`app_user`). - JWT de backoffice con claims de `role` (`super_admin`/`operator`). - `last_login_at` se actualiza en cada login. - Bloqueo automático tras N intentos fallidos. |

---

### RF-02 — Gestionar reglas de gamificación

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | CRUD de reglas de gamificación |
| **Descripción** | El administrador puede crear, editar y desactivar reglas de puntos. |
| **Reglas** | - INSERT/UPDATE en `gamification_rules`. - `updated_by_admin_id` se registra en cada cambio. - INSERT en `admin_audit_log` con before/after. - Los cambios aplican a eventos nuevos; no son retroactivos. |

---

### RF-03 — Gestionar reglas de mensajería

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | CRUD de reglas de recomendación |
| **Descripción** | El administrador gestiona las reglas de mensajería contextual sin necesidad de deploy. |
| **Reglas** | - INSERT/UPDATE en `message_rule`. - `is_active` toggle sin borrar la regla. - INSERT en `admin_audit_log`. |

---

### RF-04 — Ver logs de auditoría

| Campo | Detalle |
|-------|---------|
| **ID** | RF-04 |
| **Nombre** | Consultar auditoría |
| **Descripción** | El super_admin puede ver qué cambios hicieron los operadores y qué acciones tomaron los usuarios. |
| **Reglas** | - Lee `admin_audit_log` y `audit_log`. - Filtros: por `admin_id`, `entity`, rango de fechas. - Solo lectura — no se puede modificar ni borrar. |

---

## Requerimientos No Funcionales

### RNF-01 — Logs inmutables
`admin_audit_log` y `audit_log` no tienen UPDATE ni DELETE. Son append-only.

### RNF-02 — Separación auth
El JWT de backoffice usa un secreto diferente al de la app de usuarios. No puede usarse intercambiadamente.

### RNF-03 — Reportes sin impacto operacional
`report_snapshots` desacopla los reportes de las tablas operacionales. Los admins no ejecutan queries de agregación directamente; leen snapshots pre-calculados.
