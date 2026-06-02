# Módulo 10 — Casos de Uso

**Módulo:** Monetización  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 10

---

## CU-01 — Elegir y suscribirse a un plan

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario navega a "Planes" o llega al paywall.
2. App llama GET /plans?country_id=X.
3. Backend retorna plan + plan_price vigente para el país.
4. Usuario elige "Plan Mensual" → toca "Suscribirse".
5. App llama POST /subscriptions/checkout.
6. Backend:
   a. Crea payment_order con commerce_order único.
   b. Genera URL de pago en el proveedor (Flow/Stripe).
7. App redirige al usuario a la URL de pago.
8. Usuario completa el pago en el proveedor.
9. Proveedor envía webhook a POST /webhooks/payment.
10. Backend procesa el webhook:
    a. Busca payment_order por commerce_order.
    b. Actualiza status → paid, paid_at = now().
    c. Crea subscription con billed_amount = snapshot del precio.
    d. v_user_access → has_active_subscription = true.
11. App muestra confirmación: "¡Bienvenido al plan mensual!".
```

---

## CU-02 — Webhook duplicado (idempotencia)

**Actor principal:** Sistema (proveedor de pago)

```
1. Proveedor envía el mismo webhook dos veces por un error de red.
2. Primera vez: se procesa normalmente (CU-01 paso 10).
3. Segunda vez:
   → Backend busca payment_order por commerce_order.
   → payment_order.status ya es 'paid'.
   → Backend retorna HTTP 200 sin re-procesar.
   → No se crea una segunda subscription.
```

---

## CU-03 — Cancelar suscripción

**Actor principal:** Usuario

```
1. Usuario navega a "Configuración" → "Mi suscripción" → "Cancelar".
2. App muestra: "Tu acceso continuará hasta [ends_at]."
3. Usuario confirma.
4. App llama DELETE /subscriptions/current.
5. Backend:
   a. subscription_status → cancelled, cancelled_at = now().
   b. Si proveedor soporta: notifica al proveedor para no renovar.
   c. ends_at no cambia.
6. App muestra: "Suscripción cancelada. Tienes acceso hasta [ends_at]."
```

---

## CU-04 — Regalar suscripción

**Actor principal:** Usuario (remitente)

```
1. Usuario navega a "Regalar suscripción".
2. Ingresa email del receptor, nombre y mensaje.
3. App llama POST /subscriptions/gift.
4. Backend:
   a. Crea payment_order.
   b. Genera URL de pago.
5. Usuario completa el pago.
6. Al recibir webhook paid:
   a. Crea subscription con is_gift = true, gift_token generado.
   b. Envía email al receptor con el gift_token y un enlace de redención.
```

---

## CU-05 — Redimir suscripción regalo

**Actor principal:** Usuario (receptor)

```
1. Receptor recibe email con enlace: /redeem?token=XYZ.
2. Si no tiene cuenta: flujo de registro.
3. App llama POST /subscriptions/redeem { token: "XYZ" }.
4. Backend:
   a. Busca subscription WHERE gift_token = 'XYZ' AND gift_redeemed_at IS NULL.
   b. gift_redeemed_at = now(), user_id = receptor.user_id.
   c. subscription_status → active.
5. App muestra: "¡Suscripción activada! Disfruta Walvy Premium."
```

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Suscribirse a un plan | Usuario | RF-01, RF-02 | ✅ |
| CU-02 | Webhook duplicado (idempotencia) | Sistema | RF-03 | ✅ |
| CU-03 | Cancelar suscripción | Usuario | RF-04 | ✅ |
| CU-04 | Regalar suscripción | Usuario | RF-02 | ✅ |
| CU-05 | Redimir suscripción regalo | Usuario | RF-05 | ✅ |
