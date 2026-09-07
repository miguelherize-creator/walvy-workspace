# Modelo de Ramas, Releases y Migraciones — Walvy

Propuesta compartida por Erick (Walvy) el 2026-07-31, aprobada internamente por su equipo, pendiente de
revisión conjunta con desarrollo (5 puntos abiertos, ver [Puntos abiertos](#puntos-abiertos-para-revisar-con-erick)).
Aplica a `back-walvy` y `front-walvy`. Cuando se confirme, reemplaza el modelo actual de ramas
(`develop`/`release`/`main` permanentes).

## Flujo general

```
feature/* → PR → main → GitHub Release / tag → deploy manual a ambiente
```

- `main` es la única rama larga. **No** hay ramas permanentes por ambiente (`dev`, `qa`, `uat`, `prod`).
- Merge a `main` = valida e integra. **No** dispara deploy automático.
- El deploy a cada ambiente se dispara manualmente desde GitHub Actions indicando un `release_tag` explícito
  (nunca `latest`/`dev`/`prod` como referencia).
- La misma versión (tag) se promueve entre DEV → UAT → PROD sin crear rama ni tocar código.

## Ramas de trabajo

| Tipo | Convención | Ejemplo |
|---|---|---|
| Feature | `feature/<ticket-o-cambio>` | `feature/WAL-101-user-registration` |
| Bugfix | `bugfix/<ticket-o-error>` | `bugfix/WAL-102-login-validation-error` |
| Hotfix | `hotfix/<ticket-o-incidente>` | `hotfix/WAL-103-prod-payment-failure` |

Hotfix: `hotfix/<ticket>` → PR → `main` → release patch (`backend-v0.1.2`) → deploy manual. La corrección
siempre queda integrada en `main` (no se parchea directo en un ambiente).

## Commits — Conventional Commits

`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`, `build:`. Las ramas ordenan el flujo; los
commits ordenan el historial (release notes, changelog).

## Releases

Un release = GitHub Release + tag apuntando a un commit exacto.

```
Release: backend-v0.1.0 → Tag: backend-v0.1.0 → Commit: abc123 → Imagen: walvy-backend:abc123
```

Imágenes Docker inmutables por commit y por tag (`walvy-backend:abc123`, `walvy-backend:backend-v0.1.0`).
Evitar tags flotantes (`latest`, `dev`, `prod`).

## Deploy manual

Workflow `workflow_dispatch` con inputs: `environment`, `release_tag` (o `image_tag`), `run_migrations`.

Orden cuando el release trae cambios de schema:
1. Ejecutar migraciones TypeORM
2. Desplegar la aplicación
3. Validar health check / funcionalidad básica

## Rollback

Redeploy de la versión anterior conocida usando el mismo mecanismo manual (nunca cambios improvisados en
el ambiente). El rollback de aplicación es simple; el de base de datos no siempre lo es — ver expand/contract
abajo.

## Migraciones de base de datos

- Todo cambio de schema entra por PR, como migración **TypeORM** versionada (`src/migrations/<timestamp>-Nombre.ts`),
  viaja con el release, se ejecuta por pipeline.
- Prohibido: cambios manuales directos en RDS o scripts sueltos sin trazabilidad.
- Cambios riesgosos (breaking): estrategia **expand/contract** en 3 releases —
  1) agregar columna/estructura nueva sin romper compatibilidad,
  2) app usa la estructura nueva,
  3) eliminar lo antiguo cuando ya no se use.
- Ante un problema de datos en prod: preferir **forward fix** controlado antes que revertir la migración.

## Qué NO incluye este modelo (por ahora)

Deploy automático a prod o dev, canary, blue/green, feature flags obligatorios, release trains formales.
Evolución futura progresiva: deploy automático a DEV → promoción con approvals a UAT/PROD → canary/blue-green.

## Estado actual vs. modelo objetivo (verificado 2026-07-31)

- **back-walvy** ya tiene parte de la mecánica de deploy/release construida:
  [`release-image.yml`](../../../back-walvy/.github/workflows/build-deploy.yml) (build+push imagen inmutable
  desde un tag `vX.Y.Z` existente) y [`deploy.yml`](../../../back-walvy/.github/workflows/deploy.yml)
  (`workflow_dispatch` con `environment` + `image_tag`, verifica que el tag exista en ECR, actualiza ECS,
  smoke test). Convención de tag ahí es `vX.Y.Z`, no `backend-vX.Y.Z` como en el ejemplo de Erick — hay que
  alinear el formato.
- **Gaps a resolver** antes de operar 100% bajo este modelo:
  - `deploy.yml` no tiene input `run_migrations` ni paso de ejecución de migraciones.
  - `DB/migrations/` en back-walvy hoy son `.sql` sueltos con fecha (`2026-07-06_reseed_categorias_cliente.sql`),
    no migraciones TypeORM (`src/migrations/<timestamp>-Nombre.ts`). Falta adoptar TypeORM migrations real.
  - Ambos repos (`back-walvy`, `front-walvy`) todavía tienen `develop` y `release` como ramas permanentes
    remotas — el modelo nuevo las elimina en favor de `feature/* → main → tag`.
  - `main` protection / PR checks obligatorios (lint, tests, build, Trivy scan, validación de migraciones) —
    confirmar qué ya corre en `backend-checker.yml`/`repository-checker.yml` vs qué falta.

## Puntos abiertos para revisar con Erick

1. Cómo deben operar ramas, PRs y releases bajo el modelo aprobado (dado que hoy `develop`/`release` siguen
   vivas — plan de transición/depreciación).
2. Organización de cambios de BD con TypeORM migrations (falta adoptarlas — hoy son `.sql` sueltos).
3. Consideraciones técnicas para que releases viajen con código + imagen Docker + migraciones (formato de
   tag: `vX.Y.Z` actual vs `backend-vX.Y.Z` propuesto).
4. Cambios necesarios en la forma de trabajo actual (branch cleanup, `run_migrations` input en `deploy.yml`).
5. Dudas/riesgos técnicos antes de formalizar como guía — ej. quién ejecuta migraciones destructivas y cómo
   se valida antes del deploy.
6. **Conflicto con el modelo ya adoptado en `front-walvy`** (detectado 31/07): en paralelo a esta propuesta
   se creó una rama `release` permanente en `front-walvy` (espejo del `develop`/`release`/`main` que ya usaba
   `back-walvy`) para aislar lo entregado de Módulo 1 y dar continuidad a bugfixes de QA. Este modelo nuevo de
   Erick la elimina en favor de `feature/* → main → tag`. Definir con Erick si `front-walvy:release` se
   desarma cuando se adopte el modelo nuevo, o si convive como excepción temporal mientras se entrega Módulo 1.
