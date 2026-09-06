# G5 — Diagnóstico Inicial

**Pantallas UX:** E · Diagnóstico inicial + F · Próxima acción dominante (opcional como pantalla separada)  
**Fuentes wiki:** `Walvy_Especificacion_UX_Onboarding_App.docx §4.5 y §4.6` · `Walvy_Onboarding_Diagnostico_Fase3_Reglas_Contextuales §12, §13, §14` · `Walvy_Onboarding_Diagnostico_Fase3_Anexo_BDD §6.4` · `Walvy_Reglas_Salud_Deuda_v1.0`  
**Fuentes PM (2026-08):** `requerimientos PM/Requerimiento_Semaforo_Onboarding_G5.html` · `requerimientos PM/Requerimiento_Semaforo_Onboarding_Walvy_G2_G5_v1.0.html`

---

## Propósito

Entregar al usuario la primera lectura útil de su mes: diagnóstico sintético, semáforo, presión principal que lo explica, y una próxima acción concreta y dominante. Es el cierre del onboarding. El flujo no termina en "perfil completado" — termina cuando el usuario ve su primer diagnóstico y entiende qué le conviene hacer ahora.

---

## Condiciones

| | Descripción |
|---|---|
| **Entrada** | G4 habilitó el diagnóstico (`complete` o `partial permitido`) |
| **Avance** | Semáforo, presión principal y CTA definidos |
| **Bloqueo** | Falta de regla o datos insuficientes al momento de calcular |
| **Salida hacia** | Home / Perfil Financiero (el onboarding se considera cumplido al ver el diagnóstico) |

---

## Evento que cierra el onboarding

El sistema debe declarar `G5_diagnostico` cuando el usuario llega a esta pantalla. También deben setearse:
- `financial_profile_completed: true`
- `min_doc_threshold_met: true`

> Sin este cierre, el onboarding queda abierto indefinidamente.

---

## Outputs visibles obligatorios

| Output | Descripción |
|---|---|
| **Semáforo del mes** | Estado general de salud financiera del mes |
| **Prioridad principal** | Qué está empujando el mes (la presión dominante) |
| **Pago relevante próximo o presión del mes** | Factor más claro que hoy empuja el mes: deuda, pago próximo, categoría fuera de rango, fuga activa |
| **Fuga o desvío detectable** | Cuando exista evidencia |
| **Próxima acción dominante** | Una sola acción concreta — puede ser bloque dentro de esta misma pantalla o pantalla F separada |

La lectura debe ser **breve, humana y accionable**. No necesita score numérico.

---

## Semáforo general (`general_traffic_light_status`)

**No copia S0-S4 de deuda.** Es una escala propia del diagnóstico general del mes.

| Estado | Lectura funcional | Condiciones cualitativas |
|---|---|---|
| `in_control` | Lectura favorable, sin presión principal crítica | Indicadores críticos detectados/confirmados; calidad suficiente; compromisos/pagos interpretables; sin señal dominante de riesgo |
| `attention` | Lectura usable, pero conviene revisar | Base usable con datos por confirmar no bloqueantes; movimientos pendientes; fugas detectadas; pagos recurrentes relevantes; margen ajustado sin evidencia crítica |
| `risk` | Presión principal relevante con evidencia suficiente | Base usable + señales fuertes de sobrecarga, compromisos que presionan, gastos que comprometen estabilidad |
| `no_diagnosis` | No existe base suficiente para semáforo confiable | Falta documento usable, ingreso, movimientos o base mínima — **nunca mostrar rojo por falta de información** |

### Figma vs contrato: 3 cards, 4 estados

Figma de “Tu primera lectura está lista” dibuja **solo tres layouts** (En control / Atención / Riesgo) con los tres puntos del semáforo. Eso **no contradice** `no_diagnosis`.

| Capa | Qué hay | Fuente |
|---|---|---|
| Contrato / API | 4 valores: `in_control` · `attention` · `risk` · `no_diagnosis`. Nunca `null` ni `verified` una vez evaluada G5 | PM G5 §1 y §8 · PM G2–G5 §3.3 · esta wiki |
| UI de semáforo (Figma E) | 3 cards de color. Entrada: umbral mínimo de carga ya cumplido (G4 pasó) | Figma · wiki **Entrada** abajo |
| UI de `no_diagnosis` | **No es una cuarta card con puntos.** Es “Sin diagnóstico” o el bloqueo de G4 (completar / cargar documento) | PM G5 §7 · PM G2–G5 §6 fila gris · RF-FE-07 · CTA de esta wiki |

Regla de render (PM G2–G5 §7 y RF-FE-04/05/07):

1. Si G4 **no** habilitó diagnóstico (`blocked` / `not_available` / datos clave insuficientes / sin base / no procesable) → el usuario **no** ve las 3 cards. Ve bloqueo o “Sin diagnóstico”. CTA: completar información o cargar documento usable.
2. Si G4 **sí** habilitó y el motor elige verde / amarillo / rojo → las 3 cards de Figma. El front **no reinterpreta** finanzas (CA11 del PM G5).
3. Si G5 ya se evaluó y el motor **no puede** elegir color → API `no_diagnosis`, no `null`, no `risk`. Front: no inventar un color de las 3 cards.

El PM G2–G5 llama al estado visual de `no_diagnosis` **“SIN DIAGNÓSTICO”** (pill gris). Eso es representación del estado, no un cuarto semáforo de tres luces.

### Quién debe impedir llegar a las 3 cards

La **entrada a G5** de esta wiki: G4 habilitó diagnóstico (`complete` o `partial` permitido). El PM G3 de suficiencia (en Drive/PM el gate de revisión; en esta carpeta está documentado como G4) dice lo mismo: insuficiencia **no es riesgo**; no hay “Comenzar diagnóstico” si falta crítico.

Si el endpoint de summary igual corre (el batch de G5 calcula siempre), el resultado funcional es `no_diagnosis` + `diagnostic_blocking_reason`. Eso no autoriza a pintar En control / Atención / Riesgo.

### Período del snapshot G5 (propuesta PM, pendiente cliente)

La tabla de `no_diagnosis` sigue siendo de **suficiencia**. V56 se resuelve en G4.

El hueco de “cómo se arma el mes” quedó **cerrado funcionalmente por PM** (2026-08-24) en cuatro RN propuestas. **No son RN vigente de M1** hasta que el cliente las apruebe. Texto: `bitacora/2026-08-24-periodo-snapshot-g5.md`.

| ID | Cierre |
|---|---|
| **RN-G5-PER-001** | Ventana = `summary.period` de Kread. No min/max `occurredOn`. No obligatorio 1–último día calendario. |
| **RN-G5-PER-002** | Las txs (`occurredOn` dentro de la ventana) llenan montos; no redefinen bordes. Faltar txs un día ≠ falta de cobertura. |
| **RN-G5-PER-003** | Ingreso **usable y atribuible** al período — no se exige tx de ingreso exactamente dentro de `start`–`end`. Si no hay ingreso atribuible → G4 `ingreso_faltante`. |
| **RN-G5-PER-004** | Ventana = documento usable con `end_date` más reciente; los demás aportan evidencia atribuible a esa ventana. Conflictos → confianza/suficiencia, no recortar bordes. |

Orden: resolver `summary.period` **antes** de cerrar G4, para que G4 y G5 usen la misma referencia. Motor actual (criterio técnico): mes de `occurredOn` más reciente; aún no consume `summary.period` en G5.

---

## Señales del mes (3 signals)

| `signal_code` | Estados posibles (`signal_state`) |
|---|---|
| `margin` | `healthy` · `observation` · `adjusted` · `pressured` |
| `commitments` | `under_control` · `observation` · `high` |
| `movements` | `no_relevant_alerts` · `pending_review` · `leaks_detected` · `needs_attention` |

API actual: `diagnosis.signals[]` con `type` + `state` (no campos sueltos `margin_signal_state`). El catálogo de 11 estados **ya es el modelo funcional**. Lo pendiente no es si existen, sino **qué disparador los emite**. Detalle de alcance: [Alcance implementado vs soporte parcial](#alcance-implementado-vs-soporte-parcial-2026-08-24). Texto de trabajo: `bitacora/2026-08-24-g5-senales-alcance-parcial.md`.

---

## Presión principal (`dominant_pressure_code`)

Una sola presión por evaluación. Determina el mensaje y el CTA dominante.

| Nivel | Código | Condición | CTA esperado |
|---|---|---|---|
| Previo P0 | `data_to_confirm` (bloqueante) | Falta base documental, ingreso, movimientos o base mínima | Bloquea diagnóstico → Completar información clave |
| Previo P1 | `data_to_confirm` (crítico) | Dato que puede cambiar la lectura central | Completar o confirmar antes del diagnóstico |
| D1 | `overload` / `margin_compromised` | Compromisos/pagos/margen presionan la lectura | CTA de atención prioritaria |
| D2 | `recurring_payments` / `high_commitments` | Pagos repetidos o compromisos explican por qué el mes se siente ajustado | Revisar compromisos o pagos recurrentes |
| D3 | `pending_movements` | Movimientos sin clasificar que pueden cambiar la conclusión | Revisar movimientos o completar clasificación |
| D4 | `leaks_detected` | Fugas o pagos recurrentes optimizables | CTA de optimización o revisión |
| D5 | `data_to_confirm` (no bloqueante) | Lectura usable, puede mejorar con confirmación | Completar información clave o mejorar precisión |
| D6 | `optimization` | Estado favorable con oportunidad de ordenar | CTA de optimización saludable |
| D7 | `monthly_focus` | Sin presión dominante + objetivo declarado | Personaliza CTA hacia el foco declarado |
| D8 | `no_pressure` | Base suficiente sin señal clara dominante | Avanzar a Perfil Financiero |

---

## Nota sobre el diagnóstico (`diagnosis_basis_note_variant`)

Controla el mensaje "Sobre tu diagnóstico" — evita falsa certeza.

| Variante | Cuándo usar |
|---|---|
| `full_basis` | Diagnóstico completo con base documental suficiente |
| `partial_basis` | Diagnóstico parcial — existen datos por confirmar |
| `inferred_or_manual_basis` | Diagnóstico basado en datos inferidos o manual/asistido |
| `insufficient_basis` | No se puede mostrar diagnóstico confiable |

---

## Variantes de diagnóstico (`diagnosis_variant`)

| Variante | Contexto |
|---|---|
| `in_control` | Semáforo verde, sin presión dominante |
| `attention_pending_movements` | Atención por movimientos pendientes de clasificar |
| `attention_leaks_detected` | Atención por fugas detectadas |
| `attention_data_to_confirm` | Atención por datos por confirmar |
| `attention_adjusted_margin` | Atención por margen ajustado |
| `risk_overload` | Riesgo por sobrecarga del mes |
| `risk_high_commitments` | Riesgo por compromisos altos |
| `no_diagnosis` | Sin base suficiente para diagnóstico |

---

## CTAs por estado del diagnóstico

| Estado | CTA dominante | CTA secundario permitido |
|---|---|---|
| `in_control` | Optimizar pagos recurrentes o Ver mi Perfil Financiero | — |
| `attention` (cualquier variante) | Completar información / Revisar señal principal / Ver Perfil Financiero con advertencia | — |
| `risk` (cualquier variante) | Atender riesgo principal / Revisar acción sugerida | — |
| `no_diagnosis` | Completar información clave / Cargar documento usable | — |

**CTA dominante de cierre:** Ver mi próxima acción  
**CTA secundario opcional:** Ir a mi resumen

---

## Pantalla F — Próxima acción dominante

No es obligatoria como pantalla separada. La resolución preferente es como **bloque final dentro del diagnóstico**.

Solo conviene como pantalla separada cuando:
- La acción requiere explicación adicional que no quepa dentro del diagnóstico
- Separarlo mejora claramente la comprensión del cierre

**Acciones autorizadas como próxima acción dominante:**
- Revisar un pago relevante
- Confirmar una recurrencia detectada
- Corregir una fuga

> Categorizar movimientos pendientes: solo si el volumen es acotado y su impacto es crítico para la lectura del diagnóstico. No cerrar el onboarding con una tarea larga o pesada.

---

## Relación con Salud de Deuda en el diagnóstico

Cuando el foco declarado en G1 fue `bajar_deuda` o cuando el onboarding de deudas fue activado:

- Si existe Módulo 4 o deuda cargada, su resultado puede alimentar el semáforo general como señal — no lo gobierna por completo
- `general_traffic_light_status` **no copia** S0-S4 de Salud de Deuda
- Si la deuda es la presión dominante (`dominant_pressure_code`: `overload` o `recurring_payments` asociado a deuda), el semáforo puede ser `risk` o `attention` con CTA hacia Ruta Despeje
- Si no se ha cargado información de deuda, la Salud de Deuda aparece como `sin_datos_suficientes` — no como favorable

---

## Entidad de datos: `diagnostic_evaluation` (campos clave G5)

| Campo | Uso |
|---|---|
| `general_traffic_light_status` | Semáforo del mes |
| `diagnosis_variant` | Variante de la pantalla |
| `dominant_pressure_code` | Único por evaluación — determina mensaje y CTA |
| `diagnosis_basis_note_variant` | Controla nota de confianza |
| `suggested_action.suggested_action_type` | Tipo de acción sugerida |
| `suggested_action.dominant_cta_code` | CTA dominante: `cargar / completar / comenzar / revisar / esperar / ver_perfil` |
| `rule_version` + `evaluated_at` | Obligatorios para recálculo y auditoría |
| `mvp_scope_status` | Clasifica si la señal usada es MVP o backlog |

---

## Postergación

**No aplica como pausa del onboarding.**

Cuando el usuario ya ve el diagnóstico, **el onboarding se considera cumplido**. No tiene sentido mostrar "Ahora no" como CTA del flujo en esta pantalla. Las salidas son:
- Ver mi próxima acción → pantalla F o acción inline
- Ir a mi resumen → Perfil Financiero / Home

---

## Alcance implementado vs soporte parcial (2026-08-24)

Motor `g5_signals_v1` (PR [back-walvy#133](https://github.com/KabeliDev/back-walvy/pull/133)). Fase 3 es cualitativa: no se inventan umbrales. **No emitir un estado ≠ el estado no existe.** Clasificar con `mvp_scope_status`: `supported` / `partially_supported` / `pending_mvp_validation`. No hardcodear disparadores abiertos; no sacar enums del contrato.

### Cumple (supported)

| Pieza | Qué hay |
|---|---|
| Catálogo visible | 3 señales, 11 estados, una `dominant_pressure_code`, un CTA |
| Semáforo | `in_control` · `attention` · `risk` · `no_diagnosis`. Nunca `null`. Falta de datos ≠ Riesgo |
| Margen `healthy` / `adjusted` / `pressured` | M1-DP-006: ratio &lt; 0.90 / [0.90, 1) / ≥ 1.00 |
| Compromisos `under_control` | Default si no hay mora confirmada |
| Compromisos `high` (parcial: ver abajo) | Mora confirmada (deuda confirmada, vencida, con saldo) → Riesgo |
| Movimientos `no_relevant_alerts` / `pending_review` | Default / no categorizados. `pending_review` **no** es sinónimo de `needs_attention` |

### Soporte parcial — disparadores abiertos (no son “estados indefinidos”)

| Estado | Significado documentado | Hoy | `mvp_scope_status` | Cierre que falta (Producto) |
|---|---|---|---|---|
| Margen `observation` | Seguimiento, sin presión crítica | No se emite | `partially_supported` | Evidencia que lo diferencia de `healthy` (con `adjusted` ya en 0.90). ¿Cambia el semáforo o solo la señal? **No** preguntar si el estado existe. **No** sacarlo del contrato. |
| Compromisos `observation` | Compromisos o pagos recurrentes requieren revisión | No se emite. Sin mora = siempre `under_control` (demasiado binario) | `partially_supported` | Evidencia concreta. Fase 3: recurrencias relevantes pueden explicar Atención. |
| Compromisos `high` | Presionan el mes o explican Riesgo. **Documentalmente no es solo mora.** No copiar M04 entero a G5 | Solo mora (recorte técnico) | `partially_supported` | Lista cerrada de señales G5 **adicionales** que activan `high`. ¿Alguna basta sola para Riesgo? |
| Movimientos `leaks_detected` | Atención / `attention_leaks_detected` / SEM-03. Falta de job ≠ RN fuera de v1 | No se emite (no hay detector) | `pending_mvp_validation` | ¿Operativo en M1 v1 o `partially_supported` formal? Si v1: qué es fuga y quién la calcula. |
| Movimientos `needs_attention` | Distinto de `pending_review` | No se emite | `partially_supported` | Disparador concreto. No unificar con no-categorizados. |

### Preguntas a Producto (operacionalizar, no reabrir el catálogo)

1. Margen `observation`: ¿qué evidencia vs `healthy`? ¿mueve el semáforo?
2. Compromisos `observation`: ¿qué evidencia? ¿Atención o solo la señal?
3. Compromisos `high`: mora **no** es la única condición. ¿Qué señales G5 extra lo activan?
4. `leaks_detected`: ¿M1 v1 operativo o `partially_supported` / `pending_mvp_validation`?
5. `needs_attention`: ¿qué evidencia, distinta de `pending_review`?

Al cerrar disparadores de señal, versionar `g5_signals_v1` → `g5_signals_v2`.

### Escenario `attention_adjusted_margin` (ratio [0.90, 1), sin mora ni pendientes)

G5 **sí** determina Atención y señal dominant Margen `adjusted` (SEM-05). Lo parcialmente soportado es la **traducción** de esa señal a presión, acción, copy y navegación: el catálogo vigente no contempla explícitamente este escenario en esas cuatro capas.

El mapeo que emite `g5_signals_v1` **no es RN aprobada**. Es **fallback técnico** para no dejar vacíos `dominant_pressure_code` y el CTA (el contrato pide uno de cada). No usar `recurring_payments` como causa: el motor no detectó recurrencias que expliquen el ajuste. No usar `margin_compromised`: mezcla `adjusted` con presión más fuerte.

| Componente G5 | Estado |
|---|---|
| `general_traffic_light_status = attention` | Cerrado |
| `margin = adjusted` | Cerrado |
| `commitments = under_control` | Cerrado para este escenario |
| `movements = no_relevant_alerts` | Cerrado |
| `dominant_pressure_code` | Pendiente Producto. Fallback técnico hoy: `recurring_payments` — **no RN** |
| `dominant_cta.type` | Pendiente Producto. Fallback técnico hoy: `adjust_budget` (CHECK legado, fuera de catálogo PM) — **no RN** |
| Copy del bloque | Pendiente Producto/UX. Borrador front (menciona recurrentes) — **no RN** |
| Destino del CTA | Pendiente Producto. Hoy no hay pantalla “revisar margen” |
| Perfil como acción secundaria | Ya respaldado (M1-RN-ONB-012 / BDD), salvo que Producto lo pase a dominante |

**Consulta a Producto (cuatro cierres; no reabrir semáforo ni las 3 señales):**

1. **Presión** — ¿qué código representa `attention_adjusted_margin` sin otra señal causal? ¿Código nuevo (p. ej. `adjusted_margin`), reutilizar uno del catálogo, o `no_pressure`?
2. **Acción** — ¿cómo se materializa `revisar_senal_principal` si la señal es Margen y no existe `review_margin`? ¿Acción nueva, mapear a una existente (no `optimize_recurring_payments`), o Perfil en v1?
3. **Copy** — texto que hable **solo de margen**, sin atribuir pagos recurrentes no medidos. Botón + Perfil secundario.
4. **Destino** — ¿a qué pantalla lleva “revisar margen” en M1 v1? Perfil si M2 lo sostiene; CTA temporal a Perfil; u otra ruta.

Al responder: registrar RN/DP + casos QA y versionar `g5_signals_v1` → `g5_signals_v2`.

### Otros desvíos (no son el motor de las 3 filas)

| Tema | Hoy | Destino |
|---|---|---|
| Margen sin ingreso | Card `healthy` + `no_diagnosis` | No pintar “Saludable” si no hay lectura |
| Copy front | “Sin alertas” / “Pendientes de revisión” | “Sin alertas relevantes” / “Pendientes de revisar” |
| CTA API | CHECK legado (`adjust_budget`, …); `deepLink` suele `null` | Tipos de producto (`optimize_recurring_payments`, …) |
| `diagnosis_variant` | No viaja en el bloque | `attention_adjusted_margin`, etc. |
| Cierre onboarding | No setea `financial_profile_completed` | Wiki: G5 declara puerta + perfil completado |
| Ventana del mes | `occurredOn` más reciente | RN-G5-PER: `summary.period` (pendiente cliente) |
| Front 3 señales | Local, sin PR | Subir cuando el back esté en main |

---

## Guardrails

- No terminar el onboarding en "perfil completado" — termina en diagnóstico con próxima acción
- No mostrar `risk` (rojo) por falta de información — usar `no_diagnosis`
- No generar `dominant_pressure_code` vacío o múltiple — exactamente uno por evaluación
- No mezclar el semáforo general con S0-S4 de deuda
- La deuda puede alimentar el semáforo como señal solo cuando exista dato desde Perfil Financiero o Módulo 4
- `rule_version` y `evaluated_at` son obligatorios — sin ellos no es posible recalcular ni auditar
- No prometer ahorro garantizado ni resultados automáticos
- Un estado del catálogo que el motor aún no emite es `partially_supported` / `pending_mvp_validation`, no un estado indefinido ni un recorte del contrato (ver alcance 2026-08-24)
