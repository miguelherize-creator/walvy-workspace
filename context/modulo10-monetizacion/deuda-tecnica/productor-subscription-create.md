# Productor — checkout recurrente (`subscription/create`)

Estado: **pendiente**. Es la pieza que falta para cerrar el ciclo recurrente: hoy el consumidor (webhook) y la cancelación están listos, pero **nada crea la suscripción en Flow ni guarda `flow_subscription_id`**, así que la rama recurrente nunca se dispara en producción. Relacionado: [`README.md`](../contexto/README.md), [`cambios-implementados.md`](../contexto/cambios-implementados.md).

---

## 1. Objetivo

Reemplazar el checkout de **pago único** (`payment/create`) por el flujo de **Suscripciones de Flow**: registrar la tarjeta del cliente y crear una suscripción que Flow cobra automáticamente cada período. Guardar los ids de Flow para correlacionar cobros (webhook) y cancelar.

## 2. Estado actual (verificado)

- `PaymentProcessingService.checkout` usa `payment/create` (one-time) y devuelve `{ paymentUrl, flowToken }` — `back-walvy/src/subscriptions/services/payment-processing.service.ts:49`.
- Ya existen en `Subscription`: `flow_customer_id`, `flow_subscription_id` (agregadas para el webhook).
- **Falta**: `flow_plan_id` en `SubscriptionPlan`; y persistir el `customerId` de Flow (por usuario).
- El **consumidor está listo**: en cuanto exista una sub con `flow_subscription_id`, el webhook sincroniza cobros vía `subscription/get` (hoy cae en la rama fallback).
- El **harness** (`flow-sandbox-harness.js`) ya hace estos pasos a mano → es la referencia 1:1 de lo que el productor debe automatizar.

## 3. Flujo objetivo

```
checkout(planId)
  → (si el user no tiene customerId) customer/create (externalId = userId)  → customerId  [persistir]
  → customer/register (url_return = FLOW_RETURN_URL)                        → { url, token }
  → return { registerUrl }   // la app abre el browser para ingresar tarjeta

/subscriptions/return  (Flow redirige tras registrar tarjeta, con token)
  → customer/getRegisterStatus(token)     → ¿status 1 (registrada)?
  → subscription/create(flowPlanId, customerId)   → { subscriptionId, period_end, ... }
  → upsert Subscription local (flow_customer_id, flow_subscription_id, plan, status)
  → redirect a walvy://subscriptions/result   // deep link ya implementado

[Flow cobra el 1er invoice y los recurrentes]
  → urlCallback → webhook → handleSubscriptionCharge (YA implementado)
```

### Endpoints de Flow (ver OpenAPI / README §3)
`plans/create` · `customer/create` · `customer/register` · `customer/getRegisterStatus` · `subscription/create`.

## 4. Cambios por pieza

| Pieza | Cambio |
|---|---|
| **`SubscriptionPlan`** | Agregar `flow_plan_id` (varchar). |
| **Persistencia customerId** | Guardar el `customerId` de Flow por usuario (ver decisión D1). |
| **`SubscriptionSeedService`** | Al boot, upsert de planes también en Flow (`plans/create` con `interval` 3/4, `urlCallback`) y guardar `flow_plan_id`. |
| **`FlowService`** | Agregar `createCustomer`, `registerCard`, `getRegisterStatus`, `createSubscription`. (`getSubscription`/`cancelSubscription` ya existen.) |
| **`checkout`** | De `payment/create` → `customer/create` (idempotente) + `customer/register`; devolver la URL de registro de tarjeta. |
| **`/subscriptions/return`** | Tras registrar tarjeta: `getRegisterStatus` → `subscription/create` → upsert de la `Subscription` local. Luego el redirect al deep link (ya existe). |
| **Frontend** | El checkout sigue abriendo un browser (igual que hoy con `openAuthSessionAsync`), solo cambia que la URL es de registro de tarjeta. El retorno por deep link ya funciona. |

## 5. Plan de implementación (fases)

1. **Modelo + FlowService**: `flow_plan_id`, persistencia de `customerId`, y los 4 métodos nuevos de `FlowService` (+ tests unitarios con fetch mockeado).
2. **Seed de planes en Flow**: `SubscriptionSeedService` crea/actualiza los planes en Flow y guarda `flow_plan_id`.
3. **checkout**: refactor a registro de tarjeta.
4. **return → activación**: `getRegisterStatus` + `subscription/create` + upsert local.
5. **E2E sandbox** con el harness/app (requiere el contrato de Flow habilitado).

## 6. Decisiones / preguntas abiertas

- **D1 — ¿Dónde guardar `flow_customer_id`?** Recomendado: en **`app_user`** (el customer es por usuario y se reutiliza al re-suscribirse), además de la copia en `Subscription`. Hoy solo está en `Subscription`.
- **D2 — ¿Cuándo se dispara `subscription/create`?** Recomendado: en `/subscriptions/return` tras confirmar `getRegisterStatus`. Alternativa: usar también el callback de registro. Definir el manejo si el usuario cierra el browser antes de volver.
- **D3 — Registro OK pero `subscription/create` falla**: ¿reintento automático, o un endpoint "activar" idempotente que la app pueda reintentar? (Evitar cobrar sin dejar la sub creada.)
- **D4 — Trial**: Walvy ya maneja su propio trial en `app_user`. Recomendado: `trial_period_days=0` en Flow (cobro inmediato al crear la sub); no duplicar trial.
- **D5 — Re-suscripción**: usuario que canceló y vuelve → reutilizar su `customerId` y crear una nueva `subscription`. Confirmar que Flow permite re-suscribir un customer existente.
- **D6 — Cambio de plan** (mensual ↔ anual): ¿usar `subscription/changePlan` de Flow o cancelar+crear? (Puede quedar fuera de MVP.)

## 7. Bloqueos y dependencias

- **Contrato de cargo automático en Flow** (`7001`): bloquea `customer/register` y `subscription/create`. Sin esto no se puede probar E2E (sí se puede codear + unit-testear).
- **Deploy a `api.sonark.tech`** + `FLOW_*_URL` al servidor para el flujo real fuera de ngrok.
- El **gating** ([`gating-m10-dt-02.md`](gating-m10-dt-02.md)) no bloquea el productor, pero conviene tenerlo antes de lanzar cobros reales (o se cobra sin gatear el valor).

## 8. Cómo se prueba
El harness `flow-sandbox-harness.js` (modo `subscription`) ya ejecuta exactamente estos pasos manualmente y siembra la fila local. Sirve como referencia de implementación y como prueba E2E una vez habilitado el contrato.
