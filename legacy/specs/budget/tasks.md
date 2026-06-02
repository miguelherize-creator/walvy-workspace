# Tareas: Sprint 5 — Módulo de Presupuesto

> **Módulo:** `budget`
> **Sprint:** Sprint 5
> **Prerequisito:** Sprint 4 completado
> **Última revisión:** 2026-05-14

---

## Backend

### [ ] Backend: crear BudgetModule con controller, service y DTOs

**Descripción:** Implementar el módulo completo de presupuesto. Las entidades `BudgetPeriod` y `BudgetLine` ya existen en TypeORM; se necesita el módulo de NestJS y toda la lógica de negocio.

**Pasos:**
1. Crear `src/budget/budget.module.ts` e importar en `AppModule`
2. Crear `BudgetController` con todos los endpoints definidos en `spec.md`
3. Crear `BudgetService` con los métodos del plan
4. Crear DTOs con validaciones class-validator:
   - `CreateBudgetPeriodDto`: year, month (validar 1–12)
   - `UpdateBudgetLineDto`: plannedAmount (positivo)
5. Agregar el guard JWT a todos los endpoints
6. Todos los endpoints deben retornar solo datos del usuario autenticado (no exponer datos de otros usuarios)

**Archivos a crear:**
- `src/budget/budget.module.ts`
- `src/budget/budget.controller.ts`
- `src/budget/budget.service.ts`
- `src/budget/dto/create-budget-period.dto.ts`
- `src/budget/dto/update-budget-line.dto.ts`

**Bloqueante:** No — puede iniciar en Sprint 5

---

### [ ] Backend: lógica de cálculo de variance (plannedAmount - actualAmount)

**Descripción:** Implementar el cálculo de `variance` en `BudgetLine`. El campo debe calcularse automáticamente al leer los datos; no debe almacenarse estáticamente sino derivarse.

**Opciones:**
- Campo calculado en el DTO de respuesta (no en DB): calcular en el service al construir la respuesta
- Campo calculado en TypeORM como columna virtual

**Recomendación:** Calcular en el service al construir la respuesta, no guardar en DB (evita inconsistencias).

**Fórmula:**
```
variance = plannedAmount - actualAmount
variancePercent = ((plannedAmount - actualAmount) / plannedAmount) * 100
```

**Archivos afectados:**
- `src/budget/budget.service.ts` (al construir respuesta de líneas)

**Bloqueante:** No

---

### [ ] Backend: job/trigger para actualizar actualAmount desde transactions

**Descripción:** Implementar el mecanismo que actualiza el `actualAmount` en `BudgetLine` cuando se registra, modifica o elimina una transacción de tipo `expense`.

**Decisión de diseño a tomar al iniciar Sprint 5:**
- **Opción A (recomendada):** `EventEmitter2` — `TransactionService` emite `transaction.created`, `BudgetService` escucha y actualiza
- **Opción B (simple/acoplada):** `TransactionService` llama directamente a `BudgetService`
- **Opción C (batch):** Job nocturno que recalcula actualAmount para todos los períodos activos

**Independiente de la opción:** Considerar los casos de:
- Crear transacción → sumar al actualAmount
- Actualizar transacción → recalcular (puede cambiar monto, categoría o fecha)
- Eliminar transacción (soft delete) → restar del actualAmount

**Archivos afectados:**
- `src/cashflow/transactions/transactions.service.ts` (agregar emisión de evento)
- `src/budget/budget.service.ts` (agregar listener o método de actualización)
- `src/budget/budget.module.ts` (registrar EventEmitter si se elige Opción A)

**Bloqueante:** Sí — sin esto el `actualAmount` siempre queda en 0

---

## Frontend

### [ ] Frontend: BudgetScreen con breakdown por categoría

**Descripción:** Pantalla principal del módulo de presupuesto.

**Pasos:**
1. Crear `src/features/budget/api/budget.api.ts`
2. Crear hooks `useBudgetPeriod(year, month)` y `useCurrentBudgetPeriod()`
3. Implementar `BudgetScreen` con:
   - Header con mes/año y balance total
   - Lista de líneas de presupuesto por categoría
   - Barra de progreso por categoría (actualAmount / plannedAmount)
   - Color de barra: verde si < 80%, naranja si 80–100%, rojo si > 100%
   - Estado vacío si no hay presupuesto activo (mostrar CTA "Crear presupuesto")
4. Pull-to-refresh

**Archivos afectados:**
- `src/features/budget/api/budget.api.ts` (nuevo)
- `src/features/budget/hooks/useBudgetPeriod.ts` (nuevo)
- `src/features/budget/ui/BudgetScreen.tsx` (nuevo)
- `src/features/budget/ui/BudgetLineItem.tsx` (nuevo — componente de categoría)

**Bloqueante:** No (puede maquetarse con MockService antes de que el backend esté listo)

---

### [ ] Frontend: mockService para desarrollo y modo offline

**Descripción:** Crear datos mock del módulo de presupuesto para permitir desarrollo frontend independiente del backend y para tests.

**Pasos:**
1. Crear `src/features/budget/data/mock-budget.data.ts` con un período de ejemplo y líneas de categorías
2. Crear `useMockBudgetPeriod()` que retorne los datos mock con el mismo shape que el hook real
3. Los componentes de UI deben funcionar con ambos hooks (real y mock) sin modificaciones

**Archivos afectados:**
- `src/features/budget/data/mock-budget.data.ts` (nuevo)

**Bloqueante:** No

---

### [ ] Tests e2e budget endpoints

**Descripción:** Suite de tests e2e para los endpoints del módulo de presupuesto.

**Casos mínimos:**
- Crear período de presupuesto
- No se puede crear un segundo período para el mismo mes
- Agregar línea de presupuesto a un período
- `actualAmount` se actualiza al crear una transacción de esa categoría
- Cerrar período pasa a estado `closed`
- No se puede modificar un período `closed`

**Archivos afectados:**
- `test/budget/budget.e2e-spec.ts` (nuevo)

**Bloqueante:** No (post implementación)
