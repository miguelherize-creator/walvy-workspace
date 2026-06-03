# Deuda Técnica — Walvy

**Última actualización:** 2026-05-14

Formato: `ID — Descripción — Estado — Bloqueante`

---

## Módulo 1 — Auth & Onboarding

### M1-DT-01 — Backoffice: gestión de estado de usuario
- **RF:** RF-09
- **Estado:** ❌ Sin implementar — `src/admin/` existe pero vacío
- **Bloqueante:** Sí — requiere M1-DT-02 (RBAC) primero
- **Endpoints pendientes:** `PATCH /admin/users/:id/status` · `DELETE /admin/users/:id`
- **Qué falta:** AdminModule con endpoints protegidos por rol `admin`. Soft delete siempre.

### M1-DT-02 — RBAC: enforcement de permisos
- **RF:** RF-11
- **Estado:** ❌ Sin middleware de enforcement (tablas y seeds existen)
- **Bloqueante:** No — independiente, pero bloquea M1-DT-01
- **Qué falta:** `RbacGuard` + decorador `@RequirePermission('resource:action')`. Cachear permisos por rol (TTL 5min).

### M1-DT-03 — Job: nivel de salud financiera
- **RF:** RF-12
- **Estado:** ❌ Sin job/cron
- **Bloqueante:** Sí — bloqueado por Módulos 3 y 4 (cashflow y deudas deben existir primero)
- **Qué falta:** `@Cron()` en `src/health/` que calcule `current_financial_health_level_id` basado en transacciones + deudas.

### M1-DT-04 — Onboarding: alineación con flujo del cliente
- **RF:** RF-08
- **Estado:** ⚠️ Funciona parcialmente — no cierra nunca
- **Bloqueante:** Sí — bloqueado por M2-DT-01 (perfil financiero) y Módulo 3
- **Problemas concretos:**
  1. Auto-completado roto: exige `financialProfileCompleted = true` pero M2-DT-01 no está hecho → onboarding nunca termina
  2. `minDocThresholdMet` nunca se activa: no hay módulo de importación que lo escriba
  3. `currentStep` acepta strings libres sin validación `@IsIn([...])`
- **Qué falta:** Validar paso final con producto. Revisar si `financialProfileCompleted` sigue siendo condición. Añadir `@IsIn()` al DTO.

### M1-FE-01 — `user.email` vacío en savedUser mode
- **Detectado:** 2026-05-31
- **Estado:** ⚠️ Workaround aplicado, falta investigar backend
- **Síntomas:** `GET /users/me` devuelve user con `email: null` o `email: ""` aunque el usuario tenga sesión activa. Esto rompía `savedUserPassword` mode en LoginScreen (necesita email para enviar al backend al hacer login con password).
- **Workaround actual:** Persistencia local en SecureStore `LAST_USER_EMAIL_KEY` (ver [`decisions.md`](decisions.md) entrada 2026-05-31). `LoginScreen` y `useLoginForm` usan `effectiveEmail = user.email || savedEmail`.
- **Qué falta:** Debug en backend de `/users/me` para verificar por qué `email` no se devuelve. Probable causa: query/serializer omite el campo. Una vez corregido, el workaround puede mantenerse como capa de resiliencia pero el bug principal estará resuelto.
- **Archivos:** `Backend/MVP-CheckApp/src/users/users.controller.ts` o `users.service.ts` (revisar response shape de `getMe()`)

### M1-FE-02 — `user.firstName` vacío en savedUser mode
- **Detectado:** 2026-05-31
- **Estado:** ⚠️ Workaround aplicado (Patrón C fallback)
- **Síntomas:** Mismo problema que M1-FE-01 pero con `firstName`. El saludo personalizado "¡Hola Juancho!" no aparece (cae al genérico "Te damos la bienvenida").
- **Workaround actual:** Patrón C en LoginScreen — usar parte del email antes del `@` capitalizada como display name cuando `firstName` falta. Función `capitalize(email.split("@")[0])`.
- **Qué falta:** Mismo debug que M1-FE-01 — verificar que `/users/me` devuelve `firstName` completo. Lógica de cascada (Patrón C) puede mantenerse como fallback defensivo.
- **Archivos:** `features/auth/ui/LoginScreen.tsx` (función `displayName`)

### M1-FE-03 — Contrato `/auth/reset-password` no documentado en spec
- **Detectado:** 2026-05-31
- **Estado:** ⚠️ Resuelto en runtime, falta actualizar spec
- **Síntomas:** El frontend enviaba `{ token, newPassword }` pero el backend espera `{ email, code, newPassword }`. Resultaba en errores `property token should not exist`, `El correo es obligatorio`, `El código es obligatorio`, `newPassword must be a string`.
- **Causa raíz:** `context/specs/authentication.md` documenta el endpoint pero no el shape exacto del payload de `/auth/reset-password`. El frontend asumía un opaque `token` cuando en realidad el backend espera el código OTP de 6 dígitos + email para validar.
- **Resolución:**
  - Actualizado `api/types/auth.ts` → `ResetPasswordPayload = { email, code, newPassword }`
  - Actualizado `authRepository.resetPassword(email, code, newPassword)`
  - El URL param `token` (que es el code OTP) se mapea correctamente
- **Qué falta:** Actualizar `context/specs/authentication.md` para documentar el shape exacto del payload de `/auth/reset-password` y evitar que ocurra de nuevo en futuros refactors.
- **Archivos involucrados:** `api/types/auth.ts`, `features/auth/data/authRepository.ts`, `features/auth/hooks/useResetPasswordForm.ts`, `api/mocks/authMock.ts`

### M1-FE-04 — Touch targets bajo el mínimo recomendado (44px)
- **Detectado:** 2026-05-30 (auditorías QA pixel-perfect)
- **Estado:** ⚠️ Cumple Figma pero falla guidelines de accesibilidad
- **Síntomas:** Botones primarios usan `h-40` (Figma) y links subrayados usan `h-24`. Apple HIG y Material Design recomiendan **mínimo 44px**.
- **Pantallas afectadas:** Login, Register, VerifyCode, BiometricSetup, ChooseAlias, ResetPassword, ForgotPassword (todas las pantallas auth).
- **Workaround disponible:** `hitSlop={{ top: 12, bottom: 12, left: 8, right: 8 }}` en `Pressable` extiende el área táctil SIN modificar el aspecto visual. Ya aplicado parcialmente en algunos links.
- **Qué falta:** Aplicar `hitSlop` a TODOS los links/botones que estén por debajo de 44px. Considerar crear componente `<AuthLink>` y `<AuthButton>` que incluyan `hitSlop` por default.
- **Referencia:** Ver auditorías en `context/qa-audits/auth/` — todas mencionan este issue como Severidad Media.

---

## Módulo 2 — Perfil y Configuración

### M2-DT-01 — Perfil financiero
- **RF:** RF-02
- **Estado:** ❌ Sin endpoints (entidad y tabla existen)
- **Bloqueante:** No — independiente, pero lo bloquea M1-DT-04
- **Endpoints pendientes:** `GET /profile/financial` + `PUT /profile/financial`
- **Qué falta:** `ProfileModule` con service + controller. DTO: `monthlyIncomeEstimate`, `stableExpensesNote`, `currencyId?`. Definir cómo se calcula `estimatedPaymentCapacity`.

### M2-DT-02 — Metas financieras
- **RF:** RF-03
- **Estado:** ❌ Sin endpoints (tabla `user_goals` existe)
- **Bloqueante:** No — independiente, diseño en borrador
- **Endpoints pendientes:** `GET /profile/goals` + `POST /profile/goals` + `PATCH /profile/goals/:id/deactivate`
- **Qué falta:** Definir si son múltiples focos activos simultáneos o solo uno. `progress_cache` es solo-escritura del backend.

### M2-DT-03 — Alertas y notificaciones
- **RF:** RF-04
- **Estado:** ❌ Sin endpoints (tabla `alert_preferences` existe)
- **Bloqueante:** Sí — sin M2-DT-04 (worker) las preferencias no tienen efecto real
- **Endpoints pendientes:** `GET /profile/alerts` + `PUT /profile/alerts`

### M2-DT-04 — Worker de notificaciones
- **RF:** RF-05
- **Estado:** ❌ Sin implementar
- **Bloqueante:** Sí — requiere definir canales push (FCM/APNs pendiente de scope)
- **Qué falta:** `NotificationQueueService.enqueue()` + worker `@Cron()` que procese `WHERE sent_at IS NULL AND scheduled_for <= now()`. Decidir canales MVP: ¿solo `in_app` + `email`, o también `push`?

---

## Cadena de bloqueos

```
M1-DT-02 (RBAC)
    └── bloquea M1-DT-01 (admin endpoints)

M2-DT-01 (perfil financiero)
    └── desbloquea M1-DT-04 (onboarding cierra)

Módulo 3 (cashflow) + Módulo 4 (deudas)
    └── desbloquean M1-DT-03 (job salud financiera)

M2-DT-04 (worker notificaciones)
    └── desbloquea M2-DT-03 (alertas con efecto real)
    └── desbloquea Sprint 7 (pagos recurrentes + push)
```

---

## Leyenda

| Símbolo | Significado |
|---------|-------------|
| ❌ | No implementado |
| ⚠️ | Implementado parcialmente |
| ✅ | Cerrado |
| Bloqueante: Sí | Hay otro módulo que depende de este |
