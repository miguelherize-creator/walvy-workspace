# walvy-workspace

Capa de conocimiento de Walvy. No contiene código de producción: es lo que hace que
cualquiera —persona o agente— trabaje con el contexto correcto sin reconstruirlo desde
el historial.

**El índice operativo es [`CLAUDE.md`](CLAUDE.md).** Ahí están las rutas, el estado real
verificado contra `origin/qa` y las dos trampas de numeración que hay que conocer antes
de citar un módulo. Este README explica qué es el repo; ese explica cómo usarlo.

---

## Qué hay

```
walvy-workspace/
├── CLAUDE.md      ← índice operativo: rutas, estado real, agentes
├── context/       ← la base de conocimiento
│   ├── wiki-codigo/     ← cómo está construido el código, sobre origin/qa
│   ├── moduloNN-*/      ← un módulo: contexto + deuda técnica
│   ├── db/              ← schema por módulo
│   ├── specs/           ← especificaciones y material del cliente de M01/M02
│   ├── qa-audits/       ← reportes pixel-perfect por pantalla
│   ├── bitacora/        ← histórico por jornada · NO se actualiza
│   └── *.md             ← transversales: convenciones, decisiones, testing, releases
├── e2e/           ← tests Playwright sobre Expo Web
└── skills/        ← skills del proyecto, para leer
```

## Las dos reglas de lectura

**`bitacora/` es histórico.** Describe lo que era cierto ese día. Que una entrada de
agosto cite una regla que hoy no existe es correcto: así era entonces. **Nunca es fuente
para decidir hoy** — y por eso tampoco se depura por estar vieja.

**Todo lo demás debe estar vigente.** Si un documento quedó superado, lleva un aviso
arriba diciendo qué lo reemplaza. Si encontrás uno sin aviso y desactualizado, eso es un
defecto del repo, no una fuente alternativa.

## Cómo se mantiene

- **Los contratos de API viven en `back-walvy/docs/api/`**, no acá. Este repo explica
  cómo se conectan las piezas; el contrato de cada endpoint vive junto al código que lo
  sirve, para que se mueva con él.
- **Los entregables del cliente de M04 a M07 están en `documentacion/`**, fuera del
  repo. Los de M01 y M02 quedaron adentro, en `context/specs/wiki/onboarding/`, por
  razones históricas.
- **Un documento superado se marca, no se borra**, cuando explica de dónde salió una
  decisión que después se revirtió. Se borra cuando sólo puede confundir.
- **Todo número verificable lleva el comando que lo verifica.** «438 tests» vale porque
  hay un `npx jest src/debts` al lado.

## E2E Playwright

Tests de interfaz sobre Expo Web: `login`, `register`, `dashboard`, `forgot-password`,
`navigation`.

```bash
cd e2e && npm test                              # modo mock, sin backend
cd e2e && cross-env E2E_MODE=api npm test       # requiere PostgreSQL + backend
```

Estrategia completa en [`context/testing.md`](context/testing.md).

## Ecosistema

| Repositorio | Stack | Qué es |
|---|---|---|
| `back-walvy` | NestJS + PostgreSQL | API principal |
| `front-walvy` | Expo / React Native | App móvil y web |
| `walvy-platform-infra` | — | Infraestructura |
| Kread | FastAPI | Extracción y parseo de cartolas, equipo aparte |
| **`walvy-workspace`** | — | **Este repo** |

> Existe otro repo llamado `walvy-workspace` en la organización `walvy-org`: es el sitio
> Docusaurus de infraestructura y no tiene relación con este. Mismo nombre, contenido
> distinto.
