# Onboarding-analysis — `/(auth)/onboarding-analysis`

**Componente:** `expo/features/auth/ui/OnboardingAnalysisScreen.tsx` (+ loader en `app/(auth)/onboarding-analysis.tsx`)  
**Ruta:** `app/(auth)/onboarding-analysis.tsx`  
**Tablero:** suficiencia V48–V52 (revisión de extraído)  
**Figma:** usable `6672:8252` · confirmar `6459:8169`

Revisión de lo extraído **antes** del semáforo final. Auth: step al salir.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| GET | `/statement-imports/:id/summary` | `getImportSummaryBatch` (ruta) | Al entrar, por cada importId |
| GET | `/statement-imports/:id/status` | `getImportStatus` | Poll si aún no parsed |
| PATCH | `/auth/onboarding/step` | salir a home | `{ currentStep: "document_upload", resumeSurface: "home" }` |

`GET/PUT /profile/financial` **no** se llama (IngresosDatosSheet no está montado).

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V39` | `GET .../summary` | Documento usable | Muestra extraído. CTA a first-ready / diagnóstico | Pendiente |
| 2 | `M1-V49` | `GET .../summary` | Faltantes no bloqueantes | Advertencia, puede seguir | Pendiente |
| 3 | `M1-V50` / `V51` | `GET .../summary` | Crítico / insuficiente | Bloquea diagnóstico. Pedir completar / otra carga | Pendiente |
| 4 | `M1-V04` (ingreso) | `PUT /profile/financial` | Confirmar sueldo en sheet | **No implementado** en esta pantalla (M2 / RM1-22) | Pendiente |
| 5 | `M1-V58` / salir | `PATCH /auth/onboarding/step` | Exit modal | Home + pending document_upload | Pendiente |

**Siguiente:** [`onboarding-first-ready.md`](onboarding-first-ready.md)
