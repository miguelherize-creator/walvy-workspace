---
description: Cierre de jornada. Commits del día + reuniones → entradas Kora y bitácora.
---

Cerrá la jornada del TL. No inventes commits.

## Flujo

1. Commits de hoy (omití repos vacíos):

```bash
TODAY=$(date +%Y-%m-%d)
for repo in back-walvy front-walvy workspace/walvy-workspace; do
  git -C "/Users/miguelherize/Documents/Walvy/${repo}" \
    log --oneline --since="$TODAY 00:00" --until="$TODAY 23:59" \
    --author="$(git config user.name)" 2>/dev/null
done
```

2. Pedí reuniones (nombre + duración) si no vinieron en el mensaje.
3. Proponé el trabajo técnico a partir de los commits. Si no hay, preguntá.
4. Jornada = 8 h salvo que indiquen otra. Técnicas = 8 − reuniones.
5. Generá las dos entradas Kora y guardá
   `context/historico/bitacora/YYYY-MM-DD.md` (append-only, nunca editar días viejos).

```
ENTRADA 1 — Reuniones
ENTRADA 2 — Trabajo técnico
```

Si otro DEV usa esta command, ajustá las rutas `Documents/Walvy/…`.
