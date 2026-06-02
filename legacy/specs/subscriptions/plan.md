# Plan de Evolución: Módulo de Suscripciones

> **Módulo:** `subscriptions`
> **Última revisión:** 2026-05-14

---

## 1. Estado actual

### Backend — Implementado

- `GET /subscriptions/plans` (público, retorna planes con precios desde DB)
- `GET /subscriptions/me` (suscripción activa del usuario autenticado)
- `POST /subscriptions/checkout` (genera orden en Flow, retorna URL de pago)
- `POST /subscriptions/webhook` (recibe confirmación de Flow, activa suscripción)
- Planes sembrados al arranque con upsert desde env vars
- Idempotencia de webhook via `commerceOrder` UNIQUE

### Frontend — Placeholder

- La pantalla de suscripciones existe en la app como **placeholder** (UI sin funcionalidad)
- No consume los endpoints del backend
- El botón de pago no está implementado
- Sin gestión de estado post-pago

---

## 2. Pendiente inmediato

### Frontend: implementar flujo de suscripción completo

El frontend debe implementar el flujo completo de suscripción como parte del sprint actual o el siguiente:

1. **Pantalla de planes:** Listar planes desde `GET /subscriptions/plans` con precio real
2. **Botón de checkout:** Llamar `POST /subscriptions/checkout`, obtener `checkoutUrl`
3. **Redirección a Flow:** Abrir la URL en WebView (dentro de la app) o browser externo
4. **Retorno a la app:** Manejar el deep link / URL de retorno tras el pago en Flow
5. **Actualización de estado:** Consultar `GET /subscriptions/me` tras el retorno para mostrar la suscripción activa

### Consideraciones técnicas del frontend

- Flow redirige al usuario a una URL de retorno (`successUrl`, `errorUrl`) configurada en el backend
- La app debe manejar deep links del tipo `walvy://subscriptions/result?status=success`
- El estado de suscripción puede tomar segundos en activarse (webhook es asíncrono); la app debe manejar el estado de "pendiente de confirmación"
- Opciones para actualizar el estado: polling (`GET /subscriptions/me` cada N segundos) o WebSocket

---

## 3. Mejoras identificadas

### GET /subscriptions/me — Trial activo

El campo `trialEndsAt` está en la entidad `User`, no en `Subscription`. El endpoint `GET /subscriptions/me` debería retornar información del trial activo cuando el usuario no tiene suscripción paga:

```json
{
  "trial": {
    "active": true,
    "expiresAt": "ISO8601"
  },
  "subscription": null
}
```

Esto simplifica la lógica en el frontend para mostrar el estado de acceso del usuario.

### Notificación pre-vencimiento

Antes de que una suscripción expire, enviar notificación al usuario (push/email) recordándole renovar. Requiere M2-DT-04 (worker de notificaciones).

---

## 4. Backlog futuro (no comprometido)

### Free trial conversion funnel

Implementar métricas y comunicaciones específicas para convertir usuarios en trial a suscriptores pagos:
- Email a los 3 días antes del vencimiento del trial
- Pantalla de "Tu trial vence pronto" en la app
- Descuento de lanzamiento (opcional, requiere decisión de negocio)

### Multi-currency / Internacional

Actualmente solo CLP con Flow.cl. Para expansión internacional:
- Agregar soporte Stripe (dólares, euros)
- Detección de país del usuario para mostrar la pasarela correcta
- Precios en múltiples monedas

### Renovación automática

Flow.cl tiene soporte para suscripciones recurrentes (cargos automáticos). Implementar:
- Cobro automático al vencer la suscripción
- Endpoint para cancelar renovación automática (`DELETE /subscriptions/me/auto-renew`)
- Notificación de cobro exitoso / fallido

---

## 5. Dependencias

| Item | Depende de | Estado |
|------|------------|--------|
| Frontend pantalla de pagos | Backend implementado (ya listo) | Pendiente frontend |
| Notificación pre-vencimiento | M2-DT-04 (worker notificaciones) | Bloqueado |
| Trial info en GET /me | Cambio menor en SubscriptionsService | Planificado |
| Renovación automática | Decisión de negocio + Flow recurrente | Backlog |
| Stripe internacional | Decisión de expansión geográfica | Backlog |
