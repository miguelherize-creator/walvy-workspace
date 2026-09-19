# G5 — 3 señales: catálogo vs disparadores (alcance parcial)

**Fecha:** 2026-08-24  
**Estado:** Catálogo **cerrado** (11 estados). Disparadores de `observation`, `leaks_detected`, `needs_attention` y el set extra de `high` **abiertos**. Motor no inventa umbrales (PM G5 §16 / Fase 3).  
**Motor:** `g5_signals_v1` · PR [back-walvy#133](https://github.com/KabeliDev/back-walvy/pull/133)  
**Wiki:** `specs/wiki/onboarding/requerimiento_por_puerta/G5-diagnostico.md` § Señales + § Alcance implementado vs soporte parcial.

No tratar “no se emite hoy” como “el estado no está definido”. Usar `mvp_scope_status`: `supported` / `partially_supported` / `pending_mvp_validation`.

---

## Supported (se emite)

| Señal | Estado | Disparador vivo |
|---|---|---|
| Margen | `healthy` / `adjusted` / `pressured` | M1-DP-006: ratio &lt; 0.90 / [0.90, 1) / ≥ 1.00 |
| Compromisos | `under_control` | Default si no hay mora confirmada |
| Compromisos | `high` | Solo mora confirmada — **recorte técnico**, no la RN completa |
| Movimientos | `no_relevant_alerts` / `pending_review` | Default / no categorizados |

Semáforo: `in_control` · `attention` · `risk` · `no_diagnosis`. Nunca `null`. Falta de datos ≠ Riesgo. Una presión, un CTA.

---

## Partially supported / pending — no hardcodear

| Estado | Documentado | Hoy | Pregunta a Producto |
|---|---|---|---|
| Margen `observation` | Seguimiento, sin presión crítica. El estado **existe**. | No se emite | Evidencia vs `healthy` (`adjusted` ya arranca en 0.90). ¿Cambia el semáforo o solo la señal? No sacar del contrato. |
| Compromisos `observation` | Compromisos o pagos recurrentes a revisar. Recurrencias relevantes pueden explicar Atención. | No se emite. Sin mora = siempre `under_control`. | Evidencia concreta. |
| Compromisos `high` extra | Presionan el mes o explican Riesgo. **No es solo mora.** No copiar M04 a G5. | Solo mora | Lista cerrada de señales G5 adicionales. ¿Alguna basta para Riesgo? |
| Movimientos `leaks_detected` | Atención, `attention_leaks_detected`, SEM-03. Sin job ≠ fuera de v1. | No se emite | ¿Operativo M1 v1 o `partially_supported` / `pending_mvp_validation`? Si v1: definición y dueño del cálculo. |
| Movimientos `needs_attention` | Distinto de `pending_review`. | No se emite | Disparador. No unificar con no-categorizados. |

Al cerrar disparadores de señal: `g5_signals_v1` → `g5_signals_v2`.

---

## Escenario `attention_adjusted_margin` (2026-08-24)

Semáforo Atención + 3 señales de este caso: **cerrados**. Presión, CTA, copy y destino: **parciales**. El mapeo actual **no es RN**.

Fallback técnico (llenar contrato, no causa documental): `dominant_pressure_code = recurring_payments`, `dominant_cta = adjust_budget`, copy de recurrentes. No interpretar como “los recurrentes explican el ajuste”. No usar `margin_compromised`.

Consulta a Producto: (1) código de presión para este escenario sin otra causa; (2) cómo materializar `revisar_senal_principal` sin `review_margin`; (3) copy solo de margen; (4) destino v1. Wiki: `G5-diagnostico.md` § escenario `attention_adjusted_margin`.
