# Correo a PMO/Diseño · Estados de procesamiento en Carga de documentos

**Fecha:** 2026-09-09
**Frames:** `10272:54679` (tarjeta «Carga tus documentos», M04) ·
`10366:30385` (tarjeta «Tus documentos» de «Revisa tus documentos», onboarding)
**Comentario que responde:** falta representar subiendo / procesando / leído /
no procesable / error técnico; no listar archivos rechazados por extensión
**Medido sobre:** `front-walvy` rama `qa` y `back-walvy/src/imports/`
**Estado:** borrador, pendiente de enviar

> **Corrección respecto de la primera versión de este borrador.** Decía que los
> estados intermedios no estaban implementados. Es falso: están en producción en
> las dos pantallas de análisis, con seis variantes de error y copy definido. El
> problema es de frames y de en qué pantalla van, no de implementación.

---

**Asunto:** M04 · Estados de procesamiento del documento — ya están implementados; falta dibujarlos y decidir dónde viven

Hola [PMO], [Diseño],

Revisé el comentario contra el código antes de responder, y el resultado cambia
la conversación: **los estados que piden ya existen y están funcionando**, en
onboarding y en Ruta Despeje, con más granularidad que la que pide la
remediación. Lo que falta son las variantes dibujadas y una decisión de
producto sobre en qué pantalla se muestran.

## Lo que ya está implementado

La fila de documento de «Revisa tus documentos» —el frame `10366:30385`— ya
renderiza cinco estados por archivo, y Ruta Despeje usa el mismo modelo y la
misma fuente de copy:

| Estado | Qué muestra hoy |
|---|---|
| Subiendo | «Subiendo…» donde el frame pone el peso, con spinner |
| Procesando | «Analizando…», con spinner |
| Leído | check, fila atenuada, etiqueta del tipo de documento, «Ya analizado» si se reusó |
| Requiere contraseña | «Requiere contraseña» y ✗ |
| No se pudo leer | etiqueta + instrucción según la causa, y ✗ |

Un detalle que conviene notar: **el check y la papelera que ya están en el frame
son estados**, no dos adornos. La papelera sólo aparece mientras el documento no
esté leído ni en proceso; una vez leído la fila se atenúa y deja de ser
removible. Diseño ya dibujó esa distinción sin nombrarla.

Y los fallos ya están separados en seis casos, con copy escrito
(`features/auth/utils/importErrorCode.ts`):

| Etiqueta | Instrucción |
|---|---|
| No procesable | «Sube una cartola, un estado de cuenta o un informe CMF.» |
| Desactualizado | «Tiene más de 90 días. Sube una más reciente.» |
| No verificable | «No pudimos leer el período de esta cartola.» |
| Error temporal | «Inténtalo de nuevo en unos segundos.» |
| Requiere contraseña | — |
| No se pudo usar | «Prueba con otro archivo.» |

Sobre la remediación pedida —reintentar, reemplazar o registrar manualmente—:
**ya está, y con una precisión que vale conservar.** *Reintentar* aparece sólo
cuando la causa es transitoria. En los otros casos el mismo archivo da siempre
el mismo resultado, y el backend rechaza el reintento con un 400 explícito. Si
las tres acciones se ofrecieran juntas en un único estado de error, *Reintentar*
sería un botón que siempre falla. *Registrar deuda manualmente* ya está al lado.

## Entonces, ¿qué falta de verdad?

**Uno. Los frames.** Ninguna de las dos tarjetas —ni `10366:30385` ni
`10272:54679`— tiene variantes para estos estados: la fila sólo existe en check
y en papelera. Necesito las variantes, o la confirmación de que el copy de
arriba es el válido y lo mantengo tal cual. Si Diseño quiere cambiar esas
etiquetas, es el momento: hoy son la fuente única de las dos pantallas.

**Dos, y es la decisión de fondo.** El comentario dice que la pantalla «pasa
directamente de carga a archivo verificado/error». Eso es cierto de la tarjeta
de carga, y por diseño: en esa pantalla la fila sólo tiene estados de
contraseña, porque el procesamiento ocurre **en la pantalla siguiente**, la de
análisis, que es donde viven los cinco estados. El usuario los ve, pero después
de avanzar.

La pregunta que hay que resolver es cuál de las dos se quiere:

- **Como está hoy:** cargar → avanzar → ver el progreso y los errores en la
  pantalla de análisis.
- **Lo que el comentario parece pedir:** que el progreso y los errores se vean
  en la misma tarjeta de carga, sin cambiar de pantalla.

La segunda es implementable —el backend publica el estado por documento y el
front ya lo poletea— pero es una pantalla distinta de la dibujada, y arrastra
qué pasa con el botón de avanzar mientras hay documentos en proceso. No la
implemento por inferencia.

## Archivos rechazados por formato: son dos momentos

De acuerdo en no listarlos, con una precisión. El rechazo ocurre en dos lugares
y sólo uno tiene copy propuesto:

1. **En el selector, antes de subir.** Extensión o tamaño no admitidos; el
   archivo nunca entra a la lista. Acá va «Formato no compatible. Puedes subir
   PDF, Excel o CSV.» Falta el equivalente por tamaño: el límite real es
   **30 MB** —coincide con el hint del frame— y no hay copy para cuando se supera.
2. **En el servidor, ya subido.** El tipo se valida **por el contenido del
   archivo, no por su nombre**: un `.doc` renombrado a `.pdf` pasa el selector y
   se rechaza después. Ese archivo sí llegó a la lista. Hoy cae en «No se pudo
   usar / Prueba con otro archivo», que sirve pero no dice que el problema es el
   formato.

## Lo que necesito decidido

1. **¿Los estados se quedan en la pantalla de análisis, o se traen a la tarjeta
   de carga?** Es lo que decide si esto es dibujar variantes o rehacer la
   pantalla.
2. **Las variantes de fila**, o la confirmación de que el copy actual queda.
3. **Copy faltante:** archivo sobre 30 MB, y archivo con extensión válida cuyo
   contenido no lo es.
4. **«Leído / no leído»** del comentario: ¿es leído frente a fallido, o se
   refiere a otra distinción?

Saludos,
Miguel
