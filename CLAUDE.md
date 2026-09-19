# Walvy — índice operativo

**App de finanzas personales para Chile.** NestJS 11 + Expo 54 + PostgreSQL 16.
**Código de referencia:** `origin/qa`. **Este repo no se despliega:** es la memoria compartida.

Leé [`context/README.md`](context/README.md) si no sabés en qué capa está un archivo.

---

## Dos trampas (antes de citar un módulo)

**1 · Dos numeraciones, corridas desde M05.** Usá siempre la del cliente. `context/contratos/db/` usa otra:

| Cliente | Es | En `contratos/db/` |
|---|---|---|
| M01 | Identidad y onboarding | `modulo1.md` |
| M02 | Perfil y Foco del Mes | `modulo2.md` |
| M03 | Home | `modulo3.md` |
| M04 | Ruta Despeje | `modulo4.md` |
| **M05** | **Presupuesto Vivo** | `modulo6.md` |
| **M06** | **Pagos** | `modulo7.md` |
| **M07** | **Agente IA** | `modulo8.md` |
| M10 | Monetización | `modulo10.md` |

`contratos/db/modulo5.md` y `context/cashflow/` son **Cashflow**, no el M05 del cliente.

**2 · Histórico ≠ vigente.** `context/historico/` describe lo que era cierto ese día. No se actualiza y **nunca es fuente para decidir hoy**.

---

## Si vas a…

| Rol / tarea | Entrá por |
|---|---|
| DEV, primer día | [`context/wiki-codigo/`](context/wiki-codigo/) |
| Tocar un módulo | su `context/moduloNN-*/contexto/README.md` |
| PM / contrato del cliente | [`context/contratos/`](context/contratos/) |
| PMO / por qué se decidió | [`context/decisions.md`](context/decisions.md) |
| QA visual | [`context/qa-audits/`](context/qa-audits/) |
| Cierre de jornada | [`context/historico/bitacora/`](context/historico/bitacora/) |
| Contrato de un endpoint | `back-walvy/docs/api/` — vive en el back, no acá |

## Módulos (numeración del cliente)

| Carpeta | Qué es | Contexto |
|---|---|---|
| [`modulo01-identidad-autenticacion/`](context/modulo01-identidad-autenticacion/) | M01 · auth y onboarding | Organizado |
| [`modulo02-perfil-configuracion/`](context/modulo02-perfil-configuracion/) | M02 · perfil y Foco del Mes | Organizado |
| [`modulo04-motor-deudas/`](context/modulo04-motor-deudas/) | M04 · Ruta Despeje | El más completo |
| [`modulo05-presupuesto-vivo/`](context/modulo05-presupuesto-vivo/) | M05 · Presupuesto Vivo | Contrato, sin código |
| [`cashflow/`](context/cashflow/) | Cashflow (no es M05) | Inventario de código |
| [`modulo10-monetizacion/`](context/modulo10-monetizacion/) | M10 · Flow / suscripciones | Organizado |

M03, M06 y M07 no tienen carpeta. Sus entregables están en `documentacion/`, fuera de este repo.

En M01, M02 y M04: si no está enlazado desde el índice del módulo, no existe.

## Repos

| Repo | GitHub | Ruta |
|---|---|---|
| Backend | `KabeliDev/back-walvy` | `back-walvy/` |
| Frontend | `KabeliDev/front-walvy` | `front-walvy/expo/` |
| Infra | `KabeliDev/walvy-platform-infra` | `walvy-platform-infra/` |
| Esta memoria | `miguelherize-creator/walvy-workspace` | `workspace/walvy-workspace/` |

`walvy-org/walvy-workspace` es **otro repo** (Docusaurus de infra). No confundir.

```bash
cd back-walvy && pnpm run start:dev
cd front-walvy/expo && bun run start
cd workspace/walvy-workspace/e2e && npm test
```

Harness: [`.claude/`](.claude/). Commands `/walvy-find` · `/walvy-backend` · `/walvy-frontend` · `/walvy-db` · `/walvy-qa` · `/walvy-design` · `/walvy-think` · `/walvy-arch` · `/walvy-ai` · `/walvy-kora` (escribe en `context/historico/bitacora/`).
