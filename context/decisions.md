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
- **Decisión:** El producto se documenta e implementa como **Walvy**. La carpeta `Frontend/rork-checkapp/` se mantiene por convención del tooling.

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
