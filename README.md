# Walvy — App de Finanzas Personales

**Walvy** es una aplicación de finanzas personales (control de flujo de caja) con una API REST en **NestJS** y una app móvil en **React Native + Expo**. Permite registrar movimientos, presupuestar por categoría, visualizar deudas y recibir recomendaciones de un asistente financiero.

---

## Repositorios

| Parte | Repositorio |
|-------|-------------|
| Backend (NestJS + PostgreSQL) | [miguelherize-creator/MVP-CheckApp](https://github.com/miguelherize-creator/MVP-CheckApp) |
| Frontend (React Native + Expo) | [miguelherize-creator/rork-checkapp](https://github.com/miguelherize-creator/rork-checkapp) |

---

## Estructura del workspace

```
Walvy/
├── Backend/backend/          → API REST NestJS + PostgreSQL
├── Frontend/rork-checkapp/   → App móvil React Native (Expo)
│   └── expo/                 → Package real: package.json, app.json, fuentes
├── DB/                       → Schema SQL, DBML, casos de uso
├── E2E/                      → Tests end-to-end (Playwright)
├── ai/                       → Contexto, reglas y decisiones para el agente AI
└── utils/                    → Documentación interna, MVP scope
```

---

## Backend (`Backend/backend/`)

API REST en **NestJS + PostgreSQL** para autenticación completa y gestión de finanzas personales.

**Documentación interactiva (Swagger):** `http://localhost:3000/api`

### Requisitos

- Node.js 18+
- PostgreSQL 14+ (o Docker)

### Levantar con Docker (recomendado)

```bash
cd Backend/backend
docker compose up --build
# API en http://localhost:3000 · Swagger en /api
```

### Levantar en local

```bash
cd Backend/backend
cp .env.example .env   # ajustar DATABASE_URL, JWT_SECRET
npm install
npm run start:dev      # hot reload en http://localhost:3000
```

### Variables de entorno clave

| Variable | Descripción |
|----------|-------------|
| `DATABASE_URL` | Conexión PostgreSQL |
| `JWT_SECRET` | Secreto para tokens JWT |
| `CORS_ORIGIN` | Orígenes permitidos (incluir `http://localhost:8081` para Expo web) |
| `PASSWORD_RESET_URL_TEMPLATE` | Debe incluir `{{token}}` |
| `DB_SYNC` | `true` para sincronizar schema en producción (solo temporal) |

### Endpoints principales

| Método | Ruta | Descripción |
|--------|------|-------------|
| `POST` | `/auth/register` | Registro |
| `POST` | `/auth/login` | Login (límite 5 req/min) |
| `POST` | `/auth/refresh` | Nuevo access token |
| `POST` | `/auth/logout` | Revoca refresh token |
| `POST` | `/auth/forgot-password` | Solicita reset (límite 5 req/min) |
| `POST` | `/auth/reset-password` | Token + nueva contraseña |
| `GET` | `/users/me` | Perfil del usuario autenticado |
| `PATCH` | `/users/me` | Actualizar nombre/email |
| `PATCH` | `/users/me/password` | Cambiar contraseña |
| `GET` | `/health` | Liveness check — `{ ok: true }` |

### Scripts

```bash
npm run start:dev    # Desarrollo con hot reload
npm run build        # Compilar
npm run start:prod   # Ejecutar dist/
npm test             # Tests unitarios
npm run test:e2e     # Tests end-to-end
npm run lint         # Linter
```

---

## Frontend (`Frontend/rork-checkapp/expo/`)

App móvil de finanzas personales construida con **React Native + Expo**. El package real (`package.json`, `app.json`) vive en `expo/`.

### Requisitos

- **Bun** ≥ 1.0 — `curl -fsSL https://bun.sh/install | bash`
- Node.js ≥ 20
- iOS: macOS + Xcode 15+
- Android: Android Studio + emulador o dispositivo físico

### Ejecutar

```bash
cd Frontend/rork-checkapp/expo

bun i                        # Instalar dependencias
bun run start                # Metro + Expo (QR para Expo Go / device)
bun run start-web            # Vista previa en browser (http://localhost:8081)
bun run lint                 # Linter
bun run test                 # Tests unitarios
bun run test --watch         # Watch mode
bun run test --coverage      # Con cobertura
```

> El backend **no es obligatorio** para desarrollar UI. Si no está disponible, la app activa el **modo mock** automáticamente con datos de prueba.

### Variables de entorno

Crear `.env` en `Frontend/rork-checkapp/expo/`:

```env
# URL del backend (opcional — usa defaults por plataforma si no se define)
EXPO_PUBLIC_BACKEND_BASE_URL=http://localhost:3000

# Forzar mock mode: "true" = siempre mock | "false" = siempre API real | omitir = auto-detect
EXPO_PUBLIC_USE_MOCK_MODE=true
```

### Stack tecnológico

| Herramienta | Rol |
|-------------|-----|
| React Native + Expo SDK 52 | UI nativa cross-platform |
| Expo Router (file-based) | Navegación |
| TypeScript 5.x | Tipado estático |
| TanStack React Query 5.x | Fetching y mutaciones |
| Axios | Cliente HTTP con interceptores |
| Bun | Package manager y scripts |
| Jest + React Native Testing Library | Pruebas unitarias |
| expo-local-authentication | Biométrico (Face ID / Huella) |
| AsyncStorage | Persistencia local de tokens |

### Arquitectura — Feature-First

Cada módulo vive en `features/<nombre>/` con cuatro capas:

```
features/<feature>/
├── index.ts                   ← Contrato público
├── data/<X>Repository.ts      ← Acceso a la API
├── hooks/use<X>.ts            ← Estado y lógica — sin JSX
└── ui/<X>Screen.tsx           ← Solo renderiza; delega al hook
```

Flujo de dependencias (solo hacia abajo): `ui/ → hooks/ → data/ → api/`

### Estado de features

| # | Feature | Estado |
|---|---------|--------|
| 1 | `features/auth/` | Completo |
| 2 | `features/profile/` | Completo |
| 3 | `features/home/` | Completo |
| 4 | `features/transactions/` | Pendiente |
| 5 | `features/budget/` | Pendiente |
| 6 | `features/debts/` | Pendiente |
| 7 | `features/payments/` | Pendiente |
| 8 | `features/assistant/` | Pendiente |

### Modo Mock

Cuando el backend no está disponible, la app entra en mock automáticamente.

**Cuenta de prueba:**

| Campo | Valor |
|-------|-------|
| Email | `test@walvy.app` |
| Password | `Test1234!` |

---

## Base de datos

- `DB/schema.sql` — DDL PostgreSQL
- `DB/schema.dbml` — Descripción para diagramas

Tablas principales: `users`, `refresh_tokens`, `password_reset_tokens`, `funding_sources`, `categories`, `subcategories`, `transactions`.

---

## Diseño y tema

Walvy usa una paleta **warm sand + teal**. Fuentes de verdad:

- `Frontend/rork-checkapp/expo/constants/colors.ts`
- `Frontend/rork-checkapp/expo/constants/theme.ts`

Tokens principales: `theme.bg`, `theme.card`, `theme.oceanTeal`, `theme.mintSoft`, `theme.deepTeal`, `theme.textPrimary`, `theme.textSecondary`.

---

## Tests E2E

```bash
cd E2E
# Requiere backend corriendo en localhost:3000
npx playwright test
```
