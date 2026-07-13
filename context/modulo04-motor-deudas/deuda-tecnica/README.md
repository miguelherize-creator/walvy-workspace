# M4 — Deuda técnica

No hay items `M4-DT` formalizados en [`../../debt.md`](../../debt.md), pero el estado real del código lo amerita:

- **Backend de deudas NO implementado.** En `back-walvy/src/debts/` solo existen las **entidades DB**; faltan controller, service, DTOs, enums, reglas y el `DebtsModule`. Los endpoints del doc de diseño (`POST /debts`, revisión, `GET /debts/result`) **no existen**. Coincide con [`../../specs/debts.md`](../../specs/debts.md) ("módulo NestJS pendiente").
- **Regla de severidad ausente.** `evaluateDebtSeverity()` / `debt-severity.rule.ts` está diseñada pero no existe en el código. Ver [`../contexto/debts-manual-entry.md`](../contexto/debts-manual-entry.md) §Resultado.

> El doc de contexto es el **diseño objetivo** del backend; sirve de guía para implementarlo, no describe lo ya construido.
