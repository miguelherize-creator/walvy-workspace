# AGENTS.md — Walvy Project Context
> Archivo maestro de contexto para agentes IA. Actualizar cuando cambien arquitectura, patrones o convenciones.
> Ver también: CLAUDE.md (comandos workspace), ARCHITECTURE.md (mapa del sistema), constitution/ (reglas detalladas)

---

## 1. Descripción del proyecto y objetivos

**Walvy** es una aplicación de finanzas personales orientada al mercado chileno (con soporte multi-país en la base de datos). Su propuesta de valor central es ayudar a los usuarios a entender y controlar su flujo de caja, gestionar deudas mediante la metodología bola de nieve, presupuestar por categorías, programar pagos recurrentes y acceder a un asistente IA que contextualiza su situación financiera.

### Principios de producto
- Tono orientativo, sin asesoría certificada ni promesas de resultado financiero.
- Interfaz cálida y clara; no agresiva ni financieramente intimidante.
- El alcance de cada feature está gobernado por el CSV del MVP, no por ideas ad-hoc.

### Fuente de verdad del MVP
```
workspace/walvy-workspace/utils/organizacion/docs/
  MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv
```
Toda nueva feature debe citar una fila de ese CSV. Lo explícitamente excluido no se implementa sin una nueva decisión documentada en `ai/decisions.md`.

### Objetivos del MVP (8 módulos, 8 sprints)
| Sprint | Módulo | Estado frontend | Estado backend |
|--------|--------|-----------------|----------------|
| 1 | Enrolamiento / auth | Completo | Completo |
| 2 | Perfil y configuración | Completo | Completo |
| 3 | Home / dashboard | Completo | Completo |
| 4 | Movimientos (cashflow) | Pendiente | Completo |
| 5 | Presupuestos | Pendiente | Solo entidades |
| 6 | Motor de deudas (snowball) | Pendiente | Solo entidades |
| 7 | Pagos programados | Pendiente | Solo entidades |
| 8 | Asistente IA | Pendiente | Solo entidades |

---

## 2. Arquitectura general

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENTE (Expo / RN)                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐    │
│  │  (auth)  │  │  (tabs)  │  │  store/  │  │   api/client.ts  │    │
│  │  routes  │  │  routes  │  │AuthProv. │  │  (Axios + JWT)   │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬─────────┘    │
│       │              │              │                  │              │
│  ┌────▼──────────────▼──────────────▼──────────────────▼─────────┐  │
│  │              features/<nombre>/                                 │  │
│  │  ui/ ──► hooks/ ──► data/ ──► api/<nombre>Service.ts           │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬──────────────────────────────────┘
                         HTTPS / REST
┌──────────────────────────────────▼──────────────────────────────────┐
│                        BACKEND (NestJS 10)                           │
│  main.ts → CORS, Swagger, ValidationPipe, AllExceptionsFilter        │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │  auth/  │ │  users/  │ │cashflow/ │ │ subscr.  │ │  profile/ │  │
│  └────┬────┘ └─────┬────┘ └─────┬────┘ └─────┬────┘ └─────┬─────┘  │
│  ┌────▼────────────▼────────────▼─────────────▼────────────▼─────┐  │
│  │        TypeORM 0.3.28  ──►  PostgreSQL 15                       │  │
│  │        ~55 tablas, 19 layers                                     │  │
│  └──────────────────────────────────────────────────────────────── │  │
│  ┌─────────────────────────────────────────────────────────────┐   │  │
│  │  Servicios externos: Flow.cl (pagos), Nodemailer (SMTP)      │   │  │
│  └─────────────────────────────────────────────────────────────┘   │  │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. Stack completo

### Backend
| Dependencia | Versión | Rol |
|-------------|---------|-----|
| NestJS | ^10.0.0 | Framework HTTP, DI, módulos |
| TypeScript | ^5.1.3 | Lenguaje |
| TypeORM | ^0.3.28 | ORM, entidades, queries |
| pg | ^8.20.0 | Driver PostgreSQL |
| @nestjs/jwt | ^11.0.2 | Generación/verificación JWT |
| passport-jwt | ^4.0.1 | Estrategia JWT para Passport |
| @nestjs/throttler | ^6.5.0 | Rate limiting |
| class-validator | ^0.14.4 | Validación de DTOs |
| class-transformer | ^0.5.1 | Transformación de payloads |
| bcrypt | ^6.0.0 | Hash de contraseñas y refresh tokens |
| nodemailer | ^8.0.5 | Envío de emails (OTP, reset) |
| Jest | ^29.5.0 | Tests unitarios y e2e |
| supertest | ^7.0.0 | Tests HTTP e2e |
| ts-jest | — | Transpilador Jest para TypeScript |

### Frontend
| Dependencia | Versión | Rol |
|-------------|---------|-----|
| Expo SDK | ~54.0.27 | Shell nativo + build |
| React | 19.1.0 | UI rendering |
| React Native | 0.81.5 | Componentes nativos |
| Expo Router | ~6.0.17 | File-based routing |
| TanStack React Query | ^5.83.0 | Data fetching, cache, mutations |
| Axios | ^1.13.6 | HTTP client |
| Zustand | ^5.0.2 | Importado, no activo en MVP |
| Zod | ^4.0.0 | Validación de esquemas |
| expo-secure-store | ~15.0.8 | Almacenamiento seguro de tokens |
| expo-local-authentication | ^55.0.9 | Biometría nativa |
| TypeScript | ~5.9.2 | Lenguaje |
| Bun | ≥1.0 | Package manager y runner |

### Base de datos
- PostgreSQL 15
- ~55 tablas organizadas en 19 layers (ver sección DB)
- Sin carpeta `migrations/` aún; `DB_SYNC=false` en producción
- TypeORM `synchronize: true` solo en desarrollo controlado

### Servicios externos
| Servicio | Estado | Uso |
|----------|--------|-----|
| Flow.cl | Activo | Pagos de suscripción (HMAC-SHA256, sandbox + producción) |
| SMTP / Nodemailer | Activo | OTPs, reset de contraseña, verificación email |
| FCM / APNs | Pendiente | Notificaciones push (Sprint 7/8) |
| Open Banking API | Pendiente | Importación automática de movimientos |

---

## 4. Reglas de código por capa

### Backend — DTOs
- Todo DTO lleva decoradores de `class-validator` en cada campo.
- Los DTOs son el único punto de validación de entrada HTTP; no validar solo en servicios.
- Naming: `PascalCase + Dto` (RegisterDto, LoginDto, UpdateProfileDto).
- Ubicación: `src/<módulo>/dto/<nombre>.dto.ts`.
- Ejemplo de patrón:
```typescript
export class RegisterDto {
  @IsEmail()
  email: string;

  @MinLength(8)
  @Matches(/^(?=.*[A-Z])(?=.*[0-9]).*$/, { message: '...' })
  password: string;
}
```

### Backend — Entidades TypeORM
- Naming: `PascalCase` (User, RefreshToken, OnboardingState).
- Ubicación: `src/<módulo>/entities/<Nombre>.ts`.
- Campos `numeric(12,2)` usan el transformer `decimalToNumber` (TypeORM → JS number).
- Soft deletes con `@DeleteDateColumn()` en: `app_user`, `financial_movement`, `debt`.
- No mezclar lógica de negocio en entidades; son solo mapeo.

### Backend — Services
- Naming: `PascalCase + Service` (AuthService, UsersService, CashflowService).
- Ubicación: `src/<módulo>/<módulo>.service.ts`.
- Solo lógica de negocio pura; delegan persistencia a TypeORM repository.
- No acceden a `Request` ni `Response` HTTP directamente.
- Lanzan `HttpException` o subclases para errores controlados.

### Backend — Controllers
- Naming: `PascalCase + Controller`.
- Solo orquestan: reciben DTOs validados, llaman al servicio, devuelven respuesta.
- Decoradores obligatorios en endpoints privados: `@UseGuards(AuthGuard('jwt'))`.
- Throttling declarado con `@UseGuards(ThrottlerGuard)` o `@Throttle()`.
- No poner lógica de negocio en controllers.

### Frontend — Screens (ui/)
- Naming: `PascalCase + Screen` (LoginScreen, HomeScreen).
- Ubicación: `features/<nombre>/ui/<Nombre>Screen.tsx`.
- Solo JSX y llamadas al hook de la feature.
- No contienen estado propio ni lógica de validación.
- Consumen el theme vía `useTheme()` (nunca `colors.*` directo en JSX de pantallas).
- Máximo un acento `coral` por pantalla.

### Frontend — Hooks
- Naming: `camelCase + use` (useLoginForm, useProfileForm).
- Ubicación: `features/<nombre>/hooks/use<Nombre>.ts`.
- Sin JSX; solo estado, validaciones, `useMutation` / `useQuery`.
- Importan desde `../data/` (relativo) y desde `@/store/` (alias cross-feature).
- Son la única capa que puede usar `useRouter` de expo-router.

### Frontend — Repositories (data/)
- Naming: `PascalCase + Repository` como archivo, funciones en `camelCase verbo`.
- Ubicación: `features/<nombre>/data/<Nombre>Repository.ts`.
- Wrapean el service de `api/`; único punto de cambio si cambia el servicio.
- Solo importan desde `@/api/`.

### Frontend — API Services (api/)
- Ubicación: `api/<nombre>Service.ts`.
- Realizan llamadas Axios reales; al inicio chequean `isMockMode()`.
- Si mock: delegan a `api/mocks/<nombre>Mock.ts`.
- `api/` no conoce `features/`; es infraestructura compartida.

---

## 5. Convenciones de naming

### Backend
| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| DTOs | PascalCase + Dto | `RegisterDto`, `LoginDto` |
| Entities | PascalCase | `User`, `RefreshToken` |
| Services | PascalCase + Service | `AuthService`, `UsersService` |
| Controllers | PascalCase + Controller | `AuthController` |
| Modules | PascalCase + Module | `AuthModule`, `CashflowModule` |
| Guards | PascalCase + Guard | `JwtAuthGuard` |
| Strategies | PascalCase + Strategy | `JwtStrategy` |
| Enums | PascalCase | `OnboardingStep` |
| Archivos DTO | kebab-case.dto.ts | `register.dto.ts` |
| Archivos entidad | kebab-case.ts | `refresh-token.ts` |
| Archivos servicio | kebab-case.service.ts | `auth.service.ts` |

### Frontend
| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Screens | PascalCase + Screen | `ProfileScreen` |
| Hooks | camelCase + use | `useLoginForm` |
| Repository functions | camelCase verbo | `updateProfile()`, `getMe()` |
| Constantes estáticas | UPPER_SNAKE | `ACCESS_TOKEN_KEY`, `MENU_ITEMS` |
| Providers | PascalCase + Provider | `AuthProvider`, `ThemeProvider` |
| Mock files | camelCase + Mock | `authMock.ts`, `profileMock.ts` |
| Service files | camelCase + Service | `authService.ts` |
| Tipos/Interfaces | PascalCase | `User`, `LoginPayload` |

---

## 6. Patrones arquitectónicos implementados

### JWT con refresh rotativo
- Access token: firmado, 15 min de expiración (`JWT_EXPIRES_IN=15m`).
- Refresh token: opaco, 7 días (`REFRESH_EXPIRES_DAYS=7`), almacenado hasheado en DB.
- Al usar refresh: se invalida el token anterior y se emite uno nuevo (rotación).
- `logout-all`: invalida todos los refresh tokens del usuario.
- Payload JWT: `{ sub, email, role }`.

### Proyección pública del usuario (`toPublic()`)
- Método en la entidad/servicio User que excluye `passwordHash` y campos sensibles.
- Toda respuesta HTTP que incluya datos de usuario debe usar `toPublic()`.

### Transformer `decimalToNumber`
- Patrón TypeORM para campos `numeric(12,2)`: convierte el string de Postgres a `number` en JS.
- Aplicado en todas las columnas de tipo decimal/numeric en entidades financieras.

### Seeds con `OnModuleInit` + upsert
- Los módulos de catálogo (catalog, cashflow data) implementan `OnModuleInit`.
- Upsert por clave única; idempotente en cada arranque.
- Controla qué seeds corren mediante variables `SEED_*`.

### AllExceptionsFilter global
- Respuesta de error estandarizada: `{ statusCode, message, path, timestamp }`.
- Registrado globalmente en `main.ts`.
- No expone stack traces en producción.

### ValidationPipe global
```typescript
new ValidationPipe({
  whitelist: true,
  forbidNonWhitelisted: true,
  transform: true,
  transformOptions: { enableImplicitConversion: true },
})
```

### Idempotencia en webhooks
- `payment_order.commerce_order` tiene constraint `UNIQUE`.
- El webhook de Flow.cl verifica HMAC-SHA256 antes de procesar.

### Trigger `enforce_status_domain()`
- Todas las columnas `*_status_id` tienen un trigger PL/pgSQL que valida el dominio.
- Previene inconsistencias de estados a nivel de base de datos.

### Mock mode (frontend)
- Al arranque: `probeBackendReachability()` llama `GET .../health`.
- Si falla: activa mock mode automáticamente.
- Override: `EXPO_PUBLIC_USE_MOCK_MODE=true|false`.
- Implementaciones mock: `api/mocks/authMock.ts`, `api/mocks/profileMock.ts`, estado compartido en `api/mocks/mockMemory.ts`.

### AuthProvider como infraestructura compartida
- `store/AuthProvider.tsx` vive en `store/`, no en `features/auth/`.
- Decisión deliberada MVP: AuthProvider es infraestructura compartida (como ThemeProvider o el cliente HTTP).
- Ver ADR en `ai/decisions.md`.

---

## 7. Cómo implementar una nueva feature (paso a paso)

### Backend — Nueva feature

**Paso 1: Crear el módulo**
```bash
# Estructura mínima en src/<nombre>/
<nombre>.module.ts
<nombre>.controller.ts
<nombre>.service.ts
dto/
  create-<nombre>.dto.ts
  update-<nombre>.dto.ts
entities/
  <Nombre>.ts
```

**Paso 2: Definir la entidad TypeORM**
- Extender entidades existentes si aplica (herencia o relaciones).
- Añadir transformer `decimalToNumber` en campos monetarios.
- Registrar en `<nombre>.module.ts` con `TypeOrmModule.forFeature([Nombre])`.

**Paso 3: Crear DTOs con class-validator**
- Todos los campos con decoradores explícitos.
- Validar en el límite HTTP; no solo en el service.

**Paso 4: Implementar el service**
- Inyectar el repository de TypeORM.
- Lanzar `HttpException` para errores controlados.
- No acceder a objetos HTTP.

**Paso 5: Crear el controller**
- Decorar con `@UseGuards(AuthGuard('jwt'))` si requiere autenticación.
- Usar `@CurrentUser()` para acceder al usuario autenticado.
- Aplicar throttling donde corresponda.

**Paso 6: Registrar el módulo en AppModule**
- Importar en `src/app.module.ts`.

**Paso 7: Agregar tests e2e**
- Crear `test/<nombre>.e2e-spec.ts`.
- Seguir el patrón: `ThrottlerGuard` bypass, `MockMailService`, base de datos de prueba.

### Frontend — Nueva feature

**Paso 1: API service**
```typescript
// api/<nombre>Service.ts
import { isMockMode } from './config';
import { <nombre>Mock } from './mocks/<nombre>Mock';
// llamadas Axios reales + check isMockMode
```

**Paso 2: Mock service**
```typescript
// api/mocks/<nombre>Mock.ts
// implementación mock usando mockMemory.ts
```
Re-exportar en `api/mockService.ts`.

**Paso 3: Repository**
```typescript
// features/<nombre>/data/<Nombre>Repository.ts
import { get<Nombre> } from '@/api/<nombre>Service';
export async function get<Nombre>(): Promise<...> { ... }
```

**Paso 4: Hook**
```typescript
// features/<nombre>/hooks/use<Nombre>.ts
import { get<Nombre> } from '../data/<Nombre>Repository';
// useQuery / useMutation de TanStack Query
// sin JSX
```

**Paso 5: Screen**
```typescript
// features/<nombre>/ui/<Nombre>Screen.tsx
import { use<Nombre> } from '../hooks/use<Nombre>';
// solo JSX, consume el hook
// useTheme() para colores
```

**Paso 6: Barrels**
```typescript
// features/<nombre>/ui/index.ts
export { <Nombre>Screen } from './<Nombre>Screen';

// features/<nombre>/hooks/index.ts
export { use<Nombre> } from './use<Nombre>';

// features/<nombre>/index.ts (contrato público)
export { <Nombre>Screen } from './ui';
```

**Paso 7: Route delegate**
```typescript
// app/<nombre>.tsx (exactamente 2 líneas)
import { <Nombre>Screen } from '@/features/<nombre>';
export default <Nombre>Screen;
```

**Paso 8: Registrar en layout**
```typescript
// app/_layout.tsx
<Stack.Screen name="<nombre>" />
```

**Paso 9: Tests**
- `app/__tests__/<nombre>.test.tsx` — integración de pantalla.
- `features/<nombre>/__tests__/` — tests de hook y componentes.
- Usar `renderWithProviders` de `@/test/test-utils`.

---

## 8. Reglas de imports

### Backend
- Imports absolutos usando los paths de TypeScript configurados.
- No imports circulares entre módulos.
- Un módulo importa a otro solo a través de su `Module` exportado (NestJS DI).

### Frontend
- **Cross-feature o cross-layer:** siempre alias `@/`.
  ```typescript
  import { useAuth } from '@/store/AuthProvider';
  import { AppButton } from '@/components/AppButton';
  ```
- **Dentro de la misma feature:** rutas relativas cortas.
  ```typescript
  import { updateProfile } from '../data/profileRepository';
  import { useProfileForm } from '../hooks/useProfileForm';
  ```
- **Nunca:** `../../..` ni imports relativos que salgan de `features/<nombre>/`.
- **Nunca:** importar desde ruta interna de otra feature (ej. `@/features/profile/hooks/useProfileForm`). Usar el barrel `@/features/profile`.
- **Nunca:** `api/` importa desde `features/`.

---

## 9. Principios Clean Architecture aplicados

### Regla de dependencias (frontend)
```
ui/ ──► hooks/ ──► data/ ──► api/
```
- Ninguna capa importa la que está sobre ella.
- `api/` es infraestructura; no conoce `features/`.
- Features distintas se comunican solo a través de `@/store/` o `@/utils/`.

### Separación de responsabilidades
| Capa | Responsabilidad única |
|------|----------------------|
| `ui/` | Renderizar JSX; cero lógica |
| `hooks/` | Estado, validaciones, efectos |
| `data/` | Wrapear el service; adaptador |
| `api/` | HTTP real o mock |

### Contratos públicos (barrels)
- Cada feature expone solo lo necesario en su `index.ts` raíz.
- El resto son detalles privados de implementación.
- Si código externo importa desde una ruta interna, es una señal de encapsulación rota.

### Backend: módulo por feature
- Cada módulo NestJS es autónomo (module, controller, service, entities, DTOs).
- Los módulos se conectan a través de importaciones explícitas en `AppModule`.
- Sin singletons globales fuera de los provistos por NestJS DI.

---

## 10. Reglas de testing

### Backend — Tests E2E
- Framework: Jest + Supertest.
- Configuración: `testTimeout: 30s`, `maxWorkers: 1`.
- Archivo: `test/<módulo>.e2e-spec.ts`.
- **Bypass obligatorio de ThrottlerGuard:**
  ```typescript
  .overrideGuard(ThrottlerGuard).useValue({ canActivate: () => true })
  ```
- **MockMailService:** intercepta OTPs sin SMTP real.
- **VALID_RUT en tests:** `'12345678-5'` (calculado con módulo-11).
- No usar `DB_SYNC=true` en tests; usar la misma DB de test definida en el entorno.
- 75 tests e2e en 10 suites (estado actual).

### Backend — Tests unitarios
- 0 tests unitarios actualmente (deuda técnica).
- Pendiente para servicios con lógica compleja.

### Frontend — Tests
- Framework: Jest + React Testing Library.
- 37 archivos de test (estado actual).
- `renderWithProviders` de `@/test/test-utils`: wrappea QueryClient + Theme + Auth.
- Mockear `expo-router`, `react-native-safe-area-context` y stores en tests de screens.
- Tests de pantallas: `app/__tests__/<nombre>.test.tsx`.
- Tests de componentes de feature: `features/<nombre>/__tests__/`.
- Tests de componentes compartidos: `components/__tests__/`.

### Regla general
- Antes de cerrar cualquier tarea: ejecutar el suite completo.
  - Backend: `npm run lint && npm run build && npm run test:e2e`
  - Frontend: `bun run lint && bun run test`

---

## 11. Reglas de seguridad

### Autenticación
- Todos los endpoints privados requieren `@UseGuards(AuthGuard('jwt'))`.
- No exponer passwordHash, refresh tokens hasheados ni datos sensibles en respuestas.
- Usar siempre `toPublic()` al retornar datos del usuario.

### Contraseñas
- **Registro:** mínimo 8 caracteres, 1 mayúscula, 1 dígito.
- **Cambio de contraseña:** mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 dígito, 1 carácter especial.
- Hash con bcrypt (factor por defecto de la librería).

### OTP y tokens de un solo uso
- 6 dígitos numéricos, validez 15 minutos.
- Invalidar inmediatamente tras uso exitoso.
- Email de verificación: 3 intentos/hora (throttler).

### Rate limiting
| Endpoint | Límite |
|----------|--------|
| POST /auth/login | 5/min |
| POST /auth/forgot-password | 5/min |
| POST /auth/email-verification/request | 3/hora |

### RUT chileno
- Formato válido: `12345678-5` (sin puntos, con guion, dígito verificador módulo-11).
- Validador utilitario en `src/common/`.

### Tokens en frontend
- Almacenados en `expo-secure-store`, nunca en `AsyncStorage`.
- Access token: memoria en AuthProvider.
- Refresh token: SecureStore.

### Flow.cl (pagos)
- Verificar HMAC-SHA256 en cada webhook antes de procesar.
- `commerce_order` UNIQUE para idempotencia.
- Nunca confiar en el estado del pago sin validar el webhook.

### Reglas generales
- `DB_SYNC=false` en producción (variable de entorno explícita).
- No exponer stack traces en respuestas de error (`AllExceptionsFilter`).
- Variables sensibles siempre en `.env`; nunca hardcodeadas.

---

## 12. Reglas para NO romper módulos existentes

### Módulos backend implementados y estables
Los siguientes módulos tienen tests e2e y están en uso. Cualquier modificación requiere:
1. Ejecutar el suite e2e completo.
2. No cambiar firmas de endpoints sin versionar.
3. No cambiar nombres de campos en DTOs sin migración de datos.

| Módulo | Endpoints críticos |
|--------|-------------------|
| auth | /auth/register, /auth/login, /auth/refresh, /auth/logout, /auth/email-verification |
| users | /users/me, PATCH /users/me/password |
| cashflow | /cashflow/transactions, /cashflow/categories, /cashflow/funding-sources |
| subscriptions | GET /subscriptions/plans, POST /subscriptions/checkout, POST /subscriptions/webhook |
| profile | GET /profile/financial |
| statement-import | POST /statement-import/upload |

### Reglas específicas
- **No modificar** `AllExceptionsFilter` ni `ValidationPipe` global sin revisar todos los tests.
- **No cambiar** el formato de `JwtPayload` (`{ sub, email, role }`) sin actualizar el frontend.
- **No modificar** el esquema de refresh tokens (tabla, rotación) sin coordinar con el frontend.
- **No agregar** campos NOT NULL a tablas existentes sin valor default o migración.
- **No tocar** las seeds de catálogo sin verificar que el upsert sea idempotente.
- **No cambiar** el formato de error `{ statusCode, message, path, timestamp }` sin actualizar el manejo de errores del frontend.

### Frontend — Módulos estables
- `features/auth/` — No modificar sin coordinar cambios en el backend de auth.
- `store/AuthProvider.tsx` — AuthProvider es infraestructura compartida; cualquier cambio afecta a todas las features.
- `api/client.ts` — El interceptor de 401 es crítico para el flujo de refresh; no modificar sin tests.

---

## 13. Módulos implementados con estado

### Backend
| Módulo | Estado | Qué incluye |
|--------|--------|-------------|
| auth | Completo | register, login, refresh, logout, logout-all, forgot-password, reset-password, email-verification (request/confirm/resend), biometric, onboarding |
| users | Completo | GET/PATCH /users/me, PATCH /users/profile, PATCH /users/me/password |
| cashflow | Completo | Transactions CRUD, categories CRUD, subcategories CRUD, funding-sources CRUD |
| subscriptions | Completo | GET plans (público), GET me, POST checkout (Flow.cl), POST webhook |
| profile | Completo | GET/PUT /profile/financial |
| mail | Completo | SMTP + dev console mode, OTP templates |
| statement-import | Completo | Upload PDF, list imports, reclassify lines |
| catalog | Completo | Seeds: países, monedas, documentos, roles, status |
| common | Completo | AllExceptionsFilter, @CurrentUser, RUT validator, crypto utils |
| health | Completo | GET / (info), GET /health (liveness) |

### Frontend
| Feature | Estado | Qué incluye |
|---------|--------|-------------|
| auth | Completo | data + 8 hooks + 9 screens + utils (register, login, OTP, biometric, onboarding) |
| profile | Completo | data + hooks + 5 screens |
| home | Completo | hooks + 12 componentes (FinanceCard, FinancialHealthRings, SummaryCarousel) |
| subscription | Parcial | data + hooks + ui placeholder |

---

## 14. Módulos pendientes (no implementar sin spec)

### Backend — Solo entidades, sin endpoints
| Módulo | Entidades presentes | Bloqueado por |
|--------|--------------------|--------------:|
| admin | AdminUser, AppConfig, AuditLog | Sin spec de endpoints |
| ai | AiConversation, AiMessage | Sprint 8 |
| budget | BudgetPeriod, BudgetLine | Sprint 5 |
| debts | Debt, DebtSchedule, DebtPayment, DebtAttachment, DebtSnowballPlan | Sprint 6 |
| gamification | GamificationRules, Events, UserStats, ScoreHistory | Sin spec |
| notifications | AlertPreferences, NotificationQueue | FCM/APNs pendiente |
| payments | RecurringPayment | Sprint 7 |

**Regla:** No agregar endpoints ni lógica a estos módulos sin una spec documentada y aprobada en el CSV del MVP.

### Frontend — Placeholders
| Feature | Tab | Sprint |
|---------|-----|--------|
| transactions | Movimiento | Sprint 4 |
| budget | Presupuesto | Sprint 5 |
| debts | — | Sprint 6 |
| payments | — | Sprint 7 |
| assistant | Chatbot | Sprint 8 |

---

## 15. Deuda técnica activa (no agregar workarounds)

| ID | Descripción | Módulo | Bloqueado por |
|----|-------------|--------|---------------|
| M1-DT-01 | `src/admin/` vacío; sin endpoints PATCH /admin/users/:id/status | admin | Sin spec |
| M1-DT-02 | Sin middleware RBAC enforcement (tablas sembradas, sin guard activo) | common | Sin spec |
| M1-DT-03 | Sin job/cron para calcular financial health level | users/profile | Sprint 3/4 |
| M1-DT-04 | Onboarding auto-completado roto: `financialProfileCompleted` requiere M2-DT-01; `minDocThresholdMet` requiere cashflow datos; `currentStep` sin validación enum | auth | M2-DT-01 |
| M2-DT-01 | Sin endpoints /profile/financial (PUT); pantalla sin diseño aprobado | profile | Diseño |
| M2-DT-02 | Sin endpoints /profile/goals (borrador de diseño) | profile | Diseño |
| M2-DT-03 | Sin endpoints /profile/alerts (depende de M2-DT-04) | profile | M2-DT-04 |
| M2-DT-04 | Sin worker de notificaciones; canales push FCM/APNs no definidos | notifications | Sprint 7 |

**Regla:** No agregar workarounds a la deuda técnica activa. Si se necesita desbloquear algo, documentar la decisión en `ai/decisions.md` y crear la solución correcta.

---

## 16. Variables de entorno requeridas

### Backend (`.env`)
```bash
# Base de datos
DATABASE_URL=postgresql://walvy:walvy@localhost:5432/walvy
DB_SYNC=false

# JWT
JWT_SECRET=<secreto-largo-aleatorio>
JWT_EXPIRES_IN=15m
REFRESH_EXPIRES_DAYS=7

# SMTP
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=no-reply@walvy.app
SMTP_PASS=<password>
MAIL_FROM="Walvy <no-reply@walvy.app>"

# Flow.cl (pagos)
FLOW_API_URL=https://sandbox.flow.cl/api
FLOW_API_KEY=<api-key>
FLOW_SECRET_KEY=<secret>
FLOW_CONFIRM_URL=https://api.walvy.app/subscriptions/webhook
FLOW_RETURN_URL=https://app.walvy.app/subscription/result

# Precios planes (CLP)
PLAN_PRO_MONTHLY_PRICE=5000
PLAN_PRO_ANNUAL_PRICE=50000

# CORS
CORS_ORIGIN=http://localhost:8081,http://127.0.0.1:8081

# Seeds (opcional)
SEED_CATALOG=true
SEED_CASHFLOW=true
```

### Frontend (`expo/.env`)
```bash
EXPO_PUBLIC_BACKEND_BASE_URL=http://localhost:3000
EXPO_PUBLIC_USE_MOCK_MODE=false
```

---

## 17. Comandos de desarrollo

### Backend
```bash
cd Backend/MVP-CheckApp

# Instalar dependencias
npm install

# Solo DB en Docker, API en local
docker compose up -d postgres
npm run start:dev

# Todo en Docker
docker compose up --build

# Reiniciar solo API (sin borrar datos)
docker compose restart api

# Tests
npm run test:e2e
npm run lint
npm run build

# Herramientas
curl http://localhost:3000/health        # Liveness check
# Swagger: http://localhost:3000/api
```

### Frontend
```bash
cd Frontend/rork-checkapp/expo

# Instalar (SIEMPRE con Bun, no npm/yarn)
bun install

# Desarrollo
bun run start          # Metro (device/emulator)
bun run start-web      # Navegador web

# Calidad
bun run lint
bun run test
bun run test --watch
bun run test --coverage
```

### Cuenta de prueba (mock mode)
- Email: `test@walvy.app`
- Password: `Test1234!`

---

## 18. Flujo de datos — Auth flow

```
REGISTRO
──────────────────────────────────────────────────────────────
Frontend                         Backend
  │                                 │
  │── POST /auth/register ─────────►│
  │   { firstName, lastName, rut,   │
  │     email, password }           │── Crea user (status: pendiente)
  │                                 │── Genera OTP 6 dígitos (15min)
  │◄─ 201 { user: toPublic() } ────│── Envía email verificación
  │                                 │
  │── POST /auth/email-verification/confirm ─►│
  │   { email, otp }               │── Valida OTP
  │◄─ 200 { message: 'ok' } ──────│── Actualiza status: activo
  │                                 │
  │── POST /auth/login ────────────►│
  │   { identifier, password }     │── Busca por email/RUT/username
  │◄─ 200 { accessToken,           │── Genera access (15min) + refresh
  │         refreshToken, user }   │   Almacena refresh hasheado en DB
  │                                 │

USO NORMAL (token expira)
──────────────────────────────────────────────────────────────
  │── GET /cashflow/transactions ──►│
  │   Authorization: Bearer <at>   │── 401 (token expirado)
  │◄─ 401 ─────────────────────────│
  │                                 │
  │  [Interceptor Axios detecta 401]│
  │── POST /auth/refresh ──────────►│
  │   { refreshToken: <rt> }        │── Valida refresh hasheado
  │◄─ 200 { accessToken,           │── Invalida refresh anterior
  │         refreshToken }          │── Emite nuevos tokens (rotación)
  │                                 │
  │── GET /cashflow/transactions ──►│ (reintento con nuevo access token)
  │◄─ 200 { data }─────────────────│

LOGOUT
──────────────────────────────────────────────────────────────
  │── POST /auth/logout ───────────►│
  │   { refreshToken }              │── Invalida ese refresh token
  │◄─ 200 ─────────────────────────│
  │                                 │
  │   [Limpiar SecureStore]         │
  │   [Redirigir a (auth)/login]    │
```

---

## 19. UI/UX tokens

### Paleta Light Mode
| Token | Hex | Uso |
|-------|-----|-----|
| `bg` | `#FAF9F6` | Fondo principal (arena cálida) |
| `card` / `modal` / `inputBg` | `#FFFFFF` | Superficies elevadas |
| `border` | `#E5E7EB` | Divisores y bordes |
| `inputBorder` | `#D1D5DB` | Borde de campos de texto |
| `textHeading` | `#103F43` | H1 (30px) / H2 (24px) / H3 (20px) |
| `textPrimary` | `#374151` | Body Regular 16px |
| `textSecondary` | `#4B5563` | Body Small 14px |
| `textMuted` | `#6B7280` | Caption 12px / hints |
| `deepTeal` | `#103F43` | Primary: botones, headers, íconos activos |
| `oceanTeal` | `#1B6B73` | Mid teal: variantes, gradientes |
| `mintSoft` | `#CDECE2` | Accent: bg botón secundario, badges |
| `coral` | `#EE8D78` | Único acento cálido (máx 1 por pantalla) |
| `red` | `#D94452` | Error |
| `yellow` | `#E5A82E` | Aviso |
| `green` | `#16A34A` | Éxito / transacciones positivas |

### Paleta Dark Mode
| Token | Hex / rgba | Uso |
|-------|------------|-----|
| `bg` | `#0D191A` | Fondo dark |
| `card` / `modal` / `inputBg` | `#162A2C` | Container dark |
| `border` | `#1E3538` | Borde sutil |
| `inputBorder` | `#2A4548` | Borde de campos |
| `textPrimary` | `rgba(205,236,226,0.8)` | Texto principal |
| `textSecondary` | `rgba(205,236,226,0.55)` | Texto secundario |
| `textMuted` | `rgba(205,236,226,0.35)` | Caption / hints |
| `deepTeal` | `#103F43` | Botón primario + badge |

### Reglas de uso obligatorias
- Usar tokens vía `useTheme()` en pantallas. No usar `colors.*` directo en JSX de pantallas.
- En tarjetas dark: usar `theme.cardTextPrimary` / `theme.cardTextSecondary` (no `theme.textPrimary`).
- `coral` (#EE8D78): máximo un elemento por pantalla.
- **Prohibido:** acento neón `#b6fc1e` o cualquier hex fuera de la paleta sin actualizar `colors.ts`.
- Espaciado y radios: usar `spacing.*` y `borderRadius.*` de `theme.ts`.
- Tipografía: tokens `fontSize` en `theme.ts`; fallback: SF (iOS) / Roboto (Android).
- Jerarquía: un nivel claro título → cuerpo → secundario. No saturar con muchos pesos de coral/teal.

### Fuente de verdad en código
- `Frontend/rork-checkapp/expo/constants/colors.ts`
- `Frontend/rork-checkapp/expo/constants/theme.ts`

---

## 20. Ver también

| Documento | Contenido |
|-----------|-----------|
| `CLAUDE.md` | Comandos de workspace, overview del proyecto, convenciones de alto nivel |
| `ARCHITECTURE.md` | Mapa navegable del sistema: endpoints, DB layers, flujos, conectividad |
| `ai/context.md` | Estado actual del código, sprint status, conectividad frontend-backend |
| `ai/rules.md` | Reglas operativas detalladas, paleta UI/UX completa, checklist de features |
| `ai/skills.md` | Comandos habituales, dónde implementar cada cosa, checklist completa |
| `ai/decisions.md` | ADRs: decisiones de arquitectura y producto con contexto y consecuencias |
| `ai/changes.md` | Log de cambios relevantes por sesión |
| `DB_v2/schema.sql` | DDL completo de PostgreSQL (fuente de verdad del esquema) |
| `utils/organizacion/docs/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` | Alcance funcional del MVP (fuente de verdad de producto) |
| `Frontend/rork-checkapp/expo/docs/architecture.md` | Diagramas Mermaid: routing, capas, sprints, mock mode |
