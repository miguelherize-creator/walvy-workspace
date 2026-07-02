# Auditoría Arquitectónica — back-walvy

**Fecha**: 2026-06-22  
**Modelo de Auditoría**: walvy-audit (NestJS, SOLID, Clean Code)

---

## 📊 Resumen Ejecutivo

### Stack Técnico
- **Framework**: NestJS 10 + Express
- **BD**: PostgreSQL (TypeORM 0.3.28)
- **Auth**: JWT + Passport
- **Storage**: AWS S3
- **Validación**: class-validator + class-transformer
- **API Docs**: Swagger/OpenAPI

### Estadísticas del Proyecto
- **Módulos**: 9 principales
- **Servicios**: 20
- **Entidades**: 53
- **Controllers**: ~15
- **DTOs**: 30+

### Diagrama de Módulos
```
┌─────────────────────────────────────────────────────┐
│                   App Module                        │
├─────────────────────────────────────────────────────┤
│ ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│ │ Auth Module  │  │ Users Module │  │Catalog Mod. │ │
│ │              │  │              │  │             │ │
│ │ • AuthSvc    │  │ • UsersSvc   │  │ • CatalogSd │ │
│ │ • JwtStrat   │  │              │  │             │ │
│ └──────────────┘  └──────────────┘  └─────────────┘ │
│ ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│ │Cashflow Mod. │  │Profile Mod.  │  │Notifications│ │
│ │              │  │              │  │ Module      │ │
│ │ • FundSvc    │  │ • ProfileSvc │  │ • NotifSvc  │ │
│ │ • CatSvc     │  │              │  │ • AlertRule │ │
│ │ • TransSvc   │  │              │  │   Engine    │ │
│ └──────────────┘  └──────────────┘  └─────────────┘ │
│ ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│ │Imports Mod.  │  │Subscriptions │  │Mail Module  │ │
│ │              │  │              │  │             │ │
│ │ • ImportSvc  │  │ • SubsSvc    │  │ • MailSvc   │ │
│ │ • Parsers    │  │              │  │             │ │
│ └──────────────┘  └──────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## 🏗️ Arquitectura General

### Capa de Configuración Global (app.module.ts)

**Estado**: ✅ Bien estructurado

```typescript
- ConfigModule: .env soporta .env.local y .env
- TypeOrmModule: PostgreSQL async config (DB_URL o componentes separados)
- ThrottlerModule: Rate limiting (100 req/60s)
- ValidationPipe global: whitelist, forbid extra, transform
- AllExceptionsFilter: Captura excepciones globales
```

**Observaciones**:
- 54 entidades registradas en TypeOrmModule
- Sincronización de BD opcional (DB_SYNC env var)
- SSL configurable para prod
- CORS dinámico según NODE_ENV

---

## 📋 Módulos Principales

### 1. **Auth Module** (Crítico)

**Tamaño**: auth.service.ts = 547 líneas  
**Complejidad**: ALTA

**Responsabilidades Observadas**:
- ✅ Registro, login, refresh token
- ✅ Verificación de email (6-digit code)
- ✅ Reset de contraseña
- ✅ Biometric preferences
- ✅ Onboarding state
- ⚠️ Inicialización de datos de usuario (cashflow seed)
- ⚠️ Gamification stats

**Potencial Problema**: God Service
- AuthService toca ~10 tablas diferentes
- Múltiples responsabilidades: Auth + Setup + Gamification

**DTOs**: RegisterDto, LoginDto, UpdateBiometricDto, UpdateOnboardingStepDto

---

### 2. **Users Module**

**Tamaño**: users.service.ts = 248 líneas  
**Complejidad**: MEDIA

**Responsabilidades**:
- ✅ CRUD usuario
- ✅ Avatar upload (S3, sharp reescalado)
- ✅ Password validation (bcrypt, 12 rounds)
- ✅ Profile update
- ✅ toPublic() DTOs

**Calidad**: ✅ Buena
- Métodos enfocados
- Inyección clara
- Manejo consistente de errores
- Constantes para configuración (BCRYPT_ROUNDS, ALLOWED_AVATAR_MIME)

**DTOs**: UpdateProfileDto, UpdateDisplayNameDto

---

### 3. **Cashflow Module**

**Estructura**:
```
cashflow/
├── services/
│   ├── funding-sources.service.ts (80 líneas)
│   ├── categories.service.ts (163 líneas)
│   ├── subcategories.service.ts (136 líneas)
│   ├── transactions.service.ts (171 líneas)
│   └── cashflow-seed.service.ts (155 líneas)
├── controllers/
├── entities/
├── enums/
├── dto/
└── utils/
```

**Complejidad**: MEDIA-ALTA

**Observaciones**:
- ✅ Bien separado por dominio (Funding, Categories, Transactions)
- ✅ Seed service para inicializar datos de usuario
- Patrón CRUD estándar

---

### 4. **Notifications Module**

**Servicios**:
- notification.service.ts (214 líneas)
- alert-rules.engine.ts (259 líneas)

**Observaciones**:
- ✅ Separación: Notificación vs Reglas
- Alert Rules Engine: Lógica de negocio bien encapsulada

---

### 5. **Profile Module**

**Estructura**:
```
profile/
├── services/
├── controllers/
├── dto/
└── entities/
```

**Estado**: ✅ Modular

---

### 6. **Imports Module** (Statement Import)

**Estructura**:
```
imports/
├── services/
├── controllers/
├── parsers/ (Kread, etc.)
├── entities/
└── data/
```

**Observaciones**:
- ✅ Parsers separados por banco/fuente
- Compleja lógica de parsing CSV

---

### 7. **Catalog Module**

**Propósito**: Tablas de dominio estáticas
- Countries, Currencies, DocumentTypes, Statuses, Roles, etc.
- CatalogSeedService: inicialización de defaults

**Estado**: ✅ Limpio

---

## 🔍 Análisis de Código (Patrones Observados)

### ✅ Buenas Prácticas Detectadas

1. **Inyección de Dependencias**: Correctamente usada
   ```typescript
   constructor(
     @InjectRepository(User) private readonly usersRepo: Repository<User>,
     private readonly catalogSeed: CatalogSeedService,
     private readonly s3: S3Service,
   ) {}
   ```

2. **Excepciones NestJS**: Uso correcto
   ```typescript
   throw new BadRequestException('...');
   throw new NotFoundException('...');
   throw new ConflictException('...');
   ```

3. **DTOs con Validación**: class-validator aplicado
   - Validación declarativa en DTOs
   - Transform options habilitados

4. **Constantes**: Configuración centralizada
   ```typescript
   const BCRYPT_ROUNDS = 12;
   const ALLOWED_AVATAR_MIME = ['image/jpeg', 'image/png', 'image/webp'];
   ```

5. **Métodos Públicos**: DTO transformations (toPublic)
   ```typescript
   toPublic(user: User) {
     return {
       id: user.userId,
       firstName: user.firstName,
       // ... mapeo seguro
     };
   }
   ```

---

## ⚠️ Problemas Detectados (Primera Pasada)

### CRÍTICA

1. **God Services** (Auth, Notifications)
   - AuthService: 547 líneas, +8 repos inyectados
   - Toca: Auth + User Setup + Cashflow Seed + Gamification
   - Impacto: Difícil de testear, cambios riesgosos

### MEDIA

2. **Circular Dependencies** (Auth ↔ Users)
   ```typescript
   // auth.module.ts
   imports: [forwardRef(() => UsersModule), ...]
   
   // users.module.ts
   imports: [forwardRef(() => AuthModule), ...]
   ```
   - Viable con `forwardRef()`, pero indica acoplamiento

3. **54 Entidades en AppModule**
   - Todas registradas en TypeOrmModule.forRootAsync
   - Sí hay entidades sin usar actualmente (AI, Gamification parcial)

4. **Módulos Sin Controladores**
   - CatalogModule: exporta seed pero sin API REST
   - Correcto si es solo uso interno

---

## 🎯 Patrones a Revisar por Etapa

### Etapa 1: Arquitectura & Estructura
- [ ] Desglose de God Services (AuthService)
- [ ] Análisis de entidades no utilizadas
- [ ] Validación de límites de módulos
- [ ] Circular dependencies

### Etapa 2: Clean Code & Type Safety
- [ ] Dead code, imports no usados
- [ ] Type safety (any, unknown)
- [ ] Comments cleanup (TODO, FIXME)
- [ ] Duplicación de DTOs/mappers

### Etapa 3: SOLID Principles
- [ ] Single Responsibility
- [ ] Open/Closed en servicios
- [ ] Liskov Substitution en interfaces
- [ ] Interface Segregation en repos

### Etapa 4: Performance & Scalability
- [ ] N+1 queries en cashflow/transactions
- [ ] Sequential awaits → Promise.all
- [ ] Memory efficiency (sharp, streams)
- [ ] Rate limiting y caché

### Etapa 5: Error Handling & Validation
- [ ] Validation pipeline coverage
- [ ] Error messages consistency
- [ ] DTO contracts

---

## 📚 Próximas Acciones

1. **Profundizar en servicios críticos**
   - Full audit de auth.service.ts
   - Identificar responsabilidades que pueden ser extraídas

2. **Analizar entidades**
   - Mapeo de relaciones
   - Campos no utilizados
   - Índices en BD

3. **Revisar controllers**
   - Lógica inapropiada en controllers
   - Validación de input

4. **Mapear flujos de negocio**
   - Registration → Onboarding
   - Transaction import → Classification
   - Alerts engine

---

## 📝 Notas de Configuración

- **Node env**: .env.local + .env
- **DB**: PostgreSQL 15+ (async config)
- **Auth**: JWT (secret + expiry configurable)
- **Storage**: S3 (key format: walvy/avatars/{userId}/{uuid}.webp)
- **Logging**: Winston/Pino? (Revisar en main.ts)

---

## 🔐 Security Checklist (Inicial)

- ✅ Passwords: bcrypt 12 rounds
- ✅ JWT: Bearer tokens
- ✅ Validation: whitelist + forbid extra
- ✅ CORS: dinámico según env
- ⚠️ Rate limiting: 100 req/60s (revisar si es suficiente)
- ❓ SQL injection: TypeORM parámetros (revisar QueryBuilder)
- ❓ XSS: Verificar transformación de datos públicos
- ❓ CSRF: Solo GET/POST simple (revisar body size)

---

**Próxima sesión**: Deep-dive en AuthService + Entidades utilizadas
