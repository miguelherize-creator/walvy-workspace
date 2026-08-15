# Wiki: pantalla → endpoints (auth / users / profile)

**Frontend:** `walvy-org/walvy-app-frontend` · rama `main` (`walvy/main`) · SHA `a929a2c`  
**Alcance:** los **14 auth + 5 users + 4 profile** actualizados en backend.  
**Complementa:** [`frontend-routes-graph.md`](frontend-routes-graph.md) (navegación) y [`authentication.md`](authentication.md) (contrato auth).

Formato pedido: **Pantalla (endpoints)**. Si un cambio de backend rompe el path, el body o el shape de respuesta, las pantallas listadas son las afectadas.

---

## Pantalla (endpoints)

### `/` — Splash (`SplashScreen`)
No llama API. Espera a que `AuthProvider` termine el arranque y siempre navega a `/login`.

- Indirecto al arrancar la app: `GET /health` (probe mock/real) y `GET /users/me` (restaurar sesión).

### `/login` — Login (`LoginScreen` + `useLoginForm`)
- `POST /auth/login` — submit de correo/clave (también en modo usuario guardado).
- `GET /auth/onboarding` — post-login: decide a qué pantalla retomar (`currentStep` + `resumeSurface`).
- `POST /auth/email-verification/request` — si el onboarding viene en `email_verification`.
- Reingreso biométrico (mismo login): `GET /users/me` vía `AuthProvider.loginWithBiometric`.

**Afectación alta** si cambia el shape de `GET /auth/onboarding`: el mapa de retoma usa `currentStep` (`biometric_setup`, `profile_basic`, `welcome`, `document_upload`, `document_processing`). El backend nuevo responde `currentGate` / `resumeState`. Login no sabrá a dónde mandar al usuario.

### `/(auth)/register` — Registro (`RegisterScreen` + `useRegisterForm`)
- `POST /auth/register` — body: `email`, `documentNumber`, `password`, `acceptTerms`, `acceptPrivacy`.

Tras 201 navega a verify-code. No llama verificación acá: el backend envía el OTP en el register.

### `/(auth)/verify-code` — Código OTP (`VerifyCodeScreen` + `useVerifyCodeForm`)
Dos modos:

**Verificación de cuenta**
- `POST /auth/email-verification/confirm`
- `POST /auth/email-verification/resend` (botón reenviar)

**Reset de contraseña**
- `POST /auth/verify-reset-code` — valida sin consumir; si OK va a reset-password.
- `POST /auth/forgot-password` — reenviar OTP de reset.

### `/(auth)/forgot-password` — Olvidé mi contraseña
- `POST /auth/forgot-password`

### `/(auth)/reset-password` — Nueva contraseña
- `POST /auth/reset-password` — `email`, `code`, `newPassword`.

### `/(auth)/biometric-setup` — Prompt biométrico (`BiometricPromptScreen`)
- `PATCH /auth/biometric` — `enabled: true` + `method`, o `enabled: false` si rechaza.
- `PATCH /auth/onboarding/step` — body front: `{ currentStep: "profile_basic", resumeSurface: "onboarding" }`.

**Afectación alta:** el body de step ya no coincide con el DTO de puertas (`currentGate`). Si el PATCH 400, igual intenta ir a choose-alias, pero la retoma queda desincronizada.

### `/(auth)/choose-alias` — Nombre y alias (`ChooseAliasScreen` + `useChooseAliasForm`)
- `PATCH /users/me` — `firstName`, `lastName`, `username`.
- `PATCH /auth/onboarding/step` — `{ currentStep: "welcome", resumeSurface: "onboarding" }` (guardar y saltar).

No usa el alias deprecado `PATCH /users/profile`.

### `/(auth)/onboarding` — Slides de bienvenida (`OnboardingScreen`)
Ningún endpoint. Solo marca `onboarding_seen` en AsyncStorage y va a foco.

### `/(auth)/onboarding-foco` — Foco del mes (`OnboardingFocoScreen`)
- `POST /profile/goals` — `{ focusId }` al confirmar.
- `PATCH /auth/onboarding/step` — `{ currentStep: "document_upload", resumeSurface: "onboarding", goalsSet: true }`.
- Salir sin foco: `PATCH /auth/onboarding/step` con `resumeSurface: "home"`.

**Única pantalla que escribe goals.** `GET /profile/goals` no tiene consumidor.

### `/(auth)/onboarding-doc` — Carga de cartola (`OnboardingDocScreen`)
Auth/profile:
- `PATCH /auth/onboarding/step` al montar (`currentStep: "document_upload"`) y al salir a home.

Fuera de alcance (statement-imports): `POST /statement-imports/unlock-preview`, `POST /statement-imports/check-password`.

### `/(auth)/onboarding-analyzing` — Procesando (`OnboardingAnalyzingScreen`)
Auth:
- `PATCH /auth/onboarding/step` — `document_processing` + `importAttempted: true` al subir; vuelve a `document_upload` si falla/cancela; `resumeSurface: "home"` si sale.

### `/(auth)/onboarding-analysis` — Revisión (`OnboardingAnalysisScreen`)
Auth:
- `PATCH /auth/onboarding/step` — al salir: `{ currentStep: "document_upload", resumeSurface: "home" }`.

### `/(auth)/onboarding-first-ready` — Diagnóstico listo (`OnboardingFirstReadyScreen`)
Auth:
- `PATCH /auth/onboarding/step` — `{ currentStep: "document_processing", resumeSurface: "home" }` al ir a tabs.

### `/confirm-account` y `/verify` — Resultado de enlace (`AccountConfirmedScreen`)
Ningún endpoint. UI de deep link. El propio front documenta que hoy nadie las abre (verificación es OTP de 6 dígitos, no enlace).

### `/(tabs)` — Inicio (stub) + menú usuario (`useAppHeader`)
- `POST /auth/logout` — “Cerrar sesión” (logout completo si no hay biometría, o si se fuerza).

Con biometría activa el logout es suave y **no** llama al backend (deja token para reingreso).

### `/(tabs)/profile` — Mi perfil (stub “Próximamente”)
Ningún endpoint. No hay pantalla de avatar, cambio de clave ni perfil financiero.

### `/(tabs)/movimientos`, `/movimiento`, `/presupuesto`, `/chatbot`
Ningún endpoint de auth/users/profile.

---

## No es pantalla, pero sí llama API

| Quién | Cuándo | Endpoints |
|---|---|---|
| `AuthProvider` (arranca en `_layout`) | Restore de sesión | `GET /health`, `GET /users/me` |
| `AuthProvider.login` / `.register` | Login y registro | `POST /auth/login`, `POST /auth/register` |
| `AuthProvider.logout` | Cerrar sesión completo | `POST /auth/logout` |
| `api/client.ts` interceptor | 401 en request autenticado | `POST /auth/refresh` |
| `useNotificationSetup` (nativo) | Usuario autenticado | `PATCH /users/me/push-token` |

`POST /auth/refresh` no tiene pantalla: cualquier flujo autenticado (onboarding, tabs, restore) se rompe si cambia el contrato de refresh.

---

## Endpoint → pantallas (impacto de los 14 + 5 + 4)

### Auth (14 en backend)

| # | Método | Path | ¿Lo usa este front? | Pantalla / caller |
|---|---|---|---|---|
| 1 | POST | `/auth/register` | Sí | Registro |
| 2 | POST | `/auth/login` | Sí | Login |
| 3 | POST | `/auth/refresh` | Sí | Interceptor (todas las autenticadas) |
| 4 | POST | `/auth/logout` | Sí | Menú Inicio → Cerrar sesión |
| 5 | POST | `/auth/logout-all` | **No** | — |
| 6 | POST | `/auth/forgot-password` | Sí | Forgot password + reenviar en verify-code (modo reset) |
| 7 | POST | `/auth/verify-reset-code` | Sí | Verify-code (modo reset) |
| 8 | POST | `/auth/reset-password` | Sí | Reset password |
| 9 | POST | `/auth/email-verification/request` | Sí | Login (retoma `email_verification`) |
| 10 | POST | `/auth/email-verification/resend` | Sí | Verify-code (modo cuenta) |
| 11 | POST | `/auth/email-verification/confirm` | Sí | Verify-code (modo cuenta) |
| 12 | PATCH | `/auth/biometric` | Sí | Biometric-setup |
| 13 | GET | `/auth/onboarding` | Sí | Login (post-login / retoma) |
| 14 | PATCH | `/auth/onboarding/step` | Sí | Biometric, choose-alias, foco, doc, analyzing, analysis, first-ready |

El front declara **13** rutas auth: no llama `logout-all`.

### Users (5)

| # | Método | Path | ¿Lo usa este front? | Pantalla / caller |
|---|---|---|---|---|
| 1 | GET | `/users/me` | Sí | Arranque (`AuthProvider`) + reingreso biométrico |
| 2 | PATCH | `/users/me` | Sí | Choose-alias |
| 3 | POST | `/users/me/avatar` | **No** | Servicio existe; ninguna pantalla lo llama |
| 4 | PATCH | `/users/me/password` | **No** | Hook `useChangePasswordForm` sin ruta |
| 5a | PATCH | `/users/me/push-token` | Front **sí** | `useNotificationSetup` al autenticar |
| 5b | PATCH | `/users/profile` | Front **no** | Alias deprecado en backend; choose-alias usa `/users/me` |

El “quinto” no es el mismo: el front sigue mandando **push-token**; el backend de este workspace ya no lo declara y en su lugar mantiene `PATCH /users/profile` deprecado.

### Profile (4)

| # | Método | Path | ¿Lo usa este front? | Pantalla |
|---|---|---|---|---|
| 1 | POST | `/profile/goals` | Sí | Onboarding-foco |
| 2 | GET | `/profile/goals` | **No** | Servicio sin consumidor |
| 3 | GET | `/profile/financial` | **No** | Servicio + `IngresosDatosSheet` sin montar |
| 4 | PUT | `/profile/financial` | **No** | Igual; perfil es stub M2 |

---

## Afectación al cruzar este front con el backend actualizado

### Crítica — onboarding (login + 7 pantallas de flujo)

`walvy/main` del front habla **pasos**:

```
currentStep: email_verification | biometric_setup | profile_basic | welcome
             | document_upload | document_processing
resumeSurface: onboarding | home
```

El backend actualizado habla **puertas**:

```
currentGate: G0_activacion | G1_foco | G2_carga | G3_analisis
             | G4_revision | G5_diagnostico | G6_retoma
resumeState: none | ready_to_resume
```

Consecuencias concretas en este front:

| Pantalla | Qué deja de encajar |
|---|---|
| Login | `GET /auth/onboarding` ya no trae `currentStep` / `resumeSurface`. El mapa `ONBOARDING_STEP_ROUTE` no matchea → el usuario cae a tabs o a fallback `choose-alias`. |
| Biometric-setup | PATCH con `currentStep: "profile_basic"` → 400 (no está en `PUERTAS`). |
| Choose-alias | PATCH con `currentStep: "welcome"` → 400. |
| Onboarding (slides) | No patea `G0_activacion`; el backend nunca se entera de que vio la bienvenida. |
| Foco | PATCH con `currentStep: "document_upload"` en vez de `G1_foco` / `G2_carga`. `goalsSet` sí es campo compartido. |
| Doc / analyzing / analysis / first-ready | Mismo body viejo (`currentStep` + `resumeSurface`). Salir a home no escribe `resumeState: "ready_to_resume"`. |

`GET /users/me` ahora anida `onboarding` (puertas). El tipo `User` del front **no** tiene ese campo; el restore de sesión no lo usa para navegar (Splash siempre va a Login). Impacto bajo en Splash, alto si alguien empieza a leer `me.onboarding` sin adaptar el tipo.

### Media — users

| Cambio backend | Efecto en este front |
|---|---|
| `GET /users/me` exige cuenta que pueda sostener sesión | Arranque y biometría: token inválido → limpia store y muestra login first-time. Correcto si el mensaje/401 se mantiene. |
| `PATCH /users/me` unificado | Choose-alias ya pega aquí. Sin cambio de path. Revisar validación de `username` (formato / minúsculas). |
| `PATCH /users/profile` deprecado | Este front no lo llama. Sin afectación. |
| `PATCH /users/me/push-token` ausente en backend | Tras login, el registro de push falla en silencio (`catch {}`). No rompe UI; las push no llegan. |
| Avatar y change-password | Sin pantalla. Cambios de contrato no se ven hasta M2. |

### Baja / nula — profile financial y GET goals

Ninguna pantalla de `walvy/main` los llama. `(tabs)/profile` es placeholder. Cambiar `GET/PUT /profile/financial` no afecta esta versión. `POST /profile/goals` sí: solo **onboarding-foco**.

### Sin impacto de pantalla

- `POST /auth/logout-all` — el menú solo hace `POST /auth/logout`.
- `/confirm-account` y `/verify` — no pegan a API.

---

## Mapa rápido de retoma (lo que el login espera hoy)

| `currentStep` que lee el front | Ruta |
|---|---|
| `email_verification` | `/(auth)/verify-code` (+ request OTP) |
| `biometric_setup` | `/(auth)/biometric-setup` |
| `profile_basic` | `/(auth)/choose-alias` |
| `welcome` | `/(auth)/onboarding` |
| `document_upload` | `/(auth)/onboarding-doc` |
| `document_processing` | `/(auth)/onboarding-analyzing` |
| `completed` / `resumeSurface: "home"` / step desconocido | `/(tabs)` |

Hasta que el front traduzca `currentGate` → esas rutas, **cualquier actualización de GET/PATCH onboarding afecta primero Login y después todo el onboarding.**
