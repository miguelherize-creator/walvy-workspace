# Spec: Autenticación

**Estado backend:** ✅ Completo  
**Estado frontend:** ✅ Completo (`features/auth/`)  
**Módulo NestJS:** `src/auth/`

---

## Flujo completo

Las 14 rutas de `@Controller('auth')`. Contrastado contra `walvy/main` (`dd084c7`) y
`front-walvy/expo/api/endpoints.ts` — el frontend declara 13: no llama `logout-all`.

```
REGISTRO
  POST /auth/register              → crea usuario (pending_verification) + envía OTP email
  POST /auth/email-verification/request  → (re)envía OTP al correo indicado · JWT
  POST /auth/email-verification/confirm  → activa usuario + retorna tokens
  POST /auth/email-verification/resend   → reenvía OTP si expiró · máx 3/hora

LOGIN
  POST /auth/login                 → identifier (email/RUT/username) + password → tokens

SESIÓN
  POST /auth/refresh               → rota tokens (invalida refresh anterior)
  POST /auth/logout                → revoca refresh token
  POST /auth/logout-all            → revoca todos los refresh del usuario

RECUPERACIÓN
  POST /auth/forgot-password       → envía OTP reset por email
  POST /auth/verify-reset-code     → valida el OTP antes de pedir la nueva clave
  POST /auth/reset-password        → valida OTP + actualiza password

BIOMETRÍA
  PATCH /auth/biometric            → activa/desactiva la preferencia (method, deviceId)

ONBOARDING
  GET  /auth/onboarding            → estado actual del onboarding
  PATCH /auth/onboarding/step      → avanza un paso ⚠️ parcialmente implementado (M1-DT-04)
```

No existe endpoint de validación biométrica: el desbloqueo se resuelve en el dispositivo con
`expo-local-authentication` sobre credenciales guardadas, y termina en `POST /auth/login`. El
backend nunca ve clave pública ni firma — sólo la preferencia. Es lo que exige `M01-BIO-001`.

## Contratos clave

### POST /auth/register
```json
// Request
{ "email": "user@walvy.cl", "rut": "12345678-5",
  "firstName": "Juan", "lastName": "Pérez",
  "password": "MiClave123!", "confirmPassword": "MiClave123!",
  "acceptTerms": true, "acceptPrivacy": true }

// Response 201
{ "userId": "uuid", "message": "OTP enviado" }
// Errors: 409 email/rut duplicado · 400 password débil · 400 RUT inválido
```

### POST /auth/login
```json
// Request — identifier acepta email, RUT o username
{ "identifier": "user@walvy.cl", "password": "MiClave123!" }

// Response 200
{ "accessToken": "jwt_15min", "refreshToken": "opaque_7d",
  "user": { "id", "email", "firstName", "lastName", "onboardingDone" } }
// Errors: 401 credenciales inválidas · 403 cuenta suspendida · 429 rate limit
```

### POST /auth/refresh
```json
// Request
{ "refreshToken": "opaque_token" }
// Response 200 → nuevo par de tokens
// Si el token ya estaba revocado → revoca TODOS los del usuario (replay attack)
```

## Reglas de negocio
- Password: mín 8 chars, una mayúscula y un número (`/^(?=.*[A-Z])(?=.*\d)/` en los tres DTOs).
  No exige minúscula ni carácter especial, y no hay reglas de reutilización ni expiración — la
  política efectiva está en decisión en el pendiente 3 de `M1-RN-ACC-*` (#43)
- OTP: 6 dígitos, expira en `EMAIL_VERIFICATION_EXPIRES_MINUTES` (default 15)
- Solo usuarios con `status = active` pueden hacer login
- `username` es handle opcional (no se pide en registro)
- Rate limiting en `/auth/login` y `/auth/forgot-password` (5 req/min)
- Refresh tokens almacenados hasheados en DB, nunca en texto plano

## Tablas involucradas
`app_user` · `refresh_tokens` · `otp_tokens` · `biometric_preferences` · `user_onboarding_state`
