# Decisiones de Arquitectura — Walvy

Registro de decisiones técnicas y de producto. Orden cronológico. No borrar — si se revoca una decisión, añadir una nueva entrada que la referencie.

---

## [repo] Alcance funcional del MVP
- **Decisión:** El scope lo gobierna el CSV en `legacy/utils/organizacion/docs/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`. Nuevas features deben citar una fila del CSV; lo fuera de alcance no se implementa sin nueva decisión.

## [repo] Stack backend
- **Decisión:** NestJS + TypeORM + PostgreSQL; validación con class-validator en DTOs; JWT access (15min) + refresh rotativo hasheado en DB.

## [repo] Stack frontend
- **Decisión:** Expo + React Native + Expo Router + TanStack Query; package manager **Bun** en frontend (nunca npm); alias `@/`.

## [repo] Nombre de producto: Walvy
- **Contexto:** Coexistían "CheckApp" y "Walvy" en docs, API, Docker y CSV.
- **Decisión:** El producto se documenta e implementa como **Walvy**. La carpeta `front-walvy/` se mantiene por convención del tooling.

## [2026-04-06] Health check y URL defaults
- **Decisión:** Backend expone `GET /health`. El frontend hace probe al arranque; URL por defecto según plataforma (Android emulator = `10.0.2.2:3000`); override con `EXPO_PUBLIC_BACKEND_BASE_URL`. Mock forzado con `EXPO_PUBLIC_USE_MOCK_MODE`.
- **Archivos:** `src/health.controller.ts`, `expo/api/config.ts`

## [2026-04-06] Paleta UI en context (no hardcodeada)
- **Decisión:** Tokens de color y tipografía viven en `expo/constants/colors.ts` y `theme.ts`. No reintroducir acento neón `#b6fc1e`.

## [2026-04-10] AuthProvider como infraestructura compartida
- **Contexto:** Duda si `store/AuthProvider.tsx` debía moverse a `features/auth/`.
- **Decisión:** `store/AuthProvider.tsx` permanece en `store/` como infraestructura compartida. Los hooks importan `useAuth()` desde `@/store/AuthProvider`. No es Clean Architecture pura — es honesto y operativo para el MVP.
- **Alternativas descartadas:** Mover estado auth a `features/auth/data/authStore.ts` — demasiada complejidad para MVP.

## [2026-04-10] Utils de auth vs utils genéricos
- **Decisión:** `parseRegisterIdentifier` / `normalizeRutForStorage` → `features/auth/utils/`. Validaciones genéricas (`isValidEmail`, `isStrongPassword`, `extractApiErrorMessage`) → `utils/validation.ts`.

## [2026-04-10] Mocks separados por dominio
- **Contexto:** `api/mockService.ts` era monolítico.
- **Decisión:** Estado compartido en `api/mocks/mockMemory.ts`. Implementaciones en `api/mocks/authMock.ts`, `api/mocks/profileMock.ts`. `mockService.ts` es el barrel de re-exportación. Cada nuevo dominio añade `api/mocks/<dominio>Mock.ts`.

## [2026-04-10] Barrels y contratos públicos de features
- **Decisión:** Para código nuevo, definir `index.ts` del módulo al crear la carpeta. El barrel expone solo lo que el exterior necesita — hooks, data y utils son privados. Si un archivo externo importa desde ruta interna (no el barrel), es encapsulación rota.

## [2026-04-10] Feature-First: Sprints 1–3
- **Contexto:** Pantallas monolíticas en `app/` con lógica, estado y UI mezclados.
- **Decisión:** Migración a Feature-First + Clean Architecture:
  - Sprint 1: `features/auth/` ✅
  - Sprint 2: `features/profile/` ✅
  - Sprint 3: `features/home/` ✅
- **Consecuencias:** Todos los archivos en `app/` son delegates de 2 líneas. Toda lógica y UI real vive en `features/`. Sprint 4+ siguen el mismo patrón.

## [2026-04-10] Routing: grupos (auth) y (tabs)
- **Contexto:** Frontend usaba componente `DashboardBottomMenu` custom con SVGs inline (+8000 líneas).
- **Decisión:** Eliminar `DashboardBottomMenu`. Usar grupos Expo Router: `(auth)/` para pantallas sin sesión; `(tabs)/` con `Tabs` nativo para Balance, Presupuesto, Movimiento, Chatbot. Tab "Inversiones" removida — fuera de MVP.
- **Archivos:** `app/(auth)/`, `app/(tabs)/_layout.tsx`

## [2026-04-10] Tests en `features/<nombre>/__tests__/`
- **Decisión:** Tests de componentes y hooks de una feature → `features/<nombre>/__tests__/`. Tests de componentes compartidos → `components/__tests__/`.

## [2026-04-19] Registro único por email; login multi-identificador
- **Contexto:** Existían 3 flujos de registro (email, RUT, username) con lógica bifurcada.
- **Decisión:**
  - **Registro:** formulario único con `firstName`, `lastName`, `rut`, `email`, `password`, `confirmPassword`, `acceptTerms`, `acceptPrivacy`. Email siempre obligatorio.
  - **Login:** campo `identifier` acepta email, RUT (`12345678-9`) o username. Backend detecta tipo y hace lookup.
  - `username` en tabla `app_user` es handle opcional, se configura desde perfil (no en registro).
  - Eliminar `identifierType` y flujo 'email_collection'. Onboarding siempre arranca en 'email_verification'.
- **Consecuencias:** `JwtPayload` cambia `username` → `email`. Password regex actualizado para exigir carácter especial. `DB/schema.sql` sincronizado.

## [2026-05-31] LoginScreen — 3 modos según estado de usuario guardado
- **Contexto:** El Figma original definía solo 2 estados (firstTime / savedUser) pero faltaba el flujo biométrico-only sin ingreso de password.
- **Decisión:** `LoginScreen.tsx` implementa 3 modos via `LoginMode = "firstTime" | "savedUserBiometric" | "savedUserPassword"`:
  - **`firstTime`** (Figma 3470:6974): email + password. Default si no hay usuario guardado.
  - **`savedUserBiometric`** (Figma 3470:7080): solo botón "Entrar" + biometría. Default si `canUseBiometric === true`. Link "Ingresar con clave" cambia a `savedUserPassword`.
  - **`savedUserPassword`** (Figma 3470:7098): solo password card. Default si hay `savedEmail` pero no biometría. Link "Cambiar de usuario" vuelve a `firstTime` (ver ADR siguiente).
- **Detección de modo inicial:**
  ```tsx
  const initialMode: LoginMode = canUseBiometric
    ? "savedUserBiometric"
    : effectiveEmail
    ? "savedUserPassword"
    : "firstTime";
  ```
- **Archivos:** `features/auth/ui/LoginScreen.tsx`, `features/auth/hooks/useLoginForm.ts`

## [2026-05-31] Persistencia de email para savedUser mode (LAST_USER_EMAIL_KEY)
- **Contexto:** Bug recurrente: `user.email` viene vacío de `/users/me` aunque haya sesión activa con biometría. Esto rompía el flujo "savedUserPassword" (Figma 3470:7098) porque el hook necesita email para enviar al backend.
- **Decisión:** Persistir el email del último usuario logueado en SecureStore (`LAST_USER_EMAIL_KEY = "walvy_last_user_email"`). Exponer `savedEmail` desde `AuthProvider` como fallback de `user.email`.
- **Reglas de limpieza:**
  - **Persistir** tras `login()` y `register()` exitosos
  - **Mantener** en logout soft (con biometría activa)
  - **Borrar** en logout hard (`logout({ forceComplete: true })`) — usado por "Cambiar de usuario"
- **Email "efectivo"** = `user?.email || savedEmail || ""` en todo lugar donde antes se leía `user.email` directo.
- **Archivos:** `store/AuthProvider.tsx`, `features/auth/hooks/useLoginForm.ts`, `features/auth/ui/LoginScreen.tsx`

## [2026-05-31] Divergencia consciente Figma: link "Cambiar de usuario"
- **Contexto:** Figma original `3470:7098` (Login con usuario guardado) **NO incluía** opción para cambiar de usuario. Esto dejaba al usuario atrapado en el device si olvidaba el password (sin alternativa que reinstalar la app). Apps fintech chilenas (BancoEstado, BCI, Banco de Chile) siempre tienen esta opción.
- **Acción inicial:** Se eliminaron los links "Cambiar de usuario" y "Entrar con Face ID" del código (eran extras no diseñados, audit `login-saved-user.md` los marcaba como "elementos extra").
- **Decisión revertida (con Figma actualizado):** Designer aprobó añadir el link en Figma `4425:5268` y `4425:5301`. Se reincorporó como link terciario (SemiBold 16px `#177E96` underline) entre el botón "Entrar a mi cuenta" y "¿Necesitas recuperar tu contraseña?".
- **Comportamiento técnico:** El handler `handleChangeUser` muestra confirmación nativa (`Alert.alert`) con mensaje destructivo y, al confirmar:
  1. `logout({ forceComplete: true })` — limpia tokens + savedEmail + desactiva biometría
  2. `setMode("firstTime")` — vuelve al estado limpio
  3. Reset de inputs (email, password)
- **Visibilidad:** Solo en `savedUser` modes (biometric + password). NO en `firstTime`.
- **Archivos:** `features/auth/ui/LoginScreen.tsx`, `store/AuthProvider.tsx` (opción `forceComplete` en `logout()`)

## [2026-06-01] Prompt biométrico — texto agnóstico por limitación del OS
- **Contexto:** Figma `3470:7138` muestra una modal custom "Acceso rápido — Usa tu huella para ingresar a Walvy" con botón "Volver". El prompt nativo de biometría (Android Knox / iOS Face ID) **NO es customizable** visualmente — el OS controla la apariencia por seguridad. Solo se puede modificar texto (`promptMessage`, `cancelLabel`, `fallbackLabel`).
- **Iteraciones del texto:**
  1. Hardcoded "Usa tu huella" → bug: en Samsung con huella+rostro mostraba texto incorrecto si user elegía "Rostro" tab
  2. Detección dinámica: "Usa tu huella o rostro" → redundante con texto del OS ("Escanee su huella digital")
  3. **Final:** "Usa el método de autenticación para ingresar a Walvy" — agnóstico, no se solapa con el texto del OS
- **Decisión:** El `promptMessage` no menciona el método específico (huella/rostro/Face ID). El OS ya lo indica visualmente y textualmente. `cancelLabel: "Volver"` (match Figma). `fallbackLabel: "Ingresar con clave"` (match link de LoginScreen).
- **Archivos:** `services/biometrics.ts` función `authenticate()`

## [2026-06-01] Reorganización de assets/images por categoría
- **Contexto:** `expo/assets/images/` tenía 89 archivos planos sin estructura: logos duplicados (`walvy_logo - copia.png`), iconos sueltos, mascotas en `/assets/` raíz, basura legacy. Imposible saber qué imagen usar sin grep.
- **Decisión:** Estructura por categorías:
  ```
  expo/assets/images/
  ├── brand/         # logos, isotipos, avatares, app-icon
  ├── mascots/       # personaje Walvy (en uso actual)
  ├── onboarding/    # slides 1→4-2
  ├── icons/         # iconos UI (light + dark variants con sufijo -dark)
  ├── decorative/    # backgrounds, cards, splash
  └── _unused/       # legacy sin uso actual (revisar con equipo de diseño)
  ```
- **Convenciones:**
  - **kebab-case** en inglés (`profile-dark.png` no `perfil_1_mo.png`)
  - **Dark variants** con sufijo `-dark` (no `_mo`)
  - **WebP** preferido sobre PNG para logos (mejor calidad/peso en mobile)
- **Eliminados:** 9 archivos basura confirmados (duplicados con sufijos "copia", "(2)", "_22", hashes opacos).
- **Pendiente:** revisar `_unused/` (32 archivos) con equipo de diseño antes de eliminar.
- **Archivos:** `expo/assets/images/`, READMEs por carpeta documentando convenciones.

## [2026-07-31] Modelo de ramas/releases/migraciones (Walvy-wide)
- **Contexto:** Erick (Walvy) propuso formalmente un modelo trunk-based/main-based para `back-walvy` y `front-walvy`: sin ramas permanentes por ambiente, releases via GitHub tag, deploy manual por workflow, migraciones TypeORM versionadas. Aprobado internamente por su equipo, pendiente de revisión conjunta con desarrollo.
- **Decisión:** Adoptar `feature/* → PR → main → GitHub Release/tag → deploy manual` como flujo objetivo. Detalle completo, gaps detectados y puntos abiertos en [`release-workflow.md`](release-workflow.md).
- **Consecuencias:** `develop` y `release` (permanentes en ambos repos hoy) quedan a depreciar. `back-walvy` ya tiene parte de la mecánica (`release-image.yml`, `deploy.yml`) pero con tag `vX.Y.Z` en vez de `backend-vX.Y.Z`, sin `run_migrations`, y sin migraciones TypeORM reales (hoy son `.sql` sueltos en `DB/migrations/`).
