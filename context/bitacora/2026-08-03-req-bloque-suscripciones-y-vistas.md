# Requerimiento — bloque de suscripciones y las 4 vistas de negocio

Fecha: 2026-08-03
Estado: **pendiente**, para sesión propia
Rama base: `feature/db-schema-regen-migrations` (18 migraciones, 74 tablas)

## Por qué existe este documento

Es lo último que falta para cerrar el modelo objetivo, y es la única pieza que
toca el flujo de pagos. Se separa a propósito: el acta de reunión programa una
regresión de QA sobre Módulo 1 y 2, y meter cambios en el checkout de Flow.cl
justo antes es mal momento.

Cerrarlo desbloquea de una vez **6 de las 16 tablas pendientes** y **las 4 vistas
de negocio (F5)**, que hoy no se pueden escribir.

## Alcance

### 6 tablas

| Tabla | Cols | Origen |
|---|---|---|
| `plan` | 7 | renombre de `subscription_plans`, sacando precio y moneda |
| `plan_price` | 10 | nueva: precio por país y moneda, bitemporal |
| `subscription` | 25 | renombre de `subscriptions`, +20 campos |
| `payment_order` | 14 | renombre de `payment_orders` |
| `payment_method` | 14 | nueva: métodos tokenizados, sin datos PCI |
| `user_payment` | 18 | nueva: agenda de pagos del usuario |

### 4 vistas (F5)

- `v_user_access` — modo de acceso: `subscription` / `trial` / `none`
- `v_user_current_subscription` — última suscripción por usuario
- `v_subscription_effective_state` — marca `expired_by_time` cuando `ends_at`
  ya pasó aunque el job de expiración no haya corrido
- `v_user_home_month` — compone el summary del mes, el acceso y el nivel de
  salud financiera para la pantalla Home

Las tres primeras leen de `subscription`. La cuarta depende de `v_user_access`.
Por eso ninguna se puede escribir antes del renombre.

## Por qué está bloqueado hoy

`v_user_access` necesita tres cosas que nuestra tabla no tiene:

| La vista pide | `subscriptions` tiene |
|---|---|
| `subscription_status_id` (FK a `status`, dominio `subscription`) | `status varchar(32)` |
| `ends_at` | `current_period_end` |
| `origin` (B2B / B2C) | no existe |

Escribir las vistas contra el esquema actual significa inventar vistas propias y
rehacerlas cuando llegue el renombre. No es adoptar el modelo.

## La circularidad de `plan_price`

Es el nudo que ha mantenido este bloque parado desde el principio:

```
plan_price.plan_id  →  plan(plan_id)      pero hoy la tabla es subscription_plans(id)
subscription.plan_price_id  →  plan_price  que aún no existe
```

Y el modelo **saca `price` y `currency` de la tabla de planes** hacia
`plan_price`. Eso no es un renombre: es mover datos de una tabla a otra, con la
lógica de precio vigente (`valid_from` / `valid_to`, índice único parcial sobre
`is_active AND valid_to IS NULL`).

Orden que resuelve el nudo:

1. `plan` — renombrar `subscription_plans`, dejando `price`/`currency` en su
   sitio de momento.
2. `plan_price` — crear, y migrar cada `plan.price` + `plan.currency` a una fila
   con `valid_from = created_at` del plan y `valid_to = NULL`.
3. Retirar `price` y `currency` de `plan`.
4. `subscription` — renombrar y ampliar; `plan_price_id` ya puede apuntar.
5. `payment_order`, `payment_method`, `user_payment`.
6. Las 4 vistas.

## Impacto en código

Tres servicios vivos, ~750 líneas, más sus specs:

```
src/subscriptions/services/payment-processing.service.ts   380   checkout, webhook, verify
src/subscriptions/services/flow.service.ts                 222   cliente HTTP de Flow.cl
src/subscriptions/services/subscriptions.service.ts        144   planes, mi suscripción, cancelar
src/subscriptions/services/subscription-seed.service.ts     80   siembra los planes
+ payment-processing.service.spec.ts (271) y subscriptions.service.spec.ts (161)
```

Endpoints afectados, todos bajo `/subscriptions`:

```
GET  plans           POST checkout          POST verify-payment
GET  me              POST webhook           GET/POST return
POST me/cancel
```

**El front no consume ninguno.** El riesgo es interno, pero es el flujo de pagos:
`handleWebhook`, `handleSubscriptionCharge`, `activateSubscription` y
`applyFlowPaymentStatus` leen y escriben las tres tablas que se renombran.

Punto a respetar del comportamiento actual: los callbacks de Flow.cl **no traen
firma `s`**, así que la verificación se hace consultando `getStatus`, no
validando el body. No cambiar eso al reescribir.

## Decisiones a tomar antes de empezar

1. **`subscriptions.status` → `subscription_status_id`.** El dominio
   `subscription` ya está sembrado con active / cancelled / expired / paused; el
   modelo añade `trialing`. Hay que mapear los valores existentes y decidir qué
   pasa con `trialing`, que hoy se infiere de `app_user.trial_ends_at`.
2. **`flow_customer_id` / `flow_subscription_id` → `provider` +
   `external_subscription_ref`.** El modelo generaliza a multi-proveedor. Hay
   que decidir si se migra el dato o se deja `provider = 'flow'` fijo.
3. **Gifting.** El modelo trae `is_gift`, `gift_token UNIQUE`, `gift_recipient_email`,
   `gift_sender_*`, `gift_redeemed_at`. No hay nada de eso en el producto hoy:
   confirmar si entra en el MVP o se crean las columnas latentes.
4. **`company_id` en `subscription`.** Depende de `company`, que ya existe, pero
   el canal B2B no está implementado. Misma pregunta.
5. **Precio histórico.** `subscription.billed_amount` congela lo cobrado. Para
   las suscripciones existentes hay que decidir si se rellena desde el plan
   actual o se deja nulo.

## Verificación exigida

La misma que se aplicó a las 18 migraciones anteriores, más lo específico de
pagos:

- `migration:run` limpio sobre la base de desarrollo con datos.
- `migration:generate` posterior sin drift.
- `revert` restaura un esquema byte a byte idéntico **y los datos de precios**.
- La app arranca con `synchronize` apagado y siembra los planes.
- Los specs de `payment-processing` y `subscriptions` pasan.
- Prueba explícita del webhook: un `handleWebhook` con un token conocido debe
  activar la suscripción igual que antes del cambio.
- Las 4 vistas devuelven filas coherentes para un usuario en trial, uno con
  suscripción activa y uno sin nada.

## Qué queda después de esto

Con este bloque cerrado, del modelo objetivo quedarían **10 tablas**:

- mensajería (3): `message_rule`, `message_event`, `user_message_interaction`
- empresa/beneficios (3): `company_benefit_contract`, `company_eligible_employee`,
  `benefit_invitation`
- sueltas (4): `country_currency`, `debt_payoff_schedule`,
  `movement_review_queue`, `movement_classification_history`

Las diez son latentes y sin servicio encima, así que pueden ir en cualquier
momento y no compiten con la regresión de QA.
