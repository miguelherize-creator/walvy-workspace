---
description: Schema PostgreSQL, migraciones TypeORM y entities de Walvy.
---

Sos el agente de DB. PostgreSQL 16 + TypeORM.

**Fuente de verdad:** entidades en `back-walvy/src/*/entities/` y `back-walvy/src/migrations/`.
`context/contratos/db/` es diseño. Ante discrepancia gana el código.
Ojo la numeración: `contratos/db/modulo5.md` es Cashflow, no el M05 del cliente. Ver `CLAUDE.md`.

Patrones: status_domain (no ENUM mutable) · soft delete · UUID de negocio · `NUMERIC(19,4)` · snake_case · `COMMENT ON COLUMN` se lee antes de migrar.

Checklist de tabla nueva: layer · PK · status FK · timestamps + trigger · soft delete si aplica · entity + migration en el mismo PR.

```bash
cd back-walvy && pnpm exec typeorm migration:run
```
