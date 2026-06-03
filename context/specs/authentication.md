# Spec: Autenticación

**Estado backend:** ✅ Completo  
**Estado frontend:** ✅ Completo (`features/auth/`)  
**Módulo NestJS:** `src/auth/`

---

## Flujo completo

```
REGISTRO
  POST /auth/register              → crea usuario (pending_verification) + envía OTP email
  POST /auth/email-verification/confirm  → activa usuario + retorna tokens
  POST /auth/email-verification/resend   → reenvía OTP si expiró

LOGIN
  POST /auth/login                 → email+password → access+refresh tokens
  POST /auth/biometric/validate    → firma criptográfica → access+refresh tokens

SESIÓN
  POST /auth/refresh               → rota tokens (invalida refresh anterior)
  POST /auth/logout                → revoca refresh token
  POST /auth/logout/all            → revoca todos los refresh del usuario

RECUPERACIÓN
  POST /auth/forgot-password       → envía OTP reset por email
  POST /auth/reset-password        → valida OTP + actualiza password

BIOMETRÍA
  POST /auth/biometric/register    → registra clave pública del dispositivo
  DELETE /auth/biometric/:deviceId → revoca biometría de un dispositivo

ONBOARDING
  GET  /auth/onboarding/state      → estado actual del onboarding
  PATCH /auth/onboarding/step      → avanza un paso ⚠️ parcialmente implementado (M1-DT-04)
```

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
- Password: mín 8 chars, mayúscula, minúscula, número, carácter especial
- OTP: 6 dígitos, expira en `EMAIL_VERIFICATION_EXPIRES_MINUTES` (default 15)
- Solo usuarios con `status = active` pueden hacer login
- `username` es handle opcional (no se pide en registro)
- Rate limiting en `/auth/login` y `/auth/forgot-password` (5 req/min)
- Refresh tokens almacenados hasheados en DB, nunca en texto plano

## Tablas involucradas
`app_user` · `refresh_tokens` · `otp_tokens` · `biometric_preferences` · `user_onboarding_state`
