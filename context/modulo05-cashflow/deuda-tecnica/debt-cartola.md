# Deuda Técnica — Flujo Cartola / Statement Imports

**Fecha de análisis:** 2026-06-17
**Origen:** Revisión del flujo completo de subida de documentos durante onboarding (sesión con Claude Code)

---

## Contexto

El flujo de carga de cartolas involucra tres pantallas encadenadas:

```
onboarding-doc → onboarding-analysis → onboarding-analyzing → onboarding-first-ready
```

Durante la revisión se detectaron problemas de responsabilidad mezclada, estados perdidos y comportamiento incorrecto al retomar sesión. Se dejaron indicaciones al desarrollador responsable para corrección.

---

## DT-CARTOLA-01 — Resume desde login lleva a `onboarding-analyzing` sin documentos

- **Estado:** ❌ Sin corregir — pendiente de desarrollador
- **Severidad:** Alta — el usuario ve una pantalla de "procesando" falsa
- **Pantalla:** `OnboardingAnalyzingScreen`

**Síntoma:** Cuando un usuario sube un documento, cierra la app y vuelve a hacer login, el backend devuelve `currentStep: document_processing` + `resumeSurface: onboarding`. El mapa de rutas del login lo envía directamente a `/(auth)/onboarding-analyzing`. Pero esta pantalla espera `params.docs` (archivos del picker) para poder subir. Al venir del login los params llegan vacíos → entra a `simulateFallback()` → simula el progreso visual sin hacer ningún llamado real → navega a `onboarding-first-ready`.

**Raíz del problema:** `onboarding-analyzing` mezcla dos responsabilidades:
1. Subir documentos nuevos (flujo normal desde `onboarding-doc`)
2. Mostrar progreso de un upload ya en curso (flujo resume desde login)

Para el caso 2 necesita el `importId` del proceso en curso, que no viene en ningún param.

**Lo que debería pasar:** Al detectar `params.docs` vacíos Y `currentStep: document_processing`, la pantalla debería consultar el import en curso (`GET /statement-imports?status=processing`) y hacer polling a ese importId existente en lugar de simular.

**Archivos afectados:**
- `front-walvy/expo/features/auth/ui/OnboardingAnalyzingScreen.tsx` — función `startUpload()` y `simulateFallback()`
- `front-walvy/expo/features/auth/hooks/useLoginForm.ts` — `ONBOARDING_STEP_ROUTE["document_processing"]`

---

## DT-CARTOLA-02 — `downloadUnlocked` mezclado en pantalla de onboarding

- **Estado:** ❌ Sin corregir — pendiente de desarrollador
- **Severidad:** Media — no bloquea el flujo pero mezcla responsabilidades
- **Pantalla:** `OnboardingDocScreen`

**Síntoma:** La funcionalidad de desbloqueo de PDF con contraseña fue agregada directamente en `OnboardingDocScreen` por otro desarrollador. El problema es doble:

1. **El PDF desbloqueado no queda en la lista de documentos.** El usuario descarga el PDF sin clave fuera de la app, pero el original (con clave) sigue en la lista. El usuario tendría que subir el archivo desbloqueado manualmente — flujo confuso.

2. **Llama a `apiClient` directamente en el componente** (`POST /statement-imports/unlock-preview`), violando la arquitectura del proyecto donde las llamadas al backend van a través de services/hooks.

**Lo que debería pasar:** Si el flujo de desbloqueo se mantiene, debería:
- Reemplazar el doc con clave por el doc desbloqueado en la lista local
- Mover la llamada a `statementImportService` con una función `unlockPdf(uri, password)`

**Archivos afectados:**
- `front-walvy/expo/features/auth/ui/OnboardingDocScreen.tsx` — función `downloadUnlocked()`
- `front-walvy/expo/api/statementImportService.ts` — debería tener `unlockPdf()`

---

## DT-CARTOLA-03 — `pdfPassword` param viaja por pantalla que no lo usa

- **Estado:** ❌ Sin corregir — pendiente de desarrollador
- **Severidad:** Baja — funciona pero es frágil
- **Pantallas:** `OnboardingDocScreen` → `OnboardingAnalysisScreen` → `OnboardingAnalyzingScreen`

**Síntoma:** El `pdfPassword` se pasa como param de `onboarding-doc` a `onboarding-analysis`. Pero `OnboardingAnalysisScreen` recibe props `docs`, `onAddMore`, `onRemove`, `onComenzar` — no usa el password para nada. Luego `onboarding-analysis` lo reenvía a `onboarding-analyzing` que sí lo consume.

La cadena es `doc → analysis (transparente) → analyzing`. Si alguien modifica la navegación de `analysis` sin tener este contexto, el password se pierde silenciosamente y el upload falla con "wrong password" sin log claro.

**Lo que debería pasar:** Persistir el password en un store temporal o pasarlo directamente de `onboarding-doc` a `onboarding-analyzing` si es posible, sin atravesar pantallas intermedias.

**Archivos afectados:**
- `front-walvy/expo/features/auth/ui/OnboardingDocScreen.tsx` — `handleAnalizar()`, params enviados
- `front-walvy/expo/features/auth/ui/OnboardingAnalysisScreen.tsx` — recibe y re-envía param sin usarlo
- `front-walvy/expo/features/auth/ui/OnboardingAnalyzingScreen.tsx` — consume `params.pdfPassword`

---

## DT-CARTOLA-04 — `showExitModal` state perdido en `OnboardingDocScreen`

- **Estado:** ✅ Corregido en sesión 2026-06-17
- **Pantalla:** `OnboardingDocScreen`

**Qué pasó:** Otro desarrollador agregó la funcionalidad de desbloqueo de PDF sin respetar el estado existente del componente. Las funciones `handleMasTarde` y `handleConfirmExit` que usaban `setShowExitModal` estaban presentes, pero la declaración `const [showExitModal, setShowExitModal] = useState(false)` fue omitida. Causaba crash inmediato con `ReferenceError: showExitModal is not defined`.

**Fix aplicado:** Agregada la declaración del estado en línea 83 junto al resto de estados del componente.

---

## DT-CARTOLA-05 — `simulateFallback` no tiene logs y simula éxito silenciosamente

- **Estado:** ⚠️ Logs agregados, comportamiento aún incorrecto
- **Severidad:** Media — hace difícil detectar en QA cuándo el flujo fue real vs simulado
- **Pantalla:** `OnboardingAnalyzingScreen`

**Síntoma:** `simulateFallback()` hace avanzar el estado visual sin subir nada al backend. No había ningún log que lo indicara. Un tester o desarrollador vería la pantalla completarse normalmente sin saber que fue simulada. El log `[Upload done → onboarding-first-ready]` aparecía igual que en el flujo real.

**Fix parcial:** Se agregó log `"sin docs → simulateFallback"` para identificarlo. Pero el comportamiento sigue siendo incorrecto — ver DT-CARTOLA-01.

---

## Resumen de estado

| ID | Descripción | Severidad | Estado |
|---|---|---|---|
| DT-CARTOLA-01 | Resume login → analyzing sin docs → simulateFallback falso | Alta | ❌ Pendiente |
| DT-CARTOLA-02 | downloadUnlocked mezclado en screen, no actualiza lista | Media | ❌ Pendiente |
| DT-CARTOLA-03 | pdfPassword viaja por pantalla que no lo usa | Baja | ❌ Pendiente |
| DT-CARTOLA-04 | showExitModal state perdido en OnboardingDocScreen | Alta | ✅ Corregido |
| DT-CARTOLA-05 | simulateFallback sin logs, simula éxito silenciosamente | Media | ⚠️ Log agregado |

---

## Para comparar contra entregable del desarrollador

Al revisar el PR del desarrollador verificar:

1. **DT-CARTOLA-01:** ¿`OnboardingAnalyzingScreen` detecta que viene del login sin docs y hace polling al import existente en lugar de simular? ¿Llama a `GET /statement-imports` para encontrar el import en curso?

2. **DT-CARTOLA-02:** ¿`downloadUnlocked` fue movido a un service? ¿El PDF desbloqueado reemplaza al original en la lista de docs o se agrega como nuevo?

3. **DT-CARTOLA-03:** ¿El `pdfPassword` ya no viaja como param por `OnboardingAnalysisScreen`? ¿Se usa store temporal o navegación directa?

4. **DT-CARTOLA-04:** Verificar que el estado `showExitModal` esté declarado (ya corregido, no debería regresionar).

5. **DT-CARTOLA-05:** Verificar que `simulateFallback` tenga visibilidad en los logs y que solo se use como último recurso documentado, no como path normal.
