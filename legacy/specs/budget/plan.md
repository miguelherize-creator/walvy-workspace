# Plan Sprint 5: Módulo de Presupuesto

> **Módulo:** `budget`
> **Sprint:** Sprint 5
> **Prerequisito:** Sprint 4 (cashflow frontend) completado
> **Última revisión:** 2026-05-14

---

## 1. Prerequisito: Sprint 4 completado

El módulo de presupuesto **no puede implementarse** sin que el cashflow esté funcionando en el frontend. Las razones son:

1. El presupuesto muestra el `actualAmount` de cada categoría, que proviene de las transacciones reales del usuario
2. La lógica de actualización del `actualAmount` depende del `TransactionService`
3. El usuario necesita poder crear transacciones antes de tener sentido ver un presupuesto
4. El selector de categorías de presupuesto es el mismo que el de transacciones

---

## 2. Backend a implementar

### BudgetModule

Crear el módulo completo desde cero. Las entidades ya existen; se necesita el módulo, controller, service y DTOs.

**Estructura a crear:**
```
src/budget/
  ├── budget.module.ts
  ├── budget.controller.ts
  ├── budget.service.ts
  └── dto/
      ├── create-budget-period.dto.ts
      ├── update-budget-line.dto.ts
      └── budget-period-response.dto.ts
```

### BudgetService — métodos principales

| Método | Descripción |
|--------|-------------|
| `createPeriod(userId, year, month)` | Crea período de presupuesto |
| `getPeriods(userId)` | Lista períodos del usuario |
| `getCurrentPeriod(userId)` | Período del mes actual |
| `getPeriodWithLines(userId, id)` | Detalle con líneas y varianzas |
| `upsertLine(userId, periodId, categoryId, plannedAmount)` | Crea o actualiza línea |
| `deleteLine(userId, periodId, categoryId)` | Elimina línea |
| `closePeriod(userId, id)` | Cierra el período |
| `updateActualAmount(userId, categoryId, amount, date)` | Actualiza actualAmount (llamado por TransactionService) |

### Lógica de actualización del actualAmount

Decisión de diseño a tomar en Sprint 5. La opción recomendada es **evento asíncrono** via `EventEmitter2` de NestJS:

1. `TransactionService` emite evento `transaction.created` al crear una transacción de tipo `expense`
2. `BudgetService` escucha el evento y actualiza el `actualAmount` en la `BudgetLine` correspondiente
3. Ventaja: sin acoplamiento directo entre módulos

**Alternativa simple para MVP:** Llamada directa de `TransactionService` a `BudgetService` al crear/actualizar/eliminar transacciones. Más simple, pero crea acoplamiento.

---

## 3. Frontend a implementar

Arquitectura Feature-First siguiendo el patrón establecido:

```
src/features/budget/
  ├── api/
  │   └── budget.api.ts
  ├── hooks/
  │   ├── useBudgetPeriod.ts
  │   ├── useCreateBudgetPeriod.ts
  │   └── useUpdateBudgetLine.ts
  └── ui/
      ├── BudgetScreen.tsx         (pantalla principal con resumen)
      ├── BudgetLineItem.tsx       (componente de categoría con barra de progreso)
      ├── SetBudgetScreen.tsx      (formulario para definir presupuesto del mes)
      └── BudgetCategoryModal.tsx  (modal para editar el monto de una categoría)
```

### BudgetScreen — componentes principales

- **Resumen del mes:** Balance total, total ingresos vs gastos
- **Breakdown por categoría:** Lista de `BudgetLine` con:
  - Nombre de categoría
  - Barra de progreso (actualAmount / plannedAmount)
  - Monto planeado vs real
  - Variance coloreado (verde = ahorro, rojo = exceso)
- **Botón "Definir presupuesto"** si no existe período activo

---

## 4. Modo offline / MockService

El módulo de presupuesto debe incluir un `MockBudgetService` para:
- Tests unitarios (sin conexión a DB)
- Modo offline en el frontend (datos hardcodeados para demo)
- Desarrollo frontend antes de que el backend esté completo

```typescript
// src/features/budget/data/mock-budget.data.ts
export const MOCK_BUDGET_PERIOD = { ... }
```

---

## 5. Alertas de presupuesto (post-Sprint 5)

Una vez implementado el módulo, se pueden agregar alertas cuando el usuario llega al 80% del presupuesto de una categoría. Requiere M2-DT-03 (alertas) y M2-DT-04 (worker notificaciones).

---

## 6. Dependencias

| Item | Depende de | Estado |
|------|------------|--------|
| BudgetModule backend | Entidades ya existen | Listo para implementar |
| Frontend budget | Backend implementado | Bloqueado hasta Sprint 5 |
| actualAmount en tiempo real | Decisión: trigger vs evento vs job | A decidir Sprint 5 |
| Alertas de presupuesto | M2-DT-03 + M2-DT-04 | Backlog |
| Tests e2e budget | Backend + Frontend | Post Sprint 5 |

---

## 7. Estimación Sprint 5

| Tarea | Estimación |
|-------|------------|
| BudgetModule backend (controller, service, DTOs) | 2-3 días |
| Lógica de varianza y actualAmount | 1 día |
| Frontend BudgetScreen | 2 días |
| Frontend SetBudgetScreen + modal | 1 día |
| Tests unitarios backend | 1 día |
| Tests e2e (mínimo) | 1 día |
| **Total estimado** | **8-9 días** |
