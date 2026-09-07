> ⚠️ **Esto es Cashflow —movimientos e ingesta—, NO el M05 del cliente.** El M05 del
> cliente es **Presupuesto Vivo**: [`../../modulo05-presupuesto-vivo/`](../../modulo05-presupuesto-vivo/).
> El nombre de esta carpeta induce al error y está pendiente de renombrar.

# M5 — Cashflow (Catálogos, Ingesta y Movimientos)

Índice del módulo. La info canónica vive en `context/specs/` y `context/db/` (referenciados por el harness); acá se enlaza + se resume el modelo del resultado de cartola.

## Contexto — fuentes

| Tema | Fuente |
|---|---|
| Arquitectura y flujo de extracción de cartolas (Kread, reglas, V1/V2) | [`../../specs/cartola-extraction.md`](../../specs/cartola-extraction.md) |
| Spec de cashflow (movimientos, catálogos) | [`../../specs/cashflow.md`](../../specs/cashflow.md) |
| Schema / DB (Layers 7 Catálogos · 8 Ingesta · 9 Movimientos) | [`../../db/modulo5.md`](../../db/modulo5.md) |
| Módulos NestJS | `back-walvy/src/cashflow/` · `back-walvy/src/imports/` |

## Resultado de una cartola — modelo de datos (código real)

Pipeline en 3 etapas:
```
Archivo → StatementImport → ImportLineItem[] → Transaction[]
          (job)             (líneas extraídas)  (movimientos confirmados)
```

| Etapa | Entidad / tabla | Campos clave |
|---|---|---|
| Job | `StatementImport` / `statement_imports` | `fileKey`, `originalFilename`, `status`, `parsedAt`, `errorMessage` |
| Línea | `ImportLineItem` / `import_line_items` | `rawRow` (crudo banco), `normalized` (jsonb `NormalizedLine`), `userReviewStatus` |
| Movimiento | `Transaction` / `transactions` | ver abajo |

**`NormalizedLine`** (forma estructurada de cada movimiento, en `src/imports/kread/kread.mapper.ts`):
`occurredOn, amount, movementType('income'|'expense'), flowType('income'|'expense'|'fixed'|'variable'), description, category, subcategory, isTransfer, isAntExpense, classificationStatus, ruleMatched, docNumber, balance, branch, currency`.

**`RawRow`** (crudo del banco): `date, description, debit, credit, balance, movementType, docNumber, branch`. El banco da **debit/credit** → el mapper lo normaliza a **`movementType` income/expense** (ahí se resuelve ingreso vs egreso).

**`Transaction`** (movimiento confirmado) agrega: `flowType` (fixed/variable), `fundingSourceId` + `destinationFundingSourceId` (origen/destino), `categoryId` + `categoryLeafId`, `amount` (decimal 19,4), `occurredOn`, `bankDescription` (glosa original inmutable), `categorizationStatus`, `isAntExpense`.

**Enums**: `MovementType` (income/expense) · `FlowType` (fixed/variable) · `CategorizationStatus` (categorized/pending_review/uncategorized).

**Sugerencias de clasificación**: `MovementClassificationSuggestion` / `movement_classification_suggestions` (`suggested_target`, `confidence`, `rule_matched`, `user_decision`).

## Deuda técnica
Ver [`../deuda-tecnica/README.md`](../deuda-tecnica/README.md) — incluye el análisis del flujo cartola y el **desalineamiento doc↔código** de nombres de tablas.
