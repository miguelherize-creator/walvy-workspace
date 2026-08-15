# Casos de prueba por pantalla

Un archivo por pantalla: **endpoint × ID de variante** para controlar qué se prueba y dónde.

**Índice general:** [`../frontend-pantallas-endpoints.md`](../frontend-pantallas-endpoints.md)  
**Matriz:** `context/bitacora/2026-08-05-revision-m1-v3/variantes-validacion.psv`  
**Front:** `walvy-org/walvy-app-frontend@main` (`a929a2c`)

## Archivos

| Pantalla | Ruta | Archivo |
|---|---|---|
| Splash | `/` | [`splash.md`](splash.md) |
| Login | `/login` | [`login.md`](login.md) |
| Register | `/(auth)/register` | [`register.md`](register.md) |
| Verify-code | `/(auth)/verify-code` | [`verify-code.md`](verify-code.md) |
| Forgot-password | `/forgot-password` | [`forgot-password.md`](forgot-password.md) |
| Reset-password | `/(auth)/reset-password` | [`reset-password.md`](reset-password.md) |
| Biometric-setup | `/(auth)/biometric-setup` | [`biometric-setup.md`](biometric-setup.md) |
| Choose-alias | `/(auth)/choose-alias` | [`choose-alias.md`](choose-alias.md) |
| Onboarding slides | `/(auth)/onboarding` | [`onboarding.md`](onboarding.md) |
| Foco | `/(auth)/onboarding-foco` | [`onboarding-foco.md`](onboarding-foco.md) |
| Carga doc | `/(auth)/onboarding-doc` | [`onboarding-doc.md`](onboarding-doc.md) |
| Procesando | `/(auth)/onboarding-analyzing` | [`onboarding-analyzing.md`](onboarding-analyzing.md) |
| Revisión | `/(auth)/onboarding-analysis` | [`onboarding-analysis.md`](onboarding-analysis.md) |
| Diagnóstico | `/(auth)/onboarding-first-ready` | [`onboarding-first-ready.md`](onboarding-first-ready.md) |
| Tabs / Inicio | `/(tabs)` | [`tabs.md`](tabs.md) |
| Deep link confirm | `/confirm-account`, `/verify` | [`confirm-account.md`](confirm-account.md) |

## Cómo llenar cada archivo

| Columna | Qué va |
|---|---|
| ID variante | `M1-Vxx` / `M2-Vxx` de la matriz |
| Endpoint | Método + path. `—` si es solo UI / navegación |
| Disparador | Qué hace el usuario o el arranque |
| Esperado | Comportamiento de la matriz + lo que hace este front |
| Estado | `Pendiente` · `Conforme` · `Divergente` · `No implementado` · `Bloqueado` |

Una variante puede aparecer en dos pantallas. El archivo solo lista **los casos que se ejecutan ahí**. Veredicto vacío = aún no corrido.
