# Walvy — Agent Harness

**Proyecto:** Walvy — app de finanzas personales para Chile
**Stack:** NestJS 10 + React Native (Expo 54) + PostgreSQL 15
**Arquitectura:** Spec-Driven Development con agentes especializados

---

## Agentes disponibles

Invoca el agente correcto según el tipo de trabajo. Cada uno carga su contexto especializado y corre en el modelo óptimo.

| Comando | Modelo | Agente | Cuándo usarlo |
|---------|--------|--------|---------------|
| `/walvy-find` | Haiku | Buscador | Lookup rápido: archivo, endpoint, tabla, token, símbolo |
| `/walvy-backend` | Sonnet | Backend Engineer | NestJS, módulos, DTOs, entities, endpoints, DB queries |
| `/walvy-frontend` | Sonnet | Frontend Engineer | React Native, features, hooks, screens, Expo Router |
| `/walvy-design` | Sonnet | Design Engineer | UI pixel-perfect, design tokens, paleta, componentes |
| `/walvy-qa` | Sonnet | QA Engineer | Tests, criterios de aceptación, checklist de features |
| `/walvy-arch` | Opus | Software Architect | ADRs, decisiones cross-cutting, estructura de módulos |
| `/walvy-ai` | Opus | AI Module Engineer | Sprint 8, LLM integration, asistente financiero |
| `/walvy-think` | Opus | Analista Senior | Nuevo requerimiento, trade-offs, plan antes de implementar |

---

## Contexto compartido

Todos los agentes parten de estos archivos:

| Archivo | Contenido |
|---------|-----------|
| [`context/stack.md`](context/stack.md) | Stack tecnológico, versiones, package managers |
| [`context/architecture.md`](context/architecture.md) | Capas del sistema, módulos, sprint status |
| [`context/conventions.md`](context/conventions.md) | Naming, patrones de código, seguridad |
| [`context/db-schema.md`](context/db-schema.md) | 19 layers, tablas clave, patrones DB |
| [`context/mvp-scope.md`](context/mvp-scope.md) | Sprint status, deudas técnicas, próximos pasos |

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

## Rutas del proyecto

| Área | Ruta |
|------|------|
| Backend | `Backend/MVP-CheckApp/src/` |
| Frontend | `Frontend/rork-checkapp/expo/` |
| DB Schema | `workspace/walvy-workspace/legacy/DB_v2/schema.sql` |
| Design tokens | `Frontend/rork-checkapp/expo/constants/colors.ts` + `theme.ts` |
| Docs legacy | `workspace/walvy-workspace/legacy/` |

---

## Comandos rápidos

```bash
# Backend
cd Backend/MVP-CheckApp && npm run start:dev
docker compose up --build

# Frontend
cd Frontend/rork-checkapp/expo && bun run start
bun run start-web

# Tests
npm run test:e2e        # backend E2E
bun run test            # frontend unit
```
