# Casos de Uso — Módulo 1: Enrolamiento y Onboarding

**Tablas involucradas:** `users`, `refresh_tokens`, `password_reset_tokens`, `email_verification_tokens`, `biometric_preferences`, `onboarding_state`

---

## Actores

| Actor | Descripción |
|-------|-------------|
| **Usuario nuevo** | No tiene cuenta en Walvy |
| **Usuario registrado** | Tiene cuenta y sesión activa o expirada |
| **Sistema (job)** | Limpieza automática de tokens vencidos |

---

## Schema requerido — tabla `users`

La tabla `users` usa `email` como identificador primario (NOT NULL UNIQUE). El login también acepta `rut` y `username` como identificadores secundarios.

```dbml
Table users {
  id                  uuid [pk]
  first_name          text [not null]
  last_name           text [not null]
  email               text [not null, unique, note: 'Identificador primario. Verificado post-registro.']
  rut                 text [null, unique, note: 'RUT normalizado sin puntos con guión (12345678-9). Opcional.']
  username            text [null, unique, note: 'Handle/alias opcional. null hasta que el usuario lo configure.']
  password_hash       text [not null]
  accepted_terms_at   timestamptz
  accepted_privacy_at timestamptz
  email_verified_at   timestamptz [note: 'null = correo no verificado']
  created_at          timestamptz [not null]
  updated_at          timestamptz [not null]
}
```

## Schema requerido — tabla `email_verification_tokens`

Almacena los tokens de verificación de correo para el flujo post-registro.

```dbml
Table email_verification_tokens {
  id         uuid        [pk]
  user_id    uuid        [not null, ref: > users.id]
  email      text        [not null, note: 'El correo que se está verificando']
  token_hash text        [not null, unique, note: 'SHA-256 del código de 6 dígitos']
  expires_at timestamptz [not null, note: 'Expira en 15 minutos']
  used_at    timestamptz [note: 'null = pendiente de uso']
  created_at timestamptz [not null]
}
```

---

## UC-01: Registro con formulario unificado

**Actor:** Usuario nuevo  
**Precondición:** La app está abierta en la pantalla de bienvenida

El registro usa un único formulario. El email siempre es requerido y se envía código de verificación inmediatamente.

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL
    participant Mail as Mail Service

    U->>FE: Completa el formulario de registro
    FE->>BE: POST /auth/register { firstName, lastName, rut, email, password, confirmPassword, acceptTerms: true, acceptPrivacy: true }

    BE->>BE: Valida: confirmPassword == password
    BE->>BE: Valida: acceptTerms && acceptPrivacy == true

    BE->>DB: SELECT id FROM users WHERE email = $email
    DB-->>BE: (vacío)
    opt rut presente
        BE->>DB: SELECT id FROM users WHERE rut = $rut
        DB-->>BE: (vacío)
    end

    BE->>BE: bcrypt.hash(password)
    BE->>DB: INSERT INTO users (first_name, last_name, email, rut, password_hash, accepted_terms_at, accepted_privacy_at)
    DB-->>BE: user { id }
    BE->>DB: INSERT INTO onboarding_state (user_id, current_step = 'email_verification')
    BE->>DB: INSERT INTO biometric_preferences (user_id, enabled = false)

    BE->>BE: genera código de 6 dígitos aleatorio
    BE->>DB: INSERT INTO email_verification_tokens (user_id, email, token_hash = SHA256(código), expires_at = NOW() + 15min)
    BE->>Mail: sendVerificationEmail(email, código)

    BE->>BE: genera access_token + refresh_token
    BE->>DB: INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
    BE-->>FE: 201 { access_token, refresh_token, user: { id, firstName, lastName, email, rut }, next_step: 'email_verification' }

    FE->>U: Redirige a pantalla "Revisa tu correo"
```

---

## UC-02: Verificar correo electrónico

**Actor:** Usuario nuevo (post-registro)  
**Precondición:** Código enviado al correo, pantalla "Revisa tu correo" activa

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    FE->>U: Pantalla "Revisa tu correo"\nCampo para ingresar código de 6 dígitos

    U->>FE: Ingresa el código recibido
    FE->>BE: POST /auth/email-verification/confirm { code }

    BE->>BE: SHA256(code)
    BE->>DB: SELECT * FROM email_verification_tokens\nWHERE user_id = $1\nAND token_hash = $hash\nAND used_at IS NULL\nAND expires_at > NOW()

    alt Código inválido o expirado
        DB-->>BE: (vacío)
        BE-->>FE: 400 "Código inválido o expirado"
        FE->>U: Muestra error + opción "Reenviar código"
    else Código válido
        DB-->>BE: token { id, email }
        BE->>DB: UPDATE users SET email_verified_at = NOW() WHERE id = $user_id
        BE->>DB: UPDATE email_verification_tokens SET used_at = NOW() WHERE id = $token_id
        BE->>DB: UPDATE onboarding_state SET current_step = 'profile' WHERE user_id = $1
        BE-->>FE: 200 { email_verified: true }
        FE->>U: Redirige al paso siguiente del onboarding
    end

    Note over U,FE: Opción "Reenviar código"
    U->>FE: Tap "Reenviar código"
    FE->>BE: POST /auth/email-verification/resend
    BE->>DB: UPDATE email_verification_tokens SET used_at = NOW()\nWHERE user_id = $1 AND used_at IS NULL
    BE->>BE: genera nuevo código de 6 dígitos
    BE->>DB: INSERT INTO email_verification_tokens (user_id, email, token_hash, expires_at = NOW()+15min)
    BE->>Mail: sendVerificationEmail(email, nuevo_código)
    BE-->>FE: 200 { resent: true }
    FE->>U: "Código reenviado"
```

---

## UC-03: Login con identificador flexible

**Actor:** Usuario registrado  
**Precondición:** Cuenta activa con contraseña establecida

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Ingresa su identificador + contraseña
    FE->>BE: POST /auth/login { identifier: "lo que ingresó", password }

    BE->>BE: Detecta tipo de identificador:\n- contiene @ → busca por email\n- patrón RUT (12345678-9) → busca por rut\n- otro → busca por username

    BE->>DB: SELECT id, password_hash, email_verified_at\nFROM users WHERE <columna_detectada> = $identificador

    alt Usuario no encontrado
        BE-->>FE: 401 "Credenciales inválidas"
    else Usuario encontrado
        BE->>BE: bcrypt.compare(password, hash)
        alt Contraseña incorrecta
            BE-->>FE: 401 "Credenciales inválidas"
        else Contraseña correcta
            BE->>BE: genera access_token + refresh_token
            BE->>DB: INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
            BE-->>FE: 200 { access_token, refresh_token, user, email_verified: email_verified_at IS NOT NULL }
            FE->>BE: GET /onboarding/state
            BE->>DB: SELECT * FROM onboarding_state WHERE user_id = $1
            alt current_step != 'completed'
                FE->>U: Redirige al paso de onboarding pendiente
            else Onboarding completo
                FE->>U: Redirige a /(tabs)/home
            end
        end
    end
```

### Regla de detección del identificador

| Lo que escribe el usuario | Criterio de detección | Se busca en |
|--------------------------|----------------------|-------------|
| `tu@correo.cl` | Contiene `@` | `users.email` (case-insensitive) |
| `12345678-9` | Patrón `/^\d{7,8}-[\dkK]$/` | `users.rut` |
| `userwalvy` | Ninguno de los anteriores | `users.username` (case-insensitive) |

---

## UC-04: Refresh de token (sesión persistente)

**Actor:** Sistema (interceptor del cliente)  
**Precondición:** Access token expirado, refresh token vigente

```mermaid
sequenceDiagram
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL

    FE->>BE: Cualquier request con access_token expirado
    BE-->>FE: 401 Unauthorized
    FE->>FE: Interceptor detecta 401
    FE->>BE: POST /auth/refresh { refresh_token }
    BE->>BE: SHA256(refresh_token)
    BE->>DB: SELECT * FROM refresh_tokens\nWHERE token_hash = $1 AND revoked_at IS NULL
    alt Token expirado o revocado
        BE-->>FE: 401 "Sesión expirada"
        FE->>FE: logout() → borra SecureStore → redirige a /login
    else Token válido
        BE->>DB: UPDATE refresh_tokens SET revoked_at = NOW() WHERE id = $1
        BE->>BE: genera nuevo access_token + nuevo refresh_token
        BE->>DB: INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
        BE-->>FE: 200 { access_token, refresh_token }
        FE->>FE: Reintenta el request original con nuevos tokens
    end
```

---

## UC-05: Recuperar contraseña

**Actor:** Usuario registrado  
**Precondición:** El usuario olvidó su contraseña

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant BE as Backend
    participant DB as PostgreSQL
    participant Mail as Mail Service

    U->>FE: Ingresa su email en "Olvidé mi contraseña"
    FE->>BE: POST /auth/forgot-password { email }
    BE->>DB: SELECT id, email FROM users WHERE email = $email

    alt Usuario no encontrado
        Note over BE: Respuesta idéntica — no revelar si existe
        BE-->>FE: 200 "Si el correo existe, recibirás un link"
    else Usuario encontrado
        BE->>BE: genera token = crypto.randomBytes(32)
        BE->>DB: INSERT INTO password_reset_tokens (user_id, token_hash = SHA256(token), expires_at = NOW()+1h)
        BE->>Mail: sendPasswordResetEmail(user.email, token)
        BE-->>FE: 200 "Si el correo existe, recibirás un link"
    end

    FE->>U: Pantalla de confirmación genérica

    U->>FE: Abre link del correo → ingresa nueva contraseña
    FE->>BE: POST /auth/reset-password { token, newPassword }
    BE->>DB: SELECT * FROM password_reset_tokens\nWHERE token_hash = SHA256(token)\nAND used_at IS NULL\nAND expires_at > NOW()
    alt Token inválido o expirado
        BE-->>FE: 400 "Token inválido o expirado"
    else Token válido
        BE->>DB: UPDATE users SET password_hash = $nuevo WHERE id = $1
        BE->>DB: UPDATE password_reset_tokens SET used_at = NOW() WHERE id = $1
        BE->>DB: UPDATE refresh_tokens SET revoked_at = NOW()\nWHERE user_id = $1 AND revoked_at IS NULL
        BE-->>FE: 200 "Contraseña actualizada"
        FE->>U: Redirige a /login
    end
```

---

## UC-06: Activar autenticación biométrica

**Actor:** Usuario registrado  
**Precondición:** Dispositivo soporta Face ID o huella

```mermaid
sequenceDiagram
    actor U as Usuario
    participant FE as Frontend
    participant OS as Device Biometrics API
    participant BE as Backend
    participant DB as PostgreSQL

    U->>FE: Activa "Usar biometría"
    FE->>OS: LocalAuthentication.authenticateAsync()
    OS-->>FE: success = true
    FE->>BE: POST /auth/biometric { enabled: true, method: "face_id", device_id }
    BE->>DB: INSERT INTO biometric_preferences (user_id, enabled, method, device_id)\nON CONFLICT (user_id) DO UPDATE SET enabled = true, method = $3
    BE->>DB: UPDATE onboarding_state SET biometric_prompted = true WHERE user_id = $1
    BE-->>FE: 200 { enabled: true }
```

---

## UC-07: Completar onboarding paso a paso

**Actor:** Usuario nuevo (post-registro y verificación de correo)

```mermaid
flowchart TD
    START([Registro completado]) --> EMAIL_VER{¿email_verified_at\nno es null?}
    EMAIL_VER --> |No verificado| VER_STEP[Pantalla: Revisa tu correo\nUC-02]
    EMAIL_VER --> |Verificado| STEP1
    VER_STEP --> |Código correcto| STEP1

    STEP1[Onboarding: Perfil financiero\nM2 → user_financial_profile] --> MARK1
    MARK1[UPDATE onboarding_state\nfinancial_profile_completed = true] --> STEP2

    STEP2[Onboarding: Metas globales\nM2 → user_goals] --> MARK2
    MARK2[UPDATE onboarding_state\ngoals_set = true] --> STEP3

    STEP3{¿Importar cartola?} --> |Intenta| IMPORT[M4: statement_imports]
    STEP3 --> |Salta| BIO
    IMPORT --> MARK3[UPDATE onboarding_state\nimport_attempted = true]
    MARK3 --> BIO

    BIO[Ofrecer biometría] --> |Activa| BIO_ON[INSERT biometric_preferences\nbiometric_prompted = true]
    BIO --> |Omite| BIO_SKIP[biometric_prompted = true]
    BIO_ON --> DONE
    BIO_SKIP --> DONE

    DONE[UPDATE onboarding_state\ncurrent_step = 'completed'\ncompleted_at = NOW()] --> HOME([Redirige a home])
```

### Estados de `onboarding_state`

| Campo | Valor inicial | Se actualiza cuando |
|-------|--------------|---------------------|
| `current_step` | `'email_verification'` | Avanza con cada paso |
| `financial_profile_completed` | `false` | Usuario guarda perfil financiero (M2) |
| `goals_set` | `false` | Usuario define al menos 1 meta (M2) |
| `import_attempted` | `false` | Usuario intenta importar cartola (M4) |
| `biometric_prompted` | `false` | Se le ofreció biometría (aceptó o rechazó) |
| `completed_at` | `null` | Al terminar todos los pasos |

---

## Diagrama de relación entre tablas — M1

```mermaid
erDiagram
    users {
        uuid id PK
        text first_name
        text last_name
        text email UK "NOT NULL — login principal"
        text rut UK "null — login alternativo"
        text username UK "null — handle/alias, login alternativo"
        text password_hash
        timestamp accepted_terms_at
        timestamp accepted_privacy_at
        timestamp email_verified_at
    }
    email_verification_tokens {
        uuid id PK
        uuid user_id FK
        text email "correo a verificar"
        text token_hash UK
        timestamp expires_at
        timestamp used_at
    }
    refresh_tokens {
        uuid id PK
        uuid user_id FK
        text token_hash UK
        timestamp expires_at
        timestamp revoked_at
    }
    password_reset_tokens {
        uuid id PK
        uuid user_id FK
        text token_hash UK
        timestamp expires_at
        timestamp used_at
    }
    biometric_preferences {
        uuid user_id PK,FK "1:1 con users"
        boolean enabled
        text method "face_id | fingerprint | device_pin"
        text device_id "informativo — multi-device es roadmap"
    }
    onboarding_state {
        uuid user_id PK,FK "1:1 con users"
        text current_step
        boolean financial_profile_completed
        boolean goals_set
        boolean import_attempted
        boolean biometric_prompted
        timestamp completed_at
    }

    users ||--o{ email_verification_tokens : "verifica correo"
    users ||--o{ refresh_tokens : "tiene sesiones"
    users ||--o{ password_reset_tokens : "solicita reset"
    users ||--|| biometric_preferences : "configura biometría"
    users ||--|| onboarding_state : "tiene estado"
```
