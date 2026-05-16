# Spec: Módulo de Autenticación

> **Módulo:** `auth`
> **Backend:** NestJS 10 — `src/auth/`
> **Última revisión:** 2026-05-14

---

## 1. Descripción funcional

El módulo de autenticación gestiona el ciclo de vida completo de la identidad del usuario en Walvy: registro, verificación de correo, inicio de sesión, renovación de tokens, cierre de sesión, recuperación de contraseña y autenticación biométrica.

**Para el PM:** Permite que los usuarios creen una cuenta, verifiquen su correo electrónico con un código OTP, inicien sesión con email/contraseña o biometría, y recuperen el acceso en caso de contraseña olvidada. La sesión se maneja mediante tokens JWT de corta duración con renovación automática.

**Para el desarrollador:** Implementa JWT Bearer (access 15 min) + refresh token rotativo (7 días) almacenado en tabla `refresh_tokens`. El registro emite un OTP de 6 dígitos vía email. La recuperación de contraseña emite un token UUID de un solo uso. La biometría registra una clave pública en base de datos y valida firma en cada uso.

---

## 2. Flujo completo

```
REGISTRO
  ┌─ POST /auth/register
  │    └─ Crea usuario (estado: pending_verification)
  │    └─ Envía email con OTP 6 dígitos (expira 15 min)
  │
  ├─ POST /auth/email-verification/confirm  (OTP)
  │    └─ Usuario pasa a estado: active
  │    └─ Retorna access_token + refresh_token
  │
  └─ POST /auth/email-verification/resend   (reenvío si OTP expiró)

LOGIN
  ┌─ POST /auth/login
  │    └─ Valida email + password
  │    └─ Solo usuarios active pueden iniciar sesión
  │    └─ Retorna access_token + refresh_token
  │
  └─ POST /auth/biometric/validate          (alternativa biométrica)
       └─ Valida firma criptográfica con clave pública registrada
       └─ Retorna access_token + refresh_token

SESIÓN ACTIVA
  ├─ POST /auth/refresh
  │    └─ Recibe refresh_token, emite nuevo par de tokens
  │    └─ Invalida el refresh_token anterior (rotación)
  │
  └─ Cualquier endpoint protegido usa Bearer access_token

LOGOUT
  ├─ POST /auth/logout           (revoca refresh_token actual)
  └─ POST /auth/logout-all       (revoca todos los refresh_tokens del usuario)

RECUPERACIÓN DE CONTRASEÑA
  ├─ POST /auth/forgot-password
  │    └─ Envía email con token UUID (expira 1 hora)
  │
  └─ POST /auth/reset-password
       └─ Recibe token + nueva contraseña
       └─ Invalida el token de recuperación
       └─ Revoca todos los refresh_tokens del usuario

ONBOARDING (post-autenticación)
  ├─ GET  /auth/onboarding       (estado actual del onboarding)
  └─ PATCH /auth/onboarding/step (actualiza currentStep)
```

---

## 3. Endpoints implementados

| Método | Ruta | Auth | Descripción | Status HTTP |
|--------|------|------|-------------|-------------|
| POST | `/auth/register` | No | Crea cuenta nueva | 201 |
| POST | `/auth/login` | No | Inicio de sesión | 200 |
| POST | `/auth/refresh` | No (body) | Renueva tokens | 200 |
| POST | `/auth/logout` | JWT | Cierra sesión actual | 200 |
| POST | `/auth/logout-all` | JWT | Cierra todas las sesiones | 200 |
| POST | `/auth/forgot-password` | No | Solicita reset de contraseña | 200 |
| POST | `/auth/reset-password` | No (body token) | Aplica nueva contraseña | 200 |
| POST | `/auth/email-verification/request` | JWT | Solicita nuevo OTP | 200 |
| POST | `/auth/email-verification/confirm` | No | Confirma OTP | 200 |
| POST | `/auth/email-verification/resend` | No | Reenvía OTP | 200 |
| POST | `/auth/biometric/register` | JWT | Registra clave pública | 201 |
| POST | `/auth/biometric/validate` | No | Valida firma biométrica | 200 |
| GET | `/auth/onboarding` | JWT | Obtiene estado onboarding | 200 |
| PATCH | `/auth/onboarding/step` | JWT | Actualiza step onboarding | 200 |

---

## 4. Contratos de request/response

### POST /auth/register

**Request body:**
```json
{
  "email": "string (email válido, requerido)",
  "password": "string (requerido, ver reglas)",
  "firstName": "string (requerido)",
  "lastName": "string (requerido)",
  "documentNumber": "string (RUT chileno, formato 12345678-5, opcional)"
}
```

**Response 201:**
```json
{
  "message": "Registro exitoso. Revisa tu correo para verificar tu cuenta.",
  "userId": "uuid"
}
```

---

### POST /auth/login

**Request body:**
```json
{
  "email": "string (requerido)",
  "password": "string (requerido)"
}
```

**Response 200:**
```json
{
  "accessToken": "string (JWT, expira 15min)",
  "refreshToken": "string (UUID, expira 7d)",
  "user": {
    "id": "uuid",
    "email": "string",
    "firstName": "string",
    "lastName": "string",
    "emailVerified": "boolean",
    "avatarUrl": "string | null",
    "username": "string | null",
    "documentNumber": "string | null",
    "trialEndsAt": "ISO8601 | null",
    "createdAt": "ISO8601"
  }
}
```

---

### POST /auth/refresh

**Request body:**
```json
{
  "refreshToken": "string (requerido)"
}
```

**Response 200:** Mismo shape que login (accessToken + refreshToken + user).

---

### POST /auth/forgot-password

**Request body:**
```json
{
  "email": "string (requerido)"
}
```

**Response 200:** `{ "message": "string" }` — siempre 200 para no revelar si el email existe.

---

### POST /auth/reset-password

**Request body:**
```json
{
  "token": "string (UUID, requerido)",
  "newPassword": "string (requerido, ver reglas)"
}
```

**Response 200:** `{ "message": "Contraseña actualizada exitosamente." }`

---

### POST /auth/email-verification/confirm

**Request body:**
```json
{
  "email": "string (requerido)",
  "otp": "string (6 dígitos, requerido)"
}
```

**Response 200:** Mismo shape que login (accessToken + refreshToken + user).

---

### POST /auth/biometric/register

**Request body:**
```json
{
  "publicKey": "string (PEM o base64, requerido)",
  "deviceId": "string (requerido)"
}
```

**Response 201:** `{ "biometricId": "uuid" }`

---

### POST /auth/biometric/validate

**Request body:**
```json
{
  "biometricId": "uuid (requerido)",
  "signature": "string (base64, requerido)",
  "challenge": "string (nonce provisto por servidor)"
}
```

**Response 200:** Mismo shape que login (accessToken + refreshToken + user).

---

### GET /auth/onboarding

**Response 200:**
```json
{
  "currentStep": "email_verification | biometric_setup | profile_basic | welcome | document_upload | document_processing | null",
  "completed": "boolean",
  "checkpoints": {
    "biometricPrompted": "boolean",
    "importAttempted": "boolean",
    "financialProfileCompleted": "boolean",
    "minDocThresholdMet": "boolean"
  },
  "resumeSurface": "home | onboarding | null"
}
```

---

### PATCH /auth/onboarding/step

**Request body:**
```json
{
  "currentStep": "string (uno de los valores válidos del enum de steps)"
}
```

**Response 200:** Shape idéntico a GET /auth/onboarding.

---

## 5. Reglas de negocio

### Contraseña en registro
- Mínimo 8 caracteres
- Al menos 1 letra mayúscula
- Al menos 1 dígito

### Contraseña en cambio (PATCH /users/me/password)
- Mínimo 8 caracteres
- Al menos 1 letra mayúscula
- Al menos 1 letra minúscula
- Al menos 1 dígito
- Al menos 1 caracter especial

### OTP
- 6 dígitos numéricos
- Expira en 15 minutos
- Máximo 3 intentos fallidos antes de invalidar el OTP
- Reenvío disponible tras 60 segundos del último envío

### RUT chileno
- Formato válido: `12345678-5` (guión antes del dígito verificador)
- Validación módulo-11
- Campo opcional en registro

### Throttling
- Aplicado mediante `@nestjs/throttler` en todos los endpoints públicos
- Límites configurables vía env vars (`THROTTLE_TTL`, `THROTTLE_LIMIT`)
- Los endpoints de auth tienen límites más estrictos

---

## 6. Seguridad

| Mecanismo | Detalle |
|-----------|---------|
| Access Token | JWT firmado con `JWT_SECRET`, expira en 15 minutos |
| Refresh Token | UUID aleatorio, almacenado hasheado en tabla `refresh_tokens`, expira en 7 días |
| Rotación | Cada `POST /auth/refresh` invalida el refresh token anterior e emite uno nuevo |
| Replay attack | Un refresh token solo puede usarse una vez; reutilización lo invalida y revoca todos los del usuario |
| Blacklist access | No se implementa blacklist de access tokens; la corta duración (15min) es la mitigación |
| Reset token | UUID de un solo uso, expira en 1 hora, eliminado tras uso exitoso |
| Password storage | bcrypt con cost factor configurable (default 10) |
| OTP storage | Hasheado en base de datos, nunca expuesto en logs |
| Headers | `Authorization: Bearer <token>` en todos los endpoints protegidos |

---

## 7. Estados del usuario

| Estado | Descripción | Puede iniciar sesión |
|--------|-------------|----------------------|
| `pending_verification` | Registrado, email no verificado | No |
| `active` | Email verificado, cuenta operativa | Sí |
| `suspended` | Suspendido por admin | No |

---

## 8. Errores esperados

| Código | Caso |
|--------|------|
| 400 | Body inválido, campos requeridos faltantes, formato incorrecto |
| 400 | OTP expirado o ya utilizado |
| 400 | Token de reset expirado o ya utilizado |
| 401 | Credenciales incorrectas (email/password) |
| 401 | Access token inválido o expirado |
| 401 | Refresh token inválido, expirado o ya utilizado |
| 403 | Usuario en estado `pending_verification` intenta hacer login |
| 403 | Usuario en estado `suspended` intenta hacer login |
| 409 | Email ya registrado (POST /auth/register) |
| 429 | Rate limit superado |

> Todos los errores siguen el shape del `AllExceptionsFilter`:
> ```json
> { "statusCode": number, "message": string | string[], "error": string }
> ```
