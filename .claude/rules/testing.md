# Testing

Estrategia y números verificables: `context/testing.md`.

```bash
cd back-walvy && pnpm exec jest          # unit + e2e Supertest
cd front-walvy/expo && bun run test
cd workspace/walvy-workspace/e2e && npm test
```

- Una regla de negocio se prueba en el mismo PR que la cambia.
- Las reglas de M04 son funciones puras: leé el `.spec.ts` antes que la implementación.
- E2E de backend se corren en local; el CI no los corre.
- Playwright default es mock. `E2E_MODE=api` pide PostgreSQL + backend.
