# Walvy · M06 Pagos / Compromisos · Entrega funcional v1.0

**Candidato documental v1.0 · NO ENVIADO.**  
Esta carpeta contiene únicamente la proyección externa vigente para revisión. Los cortes internos de construcción y QA permanecen fuera del handoff y no alteran la versión formal v1.0.

## Qué leer primero

1. **Contrato funcional:** `01_CONTRATO_FUNCIONAL/Walvy_M06_Documentacion_Funcional_Consolidada_v1.0.docx`.
2. **Respuesta a las matrices originales de Kabeli:** los dos libros `...RESPUESTA_WALVY.xlsx` dentro de `02_IMPLEMENTACION/`.
3. **Ajustes Figma explicados Human First:** `02_IMPLEMENTACION/HANDOFF_UX_KABELI_M06_v1.0.docx` y `Walvy_M06_Matriz_Ajustes_Figma_v1.0.xlsx`.
4. **Mis Avisos M06:** `04_MIS_AVISOS/Walvy_M06_Mis_Avisos_Parte_II_v1.0.docx`.

Los archivos `M06_M03_M02_Matriz_Transversal_v1.0.csv` y `BDD_Interfaces_PD_M06_v1.0.xlsx` son **soporte técnico de implementación/QA**, no la ruta principal de lectura de Producto:

- **Matriz transversal M06↔M03↔M02:** aclara ownership, payloads, retornos y fronteras entre el módulo de pagos, la orquestación Home y la entrega/preferencias de avisos.
- **BDD / Interfaces / PD:** concentra escenarios ejecutables, contratos de interfaz, datos y controles que Backend/QA deben implementar o evidenciar. No redefine decisiones de Producto.

## Decisiones ya cerradas que no deben reabrirse

- **Recurrencia:** ancla conocida + día civil inexistente → último día válido preservando el ancla. Si el día/ancla no es suficientemente conocido → **no inferir fin de mes**; pedir `Confirmar/Completar fecha`. Una recurrencia probable requiere al menos dos ocurrencias económicas distintas compatibles.
- **Pago parcial:** manual y detectado/importado comparten el mismo lifecycle de dominio, incluidos múltiples abonos; cambia únicamente la procedencia.
- **`Activar alerta`:** retirado del MVP. `Recordarme este pago` queda diferido/backlog. Los avisos automáticos continúan bajo M02/M03.
- **Avisos y canales:** M06 produce la situación local; M03/Home arbitra la competencia transversal; M02 gobierna preferencias, frecuencia, deduplicación y canales. La notificación del teléfono es **canal externo**, sujeto además al permiso del sistema operativo.
- **Indicador mensual:** con 17 compromisos totales y 2 vencidos, el ejemplo coherente es 15/17 = **88% al día**. Sin denominador válido no se inventa 0% ni 100%.
- **Ruta Despeje:** M04 conserva ownership. `Vinculado a Ruta` solo corresponde con Ruta activa y relación confirmada; elegibilidad para entrar a Ruta no equivale a vínculo activo.

## Mis Avisos · por qué son 7 familias y no 17 AVI

M06 no usa “7” para imitar M04/M05. Se aplicó el criterio de autonomía: una familia activa debe tener **trigger distinguible, necesidad/acción propia y condición de resolución/lifecycle propia**, y no ser mejor representada como estado, severidad, reason, pending u output de otra familia.

El resultado vigente es **7 familias canónicas activas** y **17 AVI históricos de correspondencia**. Siete AVI sirven como referencia principal y diez quedan absorbidos/no autónomos. Los AVI permanecen para lineage y trazabilidad; no constituyen una segunda taxonomía operativa paralela.

## Matrices de Kabeli

Se preserva la capa original recibida y se responde en la capa Walvy:

- **59 variantes funcionales** respondidas: 46 `Aprobado`, 13 `Ajustar`.
- **23 controles técnicos** con dictamen de alcance: 13 `Aceptado`, 10 `Ajustar control`.

`Aceptado` / `Ajustar control` califican el **universo y definición del control**, no demuestran cumplimiento de implementación. Build, configuración, ambiente, esperado/observado y evidencia física siguen pendientes de devolución por Kabeli.

El pendiente histórico `PD-M6-03` se clasifica como **diferido/backlog no bloqueante**. Abarca más que `Activar alerta`: catálogo, anticipación, persistencia y configuración individual de recordatorios. Backend M06 no debe inferir esas capacidades en el MVP.

## Ajustes Figma

Se mantienen **15 ajustes de materialización**. El handoff separa en cada uno:

`dónde verlo → qué vemos hoy → por qué importa → qué debe cambiar → sustento/autoridad → cómo validar`.

Las imágenes sirven para ubicar la materialización actual. **No son autoridad para fórmulas o reglas de negocio**; cada ajuste cita el contrato, Discovery o decisión de Producto que corresponda.

## Estado y límites

- Decisiones A5 de Producto M06 abiertas: **0**.
- Backend puede elegir mecanismos técnicos equivalentes, pero **no inventar semántica de negocio**.
- 15 ajustes Figma: pendientes de materialización por Kabeli.
- Implementación/evidencia técnica: **NO EVALUADA**.
- Runtime Android/iOS: **NO EVALUADO**.
- Compatibilidad Microsoft Office nativa: debe acreditarse por apertura sin reparación antes del envío; este entorno no sustituye Microsoft Excel/Word nativo.
- Correo/envío externo: **NO AUTORIZADO / NO ENVIADO**.

## Devolución esperada de Kabeli

Para cada variante/control: referencia exacta, build/configuración/ambiente, fixture, pasos, resultado esperado, resultado observado y evidencia verificable. Para Figma: materializar los 15 ajustes y señalar dónde se aplicó cada uno.
