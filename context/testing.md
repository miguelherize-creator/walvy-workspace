# Estrategia de Testing — Walvy

**Estado actual**

| Categoría | Cantidad | Estado |
|-----------|----------|--------|
| E2E backend (Supertest/Jest) | 75 tests | ✅ Activo |
| Unit tests frontend (RTL) | 37 tests | ✅ Activo |
| E2E UI (Playwright sobre Expo Web) | 5 suites | ✅ Activo — `e2e/` |
| Unit tests backend (Jest) | 0 | ❌ Deuda técnica |

---

## 1. E2E Backend — Supertest + Jest

**Ubicación:** `Backend/MVP-CheckApp/test/`  
**Runner:** Jest 29 + Supertest  
**Config:** `jest-e2e.json` con `maxWorkers: 1` (DB compartida, no paralelizable)

### Estructura de suites

```
Backend/MVP-CheckApp/test/
├── auth.e2e-spec.ts
├── users.e2e-spec.ts
└── helpers/
    ├── app.helper.ts       → createTestApp()
    ├── mail.helper.ts      → MockMailService
    └── auth.helper.ts      → uniqueEmail(), registerAndVerify(), VALID_RUT
```

### Helpers

**`createTestApp()`** — levanta NestJS con `MockMailService` (sin emails reales) y sin `ThrottlerGuard`.

**`MockMailService`** — stub que expone `lastOtp: string | null` para usar en tests.

**`uniqueEmail()`** — genera `t_<timestamp>_<random>@e2e.test`. Siempre usar, nunca reutilizar emails.

**`VALID_RUT`** — `'12345678-5'` (válido por módulo-11). Constante compartida.

**`registerAndVerify()`** — flujo completo: registro → OTP → login → retorna `{ accessToken, refreshToken, userId }`.

### Comandos

```bash
cd Backend/MVP-CheckApp
npm run test:e2e                                    # todos
npm run test:e2e -- --testPathPattern=auth          # solo auth
```

---

## 2. E2E UI — Playwright sobre Expo Web

**Ubicación:** `workspace/walvy-workspace/e2e/`  
**Runner:** Playwright + Chromium  
**Suites:** login, register, dashboard, forgot-password, navigation

### Modos de ejecución

```bash
# MOCK (por defecto — sin backend ni DB)
cd e2e && npm test

# FULL STACK (requiere PostgreSQL + backend en :3000)
cd e2e && cross-env E2E_MODE=api npm test
```

El frontend arranca automáticamente en `:8081` (Expo Web).  
En modo FULL, el backend también arranca desde `../../../Backend/MVP-CheckApp`.

### Variables de entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `E2E_MODE` | `mock` | `mock` = sin backend; `api` = full stack |
| `FRONTEND_URL` | `http://localhost:8081` | URL del frontend Expo Web |
| `BACKEND_URL` | `http://localhost:3000` | URL del backend NestJS |
| `SLOW_MO` | `0` | ms de delay por acción (debug visual) |

### Estructura

```
workspace/walvy-workspace/e2e/
├── playwright.config.ts
├── package.json
├── tsconfig.json
├── tests/
│   ├── login.spec.ts
│   ├── register.spec.ts
│   ├── dashboard.spec.ts
│   ├── forgot-password.spec.ts
│   └── navigation.spec.ts
└── helpers/
    └── auth.ts
```

---

## 3. Tests Frontend — RTL + jest-expo

**Ubicación:** `Frontend/rork-checkapp/expo/**/__tests__/`  
**Runner:** Jest + React Native Testing Library  
**Helper:** `renderWithProviders()` — envuelve con `QueryClientProvider` + `AuthProvider` + `ThemeProvider`

```bash
cd Frontend/rork-checkapp/expo
bun run test              # todos
bun run test --watch      # watch mode
bun run test --coverage   # con coverage
bun run test features/auth
```

---

## 4. Reglas transversales

1. **Cada test usa `uniqueEmail()`** — nunca reutilizar emails entre tests.
2. **No compartir `accessToken` entre tests** que modifican estado.
3. **No usar `sleep()`** — usar `await` o `waitFor()` de RTL.
4. **El orden de tests no debe importar** — cada suite independiente.
5. **Todo endpoint nuevo necesita test de 401** sin token.
6. **`admin_audit_log` es append-only** — no hay que testear borrado.

---

## 5. Qué testear en e2e backend

**Happy paths:** registro, OTP, login, refresh, logout, perfil con token válido.  
**Guards:** 401 en toda ruta protegida sin token.  
**Validación:** 400 en email/RUT/contraseña inválidos, campos requeridos ausentes.  
**Errores de negocio:** email duplicado (409), contraseña incorrecta (401), OTP expirado.  
**Rotación tokens:** replay attack → 401 + revoca toda la sesión.

**No testear:** internals de services, schema de DB, hashing, emails reales, rate limiting.

---

## 6. Deuda de testing

| Tarea | Prioridad | Módulo |
|-------|-----------|--------|
| Unit tests `AuthService` | Alta | `src/auth/` |
| Unit tests `UsersService` | Alta | `src/users/` |
| E2E Supertest para cashflow (M5) | Media | `src/cashflow/` |
| E2E Supertest para subscripciones + webhooks Flow | Media | `src/subscriptions/` |
| E2E Playwright para Transactions (Sprint 4) | Media | `e2e/tests/` |
| Tests frontend `useLoginForm` | Media | `features/auth/` |
| Tests frontend `useProfile` | Media | `features/users/` |

---

## 7. CI/CD

```bash
npm run build          # TypeScript sin errores
npm run test:e2e       # Supertest e2e (DB efímera)
cd workspace/walvy-workspace/e2e && npm test     # Playwright mock mode
```

Un PR no debe mergearse si algún step falla.
