# Mapa de rutas — front-walvy (expo-router)

**Última actualización:** 2026-07-08
**Fuente:** lectura directa de `front-walvy/expo/app/**` y de los `router.push/replace` en `features/auth`, `features/home`, `features/splash`.
**Complementa a:** [`auth-navigation-flows.md`](auth-navigation-flows.md) (detalle narrativo de condiciones de login/onboarding). Este doc es el grafo completo, incluyendo `(tabs)`.

---

## Grafo de navegación

```mermaid
flowchart TD
    Start(["App abre"]) --> Splash["/ (Splash)"]
    Splash -->|sin sesión| Login
    Splash -->|sesión + onboarding pendiente| StepRoute["resume al paso guardado"]
    Splash -->|sesión + onboarding completo| Tabs
    StepRoute -.-> Biometric
    StepRoute -.-> ChooseAlias
    StepRoute -.-> Onboarding
    StepRoute -.-> OnbDoc
    StepRoute -.-> OnbAnalyzing

    Dashboard["/dashboard (redirect legacy)"] --> Tabs

    subgraph AUTH["(auth) — Módulo 1: login / registro / recuperación"]
        Login["/login"]
        Register["/(auth)/register"]
        VerifyCode["/(auth)/verify-code"]
        Forgot["/forgot-password"]
        Reset["/(auth)/reset-password"]

        Login -->|"Crear cuenta"| Register
        Register -->|"POST /auth/register"| VerifyCode
        Login -->|"Olvidé mi contraseña"| Forgot
        Forgot -->|"OTP enviado (mode=reset)"| VerifyCode
        VerifyCode -->|"modo verificación, sin username"| Biometric
        VerifyCode -->|"modo verificación, con username"| Tabs
        VerifyCode -->|"modo reset, código OK"| Reset
        VerifyCode -->|"401 sesión expirada"| Login
        Reset -->|"éxito"| Login
    end

    subgraph ONBOARDING["Onboarding (post-login)"]
        Biometric["/(auth)/biometric-setup"]
        ChooseAlias["/(auth)/choose-alias"]
        Onboarding["/(auth)/onboarding"]
        OnbFoco["/(auth)/onboarding-foco"]
        OnbDoc["/(auth)/onboarding-doc"]
        OnbAnalyzing["/(auth)/onboarding-analyzing"]
        OnbAnalysis["/(auth)/onboarding-analysis"]
        OnbReady["/(auth)/onboarding-first-ready"]

        Biometric -->|"acepta / rechaza"| ChooseAlias
        Biometric -->|"sesión expirada"| Login
        ChooseAlias -->|"elige alias"| Onboarding
        ChooseAlias -->|"sesión expirada"| Login
        Onboarding --> OnbFoco
        OnbFoco -->|"saltar"| Tabs
        OnbFoco --> OnbDoc
        OnbDoc -->|"saltar / 401"| Tabs
        OnbDoc --> OnbAnalyzing
        OnbAnalyzing -->|"reintentar / error"| OnbDoc
        OnbAnalyzing -->|"401"| Login
        OnbAnalyzing --> OnbAnalysis
        OnbAnalysis --> OnbReady
        OnbAnalysis -->|"401"| Login
        OnbReady --> Tabs
    end

    subgraph DEEPLINKS["Deep links de email"]
        ConfirmAccount["/confirm-account"]
        Verify["/verify"]
        ConfirmAccount -->|"AccountConfirmedScreen"| Login
        Verify -->|"AccountConfirmedScreen"| Login
    end

    subgraph TABSGROUP["(tabs) — post-login (M2+, hoy son stubs)"]
        Tabs["/(tabs) Inicio"]:::stub
        Movs["/(tabs)/movimientos"]:::stub
        Mov["/(tabs)/movimiento"]:::stub
        Presu["/(tabs)/presupuesto"]:::stub
        Bot["/(tabs)/chatbot"]:::stub
        Profile["/(tabs)/profile (oculta)"]:::stub

        Tabs -. tab bar .- Movs
        Tabs -. tab bar .- Mov
        Tabs -. tab bar .- Presu
        Tabs -. tab bar .- Bot
        Tabs -->|"menú usuario: Mi Perfil"| Profile
        Tabs -->|"menú usuario: Cerrar Sesión"| Login
    end

    classDef stub fill:#fff3cd,stroke:#856404,color:#7a5200;
```

**Leyenda**
- 🟨 Amarillo (`stub`) — ruta registrada y alcanzable, pero la pantalla es un placeholder "Próximamente" (funcionalidad de un módulo futuro, no M1).

---

## Rutas no cubiertas en el grafo (infraestructura, no flujo de usuario)

| Ruta | Qué hace |
|---|---|
| `+not-found` | 404 genérico de Expo Router (template, sin tocar) |
| `+native-intent` | Handler de deep links nativos (pass-through) |

---

## Tabla de referencia rápida

| Ruta | Grupo | Estado | Pantalla real |
|---|---|---|---|
| `/` | raíz | ✅ funcional | `SplashScreen` |
| `/dashboard` | raíz | ✅ funcional (redirect) | → `/(tabs)` (sin screen propia) |
| `/confirm-account` | raíz | ✅ funcional | `AccountConfirmedScreen` |
| `/verify` | raíz | ✅ funcional | `AccountConfirmedScreen` |
| `/login` | `(auth)` | ✅ funcional | `LoginScreen` |
| `/register` | `(auth)` | ✅ funcional | `RegisterScreen` |
| `/forgot-password` | `(auth)` | ✅ funcional | `ForgotPasswordScreen` |
| `/(auth)/verify-code` | `(auth)` | ✅ funcional | `VerifyCodeScreen` |
| `/(auth)/reset-password` | `(auth)` | ✅ funcional | `ResetPasswordScreen` |
| `/(auth)/biometric-setup` | `(auth)` | ✅ funcional | `BiometricPromptScreen` |
| `/(auth)/choose-alias` | `(auth)` | ✅ funcional | `ChooseAliasScreen` |
| `/(auth)/onboarding` | `(auth)` | ✅ funcional | `OnboardingScreen` |
| `/(auth)/onboarding-foco` | `(auth)` | ✅ funcional | `OnboardingFocoScreen` |
| `/(auth)/onboarding-doc` | `(auth)` | ✅ funcional | `OnboardingDocScreen` |
| `/(auth)/onboarding-analyzing` | `(auth)` | ✅ funcional | `OnboardingAnalyzingScreen` |
| `/(auth)/onboarding-analysis` | `(auth)` | ✅ funcional | `OnboardingAnalysisScreen` |
| `/(auth)/onboarding-first-ready` | `(auth)` | ✅ funcional | `OnboardingFirstReadyScreen` |
| `/(tabs)` (index) | `(tabs)` | 🚧 stub "Próximamente" | `HomeTabScreen` |
| `/(tabs)/movimientos` | `(tabs)` | 🚧 stub "Próximamente" | `MovimientosTabScreen` |
| `/(tabs)/movimiento` | `(tabs)` | 🚧 stub "Próximamente" | `MovimientoTabScreen` |
| `/(tabs)/presupuesto` | `(tabs)` | 🚧 stub "Próximamente" | `PresupuestoTabScreen` |
| `/(tabs)/chatbot` | `(tabs)` | 🚧 stub "Próximamente" | `ChatbotTabScreen` |
| `/(tabs)/profile` (oculta) | `(tabs)` | 🚧 stub "Próximamente" | `ProfileTabScreen` |
