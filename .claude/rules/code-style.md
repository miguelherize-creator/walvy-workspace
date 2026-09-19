# Estilo de código

Detalle y ejemplos en `context/conventions.md` y `context/wiki-codigo/`.

- Backend: `pnpm`. Controller tonto, lógica en service y `rules/*.rule.ts`. Sin `any`. Excepciones Nest, no `throw new Error()`.
- Frontend: `bun`, nunca npm. Feature-First. `app/` son delegates de 2 líneas. Sin imports cross-feature.
- Comentarios: solo el *porqué*. Cero nodos Figma, cero `// 16px`.
- Commits: conventional, en español, con el ID de la regla del cliente (`M2-V65`), no el issue.
- Soft delete en `app_user`, movimientos y deudas. Sin tokens en logs.
- Contratos de API: `back-walvy/docs/api/`, en el mismo PR que el endpoint.
