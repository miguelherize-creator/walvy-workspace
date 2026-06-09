# Convenciones de Código — Walvy

## Naming — Backend (NestJS)

| Elemento | Estilo | Ejemplo |
|----------|--------|---------|
| Archivos | `kebab-case` | `auth.service.ts`, `update-profile.dto.ts` |
| Clases | `PascalCase` | `AuthService`, `RegisterDto` |
| Métodos/variables | `camelCase` | `findById()`, `accessToken` |
| Constantes | `UPPER_SNAKE_CASE` | `EMAIL_VERIFICATION_EXPIRES_MINUTES` |
| Módulos | `PascalCase + Module` | `AuthModule` |
| DTOs | `PascalCase + Dto` | `RegisterDto`, `UpdateProfileDto` |
| Services | `PascalCase + Service` | `AuthService` |
| Entities | `PascalCase` | `User`, `RefreshToken` |
| Columnas DB | `snake_case` via `@Column({ name })` | `email_verified`, `created_at` |

## Naming — Frontend (React Native)

| Elemento | Estilo | Ejemplo |
|----------|--------|---------|
| Pantallas | `PascalCase + Screen.tsx` | `LoginScreen.tsx` |
| Hooks | `use + PascalCase` | `useLoginForm.ts`, `useProfile.ts` |
| Repositories | `PascalCase + Repository.ts` | `AuthRepository.ts` |
| Providers | `PascalCase + Provider` | `AuthProvider.tsx` |
| Constantes | `UPPER_SNAKE_CASE` | `ACCESS_TOKEN_KEY` |
| Tipos | `kebab-case.types.ts` | `auth.types.ts` |
| Utils | `kebab-case.utils.ts` | `rut.utils.ts` |

## Patrones de DTOs (backend)

Todo DTO debe:
- `@ApiProperty()` en cada propiedad (Swagger)
- Decoradores `class-validator` en cada propiedad
- Tipos exactos (no `any`)
- `@IsOptional()` solo en propiedades genuinamente opcionales

```typescript
export class RegisterDto {
  @ApiProperty({ example: 'juan@walvy.cl' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: '12345678-5' })
  @IsString()
  @Matches(/^\d{7,8}-[\dkK]$/, { message: 'RUT inválido' })
  rut: string;
}
```

`ValidationPipe` global: `whitelist: true` + `forbidNonWhitelisted: true`.

## Safe Area — insets en pantallas standalone (frontend)

Toda pantalla que vive **fuera de `(tabs)`** (splash, login, onboarding, subscription-success, etc.)
debe respetar los insets del sistema operativo manualmente. El `SafeAreaView` del Tab Navigator
**no aplica** en estas pantallas.

### Regla

```tsx
import { useSafeAreaInsets } from "react-native-safe-area-context";

const insets = useSafeAreaInsets();

// Aplicar en el contenedor inferior
<View style={[styles.body, { paddingBottom: insets.bottom + 36 }]}>
```

### Valores típicos de `insets.bottom`

| Dispositivo | Valor |
|---|---|
| Android con botones visibles | ~48 dp |
| Android con gestos (barra delgada) | ~24 dp |
| Android sin barra | 0 |
| iPhone con home indicator (notch/Dynamic Island) | ~34 dp |
| iPhone con botón home | 0 |

### Patrón preferido para pantallas con header + body + footer

```tsx
{/* Header — altura fija 84 con paddingTop: 36 cubre status bar */}
<View style={styles.header}>...</View>

{/* Body — top fijo, bottom dinámico con inset */}
<View style={[styles.body, { paddingBottom: insets.bottom + 36 }]}>
  ...
  {/* Footer empujado al fondo con marginTop: "auto" */}
  <Text style={styles.footer}>...</Text>
</View>
```

O con `SafeAreaView` cuando el contenido es un scroll o tab layout:

```tsx
<SafeAreaView edges={["bottom"]} style={{ flex: 1 }}>
  ...
</SafeAreaView>
```

> **Regla de oro**: si el contenido importante está en el fondo de la pantalla
> y la pantalla no está dentro de `(tabs)`, usar `useSafeAreaInsets()` o
> `SafeAreaView edges={["bottom"]}`. De lo contrario el nav bar de Android
> tapa el contenido.

## Patrones de hooks (frontend)

- No contienen JSX
- Retornan objeto plano (no arrays)
- TanStack Query para toda interacción con servidor
- Zod para validar inputs antes de llamar al repositorio

```typescript
export function useLoginForm() {
  const loginMutation = useMutation({
    mutationFn: (data: LoginInput) => AuthRepository.login(data),
    onSuccess: (tokens) => { /* guardar tokens, navegar */ },
  });
  return { isLoading: loginMutation.isPending, handleSubmit };
}
```

## Patrones de services (backend)

- Toda la lógica de negocio vive en el service
- Inyección de dependencias via constructor
- Nunca `throw new Error('...')` — usar excepciones NestJS:
  `NotFoundException`, `ConflictException`, `UnauthorizedException`, `BadRequestException`

## Patrones de entities (TypeORM)

- Columnas DB en `snake_case` via `@Column({ name: '...' })`
- `@Exclude()` en campos sensibles (`passwordHash`)
- Transformer `decimalToNumber` en columnas `numeric(12,2)`
- Soft delete: `@DeleteDateColumn() deletedAt: Date`

## Imports

**Backend:** relativos dentro del mismo módulo.

**Frontend:**
- `@/` (alias) → obligatorio para imports cross-feature
- `./` o `../` → solo dentro de la misma feature
- PROHIBIDO: `import { X } from '../../otra-feature/...'`

## Seeds

- Implementan `OnModuleInit`
- Usar `upsert` con `conflictPaths` (idempotentes)
- Solo catálogos de sistema, nunca datos de usuario

## Seguridad — reglas críticas

1. Nunca loguear tokens (`accessToken`, `refreshToken`, `passwordHash`)
2. Nunca exponer `passwordHash` en respuestas — usar `toPublic()` o `@Exclude()`
3. Nunca DELETE físico de `app_user`, `financial_movement`, `debt`
4. Nunca hardcodear secrets — siempre variables de entorno
5. Nunca confiar en datos del cliente para determinar roles
6. Nunca AsyncStorage para tokens — usar `expo-secure-store`
7. OTPs y tokens opacos almacenados hasheados en DB
