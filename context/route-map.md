# Mapa de rutas — Walvy Frontend

**Última actualización:** 2026-06-09
**Basado en:** `front-walvy/expo/app/` (Expo Router file-based routing)

---

## Módulo 1 — Flujos sin sesión `(auth)/`

> Todas las pantallas de este grupo usan `Stack` sin header global.
> Entry point: `app/index.tsx` (Splash) decide la primera ruta.

### Lógica del Splash (`app/index.tsx`)

```
App arranca
    │
    ├── loginSource === null       ──→  /(auth)/login
    ├── loginSource === 'restored' ──→  /(tabs)          [sesión en SecureStore]
    └── loginSource === 'fresh'
            ├── sin username       ──→  /(auth)/choose-alias
            └── con username       ──→  /(tabs)
```

---

### Flujo A — Login (usuario existente)

```
/(auth)/login
    │
    ├── [credenciales OK]
    │       │
    │       ├── nextStep === "email_verification"  ──────────────────→  /(auth)/email-verification
    │       │
    │       └── GET /auth/onboarding
    │               │
    │               ├── resumeSurface === "onboarding"
    │               │       ├── currentStep: "biometric_setup"     ──→  /(auth)/biometric-setup
    │               │       ├── currentStep: "profile_basic"        ──→  /(auth)/choose-alias
    │               │       │                                                └── → /(auth)/onboarding [ver Flujo C]
    │               │       ├── currentStep: "welcome"              ──→  /(auth)/onboarding
    │               │       ├── currentStep: "document_upload"      ──→  /(auth)/onboarding-doc
    │               │       └── currentStep: "document_processing"  ──→  /(auth)/onboarding-analyzing
    │               │
    │               ├── resumeSurface === "home"  ──────────────────→  /(tabs)
    │               ├── onboardingStatus === "completed"  ──────────→  /(tabs)
    │               │
    │               └── [GET falla — fallback legacy]
    │                       ├── sin username  ──────────────────────→  /(auth)/choose-alias
    │                       └── con username  ──────────────────────→  /(tabs)
    │
    ├── "¿Olvidaste tu contraseña?"  ──────────────────────────────→  /(auth)/forgot-password
    │                                                                        └── → /(auth)/reset-password
    │                                                                                  └── [OK] → /(auth)/login
    │
    └── "Crear cuenta"  ───────────────────────────────────────────→  /(auth)/register  [ver Flujo B]
```

---

### Flujo B — Registro (usuario nuevo)

```
/(auth)/register
    │
    └── [POST /auth/register OK]
          │
          └── /(auth)/email-verification        ← "Te enviamos un código a tu correo"
                │
                ├── [ingresar código]  ──→  /(auth)/verify-code
                │                             │
                │                             └── [POST /auth/verify-email OK]
                │                                  │
                │                                  └── /(auth)/biometric-setup
                │                                       │
                │                                       ├── [activar biometría / omitir]
                │                                            │
                │                                            └── /(auth)/choose-alias
                │                                                 │
                │                                                 └── [alias guardado]
                │                                                      │
                │                                                      └── /(auth)/onboarding [ver Flujo C]
                │
                └── [reenviar código]  ──→  mismo /(auth)/email-verification
```

> **Nota:** `/(auth)/register-confirmation` es una pantalla auxiliar
> que muestra el estado de confirmación de cuenta (accesible también
> desde el flujo de reenvío de email).

---

### Flujo C — Onboarding (primera vez, post choose-alias)

```
/(auth)/onboarding                ← "Analicemos tus finanzas"
    │
    └── "Subir cartola"  ──→  /(auth)/onboarding-doc
                                │
                                └── [documento cargado]
                                    │
                                    └── /(auth)/onboarding-analyzing    ← spinner / procesando
                                                │
                                                └── [análisis listo]
                                                            │
                                                            └── /(auth)/onboarding-analysis    ← resultados IA
                                                                        │
                                                                        └── /(auth)/onboarding-foco    ← elegir foco del mes
                                                                            │
                                                                            └── /(auth)/onboarding-first-ready
                                                                                    │
                                                                                    ├── "Entrar"  ──→  /(tabs)
                                                                                    └── [skip]    ──→  /(tabs)
```

> El onboarding también se puede omitir saltando directo a `/(tabs)` desde
> `onboarding-first-ready`. Si el análisis falla con 401 → `/(auth)/login`.

---

## Resumen de pantallas — Módulo 1

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/(auth)/login` | LoginScreen | Login con email/contraseña + modo usuario guardado |
| `/(auth)/register` | RegisterScreen | Registro con email, RUT, contraseña |
| `/(auth)/email-verification` | EmailVerificationScreen | "Revisa tu correo — ingresa el código" |
| `/(auth)/verify-code` | VerifyCodeScreen | Input OTP 6 dígitos |
| `/(auth)/biometric-setup` | BiometricPromptScreen | Activar Face ID / huella |
| `/(auth)/choose-alias` | ChooseAliasScreen | Elegir @alias único |
| `/(auth)/forgot-password` | ForgotPasswordScreen | Solicitar código de recuperación |
| `/(auth)/reset-password` | ResetPasswordScreen | Nueva contraseña con código OTP |
| `/(auth)/register-confirmation` | RegisterConfirmationScreen | Estado de confirmación de cuenta |
| `/(auth)/onboarding` | OnboardingScreen | Pantalla de entrada al onboarding |
| `/(auth)/onboarding-doc` | OnboardingDocScreen | Subir cartola bancaria |
| `/(auth)/onboarding-analyzing` | OnboardingAnalyzingScreen | Spinner — procesando documento |
| `/(auth)/onboarding-analysis` | OnboardingAnalysisScreen | Resultados del análisis IA |
| `/(auth)/onboarding-foco` | OnboardingFocoScreen | Elegir foco financiero del mes |
| `/(auth)/onboarding-first-ready` | OnboardingFirstReadyScreen | "¡Listo! Ya puedes entrar" |

**Estado:** ✅ Todas conectadas al backend (onboarding ⚠️ parcial — ver M1-DT-04 en `debt.md`)

---

## Flujo D — Mi Perfil y Cerrar Sesión `(tabs)/`

> Accesible desde el menú de usuario del header global (todas las pantallas dentro de `(tabs)/`).

```
/(tabs)/index — Home
    │
    ├── Menú usuario → "Cerrar Sesión"
    │       └── POST /auth/logout { refreshToken }
    │               └── → /(auth)/login
    │
    └── Menú usuario → "Mi Perfil"
            │
            └── /(tabs)/profile
                    │   Al entrar: sin llamada (user en memoria — AuthProvider)
                    │   Acción "Guardar datos": PATCH /users/me { username, firstName, lastName }
                    │   Acción "Cambiar foto":  POST /users/me/avatar (multipart, image/jpeg|png|webp, max 5MB)
                    │                              └── Backend: resize 400×400 WebP → S3 → actualiza avatarUrl
                    │                              └── Respuesta: user completo con nuevo avatarUrl
                    │
                    ├── "Perfil financiero"
                    │       └── /(tabs)/financial-profile
                    │               Al entrar:
                    │                 GET /profile/financial
                    │                 GET /statement-imports
                    │                 GET /statement-imports/:id/lines   (si hay import parsed)
                    │               Acción "Guardar": PUT /profile/financial { monthlyIncomeEstimate, estimatedPaymentCapacity, stableExpensesNote, currency }
                    │
                    ├── "Foco del mes"
                    │       └── /(tabs)/financial-goal
                    │               Al entrar: GET /profile/goals
                    │               Acción "Guardar": POST /profile/goals { focusId }
                    │               Valores válidos: bajar_deuda | ahorrar_monto | aumentar_margen |
                    │                               evitar_atrasos | cumplir_presupuesto | ordenar_compromisos
                    │
                    ├── "Suscripción"
                    │       └── /(tabs)/subscription
                    │               Al entrar: GET /subscriptions/me
                    │               │
                    │               ├── "Ver planes"
                    │               │       └── /(tabs)/subscription-plans
                    │               │               Al entrar: GET /subscriptions/plans
                    │               │               Acción "Contratar":
                    │               │                 POST /subscriptions/checkout { planId }
                    │               │                     └── Respuesta: { paymentUrl }
                    │               │                             └── Linking.openURL(paymentUrl)
                    │               │                                     └── Usuario paga en Flow (navegador)
                    │               │                                             │
                    │               │                                             ├── [pago exitoso]
                    │               │                                             │       Flow → POST /subscriptions/webhook (backend activa suscripción)
                    │               │                                             │       Flow → GET /subscriptions/return
                    │               │                                             │               └── /subscription-success
                    │               │                                             │                       └── → /(tabs)
                    │               │                                             │
                    │               │                                             └── [pago fallido / cancelado]
                    │               │                                                     Flow → GET /subscriptions/return
                    │               │                                                             └── vuelve a /(tabs)/subscription-plans
                    │               │
                    │               └── "Cancelar suscripción" (modal)
                    │                       Acción: POST /subscriptions/me/cancel
                    │                       Respuesta: { activeUntil }  ← acceso hasta fin de período
                    │
                    ├── "Configuración"
                    │       └── /(tabs)/settings
                    │               Al entrar: sin llamada (lee AuthProvider en memoria)
                    │               Acción "Modo oscuro": ThemeProvider local (sin API)
                    │               │
                    │               └── "Preferencias de avisos"
                    │                       └── /(tabs)/notification-settings
                    │                               Al entrar: sin llamada ⚠️ (M2-FE-06 — pendiente backend)
                    │                               Acción "Guardar": local state solo (sin API)
                    │
                    └── "Cambiar contraseña"
                            └── /(tabs)/change-password
                                    Al entrar: sin llamada
                                    Acción "Guardar": PATCH /users/me/password { currentPassword, newPassword }
```

### Estado de conexión — Flujo D

| Pantalla | Al entrar | Acción principal | Estado |
|----------|-----------|-----------------|--------|
| `profile` | — memoria | `PATCH /users/me` · `POST /users/me/avatar` | ✅ |
| `financial-profile` | `GET /profile/financial` + imports | `PUT /profile/financial` | ✅ |
| `financial-goal` | `GET /profile/goals` | `POST /profile/goals` | ✅ |
| `subscription` | `GET /subscriptions/me` | `POST /subscriptions/me/cancel` | ✅ |
| `subscription-plans` | `GET /subscriptions/plans` | `POST /subscriptions/checkout` → Flow | ✅ |
| `notification-settings` | — | local state | ⚠️ sin backend (M2-FE-06) |
| `change-password` | — | `PATCH /users/password` | ✅ |

---

## Archivos clave de navegación

| Archivo | Función |
|---------|---------|
| `app/_layout.tsx` | Root layout — providers globales (AuthProvider, QueryClientProvider, GestureHandlerRootView) |
| `app/(auth)/_layout.tsx` | Stack layout para flujo auth — `headerShown: false`, `animation: "fade"` |
| `app/(tabs)/_layout.tsx` | Tab navigator + header global |
| `app/index.tsx` | Splash + lógica de redirección inicial |
| `store/AuthProvider.tsx` | Estado de auth + `loginSource: 'fresh' \| 'restored' \| null` |
| `hooks/useDeepLinkHandler.ts` | Maneja deep links entrantes (email verification, etc.) |
