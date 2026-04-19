# Skills — Tareas habituales en Walvy

Guía práctica: rutas, comandos, Docker, variables y dónde tocar código según la arquitectura Feature-First actual.

## Rutas de trabajo

| Repo / parte | Ruta |
|--------------|------|
| Backend | `Walvy/Backend/backend` |
| Frontend (app Expo) | `Walvy/Frontend/rork-checkapp/expo` |

El **`package.json`** de la app está en **`expo/`**; ejecuta siempre comandos de frontend desde ahí.

---

## Backend

```bash
cd Backend/backend
npm install
cp .env.example .env   # y editar
```

**Solo PostgreSQL en Docker, API en Node (misma máquina):**

```bash
docker compose up -d postgres
# .env → DATABASE_URL=postgresql://walvy:walvy@localhost:5432/walvy
npm run start:dev
```

**API + DB en Docker:**

```bash
docker compose up --build
```

**Reiniciar solo el contenedor API** (no borrar datos):

```bash
docker compose restart api
# o, tras cambios en Dockerfile:
docker compose up -d --build api
```

- Swagger: **http://localhost:3000/api**
- Liveness: **http://localhost:3000/health** (`{ "ok": true }`)
- Raíz: **http://localhost:3000/** (JSON con `service`, `health`, `docs`)

Incluye en **`CORS_ORIGIN`** los orígenes de Expo web (p. ej. `http://localhost:8081`, `http://127.0.0.1:8081`).

---

## Frontend

```bash
cd Frontend/rork-checkapp/expo
bun i
bun run start          # Metro (device / emulator)
bun run start-web      # browser
bun run lint
bun run test           # todos los tests
bun run test --watch   # watch mode
bun run test --coverage
```

- **Logs en web:** consola del navegador (F12), no la terminal de Metro.
- **URL del API:** `expo/.env` → `EXPO_PUBLIC_BACKEND_BASE_URL` si hace falta; si no, defaults por plataforma en `api/config.ts`.
- **Probe:** al arranque se llama `GET {BASE}/health`; si falla → mock mode (salvo `EXPO_PUBLIC_USE_MOCK_MODE=false`).
- **Cuenta de prueba en mock:** `test@walvy.app` / `Test1234!`

---

## Dónde implementar qué (Feature-First)

### Frontend — nueva funcionalidad

| Necesidad | Dónde va |
|-----------|----------|
| UI de una pantalla | `features/<nombre>/ui/<Nombre>Screen.tsx` |
| Lógica, estado, validaciones | `features/<nombre>/hooks/use<Nombre>.ts` |
| Llamadas al API | `features/<nombre>/data/<Nombre>Repository.ts` |
| Endpoints reales | `api/<nombre>Service.ts` |
| Datos mock | `api/mocks/<nombre>Mock.ts` + re-exportar en `api/mockService.ts` |
| Utilidades genéricas (email, password) | `utils/validation.ts` |
| Utilidades de dominio | `features/<nombre>/utils/` |
| Componente UI compartido | `components/` |
| Ruta Expo Router | `app/<nombre>.tsx` (2 líneas delegate) + registrar en `app/_layout.tsx` |
| Tests de pantalla | `app/__tests__/<nombre>.test.tsx` |
| Tests de componentes de la feature | `features/<nombre>/__tests__/` |

### Backend — nueva funcionalidad

| Necesidad | Dónde va |
|-----------|----------|
| Login, refresh, forgot/reset password | `src/auth/` |
| Perfil, contraseña autenticado | `src/users/` |
| Cashflow (movimientos, categorías) | `src/cashflow/` |
| Presupuesto | `src/budget/` (a crear) |
| Deudas / snowball | `src/debts/` (a crear) |
| Pagos | `src/payments/` (a crear) |
| Email / notificaciones | `src/mail/` |
| Salud / raíz | `src/health.controller.ts` |

---

## Checklist completa para añadir una feature (frontend)

```
□ api/<nombre>Service.ts
    — llamadas Axios reales
    — check isMockMode → delegar a mock

□ api/mocks/<nombre>Mock.ts
    — implementación mock usando mockMemory

□ api/mockService.ts
    — re-exportar nuevas funciones mock

□ features/<nombre>/data/<X>Repository.ts
    — wrappea el service con firma propia

□ features/<nombre>/hooks/use<X>.ts
    — estado, validaciones, useMutation / useQuery
    — importa desde ../data/

□ features/<nombre>/hooks/index.ts
    — barrel de hooks

□ features/<nombre>/ui/<X>Screen.tsx
    — solo JSX, consume el hook

□ features/<nombre>/ui/index.ts
    — barrel de screens

□ features/<nombre>/index.ts
    — contrato público: exporta solo lo que el exterior necesita

□ app/<nombre>.tsx
    — 2 líneas: import Screen + export default

□ app/_layout.tsx
    — agregar Stack.Screen name="<nombre>"

□ app/__tests__/<nombre>.test.tsx
    — renderWithProviders, mocks de router y auth

□ features/<nombre>/__tests__/
    — tests de componentes y hook
```

---

## Calidad antes de cerrar

- **Backend:** `npm run lint`, `npm run build`, `npm test` si aplica.
- **Frontend:** `bun run lint`, `bun run test`.

---

## Material auxiliar

- Diagramas Mermaid (routing, capas, sprints): `Frontend/rork-checkapp/expo/docs/architecture.md`
- Prompts Rork: `utils/prompts-rork/semana-NN/`
- Marca: `utils/brand/Walvy_assets_cerrados_final/`
- Datos JSON de referencia: `utils/datos/cashflow/*.json`

---

## Entrada para IA

- `CLAUDE.md` — panorama, comandos y convenciones clave.
- `ai/context.md` — MVP, estado actual, arquitectura Feature-First, módulos por sprint.
- `ai/rules.md` — reglas de arquitectura + **UI/UX + checklist** de feature.
- `ai/skills.md` — este archivo: comandos, rutas, dónde tocar código.
- `ai/decisions.md` — ADRs.
- `Frontend/rork-checkapp/expo/docs/architecture.md` — diagramas Mermaid.
