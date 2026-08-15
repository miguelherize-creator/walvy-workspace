# Bloque de suscripciones y las 4 vistas (hecho)

Fecha: 2026-08-03
Rama: `feature/db-schema-regen-migrations` (23 migraciones, 78 tablas + 4 vistas)
Cierra: [`2026-08-03-req-bloque-suscripciones-y-vistas.md`](2026-08-03-req-bloque-suscripciones-y-vistas.md)

## Decisiones tomadas antes de empezar

| Punto | Decisión |
|---|---|
| `subscription.user_id` único | **Se retira.** La tabla deja de ser 1:1; los servicios leen la última por `created_at`. Es lo que hace posible `v_user_current_subscription`. |
| `payment_order.plan_id` | **Se conserva** aunque no esté en el modelo. Entre el checkout y la activación no existe suscripción, así que es el único lugar donde vive qué plan se compra. A la sesión de revisión con las otras 4 propias. |
| Gifting y `company_id` | Columnas latentes, con sus CHECK. El producto no las usa; los valores por defecto (`is_gift = false`, `origin = 'B2C'`) son consistentes. |
| `billed_amount` histórico | Se rellena desde la última orden pagada de cada suscripción — la única fuente real de lo cobrado. Sin orden, queda NULL. |
| `flow_customer_id` | Se retira: se escribía y no lo leía nadie. El modelo guarda la referencia al cliente en `payment_method.provider_customer_ref`. |
| `plan.features` | Se retira. Texto de marketing que solo escribía el seed; el modelo no lo contempla. |

## Las 5 migraciones

| # | Migración | Qué hace |
|---|---|---|
| A | `PlanAndPlanPrice` | `subscription_plans` → `plan`; el precio sale a `plan_price` versionado por país y moneda, con `uq_plan_price_active`. `billing_interval_days` → `billing_period`. |
| B | `RenameSubscription` | `subscriptions` → `subscription` con las 25 columnas del modelo. Sin UNIQUE en `user_id`. `status` → `subscription_status_id`. |
| C | `PaymentOrderAndAgenda` | `payment_orders` → `payment_order` (`currency_id` FK, `provider_token`, `paid_at`); crea `payment_method` y `user_payment` latentes. |
| D | `BusinessViews` | Las 4 vistas como `@ViewEntity`, con `dependsOn` en la que compone `v_user_access`. |
| E | `SubscriptionBlockTriggers` | Repone los triggers que el renombre dejó descubiertos. |

## El paso que casi se pierde

Las tablas renombradas **se llevaron sus triggers**. `EnforceStatusDomain` y
`SetUpdatedAtTriggers` habían corrido cuando `plan`, `subscription` y
`payment_order` se llamaban de otra forma o no existían, así que tras el
renombre la cuenta bajó de 63 a 60 y las tres tablas nuevas nunca los tuvieron.
Sin la migración E, `subscription.updated_at` no se movía con un UPDATE directo
y `subscription_status_id` aceptaba un estado de cualquier dominio. Quedan 69
triggers y se cierran tres de los cinco `*_status_domain` que el modelo tenía
pendientes: solo faltan `message_event` y `review_queue`.

## Dos bugs de `down()` que solo aparecen al revertir la cadena entera

Cada revert individual pasaba, pero la cadena completa se rompía dos escalones
más abajo: al recrear `payment_orders` y `subscriptions`, los `down` no reponían
sus FK entrantes, y la migración anterior las buscaba por nombre para soltarlas.

```
constraint "FK_306b3df5b39ba91ca7796674d54" of relation "payment_orders" does not exist
constraint "FK_e45fca5d912c3a2fab512ac25dc" of relation "subscriptions" does not exist
```

Corregido en los dos `down`. **Verificar el revert de una migración sola no
alcanza** cuando la cadena renombra tablas: hay que desandar el tramo completo.

## Cambios de contrato

Ningún endpoint del front consume `/subscriptions`, así que el riesgo es interno.

- `GET /subscriptions/plans` devuelve `{ id, code, nameEs, billingPeriod, price, currencyCode }`. Antes traía `slug`, `name`, `price`, `currency`, `features`. El precio ahora sale de `plan_price` vigente.
- `GET /subscriptions/me` conserva los nombres publicados (`status`, `currentPeriodStart`, `currentPeriodEnd`) proyectados desde `subscription_status.code`, `starts_at` y `ends_at`. La forma no cambia.
- `POST /subscriptions/checkout` resuelve el precio por el país y la moneda del usuario y **falla** si no hay uno vigente, en vez de caer a otro.
- Fin de período con aritmética de calendario: un plan mensual vence el mismo día del mes siguiente, no 30 días después.
- `PaymentOrderStatus` adopta el vocabulario del modelo. `rejected` y `cancelled` se guardan como `failed`; Flow los distingue (3 vs 4) y esa diferencia sigue en `provider_response` y en el valor que devuelve el servicio.

## Verificación

| Prueba | Resultado |
|---|---|
| Base vacía → `migration:run` | 23 migraciones, 78 tablas + 4 vistas |
| `migration:generate` tras cada fase | sin drift, las cuatro veces |
| `revert` del tramo completo → `run` | esquema idéntico byte a byte |
| Clon de la base de desarrollo (30 usuarios, 2 planes) | 23 migraciones limpias, planes con su precio vigente, usuarios intactos |
| **Base construida por synchronize vs. desde cero** | **idénticas**, salvo la marca del esquema cero |
| Las 4 vistas con datos | trial / subscription / none correctos para tres usuarios distintos |
| Triggers | el de dominio rechaza un status ajeno (`23514`); `set_updated_at` mueve la fecha en un UPDATE directo |
| Tests | 59/59, incluidos los 27 de suscripciones |
| App con `synchronize` apagado | arranca y siembra sin errores, sin drift después |

## Lo que queda del modelo

10 tablas, todas latentes y sin servicio encima:

- mensajería (3): `message_rule`, `message_event`, `user_message_interaction`
- empresa/beneficios (3): `company_benefit_contract`, `company_eligible_employee`, `benefit_invitation`
- sueltas (4): `country_currency`, `debt_payoff_schedule`, `movement_review_queue`, `movement_classification_history`

Y las 4 tablas propias que su modelo no contempla, para defender en la sesión:
`bills_payable`, `financial_health_snapshots`, `recommendation_events`,
`statement_imports`. (`typeorm_metadata` es contabilidad de TypeORM para las
vistas, no del modelo.)

## Pendiente relacionado

`jest` no corre en este entorno sin un arreglo previo: `write-file-atomic@5`
resuelve un `signal-exit@3` anidado que no exporta `onExit`, y toda suite falla
con `jest: failed to cache transform results`. Es del árbol de dependencias, no
del código — se destraba borrando `node_modules/write-file-atomic/node_modules/signal-exit`,
pero `pnpm install` lo repone. El arreglo real va en el lockfile.
