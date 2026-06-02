# Tareas: Sprint 4 — Cashflow Frontend

> **Módulo:** `cashflow`
> **Sprint:** Sprint 4
> **Última revisión:** 2026-05-14

---

## Frontend

### [ ] Feature/transactions: TransactionsScreen (lista)

**Descripción:** Pantalla principal de transacciones con lista paginada y filtros básicos.

**Pasos:**
1. Crear `src/features/cashflow/api/transactions.api.ts` con llamadas a los endpoints de transactions
2. Crear hook `useTransactions(filters?)` con TanStack Query (infinite scroll o paginación)
3. Implementar `TransactionsScreen` con:
   - Lista de transacciones agrupadas por fecha
   - Ícono de tipo (ingreso / gasto) con color diferenciado
   - Filtro rápido por mes
   - Pull-to-refresh
   - Estado vacío cuando no hay transacciones
4. Navegación al detalle al tocar una transacción

**Archivos afectados (Feature-First):**
- `src/features/cashflow/api/transactions.api.ts` (nuevo)
- `src/features/cashflow/hooks/useTransactions.ts` (nuevo)
- `src/features/cashflow/ui/TransactionsScreen.tsx` (nuevo)

**Bloqueante:** No

---

### [ ] Feature/transactions: CreateTransactionScreen

**Descripción:** Formulario para crear una nueva transacción.

**Pasos:**
1. Implementar `CreateTransactionScreen` con:
   - Selector tipo (Ingreso / Gasto) — toggle o botones
   - Campo monto (teclado numérico, formato CLP)
   - Campo fecha (date picker)
   - Campo descripción
   - Selector de categoría (abre `CategorySelectorModal`)
   - Selector de subcategoría (condicional, si la categoría tiene subcategorías)
   - Selector de fuente de fondos
2. Crear hook `useCreateTransaction()` con mutación TanStack Query
3. Validación de formulario antes de submit
4. Redirigir a lista tras creación exitosa, invalidar query cache

**Archivos afectados:**
- `src/features/cashflow/ui/CreateTransactionScreen.tsx` (nuevo)
- `src/features/cashflow/hooks/useCreateTransaction.ts` (nuevo)

**Bloqueante:** Depende de CategorySelectorModal y useFundingSources

---

### [ ] Feature/transactions: TransactionDetailScreen

**Descripción:** Pantalla de detalle de una transacción existente con opciones de editar y eliminar.

**Pasos:**
1. Implementar `TransactionDetailScreen` con visualización de todos los campos
2. Botón "Editar" — abre el formulario con los datos precargados
3. Botón "Eliminar" — confirmación modal + soft delete + volver a lista
4. Crear hook `useUpdateTransaction()` y `useDeleteTransaction()` con TanStack Query

**Archivos afectados:**
- `src/features/cashflow/ui/TransactionDetailScreen.tsx` (nuevo)
- `src/features/cashflow/hooks/useUpdateTransaction.ts` (nuevo)
- `src/features/cashflow/hooks/useDeleteTransaction.ts` (nuevo)

**Bloqueante:** No

---

### [ ] Frontend: selector de categorías (CategorySelectorModal)

**Descripción:** Modal reutilizable para seleccionar categoría y subcategoría al crear o editar una transacción.

**Pasos:**
1. Crear `src/features/cashflow/api/categories.api.ts` con llamada a `GET /cashflow/categories`
2. Crear hook `useCategories(type?)` — filtro por `income` o `expense` según el tipo de transacción
3. Implementar `CategorySelectorModal` con:
   - Lista de categorías globales y del usuario
   - Al seleccionar categoría, mostrar subcategorías si las tiene
   - Opción "Crear categoría" (navega a pantalla de creación)
4. El modal retorna `{ categoryId, subcategoryId }` al componente padre

**Archivos afectados:**
- `src/features/cashflow/api/categories.api.ts` (nuevo)
- `src/features/cashflow/hooks/useCategories.ts` (nuevo)
- `src/features/cashflow/ui/CategorySelectorModal.tsx` (nuevo)

**Bloqueante:** No

---

### [ ] Frontend: conectar home dashboard con datos reales

**Descripción:** Reemplazar los datos mock del home (`FinancialHealthRings`, `SummaryCarousel`) con datos reales del cashflow del mes actual.

**Pasos:**
1. Crear hook `useMonthSummary(year, month)` que consulte `GET /cashflow/transactions` con filtros de período
2. Calcular totales de ingresos y gastos del mes
3. Actualizar `FinancialHealthRings` para usar datos reales de salud financiera
4. Actualizar `SummaryCarousel` con ingresos y gastos reales del mes
5. Manejar estado de carga (skeleton) y estado vacío (primer uso sin transacciones)

**Archivos afectados:**
- `src/features/home/hooks/useMonthSummary.ts` (nuevo)
- `src/features/home/ui/FinancialHealthRings.tsx` (modificar para usar datos reales)
- `src/features/home/ui/SummaryCarousel.tsx` (modificar para usar datos reales)

**Bloqueante:** Requiere que la lista de transacciones esté implementada primero

---

## Backend

### [ ] Backend: unit tests TransactionsService

**Descripción:** Suite de tests unitarios para `TransactionsService`.

**Casos a cubrir:**
- Crear transacción con datos válidos
- Crear transacción con categoría global ajena retorna 403
- Soft delete marca `deletedAt` correctamente
- Listado no retorna transacciones con `deletedAt` poblado
- Filtros por tipo, fecha y categoría funcionan correctamente

**Archivos afectados:**
- `src/cashflow/transactions/transactions.service.spec.ts` (nuevo)

**Bloqueante:** No

---

### [ ] Backend: unit tests CategoriesService

**Descripción:** Suite de tests unitarios para `CategoriesService`.

**Casos a cubrir:**
- Listar categorías retorna globales + del usuario
- No se puede modificar una categoría global (retorna 403)
- No se puede eliminar categoría con transacciones asociadas (retorna 409)
- Crear categoría de usuario con datos válidos

**Archivos afectados:**
- `src/cashflow/categories/categories.service.spec.ts` (nuevo)

**Bloqueante:** No
