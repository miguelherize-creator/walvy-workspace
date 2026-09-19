# walvy-workspace

Memoria compartida de Walvy. No hay código de producción: es lo que hace que
PM, PMO, DEV o un agente trabajen con el mismo contexto.

**El índice operativo es [`CLAUDE.md`](CLAUDE.md).** Este README explica qué es el repo.

---

## Tres capas

```
walvy-workspace/
├── CLAUDE.md                 ← trampas + “si vas a X, leé Y”
├── context/
│   ├── README.md             ← mapa de capas
│   ├── wiki-codigo/          ← VIGENTE · cómo está el código
│   ├── moduloNN-*/           ← VIGENTE · un módulo (numeración del cliente)
│   ├── cashflow/             ← VIGENTE · no es el M05 del cliente
│   ├── conventions.md · decisions.md · testing.md · …
│   ├── qa-audits/            ← VIGENTE · reportes pixel-perfect
│   ├── contratos/            ← se versiona, no se reescribe
│   │   ├── specs/            ← specs + material del cliente M01/M02
│   │   ├── db/               ← schema de diseño (gana el código)
│   │   └── mvp-scope.csv
│   └── historico/            ← append-only · no se usa para decidir
│       ├── bitacora/         ← un archivo por jornada
│       ├── congelado/        ← architecture.md y stack.md de junio
│       └── sueltos/          ← docs que no eran bitácora
├── .claude/                  ← harness: rules, commands, skills, agents
├── .cursor/rules/            ← las dos trampas, para Cursor
├── e2e/                      ← Playwright sobre Expo Web
└── skills/                   ← puntero a `.claude/skills/`
```

**Vigente** se actualiza cuando cambia el código. Si no se verifica con un comando, no entra.
**Contrato** se versiona (`v1.0`, `v2.6`). No se “corrige” un Excel del cliente.
**Histórico** se agrega, no se edita.

## Cómo se mantiene

- Los contratos de API viven en `back-walvy/docs/api/`, no acá.
- Los entregables del cliente de M04–M07 están en `documentacion/`, fuera del repo.
  M01 y M02 quedaron en `context/contratos/specs/wiki/onboarding/`.
- Un documento superado se marca o se mueve a `historico/`. Se borra solo si confunde.
- Un número verificable lleva el comando que lo verifica.

## E2E

```bash
cd e2e && npm test                         # mock, sin backend
cd e2e && cross-env E2E_MODE=api npm test  # PostgreSQL + backend
```

Estrategia en [`context/testing.md`](context/testing.md).
