# Módulo 10 — Requerimientos

**Módulo:** Monetización  
**Layer:** 13  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 10

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Trial gratuito con fecha de expiración | ✅ Incluido |
| Planes mensual y anual | ✅ Incluido |
| Suscripción vía proveedor de pago (Flow/Stripe) | ✅ Incluido |
| Precios por país y moneda | ✅ Incluido |
| Suscripciones regalo (gift) | ✅ Incluido |
| Idempotencia de webhooks | ✅ Incluido |
| Facturación electrónica | ❌ No incluido en MVP |
| Descuentos y cupones | ❌ No incluido en MVP |
| Facturación B2B masiva | ❌ No incluido en MVP |

---

## Requerimientos Funcionales

### RF-01 — Ver planes disponibles

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Listar planes |
| **Descripción** | El usuario ve los planes disponibles con sus precios para su país. |
| **Reglas** | - Lee `plan` + `plan_price` WHERE `is_active = true AND valid_to IS NULL AND country_id = user.country_id`. - Muestra precio en la moneda del país del usuario. |

---

### RF-02 — Suscribirse a un plan

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | Iniciar suscripción |
| **Descripción** | El usuario elige un plan y completa el pago vía el proveedor configurado. |
| **Reglas** | - Crea `payment_order` con `commerce_order` único (idempotencia). - Redirige al proveedor de pago. - Al recibir webhook `paid`: crea `subscription` con snapshot de precio (`billed_amount = plan_price.price_amount`). - `v_user_access` pasa a retornar `has_active_subscription = true`. |

---

### RF-03 — Procesar webhook de pago

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | Idempotencia de webhooks |
| **Descripción** | El backend procesa webhooks del proveedor de pago sin duplicar suscripciones. |
| **Reglas** | - Busca `payment_order` por `commerce_order`. - Si no existe o `status != pending`: retorna 200 sin procesar (idempotencia). - Si `status = pending` y el webhook indica pago: `status → paid`, crea/activa `subscription`. - Guarda `provider_response` completo en `payment_order` para auditoría. |

---

### RF-04 — Cancelar suscripción

| Campo | Detalle |
|-------|---------|
| **ID** | RF-04 |
| **Nombre** | Cancelar suscripción |
| **Descripción** | El usuario solicita la cancelación. La suscripción sigue activa hasta `ends_at`. |
| **Reglas** | - `subscription_status → cancelled`, `cancelled_at = now()`. - `ends_at` no cambia (el usuario tiene acceso hasta el final del período pagado). - Si el proveedor soporta cancelación inmediata: `ends_at = now()`. |

---

### RF-05 — Redimir suscripción regalo

| Campo | Detalle |
|-------|---------|
| **ID** | RF-05 |
| **Nombre** | Redimir gift subscription |
| **Descripción** | El receptor canjea un token de regalo para activar su suscripción. |
| **Reglas** | - Busca `subscription` WHERE `gift_token = :token AND gift_redeemed_at IS NULL`. - Si existe y `subscription_status = pending`: `gift_redeemed_at = now()`, `user_id = receptor.user_id`, activa la suscripción. - El token es de un solo uso (UNIQUE en `gift_token`). |

---

## Requerimientos No Funcionales

### RNF-01 — Snapshot de precio inmutable
`subscription.billed_amount` se copia al momento del pago y nunca se modifica. Los cambios de precio en `plan_price` no afectan suscripciones activas.

### RNF-02 — Un precio vigente por combinación
La constraint UNIQUE parcial en `plan_price` garantiza que no pueda haber dos precios activos al mismo tiempo para la misma combinación plan+país+moneda.

### RNF-03 — Sin datos PCI en la BD
`payment_method` solo almacena tokens del proveedor. Números de tarjeta, CVV y datos sensibles **nunca** se persisten en Walvy.
