# Queries a la DB

Recetas para pgAdmin / psql. **Solo local o dev de prueba.** Nunca en producción.

En el backend local, `DB_HOST=localhost` + `DB_PORT=5433` suele ser el túnel SSM hacia RDS **dev**, no Postgres de Docker. Confirma el servidor en pgAdmin antes de borrar.

**Schema:** `context/db/` · **Baseline:** `back-walvy/src/migrations/`

## Cómo agregar una receta

Un archivo por operación. Título = lo que hace. Incluye el `SELECT` de inspección y el `DELETE`/`UPDATE` que se corre después.

## Archivos

| Receta | Archivo |
|---|---|
| Listar y borrar un usuario para re-probar registro / correo | [`borrar-usuario.md`](borrar-usuario.md) |
| Devolver un usuario al welcome del onboarding sin borrarlo | [`resetear-onboarding-al-welcome.md`](resetear-onboarding-al-welcome.md) |
| Ver status / restringir o reactivar una cuenta (M1-BC-005) | [`restringir-cuenta.md`](restringir-cuenta.md) |
