# M02 — Perfil Financiero y Configuración

Índice del módulo. Antes listaba dos documentos; el resto del contenido de M02 estaba en
el repo sin figurar en ningún índice.

**Módulos Nest:** `back-walvy/src/profile/` (4 endpoints, 2 suites) ·
`src/notifications/` (7 endpoints). **Front:** `expo/features/profile/`, 6 pantallas.

> **La suscripción no es de M02.** En la app la pantalla vive dentro de
> Perfil/Configuración, pero el dominio es **M10 — Monetización**:
> [`../../modulo10-monetizacion/contexto/README.md`](../../modulo10-monetizacion/contexto/README.md).

---

## 1 · Cómo funciona

| Tema | Documento |
|---|---|
| Perfil financiero: el modelo y sus reglas | [`perfil-financiero.md`](perfil-financiero.md) |
| Perfil financiero: código vs. especificación | [`alineacion-perfil-financiero-vs-spec.md`](alineacion-perfil-financiero-vs-spec.md) |
| Perfil de usuario: endpoints y flujos | [`../../specs/user-profile.md`](../../specs/user-profile.md) |
| Notificaciones push: requerimiento | [`req-push-notifications.md`](req-push-notifications.md) |
| Schema | [`../../db/modulo2.md`](../../db/modulo2.md) — documentación de diseño; ante discrepancia gana el código |

Reglas de alineación del perfil financiero enviadas por el cliente:
[`../Walvy_Perfil_Financiero_Reglas_Alineacion_v1_0.docx`](../Walvy_Perfil_Financiero_Reglas_Alineacion_v1_0.docx).
La especificación UX consolidada está en
`../../specs/wiki/onboarding/Modulo 1 y 2/Walvy_Especificacion_UX_Perfil_Financiero_v1.0_consolidado.pdf`.

## 2 · Lo que M02 lee y no calcula

La tabla `user_financial_profile` es de M02, pero **no todas sus columnas las escribe
M02**:

| Bloque | Lo escribe | M02 hace |
|---|---|---|
| Perfil declarado: ingreso, gastos fijos, metas | M02 | Escribe y lee |
| `route_*` — elegibilidad, estado y momento de Ruta | **M04** | Sólo lee y representa |
| `debt_health_*` — Salud de Deuda | **M04** | Sólo lee y representa |
| Suficiencia del mes y CTA dominante | **M01**, en `user_month_diagnosis_summary` | Sólo lee |

Es la costura más cargada del sistema. Está en
[`../../wiki-codigo/integracion-modulos.md`](../../wiki-codigo/integracion-modulos.md),
y el contrato de lo que M04 publica en
`back-walvy/docs/api/debts/ruta-despeje.md`.

**Si M02 endurece esa tabla, lo primero que hay que revisar es la escritura de M04.**

## 3 · Foco del Mes

Se elige en M02 y lo consume M01 en la puerta G1. El requerimiento de estados está en
[`../../specs/wiki/onboarding/requerimientos_PM/REQ_G1_Regla_Estados_Foco_del_Mes_Walvy_v1.0.html`](../../specs/wiki/onboarding/requerimientos_PM/REQ_G1_Regla_Estados_Foco_del_Mes_Walvy_v1.0.html),
la regla de priorización del CTA en
`../../specs/wiki/onboarding/Modulo 1 y 2/Walvy_Regla_Priorizacion_CTA_por_Foco_Mes_v1_0.docx`,
y el «Léeme» del cliente en el mismo directorio.

Auditoría de la pantalla: [`../../qa-audits/profile/mi-foco-del-mes.md`](../../qa-audits/profile/mi-foco-del-mes.md).

## 4 · Pantallas

Auditorías pixel-perfect en [`../../qa-audits/profile/`](../../qa-audits/profile/):
`mi-perfil-hub` · `mis-datos` · `mi-foco-del-mes` · `change-password` ·
`profile-photo-modal`.

## 5 · Deuda técnica

[`../deuda-tecnica/README.md`](../deuda-tecnica/README.md) — cuatro puntos, verificados
contra el código el 2026-09-06.
Plan de alineación del perfil financiero: [`../deuda-tecnica/plan-alineacion-perfil-financiero.md`](../deuda-tecnica/plan-alineacion-perfil-financiero.md).

## 6 · Histórico

En [`../../bitacora/`](../../bitacora/): la revisión del router de profile (14-ago) y el
flujo G0 → perfil financiero (30-ago). Es histórico y no se actualiza.
