# F1 — Esquema cero reproducible (hecho)

Fecha: 2026-08-03
Rama: `feature/db-schema-regen-migrations` (19 migraciones, 74 tablas)
Cierra: F1 de [`2026-08-03-plan-mejora-post-reunion.md`](2026-08-03-plan-mejora-post-reunion.md)

## El punto de partida sí era `main`, pero el archivo no servía

`DB/baseline/schema-cero-52-tablas.sql` era byte a byte `main:DB/schema/schema.sql`
—52 tablas, 452 columnas, las mismas que las 52 entities de `main`—, así que el
punto de partida estaba bien elegido. El problema era el formato: lo generaba
`gen-schema.ts`, que emite columna + tipo + NOT NULL + DEFAULT **literal** + PK +
FK, y nada más.

Medido contra el DDL real (Postgres vacío + `synchronize` de las entities de `main`):

| | Real | El archivo |
|---|---|---|
| Tablas / columnas / PK / FK | 52 / 452 / 52 / 44 | idénticos ✅ |
| DEFAULT | 179 | 49 |
| UNIQUE | 18 | 0 |
| Extensión `uuid-ossp` | necesaria | ausente |

Los 130 DEFAULT que faltaban eran los de función: 47 PK con `uuid_generate_v4()`,
45 `created_at` y 30 `updated_at` con `now()`. `gen-schema.ts` los descarta
explícitamente (`typeof c.default !== 'function'`).

Las 18 UNIQUE perdidas no eran cosméticas: `app_user(email)`,
`category(category_code)` —la que sostiene el `ON CONFLICT` del reseed de
categorías del cliente—, `payment_orders(commerce_order)` —idempotencia del
webhook de Flow—, `payment_orders(flow_token)`, `subscriptions(user_id)`,
`subscriptions(flow_subscription_id)`, `email_verification_tokens(token_hash)` y
los `code` de los siete catálogos.

Construir la migración baseline con ese archivo habría dado 52 tablas donde
ningún INSERT genera su PK y sin unicidad de email — y el drift habría aparecido
justo en el entorno nuevo, porque en la base de desarrollo la guarda lo salta.

## Migración `1785500000000-BaselineSchemaCero`

El DDL no se escribió a mano ni se derivó de la guía: son las 96 sentencias que
`createSchemaBuilder().log()` emite para las entities de `main` — 52 CREATE TABLE
con sus PK/UNIQUE en línea, 44 ALTER de FK. Por eso conserva los nombres hash de
constraint (`PK_`/`UQ_`/`FK_`) que la base de desarrollo ya tiene y que las
migraciones siguientes referencian por nombre.

Dos guardas, una por sentido:

- `up`: `if (await queryRunner.hasTable('app_user')) return;` — en una base que ya
  existe se registra como aplicada sin tocar nada.
- `down`: sólo borra si encuentra la marca `walvy:baseline-schema-cero` en el
  comentario del schema, que `up` deja al construir. Sin ella no se puede
  distinguir una base que esta migración creó de una que se encontró hecha, y el
  `down` borraría 52 tablas ajenas.

## Verificación

| Prueba | Resultado |
|---|---|
| Base vacía → `migration:run` | 19 migraciones, 74 tablas + `migrations` |
| `migration:generate` posterior | sin drift |
| 19 `revert` sobre esa base | vuelve a 0 tablas, marca limpiada |
| Base de desarrollo clonada (52 tablas, 30 usuarios) → `migration:run` | baseline registrada sin ejecutar nada; 30 usuarios intactos |
| 19 `revert` sobre el clon | se detiene en las 52 tablas originales, datos intactos |
| **`pg_dump` de las dos bases** | **idénticos byte a byte** |
| App con `synchronize` apagado sobre la base nueva | arranca y siembra sin errores; sin drift después |

El diff byte a byte entre la base construida por el baseline y la construida por
`synchronize` es la prueba que importa: el esquema cero reproduce exactamente lo
que había, no una aproximación.

Aparte, quedó confirmado que **la cadena no corre hoy sobre la base de desarrollo
sin limpiar antes los documentos duplicados**: 29 cuentas con `12345678-5`
rompen `uq_app_user_document`. Es la Fase 0 del plan de adopción, sigue abierta, y
como TypeORM envuelve toda la corrida en una transacción, el fallo revierte
también las migraciones anteriores.

## Los dos .sql ahora salen de las migraciones

`gen-schema.ts` se eliminó: el sentido correcto es migración → base → entities, no
entities → archivo. Los dos artefactos se regeneran volcando una base construida
por la cadena, con el comando en su cabecera:

| Archivo | Contenido |
|---|---|
| `DB/baseline/schema-cero-52-tablas.sql` | 52 tablas, 179 DEFAULT, 18 UNIQUE, 44 FK — sólo el baseline aplicado |
| `DB/schema/schema.sql` | 74 tablas, 77 CHECK, 44 índices, 98 FK, 63 triggers, 9 funciones, 352 comentarios |

El `schema.sql` anterior estaba mantenido a mano y declaraba 41 CHECK cuando hay
77, con los 63 triggers escritos como comentarios en vez de DDL. Era el archivo
que el acta pide enviar como "esquema real desde el código".

## Pendiente que esto dejó a la vista

`src/cashflow/data/category.seed.json` sigue con el catálogo de prueba de 20
padres / 98 subs, y `SEED_CASHFLOW=true` en `.env`: al arrancar la app contra la
base nueva se sembró ese catálogo, no el del cliente (11 padres / 97 subs, que
vive en `DB/migrations/2026-07-06_reseed_categorias_cliente.sql` y se aplicó a
mano). Un entorno nuevo nace hoy con el catálogo equivocado.
