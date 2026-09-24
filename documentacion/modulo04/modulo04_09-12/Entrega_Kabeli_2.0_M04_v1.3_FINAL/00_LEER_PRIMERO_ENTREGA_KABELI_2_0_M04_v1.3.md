# Entrega Kabeli 2.0 · M04 · v1.3

Esta carpeta conserva el contrato informativo vigente de M04 v1.1 y agrega de forma incremental la formalización M05→M04. No reabre P4, C×K×D, Salud, Ruta ni sus lifecycles. El historial de reconciliación conservado en la carpeta padre sirve como antecedente, no como una segunda fuente de reglas.

## Orden de lectura
1. `Walvy_M04_Matriz_Trazabilidad_Cliente_v1.3.xlsx` — contrato implementable por Trace/Regla/P4 y superficie de validación con Kabeli.
2. `Walvy_M04_Documentacion_Funcional_Consolidada_v1.1.docx` — lectura humana integrada del módulo, fronteras, flujo, estados y guardrails.
3. `Walvy_M04_Anexo_BDD_Reglas_Productivas_v1.3.docx` + `Walvy_M04_Guia_Implementacion_Backend_Reglas_y_Calculos_v1.3.docx` — semántica productiva, datos, cálculos, precedencias, casos borde y fallbacks.
4. `Walvy_M04_Mis_Avisos_Parte_II_v1.1.docx` — familias F1–F7, lifecycle, prioridad local y frontera M03.
5. `Walvy_M04_Matriz_Validacion_Tecnica_v1.3.xlsx` — qué debe validar/demostrar la implementación; no equivale por sí sola a cumplimiento runtime.
6. `Walvy_M04_Clasificacion_y_Requisitos_Proteccion_Datos_para_Implementacion_v1.0.xlsx` + `Walvy_M04_Requerimientos_Evidencia_Tecnica_Kabeli_v1.0.xlsx` — protección de datos y evidencia técnica. Se mantienen en v1.0 porque las precisiones v1.1 no crean nuevas categorías de datos, owners ni tratamientos.
7. `HANDOFF_ACTUALIZACION_M04_KABELI_v1.1.docx` — resumen Human First de las precisiones incorporadas y de la única definición de Producto todavía pendiente en este frente.

## Jerarquía de interpretación
- La Matriz de Trazabilidad Cliente cerrada entre Walvy y Kabeli es la línea base contractual de implementación/QA.
- Consolidado, BDD y Guía Backend desarrollan esa semántica y resuelven detalle no visible en una matriz.
- Figma materializa recorrido, estados y experiencia; no crea por sí solo reglas Backend. Si Figma y contrato difieren, el punto debe reconciliarse y no resolverse por inferencia.
- Discovery conserva intención y antecedentes, pero no desplaza una definición posterior cerrada/versionada.

## Precisiones incorporadas en v1.1
- **Captura manual:** al Guardar una deuda ingresada manualmente, el usuario confirma su existencia/pertenencia. La completitud se evalúa de manera independiente: puede quedar `confirmed + incomplete/pending`.
- **Deuda detectada/inferida/documental:** mantiene confirmación explícita en revisión antes de utilizarla como deuda propia en conclusiones fuertes.
- **Dato parcial de cuotas:** el dato conocido se conserva; `cuotas restantes` solo se deriva con insumos suficientes y consistentes. Missing no se convierte en cero ni autoriza descartar la fuente conocida.
- **F1 · Completar información:** se reutiliza cuando el faltante es material para el uso solicitado. No se crea una nueva familia de Mis Avisos.
- Ninguna de estas precisiones cambia el gate de Ruta, P4, Salud, ownership M06 ni la regla de cierre confirmado.

## Punto pendiente de Producto · catálogo visible de tipo de deuda
El mapping entre las opciones visibles que hoy consumen Front/Agente y la taxonomía canónica `debt_type/debt_subtype` sigue en precisión de Producto. Hasta su cierre versionado, **no agregar, retirar ni remapear opciones por inferencia**. Este pendiente condiciona solo ese catálogo visible; no reabre las demás reglas M04.

## Estado
- Cierre funcional/documental previo: preservado. El incremental v1.3 alcanzó `RELEASE_QA = PASS` tras QA Zero Trust/adversarial iterativo.
- Validación técnica runtime: no se certifica por este paquete; requiere evidencia de implementación.
- Compatibilidad nativa Office: no declarar `NATIVE_COMPAT_PASS` hasta abrir/cerrar los Office finales en Excel/Word sin mensajes de reparación o recuperación.


## Incremental v1.3 · cierre del productor upstream
- M04 sigue siendo consumidor: no calcula `headroom`, Reserva ni presupuesto.
- `D-M05-K-01` queda autocontenido en M05 y el contrato intermodular v1.1 explicita productor, anti-double-counting y fail-closed.
- `P4-CNT-022` conserva exactamente sus tres outcomes: positivo, 0 conocido/no recomendado y no evaluable.
- La fórmula legacy `max(piso, ingreso×5%)` continúa retirada y no tiene sustituto porcentual.
- Contrato intermodular vigente: `Walvy_Contrato_Intermodular_M05_M04_Outcome_Prudencial_P4_v1.1.docx`.

## Estado de esta liberación
- Contrato funcional/documental M05→M04: `RELEASE_QA = PASS`; promoción documental autorizada.
- El pendiente visible `debt_type/debt_subtype` se conserva: no fue cerrado ni alterado por este incremental.
- Runtime/evidencia de implementación: `NO EVALUADO`.
- Compatibilidad nativa Microsoft Excel/Word: `NO EVALUADA` en este entorno.
