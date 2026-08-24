# G3 — Análisis (procesamiento background)

> **Numeración canónica (esta carpeta):** G3 = análisis, G4 = suficiencia. Los HTML de `requerimientos PM` traen G3/G4 invertidos; el código sigue esta carpeta.

**Pantalla UX:** Pantalla de procesamiento (sin pantalla propia de decisión — es un estado intermedio)  
**Fuentes wiki:** `Walvy_Especificacion_UX_Onboarding_App.docx §4.2 estados operativos` · `Walvy_Onboarding_Diagnostico_Fase3_Reglas_Contextuales §9 G4` · `Walvy_Onboarding_Diagnostico_Fase3_Anexo_BDD §6.2 document_processing_run`  
**Fuentes PM:** `requerimientos PM/Requerimiento_Desarrollo_Regla_Estados_G4_Analisis.html`

---

## Propósito

Ejecutar el análisis de los documentos cargados en G2 y construir los indicadores que alimentarán el gate de suficiencia de G4. Es un estado de procesamiento, no una pantalla de decisión del usuario. El usuario puede esperar, salir sin perder avance, o pedir que se le avise cuando termine.

---

## Condiciones

| | Descripción |
|---|---|
| **Entrada** | Usuario confirmó "Analizar mis documentos" en G2 |
| **Avance** | Procesamiento exitoso de al menos un documento con información extraíble |
| **Bloqueo** | Error de procesamiento en todos los documentos (sin documento resultante usable) |
| **Salida hacia** | G4 (revisión y suficiencia) |

---

## Evento que declara esta puerta

```
advanceOnboardingStep({ currentGate: 'G3_analisis' }) + importAttempted: true
```
Se declara al iniciar la cola de procesamiento.

---

## Proceso por documento (cola en serie)

Los documentos se procesan de a uno. Para cada documento:

1. **Upload** → archivo + password opcional (si es PDF protegido)
2. **Desbloqueo en memoria** → la contraseña no se persiste ni se loguea
3. **Hash sha256** del contenido ya desbloqueado → control de duplicados
4. **Dedup** (DynamoDB por `userId + fileHash`) → si ya fue procesado, reusar `importId`
5. **Upload a S3** (SSE-S3, sin acceso público, lifecycle 30 días)
6. **Kread** → clasifica banco y extrae datos
7. **Normalización** → líneas → `import_line_item`
8. **Polling de estado** → el frontend espera la respuesta

---

## Estados de procesamiento (`analysis_status`)

| Estado | Descripción | Acción UX |
|---|---|---|
| `queued` | En cola, esperando turno | Mostrar progreso |
| `in_progress` | Procesando activamente | Mostrar progreso |
| `delayed_soft` | Superó umbral suave (parámetro: ~45 s) | Mostrar demora sin alarmar; ofrecer salir o "Avisarme" |
| `delayed_long` | Superó umbral largo (parámetro: ~90 s) | Permitir salir; Walvy continúa en background |
| `completed` | Finalizado con éxito | Avanzar a G4 |
| `failed` | Error de procesamiento | Ver `failure_reason`; puede reintentar |

---

## Códigos de fallo del documento

| `failure_reason` / `validation_error_code` | Significado |
|---|---|
| `wrong_password` | Contraseña incorrecta → rebote a G2 para reingresar |
| `non_processable` | No se pudo leer de forma útil (formato, corrupción) |
| `outdated` | El documento no corresponde al período esperado |
| `transient` | Error temporal → puede reintentarse |

---

## Entidad de datos: `document_processing_run`

| Campo | Tipo | Uso |
|---|---|---|
| `processing_run_id` | uuid | Identificador de la ejecución |
| `analysis_status` | enum | Estado del procesamiento |
| `started_at / completed_at` | timestamp | Control de tiempo |
| `analysis_delay_soft_threshold_seconds` | int | Parámetro configurable — recomendado: 45 |
| `analysis_delay_long_threshold_seconds` | int | Parámetro configurable — recomendado: 90 |
| `processing_error_code` | enum | Motivo de falla si aplica |

> **Importante:** Los umbrales deben vivir en `rule_parameter` como parámetros versionados, no hardcodeados.

---

## Tipos de documento que el extractor soporta

| Tipo | Outputs disponibles |
|---|---|
| Cartola bancaria | `metadata` + `summary` + `transactions` |
| Estado de cuenta TCR | `transactions` + `debts` (1 deuda) |
| Informe CMF | `debts` (N deudas) |

> **Nota:** `document_type` y `debts` deben estar disponibles en el contrato de respuesta del backend para que sean procesables aguas abajo.

---

## CTAs durante G3

| Estado | CTA dominante | CTA secundario |
|---|---|---|
| Procesando (normal) | Continuar esperando | — |
| Demora leve (45 s) | Quiero esperar | Avisarme cuando esté listo · Continuar más tarde |
| Demora prolongada (90 s) | Avisarme cuando esté listo | Continuar más tarde |
| Error en un documento | (continúa con el siguiente) | — |
| Error en todos los documentos | Volver a cargar | Continuar más tarde |

---

## Postergación

**¿Puede pausarse?** Sí, sin perder avance.

- El backend continúa procesando aunque el usuario salga de la app
- Al volver, si el procesamiento terminó, se retoma desde G4 directamente
- Si no terminó, se retoma desde G3 con el estado actualizado
- El `resumeContext` debe contener el `jobId` del procesamiento en curso
- No se reinicia la cola desde cero al retomar

---

## Guardrails

- No reiniciar el flujo si el usuario sale durante el procesamiento
- No prometer tiempo exacto de procesamiento
- El procesamiento demorado no debe presentarse como error
- Si un documento falla con `wrong_password`, rebotar solo ese documento a G2 — no cancelar toda la cola
- No retener la contraseña en ningún log, param ni checkpoint
- Avisar cuando el análisis termine si el usuario pidió notificación
