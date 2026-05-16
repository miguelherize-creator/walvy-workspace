# ADR-004 — Flow.cl como Pasarela de Pago MVP (Mercado Chileno)

| Campo | Valor |
|-------|-------|
| **Número** | ADR-004 |
| **Título** | Flow.cl como pasarela de pago MVP (mercado chileno) |
| **Estado** | Accepted |
| **Fecha** | 2026-05-14 |
| **Autores** | Equipo Walvy |
| **Revisores** | — |

---

## Contexto

Walvy necesita monetizarse con un modelo de suscripción. Los requisitos del MVP son:

- **Mercado chileno exclusivamente** en la primera fase. Los usuarios pagan en CLP con medios de pago locales (tarjetas bancarias chilenas, débito, transferencia, WebPay).
- **Simplicidad de integración**: el equipo es pequeño y no puede dedicar semanas a integrar múltiples pasarelas.
- **Pricing dinámico**: el precio del plan debe poder ajustarse sin hacer un redeploy del backend. Los precios son configurables via variables de entorno.
- **Un solo plan de pago**: en el MVP existe un único plan (Pro) con variantes mensual y anual. No hay plan gratuito con features limitadas (Freemium) en esta fase.
- **Idempotencia de pagos**: el sistema no debe activar una suscripción dos veces si el webhook de confirmación llega duplicado.

Se evaluaron tres pasarelas:

1. **Stripe** — pasarela internacional, cobertura global
2. **Flow.cl** — pasarela chilena, enfocada en el mercado local
3. **Transbank / WebPay Plus** — pasarela oficial de Transbank Chile

---

## Decisión

Se adopta **Flow.cl** como única pasarela de pago para el MVP.

### Plan de precios

| Plan | Periodo | Precio | Variable de entorno |
|------|---------|--------|---------------------|
| Pro | Mensual | $5.000 CLP | `PLAN_PRO_MONTHLY_PRICE` |
| Pro | Anual | $50.000 CLP | `PLAN_PRO_ANNUAL_PRICE` |

Los precios se configuran en variables de entorno y el seed del módulo de suscripciones hace `upsert` en startup en la tabla `plan_price`. Esto permite ajustar precios reiniciando el servidor sin modificar código.

### Flujo de pago

```
Usuario: "Quiero suscribirme al plan Pro Mensual"
    │
    ▼
POST /subscriptions/checkout  { planPriceId, period: 'monthly' }
    │
    ▼  [SubscriptionsService]
    ├─ Crear payment_order con status='pending', commerce_order=UUID único
    ├─ Llamar Flow API: POST /payment/create
    │   └─ params: amount, currency, commerceOrder, returnUrl, confirmationUrl
    │
    ▼
Flow API responde con { url, token }
    │
    ▼
Backend retorna { checkoutUrl } al frontend
    │
    ▼
Frontend abre checkoutUrl en WebView o browser nativo
    │
    ▼  [Usuario completa el pago en Flow]
    │
    ▼
Flow llama CONFIRM_URL (webhook): POST /subscriptions/flow/webhook
    │   { token, status: 'PAGADO' / 'RECHAZADO' }
    │
    ▼  [SubscriptionsService.handleWebhook()]
    ├─ Verificar firma HMAC-SHA256 del webhook
    ├─ Buscar payment_order por commerce_order (UNIQUE constraint)
    ├─ Si ya está en status='active' → ignorar (idempotente)
    ├─ Si status='PAGADO' → activar subscripción → payment_order.status='paid'
    └─ Si status='RECHAZADO' → payment_order.status='failed'
    │
    ▼
Flow redirige al usuario a RETURN_URL
    │
    ▼
Frontend muestra resultado (éxito o error)
```

### Verificación de firma HMAC-SHA256

Todos los webhooks de Flow deben verificarse para evitar activaciones fraudulentas:

```typescript
import { createHmac } from 'crypto';

function verifyFlowSignature(
  params: Record<string, string>,
  receivedSignature: string,
  secretKey: string,
): boolean {
  // 1. Ordenar params alfabéticamente, excluir 's' (la firma misma)
  const sortedKeys = Object.keys(params)
    .filter(k => k !== 's')
    .sort();

  // 2. Concatenar key+value sin separadores
  const toSign = sortedKeys.map(k => `${k}${params[k]}`).join('');

  // 3. HMAC-SHA256
  const computed = createHmac('sha256', secretKey)
    .update(toSign)
    .digest('hex');

  return computed === receivedSignature;
}
```

Si la firma no coincide, el webhook se rechaza con `400 Bad Request` y no se activa ninguna suscripción.

### Idempotencia de pagos

La columna `payment_order.commerce_order` tiene una restricción `UNIQUE`. Si Flow envía el webhook de confirmación dos veces (comportamiento documentado de Flow para asegurar entrega), el segundo intento:

1. Hace `findOne({ where: { commerceOrder } })`
2. Si `status = 'paid'` → responde 200 inmediatamente sin modificar nada
3. El `upsert` nunca se usa aquí — la idempotencia es explícita por diseño

### Variables de entorno requeridas

```bash
FLOW_API_KEY=<api_key_flow>
FLOW_SECRET_KEY=<secret_key_flow>
FLOW_API_URL=https://www.flow.cl/app/api       # producción
# FLOW_API_URL=https://sandbox.flow.cl/app/api # sandbox para testing
FLOW_RETURN_URL=https://api.walvy.cl/subscriptions/flow/return
FLOW_CONFIRM_URL=https://api.walvy.cl/subscriptions/flow/webhook

PLAN_PRO_MONTHLY_PRICE=5000    # CLP, sin decimales
PLAN_PRO_ANNUAL_PRICE=50000    # CLP, sin decimales
```

**Requisito crítico**: `FLOW_CONFIRM_URL` debe ser una URL HTTPS pública accesible desde internet. Flow no puede llamar a `localhost`. En desarrollo, usar un tunnel (ngrok, cloudflared) para exponer el endpoint local.

---

## Consecuencias

### Ventajas

- **Integración nativa con medios de pago chilenos**: WebPay, tarjetas bancarias locales, débito, cuotas — todo lo que un usuario chileno espera.
- **Precios sin redeploy**: cambiar `PLAN_PRO_MONTHLY_PRICE` y reiniciar el servidor actualiza el precio en producción sin modificar código.
- **Idempotencia garantizada**: `commerce_order UNIQUE` previene doble activación incluso si Flow envía el webhook múltiples veces.
- **Precios históricos preservados**: `plan_price` bitemporal permite mantener el precio al que se suscribió cada usuario, aunque el precio cambie luego.

### Desventajas

- **Solo mercado chileno**: Flow.cl no opera fuera de Chile. Para expandir a otros países se deberá integrar otra pasarela.
- **Webhook requiere HTTPS público**: complica el testing en desarrollo local (requiere tunnel).
- **No Stripe**: Stripe tiene mejor documentación, SDK más robusto y soporte para suscripciones recurrentes nativas. En el MVP, la gestión de renovaciones es manual o via jobs internos.

---

## Alternativas consideradas

### Opción 1: Stripe

- Pasarela internacional con excelente SDK, webhooks confiables y soporte nativo de suscripciones recurrentes.
- **Rechazada para MVP porque**: los medios de pago chilenos locales (débito, cuotas) requieren configuración adicional; la tarifa de conversión de moneda es más alta; el onboarding de Stripe en Chile requiere documentación legal que retrasa el MVP.
- **Considerar para expansión internacional** (M6+).

### Opción 2: Transbank WebPay Plus

- Pasarela oficial del sistema bancario chileno, máxima cobertura local.
- **Rechazada porque**: el proceso de afiliación comercial es más lento (aprobación bancaria requerida); el SDK es más complejo que Flow; no tiene variante sandbox tan sencilla para testing.

### Opción 3: Mercado Pago

- Presente en Chile, pero principalmente orientado a e-commerce.
- **Rechazada porque**: comisiones más altas para servicios digitales recurrentes; integración de suscripciones menos documentada para el mercado chileno.

---

## Estado actual de implementación

A la fecha (2026-05-14):

| Componente | Estado |
|------------|--------|
| `SubscriptionsModule` | Pendiente (M5) |
| Tabla `plan` | Definida en schema, seed pendiente |
| Tabla `plan_price` | Definida en schema (bitemporal), seed pendiente |
| Tabla `subscription` | Definida en schema |
| Tabla `payment_order` | Definida en schema |
| Integración Flow.cl API | Pendiente |
| Webhook handler + HMAC | Pendiente |

---

## Mejoras futuras

- **Free trial / conversión**: implementar período de prueba (7 días gratis) antes de requerir pago. Requiere estado `'trial'` en `status_domain` para suscripciones.
- **Stripe (expansión internacional)**: cuando Walvy expanda fuera de Chile, integrar Stripe en paralelo con un patrón de strategy (`PaymentGatewayStrategy`) que seleccione la pasarela según el país del usuario.
- **Multi-currency**: actualmente los precios son solo CLP. El schema ya soporta múltiples monedas (`plan_price.currency`); solo falta la lógica de selección.
- **Renovaciones automáticas**: Flow.cl no gestiona renovaciones recurrentes de forma nativa como Stripe. Implementar un job (cron) que detecte suscripciones próximas a vencer y genere nuevas `payment_order` automáticamente.
- **Factura electrónica (SII)**: para usuarios empresariales, integrar generación de boletas/facturas electrónicas según normativa chilena.
