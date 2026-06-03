# Spec: Presupuestos

**Estado backend:** ⚠️ Schema DB listo — módulo NestJS pendiente  
**Estado frontend:** ❌ Pendiente — Sprint 5 (`features/budget/`)  
**Módulo NestJS:** `src/budget/` (por crear)

---

## Concepto
El usuario define un presupuesto mensual por categoría. El sistema trackea el gasto real vs lo presupuestado y alerta cuando se acerca o supera el límite.

## Endpoints (a implementar)

```
GET    /budget/plans                    → planes del usuario (historial por mes)
POST   /budget/plans                    → crear plan para un mes
GET    /budget/plans/:id                → detalle con progreso real
PATCH  /budget/plans/:id                → editar montos del plan
DELETE /budget/plans/:id                → eliminar plan del mes

GET    /budget/plans/:id/items          → items del plan (por categoría)
POST   /budget/plans/:id/items          → agregar categoría al plan
PATCH  /budget/plans/:id/items/:itemId  → editar monto de una categoría
DELETE /budget/plans/:id/items/:itemId  → quitar categoría del plan
```

## Contratos propuestos

### POST /budget/plans
```json
// Request
{ "month": "2026-07",
  "items": [
    { "categoryId": "uuid-alimentacion", "amount": 200000 },
    { "categoryId": "uuid-transporte", "amount": 80000 }
  ] }
// Response 201 → plan creado con status "active"
// Error: 409 ya existe plan para ese mes
```

### GET /budget/plans/:id (con progreso)
```json
// Response 200
{ "id": "uuid", "month": "2026-07", "status": "active",
  "items": [
    { "categoryId": "uuid", "categoryName": "Alimentación",
      "planned": 200000, "spent": 145000, "percentage": 72.5,
      "status": "on_track" }   // on_track | warning | exceeded
  ],
  "totalPlanned": 280000, "totalSpent": 145000 }
```

## Reglas de negocio
- Solo un plan activo por mes por usuario
- `spent` se calcula en tiempo real consultando `financial_movement` del período
- Umbrales de alerta: `warning` a 80% · `exceeded` a 100%
- El plan puede incluir cualquier subconjunto de categorías (no todas son obligatorias)
- Meses pasados quedan con `status = closed`, no editables

## Frontend — checklist Sprint 5
```
□ features/budget/data/BudgetRepository.ts
□ features/budget/hooks/useBudgetPlans.ts
□ features/budget/hooks/useCreateBudget.ts
□ features/budget/ui/BudgetScreen.tsx
□ features/budget/ui/CreateBudgetScreen.tsx
□ api/mocks/budgetMock.ts
□ app/(tabs)/budget.tsx (delegate)
```

## Tablas involucradas
`budget_plan` · `budget_plan_item` · `category` · `financial_movement`
