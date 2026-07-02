# Suscripciones — Changelog de implementación

Registro concreto de lo construido en esta tanda (junio 2026). Para la arquitectura general ver [`README.md`](README.md); para el retorno a la app ver [`deeplink.md`](deeplink.md).

---

## 1. Webhook recurrente (consumidor) ✅ validado en sandbox

`POST /subscriptions/webhook` ahora maneja **el primer cobro y todos los recurrentes** además de la confirmación one-time existente. Bifurca por token:
- **Token con orden guardada** → confirmación one-time (lógica previa intacta).
- **Token sin orden** (invoice de suscripción) → `handleSubscriptionCharge`: `payment/getStatus` → correlación por **email del pagador** → `subscription/get` (estado autoritativo) → sincroniza la `Subscription` local + crea un `PaymentOrder` por ciclo. Idempotente por `flow_token` único.

**Archivos:**
- `back-walvy/src/subscriptions/entities/subscription.entity.ts` — columnas `flow_customer_id`, `flow_subscription_id`.
- `back-walvy/src/subscriptions/services/flow.service.ts` — `FlowSubscription` + `getSubscription()`.
- `back-walvy/src/subscriptions/services/payment-processing.service.ts` — `handleWebhook` rebranch + `handleSubscriptionCharge` + `mapFlowSubscriptionStatus`/`parseFlowDate`.

## 2. Fixes descubiertos en la prueba sandbox (2026-06-28) ✅

1. **Flow NO firma los callbacks** — el body trae solo `token`. El `verifyWebhookSignature` exigía `s` → rechazaba todo → el webhook nunca confirmó (de ahí el `verify-payment` manual). **Fix:** se eliminó la verificación de firma; la confianza viene de `payment/getStatus` (firmado con nuestro secret), que es el modelo de Flow.
2. **Excepción → 500** — `handleWebhook` ahora va en `try/catch`: nunca propaga, siempre responde 200 (ACK).

## 3. Retorno a la app vía deep link ✅ (back + front, probado en Android)

`GET|POST /subscriptions/return` ya no muestra HTML de resultado: redirige al deep link `walvy://subscriptions/result?status=&result=`. El front usa `WebBrowser.openAuthSessionAsync` y reconfirma con `GET /subscriptions/me`. Detalle completo en [`deeplink.md`](deeplink.md).

**Archivos:**
- `back-walvy/.../subscriptions.controller.ts` — `returnHtml` → redirector al deep link (env `APP_RETURN_DEEP_LINK`).
- `front-walvy/expo/features/subscription/hooks/useSubscription.ts` — `Linking.openURL` → `openAuthSessionAsync` + poll.
- `front-walvy/expo/app/subscriptions/result.tsx` — ruta puente que mata el flash "This screen doesn't exist" en Android.

## 4. Cancelación en Flow ✅ (backend + unit tests)

`cancelSubscription` ahora cancela en Flow **antes** de marcar local:
- `subscription/cancel(subscriptionId, at_period_end=1)` → no renueva, mantiene acceso hasta `currentPeriodEnd`.
- Si Flow falla → **propaga error (500), NO marca cancelada localmente** (evita "cancelada aquí pero Flow sigue cobrando").
- Legacy sin `flow_subscription_id` → solo cancela local.
- Idempotente si ya estaba `cancelled` (no llama a Flow).

**Frontend:** el modal de cancelación ahora da **feedback en error**. Antes, `handleConfirmCancel` cerraba el modal en silencio en el `catch` → con el nuevo 500 (Flow caído) el usuario no se enteraba de que NO se canceló. Ahora muestra un mensaje inline en el modal ("Tu plan sigue activo, intentá de nuevo") y lo deja abierto para reintentar.

**Archivos:**
- `back-walvy/.../flow.service.ts` — `cancelSubscription(subscriptionId, atPeriodEnd)`.
- `back-walvy/.../subscriptions.service.ts` — inyecta `FlowService`; cancela en Flow primero.
- `back-walvy/.../subscriptions.service.spec.ts` — +6 tests.
- `back-walvy/docs/api/subscriptions/subscriptions.md` — comportamiento + error 500.
- `front-walvy/.../CancelSubscriptionModal.tsx` — prop `errorMessage` + texto inline de error.
- `front-walvy/.../SubscriptionScreen.tsx` — estado `cancelError`; en `catch` no cierra el modal, muestra el error.

---

## Estado de tests
`npx jest src/subscriptions` → **27 passed** (payment-processing 13 + subscriptions 14). Typecheck limpio.

## Pendiente / bloqueado
- **Productor** (`checkout` → `customer/create` → `customer/register` → `subscription/create`) — lo único grande que falta; cierra el ciclo y destraba probar recurrente/cancelado real.
- **Gating de acceso premium (M10-DT-02)** — qué pasa al vencer los días pagos. Diseño en [`gating-m10-dt-02.md`](../deuda-tecnica/gating-m10-dt-02.md); hoy NO hay gating (el login y las features no chequean suscripción).
- **Contrato cargo automático** en la cuenta Flow (bloquea `customer/register` → `7001`).
- **Deploy** del backend a `api.sonark.tech` + `FLOW_*_URL` al servidor.
