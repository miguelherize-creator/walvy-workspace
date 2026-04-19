# Context — Walvy

Material de contexto para Claude Code y otros asistentes. Complementa la raíz `CLAUDE.md`.

## Qué es el producto

**Walvy** es una app de finanzas personales orientada a flujo de caja, deuda (metodología bola de nieve), presupuesto, pagos y motivación. El repositorio contiene:

| Área | Ruta | Rol |
|------|------|-----|
| API | `Backend/backend/` | NestJS, REST, JWT, TypeORM, PostgreSQL |
| App móvil/web | `Frontend/rork-checkapp/expo/` | Expo + React Native, Expo Router, TanStack Query |
| Base de datos | `DB/` | DDL de referencia (`schema.sql`, `schema.dbml`) |
| Trabajo y producto | `utils/` | Prompts, documentación de organización, marca, datos de referencia |
| Guía IA | `ai/` | `context.md`, `rules.md` (incl. UI/UX), `skills.md`, `decisions.md` |
| Diagramas (frontend) | `Frontend/rork-checkapp/expo/docs/architecture.md` | Diagramas Mermaid de routing, capas, sprints y mock mode |

Backend y frontend suelen versionarse en **repos separados** bajo el mismo árbol de carpetas.

---

## Conectividad frontend ↔ backend

- El cliente usa `api/config.ts`: URL base + **`probeBackendReachability()`** contra **`GET {BASE}/health`**.
- **Web (navegador en el mismo PC que la API):** por defecto `http://localhost:3000`.
- **Emulador Android:** por defecto `http://10.0.2.2:3000`.
- **Dispositivo físico:** `EXPO_PUBLIC_BACKEND_BASE_URL=http://<IP-LAN-del-PC>:3000` en `expo/.env`.
- **CORS:** el backend debe listar el origen de Expo web (p. ej. `http://localhost:8081`) en `CORS_ORIGIN`.
- **Mock:** `EXPO_PUBLIC_USE_MOCK_MODE=true` fuerza mock; `=false` fuerza API aunque `/health` falle. Si no se define, el probe decide automáticamente.

---

## Fuente de verdad del negocio (MVP)

**Alcance funcional, criterios y guardrails:**

`utils/organizacion/docs/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`

---

## Visión resumida del MVP (8 módulos)

| # | Módulo | Sprint | Estado |
|---|--------|--------|--------|
| 1 | Enrolamiento / auth | Sprint 1 | Completo |
| 2 | Perfil y configuración | Sprint 2 | Completo |
| 3 | Home / dashboard | Sprint 3 | Completo |
| 4 | Movimientos (cashflow) | Sprint 4 | Pendiente |
| 5 | Presupuestos | Sprint 5 | Pendiente |
| 6 | Motor de deudas (snowball) | Sprint 6 | Pendiente |
| 7 | Pagos programados | Sprint 7 | Pendiente |
| 8 | Asistente IA | Sprint 8 | Pendiente |

**Fuera de alcance típico:** open banking completo, ML propio, pasarela in-app, etc. (ver CSV).

---

## Arquitectura frontend — Feature-First

El frontend usa **Feature-First + Clean Architecture**. Cada módulo vive en `features/<nombre>/` con cuatro capas:

```
features/<nombre>/
├── index.ts                 ← Contrato público (único punto de importación externo)
├── data/
│   └── <X>Repository.ts     ← Llama al service de api/
├── hooks/
│   └── use<X>.ts            ← Estado, validaciones, mutaciones — sin JSX
└── ui/
    └── <X>Screen.tsx        ← Solo renderiza; delega al hook
```

Regla de dependencias: `ui → hooks → data → api`. Ninguna capa importa hacia arriba.

Los archivos en `app/` son **delegates de 2 líneas** — importan el Screen de la feature y lo re-exportan. Toda la lógica vive en `features/`.

### Features implementadas (Sprints 1-3)

```
features/
├── auth/     data/ + hooks/ + ui/ + utils/ + index.ts
├── profile/  data/ + hooks/ + ui/ + index.ts
└── home/     hooks/ + ui/ + index.ts
```

### Tabs actuales

| Tab | Feature | Estado |
|-----|---------|--------|
| Balance (`/(tabs)/`) | `features/home/` | Completo |
| Presupuesto | `features/budget/` | Placeholder — Sprint 5 |
| Movimiento | `features/transactions/` | Placeholder — Sprint 4 |
| Chatbot | `features/assistant/` | Placeholder — Sprint 8 |

---

## Estado actual del código

### Backend
Módulos implementados: `auth`, `users`, `cashflow`, `mail`, `common`, `HealthController` (`GET /`, `GET /health`).

### Frontend
- **Sprints 1–3 completos**: `features/auth/`, `features/profile/`, `features/home/`
- **Routing**: grupos `(auth)/` y `(tabs)/` con Expo Router real
- **Mock mode**: `api/mocks/` separados por dominio (authMock, profileMock, mockMemory, mockHelpers)
- **Tests**: 23 archivos de test; tests de features en `features/<nombre>/__tests__/`, tests de pantallas en `app/__tests__/`
- **Docs**: `Frontend/rork-checkapp/expo/README.md` + diagramas en `docs/architecture.md`

### DB
Tablas en `DB/schema.sql`.

---

## Carpeta `utils/`

| Ruta | Uso |
|------|-----|
| `utils/prompts-rork/semana-NN/` | Prompts Rork por semana |
| `utils/organizacion/bitacora/` | Minutas |
| `utils/organizacion/docs/` | CSV MVP, `render.yaml`, exports |
| `utils/organizacion/diagramas/` | Diagramas (complementados por `expo/docs/architecture.md`) |
| `utils/organizacion/semanas/` | Contexto por etapa |
| `utils/brand/` | Assets marca Walvy |
| `utils/datos/cashflow/` | JSON de referencia |

---

## Nombre del producto

**Walvy** en producto, API y documentación. La carpeta **`Frontend/rork-checkapp`** es convención técnica (Expo/Rork).

---

## UI/UX

Reglas de color, espaciado y tipografía: **`ai/rules.md` → sección «UI y UX — Walvy»**.
