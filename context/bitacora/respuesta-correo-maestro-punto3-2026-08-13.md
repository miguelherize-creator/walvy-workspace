# Borrador de respuesta — correo maestro, punto 3 (Protección de datos personales)

**Fecha:** 2026-08-13
**Destinatarios del original:** José Miguel Rodríguez · con Ana María Soto y Miguel Herize en copia directa
**Base técnica:** back-walvy `walvy/main` `073c523` (2026-08-13)
**Documento de respaldo:** `2026-08-13-estado-controles-seguridad-bd.md`

> **Decisiones tomadas el 2026-08-13:** Kabeli asume la actualización del v2.6 · las cartolas de la estación de desarrollo no van al correo y se remedian internamente hoy.
>
> **Antes de enviar:** confirmar con Ana el compromiso de plazo del v2.6 (el borrador dice "la semana entrante") y el plazo de la verificación de infraestructura ("esta semana").

---

## Cuerpo del correo

Jose Miguel, buenos días,

Tomamos el punto 3 en los términos en que lo planteas, incluida la instrucción de no cerrarlo todavía: esperamos el documento transversal, contrastamos la implementación contra ese marco, y levantamos lo que requiera definición adicional. Lo que sigue no pretende cerrar el punto — es el estado del baseline para que llegue como insumo al documento y no como algo que haya que descubrir después.

**Sobre el alcance del análisis, tienes razón y lo corregimos.** Nuestra revisión de datos personales estaba centrada en identificadores directos: RUT, correo, nombre, alias. Volvimos a levantar el inventario con el alcance que planteas y quedó en tres capas:

- **Documentación.** El PDF de la cartola, sus metadatos, y —esto es lo que el enfoque anterior no veía— la fila original de cada línea del documento, que se conserva tal como llegó en `import_line_items.raw_row`. La consecuencia práctica: el PDF se elimina a los 30 días, pero el contenido de cada línea permanece en la base de forma indefinida. La retención efectiva del dato financiero no son 30 días. No es un defecto —hace falta para reconstruir movimientos— pero es una decisión de conservación que hoy no está declarada, y va como pregunta al marco.
- **Información financiera vinculable.** Movimientos, transacciones, deudas y sus calendarios y pagos, cuentas de origen, presupuestos, ingreso estimado y capacidad de pago, órdenes de pago y suscripción.
- **Datos derivados del procesamiento.** Es la capa que teníamos subponderada: clasificaciones sugeridas por movimiento con su nivel de confianza y la regla que las produjo, estado de salud de deuda con sus códigos de causa, nivel de calidad del perfil, reglas de gasto hormiga, estadísticas de comportamiento, y los diagnósticos mensuales, rankings de deuda y detección de fugas.

Hay un dato de oportunidad relevante en esa tercera capa: **una parte importante de esas tablas existe en el modelo pero todavía no tiene una sola fila**, porque ningún componente las escribe aún — los indicadores de salud financiera en el tiempo, los eventos de recomendación, el historial de puntaje, los read models de diagnóstico mensual, y toda la capa de IA. Definir clasificación, finalidad y retención sobre esas tablas antes de que empiecen a poblarse es sustancialmente más barato que hacerlo después, y creemos que vale la pena que el documento transversal las alcance en esta pasada.

**Lo que ya está implementado y podemos entregar con evidencia**, sujeto a contraste contra el marco cuando llegue:

| Familia de control | Estado |
|---|---|
| Protección en reposo | La base de datos y el almacenamiento de documentos van cifrados. Contraseñas y tokens de sesión y OTP se guardan únicamente como hash, nunca recuperables |
| Accesos | La base no tiene acceso público y vive en subred aislada; las credenciales están en gestor de secretos; cada consulta verifica que el titular sea el dueño del dato antes de devolverlo o modificarlo; la autenticación tiene límites anti fuerza bruta por ruta |
| Ambientes no productivos | Los datos de prueba son sintéticos, sobre un dominio de correo inexistente, y la siembra se niega a ejecutarse contra producción. Las herramientas de desarrollo quedan excluidas del despliegue productivo |
| Eliminación | El modelo está preparado — baja lógica, y el documento de identidad vuelve a quedar disponible tras una baja — pero **el flujo de baja de cuenta todavía no existe**. Es trabajo pendiente, no una decisión |
| Logs y evidencia | **Pendiente.** La tabla de auditoría existe en el modelo y ningún componente la escribe. No avanzamos por nuestra cuenta a propósito: qué eventos entran es definición de Seguridad, y preferimos que salga del marco antes que reescribirlo después |
| Minimización · Seudonimización | Parcial, y con un antecedente concreto que va en el párrafo siguiente |

**Sobre minimización y seudonimización hay evidencia concreta ya construida, en `M01-PRV-002`.** El registro de aceptación legal quedó modelado con un identificador seudónimo por usuario que sobrevive a la eliminación de la cuenta y no permite reidentificar sin la sal del sistema: al eliminar la cuenta, la referencia al usuario queda en nulo y la evidencia del consentimiento se conserva de forma seudónima. Esto resuelve la tensión entre el derecho de supresión del titular y la necesidad de conservar prueba del consentimiento, sin sacrificar ninguno de los dos. En la misma implementación se decidió **no** recolectar dirección IP ni agente de usuario, por ser datos personales sin finalidad declarada, dejando la justificación escrita — agregar la columna después es trivial, purgar direcciones ya recolectadas no. Lo mencionamos porque es el tipo de decisión que el marco va a querer ver aplicada y no solo enunciada.

**La capa de infraestructura la estamos verificando contra el ambiente efectivamente desplegado** — cifrado en tránsito hacia la base, privilegios de la cuenta con que se conecta la aplicación, y configuración de los ambientes no productivos. Tenemos observaciones levantadas sobre la definición de infraestructura, pero esa definición tiene dos meses respecto del código actual y no queremos reportar como hallazgo algo que el ambiente real pueda ya no tener. Cerramos esa verificación esta semana y les llega el resultado con evidencia.

---

Sobre los demás puntos, brevemente:

**1 · Condición de cierre del onboarding.** Recibido, y nos sirve la precisión de que no requiere nueva definición de Producto: teníamos levantado que dos de las cuatro condiciones de cierre no las escribe ningún componente hoy, y era justamente la duda que nos frenaba. Con las referencias que indicas queda desbloqueado. El modelo de puertas del onboarding ya está implementado siguiendo `M1-RN-ONB-014`, con el dominio de estados garantizado por restricción en la base, y sobre esa base se implementa el criterio. Coordinamos con Jeaninne la materialización en BBDD.

**2 · Roles, permisos y autorización.** El principio de confinamiento del titular a su propia cuenta está implementado como verificación de propiedad en cada acceso a dato financiero. Cumpliendo con lo que pides sobre levantar en lugar de resolver por cuenta propia, te reportamos que **detectamos una excepción y la estamos corrigiendo**: un endpoint de utilidad de la etapa de pruebas de importación opera sobre registros técnicos sin verificar el titular, y quedó accesible en el despliegue. No expone contenido de cartolas ni movimientos —solo registros de control de duplicados—, pero contradice el principio de `M01-AUT-001` y por eso lo reportamos en lugar de corregirlo en silencio. Queda cerrado en la próxima entrega. Sobre cuentas administrativas: hoy no existe módulo administrativo, así que la restricción de que no otorgue acceso a contenido personal o financiero de clientes queda como criterio de diseño antes de construirlo, no como corrección posterior.

**4 · Versionamiento de documentos legales.** La precisión sobre reaceptación llega en buen momento: el modelo de `M01-PRV-002` ya contempla el campo que indica si una versión requiere reaceptación, y estaba declarado explícitamente como pendiente de definición funcional — la columna existía para soportar la decisión, no para anticiparla. Con tu definición se puede implementar sin migración adicional. El modelo también satisface ya el requisito de que la falta de respuesta no se registre como aceptación: presentación, aceptación y rechazo son acciones distintas y solo la aceptación admite fecha de aceptación, por restricción en la base. Y una aceptación histórica no se puede alterar al publicarse una versión posterior: hay un disparador que lo impide, que es lo que `TC-M01-035` tiene que acreditar.

Para que quede dimensionado con precisión: **lo entregado es el modelo de datos, no todavía el comportamiento.** El servicio que resuelve la versión vigente, decide si corresponde pedir aceptación y registra la acción del usuario es la etapa siguiente, y hoy lo que opera sigue siendo la marca de tiempo simple en la cuenta. La secuencia es deliberada — construir el registro sobre un modelo que después hay que migrar sale más caro —, pero significa que `TC-M01-034/035/036` no se pueden ejecutar aún. Quedan pendientes de tu lado el canal del artefacto oficial y la política de reaceptación; el modelo soporta contenido embebido o referencia externa sin necesidad de una segunda migración.

Sobre tu pregunta de quién actualiza el v2.6: **la tomamos nosotros.** Nos hace sentido porque el modelo ya está construido con el campo de reaceptación y con las restricciones que sostienen el resto del requisito, así que sabemos con precisión qué comportamiento hay que describir y evitamos que el texto y la implementación queden desalineados. Te enviamos la actualización de `M01-PRV-002` y `M01-PRV-003` la semana entrante, redactada para que la revises y la incorpores bajo tu firma — la fuente oficial sigue siendo tuya, nosotros aportamos el texto. Si tienes preferencia sobre el formato o sobre dónde debe quedar dentro del documento, dínoslo y nos ajustamos.

**5 · Trazabilidad de importaciones.** Revisado, y creemos que el modelo actual ya satisface la trazabilidad funcional que describes, sin necesidad de agregar la relación física. El movimiento conserva referencia directa al documento de origen, más el tipo de origen, la referencia al registro de la línea y una huella del dato; y la línea importada conserva referencia al proceso de importación y al documento. El recorrido desde el movimiento o indicador hacia su documento y su proceso de origen queda completo en las dos direcciones. Un detalle que conviene tener presente: los metadatos y la huella del documento sobreviven a la eliminación del PDF, así que la trazabilidad funcional se conserva aunque el archivo ya no esté. Quedamos disponibles para que Yanine valide la suficiencia del modelo con nosotros.

---

**Lo que necesitamos para poder declarar validación**, y que entendemos vendrá en el marco transversal — lo listamos para que no quede implícito:

1. Plazo de conservación por familia de dato: documentación, contenido de línea importada, movimientos, datos derivados, logs de auditoría, tokens, y cuentas dadas de baja.
2. Si la baja de cuenta es anonimización o supresión física, y qué debe conservarse por obligación legal de la suscripción.
3. Qué eventos entran al registro de auditoría, y con qué retención.
4. Qué controles corresponden a cada capa de datos derivados según su clasificación — es la pregunta que reemplaza a "¿se cifra el RUT?".
5. Si el documento de identidad es dato necesario en M01.

Quedamos atentos al documento transversal para hacer el contraste completo, y te confirmamos esta semana el resultado de la verificación de infraestructura.

Saludos,

---

## Notas de redacción

**Por qué no cierra el punto 3.** El correo maestro dice literalmente *"La solución técnica concreta se implementará posteriormente conforme a esos lineamientos"* y *"No cerrar este punto únicamente definiendo protección para RUT/correo"*. Un borrador que llegara con una propuesta de cifrado de campos se leería como exactamente el error que el correo advierte. La respuesta correcta es aportar el baseline y esperar el marco.

**Por qué se reconoce el sesgo del análisis anterior en la primera línea.** El correo hace esa observación de forma explícita y en más de una instancia (*"En las distintas revisiones he notado…"*). Un correo que no la recoja invita a que se repita en la siguiente. Reconocerla y mostrar el inventario corregido cierra el tema de una vez.

**Por qué se reporta la excepción del punto 2 en lugar de callarla.** El correo pide textualmente que *"cualquier duda que implique modificar estos criterios de acceso debe volver a Producto/Seguridad antes de resolverse"*. Un endpoint que contradice `M01-AUT-001` es reportable por ese mismo criterio, y es verificable desde la API por cualquiera que la revise. Reportarlo con el alcance real acotado —registros de control, no contenido financiero— cuesta mucho menos que que lo encuentren.

**Por qué la infraestructura va como verificación en curso y no como hallazgo.** Las observaciones sobre cifrado en tránsito, privilegios de la cuenta de aplicación y configuración de ambientes salen de la definición de infraestructura, cuyo último cambio es del 10 de junio contra un backend del 13 de agosto. Afirmarle al cliente un problema que el ambiente real pueda ya no tener cuesta más que los días de atraso.

**Por qué Kabeli toma el v2.6.** La respuesta se apoya en un hecho verificable —el campo de reaceptación ya existe en el modelo y quedó documentado como pendiente de definición funcional— y ofrece el texto sin arrebatarle la fuente oficial al cliente. Es la lectura más favorable posible de una situación en que el modelo se adelantó a la definición, y evita el escenario en que Producto redacta el texto sin conocer las restricciones ya implementadas y queda desalineado.

**Lo que el borrador deliberadamente no dice.** No menciona las cartolas reales en la estación de desarrollo: se remedia internamente el mismo día, son datos que no pertenecen al cliente, y reportarlo antes de remediarlo abre un proceso formal por algo que dura una hora. Queda registrado en la §5 del documento técnico. **Esta decisión asume que la remediación ocurre hoy** — si no ocurre, la ecuación cambia y corresponde reportarlo.
