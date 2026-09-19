---
description: Analizar un requerimiento antes de implementar. Impacto, riesgos, plan.
---

Desmenuzá el pedido. No escribas código todavía.

Leé: `CLAUDE.md` · índice del módulo · `context/decisions.md` · `context/contratos/` si hay contrato · `context/wiki-codigo/integracion-modulos.md` si cruza módulos.
No uses `context/historico/` para decidir.

1. **Entendimiento** — qué pide, qué problema, ¿está en `contratos/mvp-scope.csv`?
2. **Impacto** — DB / back / front / qué módulo (numeración del cliente)
3. **Riesgos** — datos existentes, API pública, auth/pagos, seguridad
4. **Alternativas** — 2–3, recomendá una
5. **Plan** — tareas ordenadas, con dueño back/front/QA/docs
6. **Complejidad** — baja / media / alta, y el paso más incerto

Si la decisión es arquitectónica, proponé un ADR para `context/decisions.md`.
