# Requerimiento: Trial para usuarios nuevos

**Fecha:** 2026-06-17  
**Área:** Backend + Frontend  
**Estado:** ✅ Decisiones cerradas — pendiente implementación frontend

---

## Decisiones del backend (respuestas del 2026-06-17)

| Pregunta | Decisión |
|---|---|
| ¿plan_id = null o plan free? | **Ninguno.** El trial no se guarda en `subscriptions` — se deriva de `app_user.trial_ends_at`. |
| ¿Trigger DB o endpoint? | **Endpoint.** Ya se setea en `auth.register`. No hay nada nuevo que construir en el backend. |
| ¿past_due con gracia? | **Sin gracia.** MVP: `past_due` = sin acceso. Fuera de alcance hasta cobros recurrentes reales. |
| ¿trialEndsAt desde suscripción o independiente? | **Independiente en `app_user`.** Fuente única. `GET /users/me` ya lo devuelve. |

---

## Arquitectura resultante

### Fuente de verdad del trial

```
app_user.trial_ends_at  ←  setea el backend en auth.register (createdAt + 30 días)
GET /users/me           ←  devuelve trialEndsAt como campo del User
GET /subscriptions/me   ←  sigue devolviendo null cuando no hay suscripción paga
```

El trial **no crea un registro en `subscriptions`**. Son dos caminos separados:

```
Usuario nuevo
  ├─ user.trialEndsAt = "2026-07-17..."   ← ya viene de /users/me
  └─ GET /subscriptions/me → null          ← sin cambio

Usuario con plan pago
  ├─ user.trialEndsAt = "2026-07-17..."   ← sigue existiendo (histórico)
  └─ GET /subscriptions/me → { status: "active", ... }
```

### Regla de acceso

```
hasAccess =
  // Plan pago activo o cancelado pero dentro del período
  (sub.status === "active" || sub.status === "cancelled") 
    && now() < sub.currentPeriodEnd
  OR
  // Trial vigente
  user.trialEndsAt != null && now() < user.trialEndsAt
```

| Estado | `sub` | `trialEndsAt` | Acceso |
|---|---|---|---|
| Trial activo | null | futuro | ✅ |
| Trial vencido | null | pasado o null | ❌ |
| Plan activo | active | cualquiera | ✅ |
| Plan cancelado dentro del período | cancelled + end futuro | cualquiera | ✅ |
| Plan cancelado y vencido | cancelled + end pasado | cualquiera | ❌ |
| past_due | past_due | cualquiera | ❌ (sin gracia MVP) |
| expired | expired | cualquiera | ❌ |

---

## Impacto en el frontend

### Problema actual

`SubscriptionScreen.tsx:501-505` calcula las fechas del trial desde `Date.now()`:

```ts
// ❌ HOY — contador siempre muestra 30 días, nunca avanza
const startIso = currentSubscription?.currentPeriodStart ?? new Date().toISOString();
const endIso   = currentSubscription?.currentPeriodEnd
  ?? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
```

### Solución

**1. `mockHelpers.ts` — activar `trialEndsAt` en el mock**

```ts
// ❌ ANTES
trialEndsAt: null,
createdAt: new Date().toISOString(),

// ✅ DESPUÉS
createdAt: user.createdAt,   // preservar la fecha real
trialEndsAt: new Date(new Date(user.createdAt).getTime() + 30 * 24 * 60 * 60 * 1000).toISOString(),
```

**2. `SubscriptionScreen.tsx` — leer fechas del user, no de la suscripción**

```ts
// Agregar al destructuring de useSubscription / useAuth:
const { user } = useAuth();

// Reemplazar bloque de fechas hardcodeadas:
const trialEndsAt  = user?.trialEndsAt ?? null;
const trialStartAt = user?.createdAt   ?? new Date().toISOString();
const trialDaysTotal     = trialEndsAt ? Math.round(daysBetween(trialStartAt, trialEndsAt)) : 30;
const endIso             = currentSubscription?.currentPeriodEnd ?? trialEndsAt
                           ?? new Date(Date.now() + 30 * 86_400_000).toISOString();
const trialDaysRemaining = daysBetween(new Date().toISOString(), endIso);
```

**3. Nuevo hook `useAccessGate.ts`** — fuente única de verdad para bloqueo de features

```ts
// features/subscription/hooks/useAccessGate.ts
import { useAuth } from "@/store/AuthProvider";
import { useSubscription } from "./useSubscription";

export function useAccessGate() {
  const { user } = useAuth();
  const { currentSubscription } = useSubscription();

  const now = Date.now();

  const trialActive =
    !!user?.trialEndsAt && now < new Date(user.trialEndsAt).getTime();

  const subEnd = currentSubscription?.currentPeriodEnd
    ? new Date(currentSubscription.currentPeriodEnd).getTime()
    : null;

  const subActive =
    (currentSubscription?.status === "active" ||
      currentSubscription?.status === "cancelled") &&
    subEnd !== null &&
    now < subEnd;

  const hasAccess = trialActive || subActive;

  const daysRemaining = trialActive && user?.trialEndsAt
    ? Math.max(0, Math.ceil((new Date(user.trialEndsAt).getTime() - now) / 86_400_000))
    : subEnd
    ? Math.max(0, Math.ceil((subEnd - now) / 86_400_000))
    : 0;

  return {
    hasAccess,
    isTrialing: trialActive && !subActive,
    daysRemaining,
    isExpired: !hasAccess,
  };
}
```

**4. Pantallas que necesitan el gate** (a implementar cuando las features existan):

| Feature | Acción cuando `!hasAccess` |
|---|---|
| Registrar transacción | Paywall inline, CTA → `/subscription-plans` |
| Importar cartola | Paywall inline |
| Asistente IA | Paywall inline |
| Bola de Nieve | Paywall inline |
| Generar informe | Paywall inline |

Lo que **no se bloquea**: navegación, perfil, historial existente, pantalla de suscripción.

---

## Archivos a modificar

| Archivo | Cambio | Complejidad |
|---|---|---|
| `api/mocks/mockHelpers.ts` | `trialEndsAt: createdAt + 30d` | Baja |
| `features/subscription/ui/SubscriptionScreen.tsx` | Leer `user.trialEndsAt` en vez de `Date.now()` | Baja |
| `features/subscription/hooks/useAccessGate.ts` | Crear hook nuevo | Media |
| `features/subscription/hooks/index.ts` | Exportar `useAccessGate` | Baja |

---

## Lo que el backend NO necesita cambiar

- `GET /subscriptions/me` → puede seguir devolviendo `null` para usuarios sin plan pago ✅
- `GET /users/me` → `trialEndsAt` ya existe en el contrato y ya se setea en registro ✅
- No hay endpoint nuevo ✅
