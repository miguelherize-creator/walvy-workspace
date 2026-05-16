# Tareas: Módulo de Deudas

> **Módulo:** `debts`
> **Última revisión:** 2026-05-14

---

## Backend

### [ ] Backend: crear DebtsModule con controller, service y DTOs

**Descripción:** Implementar el módulo completo de deudas. Las entidades ya existen en TypeORM.

**Pasos:**
1. Crear `src/debts/debts.module.ts` e importar en `AppModule`
2. Crear `DebtsController` con todos los endpoints del CRUD (ver `spec.md`)
3. Crear `DebtsService` con lógica de negocio (CRUD, pagos, soft delete)
4. Crear DTOs con validaciones class-validator:
   - `CreateDebtDto`: creditorName, currentBalance, interestRate, minimumPayment, payoffStrategy
   - `UpdateDebtDto`: todos los campos opcionales
   - `CreatePaymentDto`: amount, paymentDate, fundingSourceId, notes
5. Todos los endpoints con JWT guard y scope por userId
6. Al registrar un pago (`POST /debts/:id/payments`), actualizar `currentBalance` de la deuda

**Archivos a crear:**
- `src/debts/debts.module.ts`
- `src/debts/debts.controller.ts`
- `src/debts/debts.service.ts`
- `src/debts/dto/create-debt.dto.ts`
- `src/debts/dto/update-debt.dto.ts`
- `src/debts/dto/create-payment.dto.ts`

**Bloqueante:** No — puede iniciar cuando Sprint 4 inicie

---

### [ ] Backend: algoritmo snowball (minimum payment first, extra to lowest balance)

**Descripción:** Implementar el algoritmo Bola de Nieve como función pura en `src/debts/algorithms/snowball.algorithm.ts`.

**Contrato de la función:**
```typescript
export function calculateSnowball(
  debts: Array<{
    id: string;
    creditorName: string;
    currentBalance: number;
    interestRate: number;   // tasa anual en %
    minimumPayment: number;
  }>,
  monthlyExtraPayment: number
): {
  totalMonths: number;
  totalInterestPaid: number;
  projection: MonthlyProjection[];
}
```

**Pasos del algoritmo:**
1. Ordenar deudas por `currentBalance` ascendente (menor primero)
2. Cada mes: asignar `minimumPayment` a cada deuda, aplicar interés mensual (`tasa_anual / 12`)
3. El `monthlyExtraPayment` va íntegro a la deuda con menor saldo restante
4. Cuando una deuda llega a 0, su `minimumPayment` se acumula al extra del mes siguiente
5. Repetir hasta que todas las deudas estén en 0

**Archivos a crear:**
- `src/debts/algorithms/snowball.algorithm.ts`
- `src/debts/algorithms/snowball.algorithm.spec.ts` (tests unitarios)

**Bloqueante:** No — es lógica pura, sin dependencias externas

---

### [ ] Backend: algoritmo avalanche (minimum payment first, extra to highest rate)

**Descripción:** Implementar el algoritmo Avalanche como función pura en `src/debts/algorithms/avalanche.algorithm.ts`.

**Misma firma que snowball** pero con diferente lógica de ordenamiento:
- El `monthlyExtraPayment` va íntegro a la deuda con **mayor tasa de interés** (no menor saldo)
- Cuando una deuda con alta tasa se paga, el extra pasa a la siguiente de mayor tasa

**Archivos a crear:**
- `src/debts/algorithms/avalanche.algorithm.ts`
- `src/debts/algorithms/avalanche.algorithm.spec.ts` (tests unitarios)

**Bloqueante:** No

---

### [ ] Backend: endpoint POST /debts/simulate (retorna proyección mes a mes)

**Descripción:** Implementar el endpoint de simulación que aplica el algoritmo elegido a las deudas actuales del usuario.

**Pasos:**
1. Crear `PayoffService` que orqueste la simulación
2. Implementar `SimulatePayoffDto` con validaciones
3. El endpoint obtiene las deudas activas del usuario, aplica el algoritmo, retorna la proyección
4. Si `saveResult = true`, guardar en `DebtSnowballPlan`
5. Manejar el caso de usuario sin deudas (retornar respuesta vacía, no error)

**Archivos a crear:**
- `src/debts/payoff.service.ts`
- `src/debts/dto/simulate-payoff.dto.ts`

**Bloqueante:** Depende del algoritmo (tareas anteriores)

---

## Frontend

### [ ] Frontend: DebtScreen con lista y resumen

**Descripción:** Pantalla principal del módulo de deudas.

**Pasos:**
1. Crear `src/features/debts/api/debts.api.ts`
2. Crear hook `useDebts()`
3. Implementar `DebtScreen` con:
   - Resumen total: deuda total, interés promedio ponderado, cuota mínima mensual total
   - Lista de deudas activas con: nombre acreedor, saldo actual, cuota mínima, tasa
   - Botón "Agregar deuda"
   - Botón "Simular payoff" (navega a SimulationScreen)
   - Estado vacío con CTA motivacional

**Archivos afectados:**
- `src/features/debts/api/debts.api.ts` (nuevo)
- `src/features/debts/hooks/useDebts.ts` (nuevo)
- `src/features/debts/ui/DebtScreen.tsx` (nuevo)
- `src/features/debts/ui/DebtItem.tsx` (nuevo)

**Bloqueante:** No

---

### [ ] Frontend: AddDebtScreen

**Descripción:** Formulario para agregar una nueva deuda.

**Campos:**
- Nombre del acreedor (texto libre)
- Saldo actual (número, formato CLP)
- Tasa de interés anual (número con decimales, ej: 24.5)
- Cuota mínima mensual (número, formato CLP)
- Descripción (opcional)

**Archivos afectados:**
- `src/features/debts/ui/AddDebtScreen.tsx` (nuevo)
- `src/features/debts/hooks/useCreateDebt.ts` (nuevo)

**Bloqueante:** No

---

### [ ] Frontend: SimulationScreen (gráfico de payoff)

**Descripción:** Pantalla de simulación de estrategias de pago. Esta es la pantalla diferenciadora de Walvy.

**Pasos:**
1. Crear hook `useSimulatePayoff(strategy, monthlyExtra)`
2. Implementar `SimulationScreen` con:
   - Input/slider de "¿Cuánto puedes pagar extra por mes?" en CLP
   - Toggle snowball vs avalanche
   - Resultados: fecha de libertad financiera, total intereses pagados
   - Comparativa de ambas estrategias en pantalla dividida o tabs
   - Gráfico de línea: deuda total vs tiempo (usando `react-native-svg` o `victory-native`)
   - CTA "Adoptar estrategia" (guarda la preferencia)

**Archivos afectados:**
- `src/features/debts/ui/SimulationScreen.tsx` (nuevo)
- `src/features/debts/ui/PayoffChart.tsx` (nuevo — componente gráfico)
- `src/features/debts/hooks/useSimulatePayoff.ts` (nuevo)

**Bloqueante:** No (puede maquetarse con datos mock antes de que el backend esté listo)
