# Decisions — Walvy

Registro de **decisiones de arquitectura, producto y operación** que deben persistir más allá de un chat o un PR. Objetivo: que cualquier persona (o asistente) entienda **qué se eligió, por qué y qué descartamos**.

Relacionado: `ai/context.md`, `ai/rules.md`, `ai/skills.md`, `CLAUDE.md`.

---

## Cómo añadir una entrada

Copia el bloque siguiente al final del archivo (orden cronológico). Usa fechas reales.

```markdown
### [YYYY-MM-DD] Título corto de la decisión

- **Contexto:** Qué problema o duda había.
- **Decisión:** Qué se hace de ahora en adelante.
- **Alternativas consideradas:** (opcional) Qué se descartó y por qué.
- **Consecuencias:** Impacto en código, despliegue, UX o alcance MVP.
- **Referencias:** Archivos, issues, filas del CSV, PRs.
```

Mantén cada decisión **acotada**. Si revocas algo, añade una nueva entrada que referencie la anterior en lugar de borrar historia.

---

## Decisiones documentadas

### [repo] Alcance funcional del MVP

- **Contexto:** Hay muchas ideas posibles (open banking, MFA externo, ML, pagos in-app).
- **Decisión:** El alcance y los guardrails del MVP se gobiernan con el CSV de producto en `utils/organizacion/docs/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`.
- **Consecuencias:** Nuevas features deben citar una fila del CSV; lo explícitamente fuera de alcance no se implementa sin nueva decisión.
- **Referencias:** `ai/rules.md`, `ai/context.md`.

### [repo] Stack backend y persistencia

- **Contexto:** Necesidad de API tipada, ecosistema Node y modelo relacional.
- **Decisión:** Backend en **NestJS**, **TypeORM**, **PostgreSQL**; validación con **class-validator** en DTOs; autenticación **JWT** (access + refresh con rotación y refresh hasheado en BD).
- **Consecuencias:** Esquema de referencia en `DB/schema.sql`; en desarrollo `synchronize`, en producción migraciones.
- **Referencias:** `CLAUDE.md`, `Backend/backend/`.

### [repo] Stack frontend y paquetes

- **Contexto:** App móvil/web compartida y flujo de rutas claro.
- **Decisión:** **Expo** + **React Native**, **Expo Router**, **TanStack React Query**; gestor de paquetes **Bun** en el frontend; imports con alias **`@/`**.
- **Consecuencias:** Comandos y dependencias del frontend no usan npm/yarn por convención.
- **Referencias:** `CLAUDE.md`, `Frontend/rork-checkapp/expo/`.

### [repo] Organización de material no código

- **Contexto:** Prompts, bitácora, diagramas y docs de producto mezclados.
- **Decisión:** Bajo `utils/`: `prompts-rork/semana-NN/`, `organizacion/` (bitacora, docs, diagramas, semanas), `brand/`, `datos/cashflow/`.
- **Consecuencias:** Documentación y prompts no viven dentro de `src/` de backend o frontend salvo excepción acordada.
- **Referencias:** `ai/context.md`.

### [2026-04-06] Nombre único de producto: Walvy

- **Contexto:** Convivían las etiquetas "CheckApp" y "Walvy" en docs, API, Postman, Docker y CSV.
- **Decisión:** El producto se documenta e implementa como **Walvy**. La carpeta `Frontend/rork-checkapp/` se mantiene por convención del tooling Rork/Expo.
- **Consecuencias:** Quien use Docker Compose con datos previos debe recrear el volumen. Tras el cambio de claves en SecureStore, los usuarios deben volver a iniciar sesión una vez.
- **Referencias:** Renombre de CSV y colecciones Postman bajo `Backend/backend/postman/`.

### [2026-04-06] Health check y defaults de URL en el cliente

- **Contexto:** El frontend necesitaba saber si la API está viva; las IPs LAN fijas fallaban en web.
- **Decisión:** Backend expone `GET /health`. El cliente hace probe al arranque; URL por defecto según plataforma; override con `EXPO_PUBLIC_BACKEND_BASE_URL`. Mock forzado o real vía `EXPO_PUBLIC_USE_MOCK_MODE`.
- **Consecuencias:** CORS debe permitir el origen de Expo web; documentado en `ai/context.md` y `ai/skills.md`.
- **Referencias:** `Backend/backend/src/health.controller.ts`, `Frontend/rork-checkapp/expo/api/config.ts`.

### [2026-04-06] Documentación de UI: paleta Walvy en `ai/rules.md`

- **Contexto:** La guía antigua mencionaba acento neón `#b6fc1e`; el código usa Brand Starter Kit (arena, teal, coral).
- **Decisión:** Reglas de UI/UX y tabla de tokens viven en **`ai/rules.md`**, alineadas a `expo/constants/colors.ts` y `theme.ts`.
- **Consecuencias:** Nuevas pantallas deben usar tokens; no reintroducir el neón como identidad principal.
- **Referencias:** `CLAUDE.md`, `ai/rules.md`.

### [2026-04-10] `AuthProvider` como infraestructura compartida (no dentro de features/auth/)

- **Contexto:** Al organizar la feature auth, surgió la duda de si `store/AuthProvider.tsx` debía moverse a `features/auth/` para lograr aislamiento estricto.
- **Decisión (MVP):** **`store/AuthProvider.tsx` permanece en `store/`** como infraestructura compartida (igual que el tema o el cliente HTTP). Los hooks de auth pueden importar `useAuth()` desde `@/store/AuthProvider` sin que eso sea un error de arquitectura.
- **Alternativas consideradas:** Mover estado auth a `features/auth/data/authStore.ts`, definir `IAuthRepository`, etc. — descartado por complejidad innecesaria en MVP.
- **Consecuencias:** No es Clean Architecture pura; es honesto y operativo para el MVP. Si se requiere testabilidad aislada, se puede migrar con una nueva entrada ADR.
- **Referencias:** `expo/store/AuthProvider.tsx`, `expo/features/auth/hooks/`.

### [2026-04-10] Ubicación de `registerIdentifier` vs `validation`

- **Contexto:** Duda sobre dónde poner el parseo de correo/RUT/nickname del registro.
- **Decisión:** **`parseRegisterIdentifier` / `normalizeRutForStorage` viven en `features/auth/utils/`** (lógica de dominio de auth). Las reglas genéricas (`isValidEmail`, `isStrongPassword`, `extractApiErrorMessage`) permanecen en **`utils/validation.ts`**.
- **Consecuencias:** `utils/index.ts` reexporta solo validación genérica. La feature auth reexporta sus utils desde `features/auth/utils/index.ts`.
- **Referencias:** `expo/features/auth/utils/registerIdentifier.ts`, `expo/utils/validation.ts`.

### [2026-04-10] Mocks de API separados por dominio

- **Contexto:** `api/mockService.ts` mezclaba mocks de autenticación y perfil en un solo archivo monolítico.
- **Decisión:** Estado compartido en **`api/mocks/mockMemory.ts`**; implementaciones en **`api/mocks/authMock.ts`** y **`api/mocks/profileMock.ts`**. **`api/mockService.ts`** es el barrel de re-exportación para no romper `authService` / `profileService` / tests.
- **Consecuencias:** Cada nuevo dominio añade su propio `api/mocks/<dominio>Mock.ts` y registra en `mockService.ts`. `authMock.ts` importa desde `@/utils` (no desde `@/features/auth/utils`) para evitar inversión de dependencias.
- **Referencias:** `expo/api/mocks/`, `expo/api/mockService.ts`.

### [2026-04-10] Barrels (`index.ts`) y contrato público de cada feature

- **Contexto:** En un plan ideal, el barrel define la API pública antes del código. En este repo se añadieron durante el refactor.
- **Decisión:** Para **código nuevo**, definir o actualizar el `index.ts` del módulo al crear la carpeta. El barrel de la feature expone solo lo que el exterior necesita; hooks, data y utils son privados.
- **Consecuencias:** Guía de proceso obligatoria para Sprint 4+. Si un archivo externo importa desde una ruta interna (ej. `@/features/profile/hooks/useProfileForm`) en lugar del barrel, es una señal de encapsulación rota.

### [2026-04-10] Arquitectura Feature-First: Sprints 1–3

- **Contexto:** El frontend tenía pantallas monolíticas directamente en `app/` con lógica, estado, validación y UI mezclados. Sin separación por dominio.
- **Decisión:** Migración a **Feature-First + Clean Architecture** en tres sprints:
  - Sprint 1: `features/auth/` — data + hooks + ui + utils.
  - Sprint 2: `features/profile/` — data + hooks + ui.
  - Sprint 3: `features/home/` — hooks + ui. Corrección de mock imports (authMock → `@/utils`). Eliminación de código muerto (5 iconos DashboardBottom*, `app/modal.tsx`).
- **Alternativas consideradas:** Mantener pantallas en `app/` con hooks separados (sin carpeta features). Descartado porque mezcla routing con lógica de negocio y no escala a 8 módulos MVP.
- **Consecuencias:**
  - Todos los archivos en `app/` son delegates de 2 líneas.
  - Toda lógica y UI real vive en `features/`.
  - Tests de componentes de features viven en `features/<nombre>/__tests__/`, no en `components/__tests__/`.
  - Sprint 4+ siguen el mismo patrón: crear la feature completa, luego reducir el placeholder de tab a delegate.
- **Referencias:** `CLAUDE.md`, `ai/rules.md`, `Frontend/rork-checkapp/expo/README.md`, `expo/docs/architecture.md`.

### [2026-04-10] Grupos de rutas Expo Router: `(auth)` y `(tabs)`

- **Contexto:** El frontend usaba un componente `DashboardBottomMenu` custom con SVGs inline (>8000 líneas) como navegación inferior. Las rutas de auth no estaban agrupadas.
- **Decisión:** Eliminar `DashboardBottomMenu` completamente. Usar grupos de Expo Router:
  - **`(auth)/`** para pantallas sin sesión (login, register, forgot-password, reset-password, change-password).
  - **`(tabs)/`** con el componente `Tabs` nativo de Expo Router para Balance, Presupuesto, Movimiento y Chatbot.
- **Alternativas consideradas:** Mantener el componente custom de nav inferior. Descartado: SVGs duplicados, no usa Expo Router real, imposible de mantener.
- **Consecuencias:** `app/dashboard.tsx` queda como redirect de compatibilidad (`/dashboard` → `/(tabs)`). La tab "Inversiones" fue removida por estar fuera del alcance MVP.
- **Referencias:** `expo/app/(auth)/`, `expo/app/(tabs)/_layout.tsx`, `expo/app/dashboard.tsx`.

### [2026-04-10] Ubicación de tests: `features/<nombre>/__tests__/`

- **Contexto:** Los tests de componentes de `features/home/ui/` (FinanceCard, UserMenu, etc.) vivían en `components/__tests__/` aunque importaban desde `@/features/home/ui/`.
- **Decisión:** Los tests de componentes y hooks de una feature viven en **`features/<nombre>/__tests__/`**. Los tests de componentes compartidos (`AppButton`, `AppInput`, `icons`) permanecen en `components/__tests__/`.
- **Consecuencias:** Los 6 archivos de test de home se movieron a `features/home/__tests__/` en el Sprint 3. Sprint 4+ deben crear `features/<nombre>/__tests__/` desde el inicio.
- **Referencias:** `expo/features/home/__tests__/`.

### [2026-04-19] Registro único por correo; login multi-identificador (email/RUT/username)

- **Contexto:** Existían 3 flujos de registro (email, RUT, username) con lógica bifurcada en backend. UX confusa; el onboarding tenía paso 'email_collection' solo para usuarios sin email.
- **Decisión:**
  - **Registro** pasa a un único formulario que recoge: `firstName`, `lastName`, `rut`, `email`, `password`, `confirmPassword`, `acceptTerms`, `acceptPrivacy`. Email es siempre obligatorio en el alta.
  - **Login** sigue siendo multi-identificador: el campo `identifier` acepta correo, RUT (`12345678-9`) o username (handle/alias). El backend detecta el tipo y hace el lookup correspondiente. Útil cuando el usuario recuerda su RUT pero no su correo.
  - **`username`** en la tabla `users` pasa a ser un handle opcional que el usuario puede configurar desde su perfil (no se pide en el registro).
  - Se elimina `identifierType` de la entidad y la lógica Flow B ('email_collection'). El onboarding siempre arranca en 'email_verification'.
- **Alternativas consideradas:** Mantener los 3 flujos de registro — descartado por complejidad de onboarding y porque el RUT ya se recoge en registro, por lo que el caso "no tengo email" no aplica en altas nuevas.
- **Consecuencias:**
  - Tabla `users`: añade `first_name`, `last_name`, `rut` (nullable unique), `accepted_privacy_at`; elimina `identifier_type`; convierte `email` en NOT NULL; `username` pasa a nullable unique (handle).
  - `JwtPayload`: cambia `username` → `email`.
  - `RegisterDto`: campos nuevos. `LoginDto`: campo `username` → `identifier`.
  - Password regex actualizado en todos los DTOs para exigir carácter especial (era el requisito documentado en CLAUDE.md pero no estaba implementado).
  - `DB/schema.sql` sincronizado: se añaden las tablas faltantes (`email_verification_tokens`, `onboarding_state`, `biometric_preferences`).
  - **Frontend (Sprint 1 - features/auth/)**: debe actualizar el formulario de registro, `authMock.ts`, `mockMemory.ts`, `utils/validation.ts` y los tipos de usuario para reflejar `firstName`/`lastName`/`rut` en lugar de `name`/`identifierType`/`needsEmailOnboarding`.
- **Referencias:** `Backend/backend/src/auth/`, `Backend/backend/src/users/`, `DB/schema.sql`.

---

## Índice por tema

| Tema | Entradas |
|------|----------|
| Producto / MVP | Alcance funcional del MVP; nombre único Walvy |
| Backend | Stack backend y persistencia; health `/health` |
| Frontend — stack | Stack frontend y paquetes; probe y URLs por plataforma |
| Frontend — arquitectura | Feature-First Sprints 1–3; grupos de rutas (auth)/(tabs); AuthProvider en store; barrels y contratos |
| Frontend — datos | auth utils vs validation; mocks separados por dominio; inversión de dependencias resuelta |
| Frontend — tests | Ubicación de tests en features/__tests__ |
| UI/UX | Paleta documentada en `ai/rules.md` |
| Repositorio | Organización de material no código |
