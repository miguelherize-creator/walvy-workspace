# Spec: Gestión de Deudas (Snowball)

**Estado backend:** ⚠️ Schema DB listo — módulo NestJS pendiente  
**Estado frontend:** ❌ Pendiente — Sprint 6 (`features/debts/`)  
**Módulo NestJS:** `src/debts/` (por crear)

---

## Concepto
El usuario registra sus deudas (tarjetas, créditos, préstamos). El sistema genera un plan de pago usando la estrategia snowball (menor saldo primero) o avalanche (mayor tasa primero). El usuario registra pagos y ve el progreso hacia estar libre de deudas.

## Endpoints (a implementar)

```
DEUDAS
  GET    /debts                        → lista de deudas activas
  POST   /debts                        → registrar nueva deuda
  GET    /debts/:id                    → detalle + schedule
  PATCH  /debts/:id                    → editar deuda
  DELETE /debts/:id                    → soft delete

PAGOS
  POST   /debts/:id/payments           → registrar pago realizado
  GET    /debts/:id/payments           → historial de pagos

PLAN SNOWBALL
  GET    /debts/snowball-plan          → plan calculado para todas las deudas
  POST   /debts/snowball-plan          → generar/regenerar plan
  PATCH  /debts/snowball-plan/strategy → cambiar estrategia (snowball|avalanche)
```

## Contratos propuestos

### POST /debts
```json
// Request
{ "creditorName": "Banco BCI", "originalAmount": 2000000,
  "currentBalance": 1500000, "interestRate": 18.5,
  "minimumPayment": 50000, "dueDay": 15,
  "currencyId": "CLP" }
// Response 201 → deuda creada con status "active"
```

### GET /debts/snowball-plan
```json
// Response 200
{ "strategy": "snowball", "totalDebt": 3500000,
  "estimatedPayoffDate": "2028-03",
  "monthlyExtraPayment": 100000,
  "order": [
    { "debtId": "uuid", "creditorName": "Banco BCI",
      "currentBalance": 1500000, "payoffMonth": "2027-06",
      "totalInterestPaid": 280000 }
  ] }
```

### POST /debts/:id/payments
```json
// Request
{ "paidAmount": 80000, "paidAt": "2026-06-15" }
// Response 201 → pago registrado, balance actualizado
```

## Reglas de negocio
- Soft delete: `deleted_at` en deuda, nunca DELETE físico
- `currentBalance` se recalcula automáticamente al registrar un pago
- Estrategia **snowball**: ordenar de menor a mayor `currentBalance`
- Estrategia **avalanche**: ordenar de mayor a menor `interestRate`
- El `extra_payment_monthly` es la capacidad adicional del usuario (viene de `user_financial_profile`)
- `debt_schedules` se regenera cuando se registra un pago o cambia la estrategia

## Frontend — checklist Sprint 6
```
□ features/debts/data/DebtsRepository.ts
□ features/debts/hooks/useDebts.ts
□ features/debts/hooks/useSnowballPlan.ts
□ features/debts/hooks/useRegisterPayment.ts
□ features/debts/ui/DebtsScreen.tsx
□ features/debts/ui/DebtDetailScreen.tsx
□ features/debts/ui/SnowballPlanScreen.tsx
□ api/mocks/debtsMock.ts
□ app/(tabs)/debts.tsx (delegate)
```

## Tablas involucradas
`debt` · `debt_schedules` · `debt_payments` · `debt_snowball_plan` · `user_financial_profile`
