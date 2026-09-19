# Harness de Claude — Walvy

Sistema operativo del repo. El contenido vive en `context/`.

| Carpeta | Qué es | Cómo se usa |
|---|---|---|
| `rules/` | Convenciones que Claude aplica solo | Siempre o al tocar el tema |
| `commands/` | Flujos que invocás | `/walvy-find`, `/walvy-kora`, … |
| `skills/` | Metodologías que se activan solas | audit, QA visual, RN, backend auditor |
| `agents/` | Subagentes especializados | reviewer, QA visual, cierre Kora |
| `settings.json` | Permisos compartidos | `settings.local.json` es personal |

Si Claude Code abre `Documents/Walvy`, hay un `CLAUDE.md` en esa raíz que apunta acá. Los commands/rules/skills de esa carpeta son **symlinks** a este `.claude/`.

## Context-mode

Está en [`.mcp.json`](../.mcp.json) (MCP). En Claude Code, lo más sólido es el plugin:

```
/plugin marketplace add mksglu/context-mode
/plugin install context-mode@context-mode
```

Después, indexá **solo vigente** (nunca bitácora ni xlsx del cliente):

```
ctx index CLAUDE.md context/README.md context/wiki-codigo context/modulo01-identidad-autenticacion context/modulo02-perfil-configuracion context/modulo04-motor-deudas context/modulo05-presupuesto-vivo context/modulo10-monetizacion context/cashflow context/conventions.md context/decisions.md context/testing.md
```

Los `/walvy-*` de `~/.claude/skills/` son de junio de 2026. Archiválos para que no pisen estos.
