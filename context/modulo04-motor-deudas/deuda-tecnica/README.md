# M4 — Deuda técnica

**Revisado:** 2026-09-06 contra `origin/qa` de `back-walvy` y `front-walvy`.

> Las dos afirmaciones de la versión anterior de este archivo eran **falsas**: decían que
> el backend de deudas no existía y que la regla de severidad no estaba escrita. Ambas
> quedaron obsoletas y sirvieron de base para decisiones equivocadas. Ver «Lo que dejó
> de ser deuda».

---

## Lo que sí es deuda hoy

### 1 · El adaptador de `PressureInputs` — el bloqueo real

`debts.module.ts` inyecta `NullPressureInputsAdapter`, que devuelve todo en `null`. Sin
ingreso canónico ni headroom (**M05**), ni hecho de pago ni aging (**M06**), el motor P4
corre pero no concluye: la presión sale `no_calculable` y la salud `sin_datos_suficientes`.

**Consecuencia:** los escenarios En Control / Atención / Riesgo **no son reproducibles en
QA**. Todo usuario cae en el mismo estado.

**No es que falte el motor.** El motor está completo y cableado. Falta un adaptador — un
archivo. Un adaptador de fixtures detrás de un flag desbloquearía QA sin esperar a la
entrega de M05. **Sin dueño asignado.**

> ⚠️ **Y el bloqueo no es sólo de calendario.** Revisada la entrega de M05
> (`documentacion/Módulo05/`, 2026-09-06), su alcance **no incluye** el ingreso canónico
> ni el headroom que este puerto pide: cero menciones en los ocho documentos del paquete.
> Escribir el adaptador real no depende de que M05 entregue, sino de que alguien le
> asigne esos outputs. Es decisión de Producto y del cliente —
> [`../../modulo05-presupuesto-vivo/deuda-tecnica/README.md`](../../modulo05-presupuesto-vivo/deuda-tecnica/README.md).

### 2 · Dos tratamientos del contrato sin frame

OD-03 §8.3 define **cuatro** tratamientos: En Control, Atención, Riesgo con gate
incompleto, y Riesgo con confirmación y suficiencia. Figma dibujó dos. Sin frame quedan
🟡 **Atención** y 🔴 **Riesgo-con-gate-incompleto**.

A ellos se suma ⚪️ **No calculable**, que no es una lectura de OD-03 sino una degradación
del eje de calidad —`evaluable / parcial / no calculable`— y por eso necesita su propia
representación aunque el contrato no la enumere entre las lecturas del Resultado.

Los tres comparten hoy una **card neutra provisional** —sin mascota, con los neutros del
sistema— que dice «Aún no podemos concluir». Es honesto pero incompleto: la app no puede
representar dos tratamientos que el contrato exige.

**No está bloqueado por Diseño: está sin pedir.** La hoja `06_Ajustes_Materializacion` de
la Matriz de Trazabilidad lista los ajustes visuales pendientes del cliente, y estos
frames **no figuran** ahí. No hay nada que esperar; hay que solicitarlos. **Owner del
pedido: Producto.**

### 3 · Dos reglas escritas y sin cablear

`sustainability-gate` y `selected-plan` están completas y probadas, sin ningún camino que
las llame. No son deuda accidental: son **inversión adelantada** contra el contrato, a la
espera de M05 y de la pantalla de simulación de aporte. Se listan para que nadie las
crea muertas.

### 4 · El 27% del «Resumen del análisis» — ya resuelto, no es deuda de reglas

> **Corregido el 2026-09-06.** Este punto estaba mal planteado: decía que necesitaba que
> Producto declarara el porcentaje como regla. **La entrega ya lo cerró**, y en contra de
> esa lectura.

El frame muestra un porcentaje que ninguna regla calcula, y eso es correcto. La entrega
`Walvy_M04_Entrega_Kabeli_v1.0` lo resuelve en dos lugares:

- **§14 · Compatibilidad y reglas no vigentes:** «Valores Figma 27/43/58 —
  visual/referencial — **no thresholds financieros**».
- **`P4-CNT-007` · PRES-BASE**, en el borde de la regla: «no sumar puntos; **no usar
  27/43/58 Figma**».

Son tres números decorativos del frame, no uno, y el contrato los declara sin efecto
funcional. **No hay decisión de reglas pendiente.** Lo que queda es de materialización:
etiquetarlos como referenciales o sacarlos del frame. **Owner: Diseño / Producto.**

### 5 · Ninguna documentación de routing conoce Ruta Despeje

Las **diez pantallas** de `(tabs)/debt-route*` y `(tabs)/debts-*` no aparecen en ninguno
de los tres documentos que describen la navegación del front:

| Documento | Estado |
|---|---|
| [`../../specs/frontend-routes-graph.md`](../../specs/frontend-routes-graph.md) | Se declara «el grafo completo, incluyendo `(tabs)`». Es de jul-08 y no las tiene |
| [`../../specs/wiki/frontend-pantallas-endpoints.md`](../../specs/wiki/frontend-pantallas-endpoints.md) | Mapea pantalla → endpoints. Cubre auth, users y profile; no debts |
| [`../../wiki-codigo/frontend.md`](../../wiki-codigo/frontend.md) | Routing y Feature-First. Tampoco las nombra |

`route-map.md` era el cuarto y se borró el 2026-09-06: de jun-10, le faltaban dieciséis
rutas reales.

Los contratos de backend están completos (`back-walvy/docs/api/debts/`) y las pantallas
existen y tienen tests, pero **quien busque cómo se navega Ruta Despeje no lo encuentra
en el mapa de rutas**. Es la contraparte front del punto 6.

**Owner: M04 front.**

### 6 · El front consume una forma que el backend no devuelve

`getCurrentRoute()` en `expo/api/debtsService.ts` tipa la respuesta de
`GET /debts/route/current` como `RouteProgress` —`planId`, `progressPct`,
`recentPayments`—, y el backend devuelve `RouteStatus`: elegibilidad, activación,
review y plan. Ninguno de esos tres campos existe.

**Seis pantallas de Ruta Despeje** consumen ese tipo. Está anotado en el código
como trabajo de la etapa 2. **Owner: M04 front.**

### 7 · `transactionId` promete idempotencia y no la tiene

El DTO de `POST /debts/:id/payments` describe el campo como «(idempotencia)». No
hay índice único en `debt_payments.transaction_id` ni chequeo previo: dos POST con
el mismo `transactionId` insertan dos abonos y descuentan el saldo dos veces. El
`COMMENT ON COLUMN` del esquema dice lo correcto —«Movimiento con el que se
concilió el abono»—; la promesa está sólo en la descripción de Swagger.

Importa ahora porque **M07** es quien va a registrar pagos, y un reintento suyo
hoy corrompe el saldo. Se cierra con un índice único o borrando la promesa del
DTO. **Sin dueño asignado.**

---

## Lo que dejó de ser deuda

| Antes | Estado |
|---|---|
| «Backend de deudas no implementado» | **Falso desde ago-2026.** Módulo completo: 16 reglas, 3 servicios, 12 endpoints, 438 tests |
| «`evaluateDebtSeverity` no existe» | **Falso.** Existía desde jun-2026 — y se **borró** el 2026-09-06 por quedar sin dueño (ver abajo) |
| `GET /debts/result` ausente | **Descartado**, no pendiente. El contrato no define esa forma; presión y gate se publican en `GET /debts/route/current` |
| El Resultado afirmaba «En Control» sin evaluar | **Corregido** en `front-walvy#159` |
| «Ver Ruta» navegaba a Movimientos | **Corregido** en `front-walvy#160` |

### Por qué `debt-severity` sobrevivió tanto

Nació el 2026-06-28 en el primer commit de M04, como semáforo por vencimiento, **dos meses
antes de que llegara el contrato del cliente** (2026-08-31). Cuando llegó, el eje cambió:
el color sale de C×K×D, y el vencimiento pasó a Salud de Deuda con owner operativo M06.

La regla quedó huérfana pero **no se veía muerta**: el 2026-08-20 se le había agregado
encima `hasMoraConfirmada`, que sí estaba en uso desde M01. El archivo seguía importado,
así que un `grep` superficial lo daba por vivo.

**Lección para este README:** «existe un import» no es «está cableado». Verificar contra
los controllers.

---

## Cómo verificar este archivo

```bash
cd back-walvy && npx jest src/debts     # 438 tests, 27 suites
grep -rn "NullPressureInputsAdapter" src/debts/debts.module.ts
```

Contratos vivos: `back-walvy/docs/api/debts/route.md` ·
[`../motor-m04-en-detalle.md`](../motor-m04-en-detalle.md) ·
[`../plan-cierre-semaforo-resultado.md`](../plan-cierre-semaforo-resultado.md)
