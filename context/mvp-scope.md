# MVP Scope & Sprint Status — Walvy

**Fuente de verdad:** `legacy/utils/organizacion/docs/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`

## Estado de sprints

| Sprint | Módulo | Backend | Frontend | Notas |
|--------|--------|---------|----------|-------|
| 1 | Auth/Enrolment | ✅ | ✅ | Login, register, OTP, password reset, onboarding, biometría |
| 2 | Profile & Settings | ✅ | ✅ | Edit profile, password change, financial profile setup |
| 3 | Home Dashboard | ✅ | ✅ | Financial summary, health rings, balance overview |
| 4 | Transactions | ✅ | ❌ | CRUD movimientos, categorías/subcategorías — backend completo |
| 5 | Budgets | ⚠️ | ❌ | Schema DB listo, lógica de negocio pendiente |
| 6 | Debt Management | ⚠️ | ❌ | Schema DB listo, snowball pendiente |
| 7 | Recurring Payments | ⚠️ | ❌ | Schema DB listo, worker de notificaciones pendiente |
| 8 | AI Assistant | ⚠️ | ❌ | Schema DB listo, integración LLM pendiente |

## Deudas técnicas conocidas

| ID | Descripción | Impacto |
|----|-------------|---------|
| M1-DT-01 | `src/admin/` vacío — AdminModule sin implementar | Backoffice inaccesible |
| M1-DT-04 | Validación onboarding solo en controller, no en service | Bypass posible |
| M2-DT-01 | PUT `/profile/financial` endpoint pendiente | Perfil financiero incompleto |
| M2-DT-04 | Worker de notificaciones FCM/APNs no existe | Bloquea Sprint 7 |
| — | Sin carpeta `migrations/` — usando `DB_SYNC` en dev | Riesgo en producción |

## Próximos pasos (Sprints 4-8)

### Sprint 4 — Transactions (Frontend)
- `features/transactions/` con las 4 capas (data, hooks, ui)
- CRUD movimientos: crear, editar, eliminar (soft), listar con filtros
- Selector de categoría/subcategoría
- Mock mode para desarrollo offline

### Sprint 5 — Budgets (Backend + Frontend)
- Implementar `BudgetModule` en NestJS
- `features/budget/` en frontend
- Budget por categoría, tracking de gasto vs presupuesto

### Sprint 6 — Debt Management (Backend + Frontend)
- Implementar `DebtsModule` con snowball strategy
- `features/debts/` en frontend
- Calculadora de plan de pago

### Sprint 7 — Recurring Payments
- Worker de notificaciones (deuda M2-DT-04)
- `RecurringPaymentsModule` backend
- `features/payments/` frontend + push notifications

### Sprint 8 — AI Assistant
- Integración LLM (Claude API)
- `AIAssistantModule` backend
- `features/assistant/` frontend
- Context snapshots para recomendaciones personalizadas

## Funcionalidades fuera de MVP

- B2B / corporativo (Layer 5 DB)
- Gamificación (Layer 14 DB)
- Open Banking automático (solo import manual PDF por ahora)
- Admin backoffice completo
