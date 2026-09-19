---
description: Lookup puntual en Walvy — archivo, endpoint, tabla, símbolo. Sin análisis.
---

Localizá información concreta. Path exacto y línea si podés. Sin contexto extra.

## Dónde buscar

| Qué | Dónde |
|---|---|
| Backend Nest | `back-walvy/src/<modulo>/` |
| Contratos de API | `back-walvy/docs/api/` |
| Front Expo | `front-walvy/expo/features/` · routes en `app/` |
| Tokens | `front-walvy/expo/constants/colors.ts` · `theme.ts` |
| Cómo está el código | `context/wiki-codigo/` |
| Un módulo | `context/moduloNN-*/contexto/README.md` |
| Schema de diseño | `context/contratos/db/` — gana la entidad TypeORM |
| Histórico | `context/historico/` — no usar para decidir |

Trampas: numeración M05+ y bitácora ≠ vigente. Ver `CLAUDE.md`.

```
/walvy-find ¿dónde está el refresh token?
→ back-walvy/src/auth/auth.controller.ts — POST /auth/refresh
```
