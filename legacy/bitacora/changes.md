# Bitácora de cambios

---

## 2026-05-14 — Índice de documentación para Product Management + tag v1.0.0

### Commit sugerido

```
docs: add API index for PM + mark v1.0.0 (Módulo 1 + 2 functional)
```

### Tag

```
v1.0.0
```

> **Qué representa v1.0.0:** cierre de Módulo 1 (Auth & Onboarding, 13 endpoints) y Módulo 2 funcional (Perfil, Cambio de contraseña, Suscripciones, 6 endpoints). Suite e2e de 75 pruebas. Primera versión del backend lista para integración con frontend.

### Resumen de cambios

- `docs/README.md` — índice en español para Product Management: estado por módulo, tabla de endpoints con auth requerida, pasos y checkpoints del onboarding, planes de suscripción, pendientes M2, reglas de negocio clave

---

## 2026-05-14 — Suite e2e desde cero (76 tests, 10 suites)

### Commit sugerido

```
test(e2e): crear suite de pruebas desde cero basada en colección Postman
```

### Resumen de cambios

- `test/jest-e2e.json` — +testTimeout 30s, maxWorkers:1
- `test/helpers/mail.mock.ts` — MockMailService intercepta OTPs sin SMTP real
- `test/helpers/app.helper.ts` — bootstrap con ThrottlerGuard desactivado; helpers `registerUser`, `registerAndVerify`, `uniqueEmail`
- `test/auth/register.e2e-spec.ts` — happy path, 409 duplicado, validaciones RUT/password/terms
- `test/auth/email-verification.e2e-spec.ts` — confirm OTP, request, resend
- `test/auth/login.e2e-spec.ts` — usuario verificado, no verificado, credenciales inválidas
- `test/auth/session.e2e-spec.ts` — refresh con rotación, reuse detection (revokeAll), logout, logout-all
- `test/auth/password.e2e-spec.ts` — forgot/reset OTP + changePassword (revoca sesiones)
- `test/auth/onboarding.e2e-spec.ts` — GET estado, PATCH biometric, PATCH step/checkpoints
- `test/users/profile.e2e-spec.ts` — GET/PATCH me, PATCH profile
- `test/subscriptions/plans.e2e-spec.ts` — GET plans (slug, price numérico), GET me, checkout guards

**Bugs encontrados durante primera pasada (corregidos en tests):**
- `changePassword` lanza 401 (no 400) cuando la contraseña actual es incorrecta
- Reuso de refresh token revocado activa `revokeAllRefreshForUser` (reuse detection) — invalida también el token recién rotado
- La entidad `SubscriptionPlan` expone `slug`, no `code`
- `logout` es idempotente: siempre 201 aunque el token ya esté revocado

---

## 2026-05-14 — Modelo de precios suscripciones (pro_monthly + pro_annual)

### Commit sugerido

```
feat(subscriptions): replace free+pro seed with dynamic pro_monthly/pro_annual pricing

- Remove Free plan from seed — trial period is handled by app_user.trial_ends_at
- Add pro_monthly (PLAN_PRO_MONTHLY_PRICE, 30 days) and pro_annual
  (PLAN_PRO_ANNUAL_PRICE, 365 days) as the two available plans
- Seed does upsert: if price env var changes, the plan is updated on next restart
  without manual SQL — price change = update env var + restart
- Annual features[] auto-calculates savings label from monthly vs annual prices
- Fix SubscriptionPlan.price: numeric(12,2) was returned as string by TypeORM;
  add decimalToNumber transformer so price comparisons and toLocaleString() work
- Add PLAN_PRO_MONTHLY_PRICE and PLAN_PRO_ANNUAL_PRICE to .env.example
```

### Resumen de cambios

#### Entidad
- `src/subscriptions/entities/subscription-plan.entity.ts` — transformer `decimalToNumber` en `price` (bug: numeric retornaba string)

#### Seed
- `src/subscriptions/services/subscription-seed.service.ts` — reemplaza Free+Pro por `pro_monthly`/`pro_annual`; upsert con `ConfigService`; calcula ahorro anual automáticamente

#### Env
- `.env.example` — agrega `PLAN_PRO_MONTHLY_PRICE=5000` y `PLAN_PRO_ANNUAL_PRICE=50000`

---

## 2026-05-14 — Módulo 2: corrección entidades P1–P5 + refactor firstName/lastName

### Commit sugerido

```
fix(module2): align entities to DB spec (P1-P5) + split fullName into firstName/lastName

Entity fixes:
- P1/P5 notification_queue: replace bills_payable_id UUID with reference_type TEXT
  + reference_id UUID nullable; add length:10 to channel column
- P2 user_financial_profile: add decimalToNumber transformer to
  monthlyIncomeEstimate and estimatedPaymentCapacity; bigintToNumberNullable
  to currencyId — fixes TypeORM returning numeric/bigint as string
- P3 user_goals: fix goalType varchar(50) → varchar(40) per DB spec;
  add decimalToNumber transformer to targetValue
- P4 alert_preferences: add length:10 to channel column

User model refactor:
- Remove full_name VARCHAR(200) from app_user entity — was ambiguous for
  compound names (e.g. "Ana María García López")
- Add first_name VARCHAR(100) nullable and last_name VARCHAR(100) nullable
- UpdateProfileDto: replace fullName with firstName + lastName, remove email field
- UpdateDisplayNameDto: replace fullName with firstName + lastName
- users.service.ts: update create(), updateProfile(), updateDisplayName() and
  toPublic() — toPublic() now returns firstName, lastName, documentNumber
```

### Resumen de cambios

#### Entidades Module 2
- `src/notifications/entities/notification-queue.entity.ts` — P1: `billsPayableId` → `referenceType + referenceId`; P5: `channel length:10`
- `src/profile/entities/user-financial-profile.entity.ts` — P2: transformers decimal en `monthlyIncomeEstimate`, `estimatedPaymentCapacity`; bigint en `currencyId`
- `src/profile/entities/user-goal.entity.ts` — P3: `goalType varchar(40)`; transformer decimal en `targetValue`
- `src/notifications/entities/alert-preferences.entity.ts` — P4: `channel length:10`

#### User model
- `src/users/entities/user.entity.ts` — columna `fullName` eliminada; `firstName` + `lastName` agregadas como `varchar(100) nullable`
- `src/users/dto/update-profile.dto.ts` — reemplazado `fullName` por `firstName` + `lastName`; eliminado `email`
- `src/users/dto/update-display-name.dto.ts` — reemplazado `fullName` por `firstName` + `lastName`
- `src/users/users.service.ts` — `create()`, `updateProfile()`, `updateDisplayName()`, `toPublic()` actualizados; `toPublic()` ahora expone `firstName`, `lastName`, `documentNumber`

#### Pendientes del equipo frontend
- `PATCH /users/profile` (onboarding): debe enviar `firstName` + `lastName` en lugar de `fullName`
- `PATCH /users/me` (mis datos): debe enviar `firstName` + `lastName`, sin campo `email`

---

---

## 2026-05-13 — Recuperación de contraseña OTP + email inmutable en perfil

### Commit sugerido

```
feat(auth): replace password reset magic link with OTP + lock email on profile update

Password reset flow:
- Add attempts column (int, default 0) to password_reset_tokens entity
- forgotPassword(): generate 6-digit OTP via generateSixDigitCode(), store
  hashed, send via sendPasswordResetOtp() — deletes previous token first,
  expires in 15 min (down from 60)
- resetPassword(): accept (email, code, newPassword); look up token by userId,
  verify hash, track attempts (max 5 with remaining-count message), revoke
  all sessions on success
- ResetPasswordDto: replace token with email + code (@Matches /^\d{6}$/)
- New password-reset-otp.template.ts — reuses formatOtpTwoBlocks pattern
- mail.service.ts: sendPasswordResetEmail() → sendPasswordResetOtp()

Profile update:
- Remove email field from UpdateProfileDto and updateProfile() service method
  — email is immutable after registration for MVP
- Remove ConflictException branch that was re-verifying email on PATCH /users/me

Docs:
- docs/api/auth/password-reset.md — new; 2-step OTP flow, errors, attempt messages
- docs/api/users/me.md — new; GET + PATCH /users/me, 3 updatable fields only
- docs/postman: resetToken var → resetOtpCode, reset-password body updated
- docs/sql/dev-queries.md — password_reset_tokens queries added
```

---

### Resumen de cambios

#### Entidad
- `src/auth/entities/password-reset-token.entity.ts` — nueva columna `attempts: int DEFAULT 0`

#### DTO
- `src/auth/dto/reset-password.dto.ts` — reemplazado `token: string` por `email: string` + `code: string` (`@Matches(/^\d{6}$/)`)
- `src/users/dto/update-profile.dto.ts` — eliminado campo `email` e import `IsEmail`

#### Auth flow
- `auth.service.ts` — `forgotPassword()`: usa `generateSixDigitCode()` + `hashOpaqueToken()`, llama `sendPasswordResetOtp()`; expiración 15 min
- `auth.service.ts` — `resetPassword()`: firma cambia a `(email, code, newPassword)`; busca token por `userId` (latest), verifica hash, incrementa `attempts` si falla (max 5), invalida sesiones al éxito
- `auth.controller.ts` — llama `resetPassword(dto.email, dto.code, dto.newPassword)`

#### Users
- `users.service.ts` — `updateProfile()`: eliminado bloque de actualización de email y `emailVerifiedAt = null`; el email queda inmutable desde el perfil

#### Mail
- `mail.service.ts` — `sendPasswordResetEmail()` reemplazado por `sendPasswordResetOtp(to, code)`
- `src/mail/templates/password-reset-otp.template.ts` — nuevo; mismo patrón que `email-verification.template.ts` con copy de recuperación

#### Docs
- `docs/api/auth/password-reset.md` — nuevo; flujo de 2 pasos, tabla de errores, mensajes de intentos, diagrama de secuencia
- `docs/api/users/me.md` — nuevo; GET + PATCH `/users/me`, 3 campos actualizables (`fullName`, `username`, `avatarUrl`), nota explícita email no modificable
- `docs/postman/Walvy-Modulo1.postman_collection.json` — variable `resetToken` → `resetOtpCode`; body de reset-password actualizado a `{ email, code, newPassword }`; descripciones de los 2 pasos actualizadas
- `docs/sql/dev-queries.md` — queries para `password_reset_tokens`: ver OTP activo, limpiar para re-testear

---

## 2026-05-13 — Onboarding alineado a flujo UI (C1–C4)

### Commit sugerido

```
feat(onboarding): align step flow to Figma UI — C1 through C4

- confirmEmailVerification() advances to biometric_setup instead of profile
- updateBiometric() marks biometric_prompted=true always (activate or skip)
  — represents the user saw the screen, not that they enabled biometrics
- Add PATCH /users/profile with UpdateDisplayNameDto: fullName + username,
  cross-field validation (at least one non-empty), app concatenates
  nombre+apellido into fullName before sending
- Remove goalsSet from onboarding auto-completion condition — no UI screen
  assigned yet, was blocking onboarding from ever reaching completed
- Rewrite docs/api/auth/onboarding.md: new step registry (biometric_setup,
  profile_basic, welcome, document_upload, document_processing), full
  integration flow with resume_surface/resume_context examples per transition
- Add docs/api/users/profile.md: UI→backend field mapping, button behavior
- Update docs/api/auth/biometric.md: biometric_prompted always-set note
```

---

### Resumen de cambios

#### auth.service.ts
- `confirmEmailVerification()` — `current_step` avanza a `biometric_setup` en lugar de `profile` (C1)
- `updateBiometric()` — `biometric_prompted = true` siempre, fuera del bloque `if (enabled)` (C2)
- `updateOnboardingStep()` — `goalsSet` eliminado de la condición de auto-completion (C4)

#### users/
- `src/users/dto/update-display-name.dto.ts` — nuevo; `fullName?: string`, `username?: string`, ambos opcionales con validación individual
- `src/users/users.service.ts` — `updateDisplayName()`: valida cross-field (al menos uno no vacío), no sobreescribe email ni avatar
- `src/users/users.controller.ts` — `PATCH /users/profile` con JWT guard

#### Docs
- `docs/api/auth/onboarding.md` — reescrito: registry de steps con nuevos nombres (`biometric_setup`, `profile_basic`, `welcome`, `document_upload`, `document_processing`), flujo de integración completo, ejemplos por transición
- `docs/api/users/profile.md` — nuevo: mapeo 3 campos UI → 2 campos API, regla de validación, comportamiento por botón
- `docs/api/auth/biometric.md` — nota actualizada: `biometric_prompted` siempre true

#### Step names nuevos
| Antes | Ahora |
|---|---|
| `profile` (tras email confirm) | `biometric_setup` |
| `name_setup` | `profile_basic` |
| `import` | `document_upload` |
| `analyzing` | `document_processing` |

---

## 2026-05-12 — Revisión onboarding UI vs backend

### Estado
Análisis completado — sin cambios de código. Cambios pendientes para mañana.

### Documento de referencia
`bitacora/onboarding_review.md` — flujo completo Figma, mini-matriz de transiciones, 6 incoherencias detalladas, 8 cambios priorizados (C1–C8).

### Resumen de hallazgos

#### Flujo UI (happy path completo)
registro → verificación email → biometría (sí/no) → nombre + alias → bienvenida → carga de cartolas → analizando → perfil financiero

#### Incoherencias críticas detectadas
- `confirmEmailVerification()` avanza a `current_step = 'profile'` en lugar de `'biometric'`
- `PATCH /auth/biometric` solo marca `biometric_prompted = true` al activar; si el usuario salta el paso el checkpoint nunca se registra
- `financial_profile_completed` está mapeado al paso nombre/alias pero corresponde al resultado del análisis de cartolas
- `goals_set` no tiene pantalla en el flujo UI actual — bloquea la auto-completion del onboarding
- Steps `biometric`, `name_setup`, `welcome`, `analyzing` no están documentados en la DB
- `resume_surface` / `resume_context` no se escriben en los flujos de salida (A, B, C)

#### Cambios pendientes (prioridad alta)
- C1 — `confirmEmailVerification()` → avanzar a `biometric` no a `profile`
- C2 — `PATCH /auth/biometric` → marcar `biometric_prompted = true` siempre
- C3 — Definir y documentar nuevos valores de `current_step`
- C4 — Endpoint para persistir nombre + alias (`PATCH /users/profile`)

#### Pendiente de decisión de producto
- C5 — Qué dispara `financial_profile_completed` (¿módulo cashflow?)
- C6 — Qué pasa con `goals_set` (¿post-MVP, opcional, o se elimina de la condición de completion?)

---

## 2026-05-12 — RF-07 logout-all + RF-08 onboarding

### Commit sugerido

```
feat(auth): implement RF-07 POST /auth/logout-all and RF-08 onboarding endpoints

- Add POST /auth/logout-all (JWT required): revokes all active refresh tokens for
  the authenticated user — delegates to existing revokeAllRefreshForUser()
- Add GET /auth/onboarding: returns full user_onboarding_state for the app to
  decide whether to show the pending onboarding step on open
- Add PATCH /auth/onboarding/step: partial update of onboarding fields; auto-advances
  to onboarding_status=completed when all five checkpoints are true
- Create UpdateOnboardingStepDto with optional boolean checkpoints + step/surface/context
- Add docs/api/auth/logout-all.md and docs/api/auth/onboarding.md
```

---

### Resumen de cambios

#### Auth flow
- `auth.service.ts` — `logoutAll(userId)`: llama `revokeAllRefreshForUser()`, retorna `{ ok: true }`
- `auth.service.ts` — `getOnboarding(userId)`: busca y retorna `user_onboarding_state` vía `toOnboardingPublic()`
- `auth.service.ts` — `updateOnboardingStep(userId, dto)`: actualiza solo los campos enviados; si todos los checkpoints `true` y status no es `completed` → avanza automáticamente a `completed`, limpia `currentStep`, pone `resumeSurface = 'home'`
- `auth.service.ts` — `toOnboardingPublic()`: helper privado que projeta los campos públicos del estado
- `auth.controller.ts` — `POST /auth/logout-all` con JWT guard
- `auth.controller.ts` — `GET /auth/onboarding` con JWT guard
- `auth.controller.ts` — `PATCH /auth/onboarding/step` con JWT guard

#### DTO
- `src/auth/dto/update-onboarding-step.dto.ts` — todos los campos opcionales: `currentStep`, `resumeSurface`, `resumeContext`, `financialProfileCompleted`, `goalsSet`, `importAttempted`, `biometricPrompted`, `minDocThresholdMet`

#### Docs
- `docs/api/auth/logout-all.md` — request/response y flujo
- `docs/api/auth/onboarding.md` — GET + PATCH, tabla de pasos, flujo completo

---

## 2026-05-12 — RF-06 biométrico

### Commit sugerido

```
feat(auth): implement RF-06 PATCH /auth/biometric — activate/deactivate biometric auth

- Create UpdateBiometricDto with enabled (required), method (required on enable,
  validated against face_id|fingerprint|device_pin), deviceId (optional)
- Add updateBiometric() to AuthService: validates method when enabling, upserts
  biometric_preferences, marks biometric_prompted=true in user_onboarding_state on enable,
  clears method/deviceId on disable
- Add PATCH /auth/biometric endpoint to AuthController with JWT guard
- Add docs/api/auth/biometric.md with request/response and both flows
```

---

### Resumen de cambios

#### DTO
- `src/auth/dto/update-biometric.dto.ts` — nuevo; `enabled: boolean`, `method?: string` (`@IsIn` sobre `face_id|fingerprint|device_pin`), `deviceId?: string`

#### Auth flow
- `auth.service.ts` — `updateBiometric()`: si `enabled=true` y falta `method` → 400; actualiza `biometric_preferences`; al activar marca `biometric_prompted=true` en `user_onboarding_state`; al desactivar limpia `method` y `deviceId`
- `auth.controller.ts` — `PATCH /auth/biometric` con `@UseGuards(AuthGuard('jwt'))`

#### Docs
- `docs/api/auth/biometric.md` — request/response, flujo de activación y desactivación

---

## 2026-05-12 — RF-03 refresh token

### Commit sugerido

```
fix(auth): implement replay attack protection on POST /auth/refresh — RF-03

- Separate revoked vs not-found check: if token exists but is already revoked,
  revoke ALL active sessions for the user before returning 401
- Previously all failure cases (not found, revoked, expired) hit the same branch
  with no side effect — missing the replay attack mitigation from RF-03 spec
- Remove unused relations: ['user'] from refreshRepo.findOne (user loaded separately)
- Add docs/api/auth/refresh.md with full request/response spec for frontend
```

---

### Resumen de cambios

#### Auth flow
- `auth.service.ts` — `refresh()` separa los casos de fallo: token no encontrado → 401 genérico; token revocado → `revokeAllRefreshForUser()` + 401 (replay attack); token expirado → 401 genérico
- `auth.service.ts` — eliminado `relations: ['user']` innecesario en `refreshRepo.findOne` (el usuario se carga por separado con `findById`)

#### Docs
- `docs/api/auth/refresh.md` — creado con request/response, flujo normal y flujo replay attack

---

## 2026-05-12 — RF-07 logout individual

### Commit sugerido

```
docs(auth): add logout endpoint doc — RF-07 POST /auth/logout already aligned
```

---

### Resumen de cambios

#### Docs
- `docs/api/auth/logout.md` — creado con request/response, flujo y nota sobre access token

> Sin cambios de código — implementación ya estaba alineada con RF-07.

---

## 2026-05-12 — RF-05 + fixes

### Commit sugerido

```
feat(auth): align RF-05 email verification and fix login flow for unverified users

- Login for pending_verification users now issues tokens and auto-resends OTP
  instead of returning 401 — prevents users from being locked out after token expiry
- Move password validation before status check to avoid leaking email existence
- Add bigint→number transformers to User entity (TypeORM returns bigint as string,
  breaking strict equality checks against CatalogDefaults IDs)
- Add explicit throttle (3/hour) to POST /auth/email-verification/request
- Replace @Length(6,6) with @Matches(/^\d{6}$/) on confirm DTO — rejects non-numeric codes
- Remove fullName param from sendEmailVerificationCode and buildOtpAndPersist
- Redesign email verification template: OTP as two 3-digit blocks, updated copy,
  postDividerRows/omitFooterDisclaimer layout hooks in base shell
- Improve preview.ts: reads mascot/logo/isotype URLs from .env with variable expansion
- Clean up comments: remove section separators, shorten JSDoc to one-liners,
  remove Figma node references
- Update docs/api/auth/login.md and email-verification.md
```

---

### Resumen de cambios

#### Auth flow
- `auth.service.ts` — `login()` con `pending_verification` emite tokens + reenvía OTP automáticamente (fix: usuario atascado al expirar token de registro)
- `auth.service.ts` — validación de contraseña movida antes del check de status (evita revelar existencia del email)
- `auth.controller.ts` — `POST /auth/email-verification/request` agrega `@Throttle({ short: { limit: 3, ttl: 3600000 } })`

#### DTO / Validación
- `confirm-email-verification.dto.ts` — `@Length(6,6)` reemplazado por `@Matches(/^\d{6}$/)` — rechaza códigos con letras

#### DB / Entidades
- `user.entity.ts` — transformers `bigintToNumber` y `bigintToNumberNullable` en todas las columnas `bigint` (TypeORM devuelve bigint como string desde PostgreSQL, rompía comparaciones estrictas con IDs de `CatalogDefaults`)

#### Mail
- `mail.service.ts` — eliminado parámetro `fullName` de `sendEmailVerificationCode`; removidos separadores de sección decorativos
- `email-verification.template.ts` — OTP en formato dos bloques de 3 dígitos (`123 456`); copy actualizado; `postDividerRows` para disclaimer del pie
- `base.ts` — `footerRows` dividida en `footerDisclaimerRow` + `footerSignOffRow`; interfaz `EmailShellOptions` agrega `postDividerRows` y `omitFooterDisclaimer`; JSDoc reducidos a una línea
- `preview.ts` — lee `MAIL_MASCOT_URL`, `MAIL_LOGO_URL`, `MAIL_ISOTYPE_URL` desde `.env` con resolución de variables `${VAR}`

#### Docs
- `docs/api/auth/login.md` — documenta respuesta 200 para `pending_verification` con `nextStep: "email_verification"`
- `docs/api/auth/email-verification.md` — creado con los 3 endpoints: request, confirm, resend

---

## 2026-05-12 — RF-02

### Commit sugerido

```
fix(auth): align RF-02 POST /auth/login to DB v2 and MVP docs

- Restrict login identifier to email only; remove username/identifier multi-field
- Remove unique constraint on username — display alias only, not an identifier
- Add user_status_id validation: 401 for pending_verification, 403 for suspended,
  403 generic fallback for any unknown future status
- Add deleted_at IS NULL filter to findByEmailWithPassword and findByIdWithPassword
  QueryBuilders (TypeORM does not apply soft-delete filter automatically on QB)
- Change REFRESH_EXPIRES_DAYS default from 7 to 30 to match RF-02 spec
- Expose suspendedStatusId in CatalogDefaults; capture suspended status in seed
- Add docs/api/auth/login.md with full request/response spec for frontend
```

---

### Resumen de cambios

#### DTO / Validación
- `login.dto.ts` — campo `identifier` renombrado a `email`; agregado `@IsEmail()`; eliminado soporte de login por username

#### Auth flow
- `auth.service.ts` — `login()` agrega validación de `user_status_id`: 401 si `pending_verification`, 403 explícito si `suspended`, 403 genérico para cualquier estado futuro desconocido
- `auth.service.ts` — `issueTokens()` cambia default de `REFRESH_EXPIRES_DAYS` de 7 a 30 días (alineado con RF-02)
- `auth.service.ts` — llama a `findByEmailWithPassword` en lugar de `findByIdentifierWithPassword`

#### Users / Entidades
- `users.service.ts` — `findByIdentifierWithPassword` reemplazado por `findByEmailWithPassword` (solo email, rama username eliminada)
- `users.service.ts` — `findByIdWithPassword` corregido: agrega `.andWhere('user.deletedAt IS NULL')` (QueryBuilder no aplica soft-delete automáticamente)
- `users.service.ts` — `updateProfile()` elimina check de unicidad de username
- `user.entity.ts` — removido `unique: true` del campo `username` (es alias de experiencia, no identificador)

#### Catalog / Seed
- `catalog-seed.service.ts` — `CatalogDefaults` agrega `suspendedStatusId`; `suspended` capturado como variable en `seed()` y expuesto en defaults

#### Docs
- `docs/api/auth/login.md` — request/response completo del endpoint para el frontend

---

## 2026-05-11

### Commit sugerido

```
feat(auth): implement RF-01 POST /auth/register aligned to DB v2 and MVP docs

- Replace magic link with 6-digit OTP email verification (15 min expiry, 5 attempt limit)
- Add RUT validation using Módulo 11 via extensible DocumentValidatorFactory strategy
- Add accepted_privacy_at column to app_user and require acceptPrivacy on register
- Make documentNumber required; remove fullName and confirmPassword from registration
- Simplify password policy to 8+ chars, one uppercase, one number
- Seed document_type with validation_regex; expose rutDocumentTypeId/Code in CatalogDefaults
- Create user_onboarding_state with not_started, advance to in_progress on email confirm
- Create user_gamification_stats (total_points=0, level=1) and biometric_preferences on register
- Set user_status_id = pending_verification on register, promote to active on email confirm
- Activate trial period from TRIAL_DAYS_DEFAULT config on register
- Add docs/api/auth/register.md with full request/response spec for frontend
- Align DB/modulo1 docs (RF-01, CU-01, documentacion.md) with implementation
```

---

### Resumen de cambios

#### DTO / Validación
- `register.dto.ts` — eliminados `fullName`, `confirmPassword`; `documentNumber` pasa a requerido; agregado `acceptPrivacy`; política de password simplificada (mayúscula + número)
- `reset-password.dto.ts` — misma política de password

#### Auth flow
- `auth.service.ts` — flujo completo OTP (eliminado magic link), validación RUT vía Módulo 11, gamification stats, `accepted_privacy_at`, trial period, `onboardingStatus: not_started` al registro → `in_progress` al confirmar email
- `auth.controller.ts` — eliminado `GET /email-verification/confirm/:token`, limpieza de imports, throttle de resend corregido a 1h

#### DB / Entidades
- `user.entity.ts` — nueva columna `accepted_privacy_at`
- `document-type.entity.ts` — nueva columna `validation_regex`
- `catalog-seed.service.ts` — seed RUT con regex Módulo 11, `pending_verification` status, `rutDocumentTypeId/Code` en defaults

#### Validadores
- `src/common/validators/document/` — interfaz + `RutValidator` (Módulo 11) + factory extensible por código de documento

#### Mail
- Template reemplazado: de magic link button → 6 dígitos visuales

#### Docs
- `DB/modulo1/` — RF-01, CU-01, `documentacion.md` alineados con la implementación
- `docs/api/auth/register.md` — request/response del endpoint para el frontend
