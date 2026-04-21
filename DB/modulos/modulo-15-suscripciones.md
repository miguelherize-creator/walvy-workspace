# Módulo 15 — Suscripciones & Pasarela de Pago (Flow.cl)

> Fuente: diseño transversal MVP — cubre monetización de la plataforma Walvy.

---

### Suscripciones › Planes y pasarela de pago (Flow.cl)

**✅ Incluye:**
Catálogo de planes (Free y Pro mensual).
Checkout con redirección a Flow.cl (sandbox y producción).
Webhook de confirmación de pago con verificación de firma HMAC-SHA256.
Activación automática de suscripción al confirmar el pago.
Página de resultado post-pago con Walvy branding.
Historial de órdenes de pago (`payment_orders`).
Mock mode en el frontend para probar el flujo sin conectar Flow.

**❌ No incluye:**
Cancelación de suscripción desde la app (MVP: manual vía soporte).
Renovación automática / débito automático (MVP: el usuario inicia cada renovación).
Múltiples pasarelas de pago (solo Flow.cl en V1).
Reembolsos automáticos.
Facturación electrónica.

**Trazabilidad:**
Transversal — habilita acceso a funciones premium en M4, M6, M8.

**Objetivo estratégico:**
Monetizar la plataforma mediante planes de suscripción pagos con una pasarela confiable en Chile (Flow.cl), sin depender de integración de plataformas de stores en el MVP.

**Resultado visible para el usuario:**
El usuario puede ver los planes disponibles, iniciar el pago con Flow y, al confirmar, obtener acceso inmediato a las funciones Pro.

**Definición funcional detallada:**
El módulo expone tres tablas: `subscription_plans` (catálogo gestionado desde el backoffice), `subscriptions` (estado activo del usuario, relación 1:1) y `payment_orders` (registro de cada intento de pago). El checkout genera una orden en Flow y devuelve una URL de pago; Flow llama al webhook del backend al confirmar, que verifica la firma y activa la suscripción. La URL de retorno renderiza una página HTML con el resultado del pago.

**UX / UI:**
Pantalla de planes con comparativa de features. CTA "Suscribirse" redirige a Flow en el browser. Tras el pago, página de resultado Walvy (cálido arena + teal) con datos de la transacción y botón "Cerrar ventana". En mock mode aparece botón "Simular pago" para testing.

**Criterio de aceptación MVP / QA:**
El usuario puede iniciar el checkout desde la app, completar el pago en el sandbox de Flow y ver su suscripción activada en la pantalla de perfil, sin intervención manual del equipo.

**Guardrails de alcance:**
No agregar más pasarelas ni flujo de cancelación/reembolso automático en esta versión. El plan Free no genera orden de pago.
