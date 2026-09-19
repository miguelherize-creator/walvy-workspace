# G4 — Revisión y Suficiencia

> **Numeración canónica (esta carpeta):** G3 = análisis, G4 = suficiencia, G5 = diagnóstico. Los HTML de `requerimientos PM` traen G3/G4 invertidos; el código sigue esta carpeta.

**Pantallas UX:** C · Evidencia documental insuficiente (si aplica) + D · Revisión rápida del perfil inicial  
**Fuentes wiki:** `Walvy_Especificacion_UX_Onboarding_App.docx §4.3 y §4.4` · `Walvy_Onboarding_Diagnostico_Fase3_Reglas_Contextuales §8, §9, §10` · `Walvy_Onboarding_Diagnostico_Fase3_Anexo_BDD §6.3 y §6.4`  
**Fuentes PM:** `requerimientos PM/Walvy_Requerimiento_Desarrollo_G3_Revision_Suficiencia_v1.0.html` · `requerimientos PM/Requerimiento_Semaforo_Onboarding_Walvy_G2_G5_v1.0.html`

---

## Propósito

Evaluar si los indicadores extraídos en G3 son suficientes para habilitar un diagnóstico inicial confiable. Si la base es suficiente, avanza a diagnóstico. Si faltan datos críticos, bloquea y pide más evidencia. Si hay datos por confirmar no bloqueantes, puede habilitar un diagnóstico parcial con advertencia.

---

## Condiciones

| | Descripción |
|---|---|
| **Entrada** | G3 completó el procesamiento con al menos un documento |
| **Avance** | Suficiencia `base_suficiente` o `datos_por_confirmar` (parcial permitido) |
| **Bloqueo** | `datos_clave_insuficientes` · `sin_base` · `documento_no_procesable` |
| **Salida hacia** | G5 (diagnóstico inicial) si pasa el gate · G2 si necesita más documentos |

Si **no** pasa el gate, el usuario **no** entra a las 3 cards de Figma de G5 (En control / Atención / Riesgo). El PM G3 REQ-G3-008: insuficiencia no es riesgo. Si alguien igual evalúa el semáforo, el contrato G5 es `no_diagnosis` + CTA completar/cargar — ver `G5-diagnostico.md`.

---

## Evento que declara esta puerta

```
GET resumen combinado por importIds → evaluateSufficiencyGate
```
El backend calcula el estado de suficiencia a partir de los indicadores detectados.

---

## Los 5 indicadores funcionales

| # | `indicator_code` | Criticidad | Uso en diagnóstico |
|---|---|---|---|
| 1 | `ingreso_principal` | **Crítico** | Dimensiona la capacidad del mes y relaciona compromisos con ingreso |
| 2 | `compromisos_base` | **Crítico** | Estima obligaciones recurrentes y piso de gastos |
| 3 | `pagos_recurrentes` | **Crítico** | Detecta compromisos, suscripciones y presión del mes |
| 4 | `movimientos_recientes` | **Crítico** | Lee comportamiento del mes, fugas, regularidad y suficiencia |
| 5 | `instrumentos_pago` | Importante | Contextualiza origen de movimientos — no bloquea por sí solo |

---

## Estados posibles de cada indicador

| `indicator_detection_status` | Definición | Efecto |
|---|---|---|
| `detected` | Dato identificado con fuente suficiente y coherente | Puede alimentar diagnóstico y semáforo |
| `to_confirm` | Aparece pero requiere confirmación, categorización o corrección | Puede permitir diagnóstico parcial si no bloquea críticos |
| `not_detected` | No existe o no es utilizable | Bloquea si es indicador crítico |
| `outdated` | Existe pero no corresponde al período | Reduce confianza o exige corrección |
| `inferred` | Se deduce por patrón — sin confirmación | Debe comunicarse como aproximación |
| `manual_assisted` | Completado por categorización manual post carga documental | Complementa, no reemplaza fuente documental |

---

## Estados de suficiencia (`sufficiency_status`)

| Estado | Condición funcional | Diagnóstico permitido | CTA dominante |
|---|---|---|---|
| `base_suficiente` | Ingreso + movimientos detectados/confirmados; al menos compromisos o pagos detectados/confirmados; calidad global suficiente | **Sí — completo** | Comenzar diagnóstico |
| `datos_por_confirmar` | Base documental usable; ingreso + movimientos detectables/confirmables; ≤1 indicador crítico no detectado; faltantes no impiden leer el mes | **Sí — parcial** (con advertencia de precisión) | Completar información clave + secundario: Comenzar diagnóstico con esta base |
| `datos_clave_insuficientes` | Falta documento usable, ingreso, movimientos, o base mínima de compromisos/pagos; o calidad global insuficiente | **No** | Completar información clave |
| `sin_base` | Sin documentos cargados o usuario intenta evitar carga | **No** | Cargar documentos |
| `documento_no_procesable` | Archivo no permite extraer información relevante o no corresponde al período | **No** | Subir otro documento o revisar archivo |

---

## Pantalla C — Evidencia documental insuficiente

Aparece cuando ya existe alguna carga o intento válido, pero la suficiencia es `datos_clave_insuficientes`.

**Reglas:**
- No dar falsa sensación de cumplimiento
- Explicar que hubo avance, pero falta evidencia para una lectura confiable
- No ofrecer llenado manual de movimientos como sustituto
- Conectar el faltante con el beneficio visible: con más base documental, Walvy podrá detectar mejor recurrencias, mejorar categorización y dar una lectura más clara del mes

**Copy base sugerido:**  
> "Aún falta base para activar tu diagnóstico. Para mostrarte una lectura confiable del mes, necesitamos más movimientos cargados desde cartola o documento."

**CTAs:**
- Dominante: Cargar más movimientos o documento
- Secundario: Ahora no

---

## Pantalla D — Revisión rápida del perfil inicial

Aparece cuando la suficiencia es `base_suficiente` o `datos_por_confirmar`.

**Mínimo que debe mostrar:**
- Ingreso base detectado
- Compromisos base detectados
- Movimientos sin categorizar (como contador, no como lista)
- Señales de recurrencia relevantes
- Deuda activa relevante (si fue detectada o declarada en otros módulos)

**Reglas:**
- Es una confirmación mínima, no un análisis profundo
- Movimientos sin categorizar: mostrar como contador con salida directa a revisión
- Si la información proviene de documentos o cartolas, destacarla como base preferente
- No transformarla en formulario ni en pantalla de análisis

**CTA dominante:** Confirmar y ver mi diagnóstico

---

## Reglas de diagnóstico parcial

| Caso | Tratamiento | Estado de regla |
|---|---|---|
| Todos los indicadores críticos detectados | Diagnóstico completo | MVP |
| Mínimo funcional para parcial: doc usable + ingreso + movimientos + al menos compromisos o pagos | Permitir "Comenzar diagnóstico con esta base" | MVP |
| Indicadores críticos detectados pero datos por confirmar de baja incidencia | Diagnóstico parcial con advertencia de precisión | MVP condicionado |
| `instrumentos_pago` no detectado | No bloquea por sí solo | MVP |
| Un indicador crítico bloqueante no detectado | Bloquear diagnóstico | MVP |
| Base documental insuficiente o no procesable | Bloquear; pedir nueva carga | MVP |
| Dato manual/asistido completa faltante crítico | Puede complementar puntualmente — no reemplaza fuente documental | Requiere Anexo BDD |
| Varios indicadores críticos no detectados | Bloquear diagnóstico | MVP |
| Dato por confirmar es crítico para interpretar el mes | Bloquear diagnóstico parcial hasta confirmar | MVP condicionado |

---

## Entidad de datos: `diagnostic_evaluation` (parte relevante para G4)

| Campo | Tipo | Uso |
|---|---|---|
| `sufficiency_status` | enum | Controla avance, bloqueo o diagnóstico parcial |
| `diagnostic_mode` | enum | `complete / partial / blocked / not_available` |
| `partial_diagnostic_allowed` | boolean | Habilita "Comenzar diagnóstico con esta base" |
| `diagnostic_blocking_reason` | enum | `sin_documento / documento_no_procesable / ingreso_faltante / movimientos_faltantes / pagos_compromisos_insuficientes / confianza_insuficiente` |
| `diagnostic_warning_reason` | enum | `datos_por_confirmar / dato_inferido / dato_manual_asistido / dato_desactualizado` |

---

## Confianza del dato (`confidence_level`)

| Nivel | Uso |
|---|---|
| `high` | Fuente documental, dato confirmado, sin ambigüedad |
| `medium` | Inferido o por confirmar con base razonable |
| `low` | Manual/asistido o con baja evidencia |
| `insufficient` | No puede usarse para diagnóstico confiable |

---

## Postergación

**¿Puede pausarse?** Sí.

| Situación | Al retomar |
|---|---|
| `base_suficiente` o datos por confirmar | Puede ir directamente a diagnóstico al retomar |
| Revisión sin validación obligatoria pendiente | Ir directo al diagnóstico |
| `datos_clave_insuficientes` | Retomar desde pantalla C o G2 según el faltante |

---

## Guardrails

- La suficiencia se evalúa siempre desde datos documentales — no desde dato manual como fuente primaria
- El diagnóstico parcial no es una vía para mostrar certezas con datos débiles
- Si la calidad global del dato es `insufficient`, bloquear aunque existan indicadores detectados
- No listar movimientos sin categorizar uno a uno en esta vista
- Los instrumentos de pago nunca bloquean el diagnóstico — solo suman advertencia
