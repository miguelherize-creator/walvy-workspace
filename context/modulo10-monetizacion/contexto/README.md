# M10 — Monetización · índice del módulo

**Módulo Nest:** `back-walvy/src/subscriptions/` — 8 endpoints, 2 suites.
**Front:** `expo/features/subscription/`, 3 pantallas.
**En la app** la pantalla vive dentro de Perfil/Configuración, pero el dominio es este
módulo, no [M02](../../modulo02-perfil-configuracion/contexto/README.md).

Estado: **en construcción · reverificado el 2026-09-06.** El webhook recurrente (lado
consumidor) está implementado, con unit tests y **validado contra Flow sandbox**
(2026-06-28, modo payment — ver §6). El productor (checkout → `subscription/create`)
**sigue sin existir**: `flow.service.ts` sólo llama a `payment/create`, y no hay
`customer/create`, `customer/register` ni `subscription/create` en todo el módulo. Las
columnas `flow_customer_id` y `flow_subscription_id` de la entity ya están, esperándolo.

## Qué hay en este módulo

| Archivo | Qué es |
|---|---|
| Este documento | Contexto, flujo Flow, webhook y cómo probar en sandbox |
| [`cambios-implementados.md`](cambios-implementados.md) | Changelog de lo construido |
| [`deeplink.md`](deeplink.md) | Retorno de pago → app vía `walvy://`. Backend ✅, front ⏳ |
| [`../deuda-tecnica/productor-subscription-create.md`](../deuda-tecnica/productor-subscription-create.md) | El productor que falta, con plan de implementación |
| [`../deuda-tecnica/gating-m10-dt-02.md`](../deuda-tecnica/gating-m10-dt-02.md) | Acceso premium al vencer los días pagos. Diseño pendiente |
| [`../utils/flow-sandbox-harness.js`](../utils/flow-sandbox-harness.js) | Harness de prueba contra sandbox — ver §5 |
| [`../utils/flow-sign-plan.js`](../utils/flow-sign-plan.js) | Firma HMAC de un `plans/create` |
| [`../utils/flow-subscriptions.postman_collection.json`](../utils/flow-subscriptions.postman_collection.json) | Colección Postman de los endpoints de Flow |

**El contrato de la API está en** `back-walvy/docs/api/subscriptions/`, no acá. La spec
funcional, en [`../../specs/subscriptions.md`](../../specs/subscriptions.md).

---

## 1. Decisión de arquitectura

Walvy migra del modelo de **pago único** de Flow (`payment/create`, cobra 1 vez, no guarda tarjeta) al producto **Suscripciones de Flow** (auto-cobro mensual/anual). Decisiones tomadas:

| Tema | Decisión |
|---|---|
| Modelo de cobro | **Suscripciones Flow** (auto-cobro real con tarjeta registrada) |
| Planes en Flow | Por API (`plans/create`) — a futuro desde el seed, guardando `flowPlanId` |
| `verify-payment` ("Ya pagué") | Se mantiene por ahora (no aprobado por negocio, fallback no documentado) |
| Confirmación de pago | Vía **webhook** (`urlCallback` del plan), no manual |

---

## 2. Flujo completo (modelo recurrente)

```
checkout(planId)
  → customer/create (externalId = userId)        → customerId
  → customer/register (url_return)               → { url, token }  → usuario ingresa tarjeta
return (tras registrar tarjeta)
  → customer/getRegisterStatus(token)            → status 1 (ok)
  → subscription/create(planId, customerId)      → subscriptionId  (Flow cobra el 1er invoice)
[cada cobro: el primero y los recurrentes]
  → Flow POST urlCallback { token }              → WEBHOOK (ver §4)
cancelación
  → subscription/cancel(subscriptionId, at_period_end=1)   ← mantiene acceso hasta period_end
```

---

## 3. Mapa de endpoints Flow (verificado contra el OpenAPI oficial)

| Acción | Endpoint | Params clave | Devuelve |
|---|---|---|---|
| Crear plan | `POST /plans/create` | `planId` (texto, sin espacios), `name`, `amount`, `interval` (3=mensual, 4=anual), `urlCallback`, `charges_retries_number` (def 3), `days_until_due` (def 3) | `Plan` |
| Crear cliente | `POST /customer/create` | `name`, `email`, **`externalId`** | `Customer` (`customerId`) |
| Registrar tarjeta | `POST /customer/register` | `customerId`, **`url_return`** | `{ url, token }` |
| Confirmar tarjeta | `GET /customer/getRegisterStatus` | `token` | `RegisterResult` (`status` 1=ok, `last4CardDigits`, `issuerBank`) |
| Crear suscripción | `POST /subscription/create` | `planId`, `customerId`, `subscription_start?`, `trial_period_days?` | `Subscription` |
| Consultar suscripción | `GET /subscription/get` | `subscriptionId` | `Subscription` (autoritativo) |
| Cancelar | `POST /subscription/cancel` | `subscriptionId`, **`at_period_end`** (1=fin de período, 0=inmediato) | `Subscription` |

**Notificaciones (patrón general de Flow):** toda transacción asíncrona se notifica por `POST` con un `token`; el detalle se obtiene con el `getStatus` correspondiente. El `urlCallback` del plan → resolver con `payment/getStatus`.

### Firma HMAC
Ordenar params alfabéticamente, concatenar `clave+valor`, `HMAC-SHA256` con `FLOW_SECRET_KEY`, hex. El parámetro `s` no se firma. (Idéntico a `FlowService.sign`.)

---

## 4. El webhook (implementado)

`POST /subscriptions/webhook` recibe `{ token }` y bifurca:

- **Orden rastreada** (token que sí guardamos → checkout one-time legacy): ruta existente, `applyFlowPaymentStatus`.
- **Sin orden** (cobro de suscripción — el token del invoice NO es nuestro): → `handleSubscriptionCharge`:
  1. `payment/getStatus(token)` → si `status==2` (pagado), toma `payer` (email).
  2. Correlaciona: `app_user.email == payer` → `Subscription` del usuario.
  3. `subscription/get(flowSubscriptionId)` → lee `next_invoice_date`/`period_end` + `status`/`morose`.
  4. Guarda `Subscription` local (`currentPeriodEnd`, `status`, `cancelledAt=null`).
  5. Crea `PaymentOrder` (invoice del ciclo, `status=paid`, `flowToken`=token). **Idempotente** por `flow_token` único: un reintento de Flow reentra por la rama "orden ya procesada".
  6. Responde **200** siempre.

### Mapeo de estado Flow → Walvy
| Flow | Walvy `SubscriptionStatus` |
|---|---|
| `status 1, morose 0` | `active` |
| `status 2` | `trialing` |
| `morose 1` (prioridad sobre activa) | `past_due` |
| `status 4` | `cancelled` |
| `status 0` (inactiva/terminada) | `expired` |

### Archivos
- `back-walvy/src/subscriptions/entities/subscription.entity.ts` — columnas `flow_customer_id`, `flow_subscription_id`.
- `back-walvy/src/subscriptions/services/flow.service.ts` — `FlowSubscription` + `getSubscription()`.
- `back-walvy/src/subscriptions/services/payment-processing.service.ts` — `handleWebhook` (rebranch) + `handleSubscriptionCharge` + `mapFlowSubscriptionStatus` / `parseFlowDate`.
- `back-walvy/src/subscriptions/services/payment-processing.service.spec.ts` — 6 tests del flujo recurrente.

---

## 5. Cómo probar contra sandbox

### Pre-requisitos (los levantas tú)
1. **Backend** corriendo con creds de **sandbox** en `back-walvy/.env`.

   > ⚠️ **Corregido el 2026-09-06.** Este paso decía «con `DB_SYNC=true` (crea las
   > columnas nuevas)». Ya no: el proyecto tiene **35 migraciones TypeORM** y el esquema
   > se aplica con `pnpm run migration:run`. `DB_SYNC` sigue existiendo como flag en
   > `app.module.ts` y **no debe usarse** para levantar columnas — `data-source.ts` deja
   > `synchronize: false` a propósito, «la CLI nunca debe alterar el esquema». Las
   > columnas `flow_customer_id` y `flow_subscription_id` ya vienen en una migración.
2. **ngrok** apuntando al backend; `FLOW_CONFIRM_URL` = `https://<tu-ngrok>/subscriptions/webhook`.
3. Un `app_user` con el email de prueba (`migherize@gmai.com` o `miguel.herize@kabeli.cl`).

### ⚠️ Bloqueo: contrato de cargo automático
La cuenta sandbox **no tiene habilitado "cargo automático"/suscripciones** (`customer/register` → `7001 Commerce has not automatic charge contract`). Para el flujo recurrente **real** hay que pedirle a Flow que lo habilite. Mientras tanto, el harness tiene un modo `payment` que prueba el webhook sin ese contrato.

### Ejecutar el harness — dos modos
El productor real no existe aún, así que `flow-sandbox-harness.js` siembra la fila local en `subscriptions` (lo que hará el productor). Sin esa fila el webhook se corta en `no subscription for user`.

- **`MODE=payment`** (default): pago único cuyo token no guardamos → cae en la rama recurrente del webhook. **No requiere contrato.** Valida correlación + invoice + idempotencia + firma + 200, por la rama de **fallback** (sin `subscription/get`; eso ya lo cubren los unit tests).
- **`MODE=subscription`**: flujo recurrente real (`customer/register` + `subscription/create`). Requiere el contrato habilitado.

```bash
cd workspace/walvy-workspace/context/modulo10-monetizacion/utils
node flow-sandbox-harness.js                                   # payment, mensual, email default
EMAIL=migherize@gmai.com node flow-sandbox-harness.js          # otro usuario
PLAN=anual node flow-sandbox-harness.js                        # plan anual
MODE=subscription node flow-sandbox-harness.js                 # recurrente real (needs contrato)
```

El script pausa para que abras la URL y pagues/registres con la **tarjeta `4051885600446623` / CVV `123`** (banco simulado: RUT `11111111-1`, clave `123`).

### Qué deberías ver (señal de éxito)
En los **logs del backend**, tras el paso 5:
```
[webhook] order found: null
[webhook] subscription charge status 2 payer=<email>
[webhook] recurring charge applied for user <userId> → period end <fecha>
```
En **DB**: la fila de `subscriptions` queda `active` con `flow_subscription_id`, y aparece **1 fila nueva en `payment_orders`** (`status=paid`) ligada a la suscripción.

---

## 6. Hallazgos de la prueba en sandbox (2026-06-28)

1. **✅ RESUELTO — Flow NO firma los callbacks.** El primer test reveló en los logs:
   ```
   [webhook] body keys: token        ← Flow manda solo el token, sin `s`
   [webhook] signature valid: false  ← verifyWebhookSignature rechazaba todo
   ```
   El `verifyWebhookSignature` exigía `s` → **siempre daba false → el webhook nunca procesaba nada**. (Esto explica por qué existía el `verify-payment` manual: el webhook de confirmación nunca funcionó.) **Fix:** se eliminó la verificación de firma del webhook; la confianza viene de re-consultar `payment/getStatus` (firmado con nuestro secretKey), que es el modelo de seguridad documentado de Flow.
2. **✅ RESUELTO — Excepción → 500.** `handleWebhook` ahora está envuelto en `try/catch`: nunca propaga, siempre responde 200 (ACK), aunque `getPaymentStatus` falle.
3. **⏳ Pendiente — Zona horaria**: las fechas de Flow vienen como `yyyy-mm-dd hh:mm:ss` en hora de Chile sin offset; `parseFlowDate` las interpreta en la zona del servidor. Validar el offset real (solo aplica a la rama `subscription/get`, no probada aún por falta de contrato).

---

## 7. Pendiente (siguiente entrega)

- **Productor**: refactor de `checkout` a `customer/create` → `customer/register` → `subscription/create`, guardando `flowCustomerId`/`flowSubscriptionId`. Reemplaza la siembra manual del paso 6 del harness.
- **Seed de planes en Flow** (`plans/create` desde `SubscriptionSeedService`, guardando `flowPlanId`).
- Desplegar el backend a `api.sonark.tech` + apuntar `FLOW_RETURN_URL`/`FLOW_CONFIRM_URL` al servidor (hoy en ngrok).
- Habilitar el contrato de **cargo automático** en la cuenta Flow (bloquea `customer/register` → `7001`).
- Zona horaria de `parseFlowDate` (§6.3).

### Hecho
- ✅ **Webhook** (confirmación + recurrente), validado en sandbox.
- ✅ **Cancelación**: `cancelSubscription` llama a Flow `subscription/cancel(at_period_end=1)` antes de marcar local; si Flow falla, no marca cancelada (propaga). Legacy sin `flow_subscription_id` → solo local. Tests en `subscriptions.service.spec.ts`.
- ✅ **Deep link return** (back + front + ruta puente Android) — ver [`deeplink.md`](deeplink.md).

## Referencias
- OpenAPI Flow: https://developers.flow.cl/api — la referencia anterior apuntaba a `~/Downloads/es-openApiFlow.yaml`, que sólo existía en una máquina
- Postman: [`../utils/flow-subscriptions.postman_collection.json`](../utils/flow-subscriptions.postman_collection.json)
- Tarjetas/datos de prueba sandbox: en el OpenAPI (sección "Realizar pruebas en nuestro ambiente Sandbox").
