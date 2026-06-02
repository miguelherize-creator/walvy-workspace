# Tareas: Módulo de Suscripciones

> **Módulo:** `subscriptions`
> **Última revisión:** 2026-05-14

---

## Frontend (Sprint actual / siguiente)

### [ ] Frontend: implementar SubscriptionScreen con listado de planes y botón checkout

**Descripción:** Reemplazar el placeholder actual con una pantalla funcional que muestre los planes disponibles y permita iniciar el proceso de pago.

**Pasos:**
1. Crear `api/subscriptions.ts` con llamadas a `GET /subscriptions/plans` y `POST /subscriptions/checkout`
2. Crear hook `useSubscriptionPlans()` con TanStack Query
3. Implementar `SubscriptionScreen` con:
   - Listado de planes (nombre, precio formateado en CLP, duración)
   - Resaltado del plan anual como "mejor valor" si aplica
   - Botón "Suscribirse" por plan
   - Estado de carga y error
4. Al tocar "Suscribirse": llamar `POST /subscriptions/checkout` y manejar la URL retornada

**Archivos afectados (Feature-First):**
- `src/features/subscriptions/api/subscriptions.api.ts` (nuevo)
- `src/features/subscriptions/hooks/useSubscriptionPlans.ts` (nuevo)
- `src/features/subscriptions/hooks/useCheckout.ts` (nuevo)
- `src/features/subscriptions/ui/SubscriptionScreen.tsx` (modificar placeholder)

**Bloqueante:** No (backend listo)

---

### [ ] Frontend: manejar redirección a Flow URL y retorno a la app

**Descripción:** Al obtener la `checkoutUrl` del backend, abrir Flow y manejar el retorno a la app cuando el usuario complete o cancele el pago.

**Pasos:**
1. Evaluar entre WebView interno (`expo-web-browser` o `react-native-webview`) y browser externo (`Linking.openURL`)
2. Configurar deep link `walvy://subscriptions/result` para el retorno desde Flow
3. Manejar los casos:
   - Pago exitoso: mostrar pantalla de confirmación
   - Pago cancelado: volver a la pantalla de planes con mensaje informativo
   - Error: mostrar error con opción de reintentar
4. Registrar las URLs de retorno en el backend (variables de entorno `FLOW_SUCCESS_URL`, `FLOW_ERROR_URL`)

**Archivos afectados:**
- `src/features/subscriptions/ui/PaymentResultScreen.tsx` (nuevo)
- `app.json` o `app.config.ts` (configurar deep links)
- `src/navigation/` (manejar deep link de retorno)

**Bloqueante:** No (backend listo)

---

### [ ] Frontend: actualizar estado de suscripción tras webhook (polling o WebSocket)

**Descripción:** Como el webhook de Flow es asíncrono, la suscripción no se activa instantáneamente al volver a la app. Implementar mecanismo para que la UI refleje el estado correcto.

**Opción recomendada (polling simple):**
1. Al volver de Flow con `status=success`, iniciar polling de `GET /subscriptions/me` cada 3 segundos
2. Detener el polling cuando la respuesta muestra `status: "active"` o tras 30 segundos (timeout)
3. Mostrar UI de "Verificando pago..." mientras se espera

**Alternativa (WebSocket):** Más compleja, considerar para versión futura.

**Archivos afectados:**
- `src/features/subscriptions/hooks/useSubscriptionStatus.ts` (nuevo)
- `src/features/subscriptions/ui/PaymentResultScreen.tsx` (usar hook)

**Bloqueante:** No (backend listo)

---

## Backend

### [ ] Backend: endpoint GET /subscriptions/me devuelve info de trial activo

**Descripción:** Modificar `GET /subscriptions/me` para incluir información del trial activo cuando el usuario no tiene suscripción paga, simplificando la lógica del frontend.

**Response actualizado:**
```json
{
  "subscription": null,
  "trial": {
    "active": true,
    "expiresAt": "2026-06-14T00:00:00.000Z",
    "daysRemaining": 31
  }
}
```

**Pasos:**
1. En `SubscriptionsService.getMySubscription()`, consultar también `user.trialEndsAt`
2. Calcular `daysRemaining` y `active` basado en la fecha actual
3. Retornar el objeto combinado en lugar de solo la suscripción

**Archivos afectados:**
- `src/subscriptions/subscriptions.service.ts` (modificar)
- `src/subscriptions/dto/subscription-response.dto.ts` (modificar o crear)

**Bloqueante:** No

---

## Backlog (no comprometido)

### [ ] Backend: notificación email pre-vencimiento de suscripción

**Descripción:** Job que corre diariamente y envía email a usuarios cuya suscripción vence en 3 días.

**Prerequisito:** M2-DT-04 (worker notificaciones)

---

### [ ] Backend + Frontend: renovación automática con Flow recurrente

**Descripción:** Implementar cobros automáticos al vencer la suscripción usando la funcionalidad de suscripciones recurrentes de Flow.cl.

**Prerequisito:** Decisión de negocio + revisión de Flow recurrente API
