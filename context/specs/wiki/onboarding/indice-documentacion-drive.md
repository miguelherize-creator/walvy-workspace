# Índice de documentación de onboarding — Drive

Fuente: carpeta Drive descargada el 2026-08-22.
Drive URL: https://drive.google.com/drive/folders/1ryc04VOCJTKXdkYeI5-oGXpVhWtTf-e8

---

## Carpetas en el Drive

### `Modulo 1 y 2`
Carpeta principal con la documentación más actualizada de M1 y M2.

| Archivo | Tipo | Qué contiene |
|---|---|---|
| `Leeme M1.docx` | Readme | Puntero a los dos docs de reglas de diagnóstico |
| `Leeme Foco del Mes M2.docx` | Readme | Resumen del doc de Foco del Mes |
| `Walvy_Especificacion_UX_Onboarding_App.docx` | **Spec UX** | Flujo completo de onboarding: 6 pantallas, reglas de despliegue, política de pausa, guardrails, UX writing |
| `Walvy_Onboarding_Diagnostico_Fase3_Reglas_Contextuales_Suficiencia_Semaforo_CTA_v1_0.docx` | **Reglas funcionales** | Suficiencia documental, puertas G0–G6, semáforo, presión principal, CTA por estado |
| `Walvy_Onboarding_Diagnostico_Fase3_Anexo_BDD_Reglas_Productivas_v1_0.docx` | **Modelo de datos** | Entidades, campos, enums candidatos, guardrails productivos |
| `Walvy_Regla_Priorizacion_CTA_por_Foco_Mes_v1_0.docx` | **Regla de negocio M2** | Foco del Mes: 6 focos, jerarquía crítica > foco > sugerido, matriz foco-indicadores-CTA |
| `Walvy_Modulo2_Configurar_Mis_Avisos_Parte_I_Definicion_Funcional_v1.0.docx` | Spec M2 | Preferencias de notificaciones: canales, recordatorios, cadencia de exposición |
| `Walvy_Onboarding_Deudas_v1.0.pdf` | **Spec subflujo** | Subflujo de deudas dentro del onboarding (pendiente leer — necesita pandoc) |
| `Walvy_Ruta_Despeje_v1.0.pdf` | Spec M4 | Ruta Despeje completa (pendiente leer) |
| `Walvy_Reglas_Salud_Deuda_v1.0.pdf` | Reglas M4 | Reglas de salud de deuda S0–S4 (pendiente leer) |
| `Walvy_Especificacion_UX_Perfil_Financiero_v1.0_consolidado.pdf` | Spec UX | Perfil Financiero consolidado (pendiente leer) |
| `Walvy_Rector_Producto_y_Funcionalidades_MVP_v1.0_OLD_20260516.pdf` | Old rector | Versión OLD del rector de producto — referencia histórica |

### `1. Entregables Walvy_Módulo 1`
Entregables formales del módulo 1 para el cliente.

| Archivo | Tipo | Qué contiene |
|---|---|---|
| `Documentación_Entrega_Módulo1.pdf` | Entregable cliente | Doc de entrega formal M1 |
| `Walvy_M1_Matriz_Trazabilidad_Cliente_v2.6.xlsx` | **Matriz** | Trazabilidad cliente v2.6 — fuente de IDs para assessment y reportes |
| `Walvy_M1_Matriz_Variantes_Validacion_Cliente_v1.0.xlsm` | Matriz | Variantes de validación M1 |
| `Walvy_M2_Matriz_Variantes_Validacion_Cliente_v1.0.xlsx` | Matriz | Variantes de validación M2 |

---

## Glosario de conceptos clave

### Flujo de onboarding (6 estados)

| ID | Pantalla | CTA dominante | Bloqueable |
|---|---|---|---|
| A | Bienvenida | Comenzar | No |
| B | Carga documental preferente | Cargar cartola o documento | Sí (con cuidado) |
| C | Evidencia documental insuficiente | Cargar más movimientos o documento | Sí |
| D | Revisión rápida del perfil inicial | Confirmar y ver mi diagnóstico | Sí |
| E | Diagnóstico inicial | Ver mi próxima acción | No aplica (cierre) |
| F | Reactivación (banner/modal) | CTA específico al paso pendiente | — |

### Estados de suficiencia

| Estado | Diagnóstico permitido | CTA |
|---|---|---|
| `base_suficiente` | Sí, completo | Comenzar diagnóstico |
| `datos_por_confirmar` | Sí, parcial (con advertencia) | Completar + opción "Comenzar con esta base" |
| `datos_clave_insuficientes` | No | Completar información clave |
| `sin_base` | No | Cargar documentos |
| `documento_no_procesable` | No | Subir otro documento |

### Semáforo general del diagnóstico

| Estado | Lectura |
|---|---|
| `in_control` | Favorable, sin presión crítica |
| `attention` | Datos por confirmar, fugas, margen ajustado |
| `risk` | Presión principal con evidencia suficiente |
| `no_diagnosis` | Sin base suficiente — no mostrar rojo por falta de datos |

### Puertas funcionales (G0–G6)

| Puerta | Nombre | Bloqueo |
|---|---|---|
| G0 | Activación | Salida sin foco |
| G1 | Foco del mes | Sin bloqueo fuerte |
| G2 | Carga documental | Sin documento o no procesable |
| G3 | Revisión y suficiencia | Datos clave insuficientes |
| G4 | Análisis | Demora o error de procesamiento |
| G5 | Diagnóstico inicial | Falta regla o datos insuficientes |
| G6 | Retoma | No hay avance guardado |

### Jerarquía del Foco del Mes (M2)

```
Señales críticas > Foco declarado > Foco sugerido por Walvy
```

**Señales críticas** (prevalecen siempre): deuda presionada, mora, vencimiento crítico, disponible negativo, compromiso base en riesgo, dato faltante bloqueante.

**6 focos del catálogo**: Bajar deuda · Ordenar compromisos · Ahorrar un monto · Aumentar margen · Evitar atrasos · Cumplir presupuesto.

### Campos de datos críticos (Anexo BDD)

| Campo | Entidad | Para qué |
|---|---|---|
| `sufficiency_status` | `diagnostic_evaluation` | Controla avance o bloqueo |
| `diagnostic_mode` | `diagnostic_evaluation` | `complete / partial / blocked / not_available` |
| `confidence_level` | `extracted_indicator` | `high / medium / low / insufficient` |
| `data_origin` | `extracted_indicator` | `documental / inferred / manual / assisted / user_confirmed` |
| `dominant_pressure_code` | `diagnostic_evaluation` | Único por evaluación — ordena mensaje y CTA |
| `diagnosis_basis_note_variant` | `diagnostic_evaluation` | Controla nota "Sobre tu diagnóstico" (evita falsa certeza) |
| `onboarding_resume_state` | `onboarding_session` | Punto de retoma sin reinicio |
| `rule_version` + `evaluated_at` | `onboarding_session` | Obligatorios para recálculo y auditoría |
| `mvp_scope_status` | varios | Clasifica si algo es MVP o backlog |

### Guardrails transversales

- El diagnóstico **no se habilita solo con datos manuales** — requiere base documental
- El semáforo **no copia S0–S4 de deuda** — escala propia
- `dominant_pressure_code` es **único** por evaluación (sin CTAs compitiendo)
- El onboarding puede pausarse pero **conserva avance** — retoma desde el punto de mayor valor, nunca desde cero
- Dato manual/asistido **complementa** después de carga documental; no la reemplaza

---

## PDFs pendientes de leer

Requieren `brew install pandoc` para extraer texto:

```
Modulo 1 y 2/Walvy_Onboarding_Deudas_v1.0.pdf
Modulo 1 y 2/Walvy_Ruta_Despeje_v1.0.pdf
Modulo 1 y 2/Walvy_Reglas_Salud_Deuda_v1.0.pdf
Modulo 1 y 2/Walvy_Especificacion_UX_Perfil_Financiero_v1.0_consolidado.pdf
1. Entregables Walvy_Módulo 1/Documentación_Entrega_Módulo1.pdf
```
