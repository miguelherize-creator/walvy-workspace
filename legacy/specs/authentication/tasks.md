# Tareas: Módulo de Autenticación

> **Módulo:** `auth`
> **Última revisión:** 2026-05-14

---

## Deuda técnica activa

### [ ] M1-DT-01: Endpoints admin — gestión de usuarios

**Descripción:** El directorio `src/admin/` existe pero está vacío. Se deben implementar los endpoints mínimos para que un administrador pueda gestionar el estado de los usuarios.

**Endpoints a crear:**
- `PATCH /admin/users/:id/status` — cambiar estado (`active`, `suspended`)
- `DELETE /admin/users/:id` — soft delete de usuario

**Requisitos:**
- Requiere RBAC enforcement (M1-DT-02) implementado primero
- Solo accesible con rol `admin`
- Retornar 403 si el usuario autenticado no tiene permiso
- Soft delete: marcar `deletedAt`, no eliminar físicamente

**Archivos afectados:**
- `src/admin/admin.module.ts` (nuevo)
- `src/admin/admin.controller.ts` (nuevo)
- `src/admin/admin.service.ts` (nuevo)
- `src/admin/dto/update-user-status.dto.ts` (nuevo)
- `src/users/users.service.ts` (agregar método `updateStatus`)

**Bloqueante:** Sí — bloqueado por M1-DT-02 (RBAC)

---

### [ ] M1-DT-02: Guard RBAC enforcement

**Descripción:** Implementar autorización basada en roles. El JWT incluye el `role` del usuario; se debe consultar `role_permission → permission` y validar que la ruta + método HTTP están permitidos para ese rol.

**Implementación:**
1. Crear `RbacGuard implements CanActivate`
2. Crear decorador `@RequirePermission('resource:action')`
3. El guard lee `request.user.role`, consulta permisos en DB, valida contra el permiso requerido
4. Cachear permisos por rol con TTL de 5 minutos para evitar N+1
5. Registrar el guard globalmente o por módulo (evaluar impacto)

**Archivos afectados:**
- `src/auth/guards/rbac.guard.ts` (nuevo)
- `src/auth/decorators/require-permission.decorator.ts` (nuevo)
- `src/auth/auth.module.ts` (registrar guard)
- `src/common/` (posible integración global)

**Bloqueante:** Sí — bloquea M1-DT-01 y cualquier endpoint admin

---

### [ ] Unit tests AuthService

**Descripción:** Escribir suite de tests unitarios para `AuthService` con los casos críticos del flujo de autenticación.

**Casos a cubrir:**

| Test | Método | Resultado esperado |
|------|--------|--------------------|
| Registro exitoso | `register()` | Usuario creado, email enviado |
| Email duplicado | `register()` | Lanza `ConflictException` (409) |
| Login exitoso | `login()` | Retorna `accessToken` + `refreshToken` |
| Contraseña incorrecta | `login()` | Lanza `UnauthorizedException` (401) |
| Usuario no verificado | `login()` | Lanza `ForbiddenException` (403) |
| Usuario suspendido | `login()` | Lanza `ForbiddenException` (403) |
| Refresh con token válido | `refreshTokens()` | Rota el token, retorna nuevos |
| Refresh con token inválido | `refreshTokens()` | Lanza `UnauthorizedException` (401) |
| Cambio de contraseña | `changePassword()` | Revoca todas las sesiones del usuario |

**Convenciones:**
- Usar `uniqueEmail()` helper para evitar colisiones entre tests
- Mockear `MailService` con `MockMailService` (no enviar emails reales)
- Desactivar `ThrottlerGuard` en ambiente de test
- Tests en `src/auth/auth.service.spec.ts`

**Archivos afectados:**
- `src/auth/auth.service.spec.ts` (nuevo)
- `src/auth/auth.service.ts` (sin modificar, solo testear)

**Bloqueante:** No — mejora de calidad

---

### [ ] M1-DT-04 (parcial): Validación enum currentStep en UpdateOnboardingStepDto

**Descripción:** El campo `currentStep` en `UpdateOnboardingStepDto` acepta cualquier string. Esto permite escribir valores arbitrarios que corrompen el estado del onboarding. Se debe restringir a los valores válidos del enum.

**Steps válidos:**
```
email_verification | biometric_setup | profile_basic | welcome | document_upload | document_processing
```

**Implementación:**
1. Definir `OnboardingStep` enum en `src/auth/enums/onboarding-step.enum.ts`
2. Agregar `@IsEnum(OnboardingStep)` en `UpdateOnboardingStepDto`
3. Verificar que todos los servicios que escriben `currentStep` usen el enum

**Archivos afectados:**
- `src/auth/enums/onboarding-step.enum.ts` (nuevo)
- `src/auth/dto/update-onboarding-step.dto.ts` (modificar)
- `src/auth/auth.service.ts` (verificar usos de currentStep)

**Bloqueante:** No — pero es un bug latente que debe resolverse pronto

---

## Backlog (no comprometido)

### [ ] MFA — Autenticación multifactor TOTP

**Descripción:** Soporte para autenticación de dos factores con TOTP (Google Authenticator / Authy). Requiere decisión de roadmap con cliente.

**Bloqueante:** No (backlog)

---

### [ ] OAuth — Google Sign-In / Apple Sign-In

**Descripción:** Iniciar sesión con cuenta Google o Apple. Requerido por App Store si se ofrece cualquier OAuth. Requiere credenciales de cada proveedor.

**Bloqueante:** No (backlog)

---

### [ ] Gestión de dispositivos y sesiones

**Descripción:** Pantalla en la app para listar sesiones activas y revocar individualmente. Notificación push en inicio de sesión desde dispositivo nuevo.

**Bloqueante:** No (backlog, depende M2-DT-04 worker notificaciones)
