# Spec: Suscripciones y Pagos

**Estado backend:** ✅ Completo  
**Estado frontend:** ⚠️ Básico implementado  
**Módulo NestJS:** `src/subscriptions/`

---

## Flujo completo

```
1. GET  /subscriptions/plans          → lista planes disponibles con precio vigente
2. POST /subscriptions/checkout       → inicia transacción Flow.cl → retorna redirectUrl
3. Usuario paga en Flow.cl (externo)
4. POST /subscriptions/flow/webhook   → Flow confirma pago (HMAC-SHA256)
   → crea payment_order → activa subscription
5. GET  /subscriptions/flow/return    → retorno del usuario post-pago (UI redirect)
6. GET  /subscriptions/my             → suscripción activa del usuario
```

## Endpoints

```
GET    /subscriptions/plans           → planes activos con precio actual (bitemporal)
POST   /subscriptions/checkout        → iniciar pago
GET    /subscriptions/flow/return     → redirect post-pago (no auth requerido)
POST   /subscriptions/flow/webhook    → webhook Flow.cl (sin auth, firma HMAC)
GET    /subscriptions/my              → suscripción activa del usuario autenticado
```

## Contratos

### GET /subscriptions/plans
```json
// Response 200
[{ "id": "uuid", "name": "Pro Mensual", "features": ["feature1"],
   "price": { "amount": 5000, "currency": "CLP", "billingPeriod": "monthly" } }]
```

### POST /subscriptions/checkout
```json
// Request
{ "planId": "uuid" }
// Response 201
{ "redirectUrl": "https://www.flow.cl/app/pay?token=...",
  "commerceOrder": "walvy_uuid_timestamp" }
```

### POST /subscriptions/flow/webhook
```
Headers: x-flow-signature: HMAC-SHA256(body, FLOW_SECRET_KEY)
Body: { commerceOrder, flowOrder, status, amount }
→ Valida firma → crea payment_order → activa subscription
→ Idempotente: si commerceOrder ya existe, retorna 200 sin duplicar
```

## Reglas de negocio
- Precios bitemporales: `plan_price` tiene `valid_from` / `valid_until`. El precio vigente es el que tiene `valid_from <= NOW() AND (valid_until IS NULL OR valid_until >= NOW())`
- `payment_order.commerce_order UNIQUE` — idempotencia ante webhooks duplicados
- Validación HMAC-SHA256 obligatoria en webhook. Sin firma válida → 401
- Una suscripción activa bloquea nuevo checkout para el mismo plan
- Variables de entorno: `FLOW_API_KEY`, `FLOW_SECRET_KEY`, `FLOW_API_URL` (sandbox vs producción)

## Tablas involucradas
`plan` · `plan_price` · `subscription` · `payment_order`
