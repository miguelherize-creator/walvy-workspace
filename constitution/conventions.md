# Convenciones de Código — Walvy

**Versión:** 1.0  
**Fecha:** 2026-05-14  
**Estado:** Vigente

---

## 1. Naming conventions

### 1.1 Backend (NestJS / TypeScript)

| Elemento | Estilo | Ejemplo |
|----------|--------|---------|
| Archivos | `kebab-case` | `auth.service.ts`, `update-profile.dto.ts`, `jwt-auth.guard.ts` |
| Clases | `PascalCase` | `AuthService`, `RegisterDto`, `User`, `RefreshToken` |
| Métodos y variables | `camelCase` | `findById()`, `accessToken`, `isEmailVerified` |
| Constantes estáticas | `UPPER_SNAKE_CASE` | `EMAIL_VERIFICATION_EXPIRES_MINUTES`, `VALID_RUT` |
| Módulos NestJS | `PascalCase + Module` | `AuthModule`, `UsersModule`, `SeedModule` |
| DTOs | `PascalCase + Dto` | `RegisterDto`, `LoginDto`, `UpdateProfileDto` |
| Services | `PascalCase + Service` | `AuthService`, `UsersService`, `MailService` |
| Guards | `PascalCase + Guard` | `JwtAuthGuard`, `ThrottlerGuard` |
| Entidades TypeORM | `PascalCase` | `User`, `RefreshToken`, `FinancialMovement` |
| Columnas DB | `snake_case` (via `@Column({ name: '...' })`) | `email_verified`, `created_at`, `deleted_at` |

**Sufijos obligatorios:**
- Módulos: terminan en `Module`
- Services: terminan en `Service`
- DTOs: terminan en `Dto`
- Guards: terminan en `Guard`
- Strategies (Passport): terminan en `Strategy`

### 1.2 Frontend (React Native / Expo)

| Elemento | Estilo | Ejemplo |
|----------|--------|---------|
| Archivos de pantalla | `PascalCase + Screen.tsx` | `LoginScreen.tsx`, `HomeScreen.tsx` |
| Hooks | `camelCase + use` (prefijo) | `useLoginForm.ts`, `useProfile.ts`, `useAuthStore.ts` |
| Repositories (data layer) | `camelCase`, verbo descriptivo | `getMe.ts`, `updateProfile.ts`, `login.ts` |
| Providers | `PascalCase + Provider` | `AuthProvider.tsx`, `ThemeProvider.tsx` |
| Constantes | `UPPER_SNAKE_CASE` | `ACCESS_TOKEN_KEY`, `REFRESH_TOKEN_KEY`, `MENU_ITEMS` |
| Archivos de tipos | `kebab-case.types.ts` | `auth.types.ts`, `user.types.ts` |
| Archivos de utils | `kebab-case.utils.ts` | `rut.utils.ts`, `format.utils.ts` |
| Barrel exports | `index.ts` | `features/auth/index.ts` |

---

## 2. Estructura de carpetas

### 2.1 Módulo backend (NestJS)

```
src/<modulo>/
├── <modulo>.module.ts        # declaración del módulo
├── <modulo>.controller.ts    # endpoints REST
├── <modulo>.service.ts       # lógica de negocio
├── dto/
│   ├── create-<entidad>.dto.ts
│   ├── update-<entidad>.dto.ts
│   └── index.ts              # barrel export
├── entities/
│   ├── <entidad>.entity.ts
│   └── index.ts
├── guards/                   # solo si el módulo define guards propios
├── strategies/               # solo para módulos de auth (Passport)
└── <modulo>.service.spec.ts  # unit tests (pendiente)
```

### 2.2 Feature frontend

```
features/<nombre>/
├── index.ts                         # contrato público — único punto de entrada externo
├── data/
│   ├── <nombre>Repository.ts        # wrappea api/<nombre>Service
│   └── index.ts
├── hooks/
│   ├── use<Nombre>.ts               # estado + handlers, sin JSX
│   └── index.ts
└── ui/
    ├── <Nombre>Screen.tsx           # JSX puro, delega al hook
    └── components/                  # componentes visuales locales (si aplica)
        └── <Nombre>Card.tsx
```

### 2.3 Infraestructura compartida (frontend)

```
src/
├── api/
│   ├── axiosInstance.ts             # instancia Axios con interceptores
│   ├── <dominio>Service.ts          # llamadas HTTP por dominio
│   └── index.ts
├── store/
│   ├── AuthProvider.tsx
│   ├── ThemeProvider.tsx
│   └── index.ts
└── common/
    ├── validators/                  # validadores custom (RUT, etc.)
    ├── transformers/                # transformers TypeORM
    └── filters/                     # AllExceptionsFilter
```

---

## 3. Estilos de código TypeScript

- **Strict mode obligatorio** (`"strict": true` en `tsconfig.json`).
- **Prohibido `any` explícito o implícito.** Usar tipos concretos, genéricos, o `unknown` con type guards.
- **No usar `as any`** salvo en tests (y documentando el motivo).
- **Interfaces para contratos públicos** (lo que se exporta); types para uniones/aliases locales.
- **No usar `namespace`.** Usar módulos ES.
- **Enums solo para valores que nunca cambiarán** (e.g., roles fijos de sistema). Estados mutables usan `status_domain`.
- **Decoradores** en el orden: primero los de NestJS/TypeORM, luego los de validación.

---

## 4. Patrones de DTOs (backend)

Todo DTO debe:
- Decorar cada propiedad con `@ApiProperty()` (Swagger).
- Decorar con validadores de `class-validator`.
- Usar tipos exactos (no `any`).
- Incluir `@IsOptional()` solo en propiedades genuinamente opcionales.

```typescript
// Ejemplo correcto
export class RegisterDto {
  @ApiProperty({ example: 'juan@ejemplo.cl' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: '12345678-5' })
  @IsString()
  @Matches(/^\d{7,8}-[\dkK]$/, { message: 'RUT inválido' })
  rut: string;

  @ApiProperty({ example: 'MiClave123!' })
  @IsString()
  @MinLength(8)
  password: string;
}
```

**Regla:** `ValidationPipe` global está configurado con `whitelist: true` y `forbidNonWhitelisted: true`. Cualquier propiedad no decorada en el DTO es rechazada automáticamente.

---

## 5. Patrones de hooks (frontend)

Los hooks:
- **No contienen JSX.** Solo estado, handlers y efectos.
- **Retornan un objeto plano** con estado y callbacks (no arrays como `useState`).
- **Usan TanStack Query** para toda interacción con el servidor.
- **Validan con Zod** antes de llamar al repositorio.

```typescript
// Ejemplo correcto
export function useLoginForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const loginMutation = useMutation({
    mutationFn: (data: LoginInput) => loginRepository.login(data),
    onSuccess: (tokens) => { /* guardar tokens, navegar */ },
    onError: (error) => { /* manejar error */ },
  });

  const handleSubmit = () => {
    const parsed = LoginSchema.safeParse({ email, password });
    if (!parsed.success) return; // mostrar error de validación
    loginMutation.mutate(parsed.data);
  };

  return {
    email, setEmail,
    password, setPassword,
    isLoading: loginMutation.isPending,
    error: loginMutation.error,
    handleSubmit,
  };
}
```

---

## 6. Patrones de services (backend)

- **Toda la lógica de negocio vive en el service.** El controller solo llama al service.
- **Inyección de dependencias** mediante constructor con `@InjectRepository()` o `@Inject()`.
- **No lanzar `Error` genérico.** Usar excepciones de NestJS (`NotFoundException`, `ConflictException`, `UnauthorizedException`, `BadRequestException`, `ForbiddenException`).
- **Método `toPublic()`** en entidades con datos sensibles — proyecta solo campos seguros para la respuesta.

```typescript
// Ejemplo correcto
@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async findByEmail(email: string): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { email } });
    if (!user) throw new NotFoundException('Usuario no encontrado');
    return user;
  }
}
```

---

## 7. Patrones de entities (TypeORM)

- **Columnas DB en `snake_case`** mediante `@Column({ name: 'nombre_columna' })`.
- **Propiedades TypeScript en `camelCase`**.
- **Transformer `decimalToNumber`** para columnas `numeric(12,2)` (evita que TypeORM retorne string).
- **`@Exclude()` en campos sensibles** (`passwordHash`, `otpCode`) para que `ClassSerializerInterceptor` los omita.
- **Soft delete** con `@DeleteDateColumn() deletedAt: Date`.

```typescript
// Ejemplo correcto
@Entity('app_user')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'email_verified', default: false })
  emailVerified: boolean;

  @Column({ name: 'password_hash' })
  @Exclude()
  passwordHash: string;

  @Column({ name: 'monthly_income', type: 'numeric', precision: 12, scale: 2,
            transformer: decimalToNumberTransformer })
  monthlyIncome: number;

  @DeleteDateColumn({ name: 'deleted_at' })
  deletedAt: Date;

  toPublic() {
    const { passwordHash, ...rest } = this;
    return rest;
  }
}
```

---

## 8. Manejo de errores

### Backend

- `AllExceptionsFilter` registrado globalmente captura toda excepción no manejada.
- El filtro normaliza la respuesta al formato estándar: `{ statusCode, message, path, timestamp }`.
- En services, lanzar siempre excepciones HTTP de NestJS (nunca `throw new Error('...')`).
- Los errores de validación de `ValidationPipe` ya generan respuesta 400 automáticamente.

```typescript
// Correcto
throw new ConflictException('El email ya está registrado');

// Incorrecto
throw new Error('email duplicado');
```

### Frontend

- Los errores de mutations de TanStack Query se manejan en el hook (`onError`).
- Los errores de red (401 con token expirado) se manejan en el interceptor de Axios.
- La capa `ui` solo muestra el mensaje de error que le pasa el hook; no hace `try/catch`.

---

## 9. Validaciones

- **Backend:** todas las validaciones de entrada se hacen en DTOs con `class-validator`. Validadores custom (e.g., RUT chileno modulo-11) se ubican en `src/common/validators/`.
- **Frontend:** validaciones de formulario con `Zod`. Los schemas se definen junto al hook que los usa.
- **RUT chileno:** formato esperado `'12345678-5'`, validación por algoritmo módulo-11.

---

## 10. Imports

### Backend

- Imports relativos dentro del mismo módulo: `./auth.service`, `../entities/user.entity`.
- No usar paths absolutos en backend (no hay alias configurado en tsconfig de NestJS por defecto).
- Agrupar imports: primero librerías externas, luego módulos internos, luego archivos locales.

### Frontend

- **Alias `@/`** apunta a `src/`. Obligatorio para imports cross-feature.
- Imports relativos (`./`, `../`) solo dentro de la misma feature.
- Prohibido: `import { X } from '../../otra-feature/...'`
- Permitido: `import { X } from '@/store/AuthProvider'`
- Agrupar imports: React/React Native, librerías externas, alias `@/`, relativos locales.

---

## 11. Seeds

- Los seeds implementan `OnModuleInit` de NestJS.
- Usan `upsert` (INSERT ... ON CONFLICT DO UPDATE) en lugar de `save()` o `insert()` simple, para ser idempotentes.
- Se ejecutan en el startup del servidor en todos los entornos.
- No insertan datos de usuario; solo catálogos de sistema (roles, status_domain, health_levels, plan, plan_price).

```typescript
// Ejemplo correcto
async onModuleInit() {
  await this.roleRepository.upsert(
    [{ id: 'user', name: 'Usuario' }, { id: 'admin', name: 'Administrador' }],
    { conflictPaths: ['id'] },
  );
}
```

---

## 12. Barrel exports

- Cada feature frontend tiene `index.ts` en su raíz que exporta **únicamente lo necesario** para los consumidores externos.
- Cada subcarpeta (`data/`, `hooks/`, `ui/`) puede tener su propio `index.ts` interno.
- Los barrel exports de features deben ser mínimos: normalmente solo exportan la Screen y los tipos públicos.

```typescript
// features/auth/index.ts — ejemplo correcto
export { LoginScreen } from './ui/LoginScreen';
export { RegisterScreen } from './ui/RegisterScreen';
export type { AuthUser } from './data/auth.types';
```

---

## 13. Comentarios

- **Solo cuando el WHY no es obvio** a partir del código.
- No comentar lo que el código ya dice claramente.
- Para decisiones no evidentes, referenciar el ADR correspondiente en `decisions/`.
- Usar `// TODO:` para deuda técnica, siempre con ticket o contexto.
- Usar `// FIXME:` para bugs conocidos que no se arreglan en el momento.

```typescript
// Bien: explica el porqué
// sha256 en lugar de bcrypt porque se usa como índice de lookup (bcrypt no es determinista)
const hash = hashOpaqueToken(token);

// Mal: redundante con el código
// obtiene el usuario por email
const user = await this.findByEmail(email);
```

---

## 14. Reglas de seguridad en código

1. **Nunca loguear tokens.** Prohibido `console.log(accessToken)`, `Logger.log(refreshToken)`, o cualquier variante.
2. **Nunca exponer `passwordHash`** en respuestas HTTP. Usar `toPublic()` o `@Exclude()`.
3. **Nunca DELETE físico de `app_user`, `financial_movement`, `debt`.** Siempre soft delete.
4. **Nunca hardcodear secrets.** Toda credencial (JWT secret, DB password, Flow API key) debe venir de variables de entorno.
5. **Nunca confiar en datos del cliente** para determinar roles o permisos. Los guards leen el payload del JWT firmado.
6. **Nunca almacenar tokens en AsyncStorage** (no es seguro en móvil). Usar `expo-secure-store`.
7. **OTPs y tokens opacos** se almacenan hasheados en DB, nunca en texto plano.
