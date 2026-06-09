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
4. POST /subscriptions/webhook        → Flow confirma pago (HMAC-SHA256)
   → crea payment_order → activa subscription
5. GET  /subscriptions/return         → retorno del usuario post-pago (UI redirect)
6. GET  /subscriptions/me             → suscripción activa del usuario
7. POST /subscriptions/me/cancel      → cancelar suscripción (acceso hasta fin de período)
```

## Endpoints

```
GET    /subscriptions/plans           → planes activos con precio actual (bitemporal)
GET    /subscriptions/me              → suscripción activa del usuario autenticado
POST   /subscriptions/me/cancel       → cancelar suscripción del usuario
POST   /subscriptions/checkout        → iniciar pago
GET    /subscriptions/return          → redirect post-pago (GET y POST, sin auth)
POST   /subscriptions/webhook         → webhook Flow.cl (sin auth, firma HMAC)
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

### POST /subscriptions/webhook
```
Headers: x-flow-signature: HMAC-SHA256(body, FLOW_SECRET_KEY)
Body: { commerceOrder, flowOrder, status, amount }
→ Valida firma → crea payment_order → activa subscription
→ Idempotente: si commerceOrder ya existe, retorna 200 sin duplicar
```

### POST /subscriptions/me/cancel
```json
// Request — sin body, JWT del usuario
// Response 200
{ "activeUntil": "2026-06-21T03:00:00.000Z" }   // = currentPeriodEnd (ISO UTC) · null si ya vencida
```
Comportamiento:
- `active`/`trialing` → `status = cancelled`, `cancelled_at = now()`, responde `activeUntil`
- **No corta el acceso** — el usuario mantiene acceso hasta `currentPeriodEnd`
- **Idempotente**: si ya está `cancelled`, devuelve el `activeUntil` existente (200, no 409)
- Sin suscripción activa (incluye `expired`/`past_due`) → **404**

| Status | Cuándo |
|--------|--------|
| 200 | Cancelada o ya cancelada (idempotente) |
| 401 | Token ausente o expirado |
| 404 | No tiene suscripción activa |

## Reglas de negocio
- Precios bitemporales: `plan_price` tiene `valid_from` / `valid_until`. El precio vigente es el que tiene `valid_from <= NOW() AND (valid_until IS NULL OR valid_until >= NOW())`
- `payment_order.commerce_order UNIQUE` — idempotencia ante webhooks duplicados
- Validación HMAC-SHA256 obligatoria en webhook. Sin firma válida → 401
- Una suscripción activa bloquea nuevo checkout para el mismo plan
- Variables de entorno: `FLOW_API_KEY`, `FLOW_SECRET_KEY`, `FLOW_API_URL` (sandbox vs producción)
- **Vigencia como instante exacto (no fecha):** `current_period_start` / `current_period_end` son `TIMESTAMPTZ`. `activeUntil` se serializa como ISO UTC (`2026-06-21T03:00:00.000Z`). El frontend convierte a hora local de Chile para mostrar. Decisión: evitar el off-by-one de zona horaria que produce un `date` puro. Ver decisión de diseño abajo.
- **Borde de acceso exclusivo (Stripe-style):** el acceso premium es válido mientras `now() < currentPeriodEnd`. No usar `23:59:59` artificial. ⚠️ El guard de acceso premium aún no está implementado — esta es la regla a aplicar cuando se haga.

## Tablas involucradas
`plan` · `plan_price` · `subscription` · `payment_order`
