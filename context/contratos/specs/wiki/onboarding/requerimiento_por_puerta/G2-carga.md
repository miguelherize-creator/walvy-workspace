# G2 — Carga Documental

**Pantalla UX:** B · Carga documental preferente  
**Fuentes:** `Walvy_Especificacion_UX_Onboarding_App.docx §4.2` · `Walvy_Onboarding_Diagnostico_Fase3_Reglas_Contextuales §9 G2` · `Walvy_Onboarding_Diagnostico_Fase3_Anexo_BDD §6.2`

---

## Propósito

Capturar la evidencia documental que habilita el diagnóstico inicial. La ruta documental es **preferente** porque mejora precisión, categorización, recurrencia y lectura de variaciones. No existe ruta manual sustitutiva dentro del onboarding para cumplir este paso.

---

## Condiciones

| | Descripción |
|---|---|
| **Entrada** | Viene de G1 con foco guardado (`G2_carga` declarado) |
| **Avance** | Existe al menos un documento usable y el usuario inicia el análisis |
| **Bloqueo** | Sin documento · documento no procesable |
| **Salida hacia** | G3 (análisis background) cuando el usuario presiona "Analizar mis documentos" |

---

## Evento que declara esta puerta

```
advanceOnboardingStep({ currentGate: 'G2_carga', goalsSet: true })
```
Declarado al llegar desde G1. El flag `goalsSet: true` indica que el foco fue guardado antes de entrar.

---

## Tipos de documento soportados

| `document_type` | Descripción |
|---|---|
| `bank_statement` | Cartola bancaria |
| `card_statement` | Estado de cuenta TCR |
| `payroll` | Liquidación de sueldo |
| `account_movements` | Últimos movimientos |
| `other` | Otro documento financiero |
| `unknown` | No clasificado aún |

---

## Estados del documento (`document_upload_status`)

| Estado | Significado | Acción recomendada |
|---|---|---|
| `none` | Sin documento cargado | Cargar cartola o documento |
| `uploaded` | Subido, pendiente de procesamiento | — |
| `usable` | Procesado y con información útil | Avanzar |
| `non_processable` | No se pudo leer de forma útil | Subir otro documento / revisar archivo |
| `outdated` | Existe pero no corresponde al período esperado | Cargar documento más reciente |
| `duplicate` | Ya fue procesado antes (misma huella de contenido) | Reusar importId existente |
| `rejected` | Rechazado por validación | Revisar y volver a intentar |

---

## Estados operativos de la pantalla (8 estados que UX debe diseñar)

| Estado UX | Descripción |
|---|---|
| Listo para cargar | Zona de carga vacía, sin archivos seleccionados |
| Subiendo | Archivo en tránsito al servidor |
| Procesando | Servidor leyendo el documento |
| Procesamiento demorado (45 s) | Superó umbral suave — mostrar aviso sin alarmar, ofrecer salir sin perder avance o "Avisarme cuando esté listo" |
| Procesamiento demorado (90 s) | Superó umbral largo — permitir salir, Walvy continúa en background |
| Carga exitosa suficiente | El documento entrega señales suficientes para avanzar |
| Carga exitosa pero insuficiente | Hubo avance, pero la base no alcanza para diagnóstico — no tratar como error |
| Error / documento no usable | No se pudo leer — pedir otro documento o revisar archivo |

---

## CTAs por estado

| Estado | CTA dominante | CTA secundario |
|---|---|---|
| Sin archivo | Cargar cartola o documento | — |
| Archivo seleccionado | Procesar documento | — |
| Carga exitosa suficiente | Analizar mis documentos / Continuar | Agregar más documentos |
| Carga exitosa insuficiente | Cargar más movimientos o documento | Analizar con esta base |
| Procesamiento demorado | Quiero esperar | Avisarme cuando esté listo · Continuar más tarde |
| Error / no usable | Subir otro documento | Revisar archivo |
| Sin documento (bloqueo) | Cargar documentos | Continuar más tarde |

> **Regla:** "Continuar" solo conviene después de una carga exitosa. No debe ofrecerse como escape antes de esa condición.

---

## Reglas de carga

- **Máximo por lote:** definido en configuración (ver `rule_parameter`)
- **Formatos aceptados:** PDF, XLSX, CSV (al menos)
- **PDF protegido:** auto-unlock por RUT → si no abre, pedir contraseña manual
- **Dedup:** por huella del contenido (sha256 post-desbloqueo), por usuario. Si ya fue procesado, reusar el `importId` sin reprocesar
- **Contraseña:** nunca persiste en params, logs ni checkpoints — solo en memoria durante el proceso
- La carga manual de movimientos (ingreso manual uno a uno) **no forma parte de este flujo** y no debe ofrecerse como alternativa para desbloquear el onboarding

---

## Entidad de datos: `uploaded_document`

| Campo clave | Tipo | Uso |
|---|---|---|
| `document_id` | uuid | Identificador del documento |
| `document_upload_status` | enum | Estado del ciclo de vida |
| `document_type` | enum | Tipo de documento |
| `period_start / period_end` | date | Período detectado o declarado |
| `file_hash` | string | Control de duplicados (sha256) |
| `validation_error_code` | enum | Motivo de rechazo si aplica |

---

## Postergación

**¿Puede pausarse?** Sí, con cuidado.

| Situación | Qué pasa |
|---|---|
| No subió nada | Solo queda pendiente el paso; al retomar vuelve al inicio de G2 |
| Ya existe carga procesada útil | El sistema conserva el avance; al retomar puede ir directamente a G3, G4 o G5 según el avance real guardado |
| Intentando salir mientras sube un archivo | Pedir confirmación breve antes de salir |
| Procesamiento en curso al salir | Permitir salir sin perder avance; el backend continúa; avisar que podrá retomar desde el punto correspondiente |

---

## Guardrails

- No ofrecer ingesta manual de movimientos como sustituto de la carga documental
- No tratar una carga exitosa pero insuficiente como error — es avance, no fracaso
- No mostrar instrucciones largas, tecnicismos sobre formatos ni textos defensivos
- Si el procesamiento toma más de lo esperado: permitir salir sin perder avance — no reiniciar el flujo
- No consolidar deudas detectadas en documento sin revisión del usuario (ver subflujo Onboarding de Deudas)
