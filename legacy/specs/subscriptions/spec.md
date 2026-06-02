# Spec: Módulo de Suscripciones

> **Módulo:** `subscriptions`
> **Backend:** NestJS 10 — `src/subscriptions/`
> **Pasarela de pago:** Flow.cl (Chile)
> **Última revisión:** 2026-05-14

---

## 1. Descripción funcional

El módulo de suscripciones gestiona los planes de pago de Walvy y la integración con Flow.cl para procesar cobros en Chile. Los usuarios pueden suscribirse a un plan Pro (mensual o anual) desde la app.

**Para el PM:** Los usuarios en plan gratuito tienen acceso limitado. Al suscribirse al plan Pro, acceden a todas las funcionalidades premium. El pago se procesa a través de Flow.cl (pasarela local chilena). La suscripción se activa automáticamente cuando Flow confirma el pago.

**Para el desarrollador:** El flujo es asíncrono: la app redirige al usuario a Flow, y la activación ocurre vía webhook cuando Flow confirma el pago. Los precios se configuran via env vars y se cargan al iniciar el servidor mediante upsert. El webhook usa firma HMAC para verificar la autenticidad de la notificación.

---

## 2. Planes disponibles

| Slug | Nombre | Precio | Duración | Env var precio |
|------|--------|--------|----------|----------------|
| `pro_monthly` | Pro Mensual | $5.000 CLP | 30 días | `PLAN_PRO_MONTHLY_PRICE` |
| `pro_annual` | Pro Anual | $50.000 CLP | 365 días | `PLAN_PRO_ANNUAL_PRICE` |

### Precios dinámicos

Los precios de los planes se configuran mediante variables de entorno (`PLAN_PRO_MONTHLY_PRICE`, `PLAN_PRO_ANNUAL_PRICE`). Al iniciar el servidor, el módulo ejecuta un **upsert** de los planes en la base de datos, garantizando que los precios en DB siempre reflejen los valores de las env vars.

Esto permite actualizar precios sin cambios de código ni migraciones de base de datos.

---

## 3. GET /subscriptions/plans

**Auth:** No requerido (endpoint público)

**Descripción:** Lista todos los planes de suscripción disponibles.

**Response 200:**
```json
[
  {
    "id": "uuid",
    "slug": "pro_monthly",
    "name": "Pro Mensual",
    "price": 5000,
    "currency": "CLP",
    "durationDays": 30,
    "description": "string | null"
  },
  {
    "id": "uuid",
    "slug": "pro_annual",
    "name": "Pro Anual",
    "price": 50000,
    "currency": "CLP",
    "durationDays": 365,
    "description": "string | null"
  }
]
```

> `price` es retornado como `number` (no string), usando el transformer `decimalToNumber`.

---

## 4. GET /subscriptions/me

**Auth:** Bearer JWT requerido

**Descripción:** Retorna la suscripción activa del usuario. Si no tiene suscripción activa, retorna `null`.

**Response 200 — Con suscripción activa:**
```json
{
  "id": "uuid",
  "planSlug": "pro_monthly",
  "planName": "Pro Mensual",
  "status": "active",
  "startsAt": "ISO8601",
  "expiresAt": "ISO8601",
  "autoRenew": false
}
```

**Response 200 — Sin suscripción activa:**
```json
null
```

**Nota sobre trial:** Los usuarios tienen acceso al período de prueba gratuito (`trialEndsAt` en la entidad User). Este campo está en el response de `/users/me`. La lógica de "trial activo" se evalúa desde el servicio de suscripciones al consultar el estado del usuario.

---

## 5. POST /subscriptions/checkout

**Auth:** Bearer JWT requerido

**Descripción:** Inicia el proceso de pago para el plan seleccionado. Retorna la URL de Flow donde el usuario completa el pago.

**Request body:**
```json
{
  "planSlug": "pro_monthly | pro_annual"
}
```

**Response 200:**
```json
{
  "checkoutUrl": "https://www.flow.cl/app/web/pay.php?token=XXXXX",
  "commerceOrder": "string (ID único del pedido)"
}
```

**Comportamiento:**
1. Valida que el `planSlug` existe en la base de datos
2. Genera un `commerceOrder` único (UUID o combinación userId + timestamp)
3. Crea un registro de suscripción en estado `pending`
4. Llama a la API de Flow para crear la orden de pago
5. Retorna la URL de Flow para que la app abra el WebView o browser externo

**Errores:**
- `400` — `planSlug` inválido o no existe
- `401` — No autenticado
- `409` — Usuario ya tiene suscripción activa para ese plan

---

## 6. POST /subscriptions/webhook

**Auth:** No requerido (verificación por firma HMAC de Flow)

**Descripción:** Endpoint receptor de notificaciones de Flow. Cuando un pago es confirmado o rechazado, Flow llama a este endpoint.

**Seguridad:** El webhook verifica la firma HMAC enviada por Flow usando la clave secreta `FLOW_SECRET`. Cualquier request sin firma válida retorna `401`.

**Flow de procesamiento:**
1. Verifica firma HMAC del body
2. Extrae `commerceOrder` del payload de Flow
3. Busca la suscripción pendiente por `commerceOrder`
4. Si el pago fue aprobado:
   - Actualiza estado a `active`
   - Calcula `startsAt = now()` y `expiresAt = now() + durationDays`
   - Actualiza el campo `subscriptionStatus` en el usuario si aplica
5. Si el pago fue rechazado:
   - Actualiza estado a `cancelled`
   - Loggea el motivo de rechazo

**Response 200:** `{ "received": true }` — Flow requiere 200 para no reintentar.

**Idempotencia:** El campo `commerceOrder` tiene restricción UNIQUE en la base de datos. Si Flow envía el mismo webhook dos veces, el segundo intento no duplica la suscripción.

---

## 7. Estados de suscripción

| Estado | Descripción |
|--------|-------------|
| `pending` | Orden creada, pago pendiente en Flow |
| `active` | Pago confirmado, suscripción vigente |
| `cancelled` | Pago rechazado o suscripción cancelada manualmente |
| `expired` | Fecha de expiración superada sin renovación |

---

## 8. Flujo completo

```
App                    Backend                 Flow.cl
 │                        │                       │
 ├─ POST /checkout ───────►                       │
 │                        ├─ Crea orden pendiente  │
 │                        ├─ Llama Flow API ───────►
 │                        │                       ├─ Retorna token pago
 │◄────── checkoutUrl ────┤                       │
 │                        │                       │
 ├─ Abre URL Flow ────────────────────────────────►
 │                        │                       │
 │  (usuario paga en Flow)                        │
 │                        │                       │
 │                        │◄─── POST /webhook ────┤
 │                        ├─ Verifica firma HMAC   │
 │                        ├─ Activa suscripción    │
 │                        ├─ Retorna 200 ──────────►
 │                        │                       │
 ├─ App consulta ─────────►                       │
 │  GET /subscriptions/me │                       │
 │◄── suscripción activa ─┤                       │
```

---

## 9. Variables de entorno requeridas

| Variable | Descripción |
|----------|-------------|
| `FLOW_API_KEY` | Clave de API de Flow.cl |
| `FLOW_SECRET` | Clave secreta para verificación HMAC del webhook |
| `FLOW_API_URL` | URL base de la API de Flow (sandbox o producción) |
| `FLOW_WEBHOOK_URL` | URL del endpoint webhook expuesto públicamente |
| `PLAN_PRO_MONTHLY_PRICE` | Precio del plan mensual en CLP (ej: `5000`) |
| `PLAN_PRO_ANNUAL_PRICE` | Precio del plan anual en CLP (ej: `50000`) |

---

## 10. Errores esperados

| Código | Caso |
|--------|------|
| 400 | `planSlug` inválido en checkout |
| 401 | No autenticado |
| 401 | Firma HMAC inválida en webhook |
| 409 | Usuario ya tiene suscripción activa |
| 500 | Error al comunicarse con la API de Flow |
