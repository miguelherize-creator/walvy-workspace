# Onboarding-foco — `/(auth)/onboarding-foco`

**Componente:** `expo/features/auth/ui/OnboardingFocoScreen.tsx`  
**Ruta:** `app/(auth)/onboarding-foco.tsx`  
**Tablero:** [MV-M1-08](https://github.com/KabeliDev/front-walvy/issues/25) V28–V36 · retoma V58  
**Figma:** selección `6670:13227` · sin foco `6670:13290`

Única pantalla que hace `POST /profile/goals`. `GET /profile/goals` no se llama (eso es M2).

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| POST | `/profile/goals` | `saveGoal` | Confirma un foco. `{ focusId }` |
| PATCH | `/auth/onboarding/step` | `advanceOnboardingStep` | Tras save: `{ currentStep: "document_upload", resumeSurface: "onboarding", goalsSet: true }`. Salir sin foco: `resumeSurface: "home"` |

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V28` | `POST /profile/goals` | Elige un objetivo y continúa | 200. Un solo foco activo (sobrescribe) | Pendiente |
| 2 | `M1-V28` | `PATCH /auth/onboarding/step` | Tras POST OK | `goalsSet: true` + avanza a doc. Body `currentStep` vs `currentGate` (G1/G2) | Pendiente |
| 3 | `M1-V29` | `PATCH /auth/onboarding/step` | Continúa / sale **sin** foco | Sin POST goals. Va a doc o a tabs (`resumeSurface: home`). No bloquea carga | Pendiente |
| 4 | `M1-V30` | `GET /profile/goals` | Foco inferido/sugerido | **No implementado.** Nadie lee GET. Matriz documental | Pendiente |
| 5 | `M1-V31` | `POST /profile/goals` | Bajar deuda | `focusId` catálogo. 200 no 500 | Pendiente |
| 6 | `M1-V32` | `POST /profile/goals` | Ahorrar un monto | idem | Pendiente |
| 7 | `M1-V33` | `POST /profile/goals` | Aumentar margen | idem | Pendiente |
| 8 | `M1-V34` | `POST /profile/goals` | Evitar atrasos | idem | Pendiente |
| 9 | `M1-V35` | `POST /profile/goals` | Cumplir presupuesto | idem | Pendiente |
| 10 | `M1-V36` | `POST /profile/goals` | Ordenar compromisos | idem | Pendiente |
| 11 | `M1-V58` | `PATCH /auth/onboarding/step` | Pausa en foco | Conservar; retoma en carga si `goalsSet`. Front manda `document_upload` + `home` al salir | Pendiente |

Si `POST /profile/goals` falla, **no** avanzar (M01-RGL-007). 401 → login.

**Anterior:** [`onboarding.md`](onboarding.md) · **Siguiente:** [`onboarding-doc.md`](onboarding-doc.md)
