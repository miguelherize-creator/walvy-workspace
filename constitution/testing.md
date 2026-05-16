# Estrategia de Testing — Walvy

**Versión:** 1.0  
**Fecha:** 2026-05-14  
**Estado:** Vigente

---

## Estado actual

| Categoría | Cantidad | Estado |
|-----------|----------|--------|
| E2E backend (Supertest) | 75 tests | Activo y mantenido |
| Unit tests frontend (RTL) | 37 tests | Activo y mantenido |
| Unit tests backend (Jest) | 0 tests | Pendiente — deuda técnica |

---

## 1. E2E Backend

### Stack

- **Jest** `^29.5.0` como runner
- **Supertest** `^7.0.0` para hacer requests HTTP contra la app real
- **NestJS Testing** (`@nestjs/testing`) para levantar el módulo de test
- Configuración en `jest-e2e.json` (separada de unit tests)

### Cómo correr

```bash
# Todos los e2e
npm run test:e2e

# Solo una suite
npm run test:e2e -- --testPathPattern="auth"

# Con coverage (no disponible en e2e por defecto)
npm run test:e2e -- --verbose
```

**Requisito:** La variable `DATABASE_URL` debe apuntar a una DB de test. En CI, se levanta un contenedor Postgres efímero.

### Configuración base (jest-e2e.json)

```json
{
  "moduleFileExtensions": ["js", "json", "ts"],
  "rootDir": ".",
  "testEnvironment": "node",
  "testRegex": ".e2e-spec.ts$",
  "transform": { "^.+\\.(t|j)s$": "ts-jest" },
  "testTimeout": 30000,
  "maxWorkers": 1
}
```

`maxWorkers: 1` es obligatorio porque todos los e2e comparten la misma DB y no son seguros para ejecución en paralelo.

### Estructura de suites

```
test/
├── auth.e2e-spec.ts          # registro, OTP, login, refresh, logout
├── users.e2e-spec.ts         # perfil, onboarding, biometría
└── helpers/
    ├── app.helper.ts         # createTestApp()
    ├── mail.helper.ts        # MockMailService
    └── auth.helper.ts        # uniqueEmail(), registerAndVerify(), VALID_RUT
```

### Helpers definidos

#### `createTestApp()`

Levanta el módulo NestJS de test con dos overrides esenciales:

```typescript
export async function createTestApp(): Promise<INestApplication> {
  const moduleFixture = await Test.createTestingModule({
    imports: [AppModule],
  })
    .overrideProvider(MailService)
    .useClass(MockMailService)
    .overrideGuard(ThrottlerGuard)
    .useValue({ canActivate: () => true })
    .compile();

  const app = moduleFixture.createNestApplication();
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    enableImplicitConversion: true,
  }));
  app.useGlobalFilters(new AllExceptionsFilter());
  await app.init();
  return app;
}
```

#### `MockMailService`

Stub que no envía emails reales. Expone el último OTP generado para poder usarlo en tests:

```typescript
export class MockMailService implements MailService {
  public lastOtp: string | null = null;

  async sendOtpEmail(to: string, otp: string): Promise<void> {
    this.lastOtp = otp;  // capturado para usar en el test
  }
}
```

#### `uniqueEmail()`

```typescript
export function uniqueEmail(): string {
  return `t_${Date.now()}_${Math.random().toString(36).slice(2)}@e2e.test`;
}
```

Garantiza que cada test use un email único y no haya colisiones entre ejecuciones.

#### `VALID_RUT`

```typescript
export const VALID_RUT = '12345678-5'; // RUT válido por algoritmo módulo-11
```

Constante compartida. Todos los e2e que necesiten un RUT válido usan esta constante — no generar RUTs ad-hoc.

#### `registerAndVerify()`

Flujo completo de activación de usuario:

```typescript
export async function registerAndVerify(
  app: INestApplication,
  mailService: MockMailService,
): Promise<{ accessToken: string; refreshToken: string; userId: string }> {
  const email = uniqueEmail();
  const password = 'TestPass123!';

  // 1. Registro
  await request(app.getHttpServer())
    .post('/auth/register')
    .send({ email, password, rut: VALID_RUT, name: 'Test User' })
    .expect(201);

  // 2. Verificación OTP
  const otp = mailService.lastOtp!;
  await request(app.getHttpServer())
    .post('/auth/verify-otp')
    .send({ email, otp })
    .expect(200);

  // 3. Login
  const loginRes = await request(app.getHttpServer())
    .post('/auth/login')
    .send({ email, password })
    .expect(200);

  return {
    accessToken: loginRes.body.accessToken,
    refreshToken: loginRes.body.refreshToken,
    userId: loginRes.body.user.id,
  };
}
```

---

## 2. Qué testear en e2e backend

### Happy paths (siempre)

- Registro exitoso → 201 con usuario creado
- Verificación OTP correcta → emailVerified = true
- Login con credenciales correctas → tokens emitidos
- Refresh token → nuevos tokens emitidos
- Logout → token revocado
- Endpoints de perfil con token válido → datos correctos

### Auth guards (siempre, para toda ruta protegida)

```typescript
it('debe rechazar sin token (401)', async () => {
  await request(app.getHttpServer())
    .get('/users/me')
    .expect(401);
});
```

### Validación de inputs (400)

- Email inválido en registro
- RUT con formato incorrecto
- Contraseña menor al mínimo requerido
- Campos requeridos ausentes

### Errores de negocio

- Registro con email duplicado → 409
- Login con contraseña incorrecta → 401
- OTP expirado → 400 o 410
- Refresh con token revocado → 401

### Rotación de tokens

- Usar refresh token por segunda vez → debe fallar (401) y revocar toda la sesión del usuario

---

## 3. Qué NO testear en e2e

- **Implementación interna de services.** No verificar qué métodos internos se llamaron.
- **Detalles de schema de DB.** Los e2e verifican comportamiento HTTP, no estructura de tablas.
- **Lógica de hashing.** No testear que `bcrypt.hash()` funciona (es responsabilidad de la librería).
- **Emails reales enviados.** `MockMailService` es suficiente.
- **Rate limiting.** `ThrottlerGuard` está override en tests.

---

## 4. Tests frontend

### Stack

- **jest-expo**: preset Jest adaptado a Expo/React Native
- **@testing-library/react-native**: queries y assertions de componentes
- `renderWithProviders`: helper que envuelve el componente con `QueryClientProvider`, `AuthProvider` y `ThemeProvider`

### Estructura

```
__tests__/
├── hooks/
│   ├── useLoginForm.test.ts
│   └── useProfile.test.ts
└── ui/
    ├── LoginScreen.test.tsx
    └── HomeScreen.test.tsx

src/test-utils/
├── renderWithProviders.tsx   # wrapper con providers
├── mockSecureStore.ts        # mock de expo-secure-store
└── mockRouter.ts             # mock de expo-router
```

### Helper `renderWithProviders`

```typescript
export function renderWithProviders(ui: React.ReactElement) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ThemeProvider>
          {ui}
        </ThemeProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}
```

### Mocks necesarios

- `expo-router`: mockear `useRouter()` y `useLocalSearchParams()`
- `expo-secure-store`: mockear `getItemAsync()` y `setItemAsync()`
- `expo-local-authentication`: mockear `authenticateAsync()`
- Axios: usar `axios-mock-adapter` o Jest manual mocks para tests de hooks

---

## 5. Reglas de testing

1. **Cada test usa `uniqueEmail()`**. Nunca reutilizar emails entre tests que crean usuarios.
2. **No compartir `accessToken` entre tests que modifican estado.** Cada test que necesita autenticación debe crear su propio usuario con `registerAndVerify()`.
3. **No usar `sleep()` o `setTimeout()` para esperar operaciones async.** Usar `await` con las promesas correctas o `waitFor()` de RTL.
4. **El orden de tests no debe importar.** Cada suite debe funcionar independientemente.
5. **Limpiar estado en `afterEach` / `afterAll`** si el test deja datos en DB que podrían afectar otros tests.
6. **Tests de guards en todo endpoint nuevo.** Todo endpoint protegido por `AuthGuard` debe tener un test que verifique el 401 sin token.

---

## 6. Pendientes (deuda de testing)

| Tarea | Prioridad | Módulo |
|-------|-----------|--------|
| Unit tests para `AuthService` | Alta | `src/auth/` |
| Unit tests para `UsersService` | Alta | `src/users/` |
| E2E para cashflow (M3) | Media | `src/cashflow/` |
| E2E para subscripciones + Flow.cl webhook | Media | `src/subscriptions/` |
| E2E para refresh token replay attack | Alta | `src/auth/` |
| Tests de frontend para `useLoginForm` | Media | `features/auth/` |
| Tests de frontend para `useProfile` | Media | `features/users/` |

---

## 7. TDD — recomendación para nuevos módulos

Para módulos nuevos (M2 en adelante), el flujo recomendado es:

1. **Definir el spec de comportamiento** — qué endpoints tendrá, qué responses, qué errores
2. **Escribir los tests e2e primero** (red → fail)
3. **Implementar el módulo** hasta que los tests pasen (green)
4. **Refactorizar** manteniendo los tests en green

Este flujo garantiza cobertura desde el inicio y documenta el comportamiento esperado en el código de tests.

---

## 8. CI/CD

El pipeline de CI debe ejecutar en orden:

```bash
npm run build          # verifica que TypeScript compile sin errores
npm run test:e2e       # suite e2e completa contra DB efímera
```

Un PR no debe mergearse si algún step falla.
