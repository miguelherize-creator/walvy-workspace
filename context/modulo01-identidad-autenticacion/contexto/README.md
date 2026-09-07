# M01 — Identidad, Autenticación y Onboarding

Índice del módulo. Todo lo de M01 que hay en el repo se enlaza desde acá — antes estaba
repartido en cinco carpetas y la mitad no figuraba en ningún índice.

**Módulos Nest:** `back-walvy/src/auth/` (14 endpoints, 7 suites) · `src/users/` (5
endpoints, 8 suites) · `src/imports/` (15 endpoints, pipeline de cartolas) ·
`src/health/` (el motor de diagnóstico del mes). **Front:** `expo/features/auth/`, 15
pantallas.

---

## 1 · Las puertas del onboarding · G0 → G5

**Es el corazón funcional del módulo** y lo que más se consulta. Un archivo por puerta:

| Puerta | Qué resuelve | Documento |
|---|---|---|
| G0 | Activación de la cuenta | [`../../specs/wiki/onboarding/requerimiento_por_puerta/G0-activacion.md`](../../specs/wiki/onboarding/requerimiento_por_puerta/G0-activacion.md) |
| G1 | Foco del Mes | [`G1-foco.md`](../../specs/wiki/onboarding/requerimiento_por_puerta/G1-foco.md) |
| G2 | Carga documental | [`G2-carga.md`](../../specs/wiki/onboarding/requerimiento_por_puerta/G2-carga.md) |
| G3 | Análisis | [`G3-analisis.md`](../../specs/wiki/onboarding/requerimiento_por_puerta/G3-analisis.md) |
| G4 | Revisión de suficiencia | [`G4-revision.md`](../../specs/wiki/onboarding/requerimiento_por_puerta/G4-revision.md) |
| G5 | Diagnóstico y semáforo | [`G5-diagnostico.md`](../../specs/wiki/onboarding/requerimiento_por_puerta/G5-diagnostico.md) |

Y además:

- [`flujo-documento-kread-g5.md`](../../specs/wiki/onboarding/requerimiento_por_puerta/flujo-documento-kread-g5.md) — el recorrido del documento desde la carga hasta el diagnóstico.
- [`diagramas-g0-g5.md`](../../specs/wiki/onboarding/diagramas-g0-g5.md) — los diagramas de las seis puertas.
- [`../../bitacora/2026-08-19-diagramas-g2-g5.md`](../../bitacora/2026-08-19-diagramas-g2-g5.md) — cómo se levantaron.

**En el código** las reglas de las puertas viven en `back-walvy/src/health/rules/`:
`sufficiency-gate.rule.ts`, `g5-month-signals.rule.ts`, `dominant-pressure.rule.ts` y
`monthly-focus-cta.rule.ts`, cada una con su `.spec.ts`.

## 2 · Cómo funciona

| Tema | Documento |
|---|---|
| Autenticación: registro, OTP, JWT, biometría | [`../../specs/authentication.md`](../../specs/authentication.md) |
| Navegación Splash → Onboarding | [`../../specs/auth-navigation-flows.md`](../../specs/auth-navigation-flows.md) |
| Onboarding / enrolment | [`../../specs/onboarding.md`](../../specs/onboarding.md) |
| Pantalla de análisis en curso | [`onboarding-analyzing-flow.md`](onboarding-analyzing-flow.md) |
| Integración onboarding ↔ backend | [`../utils/integracion-onboarding-backend.md`](../utils/integracion-onboarding-backend.md) |
| Perfil financiero y recurrentes vistos desde M01 | [`perfil-financiero-y-recurrentes.md`](perfil-financiero-y-recurrentes.md) |
| Contrato de auth Walvy ↔ Kread | [`contrato-walvy-kread-auth.md`](contrato-walvy-kread-auth.md) |
| El registro paso a paso, en árbol | [`../../qa-audits/auth/flujo_mod_1.txt`](../../qa-audits/auth/flujo_mod_1.txt) |
| Schema | [`../../db/modulo1.md`](../../db/modulo1.md) — ojo: documentación de diseño, ante discrepancia gana el código |

**Correo vs. usuario como identificador de acceso** —la lectura de negocio— está en
[`flujos-identificador-acceso-cliente.md`](flujos-identificador-acceso-cliente.md). El
`.md` es la fuente; el [`.html`](flujos-identificador-acceso-cliente.html) y el
[`.pdf`](flujos-identificador-acceso-cliente.pdf) son exportes para mandar al cliente y
se regeneran, no se editan.

## 3 · Pantallas

Especificación por pantalla en [`../../specs/wiki/pantallas/`](../../specs/wiki/pantallas/):
`splash` · `login` · `register` · `verify-code` · `confirm-account` · `choose-alias` ·
`biometric-setup` · `forgot-password` · `reset-password` · `onboarding` ·
`onboarding-foco` · `onboarding-doc` · `onboarding-analyzing` · `onboarding-analysis` ·
`onboarding-first-ready` · `tabs`.

Auditorías pixel-perfect en [`../../qa-audits/auth/`](../../qa-audits/auth/) y
[`../../qa-audits/onboarding/`](../../qa-audits/onboarding/). **La spec dice qué debe
hacer la pantalla; la auditoría dice qué tan lejos está de Figma.** Comparten nombre de
archivo a propósito.

## 4 · Deuda técnica

[`../deuda-tecnica/README.md`](../deuda-tecnica/README.md) — cuatro puntos, verificados
contra el código el 2026-09-06.
Integración con Kread: [`../deuda-tecnica/KREAD-INTEGRATION.md`](../deuda-tecnica/KREAD-INTEGRATION.md).

## 5 · Producto

- [`DudasModulo1.md`](DudasModulo1.md) — duda abierta con el PM: los 15 minutos de expiración del código de verificación.
- [`../../specs/wiki/onboarding/requerimientos_PM/`](../../specs/wiki/onboarding/requerimientos_PM/) — los requerimientos que llegaron de PM, en HTML.
- [`../../specs/wiki/onboarding/indice-documentacion-drive.md`](../../specs/wiki/onboarding/indice-documentacion-drive.md) — qué hay en Drive y qué está bajado.

## 6 · Entregables del cliente

`../../specs/wiki/onboarding/1. Entregables Walvy_Módulo 1/` — la Matriz de Trazabilidad
v2.6, la de Variantes de Validación y el PDF de la entrega. Los `.docx` y `.pdf` de M01 y
M02 están en `../../specs/wiki/onboarding/Modulo 1 y 2/`.

> Los entregables de M04 a M07 viven en `documentacion/`, **fuera** de este repo. Los de
> M01 y M02 quedaron adentro por razones históricas; es una incoherencia conocida.

## 7 · Histórico

En [`../../bitacora/`](../../bitacora/): el diagnóstico de onboarding (12-ago), las
puertas fuera del modelo (13-ago), el checklist pre-QA (21-ago), el refactor del
`AuthService`, el plan de onboarding del dev nuevo (29-ago) y el flujo G0 → perfil
financiero (30-ago). **Es histórico: describe lo que era cierto ese día.**

## 8 · Utils

[`../utils/integracion-onboarding-backend.md`](../utils/integracion-onboarding-backend.md).
