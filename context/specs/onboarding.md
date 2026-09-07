# Spec: Onboarding

> **Desactualizado · revisado el 2026-09-06.** El contrato vigente es puertas
> (`currentGate` / `resumeState`), no `currentStep`. Lo de abajo describe el modelo de
> pasos y no el de puertas.
>
> **Lo que cambió desde la versión anterior de este aviso:** decía que el cierre del
> código eran «cuatro flags (`allDone`) y no se alcanza». Ya no: `user-onboarding.service.ts`
> cierra en `onboardingStatus === 'completed'` y esa condición de cuatro banderas quedó
> reemplazada. El cierre **se alcanza**.
>
> **Vigente en su lugar:** las seis puertas, un archivo por puerta, en
> [`wiki/onboarding/requerimiento_por_puerta/`](wiki/onboarding/requerimiento_por_puerta/),
> y el índice del módulo en
> [`../modulo01-identidad-autenticacion/contexto/README.md`](../modulo01-identidad-autenticacion/contexto/README.md).

**Estado backend:** ✅ Puertas G0–G5 implementadas, con reglas en `src/health/rules/`
**Estado frontend:** ✅ Completo
**Módulos NestJS:** `src/auth/` · `src/health/` · `src/imports/`

---

## Flujo de pasos

```
email_verification  →  financial_profile  →  categories  →  completed
       ✅                    ⚠️ M2-DT-01          ✅              ⚠️ nunca cierra
```

## Endpoints

```
GET    /auth/onboarding/state       → paso actual + flags de completado
PATCH  /auth/onboarding/step        → avanzar un paso
```

## Contrato

### GET /auth/onboarding/state
```json
// Response 200
{ "currentStep": "financial_profile",
  "emailVerified": true,
  "financialProfileCompleted": false,   // ⚠️ bloqueado por M2-DT-01
  "minDocThresholdMet": false,          // ⚠️ nadie lo activa aún
  "onboardingDone": false }
```

### PATCH /auth/onboarding/step
```json
// Request
{ "step": "categories" }   // ⚠️ acepta strings libres — falta @IsIn() en DTO
// Response 200 → estado actualizado
```

## Problema activo (M1-DT-04)
El onboarding **nunca puede auto-completarse** con la lógica actual porque:
1. Exige `financialProfileCompleted = true` → el endpoint PUT /profile/financial no existe (M2-DT-01)
2. `minDocThresholdMet` queda en `false` para siempre → nadie lo escribe
3. `currentStep` sin validación enum → el backend acepta cualquier string

**Workaround actual en frontend:** el usuario puede navegar al Home sin completar el onboarding si `onboardingDone` ya está en `true` por una sesión anterior.

## Pasos definidos
```
email_verification   → verifica OTP del registro
financial_profile    → declara ingreso + gastos fijos (M2-DT-01 pendiente)
categories           → selecciona categorías de interés
completed            → onboarding terminado, redirige a Home
```

## Tablas involucradas
`user_onboarding_state` · `app_user.onboarding_done`
