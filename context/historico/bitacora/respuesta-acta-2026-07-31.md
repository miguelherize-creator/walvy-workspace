# Borrador de respuesta al acta del 2026-07-31

Rama: `feature/db-schema-regen-migrations` — PR https://github.com/Walvy-Finance/walvy-org/pull/243

---

Hola Jeaninne, hola Ana,

Gracias por el acta, quedó muy clara. Ya está listo el trabajo de base de datos
que acordamos. Va el detalle punto por punto.

Todo está en la rama `feature/db-schema-regen-migrations`, en el PR
**https://github.com/Walvy-Finance/walvy-org/pull/243**, dentro de la
organización de Walvy — con lo que también queda cubierto el punto 2 del acta.

## 1. Esquema cero y migraciones versionadas

**`DB/baseline/schema-cero-52-tablas.sql`** es el estado del backend en `main`,
tal cual: 52 tablas, 452 columnas, 44 claves foráneas, con sus defaults y sus
18 restricciones de unicidad. No es una guía escrita a mano — es el DDL que el
propio TypeORM emite para esas entidades, y está reproducido en la migración
`BaselineSchemaCero` con una guarda: sobre una base que ya existe se registra
como aplicada sin tocar nada, y sobre una base vacía la construye.

Sobre ese punto de partida hay **23 migraciones incrementales**, cada una con
`up` y `down`, que incorporan lo enviado en `migration.sql`, `seeds.sql` y
`comments.sql`.

Estado de la base que producen:

| | |
|---|---|
| Tablas | 77 + 4 vistas |
| CHECK | 95 |
| Índices | 154 |
| Claves foráneas | 114 |
| Triggers | 69 |
| Funciones | 12 |
| Comentarios de tabla y columna | 366 |

Cobertura de lo que nos enviaron:

- **`migration.sql`**: las 131 columnas de los 9 `ALTER` están aplicadas, y las
  14 tablas nuevas existen (`financial_rule`, `rule_parameter`, `debt_cycle`,
  `debt_signal`, `debt_recommendation`, `debt_projection`,
  `movement_user_validation`, `classification_learning_rule`, `budget_signal`,
  `budget_recommendation`, `recommendation_evidence`, `intermodule_derivation`,
  `functional_tag`, `functional_tag_assignment`).
- **`comments.sql`**: incorporado como metadata en las entidades, que es de
  donde la migración lo emite. Las 45 referencias `Fuente: BDD/Rector` viajan al
  catálogo de PostgreSQL, que era el punto.
- **`seeds.sql`**: `financial_rule` (3), `rule_parameter` (10), `app_config` (6),
  el dominio de status `debt_health` y el catálogo de categorías de José Miguel
  (11 padres / 97 subcategorías).
- **Blindaje en la base**: `enforce_status_domain()` con un trigger por cada
  columna `*_status_id`, `set_updated_at()` con su trigger por tabla, y las
  4 vistas de negocio (`v_user_access`, `v_user_current_subscription`,
  `v_subscription_effective_state`, `v_user_home_month`).

Cada migración se verificó igual: corre limpia sobre una base vacía, un
`migration:generate` posterior no reporta diferencias, y el `revert` devuelve el
esquema byte a byte al estado anterior. Además comparamos una base construida
desde cero por las migraciones contra la base de desarrollo actual con las
migraciones aplicadas: **son idénticas**.

**`DB/schema/schema.sql`** es el volcado de esa base, con el comando de
regeneración en su cabecera. Ya no se mantiene a mano ni se deriva de las
entidades: sale de las migraciones, que son la única vía para cambiar el
esquema.

## 7. RUT / documento de identidad

El documento se guarda como el modelo pide: `document_type_id` +
`document_number`, con el tipo resuelto contra el catálogo `document_type` por
país.

La unicidad es un índice único parcial sobre `(country_id, document_type_id,
document_number)` — parcial porque excluye las cuentas eliminadas. Con eso: un
RUT es de una sola cuenta, el segundo registro con el mismo documento se
rechaza en la base, y el `23505` se traduce a un `409 Conflict` con mensaje
usable. El login es por correo; el documento no sirve para autenticar.

**Pendiente**: la encriptación del RUT sigue abierta con José Miguel.

## 8. `identifier_type` y `username`

`identifier_type` está **eliminado**. No quedan referencias en el código.

`username` **no es único**: solo tiene un índice de consulta parcial. Queda como
alias, tal como se acordó.

## 9. Usuarios administrativos y auditoría

`admin_users` y `admin_audit_log` están **retiradas**. En su lugar:

- `permission` y `role_permission` con los 12 permisos base y su asignación por
  rol: `admin` todos, `support` solo los de lectura, el usuario final todo menos
  `admin.*`. Todavía no se evalúan por endpoint —el guard sigue siendo por rol—
  pero el catálogo ya es el contrato para cuando eso entre.
- `audit_log` absorbió `admin_audit_log` ganando `before_data` y `after_data`.
  La auditoría es transversal: una sola tabla para cualquier actor.

El retiro de `admin_users` se hizo con una guarda que impide perder cuentas
administrativas existentes.

## Cuatro puntos que les devolvemos

Al aplicar la entrega aparecieron cuatro cosas que conviene corregir del lado
del modelo:

1. **`app_user_username_key`.** Su `schema.sql` declara un índice único sobre
   `username`, que contradice el acuerdo 8 del acta. El backend está correcto;
   lo que hay que corregir es el modelo.
2. **`comments.sql` comenta 65 columnas dos veces**, con textos distintos. Si se
   ejecuta tal cual, gana la segunda —la genérica— y se pierde la que trae
   `Fuente: BDD/Rector`, que es justamente la trazabilidad que motiva el
   archivo. Nosotros adoptamos la primera.
3. **`file_upload`** trae `requires_password` y `password_required` para el mismo
   hecho, y `document_processing_status` y `document_business_type` declaradas
   dos veces con anchos distintos. Adoptamos el más ancho en cada caso.
4. **`debt_type`.** El modelo fija cinco valores; el producto usa ocho, y los
   cinco no cubren `deuda_informal`, `credito_automotriz` ni `prestamo_personal`.
   Por eso ese CHECK no se puso: preferimos acordar el vocabulario antes de
   fijarlo en la base.

Además, `payment_order` en su modelo no tiene `plan_id`. Lo conservamos porque
entre el checkout y la activación todavía no existe suscripción, así que es el
único lugar donde vive qué plan se está comprando. Junto con él llevamos a la
sesión otras cuatro tablas nuestras que el modelo no contempla —`bills_payable`,
`financial_health_snapshots`, `recommendation_events` y `statement_imports`—
para decidir si se mantienen, se mapean o se retiran.

## Lo que falta del modelo

Quedan **10 tablas**, todas latentes y sin servicio encima, así que pueden
entrar en cualquier momento sin competir con la regresión:

- mensajería (3): `message_rule`, `message_event`, `user_message_interaction`
- empresa y beneficios (3): `company_benefit_contract`,
  `company_eligible_employee`, `benefit_invitation`
- sueltas (4): `country_currency`, `debt_payoff_schedule`,
  `movement_review_queue`, `movement_classification_history`

Y dos brechas de blindaje que preferimos declarar antes que dejar que aparezcan
en la revisión: faltan **38 CHECK** y **17 índices** del modelo sobre tablas que
ya existen — sobre todo el vocabulario funcional de M4 en `debt` (11),
`user_onboarding_state` (6) y `user_goals` (3). Las columnas están todas; lo que
falta es fijar los valores permitidos. Va en el próximo ciclo.

## 3, 5 y 6. Ambientes, API de cartolas y regresión

**Ambiente de Walvy.** La base allá está vacía, que es el mejor escenario: se
crea la base y se corre `migration:run`. Las 23 migraciones la construyen desde
cero con triggers, vistas, índices y comentarios incluidos. Es importante que
ese ambiente arranque con `synchronize` apagado: si se deja que TypeORM cree el
esquema por su cuenta, se pierden exactamente los objetos que el acta señala
como faltantes. Con eso la base queda consultable por ambas partes.

**Dump de Sandbox.** Pendiente de nuestro lado; lo coordinamos para enviarlo.

**API de cartolas v1 → v2.** Pendiente. Proponemos cerrarlo en una sesión
aparte, con el detalle de qué versión usa cada módulo y los contratos de entrada
y salida documentados.

**Trazabilidad de pruebas.** Pendiente. Proponemos partir por Módulo 1 y 2:
criterio funcional → caso de prueba → evidencia de ejecución → resultado en base
de datos, y de ahí extenderlo.

**Evidencia de cómo viaja la información del Módulo 1.** Pendiente, y depende
del punto siguiente.

## Próximos pasos que proponemos

1. Revisión de la base con ustedes para aprobar el esquema y las migraciones.
2. En paralelo, repasamos los endpoints del Módulo 1 que consume el front de
   `main`, para confirmar que el cambio de esquema no los afectó.
3. Levantar el backend en el ambiente de Walvy corriendo la cadena de
   migraciones sobre una base vacía.
4. Regresión de QA sobre Módulos 1 y 2 con esa base.
5. Con eso cerrado, la evidencia de request/response y datos persistidos del
   Módulo 1 sale de la propia ejecución de regresión.
6. Certificación del Módulo 4.

Quedamos atentos para agendar la revisión.

Saludos,
Miguel
