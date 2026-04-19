# Módulo 4 — Motor de deudas (Bola de Nieve)

> Fuente: `DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`


### Motor de deudas (Bola de Nieve) › Registrar deudas › Ingesta de datos manualmente (Monto, tasa, pago, fechas de vencimiento)
**✅ Incluye:**
Adjuntar documentos bancarios (ej: cartola ultimos movimientos).
Almacenamiento en base de datos.
Ordenamiento automático por prioridad (método bola de nieve).
Proyección básica de capacidad de ahorro a liberar.
Visualización plan de salida

La categorización será:
Regla simple por palabra clave
No modelo entrenado

**❌ No incluye:**
Consolidación automática de deudas bancarias.
Renegociación automática.
Conexión directa con bancos para pago.

**Adicionales:**
Validación automática del documento (Extrae datos y los ingresa a la BD)
Clasificación automática con IA.

**Trazabilidad:**
MR 3, 6, 7, 7.1, 9 | VP 3.2, 3.3, 5.1, P1, P3, P4 | BOS 4, 6, 9, 10

**Objetivo estratégico:**
Construir el núcleo del MVP para salir del rojo con una carga de datos viable.

**Resultado visible para el usuario:**
El usuario registra su deuda, entiende prioridad y obtiene un plan básico de salida para recuperar capacidad de ahorro.

**Definición funcional detallada:**
Alta manual de deuda con datos mínimos alineados al cálculo base: nombre o acreedor, monto bruto/principal cuando aplique, deuda actual, pago mínimo, interés o costo financiero cuando exista, número de cuotas pactadas y cuotas pendientes si aplica, y vencimiento. A partir de esa base el sistema aplica la lógica de bola de nieve para V1: orden principal por menor deuda actual, mantenimiento de pagos mínimos en las demás deudas y reasignación de la capacidad de ahorro recuperada a la siguiente deuda al cerrar una. El adjunto documental es apoyo, no requisito para comenzar.

**UX / UI:**
Flujo guiado paso a paso, con explicación simple de por qué se pide cada dato y cómo impacta el plan. Debe ser evidente que el orden sugerido sigue una lógica entendible y orientada a recuperar capacidad de ahorro, no una caja negra.

**Criterio de aceptación MVP / QA:**
Puede crear una deuda, guardarla y ver de inmediato su ubicación dentro del orden sugerido o del plan, usando los campos mínimos requeridos por la lógica de bola de nieve.

**Guardrails de alcance:**
No asumir consolidación bancaria, renegociación, pago desde la app, ni reemplazar la lógica base de bola de nieve por un ranking opaco fuera del alcance aprobado.


---


### Adjuntar cartolas o últimos movimientos
**Trazabilidad:**
MR 5.4, 8.1, 9 | VP 3.3, 5.1, P3 | BOS 6 Crear diagnóstico inicial

**Objetivo estratégico:**
Acortar el tiempo al primer valor, capturar deudas de forma automática y habilitar diagnóstico inmediato sin esperar un mes de uso manual.

**Resultado visible para el usuario:**
Si sube cartolas o últimos movimientos, en los primeros minutos el sistema identifica deudas potenciales no registradas (por ejemplo, compras en cuotas y saldo de línea de crédito), y entrega una lectura inicial de salud financiera, categorías sugeridas y primeras recomendaciones.

**Definición funcional detallada:**
Permitir adjuntar cartolas o últimos movimientos de uno o varios meses recientes en los formatos definidos por el proyecto. El foco de esta sección es identificar deudas que el usuario no haya ingresado manualmente y sugerirlas como registros potenciales para incorporarlas a la bola de nieve (por ejemplo, compras en cuotas, saldo de línea de crédito u otras obligaciones recurrentes). Adicionalmente, esta información alimenta el diagnóstico inicial, el presupuesto sugerido, el semáforo y las primeras recomendaciones apenas el usuario se enrola.

Debe presentarse como un paso altamente recomendado si el usuario quiere saber “cómo está hoy”. El sistema debe intentar leer automáticamente datos básicos cuando sea posible y, si la lectura no es suficiente, habilitar una instancia de revisión y corrección manual antes de guardar.

**UX / UI:**
Entrada visible y bien explicada: qué archivo sirve, por qué conviene subirlo para saber “cómo está hoy”, qué datos intentará leer el sistema (incluida la detección automática de deudas) y qué ocurre si el archivo no puede procesarse por completo.

**Criterio de aceptación MVP / QA:**
Flujo sin bloqueo: el usuario puede adjuntar el archivo, revisar lo detectado, corregir o completar manualmente (incluyendo confirmar/descartar deudas sugeridas), y el sistema refleja esa carga en el diagnóstico inicial, categorías sugeridas, deudas a incorporar (bola de nieve) y metas por categoría o presupuesto base.

**Guardrails de alcance:**
No vender esta función como open finance completo, no exigir extracción perfecta y no obligar a subir archivos para usar la app.


---


### Registrar movimientos › Categorización automática de los movimientos
**Trazabilidad:**
MR 5.4, 7.1, 8.1 | VP 3.2, 3.3, 5.1, P1, P3, P4 | BOS 4, 6, 9

**Objetivo estratégico:**
Reducir el trabajo manual y detectar movimientos que deben alimentar Bola de Nieve o Pagos, sin confundirlos con el armado base del presupuesto. Además, cada registro debe incorporar la institución financiera (o entidad donde están los fondos) para que el usuario, además de contar con una vista consolidada, pueda visualizar en un solo lugar cómo se distribuyen sus flujos entre cuentas, bancos y fuentes de dinero.

**Resultado visible para el usuario:**
El usuario ve sugerencias cuando un movimiento parece corresponder a pago de deuda, cuota, interés, mora o compromiso recurrente y puede enviarlo al módulo correcto.

**Definición funcional detallada:**
La lectura automática de movimientos, documentos o cartolas en este punto no busca armar todo el presupuesto, sino identificar registros ligados a deuda y obligaciones. Debe detectar, con reglas por palabra clave, nombre de comercio o texto del documento/movimiento y con apoyo técnico opcional si el equipo lo necesita, señales como cuotas de tarjeta con o sin interés, cargos por línea de crédito, intereses, mora, avances, pagos de crédito de consumo u otros pagos de deuda no declarados por el usuario. Cuando encuentre coincidencias, la app sugiere una de dos rutas: (a) incorporarlo o vincularlo al módulo de Bola de Nieve si revela una deuda/financiamiento que debe entrar al plan o está lesionando la capacidad de ahorro; (b) asociarlo al módulo de Pagos si se trata de una obligación recurrente a controlar por vencimiento. También debe permitir asociar movimientos reales a deudas o cuentas ya registradas para mantener consistencia entre módulos. Esto opera sobre movimientos ya cargados y no agrega una nueva fuente de datos al alcance.

**UX / UI:**
La sugerencia debe explicar por qué se detectó el movimiento, a qué módulo propone enviarlo (Bola de Nieve o Pagos) y qué acción puede tomar el usuario: vincular, crear, ignorar o corregir. Priorizar lectura simple y confirmación visible.

**Criterio de aceptación MVP / QA:**
Ante un movimiento compatible, la app propone clasificación deuda/pago, permite confirmarla y, si el usuario acepta, crea o vincula el registro sin duplicar estructuras.

**Guardrails de alcance:**
No confundir esta función con open finance completo ni con el armado base del presupuesto; no mover registros al plan o a pagos sin confirmación visible del usuario; no depender de IA opaca o de un modelo propio; y no tratar un apoyo técnico externo como una capacidad nueva del alcance. La institución/origen se registra solo como metadato de trazabilidad y consolidación de flujos a partir de los movimientos cargados por el usuario.


---


### Salida de deudas › Ajustar pagos y ver impacto en tiempo de salida
**Trazabilidad:**
VP P1 | BOS 9 Uso

**Objetivo estratégico:**
Permitir al usuario comparar esfuerzo vs tiempo de salida siguiendo la lógica de bola de nieve.

**Resultado visible para el usuario:**
Ve cómo cambia la fecha de salida si ajusta pagos.

**Definición funcional detallada:**
Simulador básico dentro del plan de deuda para cambiar pago adicional mensual y, si producto lo habilita, un pago inicial único disponible. Debe recalcular impacto siguiendo la lógica de bola de nieve: mantener mínimos en las demás deudas, aplicar el extra a la deuda prioritaria y, al cerrarla, trasladar esa capacidad de ahorro recuperada a la siguiente deuda.

**UX / UI:**
Controles simples y feedback inmediato sobre meses, fecha estimada y efecto del pago extra sobre la capacidad de ahorro recuperada.

**Criterio de aceptación MVP / QA:**
Al ajustar el pago adicional disponible, cambia el tiempo estimado de salida y la capacidad de ahorro recuperada conforme a la lógica definida.

**Guardrails de alcance:**
Sin escenarios avanzados multi-variable ni proyecciones a largo plazo fuera de la metodología base.


---


### Visualizar orden de pago sugerido (pago minimo, interes, pago sugerido)
**Trazabilidad:**
VP P1 | BOS 4 Mensaje contundente

**Objetivo estratégico:**
Hacer accionable la prioridad.

**Resultado visible para el usuario:**
Ve qué pagar primero, mínimo, interés y sugerencia.

**Definición funcional detallada:**
Lista ordenada con criterios visibles y campos mínimos comparables: saldo/deuda actual, pago mínimo, interés o costo financiero cuando exista, y pago sugerido o extra aplicado según la lógica de bola de nieve.

**UX / UI:**
Orden claro tipo 1-2-3; resaltar deuda prioritaria y explicar en lenguaje simple qué se paga mínimo y dónde entra el extra.

**Criterio de aceptación MVP / QA:**
El orden cambia según reglas y el usuario entiende por qué, incluyendo qué deuda recibe el extra y cuál mantiene pago mínimo.

**Guardrails de alcance:**
No ocultar lógica ni convertirlo en caja negra; el criterio principal debe seguir la metodología de bola de nieve aprobada.


---


### Ver plan de salida de deudas (Resumen del plan)
**Trazabilidad:**
VP P1, P5 | BOS 9 Continuidad

**Objetivo estratégico:**
Convertir prioridad en plan legible.

**Resultado visible para el usuario:**
Ve resumen del plan y próximos pasos.

**Definición funcional detallada:**
Vista resumen con deudas, secuencia sugerida, hitos y fecha estimada, siguiendo el orden de la bola de nieve y mostrando cómo se va trasladando la capacidad de ahorro recuperada entre deudas.

**UX / UI:**
Bloques simples y legibles; evitar tablas densas.

**Criterio de aceptación MVP / QA:**
El usuario puede leer el plan completo, entender la siguiente acción y reconocer cómo se compone su ruta de salida.

**Guardrails de alcance:**
No usar términos financieros confusos ni escenarios complejos.


---


### Ver proyección de capacidad liberada
**Trazabilidad:**
MR 7.1 | VP P4 | BOS 6 Potenciar capacidad de ahorro

**Objetivo estratégico:**
Hacer visible cuánta capacidad de ahorro puede recuperar el usuario al ordenar su deuda.

**Resultado visible para el usuario:**
El usuario entiende cuánta capacidad del mes podría recuperar al bajar deuda o evitar recargos.

**Definición funcional detallada:**
Mostrar una estimación simple del monto mensual que podría quedar disponible según el plan de salida o la reducción de recargos. Debe expresar la idea de “capacidad de ahorro recuperada”: cuando una deuda termina, ese mínimo deja de presionar el mes y puede reasignarse a la siguiente deuda o reflejarse como mayor holgura del presupuesto.

**UX / UI:**
Destacar el monto con lenguaje cotidiano, por ejemplo “capacidad de ahorro recuperada” o “plata que vuelve al mes”, y explicar en una línea si proviene de deuda terminada, menor recargo o menor presión financiera.

**Criterio de aceptación MVP / QA:**
El valor se actualiza cuando cambia el plan o los pagos y se muestra como un número entendible de capacidad de ahorro recuperada.

**Guardrails de alcance:**
No presentar esta cifra como ahorro garantizado, rentabilidad futura ni asesoría financiera formal.


---


### Ver listado de deudas priorizadas automáticamente
**Trazabilidad:**
VP P1 | BOS 5 Foco

**Objetivo estratégico:**
Ordenar el caos en una sola vista.

**Resultado visible para el usuario:**
Ve listado de deudas priorizadas automáticamente.

**Definición funcional detallada:**
Listado ordenado automáticamente por la lógica de bola de nieve definida para V1: menor deuda actual primero, manteniendo pagos mínimos en las demás; al cerrarse una deuda, su pago mínimo deja de presionar el mes y esa capacidad de ahorro recuperada se reasigna a la siguiente del orden.

**UX / UI:**
Visual limpia con columnas mínimas y prioridad visible; incluir pista corta del criterio usado.

**Criterio de aceptación MVP / QA:**
La lista se genera sin pasos manuales extra una vez cargadas las deudas.

**Guardrails de alcance:**
No mezclar con productos externos, refinanciamiento ni cambiar el criterio principal por tasa más alta salvo cambio explícito de producto.


---
