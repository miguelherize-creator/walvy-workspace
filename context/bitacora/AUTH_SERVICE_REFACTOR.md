# Refactoring: AuthService God Service → Servicios Especializados

**Status**: Análisis Detallado  
**Líneas Actuales**: 547  
**Complejidad Ciclomática**: 45+ (MUY ALTA)

---

## 🔴 Problemas Actuales

### 1. **Múltiples Responsabilidades (SRP Violation)**

```typescript
export class AuthService {
  // 1. AUTENTICACIÓN (core)
  async register(dto: RegisterDto) { ... }
  async login(dto: LoginDto) { ... }
  async logout(token: string) { ... }
  async logoutAll(userId: string) { ... }
  
  // 2. GESTIÓN DE TOKENS (core)
  async refresh(token: string) { ... }
  private async issueTokens(user: User) { ... }
  private async revokeAllRefreshForUser(userId: string) { ... }
  
  // 3. PASSWORD MANAGEMENT
  async forgotPassword(email: string) { ... }
  async resetPassword(email: string, code: string, ...) { ... }
  async changePassword(userId: string, ...) { ... }
  
  // 4. EMAIL VERIFICATION
  async requestEmailVerification(userId: string, ...) { ... }
  async confirmEmailVerification(userId: string, ...) { ... }
  private async buildOtpAndPersist(...) { ... }
  
  // 5. ONBOARDING STATE (business logic)
  async getOnboarding(userId: string) { ... }
  async updateOnboardingStep(userId: string, dto) { ... }
  private toOnboardingPublic(state) { ... }
  
  // 6. BIOMETRIC PREFERENCES (business logic)
  async updateBiometric(userId: string, dto) { ... }
  
  // 7. USER INITIALIZATION (side-effects)
  → Dentro de register():
    - cashflowSeed.ensureFundingSourcesForUser()
    - onboardingRepo.save()
    - biometricRepo.save()
    - gamificationStatsRepo.save()
}
```

### 2. **Excesivas Inyecciones de Dependencias**

```typescript
constructor(
  private readonly usersService,          // ✅ legítimo
  private readonly cashflowSeed,          // ⚠️ side-effect (debería en otro svc)
  private readonly catalogSeed,           // ✅ legítimo
  private readonly jwtService,            // ✅ legítimo
  private readonly config,                // ✅ legítimo
  private readonly mailService,           // ✅ legítimo
  @InjectRepository(RefreshToken),        // ✅ legítimo
  @InjectRepository(PasswordResetToken),  // ⚠️ debería en PasswordManagementService
  @InjectRepository(EmailVerificationToken), // ⚠️ debería en EmailVerificationService
  @InjectRepository(BiometricPreferences),  // ⚠️ debería en UserOnboardingService
  @InjectRepository(OnboardingState),      // ⚠️ debería en UserOnboardingService
  @InjectRepository(UserGamificationStats), // ⚠️ side-effect, debería en UserInitializationService
) {}
```

**Problema**: 9 inyecciones → 6 servicios/repos. Demasiado acoplamiento.

### 3. **Complejidad Ciclomática Alta**

Métodos con múltiples puntos de decisión:
- `register()`: 1 if, 1 await, 4 writes (DB)
- `login()`: 3 if, 4 throws (flujo condicional complejo)
- `confirmEmailVerification()`: 5 if/else cascadas
- `resetPassword()`: 4 if/else, intentos counter

### 4. **Side-Effects Acoplados en register()**

```typescript
async register(dto: RegisterDto) {
  // 1. Validación y creación de usuario
  const user = await this.usersService.create({ ... });
  
  // 2. LADO: Inicializar datos de usuario
  await this.cashflowSeed.ensureFundingSourcesForUser(user.userId);
  
  // 3. LADO: Crear estado de onboarding
  await this.onboardingRepo.save(this.onboardingRepo.create({ ... }));
  
  // 4. LADO: Crear preferencias biométricas
  await this.biometricRepo.save(this.biometricRepo.create({ ... }));
  
  // 5. LADO: Inicializar gamification stats
  await this.gamificationStatsRepo.save(this.gamificationStatsRepo.create({ ... }));
  
  // 6. LADO: Enviar email (fire-and-forget)
  void this.mailService.sendEmailVerificationCode(...).catch(...);
  
  return { user, tokens, nextStep };
}
```

**Problemas**:
- Si algo falla en step 4, user ya existe pero estado incompleto
- Difícil de testear: necesita mockear 5 servicios
- Cambiar onboarding flow → cambiar AuthService
- Sin transacción BD → inconsistencia posible

---

## ✅ Propuesta de Refactoring

### Arquitectura Objetivo

```
AuthModule
├── AuthService (core)
│   ├── register()
│   ├── login()
│   ├── logout()
│   ├── refresh()
│   └── changePassword()
│
├── EmailVerificationService
│   ├── requestEmailVerification()
│   ├── confirmEmailVerification()
│   └── buildOtpAndPersist() (private)
│
├── PasswordManagementService
│   ├── forgotPassword()
│   └── resetPassword()
│
├── UserOnboardingService
│   ├── getOnboarding()
│   ├── updateOnboardingStep()
│   ├── updateBiometric()
│   └── toOnboardingPublic() (private)
│
└── UserInitializationService
    └── initializeNewUser() (publica)
        ├── Crea OnboardingState
        ├── Crea BiometricPreferences
        ├── Crea UserGamificationStats
        ├── Llama a CashflowSeedService
        └── Retorna initializedUser DTO
```

---

## 🔧 Refactoring Paso a Paso

### PASO 1: Extraer `UserInitializationService`

```typescript
// src/auth/services/user-initialization.service.ts

import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OnboardingState } from '../entities/onboarding-state.entity';
import { BiometricPreferences } from '../entities/biometric-preferences.entity';
import { UserGamificationStats } from '../../gamification/entities/user-gamification-stats.entity';
import { CashflowSeedService } from '../../cashflow/services/cashflow-seed.service';
import { User } from '../../users/entities/user.entity';

@Injectable()
export class UserInitializationService {
  constructor(
    private readonly cashflowSeed: CashflowSeedService,
    @InjectRepository(OnboardingState)
    private readonly onboardingRepo: Repository<OnboardingState>,
    @InjectRepository(BiometricPreferences)
    private readonly biometricRepo: Repository<BiometricPreferences>,
    @InjectRepository(UserGamificationStats)
    private readonly gamificationStatsRepo: Repository<UserGamificationStats>,
  ) {}

  async initializeNewUser(userId: string): Promise<void> {
    await Promise.all([
      this.cashflowSeed.ensureFundingSourcesForUser(userId),
      this.createOnboardingState(userId),
      this.createBiometricPreferences(userId),
      this.createGamificationStats(userId),
    ]);
  }

  private async createOnboardingState(userId: string): Promise<void> {
    await this.onboardingRepo.save(
      this.onboardingRepo.create({
        userId,
        onboardingStatus: 'not_started',
        currentStep: 'email_verification',
        financialProfileCompleted: false,
        goalsSet: false,
        importAttempted: false,
        biometricPrompted: false,
        minDocThresholdMet: false,
        completedAt: null,
        resumeSurface: null,
        resumeContext: null,
      }),
    );
  }

  private async createBiometricPreferences(userId: string): Promise<void> {
    await this.biometricRepo.save(
      this.biometricRepo.create({
        userId,
        enabled: false,
        method: null,
        deviceId: null,
      }),
    );
  }

  private async createGamificationStats(userId: string): Promise<void> {
    await this.gamificationStatsRepo.save(
      this.gamificationStatsRepo.create({
        userId,
        totalPoints: 0,
        level: 1,
        lastComputedAt: new Date(),
      }),
    );
  }
}
```

**Ventajas**:
- Single Responsibility: solo inicialización
- Promise.all: inicializa en paralelo
- Fácil de testear
- Reutilizable si hay otros flujos de signup

---

### PASO 2: Extraer `EmailVerificationService`

```typescript
// src/auth/services/email-verification.service.ts

import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmailVerificationToken } from '../entities/email-verification-token.entity';
import { MailService } from '../../mail/mail.service';
import { UsersService } from '../../users/users.service';
import { ConfigService } from '@nestjs/config';
import {
  generateSixDigitCode,
  hashOpaqueToken,
} from '../../common/utils/crypto.utils';

@Injectable()
export class EmailVerificationService {
  private readonly MAX_ATTEMPTS = 5;

  constructor(
    @InjectRepository(EmailVerificationToken)
    private readonly emailVerifRepo: Repository<EmailVerificationToken>,
    private readonly usersService: UsersService,
    private readonly mailService: MailService,
    private readonly config: ConfigService,
  ) {}

  async requestEmailVerification(userId: string, email: string) {
    const payload = await this.generateAndPersistOtp(userId, email);
    await this.mailService.sendEmailVerificationCode(
      payload.normalizedEmail,
      payload.code,
    );
    return { message: `Código de verificación enviado a ${payload.normalizedEmail}` };
  }

  async confirmEmailVerification(userId: string, email: string, code: string) {
    const normalizedEmail = email.trim().toLowerCase();

    const row = await this.findPendingToken(userId);
    if (!row) {
      throw new BadRequestException('No hay un código pendiente. Solicita uno nuevo.');
    }

    this.validateTokenNotExpired(row);
    this.validateAttemptsRemaining(row);

    const tokenHash = hashOpaqueToken(code);
    if (row.tokenHash !== tokenHash) {
      return this.handleIncorrectCode(row);
    }

    if (row.email !== normalizedEmail) {
      throw new BadRequestException('El correo no coincide con el código enviado.');
    }

    row.usedAt = new Date();
    await this.emailVerifRepo.save(row);

    const updatedUser = await this.usersService.setEmailVerified(userId, normalizedEmail);
    return {
      message: 'Correo verificado correctamente',
      user: this.usersService.toPublic(updatedUser),
    };
  }

  private async generateAndPersistOtp(
    userId: string,
    email: string,
  ): Promise<{ normalizedEmail: string; code: string }> {
    const normalizedEmail = email.trim().toLowerCase();

    const existing = await this.usersService.findByEmail(normalizedEmail);
    if (existing && existing.userId !== userId) {
      throw new ConflictException('Este correo ya está registrado por otra cuenta');
    }

    // Invalidar tokens anteriores
    await this.emailVerifRepo
      .createQueryBuilder()
      .update(EmailVerificationToken)
      .set({ usedAt: new Date() })
      .where('user_id = :userId', { userId })
      .andWhere('used_at IS NULL')
      .execute();

    const code = generateSixDigitCode();
    const tokenHash = hashOpaqueToken(code);
    const minutes = this.config.get<number>('EMAIL_VERIFICATION_EXPIRES_MINUTES', 15);
    const expiresAt = new Date(Date.now() + minutes * 60 * 1000);

    await this.emailVerifRepo.save(
      this.emailVerifRepo.create({
        userId,
        email: normalizedEmail,
        tokenHash,
        expiresAt,
        usedAt: null,
        attempts: 0,
      }),
    );

    const user = await this.usersService.findById(userId);
    if (user && user.email !== normalizedEmail) {
      await this.usersService.setPendingEmail(userId, normalizedEmail);
    }

    return { normalizedEmail, code };
  }

  private async findPendingToken(userId: string) {
    const rows = await this.emailVerifRepo.find({
      where: { userId, usedAt: undefined as any },
      order: { createdAt: 'DESC' },
    });
    return rows.find((r) => r.usedAt === null) || null;
  }

  private validateTokenNotExpired(row: EmailVerificationToken) {
    if (row.expiresAt.getTime() < Date.now()) {
      throw new BadRequestException('El código expiró. Solicita uno nuevo.');
    }
  }

  private validateAttemptsRemaining(row: EmailVerificationToken) {
    if (row.attempts >= this.MAX_ATTEMPTS) {
      throw new BadRequestException('Demasiados intentos. Solicita un nuevo código.');
    }
  }

  private async handleIncorrectCode(row: EmailVerificationToken) {
    row.attempts += 1;
    if (row.attempts >= this.MAX_ATTEMPTS) {
      row.usedAt = new Date();
    }
    await this.emailVerifRepo.save(row);

    const remaining = this.MAX_ATTEMPTS - row.attempts;
    if (remaining > 0) {
      throw new BadRequestException(
        `Código incorrecto. ${remaining} intentos restantes.`,
      );
    }
    throw new BadRequestException('Demasiados intentos. Solicita un nuevo código.');
  }
}
```

**Ventajas**:
- Encapsula toda lógica de verificación de email
- Métodos privados para validaciones
- Fácil de testear
- Si hay cambios en OTP → modificar solo este servicio

---

### PASO 3: Extraer `PasswordManagementService`

```typescript
// src/auth/services/password-management.service.ts

import {
  BadRequestException,
  Injectable,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PasswordResetToken } from '../entities/password-reset-token.entity';
import { UsersService } from '../../users/users.service';
import { MailService } from '../../mail/mail.service';
import { ConfigService } from '@nestjs/config';
import {
  generateSixDigitCode,
  hashOpaqueToken,
} from '../../common/utils/crypto.utils';

@Injectable()
export class PasswordManagementService {
  private readonly MAX_ATTEMPTS = 5;

  constructor(
    @InjectRepository(PasswordResetToken)
    private readonly resetRepo: Repository<PasswordResetToken>,
    private readonly usersService: UsersService,
    private readonly mailService: MailService,
    private readonly config: ConfigService,
  ) {}

  async forgotPassword(email: string) {
    const generic = {
      message:
        'Si el correo existe en nuestro sistema, recibirás un código para restablecer tu contraseña.',
    };

    const user = await this.usersService.findByEmail(email);
    if (!user) return generic;

    await this.resetRepo.delete({ userId: user.userId });

    const code = generateSixDigitCode();
    const tokenHash = hashOpaqueToken(code);
    const minutes = this.config.get<number>('PASSWORD_RESET_EXPIRES_MINUTES', 15);
    const expiresAt = new Date(Date.now() + minutes * 60 * 1000);

    await this.resetRepo.save(
      this.resetRepo.create({
        userId: user.userId,
        tokenHash,
        expiresAt,
        usedAt: null,
        attempts: 0,
      }),
    );

    await this.mailService.sendPasswordResetOtp(user.email!, code);
    return generic;
  }

  async resetPassword(email: string, code: string, newPassword: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new BadRequestException('Código inválido o expirado');
    }

    const row = await this.resetRepo.findOne({
      where: { userId: user.userId },
      order: { createdAt: 'DESC' },
    });

    if (!row || row.usedAt || row.expiresAt.getTime() < Date.now()) {
      throw new BadRequestException('Código inválido o expirado');
    }

    if (row.attempts >= this.MAX_ATTEMPTS) {
      throw new BadRequestException('Demasiados intentos fallidos. Solicita un nuevo código.');
    }

    const hash = hashOpaqueToken(code);
    if (hash !== row.tokenHash) {
      row.attempts += 1;
      await this.resetRepo.save(row);
      const remaining = this.MAX_ATTEMPTS - row.attempts;
      if (remaining <= 0) {
        throw new BadRequestException('Demasiados intentos fallidos. Solicita un nuevo código.');
      }
      throw new BadRequestException(`Código incorrecto. Te quedan ${remaining} intentos.`);
    }

    await this.usersService.updatePassword(row.userId, newPassword);
    row.usedAt = new Date();
    await this.resetRepo.save(row);

    return { message: 'Contraseña actualizada correctamente' };
  }
}
```

**Nota**: `changePassword()` permanece en AuthService (es operación autenticada, parte del core)

---

### PASO 4: Extraer `UserOnboardingService`

```typescript
// src/auth/services/user-onboarding.service.ts

import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OnboardingState } from '../entities/onboarding-state.entity';
import { BiometricPreferences } from '../entities/biometric-preferences.entity';
import { UpdateOnboardingStepDto } from '../dto/update-onboarding-step.dto';
import { UpdateBiometricDto } from '../dto/update-biometric.dto';

@Injectable()
export class UserOnboardingService {
  constructor(
    @InjectRepository(OnboardingState)
    private readonly onboardingRepo: Repository<OnboardingState>,
    @InjectRepository(BiometricPreferences)
    private readonly biometricRepo: Repository<BiometricPreferences>,
  ) {}

  async getOnboarding(userId: string) {
    const state = await this.onboardingRepo.findOne({ where: { userId } });
    if (!state) {
      throw new NotFoundException('Estado de onboarding no encontrado');
    }
    return this.toOnboardingPublic(state);
  }

  async updateOnboardingStep(userId: string, dto: UpdateOnboardingStepDto) {
    const state = await this.onboardingRepo.findOne({ where: { userId } });
    if (!state) {
      throw new NotFoundException('Estado de onboarding no encontrado');
    }

    const updated = this.applyUpdates(state, dto);
    const saved = await this.onboardingRepo.save(updated);
    return this.toOnboardingPublic(saved);
  }

  async updateBiometric(userId: string, dto: UpdateBiometricDto) {
    if (dto.enabled && !dto.method) {
      throw new BadRequestException('El método biométrico es obligatorio al activar');
    }

    const prefs = await this.biometricRepo.findOne({ where: { userId } });
    if (!prefs) {
      throw new NotFoundException('Preferencias biométricas no encontradas');
    }

    prefs.enabled = dto.enabled;
    if (dto.enabled) {
      prefs.method = dto.method!;
      prefs.deviceId = dto.deviceId ?? null;
    } else {
      prefs.method = null;
      prefs.deviceId = null;
    }

    await this.markBiometricPrompted(userId);
    const saved = await this.biometricRepo.save(prefs);

    return {
      enabled: saved.enabled,
      method: saved.method,
      deviceId: saved.deviceId,
      updatedAt: saved.updatedAt,
    };
  }

  private applyUpdates(state: OnboardingState, dto: UpdateOnboardingStepDto): OnboardingState {
    if (dto.currentStep !== undefined) state.currentStep = dto.currentStep;
    if (dto.resumeSurface !== undefined) state.resumeSurface = dto.resumeSurface;
    if (dto.resumeContext !== undefined) state.resumeContext = dto.resumeContext;
    if (dto.financialProfileCompleted !== undefined) {
      state.financialProfileCompleted = dto.financialProfileCompleted;
    }
    if (dto.goalsSet !== undefined) state.goalsSet = dto.goalsSet;
    if (dto.importAttempted !== undefined) state.importAttempted = dto.importAttempted;
    if (dto.biometricPrompted !== undefined) state.biometricPrompted = dto.biometricPrompted;
    if (dto.minDocThresholdMet !== undefined) state.minDocThresholdMet = dto.minDocThresholdMet;

    if (this.isOnboardingComplete(state)) {
      state.onboardingStatus = 'completed';
      state.completedAt = new Date();
      state.resumeSurface = 'home';
      state.currentStep = null;
    }

    return state;
  }

  private isOnboardingComplete(state: OnboardingState): boolean {
    return (
      state.financialProfileCompleted &&
      state.importAttempted &&
      state.biometricPrompted &&
      state.minDocThresholdMet &&
      state.onboardingStatus !== 'completed'
    );
  }

  private async markBiometricPrompted(userId: string): Promise<void> {
    await this.onboardingRepo
      .createQueryBuilder()
      .update(OnboardingState)
      .set({ biometricPrompted: true })
      .where('user_id = :userId', { userId })
      .execute();
  }

  private toOnboardingPublic(state: OnboardingState) {
    return {
      onboardingStatus: state.onboardingStatus,
      currentStep: state.currentStep,
      resumeSurface: state.resumeSurface,
      resumeContext: state.resumeContext,
      financialProfileCompleted: state.financialProfileCompleted,
      goalsSet: state.goalsSet,
      importAttempted: state.importAttempted,
      biometricPrompted: state.biometricPrompted,
      minDocThresholdMet: state.minDocThresholdMet,
      completedAt: state.completedAt,
    };
  }
}
```

---

### PASO 5: Refactorizar `AuthService` (Core)

```typescript
// src/auth/auth.service.ts (REFACTORIZADO)

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UsersService } from '../users/users.service';
import { MailService } from '../mail/mail.service';
import { RefreshToken } from './entities/refresh-token.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { JwtPayload } from './interfaces/jwt-payload.interface';
import {
  generateOpaqueToken,
  hashOpaqueToken,
} from '../common/utils/crypto.utils';
import { User } from '../users/entities/user.entity';
import { CatalogSeedService } from '../catalog/catalog-seed.service';
import { getDocumentValidator } from '../common/validators/document/document-validator.factory';
import { EmailVerificationService } from './services/email-verification.service';
import { UserInitializationService } from './services/user-initialization.service';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly catalogSeed: CatalogSeedService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly mailService: MailService,
    private readonly emailVerification: EmailVerificationService,
    private readonly userInitialization: UserInitializationService,
    @InjectRepository(RefreshToken)
    private readonly refreshRepo: Repository<RefreshToken>,
  ) {}

  async register(dto: RegisterDto) {
    if (!dto.acceptTerms || !dto.acceptPrivacy) {
      throw new BadRequestException(
        'Debes aceptar los términos y política de privacidad',
      );
    }

    const defaults = this.catalogSeed.getDefaults();
    const docValidator = getDocumentValidator(defaults.rutDocumentTypeCode);
    if (docValidator && !docValidator.validate(dto.documentNumber)) {
      throw new BadRequestException(docValidator.errorMessage);
    }

    const now = new Date();
    const user = await this.usersService.create({
      email: dto.email,
      documentNumber: dto.documentNumber,
      documentTypeId: defaults.rutDocumentTypeId,
      password: dto.password,
      acceptedTermsAt: now,
      acceptedPrivacyAt: now,
      trialDays: this.config.get<number>('TRIAL_DAYS_DEFAULT', 30),
    });

    await this.userInitialization.initializeNewUser(user.userId);

    const otpPayload = await this.emailVerification['generateAndPersistOtp'](
      user.userId,
      user.email!,
    );
    void this.mailService
      .sendEmailVerificationCode(otpPayload.normalizedEmail, otpPayload.code)
      .catch((err: unknown) => {
        const msg = err instanceof Error ? err.message : String(err);
        this.logger.warn(
          `Código de verificación no enviado tras registro (${otpPayload.normalizedEmail}): ${msg}`,
        );
      });

    const tokens = await this.issueTokens(user);
    return {
      user: this.usersService.toPublic(user),
      ...tokens,
      nextStep: 'email_verification',
    };
  }

  async login(dto: LoginDto) {
    const user = await this.usersService.findByEmailWithPassword(dto.email);
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const ok = await this.usersService.validatePassword(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const defaults = this.catalogSeed.getDefaults();
    const status = user.userStatusId;

    if (status === defaults.pendingVerificationStatusId) {
      const tokens = await this.issueTokens(user);
      void this.emailVerification
        .requestEmailVerification(user.userId, user.email!)
        .catch((err: unknown) => {
          const msg = err instanceof Error ? err.message : String(err);
          this.logger.warn(`OTP auto-resend on login failed for ${user.email}: ${msg}`);
        });
      return {
        user: this.usersService.toPublic(user),
        ...tokens,
        nextStep: 'email_verification',
      };
    }

    if (status === defaults.suspendedStatusId) {
      throw new ForbiddenException('Tu cuenta ha sido suspendida. Contacta soporte.');
    }

    if (status !== defaults.activeStatusId) {
      throw new ForbiddenException('Tu cuenta no está disponible. Contacta soporte.');
    }

    const tokens = await this.issueTokens(user);
    return {
      user: this.usersService.toPublic(user),
      ...tokens,
    };
  }

  async refresh(refreshTokenPlain: string) {
    const hash = hashOpaqueToken(refreshTokenPlain);
    const row = await this.refreshRepo.findOne({ where: { tokenHash: hash } });

    if (!row) {
      throw new UnauthorizedException('Sesión inválida o expirada');
    }

    if (row.revokedAt) {
      await this.revokeAllRefreshForUser(row.userId);
      throw new UnauthorizedException('Sesión inválida o expirada');
    }

    if (row.expiresAt.getTime() < Date.now()) {
      throw new UnauthorizedException('Sesión inválida o expirada');
    }

    const user = await this.usersService.findById(row.userId);
    if (!user) {
      throw new UnauthorizedException('Usuario no encontrado');
    }

    row.revokedAt = new Date();
    await this.refreshRepo.save(row);
    return this.issueTokens(user);
  }

  async logout(refreshTokenPlain: string) {
    const hash = hashOpaqueToken(refreshTokenPlain);
    const row = await this.refreshRepo.findOne({ where: { tokenHash: hash } });
    if (row && !row.revokedAt) {
      row.revokedAt = new Date();
      await this.refreshRepo.save(row);
    }
    return { ok: true };
  }

  async logoutAll(userId: string) {
    await this.revokeAllRefreshForUser(userId);
    return { ok: true };
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.usersService.findByIdWithPassword(userId);
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException();
    }

    const ok = await this.usersService.validatePassword(currentPassword, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Contraseña actual incorrecta');
    }

    await this.usersService.updatePassword(userId, newPassword);
    await this.revokeAllRefreshForUser(userId);
    return { message: 'Contraseña actualizada correctamente' };
  }

  private async revokeAllRefreshForUser(userId: string): Promise<void> {
    await this.refreshRepo
      .createQueryBuilder()
      .update(RefreshToken)
      .set({ revokedAt: new Date() })
      .where('user_id = :userId', { userId })
      .andWhere('revoked_at IS NULL')
      .execute();
  }

  private async issueTokens(user: User) {
    const payload: JwtPayload = {
      sub: user.userId,
      email: user.email!,
    };
    const accessToken = await this.jwtService.signAsync(payload);
    const refreshPlain = generateOpaqueToken();
    const refreshHash = hashOpaqueToken(refreshPlain);
    const days = this.config.get<number>('REFRESH_EXPIRES_DAYS', 30);
    const expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000);

    await this.refreshRepo.save(
      this.refreshRepo.create({
        userId: user.userId,
        tokenHash: refreshHash,
        expiresAt,
        revokedAt: null,
      }),
    );

    return {
      accessToken,
      refreshToken: refreshPlain,
      expiresIn: this.config.get<string>('JWT_EXPIRES_IN', '15m'),
    };
  }
}
```

---

### PASO 6: Actualizar `auth.module.ts`

```typescript
// src/auth/auth.module.ts

import { Module, forwardRef } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import type { SignOptions } from 'jsonwebtoken';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { RefreshToken } from './entities/refresh-token.entity';
import { PasswordResetToken } from './entities/password-reset-token.entity';
import { EmailVerificationToken } from './entities/email-verification-token.entity';
import { BiometricPreferences } from './entities/biometric-preferences.entity';
import { OnboardingState } from './entities/onboarding-state.entity';
import { UsersModule } from '../users/users.module';
import { MailModule } from '../mail/mail.module';
import { CashflowModule } from '../cashflow/cashflow.module';
import { CatalogModule } from '../catalog/catalog.module';
import { UserGamificationStats } from '../gamification/entities/user-gamification-stats.entity';
import { EmailVerificationService } from './services/email-verification.service';
import { PasswordManagementService } from './services/password-management.service';
import { UserOnboardingService } from './services/user-onboarding.service';
import { UserInitializationService } from './services/user-initialization.service';

@Module({
  imports: [
    forwardRef(() => UsersModule),
    CashflowModule,
    MailModule,
    CatalogModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    TypeOrmModule.forFeature([
      RefreshToken,
      PasswordResetToken,
      EmailVerificationToken,
      BiometricPreferences,
      OnboardingState,
      UserGamificationStats,
    ]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: config.get<string>('JWT_EXPIRES_IN', '15m') as SignOptions['expiresIn'],
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtStrategy,
    EmailVerificationService,
    PasswordManagementService,
    UserOnboardingService,
    UserInitializationService,
  ],
  exports: [AuthService],
})
export class AuthModule {}
```

---

## 📊 Comparativa: Antes vs Después

| Métrica | Antes | Después |
|---------|-------|---------|
| **Líneas en AuthService** | 547 | ~220 |
| **Máximo inyecciones** | 9 | 7 (AuthService solo) |
| **Responsabilidades** | 7 | 1 (Core Auth) |
| **Métodos públicos** | 11 | 5 |
| **Complejidad ciclomática** | ~45 | ~15 |
| **Testabilidad** | ⚠️ Difícil | ✅ Fácil |
| **Reutilizable** | ❌ No | ✅ Sí |

---

## ✅ Beneficios del Refactoring

### 1. **Single Responsibility Principle**
- AuthService: solo autenticación
- EmailVerificationService: solo verificación de email
- PasswordManagementService: solo gestión de contraseñas
- UserOnboardingService: solo estado de onboarding
- UserInitializationService: solo inicialización de usuario

### 2. **Testabilidad**
Antes:
```typescript
it('should register user', () => {
  // Necesita mockear: UsersService, CashflowSeedService, 
  // MailService, 5 Repositories, CatalogSeedService
  const authService = new AuthService(
    mockUsers, mockCashflow, mockCatalog, mockJwt, 
    mockConfig, mockMail, mockRefresh, mockReset, 
    mockEmailVerif, mockBiometric, mockOnboarding, 
    mockGamification
  );
});
```

Después:
```typescript
it('should register user', () => {
  // AuthService solo necesita:
  const authService = new AuthService(
    mockUsers, mockCatalog, mockJwt, mockConfig,
    mockMail, mockEmailVerification, mockUserInitialization, 
    mockRefresh
  );
});
```

### 3. **Mantenibilidad**
- Cambiar flujo de verificación de email → solo editar EmailVerificationService
- Cambiar logica de reset password → solo editar PasswordManagementService
- Cambiar onboarding flow → solo editar UserOnboardingService

### 4. **Modularidad**
UserInitializationService puede ser usado en otros contextos:
- Re-activation de usuarios suspendidos
- Admin creando usuarios
- Imports/migrations

---

## 🚨 Consideraciones de Implementación

### 1. **Migración de Controllers**
Auth.controller debe delegar a los nuevos servicios:
```typescript
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly emailVerification: EmailVerificationService,
    private readonly passwordManagement: PasswordManagementService,
    private readonly onboarding: UserOnboardingService,
  ) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('email-verification/confirm')
  confirmEmail(@Req() req, @Body() dto) {
    return this.emailVerification.confirmEmailVerification(
      req.user.sub,
      dto.email,
      dto.code,
    );
  }

  @Post('password-reset')
  resetPassword(@Body() dto) {
    return this.passwordManagement.resetPassword(dto.email, dto.code, dto.newPassword);
  }

  @Get('onboarding')
  getOnboarding(@Req() req) {
    return this.onboarding.getOnboarding(req.user.sub);
  }
}
```

### 2. **Transacciones**
⚠️ `UserInitializationService.initializeNewUser()` usa `Promise.all()` pero NO hay transacción.
Si algo falla en step 3 de 4 → usuario existe pero estado incompleto.

**Solución**:
```typescript
// Usar decorador @Transactional de TypeORM
@Transactional()
async initializeNewUser(userId: string): Promise<void> {
  // Todos los awaits dentro de una txn
}
```

### 3. **Logging**
Agregar logs en nivel service:
```typescript
// UserInitializationService
private readonly logger = new Logger(UserInitializationService.name);

async initializeNewUser(userId: string): Promise<void> {
  this.logger.log(`Initializing new user: ${userId}`);
  try {
    await Promise.all([...]);
    this.logger.log(`User initialized successfully: ${userId}`);
  } catch (err) {
    this.logger.error(`Failed to initialize user ${userId}`, err);
    throw;
  }
}
```

---

## 🎯 Plan de Implementación

### Fase 1: Crear nuevos servicios
- [ ] UserInitializationService
- [ ] EmailVerificationService
- [ ] PasswordManagementService
- [ ] UserOnboardingService

### Fase 2: Refactorizar AuthService
- [ ] Eliminar métodos extraídos
- [ ] Actualizar inyecciones
- [ ] Actualizar constructor

### Fase 3: Actualizar módulo
- [ ] auth.module.ts: agregar nuevos providers
- [ ] Exportar servicios si es necesario

### Fase 4: Actualizar controllers
- [ ] auth.controller.ts: delegar a servicios
- [ ] Verificar rutas siguen funcionando

### Fase 5: Tests
- [ ] Tests unitarios nuevos servicios
- [ ] Tests integración auth.service
- [ ] E2E: register, login, email verification

---

**Próxima sesión**: Implementar refactoring o auditar siguiente módulo?
