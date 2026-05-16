# Plan de Evolución: Módulo de Autenticación

> **Módulo:** `auth`
> **Última revisión:** 2026-05-14

---

## 1. Estado actual

### Implementado y en uso

- Registro con validación de email y contraseña
- Verificación de email por OTP (6 dígitos, 15 min)
- Login email/contraseña
- Tokens JWT 15min + refresh token rotativo 7 días
- Logout y logout-all (revocación de refresh tokens)
- Recuperación de contraseña (forgot + reset)
- Autenticación biométrica (registro de clave pública + validación de firma)
- Onboarding GET/PATCH integrado en módulo auth
- Throttler aplicado en endpoints públicos
- AllExceptionsFilter global

### Probado manualmente

- Flujo completo registro → OTP → login funciona en staging
- Refresh token rotation validado
- Biometría validada en device real (iOS)

### No cubierto por tests automatizados

- No hay unit tests para `AuthService`
- No hay e2e para flujos de auth (están en backlog E2E)

---

## 2. Mejoras identificadas (deuda técnica activa)

### M1-DT-02 — Sin RBAC enforcement

**Problema:** El sistema tiene tablas `role`, `role_permission` y `permission` en la base de datos, pero no hay guard que evalúe permisos por ruta y método HTTP.

**Impacto:** Cualquier usuario autenticado puede acceder a rutas reservadas para admin. La protección actual es solo JWT (autenticación), no autorización por rol.

**Solución propuesta:**
1. Crear `RbacGuard` que lea el JWT, extraiga `role`, consulte `role_permission → permission` y valide contra ruta + método
2. Decorador `@RequirePermission('users:manage')` para marcar rutas protegidas
3. Cachear permisos por rol (TTL corto) para evitar N+1 en cada request

**Archivos afectados:**
- `src/auth/guards/rbac.guard.ts` (nuevo)
- `src/auth/decorators/require-permission.decorator.ts` (nuevo)
- `src/common/modules/` (integración global)

---

### Unit tests para AuthService

**Cobertura mínima requerida:**

| Caso | Método |
|------|--------|
| Registro exitoso | `register()` |
| Registro con email duplicado lanza 409 | `register()` |
| Login exitoso devuelve tokens | `login()` |
| Login con contraseña incorrecta lanza 401 | `login()` |
| Login con usuario no verificado lanza 403 | `login()` |
| Refresh con token válido rota el token | `refreshTokens()` |
| Refresh con token inválido lanza 401 | `refreshTokens()` |
| Cambio de contraseña revoca todas las sesiones | `changePassword()` |

**Convenciones a seguir:**
- Usar `uniqueEmail()` helper para emails de prueba
- Mockear `MailService` con `MockMailService`
- Desactivar `ThrottlerGuard` en tests unitarios

---

### Validación de enum en `currentStep`

**Problema (parte del M1-DT-04):** El campo `currentStep` en `UpdateOnboardingStepDto` acepta cualquier string, permitiendo valores inválidos que corrompen el estado del onboarding.

**Solución:** Agregar `@IsIn([...steps])` o `@IsEnum(OnboardingStep)` en el DTO.

---

## 3. Backlog futuro (no comprometido)

### MFA (Autenticación multifactor)

- TOTP (Google Authenticator / Authy)
- SMS OTP como alternativa
- Flujo: login → si MFA activo → solicitar TOTP → emitir tokens
- Dependencia: definir requerimiento con cliente, UX a diseñar

### OAuth / Inicio de sesión social

- Google Sign-In (prioritario para móvil)
- Apple Sign-In (requerido por App Store si se ofrece OAuth)
- Gestión de cuentas vinculadas (un email puede tener múltiples providers)

### Gestión de dispositivos

- Listar sesiones activas (dispositivo, IP, última actividad)
- Revocar sesión específica desde la app
- Notificación push al usuario cuando se inicia sesión desde dispositivo nuevo

### Biometría multi-dispositivo

- Actualmente un usuario puede tener múltiples `biometric_credentials` (por deviceId)
- Falta UI para listar y revocar credenciales biométricas por dispositivo

---

## 4. Dependencias

| Item | Depende de | Bloquea |
|------|------------|---------|
| RBAC enforcement (M1-DT-02) | Schema de permisos ya en DB | Rutas admin (M1-DT-01) |
| Onboarding auto-complete | M2-DT-01 (perfil financiero) | Completar flujo onboarding |
| Biometría multi-dispositivo | Diseño UX aprobado | — |
| MFA | Decisión de roadmap con cliente | — |
| OAuth | Credenciales Google/Apple configuradas | — |

---

## 5. Próximos pasos recomendados (prioridad)

1. **Inmediato:** Agregar `@IsEnum(OnboardingStep)` en `UpdateOnboardingStepDto` — 30 min, bajo riesgo
2. **Sprint actual:** Unit tests `AuthService` — 1-2 días, bloquea calidad del módulo
3. **Sprint siguiente:** `RbacGuard` (M1-DT-02) — antes de exponer endpoints admin
4. **Futuro:** Reunión con cliente para definir MFA y OAuth roadmap
