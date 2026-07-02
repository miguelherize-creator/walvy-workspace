# Flujos de Navegación: Splash → Onboarding

**Última actualización:** 2026-06-15  
**Estado:** ✅ Refleja código actual post-fix biometría doble  
**Archivos clave:**
- `front-walvy/expo/store/AuthProvider.tsx` — restauración de sesión
- `front-walvy/expo/features/splash/ui/SplashScreen.tsx` — router principal
- `front-walvy/expo/features/auth/hooks/useLoginForm.ts` — lógica post-login
- `front-walvy/expo/features/auth/hooks/useBiometricLogin.ts` — login biométrico

---

## Cómo funciona el arranque

Cada vez que la app abre, suceden dos cosas en paralelo:

1. **AuthProvider** (invisible) — intenta restaurar sesión desde SecureStore. Mientras trabaja, `isLoading = true`.
2. **SplashScreen** — se muestra al usuario. Espera hasta que `isLoading = false`, luego decide a dónde navegar.

El SplashScreen **no decide por lógica propia** — solo lee el estado que deja AuthProvider (`isAuthenticated`, `loginSource`) y enruta.

---

## Flujo 1 — Primera vez (sin usuario guardado)

No hay token en SecureStore.

```
App abre
  │
  ├─ AuthProvider: sin token → isAuthenticated=false, isLoading=false
  │
  └─ SplashScreen → /login  (modo: firstTime)
       │  UI: campo email + campo password
       │
       └─ POST /auth/login
            │
            ├─ nextStep: "email_verification"
            │    └─ /(auth)/email-verification
            │         └─ ingresa OTP → POST /auth/email-verification/confirm
            │              └─ ── continúa en Flujo 4 (onboarding) ──
            │
            └─ sin nextStep → GET /auth/onboarding
                 └─ ── continúa en Flujo 4 (onboarding) ──
```

---

## Flujo 2 — Usuario guardado, sin biometría

Hay token en SecureStore. El usuario no tiene biometría habilitada.

```
App abre
  │
  ├─ AuthProvider: token existe → getMe() OK
  │    → isAuthenticated=true, loginSource='restored', isLoading=false
  │
  └─ SplashScreen: loginSource='restored' → /login  (modo: savedUserPassword)
       │  UI: saludo "¡Hola [nombre]!" + solo campo password
       │
       └─ POST /auth/login  (email tomado de SecureStore, invisible)
            └─ GET /auth/onboarding
                 └─ onboardingStatus='completed' → /(tabs)
```

> Si `getMe()` falla (token expirado/inválido), AuthProvider limpia SecureStore
> y el usuario cae en Flujo 1 (firstTime).

---

## Flujo 3 — Usuario guardado, con biometría

Hay token en SecureStore. El usuario tiene biometría habilitada y disponible.

```
App abre
  │
  ├─ AuthProvider: token existe → getMe() OK  (sin desafío biométrico aquí)
  │    → isAuthenticated=true, loginSource='restored', isLoading=false
  │
  └─ SplashScreen: loginSource='restored' → /login  (modo: savedUserBiometric)
       │  UI: saludo "¡Hola [nombre]!" + botón biométrico
       │
       └─ usuario toca botón → bioAuthenticate()
            ├─ canceló / falló → se queda en /login
            │    └─ puede tocar "Ingresar con clave" → modo savedUserPassword
            │         └─ continúa en Flujo 2
            │
            └─ OK → loginWithBiometric() → getMe()
                 └─ user.username existe → /(tabs)
```

> **Nota:** La biometría ocurre UNA sola vez, en la pantalla de login.
> AuthProvider ya no la desafía al arrancar (fix 2026-06-15).

---

## Flujo 4 — Onboarding (post login exitoso)

Se llega aquí desde Flujo 1, 2 o 3 después de `POST /auth/login` exitoso.
El `GET /auth/onboarding` determina en qué paso está el usuario.

```
GET /auth/onboarding
  │
  ├─ onboardingStatus: 'completed'           → /(tabs)  ✅ ya terminó
  ├─ resumeSurface: 'home'                   → /(tabs)  ✅ backend dice ir a home
  │
  ├─ currentStep: 'profile_basic'            → /(auth)/choose-alias
  │    └─ elige username → PATCH /auth/onboarding/step
  │         └─ /(auth)/onboarding  (carrusel intro, 4 slides)
  │              └─ /(auth)/onboarding-foco  (selección de objetivos)
  │                   └─ /(auth)/onboarding-doc  (subida de cartola)
  │                        └─ /(auth)/onboarding-analyzing  (procesando)
  │                             └─ /(auth)/onboarding-first-ready  (semáforo)
  │                                  └─ /(tabs)  ✅
  │
  ├─ currentStep: 'welcome'                  → /(auth)/onboarding  (carrusel)
  ├─ currentStep: 'document_upload'          → /(auth)/onboarding-doc
  ├─ currentStep: 'document_processing'      → /(auth)/onboarding-analyzing
  └─ currentStep: 'biometric_setup'          → /(auth)/biometric-setup
       └─ usuario acepta/rechaza → /(tabs)  ✅
```

---

## Flujo 5 — Registro nuevo

Usuario que nunca ha tenido cuenta.

```
/login → toca "Crear cuenta" → /(auth)/register
  │  UI: email, RUT, password, términos
  │
  └─ POST /auth/register
       └─ /(auth)/verify-code  (ingresa OTP del email)
            └─ POST /auth/email-verification/confirm
                 └─ loginSource='fresh' → GET /auth/onboarding
                      └─ currentStep: 'profile_basic' → /(auth)/choose-alias
                           └─ ── continúa en Flujo 4 ──
```

---

## Flujo 6 — Recuperación de contraseña

```
/login → toca "Olvidé mi contraseña" → /(auth)/forgot-password
  │
  └─ POST /auth/forgot-password  (envía OTP al email)
       └─ /(auth)/verify-code  (ingresa OTP)
            └─ /(auth)/reset-password  (nueva contraseña)
                 └─ → /login  (con mensaje de éxito)
```

---

## Resumen de condiciones clave

| Condición | Evaluada en | Resultado |
|-----------|-------------|-----------|
| Sin token en SecureStore | AuthProvider | firstTime mode |
| Token válido + `getMe()` OK | AuthProvider | `loginSource='restored'` → /login savedUser |
| Token inválido / expirado | AuthProvider | limpia SecureStore → firstTime mode |
| `savedEmail` en SecureStore | LoginScreen | savedUserPassword mode |
| `biometricAvailable && biometricEnabled && hasStoredToken` | LoginScreen | savedUserBiometric mode |
| `result.nextStep === 'email_verification'` | useLoginForm | → email-verification |
| `onboardingStatus === 'completed'` | useLoginForm | → /(tabs) directo |
| `resumeSurface === 'home'` | useLoginForm | → /(tabs) directo |
| `currentStep !== null` | useLoginForm | → pantalla del paso |
| `!user.username` (fallback) | useLoginForm / SplashScreen | → choose-alias |

---

## Estado de salud del flujo

| Check | Estado |
|-------|--------|
| Biometría doble en startup | ✅ Corregido 2026-06-15 |
| onboarding nunca cierra (M1-DT-04) | ⚠️ Pendiente — `financialProfileCompleted` bloqueado por M2-DT-01 |
| `currentStep` sin validación enum | ⚠️ Backend acepta strings libres |
| Fallback si GET /auth/onboarding falla | ✅ Usa `!user.username` como proxy |
