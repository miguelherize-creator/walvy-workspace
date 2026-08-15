# Onboarding-first-ready — `/(auth)/onboarding-first-ready`

**Componente:** `expo/features/auth/ui/OnboardingFirstReadyScreen.tsx`  
**Ruta:** `app/(auth)/onboarding-first-ready.tsx`  
**Tablero:** diagnóstico V53–V57 · frontera perfil `M1-RN-ONB-016` / [RM1-22](https://github.com/KabeliDev/back-walvy/issues/42)  
**Figma:** en control `6670:13628` · atención `6670:13717` · riesgo `6670:13805`

Primera lectura (semáforo). Luego tabs. **No cierra el onboarding.**

`UserOnboardingService` solo pone `completed` si `financialProfileCompleted`, `importAttempted`, `biometricPrompted` y `minDocThresholdMet` son las cuatro `true`. `goalsSet` no cuenta. Las dos de suficiencia no las escribe nadie (M3); el DTO del step ya no las acepta. Ir a Inicio deja el onboarding en `in_progress`. Detalle: [`frontend-pantallas-endpoints.md`](../frontend-pantallas-endpoints.md) § Cierre.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| GET | `/statement-imports` | `listImports` | Resolver ids |
| GET | `/statement-imports/:id/summary` | `getImportSummary` | Semáforo |
| PATCH | `/auth/onboarding/step` | CTA ir a home | `{ currentStep: "document_processing", resumeSurface: "home" }` |

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V48` / `V53` | `GET .../summary` | Base suficiente, en control | Lectura favorable + CTA. Light válido | Pendiente |
| 2 | `M1-V54` | `GET .../summary` | Atención | Copy + CTA dominante | Pendiente |
| 3 | `M1-V55` | `GET .../summary` | Riesgo | Riesgo sereno, una presión | Pendiente |
| 4 | `M1-V56` | `GET .../summary` | Sin diagnóstico | No rojo por falta de datos | Pendiente |
| 5 | `M1-V57` | — | Varias señales | Una presión + un CTA. Resto secundario | Pendiente |
| 6 | `M1-V48` | `PATCH /auth/onboarding/step` | CTA a Inicio | Va a `/(tabs)`. No cierra: faltan `financialProfileCompleted` y `minDocThresholdMet` (M3). Body viejo (`currentStep`) | Pendiente |
| 7 | `M1-RN-ONB-016` | `GET/PUT /profile/financial` | Salida a Perfil Financiero | **Fuera de M1.** Tabs/profile es stub. RM1-22 | Pendiente |

**Siguiente:** [`tabs.md`](tabs.md)
