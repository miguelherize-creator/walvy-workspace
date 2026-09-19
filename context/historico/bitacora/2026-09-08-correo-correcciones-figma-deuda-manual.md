# Correo a PMO · Correcciones Figma — Sheet de deuda manual

**Fecha:** 2026-09-08
**Frame:** `Sheet_Deuda Manual_Ingresar datos` — `10272:55371`
**Medido sobre:** `back-walvy` `src/debts/` (código vigente, no la doc de contexto)
**Estado:** borrador, pendiente de enviar
**Incorpora:** comentarios de Diseño/PMO sobre los botones de guardado y sobre
las opciones de tipo de deuda

---

**Asunto:** M04 · Deuda manual (`10272:55371`) — cuatro puntos antes de implementar

Hola [PMO],

Revisé el frame contra el backend y contra los comentarios que dejaron. El
criterio de los dos guardados calza bien con lo que ya existe; quedan cuatro
cosas por cerrar antes de que lo implemente.

## 1 · Los dos guardados calzan con el modelo, pero crean dos umbrales y el frame marca uno

El comentario —sin todos los obligatorios se guarda como pendiente, con todos se
guarda la deuda— es exactamente la distinción que el backend ya tiene: una deuda
nace **`unconfirmed`** y pasa a **`confirmed`** cuando está completa, y sólo las
confirmadas entran al plan de Ruta Despeje. Se implementa sin cambios de
backend: pendiente es `POST /debts`, deuda es esa llamada más
`POST /debts/:id/confirm`.

Justamente por eso hay **dos niveles de obligatoriedad**, no uno:

- **Para guardar como pendiente** el backend exige tres campos: acreedor, tipo
  de deuda y saldo actual (`create-debt.dto.ts`). Sin cualquiera de ellos no hay
  nada que guardar, ni siquiera como pendiente.
- **Para guardar la deuda** se suman pago mínimo y próximo vencimiento
  (`REQUIRED_FOR_CONFIRMATION`).

El frame usa el mismo asterisco para campos de los dos niveles —tipo de deuda y
saldo actual del primero, pago mínimo y próximo vencimiento del segundo— y deja
**acreedor sin ninguna marca**, aunque sea del primero.

Eso produce dos lecturas equivocadas. Quien llene los cuatro campos con
asterisco y deje el acreedor vacío espera *guardar deuda* habilitado y recibe un
error que la pantalla no anticipó. Y a la inversa, quien vea asteriscos sin
llenar puede creer que no puede guardar nada, cuando *guardar como pendiente* ya
está disponible.

Necesito una de dos: o el frame distingue los dos niveles con notaciones
distintas, o el asterisco pasa a significar «requerido para guardar deuda» —y
entonces el acreedor también lo lleva, porque hace falta para ambos.

**Y falta el frame de los botones.** El footer actual (`10272:55426`) tiene
*Cancelar*, *Guardar* y el enlace *Guardar y agregar otra deuda*: un solo
guardado, deshabilitado. No hay dos opciones dibujadas ni copy para ellas. ¿Son
dos botones, o el mismo *Guardar* cambiando de etiqueta según el estado? Y en el
caso pendiente, ¿qué dice, y qué pasa con *Guardar y agregar otra deuda*?

## 2 · Con dos guardados, el checkbox de la cuota abre un tercer estado

«No sé la cuota mensual por ahora» (`10272:55399`) ahora tiene una pregunta
concreta: **¿marcarlo habilita *guardar deuda* sin la cuota?**

- Si la habilita, choca con el backend: la cuota es requisito para confirmar y
  la llamada responde 400 sin ella. Sería un guardado que la pantalla ofrece y
  el sistema rechaza.
- Si sólo deja al usuario en *pendiente*, entonces no aporta nada: produce el
  mismo estado guardado que dejar el campo vacío. El backend deriva
  `metadata.unknownMinimumPayment` de que la cuota llegue nula, no de una
  declaración, así que no distingue «no la sé» de «no la llené».

En el segundo caso propongo eliminarlo: su bajada («Podrás completarlo en el
siguiente paso») ya la dice el aviso al pie para toda la pantalla, y es un
control menos en un formulario de ocho campos. Si a Producto le importa
distinguir a quien declara no saber la cuota, eso sí es un cambio de backend y
lo hago sólo si ese matiz se va a usar en algún copy o alguna regla.

Nota menor: el control instanciado es `btn_Radio check` (`10272:55400`), un
radio, que no se puede desmarcar. Si se queda, debería ser checkbox.

## 3 · Tipo de deuda: la lista ya existe y es contrato

Sobre «opciones iniciales serán revisadas y definidas por Negocio»: hay ocho
opciones vigentes en producción, y el backend es dueño del copy y lo publica en
`GET /catalog/debt-types`, que consumen el front y el agente
(`debt-type.enum.ts`).

Tarjeta de crédito · Crédito de consumo · Crédito automotriz · Crédito
hipotecario · Préstamo personal · Deuda informal · Línea de crédito · Otro
compromiso mensual

Dos consecuencias prácticas. Primero, conviene que Negocio revise **esta** lista
en vez de partir de cero. Segundo, el campo está validado contra ese conjunto
cerrado: una opción que se agregue después y no esté en él se rechaza con 400,
así que un cambio posterior a diseño no es sólo copy —toca backend, front y
agente. Necesito una fecha de corte para esa definición, porque el desplegable
no se puede cerrar antes.

## 4 · «Última cuota pagada» sigue siendo el dato inverso

Ya estaba abierto en el frame anterior (`5946:6498`) y este lo mantiene. El
sistema guarda **cuotas que faltan**; el frame pide **cuotas ya pagadas**. Con
total 10 y última pagada 5 coinciden por casualidad, pero son cosas distintas. O
el modelo gana un campo, o el label cambia a «Cuotas restantes». Seguimiento en
KabeliDev/back-walvy#234.

## Lo que necesito decidido

1. Cómo se distinguen en pantalla los dos niveles de obligatoriedad, y el
   asterisco que le falta a «¿Con quién tienes esta deuda?».
2. El frame de los dos guardados, con su copy y qué pasa con *Guardar y agregar
   otra deuda*.
3. El checkbox de la cuota: ¿se elimina, o habilita *guardar deuda*?
4. Fecha de corte para las opciones de tipo de deuda.

Saludos,
Miguel
