# Entrega Kabeli 2.0 · M05 · v1.0

Esta carpeta es la superficie oficial de trabajo para la revisión de M05 con Kabeli. Los nombres de los documentos se mantienen en **v1.0** porque esta es la primera versión contractual de `Entrega Kabeli 2.0 - M05`.

## Orden de lectura
1. `Walvy_M5_Matriz_Trazabilidad_Cliente_v1.0_RESPUESTA_WALVY.xlsx` — respuesta funcional. Incluye **Reglas Walvy canónicas**, cruce de cada variante y de `Historias y CA` con esas reglas, y referencia directa al documento donde vive cada definición.
2. `Walvy_M5_Matriz_Validacion_Tecnica_v1.0_RESPUESTA_WALVY.xlsx` — alcance y controles técnicos. Incluye **TEC Walvy canónicos** y el mapeo semántico entre los controles recibidos de Kabeli y el catálogo Walvy.
3. `Walvy_M05_Anexo_BDD_Reglas_Productivas_v1.0.docx` + `Walvy_M05_Guia_Implementacion_Backend_Reglas_y_Calculos_v1.0.docx` — fuentes rectoras para contrato lógico-productivo, reglas, cálculos, precedencias, fallbacks y fixtures.
4. `Walvy_M05_Mis_Avisos_Parte_II_v1.0.docx` + `M05_M03_Matriz_Transversal_v1.0.csv` — familias F1–F6, acciones visibles, prioridad local y frontera M03.
5. `HANDOFF_UX_KABELI_M05_v1.0.docx` — materialización y remediación sobre Figma 5.2.
6. `Walvy_M05_Clasificacion_y_Requisitos_Proteccion_Datos_para_Implementacion_v1.0.xlsx` — clasificación, minimización y lifecycle de datos M05.
7. `Walvy_M05_Requerimientos_Evidencia_Tecnica_Kabeli_v1.0.xlsx` — **evidencia complementaria** de datos, privacidad y arquitectura lógica. No es una segunda matriz técnica: organiza qué evidencia debe devolver Kabeli para demostrar los TEC Walvy y quién la aporta.
8. `HANDOFF_RESPUESTA_MATRICES_M05_KABELI_v1.0.docx` — apoyo operativo para la respuesta a las matrices. **No sustituye** las fuentes rectoras anteriores; cuando una definición vive en Backend, BDD, Mis Avisos o PD, las matrices apuntan directamente allí.

## Cómo interpretar las capas de las matrices
- `Reglas de Negocio` conserva los R-xxx recibidos como capa de origen/referencia. `Reglas Walvy` es el catálogo canónico vigente.
- `Matriz Trazabilidad` y `Historias y CA` muestran explícitamente qué Regla(s) Walvy gobiernan cada fila y dónde leer la definición detallada.
- En la matriz técnica, `04 Nuevos Cambios` se conserva como registro del formato original para cambios futuros; **las Brechas Walvy permanecen en `05 Brechas Walvy`** y no se registran como “nuevo cambio”.
- `06 Mapeo TEC Kabeli-Walvy` es solo el puente entre IDs del borrador y el catálogo vigente; `07 TEC Walvy` contiene los 30 controles canónicos.
- La Matriz Técnica responde **qué debe validarse**. La matriz de Requerimientos de Evidencia responde **qué prueba debe devolver Kabeli para demostrarlo**. Una no sustituye a la otra.

## Reglas de interpretación
- Figma 5.2 gobierna el recorrido/materialización visual; no convierte notas de diseño en reglas Backend.
- Cuando Mis Avisos distingue `CTA visible` de `acción funcional`, solo el CTA visible se trata como copy de botón. La acción funcional explica lo que debe ocurrir dentro del flujo y no debe trasladarse literalmente a un componente si excede el patrón visual existente.
- Los AVI-M05 anteriores se conservan para trazabilidad. La operación vigente consume F1–F6 y la matriz transversal M05→M03 incluida en esta carpeta.
- M05 no habilita correo/push/cadencia por inferencia; M03/M02 conservan sus respectivos ownerships.
- No inventar reglas, thresholds, canales o estados que no estén definidos en estos documentos.

## Estado
Revisión funcional y documental: completada. Antes de utilizar esta carpeta como fuente final de implementación, confirmar que los archivos Office modificados en este incremental abren y cierran normalmente en Microsoft Excel/Word sin mensajes de reparación o recuperación.

## Figma 5.2 cerrado
- **Semántica canónica:** sin cambios. El Figma cerrado no crea ni modifica reglas BDD/Backend; las diferencias detectadas son de materialización, fixtures o evidencia de interacción.
- **Estado visual del Figma 5.2 cerrado:** `REMEDIATION_REQUIRED`. Este estado no bloquea la vigencia del contrato funcional, pero sí exige corregir la materialización antes de aprobar Figma.
- Fuente visual revisada: `M05 - figma - 5.2(4).zip`.
- Hallazgos visuales consolidados: no-presupuesto 0%, invariantes numéricos, D08 extrapolado, D07 duración/recuperación fija, D09 disponibilidad de horizontes, edición/naturaleza y rutas/post-state.
- La regla Backend/BDD no se ajusta para coincidir con un fixture visual.
- El Handoff UX es la lista operativa de remediación visual; las matrices conservan la trazabilidad de cobertura.
