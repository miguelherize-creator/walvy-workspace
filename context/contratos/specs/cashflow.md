# Spec: Cashflow (Movimientos)

**Estado backend:** ✅ Completo — **16 endpoints en tres controllers**
**Estado frontend:** ❌ Pendiente · `features/transactions/` no existe y `(tabs)/movimientos.tsx` es un stub de «Próximamente»
**Módulo NestJS:** `src/cashflow/`

> ⚠️ **Las rutas de abajo no son las reales · corregido el 2026-09-06.** Este documento
> declara `/cashflow/movements` y derivados; el módulo **no monta nada bajo `/cashflow`**.
> Las rutas vigentes, verificadas en los controllers:
>
> | Controller | Base | Endpoints |
> |---|---|---|
> | `transactions.controller.ts` | `/transactions` | `GET` · `GET /:id` · `POST` · `PATCH /:id` · `DELETE /:id` |
> | `funding-sources.controller.ts` | `/funding-sources` | `GET` · `GET /:id` · `POST` · `PATCH /:id` · `DELETE /:id` |
> | `categories.controller.ts` | `/categories` | `GET /with-subcategories` · `GET` · `GET /:id` · `POST` · `PATCH /:id` · `DELETE /:id` |
>
> El front ya apunta bien: `expo/api/endpoints.ts` tiene `transactions.base = "/transactions"`.
> Lo que sigue abajo describe el **modelo funcional**, que es útil; los paths, no.
>
> **El contrato de categorías lo gobierna M05** —la taxonomía v2.7, 20 maestras y 105
> subcategorías, en `documentacion/Módulo05/Categorias/`— y lo consumen `front-walvy` y
> Kread. No se cambia sin coordinar.

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
