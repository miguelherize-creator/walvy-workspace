# Plan de cierre · Semáforo del Resultado de deudas (M04, paso 3)

**Cierra:** [front-walvy#159](https://github.com/KabeliDev/front-walvy/issues/159) · [front-walvy#160](https://github.com/KabeliDev/front-walvy/issues/160) · [back-walvy#241](https://github.com/KabeliDev/back-walvy/issues/241)
**Contrato:** `Walvy_M04_Entrega_Kabeli_v1.0` §8.3 (OD-03), §10.1 y Anexo BDD §6.4/§19.5
**REQ:** [`req-resultado-onboarding-semaforo.md`](req-resultado-onboarding-semaforo.md)
**Fecha:** 2026-09-06

---

## 1 · El punto que hay que aceptar antes de planificar

Se pidieron **tres escenarios: verde, amarillo, rojo**. El contrato los tiene, pero **no son tres renders: son cinco.**

- El **rojo se parte en dos** derivaciones distintas, con CTA distinto: Riesgo con gate incompleto **no expone Ruta** («Riesgo con gate bloqueado ≠ CTA Ruta»).
- Existe un **quinto estado sin color**, `no calculable`, que es el único que la app produce hoy y el que causa el defecto de #159.

Planificar solo tres renders deja fuera precisamente el estado que hay que corregir. Los tres colores se mantienen como los pidió Producto; lo que se agrega es una sub-variante del rojo y un estado neutro.

---

## 2 · Matriz de escenarios (la fuente para Diseño, Back, Front y QA)

| # | Color | Presión | Gate (confirmada + datos + Riesgo) | Titular | Derivación / CTA | ¿Frame? |
|---|---|---|---|---|---|---|
| **1** | 🟢 Verde | `en_control` | — | En Control | Seguimiento/detalle. CTA operativo M06 | ✅ existe |
| **2** | 🟡 Amarillo | `atencion` | — | Atención | Revisión preventiva/contextual. **Sin Ruta** | ❌ **falta** |
| **3** | 🔴 Rojo·A | `riesgo` | ✗ incompleto | Riesgo | Resolver **F2** Confirmar → **F1** Completar → **F3** Actualizar. **Sin Ruta** | ❌ **falta** |
| **4** | 🔴 Rojo·B | `riesgo` | ✓ completo | Riesgo | **Ver Ruta Despeje** (elegible; no activa hasta «Seguir plan») | ⚠️ existe en ámbar — hay que repintar |
| **5** | ⚪️ Neutro | `no calculable` | — | *(por definir)* | No afirmar. **Prohibido pintar En Control** | ❌ **falta** |

**Lo que hoy hace la app:** todo cae en 1 o en 4. El escenario 5 —el real— se pinta como 1, y el 4 se pinta en ámbar con copy de mora. Los escenarios 2 y 3 son irrepresentables: no llegan por la API.

### Correcciones de copy que la matriz obliga

| Dónde | Hoy | Problema |
|---|---|---|
| Card ámbar | «Detectamos un **atraso confirmado**» | Riesgo es estado financiero (C×K×D + floors), no mora |
| Card verde | «Tus pagos **están al día**» | Se muestra sin evaluar. Viola §10.1 |
| Escenario 4 | Titular «Atención» | Es **Riesgo**. «Atención» es el escenario 2, que no abre Ruta |

---

## 3 · Orden de trabajo

La dependencia real es **Fase 0 → 1 → 2**. La Fase A es paralela y ya está hecha.

### Fase A · Navegación — ✅ cerrada

`#160` · PR [#161](https://github.com/KabeliDev/front-walvy/pull/161) contra `qa`. Independiente del semáforo.

### Fase 0 · Desbloquear QA — *sin esto nada de lo demás se verifica*

**Repo:** `back-walvy` · **Bloquea:** todo

Hoy `NullPressureInputsAdapter` devuelve `ingresoMensualCanonico: null` y `headroomRatio: null`, así que **los escenarios 1–4 son irreproducibles**. No es que falte el motor P4 —está completo y cableado—: falta el adaptador de entradas.

- Adaptador de fixtures detrás de flag (`M04_PRESSURE_FIXTURES` o equivalente), que permita inyectar C/K/D por usuario de prueba.
- Semillas para las cinco celdas de la matriz §2, derivadas de `PRESSURE_MATRIX` en `pressure-matrix.rule.ts`:

| Escenario | C | K | D | Presión |
|---|---|---|---|---|
| 1 Verde | C1 (<25%) | K2 (>20%) | D0 | `en_control` |
| 2 Amarillo | C1 | K1 (0–20%) | D0 | `atencion` |
| 3 y 4 Rojo | C3 (≥50%) | K0 (≤0%) | D0 | `riesgo` |
| 5 Neutro | — | — | — | `null` (adaptador nulo) |

> El flag es **solo de QA**. En producción sigue el adaptador nulo hasta que M05 y M06 entreguen las entradas reales.

### Fase 1 · Publicar el contrato — `back-walvy#241`

**Repo:** `back-walvy` · **Depende de:** nada (se puede empezar **ya**) · **Bloquea:** Fase 2

El pipeline ya calcula presión por deuda y la descarta al serializar. Hay que exponerla en `GET /debts/route/current`:

- **`pressure_evaluation_status`** con el vocabulario cerrado del contrato: `no evaluada` / `sin presión` / `posible presión` / `bajo presión` / `no calculable`. Nombre y vocabulario **del contrato**, no propios.
- La **salida visible** En Control / Atención / Riesgo cuando es evaluable.
- El **estado del gate** por separado, para distinguir el escenario 3 del 4 sin que el front lo infiera.
- **Salud de deuda** con el vocabulario que ya consume M02 (`src/profile/debt-health.ts`).

Dos cosas a no hacer:

- **No** construir `GET /debts/result` con `trafficLight`: ese contrato quedó descartado (REQ §3).
- **No** derivar el **27% de capacidad comprometida** del frame como si fuera regla — el Anexo BDD prohíbe usar indicadores visibles de Figma como fórmula. **Cerrado el 2026-09-06:** la entrega ya lo resolvió en §14 («Valores Figma 27/43/58 · visual/referencial · no thresholds financieros») y en `P4-CNT-007`. No requiere declaración de Producto; queda como ajuste de materialización.

**Importante:** publicar `no calculable` **no depende de M05**. Se puede exponer hoy y desbloquea la mitad del fix de #159 de inmediato.

### Fase 2 · Consumir y pintar — `front-walvy#159`

**Repo:** `front-walvy` · **Depende de:** Fase 1 (para 1–4) · **Bloqueo parcial:** Diseño

Se parte en dos entregas para no quedar esperando frames:

**2a · Dejar de mentir** — solo necesita `no calculable` de la Fase 1.
`resolveResultVariant` deja de mapear `pendiente_datos` / `pendiente_confirmacion` a la card verde. Es la corrección de cumplimiento; puede salir sola.

**2b · Los cinco renders** — necesita Fase 1 completa + frames.
Reescribir `resolveResultVariant` para que lea presión + gate en vez de `eligibility`, y `DebtResultScreen` para las cinco variantes. Corregir los tres copys de §2.

También aquí: hoy `ResultVariant` tiene tres valores y **dos renders** (`sin_presion` y `no_confirmed` son idénticos), y `no_elegible` —el único que legítimamente significa En Control— comparte render con `pendiente_datos`, que significa lo contrario. Esa colisión desaparece al pasar a los cinco estados.

### Fase 3 · Cerrar la documentación — ✅ cerrada 2026-09-06

- ✅ `contexto/debts-manual-entry.md` → banner de documento histórico + §3 marcada como superada.
- ✅ `deuda-tecnica/README.md` → reescrito. La deuda real es el adaptador de `PressureInputs`, los tres estados sin frame y el 27%.
- ✅ `../wiki-codigo/recorrido-de-pantallas.md` → el nodo `RESULT` ya no es binario y se agregó el párrafo de las cinco lecturas.
- `preguntas-abiertas-producto.md` §3 → OD-03 es el frame funcional; ya no es bloqueo.
- ✅ `back-walvy/docs/api/debts/route.md` → contrato nuevo, tabla de escenarios y reason codes (entró con la Fase 1).
- ~~**`debt-severity.rule.ts`** → decidir: borrar, o dejar documentado~~ → **borrado**. `hasMoraConfirmada` se movió a `src/imports/rules/mora-confirmada.rule.ts`; el aging pertenece a Salud/M06.

---

## 4 · Lo que bloquea y de quién depende

| Bloqueo | Dueño | Sin esto |
|---|---|---|
| **Frames de escenarios 2, 3 y 5** | Diseño | No sale la Fase 2b. Figma modeló amarillo y rojo como si ambos abrieran Ruta — hay que rehacerlos, no solo agregarlos |
| **Qué se pinta en `no calculable`** | Producto | El contrato prohíbe En Control pero no define alternativa. Es el estado real de hoy |
| **¿M06 es destino del CTA verde antes de existir?** | Producto | El tab `payments` es un stub. ¿Se oculta, deshabilita o cambia de copy? |
| **Dueño del adaptador de fixtures** | — **sin asignar** | No sale la Fase 0 y nada se verifica |
| **¿El 27% es una regla?** | ~~Producto~~ · **cerrado** | No. §14 y `P4-CNT-007` lo declaran visual/referencial. Fase 1 lo omite |

---

## 5 · Criterio de cierre

Los tres issues cierran cuando:

1. `GET /debts/route/current` publica presión, gate y salud con el vocabulario del contrato **(#241)**.
2. La pantalla representa los cinco escenarios de §2 y **ninguno afirma En Control sin evidencia** **(#159)**.
3. El CTA de Ruta aparece **solo** en el escenario 4 **(#159)**, y abre Ruta **(#160 ✅)**.
4. Los tres copys de §2 están corregidos.
5. QA reproduce los cinco escenarios con las semillas de la Fase 0.
6. La documentación de §3 quedó actualizada o marcada como histórica.

---

## 6 · Riesgo principal

**Las Fases 0 y 2b dependen de decisiones que aún no tienen dueño** (frames, estado neutro, adaptador). La Fase 1 y la 2a **no dependen de ninguna** y corrigen el incumplimiento de contrato.

Recomendación: **arrancar por 1 + 2a en paralelo**, que se pueden cerrar sin esperar a Producto ni a M05, y abrir las decisiones de §4 en paralelo para no bloquear la 2b.
