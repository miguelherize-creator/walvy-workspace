# Plan de Implementación: Motor de Deudas

> **Módulo:** `debts`
> **Diferenciador:** Motor snowball/avalanche es un feature clave de Walvy
> **Última revisión:** 2026-05-14

---

## 1. Prerequisito: Sprint 4 (cashflow)

El módulo de deudas **depende de cashflow** por las siguientes razones:

1. **Funding Sources:** Los pagos de deudas referencian `fundingSourceId` de cashflow. El usuario debe tener fuentes de fondos configuradas antes de registrar pagos
2. **Integración opcional de pagos:** Al registrar un pago de deuda, se puede crear automáticamente una transacción en cashflow (categoría "Pago de deuda")
3. **Salud financiera (M1-DT-03):** El índice de salud financiera requiere tanto cashflow como deudas para calcularse correctamente

El desarrollo del módulo de deudas puede iniciar en **paralelo con Sprint 5 (budget)**, pero la integración completa con cashflow depende del Sprint 4.

---

## 2. Por qué el motor snowball/avalanche es un diferenciador

En el mercado chileno de finanzas personales, las aplicaciones existentes se enfocan principalmente en tracking de gastos. Walvy se diferencia al ofrecer:

1. **Visibilidad de deudas:** Muchos usuarios no tienen claro su deuda total consolidada
2. **Proyección concreta:** "Si aportas $100.000 extra al mes, estarás libre de deudas en 18 meses"
3. **Comparativa de estrategias:** Mostrar la diferencia en intereses totales entre snowball y avalanche ayuda a tomar mejores decisiones
4. **Gamificación:** La estrategia snowball da satisfacción al eliminar deudas pequeñas rápido

Este feature debe implementarse con cuidado y buenos tests, ya que los cálculos financieros incorrectos dañan la credibilidad del producto.

---

## 3. Backend a implementar

### DebtsModule

```
src/debts/
  ├── debts.module.ts
  ├── debts.controller.ts
  ├── debts.service.ts
  ├── payoff.service.ts          (motor de simulación, separado del service principal)
  ├── algorithms/
  │   ├── snowball.algorithm.ts  (lógica pura, sin dependencias de NestJS)
  │   └── avalanche.algorithm.ts (lógica pura, sin dependencias de NestJS)
  └── dto/
      ├── create-debt.dto.ts
      ├── update-debt.dto.ts
      ├── create-payment.dto.ts
      └── simulate-payoff.dto.ts
```

### PayoffService — separación de responsabilidades

El motor de simulación debe estar en `PayoffService` (o en módulos de algoritmo puros), separado del `DebtsService` que maneja el CRUD. Esta separación facilita:
- Tests unitarios del algoritmo sin necesidad de DB
- Reutilización del algoritmo (ej: mostrar preview de simulación sin guardar)
- Claridad del código

### Algoritmos como funciones puras

Los algoritmos snowball y avalanche deben implementarse como **funciones puras** (sin efectos secundarios, sin acceso a DB):

```typescript
// src/debts/algorithms/snowball.algorithm.ts
export function calculateSnowball(
  debts: DebtInput[],
  monthlyExtra: number
): PayoffProjection { ... }

export function calculateAvalanche(
  debts: DebtInput[],
  monthlyExtra: number
): PayoffProjection { ... }
```

Esto permite testear los algoritmos de forma aislada con valores conocidos y verificar la matemática.

---

## 4. Frontend a implementar

Arquitectura Feature-First:

```
src/features/debts/
  ├── api/
  │   └── debts.api.ts
  ├── hooks/
  │   ├── useDebts.ts
  │   ├── useCreateDebt.ts
  │   ├── useSimulatePayoff.ts
  │   └── useDebtPayments.ts
  └── ui/
      ├── DebtScreen.tsx           (lista de deudas y resumen)
      ├── DebtItem.tsx             (componente de deuda individual)
      ├── AddDebtScreen.tsx        (formulario nueva deuda)
      ├── DebtDetailScreen.tsx     (detalle y historial de pagos)
      ├── SimulationScreen.tsx     (comparativa snowball vs avalanche)
      └── PayoffChart.tsx          (gráfico de proyección)
```

### SimulationScreen — el feature estrella

La pantalla de simulación es el diferenciador más visible. Debe mostrar:
- Selector de monto extra mensual (slider o input)
- Comparativa lado a lado: snowball vs avalanche
- Fecha estimada de libertad financiera
- Total de intereses pagados en cada estrategia
- Gráfico de deuda total vs tiempo (línea descendente)
- CTA para adoptar la estrategia recomendada

---

## 5. Calidad y tests

### Tests críticos (algoritmo)

Los tests del algoritmo son los más importantes del módulo. Los errores de cálculo en finanzas son inaceptables.

| Test | Descripción |
|------|-------------|
| Snowball con 3 deudas | Verificar orden de pago y proyección mes a mes |
| Avalanche con 3 deudas | Verificar que la de mayor tasa recibe el extra |
| Deuda única | Verificar meses hasta payoff con fórmula conocida |
| Sin dinero extra | Solo cuotas mínimas, proyección más larga |
| Una deuda se paga antes | Verificar que su mínimo se libera para la siguiente |

---

## 6. Dependencias

| Item | Depende de | Estado |
|------|------------|--------|
| DebtsModule backend | Entidades ya existen | Listo para implementar |
| DebtPayment con fundingSource | Cashflow (Sprint 4) | Bloqueado hasta Sprint 4 |
| Frontend debts | Backend implementado | Bloqueado |
| Integración cashflow opcional | Sprint 4 + decisión de diseño | Backlog |
| M1-DT-03 salud financiera | Cashflow + Debts real | Bloqueado |

---

## 7. Roadmap sugerido

```
Sprint 4: Cashflow frontend
  └─ Sprint 5: Budget (paralelo) + Debts backend (paralelo)
        └─ Sprint 6: Debts frontend + SimulationScreen
              └─ Sprint 7: M1-DT-03 job salud financiera (Cashflow + Debts reales)
```

La deuda técnica M1-DT-03 (job de salud financiera que alimenta el home) solo puede resolverse cuando tanto cashflow como deudas tengan datos reales del usuario.
