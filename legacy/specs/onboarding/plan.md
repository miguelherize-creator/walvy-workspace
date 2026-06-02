# Plan de Resolución: M1-DT-04 — Onboarding Auto-complete

> **Deuda técnica:** M1-DT-04
> **Módulo:** `auth` (onboarding)
> **Prioridad:** Alta — el onboarding nunca se completa con la lógica actual
> **Última revisión:** 2026-05-14

---

## El problema

El onboarding **nunca se completa automáticamente** con la lógica actual porque la condición de completado requiere que los cuatro checkpoints sean `true`:

```
biometricPrompted       = true   ← se activa correctamente
importAttempted         = true   ← se activa correctamente (si la app lo llama)
financialProfileCompleted = true ← NUNCA se activa (M2-DT-01 sin implementar)
minDocThresholdMet      = true   ← NUNCA se activa (M1-DT-03 bloqueado)
```

Esto significa que **ningún usuario puede completar el onboarding en producción** hasta que se resuelvan `financialProfileCompleted` y `minDocThresholdMet`.

---

## Análisis de la situación

### Por qué `financialProfileCompleted` no se activa

El checkpoint debería activarse cuando el usuario completa su perfil financiero (ingresos estimados, gastos fijos, capacidad de pago). Sin embargo:

- El endpoint `PUT /profile/financial` no está implementado (M2-DT-01)
- La pantalla de perfil financiero no tiene diseño aprobado
- No hay un flujo en el frontend que lleve al usuario a completar este paso

### Por qué `minDocThresholdMet` no se activa

El checkpoint debería activarse cuando el sistema tiene suficientes transacciones clasificadas para calcular la salud financiera del usuario. Sin embargo:

- El módulo de salud financiera (M1-DT-03) está bloqueado hasta que cashflow y deudas tengan datos reales
- No hay definición de cuántos documentos o transacciones constituyen el "umbral mínimo"

---

## Opciones de resolución

### Opción A: Eliminar `financialProfileCompleted` del check de auto-completado

**Descripción:** Modificar la condición de completado para que no requiera `financialProfileCompleted`. El checkpoint seguiría existiendo en la entidad para uso futuro, pero no bloquearía el onboarding.

**Nueva condición:**
```
completed = true
SI:
  biometricPrompted = true
  AND importAttempted = true
  AND minDocThresholdMet = true
```

**Pros:**
- Resuelve parcialmente el bloqueo
- Permite avanzar sin esperar M2-DT-01
- Bajo riesgo, cambio pequeño

**Contras:**
- `minDocThresholdMet` sigue sin activarse (el problema persiste)
- El perfil financiero queda desconectado del onboarding

---

### Opción B: Implementar M2-DT-01 primero (perfil financiero)

**Descripción:** Implementar `PUT /profile/financial` y la pantalla de perfil financiero antes de desbloquear el onboarding. El step `document_upload` se convierte en `profile_financial` o se agrega antes.

**Pros:**
- Resuelve `financialProfileCompleted` correctamente
- El onboarding queda completo funcionalmente

**Contras:**
- Requiere diseño UX aprobado por el cliente (aún no disponible)
- Bloquea el onboarding hasta que M2-DT-01 esté listo
- Mayor tiempo de implementación

---

### Opción C: Workaround manual desde el frontend

**Descripción:** La app llama `PATCH /auth/onboarding/step` con un step especial o el backend expone un endpoint `POST /auth/onboarding/complete` que fuerza el completado sin verificar checkpoints.

**Pros:**
- Solución inmediata, sin cambios en lógica de checkpoints
- El usuario puede completar el onboarding aunque los checkpoints no estén implementados

**Contras:**
- Rompe la integridad del sistema de checkpoints
- El onboarding se marcaría como completado sin haber pasado por todos los pasos reales
- Deuda técnica adicional

---

## Recomendación

**Alinear con el cliente cuál es el paso final real del onboarding antes de implementar cualquier opción.**

Las preguntas clave son:

1. ¿El perfil financiero (`financialProfileCompleted`) es parte del onboarding inicial o puede completarse después?
2. ¿El umbral de documentos (`minDocThresholdMet`) es una condición real de completado o es un indicador de madurez posterior?
3. ¿Cuál es el último paso que el usuario debe hacer para "terminar" el onboarding desde la perspectiva del producto?

**Si la respuesta es que el perfil financiero no es obligatorio en el onboarding inicial:** aplicar Opción A + definir activador para `minDocThresholdMet`.

**Si la respuesta es que el perfil financiero sí es obligatorio:** aplicar Opción B, con diseño UX como prerequisito.

---

## Dependencias

| Checkpoint | Depende de | Estado |
|------------|------------|--------|
| `financialProfileCompleted` | M2-DT-01 (perfil financiero) + diseño UX aprobado | Bloqueado |
| `minDocThresholdMet` | M1-DT-03 (job salud financiera) + cashflow real | Bloqueado |
| `importAttempted` | App llama correctamente PATCH /auth/onboarding/step | Funcional |
| `biometricPrompted` | Backend auto | Funcional |

---

## Plan de acción inmediato (antes de resolver la opción)

1. **Reunión con cliente** para definir el paso final del onboarding (ver `tasks.md`)
2. **Fix independiente de la decisión:** Agregar `@IsEnum(OnboardingStep)` en `UpdateOnboardingStepDto` (no depende de la opción elegida)
3. **Documentar la decisión** en `decisions/` del workspace una vez acordada con el cliente
