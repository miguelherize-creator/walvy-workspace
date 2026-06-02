# ARCHITECTURE.md — Walvy System Map
> Mapa navegable del sistema completo. Objetivo: entender la arquitectura en 10 minutos.
> Ver también: AGENTS.md (contexto para IA), CLAUDE.md (comandos), ai/decisions.md (ADRs)

---

## 1. Visión general del sistema

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          USUARIOS FINALES                                    │
│            iOS / Android (device físico o emulador)  /  Web (browser)        │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │ HTTPS / REST JSON
┌──────────────────────────────────▼──────────────────────────────────────────┐
│                      FRONTEND — Expo 54 / React Native 0.81                  │
│                                                                               │
│  Routing: Expo Router 6 (file-based)                                          │
│  ┌───────────────┐  ┌─────────────────────────────────────────────────────┐  │
│  │  (auth)/      │  │  (tabs)/                                            │  │
│  │  login        │  │  index (home)  presupuesto  movimiento  chatbot     │  │
│  │  register     │  └─────────────────────────────────────────────────────┘  │
│  │  onboarding   │                                                            │
│  └───────────────┘                                                            │
│                                                                               │
│  State: AuthProvider (store/) · ThemeProvider (store/)                        │
│  Data: TanStack Query · Axios (api/client.ts)                                 │
│  Tokens: expo-secure-store                                                    │
│  Mock: api/mocks/ (fallback si backend inaccesible)                           │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │ HTTP REST (port 3000)
┌──────────────────────────────────▼──────────────────────────────────────────┐
│                      BACKEND — NestJS 10 / TypeScript 5                       │
│                                                                               │
│  main.ts: CORS · Swagger (/api) · ValidationPipe · AllExceptionsFilter        │
│                                                                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │  auth/   │ │  users/  │ │cashflow/ │ │subscriptions/│ │   profile/   │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘ └──────────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │  mail/   │ │ catalog/ │ │statement-│ │   health/    │ │   common/    │  │
│  │          │ │          │ │ import/  │ │              │ │              │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘ └──────────────┘  │
│                                                                               │
│  Guards: AuthGuard('jwt') · ThrottlerGuard                                    │
│  Passport: JWT Strategy                                                       │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │ TypeORM 0.3.28
┌──────────────────────────────────▼──────────────────────────────────────────┐
│                      BASE DE DATOS — PostgreSQL 15                            │
│                                                                               │
│  ~55 tablas · 19 layers · Soft deletes · Triggers enforce_status_domain()    │
│  Vistas SQL (v_user_access, v_user_current_subscription, etc.)                │
│  DB_SYNC=false en producción                                                  │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼──────────────────────────────────────────┐
│                      SERVICIOS EXTERNOS                                       │
│                                                                               │
│  Flow.cl (pagos CLP)          — checkout + webhook HMAC-SHA256               │
│  SMTP / Nodemailer            — OTPs, reset password, email verification     │
│  FCM / APNs (pendiente)       — notificaciones push                          │
│  Open Banking API (pendiente) — importación automática de movimientos        │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Frontend — Estructura y arquitectura

### Árbol de carpetas principales
```
Frontend/rork-checkapp/expo/
├── app/                          # Solo routes (delegates 2 líneas)
│   ├── _layout.tsx               # Root layout: Stack global, AuthProvider, ThemeProvider
│   ├── index.tsx                 # Auth gate: redirige a (tabs) o (auth)/login
│   ├── (auth)/                   # Rutas sin sesión
│   │   ├── _layout.tsx
│   │   ├── login.tsx
│   │   ├── register.tsx
│   │   ├── forgot-password.tsx
│   │   ├── reset-password.tsx
│   │   ├── verify-email.tsx
│   │   ├── onboarding.tsx
│   │   └── biometric-setup.tsx
│   ├── (tabs)/                   # Rutas autenticadas (tab bar)
│   │   ├── _layout.tsx           # Tab bar con 4 tabs
│   │   ├── index.tsx             # Tab "Balance" → features/home
│   │   ├── budget.tsx            # Tab "Presupuesto" → placeholder Sprint 5
│   │   ├── transactions.tsx      # Tab "Movimiento" → placeholder Sprint 4
│   │   └── assistant.tsx         # Tab "Chatbot" → placeholder Sprint 8
│   └── __tests__/                # Tests de integración de pantallas
│
├── features/                     # Feature-First architecture
│   ├── auth/                     # Sprint 1 (completo)
│   │   ├── index.ts              # Contrato público
│   │   ├── data/                 # AuthRepository.ts
│   │   ├── hooks/                # 8 hooks (useLoginForm, useRegisterForm, etc.)
│   │   ├── ui/                   # 9 screens
│   │   └── utils/                # parseRegisterIdentifier, normalizeRut
│   ├── profile/                  # Sprint 2 (completo)
│   │   ├── index.ts
│   │   ├── data/                 # ProfileRepository.ts
│   │   ├── hooks/
│   │   └── ui/                   # 5 screens
│   ├── home/                     # Sprint 3 (completo)
│   │   ├── index.ts
│   │   ├── hooks/
│   │   └── ui/                   # 12 componentes: FinanceCard, FinancialHealthRings, SummaryCarousel
│   └── subscription/             # Parcial (data + hooks + placeholder)
│
├── api/                          # Infraestructura HTTP (sin conocer features)
│   ├── client.ts                 # Axios + interceptores token + 401 handling
│   ├── config.ts                 # BASE_URL por plataforma + probeBackendReachability()
│   ├── authService.ts
│   ├── profileService.ts
│   └── mocks/
│       ├── mockMemory.ts         # Estado compartido entre mocks
│       ├── authMock.ts
│       ├── profileMock.ts
│       └── mockHelpers.ts
│
├── store/                        # Infraestructura compartida de estado
│   ├── AuthProvider.tsx          # user, login, logout, tokens, biometric
│   └── ThemeProvider.tsx         # theme, isDark, toggleTheme
│
├── components/                   # UI compartida (AppButton, AppInput, icons)
├── constants/                    # colors.ts, theme.ts (fuente de verdad UI)
├── utils/                        # validation.ts (email, password, extractApiErrorMessage)
└── test/                         # test-utils.tsx (renderWithProviders)
```

### Regla de dependencias
```
app/ (delegates)
    │
features/<nombre>/ui/
    │
features/<nombre>/hooks/
    │
features/<nombre>/data/
    │
api/<nombre>Service.ts
    │
api/client.ts (Axios)
```

### Grupos de rutas Expo Router
| Grupo | Propósito | Layouts |
|-------|-----------|---------|
| `(auth)/` | Pantallas sin sesión | Stack sin tab bar |
| `(tabs)/` | Pantallas autenticadas | Stack + tab bar nativo |

### State management
| Store | Tecnología | Qué maneja |
|-------|-----------|------------|
| AuthProvider | React Context + hooks | user, accessToken, refreshToken, login, logout, biometric |
| ThemeProvider | React Context | theme object, isDark, toggleTheme |
| TanStack Query | Servidor | Cache de datos remotos, mutations, refetch |

---

## 3. Backend — Módulo por módulo con endpoints

### Módulo: auth
Ruta base: `/auth`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | /auth/register | Público | Crear cuenta (firstName, lastName, rut, email, password) |
| POST | /auth/login | Público | Login multi-identificador (email/RUT/username) |
| POST | /auth/refresh | Público | Rotar access + refresh token |
| POST | /auth/logout | JWT | Invalidar refresh token actual |
| POST | /auth/logout-all | JWT | Invalidar todos los refresh tokens |
| POST | /auth/forgot-password | Público (throttle 5/min) | Enviar OTP reset |
| POST | /auth/reset-password | Público | Cambiar contraseña con OTP |
| POST | /auth/email-verification/request | Público (throttle 3/h) | Enviar OTP verificación |
| POST | /auth/email-verification/confirm | Público | Confirmar email con OTP |
| POST | /auth/email-verification/resend | Público | Reenviar OTP verificación |
| PATCH | /auth/biometric | JWT | Actualizar preferencia biométrica |
| PATCH | /auth/onboarding | JWT | Actualizar paso de onboarding |

### Módulo: users
Ruta base: `/users`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | /users/me | JWT | Obtener perfil del usuario autenticado |
| PATCH | /users/me | JWT | Actualizar datos básicos (nombre, username) |
| PATCH | /users/profile | JWT | Actualizar datos de perfil extendido |
| PATCH | /users/me/password | JWT | Cambiar contraseña (requiere contraseña actual) |

### Módulo: cashflow
Ruta base: `/cashflow`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | /cashflow/transactions | JWT | Listar transacciones (con filtros) |
| POST | /cashflow/transactions | JWT | Crear transacción |
| GET | /cashflow/transactions/:id | JWT | Obtener transacción |
| PATCH | /cashflow/transactions/:id | JWT | Actualizar transacción |
| DELETE | /cashflow/transactions/:id | JWT | Eliminar transacción (soft delete) |
| GET | /cashflow/categories | JWT | Listar categorías del usuario |
| POST | /cashflow/categories | JWT | Crear categoría |
| PATCH | /cashflow/categories/:id | JWT | Actualizar categoría |
| DELETE | /cashflow/categories/:id | JWT | Eliminar categoría |
| GET | /cashflow/subcategories | JWT | Listar subcategorías |
| POST | /cashflow/subcategories | JWT | Crear subcategoría |
| PATCH | /cashflow/subcategories/:id | JWT | Actualizar subcategoría |
| DELETE | /cashflow/subcategories/:id | JWT | Eliminar subcategoría |
| GET | /cashflow/funding-sources | JWT | Listar fuentes de fondos |
| POST | /cashflow/funding-sources | JWT | Crear fuente de fondos |
| PATCH | /cashflow/funding-sources/:id | JWT | Actualizar fuente |
| DELETE | /cashflow/funding-sources/:id | JWT | Eliminar fuente |

### Módulo: subscriptions
Ruta base: `/subscriptions`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | /subscriptions/plans | Público | Listar planes disponibles con precios |
| GET | /subscriptions/me | JWT | Suscripción activa del usuario |
| POST | /subscriptions/checkout | JWT | Iniciar pago en Flow.cl |
| POST | /subscriptions/webhook | Público | Webhook de confirmación Flow.cl |

### Módulo: profile
Ruta base: `/profile`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | /profile/financial | JWT | Obtener perfil financiero |
| PUT | /profile/financial | JWT | Actualizar perfil financiero (en deuda técnica M2-DT-01) |

### Módulo: statement-import
Ruta base: `/statement-import`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | /statement-import/upload | JWT | Subir PDF de cartola bancaria |
| GET | /statement-import | JWT | Listar importaciones del usuario |
| PATCH | /statement-import/:id/lines/:lineId | JWT | Reclasificar línea de importación |

### Módulo: health (sin auth)
| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | / | Público | Info del servicio (name, version, health, docs) |
| GET | /health | Público | Liveness check `{ "ok": true }` |

---

## 4. Base de datos — Layers 0-19

Esquema completo: `workspace/walvy-workspace/DB_v2/schema.sql`

| Layer | Propósito | Tablas principales |
|-------|-----------|-------------------|
| 0 | Catálogo geográfico y monetario | `country`, `currency`, `document_type` |
| 1 | Sistema de estados dinámico (reemplaza ENUMs) | `status_domain`, `status` |
| 2 | RBAC: roles y permisos | `role`, `permission`, `role_permission` |
| 3 | Configuración global | `financial_health_level`, `app_config` |
| 4 | Identidad y seguridad de usuario | `app_user`, `refresh_tokens`, `password_reset_tokens`, `email_verification_tokens`, `biometric_preferences`, `user_onboarding_state` |
| 5 | B2B corporativo (futuro) | `company` |
| 6 | Perfil financiero y preferencias | `user_financial_profile`, `user_goals`, `alert_preferences`, `notification_queue` |
| 7 | Catálogo financiero | `financial_institution`, `category`, `cashflow_node`, `ant_expense_rules` |
| 8 | Gestión de archivos e importaciones | `file_upload`, `import_line_items`, `movement_classification_suggestions` |
| 9 | Movimientos financieros | `financial_movement`, `movement_review_queue` |
| 10 | Presupuestos | `budget_plan`, `budget_plan_item` |
| 11 | Deudas y metodología snowball | `debt`, `debt_schedules`, `debt_payments`, `debt_attachments`, `debt_snowball_plan` |
| 12 | Pagos programados | `user_payment`, `recurring_payment_suggestions` |
| 13 | Suscripciones y pagos Flow.cl | `plan`, `plan_price` (bitemporal), `subscription`, `payment_order` |
| 14 | Gamificación | `gamification_rules`, `gamification_events`, `user_gamification_stats`, `user_score_history` |
| 15 | Mensajería interna | Tablas de mensajes y canales |
| 16 | Asistente IA | `ai_conversation`, `ai_message`, `ai_context_snapshot` |
| 17 | Administración y auditoría | `admin_users`, `admin_audit_log`, `audit_log`, `report_snapshots` |
| 18 | Read models CQRS (diagnóstico) | `rm_monthly_diagnosis`, `rm_debt_summary`, `rm_payment_summary`, `rm_expense_leaks` |
| 19 | Vistas SQL | `v_user_access`, `v_user_current_subscription`, `v_cashflow_summary`, `v_financial_health` |

### Patrones transversales de DB
- **Soft deletes:** `deleted_at TIMESTAMPTZ` en `app_user`, `financial_movement`, `debt`.
- **Trigger `enforce_status_domain()`:** aplicado en toda columna `*_status_id`; valida que el status pertenezca al dominio correcto.
- **Idempotencia webhooks:** `payment_order.commerce_order UNIQUE`.
- **Bitemporalidad:** `plan_price` tiene `valid_from` / `valid_until` para historial de precios.
- **Transformer `decimalToNumber`:** en entidades TypeORM para campos `numeric(12,2)` → JS `number`.

---

## 5. Flujo de autenticación completo

```
REGISTRO
─────────────────────────────────────────────────────────────────
1. Usuario llena formulario:
   { firstName, lastName, rut, email, password, confirmPassword,
     acceptTerms, acceptPrivacy }

2. POST /auth/register
   Backend:
   - Valida DTO (class-validator)
   - Verifica email único + RUT único
   - Hash bcrypt de password
   - Crea app_user (status: email_pending)
   - Crea user_onboarding_state (step: email_verification)
   - Genera OTP 6 dígitos, guarda hash en email_verification_tokens (15min)
   - Envía email con OTP

3. POST /auth/email-verification/confirm { email, otp }
   Backend:
   - Busca token no expirado
   - Verifica OTP
   - Actualiza app_user.status → activo
   - Invalida token usado

ONBOARDING (post-verificación)
─────────────────────────────────────────────────────────────────
4. Frontend redirige a pantalla de onboarding
   Steps: email_verification → financial_profile → categories → completed

5. PATCH /auth/onboarding { currentStep, data }
   - Escribe step en user_onboarding_state
   - Cuando completed: onboarding_done=true

LOGIN
─────────────────────────────────────────────────────────────────
6. POST /auth/login { identifier, password }
   - identifier puede ser: email, RUT (12345678-5), o username
   - Backend detecta tipo por formato y busca en la tabla correspondiente
   - Verifica bcrypt
   - Genera access token JWT (15min, payload: { sub, email, role })
   - Genera refresh token opaco (UUID), lo hashea, guarda en refresh_tokens (7 días)
   - Responde: { accessToken, refreshToken, user: toPublic() }

7. Frontend:
   - Guarda accessToken en memoria (AuthProvider)
   - Guarda refreshToken en SecureStore
   - Redirige a /(tabs)

REFRESH DE TOKENS
─────────────────────────────────────────────────────────────────
8. api/client.ts detecta 401 (access expirado)
   → POST /auth/refresh { refreshToken }
   Backend:
   - Hashea el refresh recibido y busca en DB
   - Verifica expiración
   - Invalida registro anterior (rotación)
   - Emite nuevo access token (15min) + nuevo refresh token (7 días)
   Responde: { accessToken, refreshToken }

9. Interceptor Axios:
   - Actualiza tokens en AuthProvider + SecureStore
   - Reintenta la request original

LOGOUT
─────────────────────────────────────────────────────────────────
10. POST /auth/logout { refreshToken }
    - Invalida ese refresh token en DB
    Frontend: limpia AuthProvider + SecureStore → redirige a (auth)/login

11. POST /auth/logout-all
    - Invalida TODOS los refresh tokens del usuario (seguridad en dispositivo perdido)

RESET DE CONTRASEÑA
─────────────────────────────────────────────────────────────────
12. POST /auth/forgot-password { email }
    - Genera OTP 6 dígitos → password_reset_tokens (15min)
    - Envía email OTP

13. POST /auth/reset-password { email, otp, newPassword }
    - Verifica OTP
    - Hash nueva contraseña con bcrypt
    - Invalida token
```

---

## 6. Flujo de onboarding

```
STEPS DEL ONBOARDING
─────────────────────────────────────────────────────────────────

                   ┌─────────────────────┐
                   │  email_verification  │
                   │  (paso inicial)      │
                   └──────────┬──────────┘
                              │ OTP verificado
                   ┌──────────▼──────────┐
                   │  financial_profile   │  ← PATCH /auth/onboarding
                   │  (ingreso perfil     │     Escribe en:
                   │   financiero)        │     user_onboarding_state
                   └──────────┬──────────┘     user_financial_profile
                              │
                   ┌──────────▼──────────┐
                   │     categories       │  ← Selección de categorías
                   │  (personalización)   │     relevantes para el usuario
                   └──────────┬──────────┘
                              │
                   ┌──────────▼──────────┐
                   │      completed       │  ← onboarding_done = true
                   └─────────────────────┘     Redirige a /(tabs)

ESTADO EN DB
─────────────────────────────────────────────────────────────────
Tabla: user_onboarding_state
  - current_step: VARCHAR (enum de steps)
  - email_verified: BOOLEAN
  - financial_profile_completed: BOOLEAN  ← M2-DT-01 pendiente
  - min_doc_threshold_met: BOOLEAN        ← requiere datos cashflow
  - onboarding_done: BOOLEAN

DEUDA TÉCNICA (M1-DT-04)
  - financialProfileCompleted requiere endpoints PUT /profile/financial (M2-DT-01)
  - minDocThresholdMet requiere al menos N movimientos en cashflow
  - currentStep no tiene validación de enum en el servicio
```

---

## 7. Flujo de suscripción

```
PLANES
─────────────────────────────────────────────────────────────────
GET /subscriptions/plans (público)
  Devuelve: lista de planes con precios actuales (tabla plan_price bitemporal)
  Planes actuales: Free, Pro Mensual ($5.000 CLP), Pro Anual ($50.000 CLP)

CHECKOUT
─────────────────────────────────────────────────────────────────
1. Usuario selecciona plan
2. POST /subscriptions/checkout { planId }
   Backend:
   - Verifica usuario autenticado
   - Crea payment_order con commerce_order UNIQUE
   - Llama API Flow.cl con HMAC-SHA256
   - Devuelve { url: "<URL de pago Flow>" }

3. Frontend redirige al browser externo (URL de Flow.cl)
4. Usuario completa pago en Flow.cl

CONFIRMACIÓN VÍA WEBHOOK
─────────────────────────────────────────────────────────────────
5. Flow.cl → POST /subscriptions/webhook
   Backend:
   - Verifica firma HMAC-SHA256 (FLOW_SECRET_KEY)
   - Verifica idempotencia: payment_order.commerce_order UNIQUE
   - Si aprobado:
     - Actualiza payment_order.status → pagado
     - Crea/actualiza subscription (fecha inicio, fecha fin)
     - Actualiza app_user.plan → pro

6. Flow.cl → redirige usuario a FLOW_RETURN_URL
   Frontend: pantalla de resultado (/subscription/result)

ESTADO EN DB
─────────────────────────────────────────────────────────────────
  plan → plan_price (bitemporal) → subscription → payment_order
  payment_order.commerce_order: UNIQUE (idempotencia)
```

---

## 8. Flujo de importación de cartolas PDF

```
UPLOAD
─────────────────────────────────────────────────────────────────
1. POST /statement-import/upload
   Body: multipart/form-data { file: PDF, institutionId }
   Backend:
   - Valida tipo MIME (PDF)
   - Guarda en file_upload
   - Parser extrae líneas del PDF según institución
   - Crea import_line_items (línea por movimiento detectado)
   - Llama clasificador: movement_classification_suggestions
   - Crea financial_movement por cada línea clasificada

REVISIÓN
─────────────────────────────────────────────────────────────────
2. GET /statement-import
   Devuelve: lista de importaciones con estado y líneas

3. PATCH /statement-import/:importId/lines/:lineId
   Body: { categoryId, subcategoryId, description }
   Backend:
   - Actualiza clasificación de la línea
   - Propaga cambio al financial_movement correspondiente

TABLAS INVOLUCRADAS
─────────────────────────────────────────────────────────────────
  file_upload
    └── import_line_items (N líneas por archivo)
          └── movement_classification_suggestions
          └── financial_movement (movimiento real en cashflow)
```

---

## 9. Servicios externos

### Flow.cl (pagos)
| Atributo | Valor |
|----------|-------|
| Entorno sandbox | https://sandbox.flow.cl/api |
| Entorno producción | https://www.flow.cl/api |
| Variable de entorno | FLOW_API_URL, FLOW_API_KEY, FLOW_SECRET_KEY |
| Autenticación webhook | HMAC-SHA256 (clave FLOW_SECRET_KEY) |
| Idempotencia | commerce_order UNIQUE en payment_order |
| URLs de callback | FLOW_CONFIRM_URL (webhook), FLOW_RETURN_URL (redirect usuario) |

### SMTP / Nodemailer
| Atributo | Valor |
|----------|-------|
| Variables de entorno | SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_FROM |
| Modo desarrollo | Console mode (sin SMTP real); usa MockMailService en tests |
| Emails que envía | OTP verificación email, OTP reset password |
| OTP | 6 dígitos numéricos, validez 15 minutos |

### FCM / APNs (pendiente)
| Atributo | Estado |
|----------|--------|
| Estado | Pendiente (Sprint 7/8) |
| Bloqueado por | Deuda técnica M2-DT-04: sin worker de notificaciones |
| Tabla ready | notification_queue (Layer 6) |

### Open Banking API (pendiente)
| Atributo | Estado |
|----------|--------|
| Estado | Pendiente (fuera del alcance MVP actual) |
| Workaround actual | Importación manual de PDF (statement-import) |

---

## 10. Conectividad frontend-backend por entorno

### Resolución de URL base
El frontend resuelve `BACKEND_BASE_URL` en `api/config.ts` según esta prioridad:

```
1. EXPO_PUBLIC_BACKEND_BASE_URL (si está definida en expo/.env)
2. Por plataforma (defaults automáticos):
   - Web (navegador en mismo PC)  → http://localhost:3000
   - Emulador Android             → http://10.0.2.2:3000
   - iOS simulator                → http://localhost:3000
   - Dispositivo físico           → REQUIERE EXPO_PUBLIC_BACKEND_BASE_URL
```

### Configuración por entorno

| Entorno | URL backend | Configuración requerida |
|---------|-------------|------------------------|
| Web (mismo PC) | `http://localhost:3000` | Solo tener el backend corriendo |
| Emulador Android | `http://10.0.2.2:3000` | Automático (ADB port forward) |
| iOS Simulator | `http://localhost:3000` | Automático |
| Dispositivo físico | `http://<IP-LAN>:3000` | `EXPO_PUBLIC_BACKEND_BASE_URL=http://192.168.x.x:3000` en `expo/.env` |
| Producción | `https://api.walvy.app` | `EXPO_PUBLIC_BACKEND_BASE_URL` en CI/CD |

### CORS obligatorio
El backend debe incluir el origen de Expo web en `CORS_ORIGIN`:
```bash
CORS_ORIGIN=http://localhost:8081,http://127.0.0.1:8081
```

### Health check
- Backend expone `GET /health` → `{ "ok": true }` (sin auth, sin throttling).
- El frontend llama este endpoint al arranque: `probeBackendReachability()`.
- Si responde: modo real.
- Si no responde: modo mock (salvo override por env var).

---

## 11. Mock mode — Cómo funciona el fallback

```
ARRANQUE DEL FRONTEND
─────────────────────────────────────────────────────────────────

app/_layout.tsx
  │
  ▼
api/config.ts → probeBackendReachability()
  │
  ├── GET {BASE_URL}/health
  │
  ├── Si responde 200 → isMockMode = false → llamadas reales al backend
  │
  └── Si timeout/error → isMockMode = true → todos los servicios usan mocks

OVERRIDE MANUAL
─────────────────────────────────────────────────────────────────
EXPO_PUBLIC_USE_MOCK_MODE=true   → fuerza mock (útil en desarrollo sin backend)
EXPO_PUBLIC_USE_MOCK_MODE=false  → fuerza real (útil para debugging)
Sin definir                      → probe decide automáticamente

IMPLEMENTACIÓN
─────────────────────────────────────────────────────────────────
api/authService.ts:
  export async function login(dto) {
    if (isMockMode()) return authMock.login(dto);
    return apiClient.post('/auth/login', dto);
  }

api/mocks/
  ├── mockMemory.ts      ← Estado en memoria (users[], currentUser, tokens)
  ├── authMock.ts        ← Implementa register, login, logout, etc.
  ├── profileMock.ts     ← Implementa getMe, updateProfile, etc.
  └── mockHelpers.ts     ← Helpers compartidos

Cuenta de prueba en mock:
  email:    test@walvy.app
  password: Test1234!

NUEVA FEATURE → NUEVO MOCK
─────────────────────────────────────────────────────────────────
1. Crear api/mocks/<feature>Mock.ts
2. Agregar estado necesario en mockMemory.ts
3. Re-exportar en api/mockService.ts (barrel)
4. Usar en api/<feature>Service.ts:
   if (isMockMode()) return <feature>Mock.<funcion>(dto);
```

---

## Referencias rápidas

| Necesito saber... | Ver... |
|-------------------|--------|
| Reglas de código y naming | `AGENTS.md` secciones 4, 5 |
| Cómo agregar una feature | `AGENTS.md` sección 7 |
| Decisiones de arquitectura (ADRs) | `ai/decisions.md` |
| Estado actual del código | `ai/context.md` |
| Reglas UI/UX y paleta de colores | `ai/rules.md` → sección UI y UX |
| Comandos habituales | `ai/skills.md` |
| Deuda técnica activa | `AGENTS.md` sección 15 |
| Schema SQL completo | `DB_v2/schema.sql` |
| Alcance del MVP | `utils/organizacion/docs/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` |
