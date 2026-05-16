# ADR-002 — JWT Access Token + Opaque Refresh Token (Rotating)

| Campo | Valor |
|-------|-------|
| **Número** | ADR-002 |
| **Título** | JWT Access Token + Opaque Refresh Token Rotativo |
| **Estado** | Accepted |
| **Fecha** | 2026-05-14 |
| **Autores** | Equipo Walvy |
| **Revisores** | — |

---

## Contexto

Walvy es una aplicación móvil. A diferencia de las aplicaciones web donde la sesión puede gestionarse con cookies HttpOnly, en el contexto móvil los tokens deben almacenarse en el cliente (Keychain/Keystore via `expo-secure-store`).

Los requisitos específicos eran:

- **Sesiones largas**: los usuarios no deben tener que reautenticarse frecuentemente. Una sesión debe durar días o semanas.
- **Seguridad de tokens comprometidos**: si un token es interceptado, el daño debe ser acotado en el tiempo.
- **Revocación posible**: debe ser posible invalidar la sesión de un usuario (logout, suspensión de cuenta).
- **Detección de replay attacks**: si un refresh token es robado y reutilizado, el sistema debe detectarlo.
- **Stateless donde sea posible**: evitar lookups a DB en cada request autenticado (costo de latencia).
- **Compatibilidad con biometría**: el flujo debe permitir un "login biométrico" que no requiera enviar contraseña al servidor.

---

## Decisión

Se adopta el esquema **JWT de acceso de vida corta + Refresh Token opaco rotativo almacenado hasheado**.

### Access Token (JWT)

- **Tipo**: JWT firmado con HS256 (HMAC-SHA256)
- **Duración**: 15 minutos
- **Contenido del payload**: `{ sub: userId, email, iat, exp }`
- **Verificación**: solo verificación de firma (stateless — no lookup a DB)
- **Almacenamiento cliente**: `expo-secure-store` con clave `ACCESS_TOKEN_KEY`
- **Transporte**: header `Authorization: Bearer <token>`

### Refresh Token (opaco rotativo)

- **Tipo**: token opaco (string aleatorio criptográficamente seguro, no JWT)
- **Duración**: 7 días
- **Single-use**: cada uso emite un nuevo refresh token; el anterior se revoca inmediatamente
- **Almacenamiento en DB**: hash SHA-256 del token (nunca el valor en claro)
- **Almacenamiento cliente**: `expo-secure-store` con clave `REFRESH_TOKEN_KEY`
- **Rotación**: `POST /auth/refresh` → verifica hash → revoca token actual → emite nuevo par (accessToken + refreshToken)

### Flujo completo

```
Login exitoso:
  accessToken  = JWT firmado (exp: 15min)
  refreshToken = crypto.randomBytes(32).toString('hex')   ← en claro, solo al cliente
  hash(refreshToken) → guardado en tabla refresh_tokens    ← solo el hash en DB

Request autenticado:
  Cliente envía: Authorization: Bearer <accessToken>
  Backend: verifica firma JWT (sin DB) → extrae payload → continúa

Access token expirado:
  POST /auth/refresh { refreshToken: "<token_opaco>" }
  Backend:
    1. Calcula hash(refreshToken)
    2. Busca en DB → si no existe → 401
    3. Si existe pero ya está revocado → revokeAllRefreshForUser(userId) → 401
       (replay attack detection)
    4. Si válido → marca como revocado → emite nuevo par → 200

Logout:
  POST /auth/logout { refreshToken: "<token_opaco>" }
  Backend: revoca token en DB (idempotente — no falla si ya no existe)
```

### Detección de replay attacks

Si el backend recibe un refresh token que ya fue revocado (ya se usó), asume que el token original fue comprometido y un atacante lo está reutilizando. En este caso:

1. Se revoca **toda la sesión del usuario** (`revokeAllRefreshForUser(userId)`)
2. Se responde con 401
3. El usuario deberá hacer login nuevamente con email + contraseña

### Login biométrico

El login biométrico no es un segundo factor de autenticación contra el servidor; es una forma de desbloquear los tokens almacenados en `expo-secure-store`. El flujo es:

```
App startup / lock screen:
  1. expo-local-authentication.authenticateAsync()
  2. Si biometría exitosa → leer accessToken de SecureStore
  3. Si accessToken válido → navegar a app
  4. Si accessToken expirado → usar refreshToken para rotar silenciosamente
```

El servidor nunca sabe que se usó biometría. La biometría protege el acceso al dispositivo, no autentica contra la API.

---

## Reglas de implementación

### Hashing de tokens

```typescript
// Para tokens opacos (refresh tokens, OTPs usados como índice de lookup)
import { createHash } from 'crypto';

export function hashOpaqueToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
// SHA-256 es determinista → permite lookup por hash sin bcrypt
```

### Hashing de contraseñas

```typescript
// Para passwords — usar bcrypt (con salt, intencionalemente lento)
import * as bcrypt from 'bcrypt';

const SALT_ROUNDS = 10;
const hash = await bcrypt.hash(plainPassword, SALT_ROUNDS);
const valid = await bcrypt.compare(plainPassword, hash);
```

**Diferencia crítica**: los tokens opacos usan SHA-256 (determinista, rápido) porque necesitan ser índice de búsqueda. Las contraseñas usan bcrypt (con salt, lento) porque no se buscan por hash, solo se verifican.

### Prohibiciones

- **NO blacklist de access tokens**: los JWT no son revocables antes de expirar. La ventana de 15 minutos es el riesgo aceptado.
- **NO extender duración del access token** por conveniencia. Si 15min son insuficientes para la UX, la solución es mejorar el refresh silencioso, no alargar el JWT.
- **NO almacenar el refresh token en claro** en DB. Solo el hash SHA-256.
- **NO loguear tokens** en ningún nivel del sistema.

---

## Consecuencias

### Ventajas

- **Stateless para el 99% de los requests**: solo los `/auth/refresh` y `/auth/logout` tocan la DB de tokens.
- **Refresh tokens revocables**: el logout es efectivo inmediatamente.
- **Replay attack detection**: un token comprometido y reutilizado desencadena la revocación total de la sesión.
- **DB liviana**: la tabla `refresh_tokens` solo tiene N filas por usuario activo (una por dispositivo/sesión).

### Desventajas

- **Access token no revocable**: si un JWT es comprometido, el atacante tiene hasta 15 minutos de acceso. Mitigación: 15min es una ventana pequeña; para casos de alta criticidad (suspensión de cuenta por fraude) se puede implementar un endpoint de emergencia que invalide el JWT secret (pero esto afecta a todos los usuarios — no implementado en MVP).
- **Complejidad del refresh silencioso**: el interceptor de Axios debe manejar correctamente el caso de múltiples requests concurrentes con token expirado (solo uno debe hacer el refresh, el resto deben esperar — race condition que debe manejarse con un mutex/flag).

---

## Alternativas consideradas

### Opción 1: JWT de larga duración (7 días) sin refresh

- Token único de 7 días, sin mecanismo de refresh.
- **Rechazada**: si el token es comprometido, el atacante tiene 7 días de acceso sin posibilidad de revocación.

### Opción 2: Sesiones en DB (session tokens)

- Cada request verifica el token contra la DB.
- **Rechazada**: latencia extra en cada request autenticado; la DB se convierte en un cuello de botella. No escala bien.

### Opción 3: JWT con blacklist en Redis

- JWT de larga duración + Redis para revocar tokens antes de expirar.
- **Rechazada**: requiere infraestructura adicional (Redis); la complejidad operacional no se justifica en MVP. Se puede adoptar en el futuro si la ventana de 15min resulta insuficiente.

---

## Mejoras futuras

- **Token versioning**: agregar `tokenVersion` al payload del JWT. Al cambiar la versión (por ejemplo, al cambiar contraseña), los tokens anteriores se invalidan sin necesidad de blacklist.
- **Device fingerprinting**: registrar en `refresh_tokens` el `user-agent` y una huella del dispositivo para detectar usos desde dispositivos inusuales.
- **Multiple sessions**: actualmente un usuario puede tener múltiples refresh tokens activos (uno por dispositivo). En el futuro, agregar un panel de "sesiones activas" donde el usuario pueda revocar sesiones específicas.
- **Short-lived tokens para operaciones sensibles**: para acciones como cambiar contraseña o ver datos de pago, requerir reautenticación explícita con una sesión de corta duración (OTP o contraseña), independiente del JWT actual.
