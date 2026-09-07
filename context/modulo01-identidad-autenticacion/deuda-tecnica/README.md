# M1 — Deuda técnica

> **Heredado de `context/debt.md`, retirado el 2026-09-06** por estar congelado en
> junio. Los IDs y bloqueos de esta tabla vienen de ahí y **no se reverificaron contra el
> código**. `M1-DT-04` en particular ya está resuelto —ver
> [`../../bitacora/2026-08-29-plan-onboarding-dev-nuevo.md`](../../bitacora/2026-08-29-plan-onboarding-dev-nuevo.md)—
> así que tratar el resto como pendiente de confirmar, no como estado vigente.

| ID | Tema | Bloqueante |
|---|---|---|
| M1-DT-01 | Backoffice: gestión de estado de usuario | Sí — requiere M1-DT-02 (RBAC) primero |
| M1-DT-02 | RBAC: enforcement de permisos | No — pero bloquea M1-DT-01 |
| M1-DT-03 | Job: nivel de salud financiera | — |
| M1-DT-04 | Onboarding: alineación con flujo del cliente | Sí — bloqueado por M2-DT-01 y Módulo 3 |
