# Stack Tecnológico — Walvy

**Versión:** 1.0  
**Fecha:** 2026-05-14  
**Estado:** Vigente

---

## 1. Backend

### Framework principal

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `@nestjs/core` | `^10.0.0` | Framework NestJS | Módulos, controllers, services, DI |
| `@nestjs/common` | `^10.0.0` | Pipes, guards, filtros, decoradores | ValidationPipe global con whitelist |
| `@nestjs/platform-express` | `^10.0.0` | Adaptador Express | No usar Fastify |
| `@nestjs/config` | incluido | Variables de entorno | `ConfigService` en lugar de `process.env` directo |

### ORM y base de datos

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `typeorm` | `^0.3.28` | ORM | Patrón Repository. `DB_SYNC=false` en producción |
| `@nestjs/typeorm` | `^10.0.0` | Integración NestJS | `TypeOrmModule.forFeature([...])` por módulo |
| `pg` | `^8.20.0` | Driver PostgreSQL nativo | No usar `pg-native` |

### Autenticación y seguridad

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `@nestjs/jwt` | `^11.0.2` | JWT access tokens | Expiración 15 minutos, HS256 |
| `@nestjs/passport` | `^11.0.5` | Integración Passport | Estrategia JWT en `auth/strategies/` |
| `passport` | `^0.7.0` | Autenticación genérica | Solo como peer dep de passport-jwt |
| `passport-jwt` | `^4.0.1` | Estrategia JWT Passport | `AuthGuard('jwt')` en routes protegidas |
| `bcrypt` | `^6.0.0` | Hash de contraseñas | `saltRounds = 10`; también hashing de OTPs/tokens |
| `@nestjs/throttler` | `^6.5.0` | Rate limiting | `ThrottlerGuard` global, override en tests |

### Validación y serialización

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `class-validator` | `^0.14.4` | Validadores de DTOs | `@IsEmail()`, `@IsString()`, `@Matches()`, etc. |
| `class-transformer` | `^0.5.1` | Serialización/transformación | `@Exclude()` en campos sensibles, `plainToClass()` |

### Comunicaciones

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `nodemailer` | `^8.0.5` | Envío de emails | OTP verificación, email recovery. `MockMailService` en tests |

### Documentación API

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `@nestjs/swagger` | `^8.1.1` | Documentación OpenAPI | Disponible en `/api` (desarrollo) |
| `swagger-ui-express` | incluido | UI Swagger | Solo exponer en `NODE_ENV !== 'production'` o con auth |

---

## 2. Frontend

### Framework principal

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `expo` | `~54.0.27` | SDK Expo | Plataforma iOS/Android |
| `react` | `19.1.0` | Librería UI | Hooks, Context |
| `react-native` | `0.81.5` | Runtime móvil | No usar APIs web (localStorage, etc.) |
| `expo-router` | `~6.0.17` | Routing file-based | `app/` como delegate; screens en `features/` |

### Navegación y estado

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `@tanstack/react-query` | `^5.83.0` | Data fetching y cache | `useQuery` + `useMutation`; no Redux |
| `axios` | `^1.13.6` | Cliente HTTP | Interceptores auth; mock mode via flag |

### Validación

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `zod` | `^4.0.0` | Validación de schemas | Validar inputs de formularios en hooks |

### Almacenamiento seguro

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `expo-secure-store` | `~15.0.8` | Keychain / Keystore nativo | Tokens JWT y refresh. **Nunca** AsyncStorage para tokens |
| `expo-local-authentication` | `^55.0.9` | Biometría (FaceID / Fingerprint) | Login biométrico post autenticación |

### UI / Íconos

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `lucide-react-native` | `^1.7.0` | Iconografía | Solo íconos de esta librería; no mezclar |

### TypeScript

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `typescript` | `~5.9.2` | Lenguaje | Strict mode activado |

---

## 3. Testing

### Backend

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `jest` | `^29.5.0` | Test runner | `maxWorkers: 1` para e2e (DB compartida) |
| `ts-jest` | `^29.x` | Transformador TypeScript | Configurado en `jest-e2e.json` |
| `supertest` | `^7.0.0` | HTTP assertions e2e | Crea NestJS test app real |
| `@nestjs/testing` | incluido | Test module | `createTestingModule()`, override providers |

**Helpers de test definidos en el proyecto:**

- `createTestApp()`: levanta módulo de test con `MockMailService` y `ThrottlerGuard` override
- `uniqueEmail()`: genera email único `t_<timestamp>_<random>@e2e.test`
- `registerAndVerify()`: registro → confirmación OTP → login → retorna tokens
- `VALID_RUT`: constante `'12345678-5'` (RUT válido modulo-11)
- `MockMailService`: stub de Nodemailer que no envía emails reales

### Frontend

| Paquete | Versión | Propósito | Notas de uso |
|---------|---------|-----------|--------------|
| `jest-expo` | incluido | Preset Jest para Expo | Configurado en `package.json` |
| `@testing-library/react-native` | incluido | Queries y assertions de componentes | `renderWithProviders` helper |

---

## 4. Base de datos

| Componente | Versión | Propósito | Notas de uso |
|------------|---------|-----------|--------------|
| `PostgreSQL` | `15` | Motor de base de datos | Imagen oficial Docker `postgres:15` |
| `pgcrypto` | extensión nativa | UUIDs y funciones criptográficas | `gen_random_uuid()` |
| Triggers | — | Enforce status_domain | `enforce_status_domain()` valida FK de estados |
| Vistas SQL | — | Reportes y read models | 4 vistas en Layer 19 |

**No hay carpeta `migrations/` aún.** Antes del primer deploy a producción es obligatorio:
1. Deshabilitar `DB_SYNC`
2. Generar migrations con TypeORM CLI
3. Aplicar migrations en CI/CD

---

## 5. Servicios externos

| Servicio | Estado | Propósito | Notas |
|----------|--------|-----------|-------|
| **Flow.cl** | Activo | Pasarela de pagos Chile | Webhook HMAC-SHA256; requiere HTTPS público |
| **SMTP / Nodemailer** | Activo | Email transaccional (OTP, recovery) | Credenciales via `SMTP_*` env vars |
| **FCM / APNs** | Pendiente | Push notifications | No implementado hasta M3/M4 |
| **Open Banking API** | Pendiente | Importación automática de movimientos | No implementado; en scope M3 |

---

## 6. DevOps e infraestructura

### Docker

- Imagen backend: **multistage build** (build stage + production stage).
- `dumb-init` como PID 1 para manejo correcto de señales.
- `docker-compose.yml` en raíz del proyecto backend: levanta `api` + `postgres`.
- Variables de entorno via archivo `.env` (nunca commitear `.env` con valores reales).

### Scripts

```bash
# Backend
npm run start:dev      # desarrollo con watch
npm run start:prod     # producción
npm run test:e2e       # suite e2e completa
npm run build          # compilación TypeScript

# Frontend
bun run start          # Expo dev server
bun run ios            # simulador iOS
bun run android        # emulador Android
bun run test           # Jest
```

---

## 7. Package managers

| Entorno | Package manager | Motivo |
|---------|----------------|--------|
| Backend | `npm` | Estándar NestJS, compatibilidad CI |
| Frontend | `Bun ≥ 1.0` | Velocidad de instalación en Expo |

**Regla crítica:** NO mezclar package managers. No usar `bun` en el backend ni `npm` en el frontend. No commitear `bun.lockb` en el backend ni `package-lock.json` en el frontend.

---

## 8. IDEs y herramientas de desarrollo

| Herramienta | Propósito | Acceso |
|-------------|-----------|--------|
| **Swagger UI** | Explorar y probar la API | `http://localhost:3000/api` (solo dev) |
| **pgAdmin** / **TablePlus** | Explorar base de datos | Conexión local a PostgreSQL |
| **Postman collection** | Tests manuales de API | `docs/postman/` en el repo backend |
| **Expo Go** / **dev build** | Probar frontend en dispositivo | Expo CLI |

---

## 9. Variables de entorno

### Categorías (backend)

```bash
# Base de datos
DATABASE_URL=postgresql://user:pass@localhost:5432/walvy
DB_SYNC=false                         # true solo en desarrollo temporal

# Auth
JWT_SECRET=<secreto_seguro_32chars+>
JWT_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_DAYS=7

# Email (SMTP)
SMTP_HOST=smtp.ejemplo.cl
SMTP_PORT=587
SMTP_USER=noreply@walvy.cl
SMTP_PASS=<password>
EMAIL_VERIFICATION_EXPIRES_MINUTES=15
PASSWORD_RESET_EXPIRES_MINUTES=30

# Flow.cl
FLOW_API_KEY=<api_key>
FLOW_SECRET_KEY=<secret_key>
FLOW_API_URL=https://www.flow.cl/app/api   # o sandbox
FLOW_RETURN_URL=https://api.walvy.cl/subscriptions/flow/return
FLOW_CONFIRM_URL=https://api.walvy.cl/subscriptions/flow/webhook

# Planes (precios dinámicos sin deploy)
PLAN_PRO_MONTHLY_PRICE=5000           # CLP
PLAN_PRO_ANNUAL_PRICE=50000           # CLP

# App
NODE_ENV=production
PORT=3000
CORS_ORIGIN=https://walvy.cl
```

### Categorías (frontend)

```bash
EXPO_PUBLIC_API_URL=https://api.walvy.cl
EXPO_PUBLIC_USE_MOCK_MODE=false        # true para demos offline
```

**Regla:** Nunca hardcodear valores sensibles. Todo secret viene de variables de entorno. Las variables `EXPO_PUBLIC_*` son visibles en el bundle del cliente — no poner secrets allí.
