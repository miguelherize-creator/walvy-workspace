# Release QA · Backend · 28 sep 2026

Lo que entra a `main` con [back-walvy#330](https://github.com/KabeliDev/back-walvy/pull/330), rama `sync-qa-main-2026-09-28`.

La app que lo consume es [front-walvy#244](https://github.com/KabeliDev/front-walvy/pull/244). Este documento es la API. Donde el caso se ve en pantalla, el ID de la app va al lado.

Probar contra un backend de esa rama, con un JWT de cuenta de prueba. Reportar por el ID: pasa / falla, el request y la response completa si falla.

---

## Antes de probar

Correr las migraciones de la rama. Sin estas tres, los casos de texto asistido y de categoría fallan antes de llegar a la regla:

- `1786000060000-AddFunctionalTagEligibleACategory`
- `1786000061000-BackfillCategoryIdDesdeHojaEnMovimientos`
- `1786000062000-AddAssistedTextSourceType`

Cuenta propia del tester. Los casos de duplicado y recurrencia se pisan entre sí si se reutilizan los mismos títulos.

---



## 1. Pagos (M06)

`POST /payments` evalúa duplicado y recurrencia solo al crear. Editar un pago después no vuelve a correr esa detección.


| ID        | Qué confirmar                                                                                                                                                                                                                       |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| BE-M06-01 | Dos pagos con el mismo monto y la misma moneda, nombres distintos y vencimiento a ≤3 días. El segundo nace `duplicado_probable`. `duplicateEvidence.matchedSignals` incluye `montoMoneda` y trae título, monto y fecha del primero. |
| BE-M06-02 | Mismo nombre normalizado (mayúsculas, espacios) y vencimiento a ≤3 días, montos distintos. También `duplicado_probable`, señal `descripcion`.                                                                                       |
| BE-M06-03 | Misma `linkedBudgetCategoryId`, mismo mes calendario, nombres y montos distintos, fechas a más de 3 días. `duplicado_probable` por `categoriaPeriodo`.                                                                              |
| BE-M06-04 | Mismo nombre y mismo monto, fechas a más de 3 días y sin categoría en común. No es duplicado.                                                                                                                                       |
| BE-M06-05 | Sin `dueDate` el alta no evalúa duplicado: no nace `duplicado_probable`.                                                                                                                                                            |
| BE-M06-06 | Tres pagos con el mismo nombre y el mismo monto, separados ~30 días (20–40). El tercero nace `recurrente_probable`. `recurrenceEvidence.frequency` es `mensual` y `matchedPaymentIds` trae los dos anteriores.                      |
| BE-M06-07 | Tres pagos con el mismo nombre y el mismo monto, separados ~365 días (350–380). `recurrente_probable` con `frequency` `anual`.                                                                                                      |
| BE-M06-08 | Mismo nombre y monto cada ~90 días. No es `recurrente_probable`.                                                                                                                                                                    |
| BE-M06-09 | `GET /payments` y `GET /payments/:id` traen `duplicateEvidence` solo mientras el estado es `duplicado_probable`, y `recurrenceEvidence` solo mientras es `recurrente_probable`.                                                     |
| BE-M06-10 | Alta con `metadata.clientNumber`. No va como campo propio del body: un `clientNumber` suelto responde 400. `GET /payments/:id` devuelve el valor dentro de `metadata`. La columna `client_number` no se escribe.                    |
| BE-M06-11 | `GET /payments/:id/history` de un pago propio responde 200, la transición más reciente primero. Un id ajeno no devuelve el historial.                                                                                               |


En la app, BE-M06-01 y BE-M06-06 se ven en el sheet «Por qué Walvy lo marcó así». BE-M06-10 se ve al reabrir el compromiso manual.

---



## 2. Movimientos y presupuesto (M05)

El parse no guarda nada. El movimiento existe recién en el `POST /financial-movements` de confirmación.


| ID        | Qué confirmar                                                                                                                                                                                                                                                                                   |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| BE-M05-01 | `POST /financial-movements/assisted-text/parse` con `{ "text": "Gasté 12.990 en el súper ayer" }` responde 200, `valid: true`, `amount: 12990`, `movementDirection: "out"`, `ruleVersion: "assisted_text_v1"`. `occurredOn` es ayer en hora de Chile. No aparece una fila nueva en movimientos. |
| BE-M05-02 | `{ "text": "compré cosas" }` → `valid: false`, `reasonCode: "NO_AMOUNT"`.                                                                                                                                                                                                                       |
| BE-M05-03 | `{ "text": "gasté 5.000 y 10.000" }` → `MULTIPLE_AMOUNTS`.                                                                                                                                                                                                                                      |
| BE-M05-04 | `{ "text": "12.000 en el super" }` → `NO_DIRECTION`.                                                                                                                                                                                                                                            |
| BE-M05-05 | `{ "text": "gasté 5.000" }` → `NO_CONCEPT`.                                                                                                                                                                                                                                                     |
| BE-M05-06 | `{ "text": "" }` → `EMPTY`.                                                                                                                                                                                                                                                                     |
| BE-M05-07 | Confirmar el candidato con `POST /financial-movements`, `sourceType: "assisted_text"` y `categoryId`. Responde 201. Un `GET` posterior lo muestra. `sourceType: "document"` o `"integration"` por este POST responde 400.                                                                       |
| BE-M05-08 | `PATCH /financial-movements/:id` con `{ "amount": 15000 }` responde 200 y el monto sigue en un segundo `GET`.                                                                                                                                                                                   |
| BE-M05-09 | `{ "amount": 0 }`, `{ "amount": -100 }` o un monto con más de 4 decimales responden 400.                                                                                                                                                                                                        |
| BE-M05-10 | `{ "occurredOn": "2026-10-05" }` responde 200 y la fecha queda.                                                                                                                                                                                                                                 |
| BE-M05-11 | `{ "categoryId": "<uuid>" }` en el PATCH sigue rechazado. La categoría se corrige solo por `POST /financial-movements/:id/validate`.                                                                                                                                                            |
| BE-M05-12 | Corregir el monto hasta que coincida con otro movimiento propio de la misma fecha y glosa parecida. El corregido queda con duplicado posible en la cola de revisión.                                                                                                                            |
| BE-M05-13 | Corregir el monto para que deje de coincidir. El flag de duplicado se limpia. El movimiento sigue en la cola.                                                                                                                                                                                   |
| BE-M05-14 | Un PATCH que no cambia el monto no marca el movimiento como duplicado de sí mismo.                                                                                                                                                                                                              |
| BE-M05-15 | `POST /financial-movements/:id/validate` con `{ "action": "corrected", "categoryId": "<padre>", "categoryLeafName": "Afterschool" }` responde 200. Crea la subcategoría y se la asigna al movimiento en el mismo request.                                                                       |
| BE-M05-16 | Repetir BE-M05-15 con el mismo nombre responde 409, no 500.                                                                                                                                                                                                                                     |
| BE-M05-17 | `categoryLeafId` y `categoryLeafName` juntos responden 400: «Envía categoryLeafId o categoryLeafName, no ambos.»                                                                                                                                                                                |
| BE-M05-18 | `categoryId` de una categoría privada de otro usuario responde 403.                                                                                                                                                                                                                             |
| BE-M05-19 | `GET /budget/plan/summary?month=2026-09` incluye `ingresoMensual`, `gastoTotalMes`, `presupuestoTotal` y `gastoPresupuestado`. `ingresoMensual - gastoTotalMes` es igual a `capacidadAhorro`.                                                                                                   |
| BE-M05-20 | `GET /budget/plan/items/<categoryId>/subcategories?month=2026-09` devuelve el consumo del mes por subcategoría de esa raíz. Solo trae etiqueta de fuga activa si hay un patrón vigente. No aparecen «No planificado», «Planificable» ni «Recuperable».                                          |


En la app, BE-M05-01 a BE-M05-07 son M5-V13, M5-V14 y M5-V15. BE-M05-19 es la tarjeta «Así va tu mes».

---



## No probar en este release

Quedó en el backend y no cambia lo que ve el usuario: el stack trace del log cuando un import falla, y los tests de `financial-movements.e2e-spec.ts`. El mensaje de error en la app no cambia.

No están en este backend, aunque en `qa` existan. Un fallo acá no es regresión de este release:

- `confirmadosDelMes`, `vencidosDelMes` y `compromisosAlDiaPct` en `GET /payments/summary`.
- `linkedRouteActive` en el listado `GET /payments`. Solo viaja en `GET /payments/:id`.
- Voz o micrófono en la carga de movimientos.
- El resto de variantes de M05 fuera de la tabla de arriba (umbrales, histórico, plan de recuperación).

