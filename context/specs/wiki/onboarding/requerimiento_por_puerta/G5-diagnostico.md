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

### Hueco que Figma y el §7 no dibujan

La tabla de motivos de `no_diagnosis` (PM G5 §7 y esta wiki) es de **suficiencia**: sin documento, no procesable, ingreso, movimientos, compromisos/pagos, confianza.

Queda un caso de motor, no de Figma: **mes no cerrado / sin ingreso en la ventana** (M1-V56). El PM G5 §8 obliga igual a `no_diagnosis` en vez de `null`. Hasta que Diseño entregue frame, la UI segura es estado neutro **sin** los tres puntos de color — no la card Roja.

---

## Señales del mes (3 signals)

| `signal_code` | Estados posibles (`signal_state`) |
|---|---|
| `margin` | `healthy` · `observation` · `adjusted` · `pressured` |
| `commitments` | `under_control` · `observation` · `high` |
| `movements` | `no_relevant_alerts` · `pending_review` · `leaks_detected` · `needs_attention` |

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

## Guardrails

- No terminar el onboarding en "perfil completado" — termina en diagnóstico con próxima acción
- No mostrar `risk` (rojo) por falta de información — usar `no_diagnosis`
- No generar `dominant_pressure_code` vacío o múltiple — exactamente uno por evaluación
- No mezclar el semáforo general con S0-S4 de deuda
- La deuda puede alimentar el semáforo como señal solo cuando exista dato desde Perfil Financiero o Módulo 4
- `rule_version` y `evaluated_at` son obligatorios — sin ellos no es posible recalcular ni auditar
- No prometer ahorro garantizado ni resultados automáticos
