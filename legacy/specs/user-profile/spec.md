# Spec: Módulo de Perfil de Usuario

> **Módulo:** `users`
> **Backend:** NestJS 10 — `src/users/`
> **Última revisión:** 2026-05-14

---

## 1. Descripción funcional

El módulo de perfil gestiona la información personal y de cuenta del usuario autenticado. Expone endpoints para leer y actualizar datos de perfil, cambiar contraseña y consultar información de onboarding básica.

**Para el PM:** Los usuarios pueden ver y editar su nombre, apellido, nombre de usuario y avatar. El email es inmutable post-registro. El cambio de contraseña revoca todas las sesiones activas por seguridad.

**Para el desarrollador:** El módulo usa el guard JWT estándar. Todos los endpoints retornan el resultado de `user.toPublic()`, que excluye `passwordHash` y campos internos. La diferencia entre `/users/me` y `/users/profile` es intencional: `/profile` es un endpoint orientado al flujo de onboarding.

---

## 2. GET /users/me

Retorna los datos del usuario autenticado.

**Auth:** Bearer JWT requerido

**Response 200:**
```json
{
  "id": "uuid",
  "email": "string",
  "firstName": "string",
  "lastName": "string",
  "username": "string | null",
  "avatarUrl": "string | null",
  "documentNumber": "string | null",
  "emailVerified": "boolean",
  "trialEndsAt": "ISO8601 | null",
  "createdAt": "ISO8601"
}
```

**Campos nunca expuestos:** `passwordHash`, `refreshTokens`, `role` (interno), cualquier campo de auditoría interno.

---

## 3. PATCH /users/me

Actualiza datos editables del perfil del usuario autenticado.

**Auth:** Bearer JWT requerido

**Request body (todos opcionales):**
```json
{
  "firstName": "string (mín 1, máx 100 caracteres)",
  "lastName": "string (mín 1, máx 100 caracteres)",
  "username": "string (mín 3, máx 50, alfanumérico + guión bajo)",
  "avatarUrl": "string (URL válida)"
}
```

**Response 200:** Mismo shape que GET /users/me con los datos actualizados.

**Reglas:**
- Solo se actualizan los campos presentes en el body (PATCH parcial)
- `email` no es modificable mediante este endpoint (es inmutable post-registro)
- `username` debe ser único en el sistema; retorna 409 si ya existe
- `documentNumber` no es modificable post-registro

---

## 4. PATCH /users/profile

Actualiza datos básicos de perfil. Orientado al paso `profile_basic` del onboarding.

**Auth:** Bearer JWT requerido

**Request body (todos opcionales):**
```json
{
  "firstName": "string",
  "lastName": "string",
  "username": "string"
}
```

**Response 200:** Mismo shape que GET /users/me con los datos actualizados.

**Diferencia con PATCH /users/me:**

| Aspecto | `/users/me` | `/users/profile` |
|---------|-------------|-----------------|
| Propósito | Edición general de perfil | Paso de onboarding `profile_basic` |
| Campos editables | firstName, lastName, username, avatarUrl | firstName, lastName, username |
| avatarUrl | Sí | No |
| Contexto de uso | Pantalla "Mi perfil" (post-onboarding) | Pantalla de onboarding `profile_basic` |

> Nota: Ambos endpoints comparten la lógica de validación. La separación es intencional para aislar el flujo de onboarding del flujo general de edición de perfil.

---

## 5. PATCH /users/me/password

Cambia la contraseña del usuario autenticado.

**Auth:** Bearer JWT requerido

**Request body:**
```json
{
  "currentPassword": "string (requerido)",
  "newPassword": "string (requerido, ver reglas)"
}
```

**Response 200:**
```json
{
  "message": "Contraseña actualizada exitosamente. Se han cerrado todas las sesiones activas."
}
```

**Reglas de `newPassword`:**
- Mínimo 8 caracteres
- Al menos 1 letra mayúscula
- Al menos 1 letra minúscula
- Al menos 1 dígito
- Al menos 1 caracter especial (ej: `!@#$%^&*`)

**Comportamiento post-cambio:**
1. Verifica que `currentPassword` sea correcto; si no, retorna 401
2. Hashea la nueva contraseña con bcrypt
3. **Revoca todos los refresh tokens del usuario** (todas las sesiones activas quedan inválidas)
4. El access token actual sigue siendo válido hasta que expire (máx 15 min)
5. El usuario deberá hacer login nuevamente

**Errores:**
- `400` — `newPassword` no cumple las reglas
- `401` — `currentPassword` incorrecto
- `401` — No autenticado

---

## 6. Reglas de negocio del módulo

### Email inmutable

El email del usuario no puede modificarse una vez registrado. No existe endpoint de cambio de email. Si en el futuro se requiere, deberá pasar por un flujo de verificación del nuevo email.

### `toPublic()` — Método de serialización

Todos los endpoints del módulo retornan el resultado de `user.toPublic()`. Este método garantiza que:

- `passwordHash` **nunca** se expone en respuestas HTTP
- Tokens internos no se exponen
- Solo los campos definidos explícitamente son retornados

Este patrón es parte de las convenciones del proyecto y **no debe saltarse** para conveniencia.

### Username único

El `username` es único en el sistema. Si se intenta actualizar a uno ya existente, el endpoint retorna `409 Conflict`.

### Transformación decimal

Los campos numéricos (como importes futuros en perfil financiero) usan el transformer `decimalToNumber` para retornar `number` en lugar de `string` desde la BD.

---

## 7. Errores esperados

| Código | Caso |
|--------|------|
| 400 | Campos con formato inválido |
| 400 | `newPassword` no cumple las reglas de complejidad |
| 401 | No autenticado / token expirado |
| 401 | `currentPassword` incorrecto en cambio de contraseña |
| 404 | Usuario no encontrado (raro, protegido por JWT guard) |
| 409 | `username` ya en uso por otro usuario |
