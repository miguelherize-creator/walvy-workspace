# Contrato acordado: Trial para usuarios nuevos

**Fecha:** 2026-06-17
**Áreas:** Backend (back-walvy) ↔ Frontend (front-walvy)
**Estado:** ✅ Acordado — pendiente implementación
**Origen:** `req-trial-usuarios-nuevos.md` (propuesta frontend) + revisión backend

---

## Decisión de fondo

El trial **NO se modela como fila en `subscriptions`**. Se deriva de los campos
`trial_started_at` / `trial_ends_at` que ya existen y ya se llenan en el registro
(`auth.service.register` → `users.service.create`).

Para el frontend, `GET /subscriptions/me` devuelve **exactamente** el contrato que
pidieron — la diferencia es solo interna (de dónde sale la data), invisible para el front.

### Por qué (vs. meter el trial en `subscriptions`)

1. `subscriptions.plan_id` es `NOT NULL` con FK → un trial obligaría a un plan `free`
   falso (ensucia `GET /subscriptions/plans`) o a una migración para volverlo nullable.
2. La fecha del trial ya vive en `app_user`. Duplicarla en `subscriptions` crea dos
   fuentes de verdad → riesgo de desincronización.
3. Menos código, cero migración, mismo resultado visible.

---

## Contrato final — `GET /subscriptions/me`

### Usuario en trial vigente (`now < trial_ends_at`, sin pago)

```json
{
  "id": "trial:<userId>",
  "userId": "<uuid>",
  "plan": null,
  "status": "trialing",
  "currentPeriodStart": "<trial_started_at>",
  "currentPeriodEnd": "<trial_ends_at>",
  "cancelledAt": null,
  "createdAt": "<trial_started_at>",
  "updatedAt": "<trial_started_at>"
}
```

### Usuario con trial vencido (`now >= trial_ends_at`, sin pago)

Mismo objeto, con `status: "expired"`. Transición calculada **en el request**
(Opción A del req), sin job/cron.

### Usuario con suscripción paga

Sin cambios — sigue devolviendo la fila real de `subscriptions`.

### `null`

Solo si el usuario no tiene ni trial ni pago (edge case de migración de datos).

---

## Decisiones cerradas (naming / tipos — confirmadas por frontend)

| Campo | Decisión | Motivo |
|---|---|---|
| `id` | `"trial:<userId>"` | El tipo del front exige `string` no-nulo. Ningún código accede al valor directamente → cero impacto funcional. Evita tocar tipos. |
| `plan` | `null` | Único campo que rompe algo: `pickVariant()` hace `sub.plan.slug` sin guardia. Fix de 2 líneas en el front (ver orden de despliegue). |
| `createdAt` / `updatedAt` | = `currentPeriodStart` (`trial_started_at`) | El tipo los exige; el objeto sintético no tiene timestamps propios. |
| `status` | `"trialing"` \| `"expired"` | Ya existen en el enum `SubscriptionStatus`. |

---

## Duración del trial

- **Valor acordado: 30 días** (viene del diseño; se toma como verdad).
- Configurable vía env var **`TRIAL_DAYS_DEFAULT`** (hoy en 14 → cambiar a 30).
- Es env var, no columna: cambiarla es un restart, sin migración.

---

## Feature gating (acceso premium)

- `hasActiveAccess()` existe y está testeado en backend, pero **NO está cableado a
  ningún guard** (deuda `M10-DT-02`).
- **MVP:** el backend entrega `status` + fechas correctas; el **bloqueo de acciones
  lo hace el frontend** con `useAccessGate()`.
- Gating server-side duro = requerimiento aparte, fuera de este alcance.

### Regla de acceso (referencia, alineada front↔back)

```
hasAccess = (status === "trialing" || status === "active" || status === "cancelled")
            && now() < currentPeriodEnd
```

`expired` y `past_due` → sin acceso. **`past_due` en MVP: sin gracia** (se bloquea).

---

## Cancelar sobre un trial — NO aplica

Confirmado por frontend: el botón **"Cancelar suscripción" solo aparece cuando hay un
plan pagado** (mensual o anual). En modo trial el botón no se muestra.

Por lo tanto no hay riesgo de que un usuario en trial llame a
`POST /subscriptions/me/cancel` y reciba `404`. Sin acción requerida en ningún lado.

---

## Orden de despliegue (dependencia de secuencia)

1. **Backend primero** → deploy a dev con el objeto sintético (`plan: null`).
2. **Frontend después** → mergea el guard en `pickVariant()` (`sub.plan?.slug`) y la
   ocultación del botón cancelar para trial.

> Si el front mergea antes que el backend, no se rompe; si el backend llega antes sin
> el guard del front, `pickVariant()` revienta en dev. De ahí el orden.

---

## Lo que el backend construye (resumen de tareas)

- [ ] `GET /subscriptions/me`: cuando no hay fila paga, derivar objeto sintético desde
      `app_user.trial_started_at` / `trial_ends_at`.
- [ ] Transición `trialing → expired` calculada en el request (`now >= trial_ends_at`).
- [ ] Set `TRIAL_DAYS_DEFAULT=30` en `.env`.
- [x] `GET /users/me` ya devuelve `trialEndsAt` (sin cambios).

## Lo que el frontend construye

- [ ] Guard en `pickVariant()` para `plan === null`.
- [ ] Eliminar fechas hardcodeadas (`SubscriptionScreen.tsx:501-507`), usar
      `currentPeriodStart` / `currentPeriodEnd`.
- [ ] `useAccessGate()` + paywall inline.

---

## Estado de implementación (2026-06-17)

Backend implementado y compilando (`nest build` ✅):

- [x] `GET /subscriptions/me` deriva objeto trial sintético desde `app_user`
      (`trialing` / `expired` calculado en el request). `subscriptions.service.ts`
- [x] Repo `User` inyectado + `User` registrado en `subscriptions.module.ts`
- [x] `TRIAL_DAYS_DEFAULT=30` (en `.env` y `.env.example`; fallback de código 14→30)
- [x] Doc de API actualizada (`docs/api/subscriptions/subscriptions.md`)

## Pendientes

- **Tests del módulo de suscripción** → se actualizan al cerrar el feature completo
  de suscripción (no al cierre de este cambio puntual). Incluye:
  - Cobertura del objeto trial sintético (`trialing` / `expired` / `null`).
  - ⚠️ Deuda preexistente: `tsconfig.json` tiene `"types": ["node"]`, que excluye
    los tipos de jest → ningún `.spec.ts` compila hoy. Agregar `"jest"` a `types`
    al retomar los tests.

## Puntos abiertos

- Ninguno bloqueante. (Duración 30d, `id`, `plan:null`, timestamps y cancelar-trial
  quedaron resueltos arriba.)
