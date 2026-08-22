# Onboarding (slides) — `/(auth)/onboarding`

**Componente:** `expo/features/auth/ui/OnboardingScreen.tsx`  
**Ruta:** `app/(auth)/onboarding.tsx`  
**Tablero:** `M1-V27` (Aprobado) · `M1-V58` · `M1-RN-ACC-029` / `030` · `M1-RN-ONB-001` / `012` · `CP-M1-ONB-001` · `M01-RGL-005`  
**Figma:** láminas `6670:13197` · `6670:13103` · `8028:13058` · `8028:13093`; modal de salida `6670:13499`  
**Matriz:** [`../../matriz-v2.6/variantes-m1.psv`](../../matriz-v2.6/variantes-m1.psv) — v2.6, no el export de agosto 5

Bienvenida / activación: carrusel de 4 láminas con autoavance de 5 s y CTA **Comenzar** solo en la última.
Declara `G0_activacion` al montar. `AsyncStorage` `onboarding_seen` se escribe al terminar el carrusel y
**nadie lo lee**. El autoavance de 5 s no tiene fuente: no está en la matriz ni en los nodos de Figma.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| PATCH | `/auth/onboarding/step` | `advanceOnboardingStep` | Al montar: `{ currentGate: "G0_activacion" }`. 401 → login |

No hay PATCH de salida porque la pantalla no ofrece postergar — ver `M1-V58` abajo.

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V27` | `PATCH /auth/onboarding/step` | Entra al onboarding | Declara `G0_activacion` al montar; 4 láminas y CTA Comenzar → `/(auth)/onboarding-foco`. CTA dominante conforme: en Figma las láminas 1–3 llevan el mismo botón en `opacity-0` para alinear los dots, y el código reserva 40 px | **Conforme** (verificado en `walvy/main` `d02bb48` y en la rama local) |
| 2 | `M1-V58` | `PATCH /auth/onboarding/step` | Posterga en bienvenida | v2.6 Aprobado, decisión PO: *«permitir postergar antes de la carga conservando el checkpoint alcanzado»*. La pantalla **no ofrece salida**: falta el CTA + modal `6670:13499` que Foco sí tiene. `G0_activacion` queda declarado, pero no se escribe `resumeState: ready_to_resume` | **Divergente** — `M01-RGL-007` es Must, bloqueante si falla |
| 3 | `M1-V27` | — | Fidelidad visual | Corregido 2026-08-19: el Lottie estaba fijo en 301 cuando la composición es cuadrada de 380, y el hint del pie usaba `0.65` en vez de `rgba(31,42,51,0.8)` | Conforme |

---

**Anterior:** [`choose-alias.md`](choose-alias.md) · **Siguiente:** [`onboarding-foco.md`](onboarding-foco.md)
