# OnboardingAnalyzingScreen — Flujo de estados

Archivo: `front-walvy/expo/features/auth/ui/OnboardingAnalyzingScreen.tsx`  
Última actualización: 2026-07-04  
Estado: en pruebas activas

---

## Constantes de tiempo

| Constante | Valor | Rol |
|---|---|---|
| `AWAIT_KREAD_MS` | 15 000 ms | Umbral para disparar la modal #1 |
| `PRE_MODAL_CHECKS` | 3 | Checks antes de la modal |
| `PRE_MODAL_INTERVAL_MS` | 5 000 ms | `AWAIT_KREAD_MS / PRE_MODAL_CHECKS` |
| `POST_MODAL_INTERVAL_MS` | 10 000 ms | Intervalo después de la modal #1 |
| `SECOND_MODAL_AFTER_MS` | 45 000 ms | Modal #2 a los 60 s (15+45) |
| `MAX_POLL_DURATION_MS` | 120 000 ms | Timeout UX a los 2 min |

---

## Entrada — dos caminos

### Camino A — Upload nuevo (`params.docs` con contenido)

1. `POST /statement-imports/upload` con el PDF
   - 401 → `router.replace("/login")`
   - Error → pantalla de error (`uploadStep = 3`)
   - OK → guarda `importId` en `importIdRef` → arranca polling
2. `PATCH /auth/onboarding/step` con `document_processing` (fire & forget)
3. `pollStatus(importId)`

### Camino B — Resume (`params.docs` vacío)

1. `GET /statement-imports` → import más reciente
   - Sin imports → `onboarding-doc`
   - `parsed` → `advanceOnboardingStep` + `/(tabs)`
   - `failed` → guarda `importId`, pantalla de error con el `errorMessage` del import
   - `cancelled` → `advanceOnboardingStep` + `onboarding-doc`
   - `pending` / `processing` → guarda `importId`, arranca polling

---

## Polling — `pollStatus(importId)`

Llama `GET /statement-imports/:id/status` con esta cadencia:

```
t = 0 – 15 s   → intervalo 5 s (3 checks)
t = 15 s        → modal #1 aparece, intervalo pasa a 10 s
t = 25 s – ...  → intervalo 10 s
t = 60 s        → modal #2 aparece (mismo intervalo)
t = 120 s       → timeout UX → modal de timeout, polling se detiene
```

### Respuestas del polling

| `status` | Acción |
|---|---|
| `pending` / `processing` | Programa siguiente check |
| `parsed` | `uploadStep = 2` → navega a `onboarding-analysis` en 1.2 s |
| `failed` | `uploadStep = 3` → pantalla de error con `errorMessage` |
| `cancelled` | `router.replace("/(auth)/onboarding-doc")` |
| Error de red / 4xx | Reintenta en el mismo intervalo (no es terminal) |

---

## Modales durante el polling

### Modal #1 — t = 15 s (`isLongWait = false`)
- Título: "Parece que el análisis está tardando más de lo esperado."
- Cuerpo: "Puedes esperar aquí o salir de la app…"
- Botón principal: "Quiero esperar" → cierra modal, polling continúa
- Link: "Avisarme cuando esté listo" → `advanceOnboardingStep` + `/(tabs)`

### Modal #2 — t = 60 s (`isLongWait = true`)
- Título: "El análisis está tomando más tiempo del habitual."
- Cuerpo: "Walvy seguirá procesando en segundo plano…"
- Mismos botones

### Modal de timeout — t = 120 s (`isTimedOut = true`)
- Overlay no es tappable (no se puede descartar sin acción)
- Título: "Tu cartola sigue en proceso."
- Cuerpo: "Walvy continuará analizando en segundo plano. Te avisaremos cuando esté lista."
- Solo botón "Ir al inicio" → `advanceOnboardingStep` + `/(tabs)`
- El backend sigue procesando hasta el timeout interno de Kread (4 min)

---

## Pantalla de error — `uploadStep = 3`

El `errorMessage` viene con prefijo del backend:

| Prefijo | Título | Botón primario | Acción |
|---|---|---|---|
| `[WRONG_PASSWORD]` | "Contraseña incorrecta." | "Corregir contraseña" | `onboarding-doc` |
| `[UNSUPPORTED_BANK]` | "Banco no compatible." | "Subir otro documento" | `onboarding-doc` |
| `[SERVICE_ERROR]` | "No pudimos cargar la información." | "Reintentar" | `handleRetry()` |
| `[UNKNOWN_ERROR]` | "No pudimos cargar la información." | "Reintentar" | `handleRetry()` |

Siempre hay un link secundario "Volver al home" → `advanceOnboardingStep` + `/(tabs)`.

---

## Retry — `handleRetry()`

1. Resetea estado: `uploadStep = 0`, limpia `errorMsg`, `showDelayModal`, `isTimedOut`, `isLongWait`
2. Si `importIdRef` tiene ID → `POST /statement-imports/:id/retry`
   - 200 → `uploadStep = 1` + `pollStatus(record.id)`
   - 400 → archivo no disponible en S3 (import fue cancelado) → `onboarding-doc`
   - Otro error → pantalla de error
3. Si `importIdRef` vacío → `startUpload()` (re-sube el archivo)

---

## Tres escenarios

### Escenario A — Proceso exitoso dentro de 2 min
```
Pantalla abre → POST /upload → pollStatus
  t=5s   GET /status → processing  → espera
  t=10s  GET /status → processing  → espera
  t=15s  [modal #1 aparece — usuario puede ignorarla]
  t=25s  GET /status → parsed      → uploadStep=2
  t=26.2s → navigate onboarding-analysis (resultados de Kread)
```

### Escenario B — Kread tarda más de 2 min
```
Pantalla abre → POST /upload → pollStatus
  t=5s, 10s  processing
  t=15s      [modal #1]
  t=25s, 35s processing
  t=60s      [modal #2]
  t=70s, 80s processing
  t=120s     TIMEOUT → modal de timeout (isTimedOut=true)
             Usuario pulsa "Ir al inicio" → /(tabs)
             [backend sigue procesando hasta 4 min]
  → Al volver: resumeFromLastImport recoge el estado actual
```

### Escenario C — Kread falla (status: failed)
```
Pantalla abre → POST /upload → pollStatus
  t=5s, 10s  processing
  t=15s      [modal #1]
  t=25s      GET /status → failed [SERVICE_ERROR] No pudimos conectar...
             → uploadStep=3 → pantalla de error
             Usuario pulsa "Reintentar"
               → POST /retry → 200 pending → pollStatus (vuelve al ciclo)
               → POST /retry → 400 (S3 sin archivo) → onboarding-doc
```

---

## Llamadas API del componente

| Función | Endpoint | Cuándo |
|---|---|---|
| `uploadCartola` | `POST /statement-imports/upload` | Al montar, si hay docs en params |
| `listImports` | `GET /statement-imports` | Al montar, si no hay docs en params |
| `advanceOnboardingStep` | `PATCH /auth/onboarding/step` | Tras upload OK (fire & forget) |
| `getImportStatus` | `GET /statement-imports/:id/status` | Cada check del polling |
| `retryImport` | `POST /statement-imports/:id/retry` | Cuando el usuario pulsa "Reintentar" |
| `advanceOnboardingStep` | `PATCH /auth/onboarding/step` | Al ir al home (modal / timeout / link) |
