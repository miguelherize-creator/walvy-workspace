# DB — Módulo 15: Suscripciones & Pasarela de Pago (Flow.cl)

## Tablas propias (escribe principalmente)

| Tabla | Rol |
|-------|-----|
| `subscription_plans` | Catálogo de planes (Free, Pro). Gestionado desde backoffice (M9) |
| `subscriptions` | Suscripción vigente del usuario (1:1 con `users`) |
| `payment_orders` | Registro de cada intento de pago contra Flow |

## Tablas que lee (sin escribir)

| Tabla | Para qué |
|-------|----------|
| `users` | Obtener `email` del usuario para crear la orden en Flow |
| `subscription_plans` | Verificar `is_active`, leer `price` y `billing_interval_days` en el checkout |

---

## Detalle por tabla

### `subscription_plans`
Catálogo de planes disponibles. Se gestiona desde el backoffice (M9); los usuarios no lo escriben directamente.

| Campo | Qué hace |
|-------|----------|
| `slug` | Identificador interno único (`free`, `pro_monthly`, `pro_annual`) |
| `price` | `0` para el plan gratuito; monto en CLP para planes pagos |
| `billing_interval_days` | `30` = mensual, `365` = anual, `null` = sin renovación (Free / lifetime) |
| `features` | `jsonb` — array de strings con claves de funcionalidad (ej: `["import_pdf", "ai_assistant"]`) |
| `is_active` | `false` = plan retirado; no se muestran para nuevas suscripciones |

**Planes semilla cargados al iniciar:**
| slug | price | billing_interval_days |
|------|-------|-----------------------|
| `free` | 0 | null |
| `pro_monthly` | 4.990 CLP | 30 |

---

### `subscriptions`
Suscripción vigente del usuario. Relación **1:1** con `users` (`user_id UNIQUE`).

| Campo | Qué hace |
|-------|----------|
| `status` | `trialing` \| `active` \| `past_due` \| `cancelled` \| `expired` |
| `current_period_start` | Fecha de inicio del período activo |
| `current_period_end` | Fecha de vencimiento. `null` = plan Free sin fecha límite |
| `cancelled_at` | Cuándo el usuario canceló; acceso continúa hasta `current_period_end` |

**Ciclo de vida del estado:**
```
(nueva) → active          ← pago confirmado por webhook
active  → cancelled       ← usuario cancela (acceso hasta current_period_end)
active  → past_due        ← renovación fallida (pago rechazado)
past_due → expired        ← período vence sin pago exitoso
cancelled → active        ← usuario renueva antes de que venza
```

---

### `payment_orders`
Registro de cada intento de pago. Inmutable después de crearse (excepto `status` y `provider_response`).

| Campo | Qué hace |
|-------|----------|
| `commerce_order` | Clave idempotente propia. Formato: `WALVY-{uuid}`. Permite reconciliar si Flow envía el webhook dos veces |
| `flow_token` | Token retornado por Flow al crear la orden. Usado para construir la URL de pago: `https://sandbox.flow.cl/app/pay?token={flow_token}` |
| `flow_order` | Número de orden asignado por Flow una vez iniciado el proceso de pago |
| `provider_response` | Respuesta completa del webhook de Flow (`jsonb`). `null` mientras `status=pending` |
| `subscription_id` | `null` mientras el pago no se confirma; se enlaza en `activateSubscription()` |

**Mapeo estado Flow → `payment_order_status`:**
| Flow status (int) | `payment_order_status` |
|-------------------|------------------------|
| 1 | `pending` |
| 2 | `paid` |
| 3 | `rejected` |
| 4 | `cancelled` |

---

## Flujos de datos principales

```
CHECKOUT (iniciar pago)
  → Verificar plan activo y precio > 0
  → Generar commerce_order = "WALVY-{uuid}"
  → POST Flow /payment/create → devuelve { token, url, flowOrder }
  → INSERT payment_orders (status='pending', flow_token=token)
  → Devolver { paymentUrl: url + "?token=" + token } al frontend

WEBHOOK (confirmar pago)
  → Verificar firma HMAC-SHA256 del body con FLOW_SECRET_KEY
  → Buscar PaymentOrder por flow_token
  → GET Flow /payment/getStatus → obtener status definitivo
  → Si status=2 (paid):
      UPDATE payment_orders.status = 'paid', provider_response = flowStatus
      activateSubscription():
        UPSERT subscriptions (status='active', current_period_start=NOW(),
                              current_period_end=NOW()+billing_interval_days)
        UPDATE payment_orders.subscription_id = subscription.id
  → Si status=3 (rejected): UPDATE payment_orders.status = 'rejected'
  → Si status=4 (cancelled): UPDATE payment_orders.status = 'cancelled'

RETURN PAGE (resultado visible al usuario)
  → GET /subscriptions/return?token={token}  o  POST /subscriptions/return { token }
  → GET Flow /payment/getStatus → obtener datos del pago
  → Renderizar HTML con Walvy branding (brand warm-sand + teal)
```

---

## Índices críticos

| Tabla | Índice | Motivo |
|-------|--------|--------|
| `subscriptions` | `user_id` (UNIQUE) | Restricción 1:1, lookup más frecuente |
| `subscriptions` | `(plan_id, status)` | Analítica por plan desde backoffice |
| `subscriptions` | `(status, current_period_end)` | Job de expiración periódica |
| `payment_orders` | `(user_id, created_at DESC)` | Historial de pagos del usuario |
| `payment_orders` | `commerce_order` (UNIQUE) | Idempotencia — evitar duplicar activación |
| `payment_orders` | `flow_token` (UNIQUE) | Lookup en webhook y return page |

---

## Dependencias cross-módulo

| Origen | Qué recibe | Descripción |
|--------|-----------|-------------|
| M1 — Auth | `users.id`, `users.email` | FK para `subscriptions.user_id` y `payment_orders.user_id`; el email se envía a Flow al crear la orden |
| M9 — Admin | `subscription_plans` (write) | El backoffice gestiona el catálogo de planes |

---

## Variables de entorno requeridas (Backend)

| Variable | Ejemplo | Uso |
|----------|---------|-----|
| `FLOW_API_URL` | `https://sandbox.flow.cl/api` | URL base de la API Flow (sandbox o producción) |
| `FLOW_API_KEY` | `tu-api-key` | Clave pública de la cuenta Flow |
| `FLOW_SECRET_KEY` | `tu-secret-key` | Clave privada para firma HMAC-SHA256 |
| `FLOW_CONFIRM_URL` | `https://dominio.com/subscriptions/webhook` | Endpoint webhook al que Flow hace POST al confirmar |
| `FLOW_RETURN_URL` | `https://dominio.com/subscriptions/return` | Página de resultado mostrada al usuario tras el pago |

---

## Garantías de integridad

- Un `payment_order` con `status='paid'` siempre tiene `provider_response ≠ null` y una `subscriptions` activa enlazada.
- `commerce_order` es inmutable post-inserción y único — permite idempotencia ante webhooks duplicados.
- El webhook verifica la firma HMAC antes de procesar; sin firma válida no se actualiza nada.
- No se puede hacer checkout de un plan con `price = 0` (el plan Free se asigna automáticamente al registrarse).
- `subscriptions.user_id` es UNIQUE — un usuario tiene exactamente una suscripción en cualquier momento; `activateSubscription()` hace UPSERT.
