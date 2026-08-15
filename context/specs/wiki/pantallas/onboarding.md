# Onboarding (slides) — `/(auth)/onboarding`

**Componente:** `expo/features/auth/ui/OnboardingScreen.tsx`  
**Ruta:** `app/(auth)/onboarding.tsx`  
**Tablero:** `M1-V27` · `M1-RN-ACC-029` / `030` · `M1-RN-ONB-001`  
**Figma:** `6670:13197`

Bienvenida / activación. **Ningún endpoint.** Solo `AsyncStorage` `onboarding_seen` y va a foco.

---

## Endpoints

Ninguno. El backend espera `currentGate: G0_activacion` al entrar; este front no lo declara.

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V27` | — | Entra al onboarding | Slides + CTA Comenzar → `/(auth)/onboarding-foco` | Pendiente |
| 2 | `M1-V58` | — | Sale / posterga en bienvenida | Matriz: conservar estado. Acá no hay PATCH de retoma; si mata la app, login no sabe que vio G0 | Pendiente |
| 3 | `M1-V27` | `PATCH /auth/onboarding/step` | Montar / Comenzar | **No implementado** en walvy/main. Hueco vs puertas | Pendiente |

---

**Anterior:** [`choose-alias.md`](choose-alias.md) · **Siguiente:** [`onboarding-foco.md`](onboarding-foco.md)
