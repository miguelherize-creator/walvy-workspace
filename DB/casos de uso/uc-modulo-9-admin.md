# Casos de Uso — Módulo 9: Administración (Backoffice)

**Tablas involucradas:** `admin_users`, `app_config`, `gamification_rules`, `faq_articles`, `admin_audit_log`, `report_snapshots`

---

## Actores

| Actor | Descripción |
|-------|-------------|
| **super_admin** | Acceso total al backoffice: gestiona admins, config, reportes |
| **operator** | Acceso limitado: edita config permitida, FAQ, gamificación |
| **Sistema (job)** | Genera reportes pre-computados periódicamente |

> El backoffice es una aplicación **completamente separada** del frontend de usuarios. Tiene su propio JWT y su propia ruta de autenticación. Los `admin_users` nunca comparten tabla con `users`.

---

## UC-01: Login de administrador

**Actor:** super_admin / operator
**Precondición:** Cuenta de admin creada por un super_admin

```mermaid
sequenceDiagram
    actor A as Admin
    participant BO as Backoffice (web)
    participant BE as Backend (NestJS)
    participant DB as PostgreSQL

    A->>BO: Abre backoffice.walvy.app/login
    A->>BO: Ingresa email + contraseña admin
    BO->>BE: POST /admin/auth/login { email, password }
    BE->>DB: SELECT * FROM admin_users\nWHERE email=$1 AND is_active=true
    DB-->>BE: admin { id, role, password_hash }
    BE->>BE: bcrypt.compare(password, hash)
    alt Contraseña incorrecta o cuenta inactiva
        BE-->>BO: 401 "Credenciales inválidas"
    else Login correcto
        BE->>DB: UPDATE admin_users SET last_login_at=NOW() WHERE id=$1
        BE->>BE: genera admin_access_token (JWT con sub=admin_id, role)
        BE-->>BO: 200 { access_token, admin: { id, email, role } }
        BO->>BO: Guarda token en memoria de sesión
        BO->>A: Redirige a /dashboard
    end
```

### Diferencia con el JWT de usuarios

| Aspecto | JWT usuario | JWT admin |
|---------|------------|-----------|
| `sub` | `users.id` | `admin_users.id` |
| `role` | no incluido | `super_admin` / `operator` |
| Guard | `JwtAuthGuard` | `AdminJwtGuard` |
| Expira en | 15 minutos | 8 horas (sesión de trabajo) |

---

## UC-02: Cambiar parámetro de configuración del sistema

**Actor:** super_admin o operator (solo claves permitidas)
**Precondición:** Admin autenticado

```mermaid
sequenceDiagram
    actor A as Admin
    participant BO as Backoffice
    participant BE as Backend
    participant DB as PostgreSQL

    A->>BO: Abre "Configuración del sistema"
    BO->>BE: GET /admin/config
    BE->>DB: SELECT key, value, description FROM app_config ORDER BY key
    DB-->>BE: lista de parámetros
    BE-->>BO: 200 { config: [...] }
    BO->>A: Tabla de configuración con valores actuales

    A->>BO: Cambia 'budget.threshold.yellow_pct' de 80 a 75
    BO->>BE: PATCH /admin/config { key: 'budget.threshold.yellow_pct', value: 75 }

    BE->>BE: Verifica rol del admin
    alt Operator intentando cambiar clave restringida
        BE-->>BO: 403 "No tienes permisos para esta clave"
    else super_admin o clave permitida para operator
        BE->>DB: SELECT value FROM app_config WHERE key=$1
        DB-->>BE: { value: 80 } (valor anterior)
        BE->>DB: UPDATE app_config SET value=75, updated_by_admin_id=$admin_id WHERE key=$1
        BE->>DB: INSERT INTO admin_audit_log (\n  admin_id,\n  action='CONFIG_CHANGE',\n  entity='app_config',\n  entity_key='budget.threshold.yellow_pct',\n  before_data={value:80},\n  after_data={value:75}\n)
        DB-->>BE: OK
        BE-->>BO: 200 { updated: true }
        BO->>A: Muestra "Configuración actualizada" con registro del cambio
    end
```

### Claves de `app_config` y permisos de rol

| Clave | super_admin | operator |
|-------|-------------|---------|
| `budget.threshold.yellow_pct` | ✅ | ✅ |
| `budget.threshold.red_pct` | ✅ | ✅ |
| `ant_expense.default_max` | ✅ | ✅ |
| `gamification.level_thresholds` | ✅ | ❌ |
| `gamification.enabled` | ✅ | ❌ |
| `recommendation.rules` | ✅ | ❌ |
| `payment_reminder.days_before` | ✅ | ✅ |
| `snowball.default_extra_payment` | ✅ | ✅ |

---

## UC-03: Editar reglas de gamificación

**Actor:** super_admin o operator
**Precondición:** Admin autenticado

```mermaid
sequenceDiagram
    actor A as Admin
    participant BO as Backoffice
    participant BE as Backend
    participant DB as PostgreSQL

    A->>BO: Abre "Gamificación → Puntos por evento"
    BO->>BE: GET /admin/gamification-rules
    BE->>DB: SELECT event_type, points, label, is_active\nFROM gamification_rules\nORDER BY event_type
    DB-->>BE: lista de reglas
    BE-->>BO: 200 { rules }
    BO->>A: Tabla con todos los eventos y sus puntos

    A->>BO: Cambia 'pay_on_time' de 20 a 25 puntos
    BO->>BE: PATCH /admin/gamification-rules/pay_on_time { points: 25 }
    BE->>DB: SELECT points FROM gamification_rules WHERE event_type='pay_on_time'
    DB-->>BE: { points: 20 }
    BE->>DB: UPDATE gamification_rules\nSET points=25, updated_by_admin_id=$1\nWHERE event_type='pay_on_time'
    BE->>DB: INSERT INTO admin_audit_log (\n  admin_id, action='UPDATE',\n  entity='gamification_rules',\n  entity_key='pay_on_time',\n  before_data={points:20}, after_data={points:25}\n)
    BE-->>BO: 200
    BO->>A: "Regla actualizada. Los próximos pagos a tiempo darán 25 pts."

    A->>BO: Desactiva temporalmente el evento 'stay_under_budget'
    BO->>BE: PATCH /admin/gamification-rules/stay_under_budget { is_active: false }
    BE->>DB: UPDATE gamification_rules SET is_active=false WHERE event_type='stay_under_budget'
    BE->>DB: INSERT INTO admin_audit_log (action='UPDATE', ...)
    BE-->>BO: 200
```

---

## UC-04: Gestionar artículos FAQ

**Actor:** super_admin o operator
**Precondición:** Admin autenticado

```mermaid
sequenceDiagram
    actor A as Admin
    participant BO as Backoffice
    participant BE as Backend
    participant DB as PostgreSQL

    A->>BO: Click "Nuevo artículo FAQ"
    A->>BO: Llena: título, slug, body (markdown), tags, locale
    BO->>BE: POST /admin/faq {\n  title: '¿Cómo funciona la Bola de Nieve?',\n  slug: 'bola-de-nieve',\n  body: '## Explicación...',\n  tags: ['deuda', 'bola_de_nieve', 'simulador'],\n  locale: 'es-CL',\n  is_active: false\n}
    BE->>DB: SELECT COUNT(*) FROM faq_articles WHERE slug=$1
    alt Slug ya existe
        BE-->>BO: 409 "Slug ya en uso"
    else Slug disponible
        BE->>DB: INSERT INTO faq_articles (\n  title, slug, body, tags, locale, is_active=false\n)
        BE->>DB: INSERT INTO admin_audit_log (action='CREATE', entity='faq_articles')
        BE-->>BO: 201 { article }
        BO->>A: Artículo creado en borrador (is_active=false)
    end

    A->>BO: Publica el artículo (toggle is_active)
    BO->>BE: PATCH /admin/faq/:id { is_active: true }
    BE->>DB: UPDATE faq_articles SET is_active=true WHERE id=$1
    BE->>DB: INSERT INTO admin_audit_log (action='UPDATE', before={is_active:false}, after={is_active:true})
    BE-->>BO: 200
    BO->>A: "Artículo publicado — ya visible para el asistente IA"
```

---

## UC-05: Ver y generar reportes del sistema

**Actor:** super_admin o operator
**Precondición:** Admin autenticado

```mermaid
sequenceDiagram
    actor A as Admin
    participant BO as Backoffice
    participant BE as Backend
    participant DB as PostgreSQL

    A->>BO: Abre "Reportes → Activación de usuarios"
    BO->>BE: GET /admin/reports/user_activation
    BE->>DB: SELECT * FROM report_snapshots\nWHERE report_type='user_activation'\nORDER BY generated_at DESC LIMIT 1
    DB-->>BE: snapshot { payload, generated_at }
    BE-->>BO: 200 {\n  report_type: 'user_activation',\n  generated_at: '2026-04-14T00:01:00Z',\n  data: {\n    total_registered: 245,\n    completed_onboarding: 198,\n    with_financial_profile: 180,\n    with_goals: 142,\n    activation_rate_pct: 80.8\n  }\n}
    BO->>A: Muestra métricas en cards y gráficos\nSin exponer PII individual

    A->>BO: Click "Regenerar reporte ahora"
    BO->>BE: POST /admin/reports/user_activation/generate
    BE->>DB: SELECT COUNT(*) as total FROM users
    BE->>DB: SELECT COUNT(*) as completed FROM onboarding_state WHERE completed_at IS NOT NULL
    BE->>DB: SELECT COUNT(*) as with_profile FROM user_financial_profile
    BE->>DB: SELECT COUNT(*) as with_goals FROM users WHERE id IN (SELECT DISTINCT user_id FROM user_goals WHERE is_active=true)
    DB-->>BE: métricas
    BE->>DB: INSERT INTO report_snapshots (\n  report_type='user_activation',\n  generated_by_admin_id=$1,\n  period_start=date_trunc('month', NOW()),\n  period_end=NOW(),\n  payload={total_registered, completed_onboarding, ...}\n)
    BE-->>BO: 200 { report: { ...updated_data } }
    BO->>A: "Reporte actualizado" con timestamp
```

### Tipos de reportes disponibles

| `report_type` | Qué mide | Tablas de origen |
|---------------|---------|-----------------|
| `user_activation` | Funnel de onboarding: registro → perfil → metas | `users`, `onboarding_state`, `user_financial_profile`, `user_goals` |
| `usage_summary` | Transacciones, deudas y presupuestos del período | `transactions`, `debts`, `budget_periods` |
| `debt_overview` | Deuda total del sistema, distribución por tipo | `debts` |
| `budget_compliance` | % de usuarios dentro de presupuesto | `budget_lines`, `transactions` |

---

## UC-06: Crear nuevo admin (solo super_admin)

**Actor:** super_admin
**Precondición:** Autenticado como super_admin

```mermaid
sequenceDiagram
    actor SA as super_admin
    participant BO as Backoffice
    participant BE as Backend
    participant DB as PostgreSQL

    SA->>BO: Abre "Administradores → Nuevo admin"
    SA->>BO: Llena: email, contraseña temporal, rol (operator)
    BO->>BE: POST /admin/users { email, password, role: 'operator' }

    BE->>BE: Verifica que el JWT tiene role='super_admin'
    alt Intento de operator creando admin
        BE-->>BO: 403 "Solo super_admin puede crear administradores"
    else Es super_admin
        BE->>DB: SELECT COUNT(*) FROM admin_users WHERE email=$1
        alt Email ya existe
            BE-->>BO: 409 "Email ya registrado en el sistema admin"
        else
            BE->>BE: bcrypt.hash(password)
            BE->>DB: INSERT INTO admin_users (email, password_hash, role='operator', is_active=true)
            DB-->>BE: admin { id }
            BE->>DB: INSERT INTO admin_audit_log (\n  admin_id=$super_admin_id,\n  action='CREATE',\n  entity='admin_users',\n  entity_id=$new_admin_id\n)
            BE-->>BO: 201 { admin: { id, email, role } }
            BO->>SA: "Operador creado. Comparte las credenciales de forma segura."
        end
    end
```

---

## UC-07: Ver log de auditoría

**Actor:** super_admin o operator (solo lectura)

```mermaid
sequenceDiagram
    actor A as Admin
    participant BO as Backoffice
    participant BE as Backend
    participant DB as PostgreSQL

    A->>BO: Abre "Auditoría"
    A->>BO: Filtra por: admin Miguel, entidad 'app_config', última semana
    BO->>BE: GET /admin/audit-log?admin_id=:id&entity=app_config&days=7
    BE->>DB: SELECT al.*, au.email as admin_email\nFROM admin_audit_log al\nJOIN admin_users au ON al.admin_id=au.id\nWHERE al.admin_id=$1\nAND al.entity='app_config'\nAND al.created_at >= NOW()-INTERVAL '7 days'\nORDER BY al.created_at DESC
    DB-->>BE: registros de auditoría
    BE-->>BO: 200 { logs: [{\n  admin_email, action, entity,\n  before_data, after_data, created_at\n}] }
    BO->>A: Tabla de cambios con antes/después
```

---

## Diagrama de relación entre tablas — M9

```mermaid
erDiagram
    admin_users {
        uuid id PK
        varchar email UK
        varchar password_hash
        varchar role
        boolean is_active
        timestamp last_login_at
    }
    app_config {
        uuid id PK
        varchar key UK
        jsonb value
        text description
        uuid updated_by_admin_id FK
    }
    gamification_rules {
        uuid id PK
        varchar event_type UK
        int points
        text label
        boolean is_active
        uuid updated_by_admin_id FK
    }
    faq_articles {
        uuid id PK
        varchar slug UK
        text title
        text body
        text[] tags
        varchar locale
        boolean is_active
    }
    admin_audit_log {
        uuid id PK
        uuid admin_id FK
        varchar action
        varchar entity
        uuid entity_id
        varchar entity_key
        jsonb before_data
        jsonb after_data
        timestamp created_at
    }
    report_snapshots {
        uuid id PK
        varchar report_type
        date period_start
        date period_end
        jsonb payload
        uuid generated_by_admin_id FK
        timestamp generated_at
    }

    app_config }o--|| admin_users : "actualizado por"
    gamification_rules }o--|| admin_users : "actualizado por"
    admin_audit_log }o--|| admin_users : "registra acciones de"
    report_snapshots }o--|| admin_users : "generado por"
```
