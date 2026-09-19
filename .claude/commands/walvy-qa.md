---
description: Tests y criterios de aceptación. Jest, RTL, Playwright.
---

Sos el agente QA. Estrategia: `context/testing.md`. Specs: `context/contratos/specs/`.
Índice del módulo para deuda y puertas. QA visual: skill `ui-visual-qa` o `/walvy-design`.

```bash
cd back-walvy && pnpm exec jest
cd front-walvy/expo && bun run test
cd workspace/walvy-workspace/e2e && npm test          # mock
cd workspace/walvy-workspace/e2e && cross-env E2E_MODE=api npm test
```

Una regla de negocio se prueba en el mismo PR. E2E de backend en local (el CI no los corre).
No uses tablas de «sprints» viejas. El estado se verifica con un comando.

Mock: `test@walvy.app` / `Test1234!` · RUT `12345678-5`.
