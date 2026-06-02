# Spec: Módulo de Presupuesto

> **Módulo:** `budget`
> **Sprint asociado:** Sprint 5
> **Estado:** Solo entidades TypeORM — sin módulo ni controller
> **Última revisión:** 2026-05-14

---

## 1. Propósito

El módulo de presupuesto permite al usuario planificar cuánto quiere gastar en cada categoría durante un mes. Al final del período, Walvy compara lo planeado con lo real, mostrando variaciones positivas (gastó menos de lo planeado) y negativas (se excedió).

**Para el PM:** El usuario define un presupuesto mensual por categoría (ej: "Alimentación: $200.000", "Transporte: $80.000"). A medida que registra gastos, puede ver en tiempo real cuánto lleva gastado vs cuánto planeó. Al cierre del mes, el sistema calcula si se excedió o si ahorró en cada categoría.

**Para el desarrollador:** El módulo tiene dos entidades principales: `BudgetPeriod` (el presupuesto de un mes para un usuario) y `BudgetLine` (asignación de monto por categoría dentro de ese período). El `actualAmount` en `BudgetLine` se actualiza automáticamente al registrar transacciones. El módulo aún no está implementado (solo existen las entidades en TypeORM).

---

## 2. Entidades en base de datos

### BudgetPeriod

Representa el presupuesto total de un usuario para un mes específico.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador |
| `userId` | UUID | Dueño del presupuesto |
| `year` | Integer | Año (ej: 2026) |
| `month` | Integer | Mes (1–12) |
| `status` | Enum | `draft`, `active`, `closed` |
| `totalIncome` | Decimal | Suma total de ingresos del período |
| `totalExpense` | Decimal | Suma total de gastos del período |
| `totalBalance` | Decimal | `totalIncome - totalExpense` |
| `createdAt` | Timestamp | Creación |
| `updatedAt` | Timestamp | Última actualización |

**Restricción:** Un usuario solo puede tener un `BudgetPeriod` por año/mes (`UNIQUE(userId, year, month)`).

### BudgetLine

Representa la asignación de presupuesto para una categoría específica dentro de un período.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador |
| `budgetPeriodId` | UUID | Referencia al período de presupuesto |
| `categoryId` | UUID | Categoría presupuestada |
| `plannedAmount` | Decimal | Monto planeado para la categoría |
| `actualAmount` | Decimal | Monto real gastado (actualizado automáticamente) |
| `variance` | Decimal | `plannedAmount - actualAmount` (positivo = ahorro, negativo = exceso) |

---

## 3. Endpoints a implementar (Sprint 5)

> Estos endpoints **no están implementados**. El módulo aún no existe en el backend.

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/budget/periods` | JWT | Crea un nuevo período de presupuesto |
| GET | `/budget/periods` | JWT | Lista períodos de presupuesto del usuario |
| GET | `/budget/periods/:id` | JWT | Detalle de un período con sus líneas |
| GET | `/budget/periods/current` | JWT | Período activo del mes actual |
| PUT | `/budget/periods/:id/lines/:categoryId` | JWT | Crea o actualiza línea de presupuesto |
| DELETE | `/budget/periods/:id/lines/:categoryId` | JWT | Elimina una línea de presupuesto |
| POST | `/budget/periods/:id/close` | JWT | Cierra un período (pasa a `closed`) |

---

## 4. Contratos de request/response (diseño preliminar)

### POST /budget/periods

**Request body:**
```json
{
  "year": "number (requerido)",
  "month": "number (1–12, requerido)"
}
```

**Response 201:**
```json
{
  "id": "uuid",
  "year": 2026,
  "month": 5,
  "status": "draft",
  "totalIncome": 0,
  "totalExpense": 0,
  "totalBalance": 0,
  "lines": []
}
```

---

### PUT /budget/periods/:id/lines/:categoryId

**Request body:**
```json
{
  "plannedAmount": "number (positivo, requerido)"
}
```

**Response 200:**
```json
{
  "categoryId": "uuid",
  "categoryName": "string",
  "plannedAmount": 200000,
  "actualAmount": 45000,
  "variance": 155000,
  "variancePercent": 77.5
}
```

---

### GET /budget/periods/:id — Response completo

```json
{
  "id": "uuid",
  "year": 2026,
  "month": 5,
  "status": "active",
  "totalIncome": 1500000,
  "totalExpense": 850000,
  "totalBalance": 650000,
  "lines": [
    {
      "categoryId": "uuid",
      "categoryName": "Alimentación",
      "plannedAmount": 200000,
      "actualAmount": 185000,
      "variance": 15000,
      "variancePercent": 7.5
    }
  ]
}
```

---

## 5. Lógica de actualización del actualAmount

Cuando se registra una transacción de tipo `expense`, el sistema debe actualizar automáticamente el `actualAmount` en la `BudgetLine` correspondiente (si existe un presupuesto activo para ese mes y categoría).

**Opciones de implementación (a decidir en Sprint 5):**

| Opción | Ventaja | Desventaja |
|--------|---------|------------|
| Trigger en `TransactionService` | Tiempo real, sin delay | Acoplamiento entre módulos |
| Job batch nocturno | Sin acoplamiento | Datos con retraso de hasta 24h |
| Evento asíncrono (EventEmitter) | Desacoplado y en tiempo real | Mayor complejidad |

---

## 6. Reglas de negocio

- Un usuario solo puede tener un período de presupuesto por año/mes
- Solo se puede agregar líneas a un período en estado `draft` o `active`
- Un período `closed` es de solo lectura
- El `variance` se calcula siempre como `plannedAmount - actualAmount`
- Variance positivo = el usuario gastó menos de lo planeado (bueno)
- Variance negativo = el usuario se excedió (alerta)
- Las líneas de presupuesto solo aplican a categorías de tipo `expense`

---

## 7. Estado actual

| Componente | Estado |
|------------|--------|
| Entidad `BudgetPeriod` en TypeORM | Existe |
| Entidad `BudgetLine` en TypeORM | Existe |
| `BudgetModule` | No existe |
| `BudgetController` | No existe |
| `BudgetService` | No existe |
| DTOs de presupuesto | No existen |
| Frontend budget | Placeholder (Sprint 5) |

**Prerequisito para Sprint 5:** Sprint 4 (cashflow frontend) completado, ya que el presupuesto consume datos de transacciones reales.
