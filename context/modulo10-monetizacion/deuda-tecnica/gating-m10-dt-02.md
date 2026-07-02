# Gating de acceso premium (M10-DT-02) — diseño pendiente

Estado: **pendiente — no implementado**. Este doc captura la regla de negocio, las decisiones abiertas y el diseño técnico propuesto para cuando se retome. Relacionado: [`README.md`](../contexto/README.md), [`cambios-implementados.md`](../contexto/cambios-implementados.md).

---

## 1. Problema

Hoy la cancelación desafilia correctamente en Flow (`at_period_end=1` → el banco no vuelve a cobrar) y el acceso debería durar hasta `currentPeriodEnd`. Pero **cuando se agotan los días pagos no pasa nada**: el usuario sigue con acceso completo. Falta la regla que convierte "suscripción vencida" en "acceso restringido + invitación a re-pagar".

## 2. Estado actual (verificado en código)

- **`auth` no referencia suscripción** → el login es independiente; un usuario vencido entra igual.
- **`hasActiveAccess` existe pero NO está cableado** a ningún guard — `back-walvy/src/subscriptions/services/subscriptions.service.ts` (comentario: *"Hoy NO se cablea a ningún guard"*).
- **No hay guard premium ni paywall** en backend.
- **Front**: lo único que reacciona es `SubscriptionScreen`, que mapea `cancelled`/`expired` → vista "trial" con opciones de re-suscripción (`SubscriptionScreen.tsx:119`). Es cosmético: no bloquea otras features.
- **Nadie pasa una suscripción real a `expired`**: no hay cron y el webhook solo setea `active`/`past_due`/`cancelled`/`paid`. Una sub `cancelled` vencida se queda `cancelled` con `currentPeriodEnd` en el pasado.

## 3. Regla de negocio propuesta

Patrón estándar (Netflix/Spotify). **Principio clave: nunca bloquear el login** — el usuario necesita entrar justamente para volver a pagar. Se bloquean las *features premium*, no el acceso a la app.

| Estado | `now < currentPeriodEnd` | Login | Features premium |
|---|---|---|---|
| `trialing` | sí | ✅ | ✅ |
| `active` | sí | ✅ | ✅ |
| `cancelled` (período aún vigente) | sí | ✅ | ✅ disfruta lo pagado |
| `past_due` (cobro fallido) | — | ✅ | ⚠️ grace period (a definir) → luego ❌ |
| vencido (`now ≥ currentPeriodEnd`) o `expired` | no | ✅ | ❌ paywall → `subscription-plans` |
| sin suscripción ni trial | — | ✅ | ❌ paywall |

**El acceso se calcula por fecha en cada request** (`now() < currentPeriodEnd`), no por un estado almacenado → no se necesita cron que flipée a `expired`. `hasActiveAccess` ya implementa esta lógica.

## 4. Decisiones de negocio abiertas (requieren producto)

1. **¿Qué features son premium vs. libres?** Un usuario vencido, ¿qué puede seguir viendo (ej. solo lectura de sus datos) y qué se bloquea (ej. registrar transacciones, IA, importar cartolas)?
2. **Grace period para `past_due`**: tras un cobro fallido, ¿cuántos días mantiene acceso antes de cortar? (Flow reintenta `charges_retries_number=3`.)
3. **¿Qué ve exactamente el usuario vencido?** ¿Paywall de pantalla completa, o app navegable con features premium bloqueadas individualmente?
4. **Trial vencido**: ¿mismo tratamiento que suscripción vencida (paywall) o algún diferencial?

## 5. Diseño técnico propuesto

### Backend
- Exponer un flag **`hasAccess: boolean`** en `GET /subscriptions/me` (derivado de `hasActiveAccess`), para que el front no replique la lógica de fechas.
- Para endpoints premium: un **`PremiumGuard`** que use `hasActiveAccess`. Aplicar solo a las rutas que negocio defina como premium (no a auth ni a la pantalla de pago).
- Devolver `403` con un código claro (ej. `SUBSCRIPTION_REQUIRED`) para que el front distinga "no autorizado" de "requiere suscripción".

### Frontend
- Tras login, consultar `/subscriptions/me` (ya se hace) y leer `hasAccess`.
- Si `!hasAccess` → gatear las features premium y mostrar paywall que enrute a `subscription-plans`. **Dejar siempre libre** la pantalla de pago/suscripción.
- Interceptor: un `403 SUBSCRIPTION_REQUIRED` del backend → redirige al paywall (defensa en profundidad).

## 6. Criterios de aceptación (cuando se implemente)

- Un usuario con sub `cancelled` y período vigente conserva todas las features premium.
- Al pasar `currentPeriodEnd`, las features premium se bloquean **sin** impedir el login.
- El usuario vencido puede llegar a `subscription-plans` y re-suscribirse sin fricción.
- Re-suscribirse (webhook activa) restaura el acceso de inmediato (`hasAccess` vuelve a `true`).

## 7. Dependencias
- No bloqueante con el **productor** (`subscription/create`), pero conviene definirlo antes de lanzar cobros reales, o se cobraría sin gatear el valor.
- Requiere la definición de producto del punto 4 antes de codear.
