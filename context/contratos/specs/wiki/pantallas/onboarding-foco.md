# Onboarding-foco — `/(auth)/onboarding-foco`

**Componente:** `expo/features/auth/ui/OnboardingFocoScreen.tsx`  
**Ruta:** `app/(auth)/onboarding-foco.tsx`  
**Tablero:** [MV-M1-08](https://github.com/KabeliDev/front-walvy/issues/25) V28–V36 · retoma V58  
**Figma (según matriz v2.6):** `M1-V28` → `6670:13227` · `M1-V29` → `6670:13290`  
⚠️ Los frames muestran los estados **al revés** de lo que sugiere esa asignación: `6670:13227` es la pantalla
sin selección (botón inactivo) y `6670:13290` la que tiene «Bajar deuda» elegido. Pregunta para PO/diseño.
Los nodos `4249:*` que citaban los comentarios del componente fueron borrados del archivo (reapuntados el 2026-08-19).  
**Matriz:** [`../../matriz-v2.6/variantes-m1.psv`](../../matriz-v2.6/variantes-m1.psv)

Única pantalla que hace `POST /profile/goals`. `GET /profile/goals` no se llama (eso es M2).

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| POST | `/profile/goals` | `saveGoal` | Confirma un foco. `{ focusId }` |
| PATCH | `/auth/onboarding/step` | `advanceOnboardingStep` | Al montar: `{ currentGate: "G1_foco" }`. Tras save: `{ currentGate: "G2_carga", goalsSet: true }`. Postergar: `{ resumeState: "ready_to_resume" }` |

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V28` | `POST /profile/goals` | Elige un objetivo y continúa | 200. Un solo foco activo (sobrescribe) | Pendiente |
| 2 | `M1-V28` | `PATCH /auth/onboarding/step` | Tras POST OK | `{ currentGate: "G2_carga", goalsSet: true }` + avanza a doc. Cumple la `MatrizContinuidadM01`: `focus_saved` retoma en Carga documental, no en Foco | **Conforme** |
| 3 | `M1-V29` | `PATCH /auth/onboarding/step` | Posterga sin elegir foco | v2.6 = **Ajustar**: *«conservarse el estado pendiente y aplicarse la salida de postergación; no corresponde describir esta acción como avance directo a carga documental»*. El código hace exactamente eso: "Continuar más tarde" → modal `6670:13499` → `{ resumeState: "ready_to_resume" }` → tabs; `currentGate` sigue en `G1_foco` y el login retoma en Foco. `last_checkpoint_at` es la evidencia de `M01-RGL-007` | **Conforme al ajuste** (el «Comportamiento esperado» de la columna original quedó superado) |
| 4 | `M1-V30` | — | Foco sugerido | **Fuera del alcance de esta pantalla.** La decisión cerrada exige una versión válida del Diagnóstico y prioridad M04 → M06 → M05; en el primer paso por `G1_foco` no existe. Los CTAs («Usar este foco» / «Revisar foco» → Mi Perfil premarcado) son M2. Lo que falta de nuestro lado: `user_goals` no tiene dónde persistir el estado **`sugerido`** —`goal_status` es `active/paused/completed/dismissed/draft`, `goal_scope` es alcance— ni el marcador de «aceptado no se reemplaza». El ajuste pide además complementar `M1-RN-ONB-019` usando sólo la palabra `sugerido` | Dependencia intermodular |
| 5 | `M1-V31` | `POST /profile/goals` | Bajar deuda | `focusId` catálogo. 200 no 500 | Pendiente |
| 6 | `M1-V32` | `POST /profile/goals` | Ahorrar un monto | idem | Pendiente |
| 7 | `M1-V33` | `POST /profile/goals` | Aumentar margen | idem | Pendiente |
| 8 | `M1-V34` | `POST /profile/goals` | Evitar atrasos | idem | Pendiente |
| 9 | `M1-V35` | `POST /profile/goals` | Cumplir presupuesto | idem | Pendiente |
| 10 | `M1-V36` | `POST /profile/goals` | Ordenar compromisos | idem | Pendiente |
| 11 | `M1-V58` | `PATCH /auth/onboarding/step` | Pausa en foco | Con foco guardado ya escribió `G2_carga`, así que retoma en Carga documental. Sin foco manda sólo `resumeState`, `currentGate` sigue en `G1_foco` y retoma en Foco — que es «el punto de mayor valor pendiente» | Conforme |

Si `POST /profile/goals` falla, **no** avanzar (`M01-RGL-007`). 401 → login. Desde el 2026-08-19 el error del
POST y el del PATCH tienen mensajes distintos: si el foco quedó guardado y falló el checkpoint, la pantalla ya
no dice que no se pudo guardar el foco (copy provisional, no está en Figma).

**Anterior:** [`onboarding.md`](onboarding.md) · **Siguiente:** [`onboarding-doc.md`](onboarding-doc.md)
