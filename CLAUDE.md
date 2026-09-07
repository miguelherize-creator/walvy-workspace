# Walvy — Agent Harness

**Proyecto:** Walvy — app de finanzas personales para Chile
**Stack:** NestJS 11 + React Native (Expo 54) + PostgreSQL 16 · TypeORM, 36 migraciones
**Rama de referencia:** `origin/qa` — back `dd713df`, front `f64c1a5`, ambos del 2026-09-06

> **Antes de leer cualquier otra cosa, dos trampas de este repo.**
>
> **1 · Hay dos numeraciones de módulo y desde M05 están corridas.** La del cliente
> (los entregables `Walvy_MNN_*`) y la interna de `context/db/`:
>
> | Cliente | Es | En `context/db/` |
> |---|---|---|
> | M01 | Identidad y onboarding | `modulo1.md` |
> | M02 | Perfil y Foco del Mes | `modulo2.md` |
> | M03 | Home | `modulo3.md` |
> | M04 | Ruta Despeje · deudas | `modulo4.md` |
> | **M05** | **Presupuesto Vivo** | `modulo6.md` ⚠️ |
> | **M06** | **Pagos** | `modulo7.md` ⚠️ |
> | **M07** | **Agente IA** | `modulo8.md` ⚠️ |
> | M10 | Monetización | `modulo10.md` |
>
> `context/db/modulo5.md` es **Cashflow**, que no es el M05 del cliente. Y la carpeta
> `context/modulo05-cashflow/` arrastra el mismo error en el nombre. Al citar un módulo,
> decir de qué numeración se habla.
>
> **2 · `context/` tiene dos clases de archivo que no se leen igual.**
> Lo de `bitacora/` es **registro histórico**: describe lo que era cierto ese día y no se
> actualiza. Todo lo demás debe estar vigente. Un dato de bitácora nunca es fuente para
> decidir hoy.

---

## Por dónde entrar

| Si vas a… | Leé |
|---|---|
| Entender el código por primera vez | [`context/wiki-codigo/`](context/wiki-codigo/) — **la puerta de entrada** |
| Tocar un módulo concreto | su carpeta `context/moduloNN-*/` (abajo) |
| Saber cómo se conectan los módulos | [`context/wiki-codigo/integracion-modulos.md`](context/wiki-codigo/integracion-modulos.md) |
| Ver el contrato de un endpoint | `back-walvy/docs/api/` — **vive en el repo del back, no acá** |
| Buscar por qué se decidió algo | [`context/decisions.md`](context/decisions.md) (20 decisiones) · [`context/bitacora/`](context/bitacora/) |

## Carpetas por módulo

Cada una tiene `contexto/` (cómo funciona), `deuda-tecnica/` (qué está abierto y de quién
es) y a veces `utils/`.

| Carpeta | Módulo | Estado del contexto |
|---|---|---|
| [`context/modulo01-identidad-autenticacion/`](context/modulo01-identidad-autenticacion/) | M01 | Vigente |
| [`context/modulo02-perfil-configuracion/`](context/modulo02-perfil-configuracion/) | M02 | Vigente |
| [`context/modulo04-motor-deudas/`](context/modulo04-motor-deudas/) | M04 | **Vigente y el más completo** — ver `motor-m04-en-detalle.md` |
| [`context/modulo05-presupuesto-vivo/`](context/modulo05-presupuesto-vivo/) | **M05 del cliente** · Presupuesto Vivo | Vigente · sin código todavía |
| [`context/modulo05-cashflow/`](context/modulo05-cashflow/) | Cashflow (⚠️ **no** el M05 del cliente) | Parcial |
| [`context/modulo10-monetizacion/`](context/modulo10-monetizacion/) | M10 | Vigente |

M03, M06 y M07 no tienen carpeta todavía. Sus entregables del cliente están en
`documentacion/`, fuera de este repo.

## Contexto transversal

| Archivo | Contenido |
|---|---|
| [`context/wiki-codigo/`](context/wiki-codigo/) | Backend, frontend, integración entre módulos y arquitectura del motor de reglas, sobre `origin/qa` |
| [`context/conventions.md`](context/conventions.md) | Naming, patrones de código, seguridad |
| [`context/decisions.md`](context/decisions.md) | 20 decisiones de diseño con su por qué |
| [`context/release-workflow.md`](context/release-workflow.md) | Ramas, releases, deploy manual, migraciones TypeORM |
| [`context/db/`](context/db/) | Schema por módulo — **ojo con la numeración de arriba** |
| [`context/mvp-scope.csv`](context/mvp-scope.csv) | Alcance MVP, exportado del Excel original. **Una columna en el schema no es una feature del MVP** |
| [`context/specs/`](context/specs/) | Especificaciones por módulo y el material del cliente de M01/M02 |
| [`context/testing.md`](context/testing.md) | Estrategia de testing y patrones E2E |
| [`context/qa-audits/`](context/qa-audits/) | 20 reportes pixel-perfect por pantalla, generados por `/walvy-qa-visual` |
| [`context/ios-adhoc-testing.md`](context/ios-adhoc-testing.md) | Distribución iOS ad hoc (EAS) |
| [`context/visual-design-rules.md`](context/visual-design-rules.md) | Reglas de materialización visual |
| [`context/bitacora/`](context/bitacora/) | **Histórico.** Un archivo por jornada o por tema |

`context/architecture.md` y `context/stack.md` están **congelados en junio de 2026** y
los reemplaza `wiki-codigo/`. Llevan el aviso arriba.

---

## Estado real, verificado contra `origin/qa` el 2026-09-06

Backend, por endpoints expuestos y suites de test:

| Módulo Nest | Endpoints | Suites | Notas |
|---|---|---|---|
| `auth` | 14 | 7 | |
| `debts` | 12 | 27 | **438 tests.** Motor P4 cableado; espera entradas de M05/M06 |
| `imports` | 15 | — | Pipeline de cartolas vía Kread |
| `cashflow` | 16 | — | |
| `subscriptions` | 8 | 2 | Flow.cl |
| `notifications` | 7 | — | |
| `users` | 5 | 8 | |
| `profile` | 4 | 2 | |
| `catalog` · `legal` · `health` · `dev` | 7 | — | |

Frontend, por pantallas: `auth` 15 · `debts` 10 · `profile` 6 · `subscription` 3 ·
`splash` 1. `home` no tiene pantalla propia todavía.

Existen además como módulos Nest sin endpoints todavía: `admin`, `ai`, `budget`,
`gamification`, `payments`, `storage`, `mail`.

> No poner acá una tabla de «sprints». La anterior decía que las deudas eran «⚠️ Schema,
> frontend ❌» cuando el módulo tenía 438 tests y diez pantallas, y desorientó a todo el
> que arrancó por este archivo. Si un estado no se puede verificar con un comando, no va.

---

## Agentes

Los `/walvy-*` viven en `~/.claude/skills/` (nivel usuario). Los de este repo están en
[`skills/`](skills/) y hay que **leerlos**, no invocarlos.

| Comando | Modelo | Cuándo |
|---|---|---|
| `/walvy-find` | Haiku | Lookup: archivo, endpoint, tabla, símbolo |
| `/walvy-backend` | Sonnet | NestJS: módulos, DTOs, entities, endpoints |
| `/walvy-db` | Sonnet | Schema, migraciones, entities TypeORM |
| `/walvy-frontend` | Sonnet | React Native, features, hooks, Expo Router |
| `/walvy-design` | Sonnet | UI pixel-perfect, Figma → RN |
| `/walvy-qa` | Sonnet | Tests y criterios de aceptación |
| `/walvy-arch` | Opus | Decisiones cross-cutting |
| `/walvy-ai` | Opus | Módulo de asistente IA |
| `/walvy-think` | Opus | Analizar un requerimiento antes de implementar |
| `/walvy-kora` | Sonnet | Cierre de jornada → entradas de bitácora |

En `skills/`, para leer:

| Archivo | Para qué |
|---|---|
| [`skills/walvy-audit.md`](skills/walvy-audit.md) | Auditar cambios en staged: front + back + correos + comentarios + commits |
| [`skills/walvy-backend-auditor.md`](skills/walvy-backend-auditor.md) | Auditoría de backend |
| [`skills/ui-visual-qa-reviewer.md`](skills/ui-visual-qa-reviewer.md) | Auditoría pixel-perfect contra Figma. No genera código |
| [`skills/senior-react-native-engineer.md`](skills/senior-react-native-engineer.md) | Criterio de RN/Expo |

---

## Repositorios y rutas

| Repo | GitHub | Ruta local |
|---|---|---|
| Backend | `KabeliDev/back-walvy` | `back-walvy/` |
| Frontend | `KabeliDev/front-walvy` | `front-walvy/` |
| Infra | `KabeliDev/walvy-platform-infra` | `walvy-platform-infra/` |
| Este workspace | `miguelherize-creator/walvy-workspace` | `workspace/walvy-workspace/` |

> `walvy-org/walvy-workspace` es **otro repo** —el sitio Docusaurus de infraestructura— y
> está clonado en `walvy-workspace/` en la raíz. Mismo nombre, contenido distinto. No
> confundirlos.

| Área | Ruta |
|---|---|
| Backend src | `back-walvy/src/` |
| Contratos de API | `back-walvy/docs/api/` |
| Frontend | `front-walvy/expo/` |
| Design tokens | `front-walvy/expo/constants/colors.ts` + `theme.ts` |
| E2E Playwright | `workspace/walvy-workspace/e2e/` |
| Entregables del cliente M04–M07 | `documentacion/` |

## Comandos

```bash
# Backend
cd back-walvy && npm run start:dev
npx jest src/debts              # 438 tests del motor M04

# Frontend
cd front-walvy/expo && bun run start

# E2E de UI (modo mock)
cd workspace/walvy-workspace/e2e && npm test
```
