# Tareas: Flujo de Onboarding (M1-DT-04)

> **Deuda técnica:** M1-DT-04
> **Módulo:** `auth` (onboarding)
> **Última revisión:** 2026-05-14

---

## Tareas críticas (bloqueantes del flujo)

### [ ] M1-DT-04 — Reunión con cliente: definir paso final del onboarding

**Descripción:** Antes de modificar la lógica de auto-completado, se debe alinear con el cliente cuál es el último paso que un usuario debe completar para terminar el onboarding. La respuesta determina qué opción técnica implementar (ver `plan.md`).

**Preguntas a resolver:**
1. ¿El perfil financiero es obligatorio en el onboarding inicial?
2. ¿Cuántos documentos constituyen el "umbral mínimo"?
3. ¿Cuál es el step final que el usuario debe completar?

**Output esperado:** Decisión documentada en `decisions/onboarding-completion-criteria.md`

**Archivos afectados:** Ninguno (es una reunión de decisión)
**Bloqueante:** Sí — las demás tareas de M1-DT-04 dependen de esta decisión

---

### [ ] M1-DT-04 — Decidir si `financialProfileCompleted` se elimina del check de auto-completado

**Descripción:** Basándose en la decisión de la reunión con el cliente, determinar si `financialProfileCompleted` debe permanecer como condición de completado del onboarding o si se elimina de la evaluación.

**Si se elimina:**
- Modificar el método que evalúa completado en `OnboardingService` o `AuthService`
- Actualizar tests que verifiquen la condición de completado

**Si se mantiene:**
- Asegurarse de que M2-DT-01 quede en el roadmap como prerequisito del onboarding
- El onboarding seguirá bloqueado hasta que se implemente el perfil financiero

**Archivos afectados (si se elimina):**
- `src/auth/auth.service.ts` o `src/auth/onboarding.service.ts` (modificar condición de completado)

**Bloqueante:** Sí — depende de la reunión con cliente

---

### [ ] M1-DT-04 — Agregar `@IsEnum(OnboardingStep)` a `currentStep` en `UpdateOnboardingStepDto`

**Descripción:** El campo `currentStep` acepta cualquier string. Se debe crear un enum con los valores válidos y validar el DTO con `@IsEnum`.

**Pasos:**
1. Crear `src/auth/enums/onboarding-step.enum.ts`:
   ```typescript
   export enum OnboardingStep {
     EMAIL_VERIFICATION = 'email_verification',
     BIOMETRIC_SETUP = 'biometric_setup',
     PROFILE_BASIC = 'profile_basic',
     WELCOME = 'welcome',
     DOCUMENT_UPLOAD = 'document_upload',
     DOCUMENT_PROCESSING = 'document_processing',
   }
   ```
2. En `UpdateOnboardingStepDto`, reemplazar `@IsString()` por `@IsEnum(OnboardingStep)`
3. Revisar todos los usos de `currentStep` en los servicios para asegurarse de que usan el enum

**Archivos afectados:**
- `src/auth/enums/onboarding-step.enum.ts` (nuevo)
- `src/auth/dto/update-onboarding-step.dto.ts` (modificar)
- `src/auth/auth.service.ts` (verificar usos)

**Bloqueante:** No — fix independiente, puede hacerse ahora mismo

---

### [ ] M1-DT-04 — Definir quién escribe `minDocThresholdMet = true`

**Descripción:** El checkpoint `minDocThresholdMet` no tiene activador. Se debe definir la lógica de cuándo y quién lo activa.

**Opciones:**
- **Opción A:** Un job batch que corre periódicamente y cuenta transacciones clasificadas por usuario
- **Opción B:** El servicio de importación de estados de cuenta activa el checkpoint al procesar N documentos exitosamente
- **Opción C:** Un hook en `TransactionService` que verifica el umbral al crear transacciones

**Decisión a tomar:**
1. ¿Cuántas transacciones / documentos es el umbral mínimo? (Ej: 10 transacciones, 1 documento procesado)
2. ¿Quién activa el checkpoint? (Job, ImportService, TransactionService)

**Archivos afectados (una vez decidido):**
- El servicio que activará el checkpoint (a definir)
- `src/auth/entities/user-onboarding.entity.ts` (sin modificar, solo referencia)

**Bloqueante:** Sí — depende de cashflow M3 y la decisión de umbral con cliente

---

## Mejoras adicionales (no bloqueantes)

### [ ] Tests unitarios para `OnboardingService` / lógica de completado

**Descripción:** Una vez resuelta la lógica de auto-completado, escribir tests que verifiquen:
- Onboarding se completa cuando todos los checkpoints requeridos son `true`
- Onboarding no se completa si falta algún checkpoint
- `resumeSurface` retorna el valor correcto según el estado

**Archivos afectados:**
- `src/auth/onboarding.service.spec.ts` (nuevo)

**Bloqueante:** No

---

### [ ] Documentar la decisión final en `decisions/`

**Descripción:** Una vez resuelta la lógica de onboarding con el cliente, crear el archivo de decisión en `decisions/onboarding-completion-criteria.md` en el workspace.

**Bloqueante:** No
