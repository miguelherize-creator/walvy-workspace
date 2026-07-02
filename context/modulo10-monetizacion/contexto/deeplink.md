# Retorno de pago vía deep link (Flow → app)

Cómo, al terminar un pago en Flow, el usuario vuelve **a la app mobile** en vez de quedarse en una página HTML de resultado. Patrón estilo OAuth: `WebBrowser.openAuthSessionAsync` + un backend que redirige al scheme `walvy://`.

Estado: **backend ✅ implementado** · **frontend ✅ implementado** (falta probar en dev build — ver §5).

---

## 1. Por qué este patrón (restricciones de Flow)

No se puede poner `urlReturn = walvy://...` directo en Flow porque:
1. `urlReturn` **debe ser http(s)** — Flow valida y rechaza schemes custom.
2. Flow redirige a `urlReturn` vía **POST** (form) — un deep link no recibe POST.

Solución: `urlReturn` sigue siendo el endpoint https `/subscriptions/return`, pero ese endpoint **ya no muestra el resultado**: reabre la app vía deep link. `openAuthSessionAsync` detecta la navegación al scheme `walvy://` y cierra el browser solo, devolviendo el control a la app.

---

## 2. Secuencia completa

```
App                         Backend                       Flow
 │                            │                            │
 ├─ checkout(planId) ────────►│                            │
 │                            ├─ payment/create ──────────►│
 │                            │◄─ { url, token } ──────────┤
 │◄─ { paymentUrl } ──────────┤                            │
 │                            │                            │
 ├─ WebBrowser.openAuthSessionAsync(paymentUrl, "walvy://subscriptions/result")
 │     (abre browser in-app; el usuario paga en Flow)      │
 │                            │◄── POST /webhook ──────────┤ (confirma pago, activa sub)
 │                            │                            │
 │                            │◄── POST/GET /return ───────┤ (redirige al pagador)
 │                            ├─ getPaymentStatus(token)   │
 │                            │   responde HTML que hace   │
 │                            │   window.location='walvy://subscriptions/result?status=2&result=success'
 │◄── openAuthSessionAsync detecta el scheme, cierra el browser y devuelve { type:'success', url }
 │                            │                            │
 ├─ GET /subscriptions/me ───►│  (reconfirma estado real — NO confía en los params del deep link)
 │◄─ suscripción activa ──────┤                            │
```

Dos canales independientes confirman el pago:
- **Webhook** (`/subscriptions/webhook`): server-to-server, es la **fuente de verdad** que activa la suscripción. Ver `README.md` §4.
- **Return / deep link**: solo **UX** — devuelve al usuario a la app. Nunca activa nada por sí mismo.

---

## 3. Backend (implementado)

### `GET|POST /subscriptions/return` — `subscriptions.controller.ts`
Ya no renderiza la tabla de resultado. Ahora devuelve un HTML mínimo que:
1. Ejecuta `window.location.replace("walvy://subscriptions/result?status=<n>&result=<x>")` al cargar.
2. Muestra un botón "Volver a la app" (fallback manual si el scheme no abre: desktop / app no instalada).

`returnHtml(data)` construye el deep link con el `status` de Flow (consultado con `getPaymentStatus`). No interpola strings crudos de Flow → sin riesgo de XSS.

### Deep link
```
walvy://subscriptions/result?status=<flowStatus>&result=<label>
```
| status (Flow) | result |
|---|---|
| 1 | `pending` |
| 2 | `success` |
| 3 | `rejected` |
| 4 | `cancelled` |

Si no hay token/status, redirige a `walvy://subscriptions/result` sin params (la app igual reconfirma con `/me`).

### Configuración
| Var | Default | Nota |
|---|---|---|
| `APP_RETURN_DEEP_LINK` | `walvy://subscriptions/result` | base del deep link; permite cambiar scheme/ruta por ambiente |
| `FLOW_RETURN_URL` | — | sigue siendo `https://<host>/subscriptions/return` (NO el scheme) |

Opcional: agregar `APP_RETURN_DEEP_LINK` a `back-walvy/.env` y `.env.example` si se quiere override.

---

## 4. Frontend (pendiente — guía de implementación)

Libs ya instaladas: `expo-web-browser ~15`, `expo-linking ~8`, `expo-router ~6`. Scheme `walvy` ya configurado en `app.json`.

### Cambio en `features/subscription/hooks/useSubscription.ts`
Hoy (≈ línea 90) abre el pago con `Linking.openURL` y detecta el retorno con un listener de `AppState` (el usuario vuelve a mano). Reemplazar por `openAuthSessionAsync`, que cierra el browser solo:

```ts
import * as WebBrowser from "expo-web-browser";
import * as Linking from "expo-linking";

// dentro de checkoutMutation.onSuccess, rama real:
const returnUrl = Linking.createURL("subscriptions/result"); // → walvy://subscriptions/result
priorPlanSlugRef.current = currentSub?.plan?.slug ?? null;
setPendingFlowToken(result.flowToken ?? null);
setAwaitingPayment(true);

const res = await WebBrowser.openAuthSessionAsync(result.paymentUrl, returnUrl);

if (res.type === "success" && res.url) {
  // El deep link trae status/result SOLO como pista para UI optimista.
  // La verdad la da el backend: reconfirmar SIEMPRE.
  await queryClient.invalidateQueries({ queryKey: ["subscription", user?.id] });
} else {
  // 'cancel' (cerró el browser) o 'dismiss': no asumir pago; refrescar igual por si acaso.
  await queryClient.invalidateQueries({ queryKey: ["subscription", user?.id] });
}
setAwaitingPayment(false);
```

### Parseo del deep link (opcional, solo UI)
```ts
const { queryParams } = Linking.parse(res.url); // { status, result }
// queryParams.result === "success" → mostrar check optimista, pero la fuente de verdad es /me
```

### ⚠️ Gotcha Android — ruta puente `app/subscriptions/result.tsx`
En Android, el deep link `walvy://subscriptions/result` lo recibe **también expo-router** (además de que `openAuthSessionAsync` lo intercepta para cerrar el browser). Como esa ruta no existía, aparecía un flash **"This screen doesn't exist"** ~1s antes de la pantalla de éxito.

Fix: se creó `app/subscriptions/result.tsx`, una ruta puente que solo hace `router.back()` al montarse (muestra un spinner mínimo). No confirma nada — la navegación a `subscription-success` la sigue manejando la pantalla de planes vía `checkoutSuccess` (poll a `/me`). En iOS (ASWebAuthenticationSession) el callback no se entrega a expo-router, así que el puente es inocuo ahí.

### Reglas
- **No confiar en los params del deep link**: `status`/`result` se pueden falsificar. La activación real la hace el webhook; la app **debe reconfirmar con `GET /subscriptions/me`**.
- El listener de `AppState` actual puede **quedar como red de seguridad** (si el usuario vuelve a mano sin que dispare el scheme), o eliminarse una vez validado `openAuthSessionAsync`.
- No hace falta registrar una ruta expo-router para `subscriptions/result`: `openAuthSessionAsync` intercepta el scheme y devuelve la URL directamente. (Si se quisiera manejar el deep link también fuera del flujo de pago — ej. app abierta desde cero — ahí sí conviene una ruta.)

---

## 5. Testing

- **Expo Go NO sirve** para probar el deep link: usa scheme `exp://`, no `walvy://`, y el backend redirige a `walvy://`. Probar con **dev build** (`npx expo run:ios|android`) o build standalone, donde el scheme `walvy` está activo.
- `Linking.createURL` en dev build devuelve `walvy://...`; en Expo Go devolvería `exp://...` → mismatch con el backend. Si se necesita probar en Expo Go, habría que hacer `APP_RETURN_DEEP_LINK` configurable y pasar el `exp://` host, pero lo simple es usar dev build.
- El webhook (activación) es independiente del deep link, así que la suscripción se activa aunque el deep link falle — el peor caso es que el usuario tenga que volver a la app a mano.

---

## 6. Archivos tocados / a tocar

| Archivo | Estado |
|---|---|
| `back-walvy/src/subscriptions/subscriptions.controller.ts` — `returnHtml` ahora redirige al deep link | ✅ |
| `back-walvy/.env` — `APP_RETURN_DEEP_LINK` (opcional) | ⏳ opcional |
| `front-walvy/expo/features/subscription/hooks/useSubscription.ts` — `Linking.openURL` → `openAuthSessionAsync` + poll de reconfirmación | ✅ |
| `front-walvy/expo/app/subscriptions/result.tsx` — ruta puente que mata el flash "This screen doesn't exist" en Android | ✅ |
