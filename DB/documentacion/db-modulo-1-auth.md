# DB — Módulo 1: Auth y Onboarding

## Tablas propias (escribe principalmente)

| Tabla | Rol |
|-------|-----|
| `users` | Alta de cuenta, login, cambio de contraseña |
| `email_verification_tokens` | Verificación de correo post-registro (código 6 dígitos, TTL 15 min) |
| `refresh_tokens` | Emisión y rotación del token de refresh |
| `password_reset_tokens` | Generación del enlace de recuperación de contraseña |
| `biometric_preferences` | Activar/desactivar autenticación biométrica |
| `onboarding_state` | Inicializar y avanzar el progreso del onboarding |

---

## Detalle por tabla

### `users`
Tabla central. Se crea al registrar la cuenta.

**`email`** es el identificador primario: NOT NULL UNIQUE, siempre presente desde el registro. El login acepta también `rut` y `username` como identificadores alternativos. La detección es automática por formato:
- Contiene `@` → busca por email
- Patrón `/^\d{7,8}-[\dkK]$/` → busca por rut
- Cualquier otro → busca por username

| Campo | Descripción |
|-------|-------------|
| `first_name` | Nombre del usuario. NOT NULL. |
| `last_name` | Apellido del usuario. NOT NULL. |
| `email` | Correo electrónico. NOT NULL UNIQUE. Identificador primario de login. |
| `rut` | RUT chileno normalizado sin puntos con guión (`12345678-9`). Nullable UNIQUE. Identificador alternativo de login. |
| `username` | Handle/alias opcional del usuario. Nullable UNIQUE. Identificador alternativo de login. null hasta que el usuario lo configure. |
| `password_hash` | bcrypt (12 rounds). Regla: ≥8 chars, upper+lower+number+special. |
| `accepted_terms_at` | Timestamp al aceptar los términos. |
| `accepted_privacy_at` | Timestamp al aceptar la política de privacidad. |
| `email_verified_at` | `null` = correo no verificado. Se establece en UC-02. |

**Operaciones:**
- `INSERT` al crear cuenta
- `UPDATE email_verified_at` al confirmar código de verificación
- `UPDATE password_hash` al cambiar o restablecer contraseña
- `UPDATE username` cuando el usuario configura su handle desde el perfil

---

### `email_verification_tokens`
Flujo post-registro para verificar el correo del usuario. Siempre se envía al email ingresado en el registro.

| Campo | Descripción |
|-------|-------------|
| `email` | Correo a verificar (igual al `users.email` ingresado al registrarse) |
| `token_hash` | SHA-256 del código de 6 dígitos enviado al correo |
| `expires_at` | TTL: 15 minutos desde `created_at` |
| `used_at` | `null` = vigente. Se estampa al confirmar o al invalidar por reenvío. |

**Flujo:**
`register` → `INSERT email_verification_tokens` → envío de código → usuario confirma → `UPDATE users.email_verified_at`.

---

### `refresh_tokens`
Soporta sesiones persistentes con rotación en cada uso.

| Campo | Descripción |
|-------|-------------|
| `token_hash` | SHA-256 del token opaco enviado al cliente |
| `expires_at` | Ventana de validez (default: 7 días) |
| `revoked_at` | Se estampa al hacer logout o al rotar el token |

**Flujo:** login exitoso → `INSERT` refresh_token → cliente almacena el token opaco en SecureStore.

---

### `password_reset_tokens`
Flujo "Olvidé mi contraseña". Solo disponible por email ya que email es siempre NOT NULL.

| Campo | Descripción |
|-------|-------------|
| `token_hash` | SHA-256 del token opaco enviado por email |
| `expires_at` | TTL: 1 hora |
| `used_at` | Se estampa al usarlo (token de un solo uso) |

**Flujo:** `forgot-password` → `INSERT` token → email con link → usuario hace click → `reset-password` → `UPDATE users.password_hash` + `UPDATE used_at` + revocar todos los refresh_tokens del usuario.

---

### `biometric_preferences`
Preferencia de autenticación biométrica por usuario y dispositivo.

| Campo | Descripción |
|-------|-------------|
| `enabled` | Toggle principal: `true` = biometría activa |
| `method` | `'face_id'` \| `'fingerprint'` \| `'device_pin'` |
| `device_id` | Identificador del dispositivo (soporte multi-device futuro) |

**Reglas:**
- Se crea con `enabled=false` durante el registro.
- El usuario activa desde el primer login o desde ajustes de perfil.
- Siempre existe fallback a contraseña — nunca se deshabilita el login base.
- Relación 1:1 con `users` — `user_id` es la PK. Un registro por usuario.
- `device_id` es informativo; soporte multi-device es roadmap post-MVP.

---

### `onboarding_state`
Seguimiento del progreso del onboarding — relación 1:1 con `users`.

| Campo | Valor inicial | Se actualiza cuando |
|-------|--------------|---------------------|
| `current_step` | `'email_verification'` | Avanza con cada paso |
| `financial_profile_completed` | `false` | Usuario guarda perfil financiero (M2) |
| `goals_set` | `false` | Usuario define al menos 1 meta (M2) |
| `import_attempted` | `false` | Usuario intenta importar cartola (M4) |
| `biometric_prompted` | `false` | Se le ofreció biometría (aceptó o rechazó) |
| `completed_at` | `null` | Al terminar todos los pasos |

**Pasos de `current_step`:**
```
'email_verification'  → Código enviado al email de registro; esperando confirmación
'profile'             → Email verificado; completa perfil financiero (M2)
'goals'               → Perfil listo; define metas (M2)
'completed'           → Onboarding terminado
```

---

## Flujos de datos principales

```
REGISTRO (único flujo — formulario completo)
  → INSERT users { first_name, last_name, email, rut, password_hash, accepted_terms_at, accepted_privacy_at }
  → INSERT onboarding_state { current_step='email_verification' }
  → INSERT biometric_preferences { enabled=false }
  → INSERT email_verification_tokens { código 6 dígitos, TTL 15min }
  → sendVerificationEmail(email, código)
  → INSERT refresh_tokens
  → RETURN { user, access_token, refresh_token, next_step: 'email_verification' }

VERIFICACIÓN DE CORREO
  → INSERT email_verification_tokens (resend)
  → UPDATE users { email_verified_at=NOW() } (confirm)
  → UPDATE onboarding_state { current_step='profile' } (confirm)

LOGIN (identificador flexible)
  → Detecta tipo: @ → email | RUT regex → rut | otro → username
  → SELECT users WHERE <columna> = $identificador
  → bcrypt.compare(password, password_hash)
  → INSERT refresh_tokens
  → RETURN { user, access_token, refresh_token }

RECUPERAR CONTRASEÑA
  → INSERT password_reset_tokens
  → sendPasswordResetEmail(email, token)
  → UPDATE users.password_hash (reset-password)
  → UPDATE password_reset_tokens.used_at
  → UPDATE refresh_tokens SET revoked_at (todos los del usuario)
```

---

## Índices críticos

| Tabla | Columna | Tipo | Motivo |
|-------|---------|------|--------|
| `users` | `email` | UNIQUE NOT NULL | Login principal — búsqueda primaria |
| `users` | `rut` | UNIQUE nullable | Login alternativo por RUT |
| `users` | `username` | UNIQUE nullable | Login alternativo por handle |
| `refresh_tokens` | `token_hash` | UNIQUE | Validar token en cada request |
| `refresh_tokens` | `expires_at` | INDEX | Limpieza de tokens expirados |
| `email_verification_tokens` | `token_hash` | UNIQUE | Validar código de verificación |
| `email_verification_tokens` | `user_id` | INDEX | Invalidar tokens previos |
| `password_reset_tokens` | `token_hash` | UNIQUE | Validar enlace de recuperación |

---

## Tablas excluidas del MVP

| Tabla | Por qué no está en V1 |
|-------|----------------------|
| `user_identities` | No hay login social (Google, Apple, Facebook) |
| `user_profiles` | Perfil extendido es roadmap; MVP usa columnas en `users` |
