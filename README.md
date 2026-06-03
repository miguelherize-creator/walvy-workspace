# walvy-workspace

Repositorio de orquestación de Walvy. No contiene código de producción — es la capa de conocimiento y agentes que gobierna cómo se trabaja el proyecto.

---

## Qué hay aquí

```
walvy-workspace/
├── CLAUDE.md          ← punto de entrada para Claude Code — lista de agentes y rutas del proyecto
├── context/           ← base de conocimiento compartida entre todos los agentes
├── e2e/               ← tests E2E Playwright sobre Expo Web
├── assets/            ← archivos maestros de marca (SVGs originales, brand kit)
└── skills/            ← skills locales del proyecto (complementan los de ~/.claude/skills/)
```

---

## Metodología: Agent Harness + SDD

Este workspace implementa **Spec-Driven Development** ejecutado mediante un **Agent Harness** — una capa de orquestación que asigna contexto especializado y modelo óptimo a cada tipo de trabajo.

```
Tarea
  └── Skill (/walvy-backend, /walvy-db, etc.)
        ├── Modelo asignado (Haiku / Sonnet / Opus)
        └── Contexto recortado (solo lo relevante al rol)
```

Los agentes no reciben todo el contexto del proyecto — cada skill carga solo el slice que su rol necesita. Esto reduce ruido, mejora precisión y baja costo por token.

---

## Agentes disponibles

| Comando | Modelo | Cuándo usarlo |
|---------|--------|---------------|
| `/walvy-find` | Haiku | Buscar archivo, endpoint, tabla, símbolo |
| `/walvy-backend` | Sonnet | NestJS, módulos, DTOs, entities, endpoints |
| `/walvy-db` | Sonnet | Schema PostgreSQL, migrations, entities TypeORM |
| `/walvy-frontend` | Sonnet | React Native, features, hooks, screens, Expo Router |
| `/walvy-design` | Sonnet | UI pixel-perfect, design tokens, componentes |
| `/walvy-qa` | Sonnet | Tests, E2E Playwright, criterios de aceptación |
| `/walvy-arch` | Opus | ADRs, decisiones cross-cutting, deuda técnica |
| `/walvy-ai` | Opus | Sprint 8 — módulo de asistente financiero IA |
| `/walvy-think` | Opus | Análisis de nuevo requerimiento antes de implementar |

Los skills viven en `~/.claude/skills/walvy-*.md` (nivel usuario, disponibles en cualquier proyecto).

---

## Capa de contexto

Todo el conocimiento del proyecto está en `context/`. Cada archivo tiene un propósito específico:

| Archivo | Contenido |
|---------|-----------|
| `stack.md` | Versiones, package managers, comandos de arranque |
| `architecture.md` | Capas del sistema, módulos, patrón Feature-First |
| `conventions.md` | Naming, patrones de código, reglas de seguridad |
| `decisions.md` | 16 ADRs — por qué se tomó cada decisión de diseño |
| `debt.md` | Deuda técnica activa con cadena de bloqueos |
| `mvp-scope.md` | Sprint status y próximos pasos |
| `mvp-scope.csv` | Fuente de verdad del alcance MVP (exportado del Excel original) |
| `testing.md` | Estrategia de testing — Supertest, Playwright, RTL |
| `specs/` | Contrato de cada módulo: endpoints, flujos, criterios de aceptación |
| `db/` | Schema completo por módulo (M1-M10 + B2B) |
| `qa-audits/` | Reportes pixel-perfect por pantalla — historial de auditorías UI |

### `context/db/`

Documentación del schema PostgreSQL organizada por módulo:

| Archivo | Módulo | Estado |
|---------|--------|--------|
| `modulo1.md` | Auth & Identidad | ✅ Producción |
| `modulo2.md` | Perfil & Config | ✅ Producción |
| `modulo3.md` | Home / Dashboard | 📋 Referencia |
| `modulo4.md` | Deudas Snowball | 📋 Referencia |
| `modulo5.md` | Cashflow | 📋 Referencia |
| `modulo6.md` | Presupuesto | 📋 Referencia |
| `modulo7.md` | Pagos y Agenda | 📋 Referencia |
| `modulo8.md` | Asistente IA | 📋 Referencia |
| `modulo9.md` | Admin / Auditoría | 📋 Referencia |
| `modulo10.md` | Monetización | ✅ Producción (parcial) |
| `moduloB2B.md` | Corporativo | ⏸ Fuera de MVP |

### `context/specs/`

Contratos de módulo — fuente de verdad para frontend y backend sobre qué debe hacer cada endpoint:

```
specs/
├── authentication.md    ← M1 — registro, OTP, JWT, biometría
├── onboarding.md        ← M1 — flujo de onboarding
├── user-profile.md      ← M2 — perfil, avatar, contraseña
├── cashflow.md          ← M5 — movimientos, categorías, importación
├── budget.md            ← M6 — presupuesto mensual
├── debts.md             ← M4 — deudas, snowball/avalanche
└── subscriptions.md     ← M10 — planes, Flow.cl, webhooks
```

---

## E2E Playwright

Tests de interfaz sobre Expo Web. Cubren los flujos principales de autenticación y navegación.

```bash
# Modo mock (sin backend — por defecto)
cd e2e && npm test

# Modo full stack (requiere PostgreSQL + backend corriendo)
cd e2e && cross-env E2E_MODE=api npm test
```

Suites: `login`, `register`, `dashboard`, `forgot-password`, `navigation`.

Ver estrategia completa en `context/testing.md`.

---

## Assets de marca

`assets/brand/` contiene los archivos maestros — SVGs originales, brand kit completo:

```
assets/brand/
├── logo/       ← logo horizontal en variantes light / dark / transparent (SVG + PNG)
├── isotipo/    ← isotipo en variantes transparent (SVG + PNG)
├── avatar/     ← orb avatar en variantes transparent (SVG + PNG)
├── app_icon/   ← ícono de app final (SVG + PNG)
├── guia/       ← paleta de colores final
└── presentacion/ ← brand starter kit (PPT)
```

> Los assets de producción (optimizados para mobile) están en `Frontend/rork-checkapp/expo/assets/`.

---

## Ecosistema de repositorios

Walvy está compuesto por repositorios independientes. Este workspace es la capa transversal que los conecta a todos:

| Repositorio | Stack | Descripción |
|-------------|-------|-------------|
| `Backend/MVP-CheckApp` | NestJS + PostgreSQL | API principal — auth, perfil, cashflow, suscripciones |
| `Frontend/rork-checkapp` | Expo / React Native | App móvil y web |
| Extracción de cartolas | FastAPI | Servicio de lectura y parseo de cartolas bancarias |
| Repo arquitectura | — | Infraestructura, diagramas, decisiones de plataforma |
| Repo asistente IA | — | Módulo LLM — asistente financiero conversacional |
| **`walvy-workspace`** | **Spec-Driven Development** | **Este repo — orquestación y conocimiento transversal** |

Este workspace no se despliega. Es la capa que hace que los agentes trabajen con contexto correcto, modelos apropiados y fuentes de verdad centralizadas — independientemente de en qué repositorio estén trabajando.
