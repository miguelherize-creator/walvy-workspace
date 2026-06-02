# Etapa 1 Funcional - Campos y Endpoints (Frontend + Backend)

Este documento explica las funciones de autenticacion de Etapa 1, los campos relevantes y como se conectan con backend.

## Alcance de Etapa 1

Funcionalidades:

1. Login con email y contrasena
2. Autenticacion biometrica (opcional)
3. Creacion de cuenta
4. Cambio de contrasena (usuario autenticado)
5. Recuperacion de contrasena via email

---

## 1) Login

**Objetivo:** iniciar sesion con correo y contrasena.

**Pantalla frontend:** `app/login.tsx`

**Campos UI:**

- `email` (obligatorio)
- `password` (obligatorio)

**Servicio frontend:** `api/authService.ts -> loginUser(payload)`

**Endpoint backend esperado:**

- `POST /auth/login`
- Body:
  - `email: string`
  - `password: string`

**Respuesta usada por frontend (contrato actual):**

- `token` (string) para guardar en SecureStore
- `user` (objeto basico)

> Nota tecnica: backend Nest suele responder `accessToken/refreshToken/expiresIn`. Si se mantiene ese contrato en backend, hay que mapear respuesta en frontend para poblar `token`.

---

## 2) Autenticacion Biometria

**Objetivo:** reingreso rapido sin volver a escribir contrasena.

**Pantallas frontend:** `login.tsx`, `dashboard.tsx`

**Servicios:**

- `services/biometrics.ts`
- `store/AuthProvider.tsx`

**Campos/estados clave en `AuthProvider`:**

- `biometricAvailable: boolean`
- `biometricEnabled: boolean`
- `biometricType: "Face ID" | "Huella" | null`
- `hasStoredToken: boolean`

**Acciones clave:**

- `enableBiometric()`
- `disableBiometric()`
- `loginWithBiometric()`

**Persistencia:**

- token: `walvy_auth_token` (SecureStore)
- preferencia biometria: `walvy_biometric_enabled` (SecureStore)

**Backend requerido:** ninguno adicional; usa la sesion/token existente.

---

## 3) Creacion de cuenta

**Objetivo:** alta de usuario nuevo.

**Pantalla frontend:** `app/register.tsx`

**Campos UI actuales:**

- `email`
- `password`
- `confirmPassword` (solo validacion local)

**Endpoint backend:**

- `POST /auth/register`

**Dto backend actual (`RegisterDto`) requiere:**

- `name` (obligatorio)
- `email`
- `password` (fuerte: 8+, mayuscula, minuscula, numero)
- `acceptTerms?`

> Gap actual: el frontend no envia `name` ni `acceptTerms`. Para integracion real completa, agregar esos campos en UI/servicio o ajustar backend.

---

## 4) Cambio de contrasena

**Objetivo:** actualizar contrasena desde perfil con validacion de clave actual.

**Pantalla frontend:** `app/change-password.tsx`

**Campos UI:**

- `currentPassword`
- `newPassword`
- `confirmPassword` (validacion local)

**Validaciones frontend:**

- nueva contrasena fuerte (8+, mayuscula, minuscula, numero)
- confirmacion igual
- nueva distinta de actual

**Servicio frontend:** `changePassword(payload)`

**Endpoint backend:**

- `PATCH /users/me/password`
- Requiere token Bearer
- Body:
  - `currentPassword`
  - `newPassword`

**Criterio esperado:**

- exito: proxima sesion respeta nueva clave
- error: mensaje claro (clave actual incorrecta, formato invalido, etc.)

---

## 5) Recuperacion de contrasena via email

**Objetivo:** recuperar cuenta por correo y retomar flujo.

**Pantalla frontend:** `app/forgot-password.tsx` (2 pasos)

### Paso A - Solicitar recuperacion

- Campo: `email`
- Servicio: `forgotPassword({ email })`
- Endpoint:
  - `POST /auth/forgot-password`
- Respuesta generica:
  - `message` (no revelar si el correo existe o no)

### Paso B - Restablecer contrasena

- Campos:
  - `token`
  - `newPassword`
  - `confirmPassword`
- Servicio: `resetPassword({ token, newPassword })`
- Endpoint:
  - `POST /auth/reset-password`

**Guardrail V1:**

- Solo email (sin SMS, sin proveedores externos costosos).

---

## 6) Modo Mock para pruebas frontend

Sin backend levantado, `isMockMode` permite probar todo el flujo:

- login/register con usuarios en memoria
- change password mock
- forgot/reset password mock
- en forgot-password se expone `devToken` para completar el flujo en UI

Esto valida UX y navegacion antes de conectar backend real.
