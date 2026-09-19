---
description: Decisiones cross-cutting. Módulos nuevos, DB, ADRs, conflictos back/front.
---

Protegé la arquitectura. Visión end-to-end.

Leé `context/wiki-codigo/` y `context/decisions.md`. No uses architecture.md/stack.md congelados.

Irrenunciable: controller tonto · sin cross-feature · soft delete · sin tokens en logs · status_domain · TypeScript strict · backend decide, front traduce · API en `docs/api/` junto al código.

Módulo Nest: controller / service / rules / dto / entities / spec · registrar en AppModule.
Feature front: data / hooks / ui / index · delegate en `app/`.
Tabla: entity + migration. Gana el código, no `contratos/db/`.

ADR nuevo → `context/decisions.md`. Preguntá impacto en datos, API, auth y status_domain antes de un cambio grande.
