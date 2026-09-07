# M04 — Ruta Despeje · índice del módulo

Punto de entrada del módulo. En producto el feature se llama **Ruta Despeje**; en la
numeración de carpetas y DB es **M4 — Motor de Deudas** (`db/modulo4.md`). Módulo Nest:
`back-walvy/src/debts/`.

## Empezar por acá

| Documento | Qué cubre |
|---|---|
| [`../motor-m04-en-detalle.md`](../motor-m04-en-detalle.md) | **El motor de punta a punta**: cómo entra una deuda y cómo sale como decisión. Levantado del código en `qa` |
| `back-walvy/docs/api/debts/route.md` | **El contrato vivo**: las cinco reglas, los tres endpoints de Ruta y lo que publica en el perfil |
| `back-walvy/docs/api/debts/debts.md` | Captura, revisión y `POST /debts/:id/payments` |
| `back-walvy/src/debts/ports/pressure-inputs.port.ts` | **Lo que M04 no calcula**: la interfaz que implementan M05 y M06 |

## Producto y decisiones abiertas

| Documento | Qué cubre |
|---|---|
| [`../req-resultado-onboarding-semaforo.md`](../req-resultado-onboarding-semaforo.md) | Resultado del paso 3: presión vs elegibilidad de Ruta |
| [`../preguntas-abiertas-producto.md`](../preguntas-abiertas-producto.md) | Decisiones que no se resuelven desde backend |
| [`../revision-plan-de-trabajo.md`](../revision-plan-de-trabajo.md) | Revisión (paso 2) contra sus frames |
| [`../plan-cierre-semaforo-resultado.md`](../plan-cierre-semaforo-resultado.md) | Plan de cierre del semáforo. Parcialmente ejecutado |

## Deuda técnica

[`../deuda-tecnica/README.md`](../deuda-tecnica/README.md) — seis puntos abiertos, con
owner donde lo hay.

## Histórico

[`debts-manual-entry.md`](debts-manual-entry.md) — **no es contrato.** Diseño objetivo de
junio de 2026, escrito dos meses antes de que llegara `Walvy_M04_Entrega_Kabeli_v1.0`. El
backend se construyó con otro modelo. Se conserva porque explica de dónde salieron
decisiones que después se revirtieron; lleva su propio aviso arriba.

## Contrato del cliente

`documentacion/modulo04-update/` — la entrega `Walvy_M04_Entrega_Kabeli_v1.0`, fuera de
este repo. Ahí están el contrato funcional, el Anexo BDD, la Guía de Implementación
Backend y las dos matrices que Kabeli devuelve.
