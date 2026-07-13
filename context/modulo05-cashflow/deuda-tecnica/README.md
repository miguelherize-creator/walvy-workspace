# M5 — Deuda técnica

No hay items `M5-DT` formalizados en [`../../debt.md`](../../debt.md). Deuda documentada del módulo:

- **Flujo Cartola / Statement Imports** → [`debt-cartola.md`](debt-cartola.md) (análisis del flujo completo de subida de documentos, 2026-06-17).

## Desalineamiento doc ↔ código (verificado)
`db/modulo5.md` documenta tablas con nombres que **no coinciden** con las entidades TypeORM reales — parece un schema de diseño/legacy:

| Doc (`db/modulo5.md`) | Entidad real |
|---|---|
| `financial_movement` (tabla central) | `transactions` |
| `file_upload` | `statement_imports` |
| `user_financial_instrument` | `funding_sources` |
| `movement_review_queue`, `movement_classification_history` | no existen (review en columnas + `movement_classification_suggestions`) |

Al trabajar M5, la fuente de verdad del schema son las **entidades** (`src/cashflow/`, `src/imports/`), no `db/modulo5.md`.
