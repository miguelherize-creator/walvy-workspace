# Spec: Cashflow (Movimientos)

**Estado backend:** ✅ Completo  
**Estado frontend:** ❌ Pendiente — Sprint 4 (`features/transactions/`)  
**Módulo NestJS:** `src/cashflow/`

---

## Endpoints

```
MOVIMIENTOS
  GET    /cashflow/movements              → lista con filtros (paginado)
  POST   /cashflow/movements              → crear movimiento manual
  GET    /cashflow/movements/:id          → detalle
  PATCH  /cashflow/movements/:id          → editar
  DELETE /cashflow/movements/:id          → soft delete

CATEGORÍAS
  GET    /cashflow/categories             → lista (sistema + propias del usuario)
  POST   /cashflow/categories             → crear categoría custom
  PATCH  /cashflow/categories/:id         → editar (solo propias)
  DELETE /cashflow/categories/:id         → eliminar (solo propias)

SUBCATEGORÍAS / NODOS
  GET    /cashflow/categories/:id/nodes   → nodos del árbol de una categoría
  POST   /cashflow/nodes                  → crear nodo custom

FUENTES DE FONDOS
  GET    /cashflow/funding-sources        → instituciones financieras vinculadas
  POST   /cashflow/funding-sources        → vincular cuenta/tarjeta

IMPORTACIÓN
  POST   /cashflow/import                 → subir PDF/CSV de movimientos
  GET    /cashflow/import/:id/status      → estado del procesamiento
  PATCH  /cashflow/import/:id/lines/:lineId → reclasificar línea importada
```

## Contratos clave

### GET /cashflow/movements
```
Query params: page, limit, from (date), to (date), categoryId, type (income|expense), search
Response 200: { data: Movement[], total, page, limit }
```

### POST /cashflow/movements
```json
// Request
{ "amount": 50000, "type": "expense", "categoryId": "uuid",
  "cashflowNodeId": "uuid", "description": "Almuerzo trabajo",
  "movementDate": "2026-06-01", "fundingSourceId": "uuid" }
// Response 201 → movimiento creado
// Error: 400 categoryId no pertenece al usuario · 422 amount ≤ 0
```

### DELETE /cashflow/movements/:id
- Soft delete: marca `deleted_at`. Nunca DELETE físico.
- 403 si el movimiento pertenece a otro usuario.

## Estructura de categorías
```
category (sistema o del usuario)
  └── cashflow_node (subcategoría / nodo del árbol)
        └── financial_movement
```
- Categorías de sistema: `is_system = true`, no editables
- Categorías del usuario: `user_id = usuario`, editables y eliminables
- Un movimiento referencia tanto `category_id` como `cashflow_node_id`

## Reglas de negocio
- `amount` siempre positivo — el campo `type` determina si es ingreso o gasto
- `movementDate` puede ser pasada o presente, no futura
- La deduplicación de movimientos importados usa hash del contenido
- `source`: `manual` (usuario) | `import` (PDF/CSV) | `api` (futuro Open Banking)

## Frontend — checklist Sprint 4
```
□ features/transactions/data/TransactionsRepository.ts
□ features/transactions/hooks/useTransactions.ts   (lista + filtros)
□ features/transactions/hooks/useCreateMovement.ts
□ features/transactions/hooks/useEditMovement.ts
□ features/transactions/ui/TransactionsScreen.tsx
□ features/transactions/ui/CreateMovementScreen.tsx
□ api/mocks/transactionsMock.ts
□ app/(tabs)/transactions.tsx (delegate)
```

## Tablas involucradas
`financial_movement` · `category` · `cashflow_node` · `financial_institution` · `file_upload` · `import_line_items` · `movement_review_queue`
