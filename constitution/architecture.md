# Arquitectura del Sistema — Walvy

**Versión:** 1.0  
**Fecha:** 2026-05-14  
**Estado:** Vigente

---

## Resumen ejecutivo

Walvy es una aplicación de finanzas personales orientada al mercado chileno. El sistema está compuesto por un backend API REST y un frontend móvil multiplataforma (iOS/Android). No existe SSR; toda la comunicación es mediante HTTP/JSON sobre HTTPS.

---

## 1. Capas del sistema

```
┌─────────────────────────────────────────────────────────────┐
│                   FRONTEND (Expo / React Native)             │
│  features/<nombre>/ui  →  hooks  →  data  →  api/           │
│  store/ (AuthProvider, ThemeProvider)                        │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS / JSON (REST)
┌────────────────────────▼────────────────────────────────────┐
│                   BACKEND (NestJS 10)                        │
│  Controller → Service → Repository/Entity                    │
│  Guards (JWT, Throttler) · Pipes · Filters                   │
└────────────────────────┬────────────────────────────────────┘
                         │ TypeORM / pg driver
┌────────────────────────▼────────────────────────────────────┐
│                   DATOS (PostgreSQL 15)                       │
│  19 layers · status_domain · read models CQRS · vistas SQL   │
└──────────────────────────────────────────────────────────────┘
                         │
┌──────────────────────────────────────────────────────────────┐
│                SERVICIOS EXTERNOS                             │
│  Flow.cl (pagos)  ·  SMTP/Nodemailer (email)                 │
│  [pendiente] FCM/APNs · Open Banking                         │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Backend — módulos NestJS

### Módulos implementados (Milestone 1)

| Módulo | Descripción | Ruta base |
|--------|-------------|-----------|
| `AuthModule` | Registro, login, OTP, JWT, refresh tokens, biometría | `/auth` |
| `UsersModule` | Perfil, onboarding, RUT, foto de perfil | `/users` |
| `SeedModule` | Seeds de catálogos en startup (OnModuleInit) | — |
| `CommonModule` | Validators, transformers, filtros globales | — |
| `AppModule` | Raíz, configuración global, Swagger | — |

### Módulos pendientes

| Módulo | Milestone | Notas |
|--------|-----------|-------|
| `FinancialProfileModule` | M2 | Perfil financiero, metas, alertas |
| `CashflowModule` | M3 | Movimientos, deduplicación, categorización |
| `BudgetModule` | M4 | Presupuesto por categoría |
| `DebtsModule` | M4 | Plan bola de nieve |
| `SubscriptionsModule` | M5 | Flow.cl, planes, payment orders |
| `GamificationModule` | M6 | Reglas, eventos, stats |
| `AdminModule` | M7 | Backoffice (src/admin/ vacío — deuda técnica M1-DT-01) |
| `AIAssistantModule` | M8 | Asistente financiero |

---

## 3. Separación frontend / backend

- **No existe SSR.** El frontend es una SPA móvil compilada con Expo.
- El backend expone únicamente una API REST (JSON sobre HTTPS).
- No hay views, templates ni rendering en el servidor.
- El frontend consume el backend mediante `api/` (Axios + interceptores). Nunca accede directamente a la DB.
- La documentación de la API se genera automáticamente con Swagger (`@nestjs/swagger`) y se sirve en `/api`.

---

## 4. Patrones arquitectónicos

### 4.1 Backend — Module-per-feature

Cada dominio de negocio vive en su propio módulo NestJS bajo `src/<modulo>/`:

```
src/auth/
├── auth.module.ts
├── auth.controller.ts
├── auth.service.ts
├── dto/
│   ├── register.dto.ts
│   └── login.dto.ts
├── entities/
│   └── refresh-token.entity.ts
├── guards/
│   └── jwt-auth.guard.ts
└── strategies/
    └── jwt.strategy.ts
```

- Un módulo no importa directamente desde otro módulo de dominio; comparte contratos via módulos de infraestructura (`CommonModule`, providers exportados).
- La lógica de negocio reside **exclusivamente en los services**. Los controllers solo orquestan la request/response.

### 4.2 Frontend — Feature-First + Clean Architecture

Cada feature tiene su propio directorio bajo `features/<nombre>/` con cuatro capas estrictamente ordenadas:

```
features/<nombre>/
├── index.ts              # contrato público — único import desde fuera
├── data/<X>Repository.ts # wrappea api/<X>Service
├── hooks/use<X>.ts       # estado, validación, mutations (sin JSX)
└── ui/<X>Screen.tsx      # JSX puro, delega lógica al hook
```

**Regla de dependencias (solo downward):**

```
ui  →  hooks  →  data  →  api/
```

Ninguna capa puede importar de la capa superior. La capa `ui` no accede nunca directamente a `api/`.

**Regla de imports cross-feature:**

- PROHIBIDO importar directamente entre features (`import { algo } from '../otra-feature/...'`).
- Solo se puede cruzar mediante el alias `@/` apuntando a `store/` (estado global) o `api/` (servicios HTTP compartidos).

---

## 5. Flujo de datos

### Request HTTP estándar

```
Cliente (app)
    │
    ▼
[Guard: ThrottlerGuard]          ← rate limiting global
    │
    ▼
[Guard: AuthGuard('jwt')]        ← solo en rutas protegidas
    │
    ▼
[ValidationPipe]                 ← whitelist, forbidNonWhitelisted, transform
    │
    ▼
Controller                       ← valida DTO, extrae user de @Request()
    │
    ▼
Service                          ← lógica de negocio, llamadas a repositorios
    │
    ▼
TypeORM Repository / Entity      ← acceso a DB
    │
    ▼
PostgreSQL                       ← consulta SQL
    │
    ▼
Response (JSON)                  ← serializado por ClassSerializerInterceptor
```

### Manejo de errores

Si en cualquier capa se lanza una excepción, el `AllExceptionsFilter` global la captura y devuelve:

```json
{
  "statusCode": 400,
  "message": "El campo rut es inválido",
  "path": "/auth/register",
  "timestamp": "2026-05-14T12:00:00.000Z"
}
```

---

## 6. Auth flow

### Registro y verificación

```
POST /auth/register
    → Guarda usuario con emailVerified=false
    → Genera OTP 6 dígitos (expira EMAIL_VERIFICATION_EXPIRES_MINUTES)
    → Envía email con OTP

POST /auth/verify-otp
    → Valida OTP, marca emailVerified=true
    → Inicia onboarding state

POST /auth/login
    → Valida email + password (bcrypt)
    → Emite: accessToken (JWT 15min) + refreshToken (opaco 7 días)
```

### Token rotation

```
POST /auth/refresh
    → Recibe refreshToken opaco
    → Verifica hash en DB (refresh_tokens)
    → Marca token como usado (revocado)
    → Emite nuevos accessToken + refreshToken
    → Si el token ya estaba revocado → revokeAllRefreshForUser()
       (replay attack detection)
```

### Logout

```
POST /auth/logout
    → Revoca refreshToken en DB
    → Idempotente (no falla si el token ya no existe)
```

### Protección de rutas

- `@UseGuards(AuthGuard('jwt'))` — verifica firma JWT, extrae payload
- `@UseGuards(ThrottlerGuard)` — limita requests por IP/usuario

---

## 7. Manejo de estado — frontend

### TanStack React Query

- Todas las llamadas a API se realizan mediante hooks de TanStack Query (`useQuery`, `useMutation`).
- El cache se invalida explícitamente tras mutations que afectan otros queries.
- No existe Redux ni Zustand; el estado del servidor vive en Query Cache.

### Context hooks (store/)

- `AuthProvider`: sesión del usuario, tokens, estado de autenticación.
- `ThemeProvider`: tema de la app (light/dark), tokens de color.
- Los providers se montan en el layout raíz de Expo Router.

### Flujo de autenticación en frontend

```
App startup
    │
    ├─ SecureStore.getItem(ACCESS_TOKEN_KEY)
    │       ↓ token válido → pantallas autenticadas
    │       ↓ token expirado → POST /auth/refresh con refreshToken
    │       ↓ sin token → pantalla de login
    │
useAuthStore (AuthProvider)
    ├─ login()  → guarda tokens en SecureStore
    ├─ logout() → borra tokens, navega a /login
    └─ refresh() → rota tokens transparentemente
```

---

## 8. Estrategia de API — frontend

### Axios + interceptores

- Instancia base en `api/axiosInstance.ts` con `baseURL` del entorno.
- Interceptor de request: adjunta `Authorization: Bearer <token>`.
- Interceptor de response: si 401 → intenta refresh → reintenta request original.
- Si el refresh falla → logout automático.

### Mock mode

- Si `EXPO_PUBLIC_USE_MOCK_MODE=true` o si el health probe al backend falla, la app cambia al modo mock.
- En mock mode, los repositories devuelven datos estáticos sin llamar a Axios.
- Útil para desarrollo offline y demos.

---

## 9. Estructura DB — 19 Layers

| Layer | Contenido |
|-------|-----------|
| 0–3 | Catálogos: país, moneda, doc_type, status_domain, role, health_level, app_config |
| 4 | Identidad y auth: app_user, refresh_tokens, otp_tokens, biometric_credentials, onboarding_state |
| 5 | B2B: company, benefits |
| 6 | Perfil usuario: financial_profile, goals, alerts, notifications |
| 7–9 | Cashflow: institutions, categories, financial_movements, deduplicación |
| 10–12 | Budget, debts (snowball), payments |
| 13 | Monetización: plan, plan_price (bitemporal), subscription, payment_order |
| 14 | Gamificación: rules, events, stats, history |
| 15–16 | Messaging, AI assistant |
| 17 | Backoffice admin |
| 18 | 4 read models CQRS |
| 19 | 4 vistas SQL |

### Patrones clave de DB

**Status Domain Pattern:** Los estados de entidades no son ENUMs nativos de PostgreSQL. En su lugar, se usa una tabla `status_domain` con un trigger `enforce_status_domain()` que valida que el `status` de cada entidad sea un valor permitido para ese dominio. Esto permite agregar nuevos estados sin `ALTER TABLE`.

**Soft deletes:** Las entidades `app_user`, `financial_movement` y `debt` nunca se eliminan físicamente. Se marca `deleted_at = NOW()`.

**Precios bitemporales:** `plan_price` tiene columnas `valid_from` y `valid_to` para mantener historial de precios sin perder datos de suscripciones pasadas.

**CQRS read models:** 4 tablas desnormalizadas en Layer 18 para consultas de lectura complejas sin joins costosos.

**DB_SYNC:** `DB_SYNC=false` en producción. En desarrollo se puede activar transitoriamente (`DB_SYNC=true`), pero antes de producción se requiere implementar migrations.

---

## 10. Principios de diseño irrenunciables

1. **Sin lógica en controllers.** Los controllers solo reciben la request, delegan al service y retornan la respuesta. Ningún `if` de negocio en controllers.
2. **Sin imports cross-feature.** Features se comunican solo vía `store/` o `api/`. Nunca `import { X } from '../otra-feature/...'`.
3. **Sin DELETE físico de usuarios.** Siempre soft delete (`deleted_at`).
4. **Sin tokens en logs.** Nunca loguear `accessToken`, `refreshToken` ni `passwordHash`.
5. **Sin ENUMs para estados mutables.** Usar `status_domain` pattern.
6. **Sin `any` implícito.** TypeScript en modo strict en backend y frontend.
