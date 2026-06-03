# Spec: Onboarding

**Estado backend:** ⚠️ Parcialmente implementado — ver M1-DT-04  
**Estado frontend:** ✅ Completo (flujo básico)  
**Módulo NestJS:** `src/auth/` (integrado en auth)

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
