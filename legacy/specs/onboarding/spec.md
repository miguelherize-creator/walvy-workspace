# Spec: Flujo de Onboarding

> **Módulo:** `auth` (onboarding integrado)
> **Backend:** `src/auth/` — entidad `UserOnboarding`
> **Última revisión:** 2026-05-14

---

## 1. Propósito

El onboarding guía al usuario recién registrado a través de una serie de pasos para configurar su cuenta. El diseño fundamental es **reanudable**: si el usuario cierra la app en cualquier punto, al volver se retoma exactamente donde quedó.

La app consulta `GET /auth/onboarding` en cada arranque para determinar si el usuario debe ir al flujo de onboarding o directamente a home.

---

## 2. Steps del flujo

| Orden | Step (`currentStep`) | Pantalla en app | Quién escribe el step | Checkpoint asociado |
|-------|---------------------|-----------------|----------------------|---------------------|
| 1 | `email_verification` | Pantalla verifica email / ingresa OTP | Backend (al registrar) | — |
| 2 | `biometric_setup` | Pregunta si activa biometría | Frontend (tras OTP exitoso) | `biometricPrompted = true` (backend automático) |
| 3 | `profile_basic` | Formulario nombre, apellido, usuario | Frontend (tras biometric_setup) | — |
| 4 | `welcome` | Pantalla de bienvenida / intro a Walvy | Frontend (tras profile_basic) | — |
| 5 | `document_upload` | Subir estado de cuenta bancario (PDF) | Frontend (tras welcome) | `importAttempted = true` (app al intentar subir) |
| 6 | `document_processing` | Pantalla de espera de procesamiento | Backend (al recibir el PDF) | `minDocThresholdMet` (cashflow / M3) |
| — | `null` | Onboarding completado | Backend (auto-complete) | todos los checkpoints = true |

---

## 3. Checkpoints

Los checkpoints son flags booleanos que registran hitos importantes del onboarding. Cuando todos son `true`, el sistema puede marcar el onboarding como completado.

| Checkpoint | Activador | Estado actual |
|------------|-----------|---------------|
| `biometricPrompted` | Backend automático al pasar el step `biometric_setup` | Funciona correctamente |
| `importAttempted` | La app llama `PATCH /auth/onboarding/step` con `document_upload` | Funciona si la app lo llama |
| `financialProfileCompleted` | Debería activarse cuando el usuario completa su perfil financiero | **Sin activador implementado** (M2-DT-01 pendiente) |
| `minDocThresholdMet` | Debería activarse cuando hay suficientes transacciones clasificadas | **Sin activador implementado** (cashflow M3 pendiente) |

---

## 4. Lógica de auto-completado

El sistema evalúa si el onboarding puede marcarse como completado cada vez que se actualiza un checkpoint o step.

**Condición actual en código:**
```
onboarding.completed = true
SI:
  biometricPrompted === true
  AND importAttempted === true
  AND financialProfileCompleted === true  ← NUNCA se escribe
  AND minDocThresholdMet === true          ← NUNCA se escribe
```

**Consecuencia:** El onboarding **nunca se completa automáticamente** porque `financialProfileCompleted` y `minDocThresholdMet` no tienen activadores implementados. Ver M1-DT-04.

---

## 5. Problemas documentados — M1-DT-04

### Problema 1: `financialProfileCompleted` sin activador

**Descripción:** El checkpoint `financialProfileCompleted` está declarado en la entidad `UserOnboarding`, pero ningún servicio lo escribe como `true`.

**Causa raíz:** El endpoint `GET /profile/financial` y `PUT /profile/financial` no están implementados (M2-DT-01). Sin pantalla de perfil financiero diseñada y aprobada, no hay flujo que active este checkpoint.

**Impacto:** El onboarding nunca llega al estado `completed`.

**Opciones de resolución:** Ver `plan.md`.

---

### Problema 2: `minDocThresholdMet` sin activador

**Descripción:** El checkpoint `minDocThresholdMet` está declarado en la entidad, pero ningún job ni servicio lo escribe como `true`.

**Causa raíz:** La lógica de "umbral mínimo de documentos procesados" pertenece al módulo de cashflow e importación de estados de cuenta (M3). Este módulo existe pero no tiene la lógica de salud financiera implementada (M1-DT-03).

**Impacto:** Aunque el usuario suba un documento y se procese, el onboarding no avanza al estado completado.

**Opciones de resolución:** Ver `plan.md`.

---

### Problema 3: `currentStep` acepta strings libres sin enum

**Descripción:** El DTO `UpdateOnboardingStepDto` valida `currentStep` como `string` genérico, sin restricción a los valores válidos.

**Causa raíz:** No se definió un enum `OnboardingStep`. Cualquier valor puede escribirse, incluyendo valores incorrectos como `"documentUpload"` (camelCase) en lugar de `"document_upload"` (snake_case).

**Impacto:** Corrupción silenciosa del estado del onboarding; difícil de depurar.

**Solución:** Agregar `@IsEnum(OnboardingStep)` en el DTO. Ver `tasks.md`.

---

## 6. GET /auth/onboarding — Response completo

```json
{
  "currentStep": "email_verification | biometric_setup | profile_basic | welcome | document_upload | document_processing | null",
  "completed": false,
  "checkpoints": {
    "biometricPrompted": false,
    "importAttempted": false,
    "financialProfileCompleted": false,
    "minDocThresholdMet": false
  },
  "resumeSurface": "onboarding | home | null"
}
```

**Valores de `resumeSurface`:**

| Valor | Significado |
|-------|-------------|
| `"onboarding"` | El usuario tiene steps pendientes; ir al flujo de onboarding |
| `"home"` | Onboarding completado; ir directamente a home |
| `null` | Estado indeterminado; app decide (normalmente va a home) |

---

## 7. PATCH /auth/onboarding/step

**Request body:**
```json
{
  "currentStep": "string (enum OnboardingStep)"
}
```

**Comportamiento:**
1. Actualiza `currentStep` en la entidad `UserOnboarding` del usuario autenticado
2. Si el step implica activación de un checkpoint, lo actualiza también (ej: `biometric_setup` activa `biometricPrompted`)
3. Evalúa si todos los checkpoints están completos; si es así, marca `completed = true` y `currentStep = null`
4. Retorna el estado actualizado (mismo shape que GET /auth/onboarding)

**Response 200:** Mismo shape que GET /auth/onboarding.

**Errores:**
- `400` — `currentStep` con valor fuera del enum (tras implementar M1-DT-04 fix)
- `401` — No autenticado

---

## 8. Lógica de navegación en la app

Al arrancar la app con usuario autenticado:

```
GET /auth/onboarding
  │
  ├─ completed = true            → Ir a Home
  ├─ resumeSurface = "home"      → Ir a Home
  ├─ resumeSurface = "onboarding"→ Ir al step indicado en currentStep
  └─ currentStep = null          → Ir a Home (fallback)
```

**Mapping step → pantalla:**

| `currentStep` | Pantalla en app |
|--------------|-----------------|
| `email_verification` | `VerifyEmailScreen` |
| `biometric_setup` | `BiometricSetupScreen` |
| `profile_basic` | `ProfileBasicScreen` |
| `welcome` | `WelcomeScreen` |
| `document_upload` | `DocumentUploadScreen` |
| `document_processing` | `DocumentProcessingScreen` |
| `null` | `HomeScreen` (onboarding completado) |
