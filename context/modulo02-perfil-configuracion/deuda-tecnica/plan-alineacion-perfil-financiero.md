# Plan de acción — alineación Perfil Financiero

Última actualización: 2026-07-08
Basado en: `contexto/alineacion-perfil-financiero-vs-spec.md`
Objetivo: separar **lo que se arregla ya en backend** (sin bloqueo) de **lo que espera decisión de Producto**.

---

## 🔎 Hallazgo crítico que reordena las prioridades

**Los "pagos recurrentes" NO están implementados en ninguna punta:**
- Backend `mapper` (`kread.mapper.ts:172`): `isAntExpense` se hardcodea a **`false`** siempre.
- Frontend (`calcMetrics`): `topRecurrentes = isAntExpense === true` → **siempre vacío**.
- Backend `/summary`: `hasRecurringPayments` = alias de `hasFixedExpenses` → **falso positivo** (marca `true` con cualquier gasto fijo, que son compromisos base, no recurrentes).

Resultado: hoy la app muestra el flag `hasRecurringPayments=true` (por el alias) pero la lista de recurrentes está vacía. Es inconsistente y viola la regla del cliente (compromisos ≠ recurrentes).

---

## Track A — Se puede hacer YA en backend (sin bloqueo de Producto)

| P | Acción | Archivo | Esfuerzo | Nota |
|---|--------|---------|----------|------|
| **P0** | Dejar de reportar `hasRecurringPayments` como alias de `fixed`. Interino: derivarlo de `isAntExpense` (queda coherente con el frontend) **o** marcarlo explícitamente como no-implementado hasta cerrar la regla. | `statement-import.service.ts` (getImportSummary) | S | Quita el falso positivo. La versión "real" (Top 5 con recurrencia) es Track B. |
| **P1** | Exponer **contador de sin-categorizar** en `/summary` (líneas `pending_review`). Hoy solo hay `hasRecentMovements` (líneas>0). | `statement-import.service.ts` | S | La spec pide contador (indicador #4). Dato ya existe (`/lines/pending`). |
| **P1** | Renombrar/clarificar `hasPaymentInstruments` (hoy = "hay egresos", no detecta instrumentos). Mínimo documentar; ideal mover la heurística de instrumentos (hoy solo en front) al backend. | `statement-import.service.ts` / mapper | M | Alinea el indicador #5; unifica la lógica en un solo lado. |
| **P2** | Guard defensivo: si `DYNAMO_ENABLED=true` pero falta table name, warning al arrancar en vez de `ValidationException` opaco. | `dynamo-*.service.ts` | S | Robustez operativa (visto en el server). |

> **S** = ~1h, **M** = medio día.

---

## Track B — Bloqueado en decisión de Producto (llevar a reunión)

Cada uno está marcado **Pendiente** en la propia doc del cliente. No tocar código hasta cerrarlos.

| Indicador | Pregunta cerrada para Producto | Desbloquea |
|-----------|-------------------------------|------------|
| **Ingreso principal** | ¿Regla de desempate con múltiples fuentes? (¿suma? ¿la mayor? ¿prioridad sueldo>pensión>honorarios>transferencia?) ¿Se expone el tipo/origen? | Ampliar `SALARY_SUBCATEGORIES` + devolver tipo de ingreso |
| **Pagos recurrentes** | Regla técnica de recurrencia: ¿frecuencia mínima? ¿ventana de meses? ¿tolerancia de monto/comercio? | Implementar detección real + Top 5 con % sobre ingreso |
| **Movimientos sin categorizar** | Umbral del nivel **medio** (C-02 "pide validación"). Hoy solo hay alta/baja (≥0.7 / resto). | 3er nivel de certeza en `resolveStatus` |
| **Instrumentos** | Regla de agregación cuando el mismo instrumento aparece en varios documentos. | Detección backend robusta |
| **Badge completitud** | Umbrales alto/medio/bajo. | Indicador de confianza |
| **Semáforo Home** | Combinación multi-señal (pagos próximos + fugas + presupuesto + Salud de Deuda) y regla de señal dominante. | Semáforo real de Home (hoy solo hay un ratio por cartola) |

---

## Orden sugerido

1. **P0 backend** — matar el falso positivo de `hasRecurringPayments` (1 línea + decisión interina).
2. **Reunión con Producto** — cerrar las 6 preguntas del Track B (sobre todo recurrencia e ingreso principal, que son los que más se ven en UI).
3. **P1 backend** — contador de sin-categorizar + clarificar instrumentos, una vez sepamos si la heurística vive en back o front.
4. **Track B por prioridad de UI** — recurrentes (Top 5) e ingreso principal primero; completitud y semáforo Home después.

---

## Aclaración de alcance

El `semaforo` de `/summary` (ratio ingreso/gasto por cartola, umbrales 0.80/1.0 que **inventamos**) **no es** el semáforo de Home de la spec. Son dos cosas: dejar el de `/summary` como diagnóstico local documentado, y tratar el de Home como feature aparte (Track B).
