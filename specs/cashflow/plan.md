# Plan de Evolución: Módulo de Cashflow

> **Módulo:** `cashflow`
> **Última revisión:** 2026-05-14

---

## 1. Estado actual

### Backend — Completo

Todos los sub-módulos del backend están implementados:

| Sub-módulo | Estado | Endpoints |
|------------|--------|-----------|
| Transactions | Implementado | CRUD completo |
| Categories | Implementado | CRUD + globales |
| Subcategories | Implementado | CRUD anidado |
| Funding Sources | Implementado | CRUD + sembrado |
| Statement Import | Implementado | Upload, list, get, lines, reclassify, delete |

### Frontend — Placeholder

El frontend tiene tabs de cashflow como **placeholders vacíos**:

| Pantalla | Estado |
|----------|--------|
| Transactions list | Placeholder (Sprint 4) |
| Transaction create | Placeholder (Sprint 4) |
| Transaction detail | Placeholder (Sprint 4) |
| Categories selector | Placeholder (Sprint 4) |
| Home dashboard | Implementado con **datos mock** — requiere cashflow real |

### Home Dashboard con datos mock

El home screen (Sprint 3) está implementado con datos ficticios:
- `FinancialHealthRings` — anillos de salud financiera con valores hardcodeados
- `SummaryCarousel` — resumen de ingresos/gastos con datos mock

**Estos componentes deben conectarse a datos reales en Sprint 4** al implementar el cashflow en el frontend.

---

## 2. Sprint 4 — Frontend Cashflow

El Sprint 4 está dedicado a implementar el cashflow completo en el frontend.

### Arquitectura (Feature-First)

```
src/features/cashflow/
  ├── api/
  │   ├── transactions.api.ts
  │   ├── categories.api.ts
  │   └── funding-sources.api.ts
  ├── hooks/
  │   ├── useTransactions.ts
  │   ├── useCreateTransaction.ts
  │   ├── useCategories.ts
  │   └── useFundingSources.ts
  └── ui/
      ├── TransactionsScreen.tsx
      ├── TransactionDetailScreen.tsx
      ├── CreateTransactionScreen.tsx
      └── CategorySelectorModal.tsx
```

### Conexión del home con datos reales

Al tener transacciones reales, el home debe:
1. Consultar `GET /cashflow/transactions?from=<inicio_mes>&to=<fin_mes>` para obtener el resumen del mes
2. Calcular totales de ingresos y gastos del período
3. Alimentar `FinancialHealthRings` y `SummaryCarousel` con datos reales

---

## 3. Deuda técnica relacionada

### M1-DT-03: Job de salud financiera (bloqueado)

El job que calcula el nivel de "salud financiera" del usuario está bloqueado hasta que:
1. Cashflow tenga datos reales (Sprint 4)
2. Debts tenga datos reales (sprint posterior)

Sin estas dos fuentes de datos, el índice de salud financiera no puede calcularse correctamente. Los `FinancialHealthRings` en el home mostrarán datos reales solo después de Sprint 4.

---

## 4. Pendiente de decisión

### Umbral mínimo para `minDocThresholdMet`

El checkpoint de onboarding `minDocThresholdMet` requiere definir cuántas transacciones o documentos importados constituyen el "umbral mínimo". Esta decisión impacta tanto el módulo de cashflow (quién activa el checkpoint) como el onboarding (cuándo se completa).

Ver `specs/onboarding/plan.md` para el análisis completo.

---

## 5. Calidad y tests

### Unit tests pendientes

| Servicio | Prioridad |
|----------|-----------|
| `TransactionsService` | Alta — lógica de negocio central |
| `CategoriesService` | Alta — reglas de globales vs usuario |
| `StatementImportService` | Media — lógica de parseo compleja |

Los tests deben seguir las convenciones del proyecto: `uniqueEmail()`, `MockMailService`, desactivar `ThrottlerGuard`.

---

## 6. Dependencias

| Item | Depende de | Bloquea |
|------|------------|---------|
| Frontend cashflow | Backend listo (ya) | Home dashboard datos reales |
| Home datos reales | Frontend cashflow (Sprint 4) | Feedback real al usuario |
| M1-DT-03 job salud | Cashflow + Debts con datos | `minDocThresholdMet` |
| Budget (Sprint 5) | Cashflow completado | — |
| Debts (sprint posterior) | Cashflow (funding sources) | Motor snowball/avalanche |
