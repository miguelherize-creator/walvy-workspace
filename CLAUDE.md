# Walvy — Agent Harness

**Proyecto:** Walvy — app de finanzas personales para Chile
**Stack:** NestJS 10 + React Native (Expo 54) + PostgreSQL 16
**Arquitectura:** Spec-Driven Development con agentes especializados

---

## Agentes disponibles

Invoca el agente correcto según el tipo de trabajo. Cada uno carga su contexto especializado y corre en el modelo óptimo.

| Comando | Modelo | Agente | Cuándo usarlo |
|---------|--------|--------|---------------|
| `/walvy-find` | Haiku | Buscador | Lookup rápido: archivo, endpoint, tabla, token, símbolo |
| `/walvy-backend` | Sonnet | Backend Engineer | NestJS, módulos, DTOs, entities, endpoints, DB queries |
| `/walvy-db` | Sonnet | DB Engineer | Schema PostgreSQL, tablas, migrations, entities TypeORM, queries |
| `/walvy-frontend` | Sonnet | Frontend Engineer | React Native, features, hooks, screens, Expo Router |
| `/walvy-design` | Sonnet | Design Engineer | UI pixel-perfect (Builder): Figma → código RN |
| `/walvy-qa` | Sonnet | QA Engineer | Tests, criterios de aceptación, checklist de features |
| `/walvy-qa-visual` | Sonnet | UI Visual QA Reviewer | Auditoría pixel-perfect contra Figma (NO genera código — solo reporta) — ver [`skills/ui-visual-qa-reviewer.md`](skills/ui-visual-qa-reviewer.md) |
| `/walvy-audit` | Sonnet | Code Auditor | Auditoría de calidad de cambios en staged (front+back): correctness, comentarios, tipos, design system, a11y + sugerencia de commit — ver [`skills/walvy-audit.md`](skills/walvy-audit.md) |
| `/walvy-arch` | Opus | Software Architect | ADRs, decisiones cross-cutting, estructura de módulos |
| `/walvy-ai` | Opus | AI Module Engineer | Sprint 8, LLM integration, asistente financiero |
| `/walvy-think` | Opus | Analista Senior | Nuevo requerimiento, trade-offs, plan antes de implementar |
| `/walvy-kora` | Sonnet | Bitácora / Kora | Cierre de jornada — commits del día + reuniones → entradas Kora |

---

## Contexto compartido

Todos los agentes parten de estos archivos:

| Archivo | Contenido |
|---------|-----------|
| [`context/stack.md`](context/stack.md) | Stack tecnológico, versiones, package managers |
| [`context/architecture.md`](context/architecture.md) | Capas del sistema, módulos, sprint status |
| [`context/conventions.md`](context/conventions.md) | Naming, patrones de código, seguridad |
| [`context/db/`](context/db/) | Schema completo por módulo (M1-M10 + B2B) — M1-M2 producción, M3-M10 referencia |
| [`context/mvp-scope.md`](context/mvp-scope.md) | Sprint status, próximos pasos |
| [`context/decisions.md`](context/decisions.md) | 16 ADRs — por qué tomamos cada decisión |
| [`context/release-workflow.md`](context/release-workflow.md) | Modelo de ramas/releases/deploy manual/migraciones TypeORM (propuesta Erick 2026-07-31) |
| [`context/debt.md`](context/debt.md) | Deuda técnica activa con cadena de bloqueos |
| [`context/specs/`](context/specs/) | Contrato de cada módulo (endpoints, flujos, checklist) |
| [`context/testing.md`](context/testing.md) | Estrategia de testing, patrones E2E, deuda de tests |
| [`context/ios-adhoc-testing.md`](context/ios-adhoc-testing.md) | Distribución iOS ad hoc (EAS), registro de dispositivos, credenciales Apple |
| [`context/bitacora/`](context/bitacora/) | Bitácora diaria — un archivo por día generado con `/walvy-kora` |
| [`context/mvp-scope.csv`](context/mvp-scope.csv) | Fuente de verdad del alcance MVP (Excel exportado) |
| [`context/qa-audits/`](context/qa-audits/) | Reportes pixel-perfect generados por `/walvy-qa-visual` — uno por pantalla por iteración |

---

## Estado actual del MVP

| Sprint | Módulo | Backend | Frontend |
|--------|--------|---------|----------|
| 1 | Auth/Enrolment | ✅ | ✅ |
| 2 | Profile & Settings | ✅ | ✅ |
| 3 | Home Dashboard | ✅ | ✅ |
| 4 | Transactions | ✅ | ❌ Próximo |
| 5 | Budgets | ⚠️ Schema | ❌ |
| 6 | Debt Management | ⚠️ Schema | ❌ |
| 7 | Recurring Payments | ⚠️ Schema | ❌ |
| 8 | AI Assistant | ⚠️ Schema | ❌ |

---

## Repositorios (KabeliDev)

| Repo | GitHub | Ruta local |
|------|--------|------------|
| Frontend | `github.com/KabeliDev/front-walvy` | `front-walvy/` |
| Backend | `github.com/KabeliDev/back-walvy` | `back-walvy/` |
| Infra | `github.com/KabeliDev/walvy-platform-infra` | `walvy-platform-infra/` |

---

## Rutas del proyecto

| Área | Ruta |
|------|------|
| Backend src | `back-walvy/src/` |
| Frontend | `front-walvy/expo/` |
| DB Schema | `back-walvy/DB/schema.sql` |
| Design tokens | `front-walvy/expo/constants/colors.ts` + `theme.ts` |
| E2E Playwright | `workspace/walvy-workspace/e2e/` |
| Brand assets | `workspace/walvy-workspace/assets/brand/` |

---

## Comandos rápidos

```bash
# Backend
cd back-walvy && npm run start:dev
docker compose up --build

# Frontend
cd front-walvy/expo && bun run start
bun run start-web

# Tests
npm run test:e2e        # backend E2E (Supertest)
bun run test            # frontend unit
cd workspace/walvy-workspace/e2e && npm test   # E2E UI Playwright (mock mode)
```
