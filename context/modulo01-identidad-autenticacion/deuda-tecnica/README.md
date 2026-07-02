# M1 — Deuda técnica

Detalle completo y cadena de bloqueos en [`../../debt.md`](../../debt.md). Resumen:

| ID | Tema | Bloqueante |
|---|---|---|
| M1-DT-01 | Backoffice: gestión de estado de usuario | Sí — requiere M1-DT-02 (RBAC) primero |
| M1-DT-02 | RBAC: enforcement de permisos | No — pero bloquea M1-DT-01 |
| M1-DT-03 | Job: nivel de salud financiera | — |
| M1-DT-04 | Onboarding: alineación con flujo del cliente | Sí — bloqueado por M2-DT-01 y Módulo 3 |
