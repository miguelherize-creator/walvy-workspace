# REQ-M2-PUSH — Notificaciones push (Expo) por procesamiento de cartola

**Estado:** Diseñado, sin implementar  
**Módulo:** M2 — Perfil y Configuración  
**Prioridad:** Media-Alta (UX crítico cuando el usuario cierra la app durante el onboarding)  
**Bloqueante para:** M2 Frontend completo (pantalla Configuración > Notificaciones)

---

## Problema

Cuando Kread tarda más de ~15 segundos, el usuario puede salir del `OnboardingAnalyzingScreen` (por modal de demora o timeout). El polling se detiene pero el backend sigue procesando. El usuario no sabe cuándo terminó → abandono o re-apertura manual sin saber el estado.

---

## Solución diseñada

Enviar un **push notification nativo** (via Expo Push API) cuando `processWithKread` termina con `status = parsed` o `status = failed`.

### Flujo completo

```
Usuario abre app
  → useNotificationSetup (hook en _layout.tsx)
    → pide permiso de notificaciones
    → obtiene ExpoPushToken
    → PATCH /users/me/push-token → guarda en app_user.expo_push_token

Kread termina de procesar (back-walvy)
  → status = parsed  → sendPushNotification("Tu cartola está lista 🎉")
  → status = failed  → sendPushNotification("Hubo un problema con tu cartola")
    → busca expo_push_token del usuario en app_user
    → POST https://exp.host/--/push/send

Usuario toca la notificación
  → addNotificationResponseReceivedListener → router.replace("/(tabs)")
  → (killed) getLastNotificationResponseAsync → router.replace("/(tabs)")
```

---

## Cambios de DB requeridos

```sql
-- Agregar en prod ANTES del deploy (o DB_SYNC=true en dev)
ALTER TABLE app_user
  ADD COLUMN expo_push_token VARCHAR(500);
```

---

## Backend — implementación lista para copiar

### 1. `src/users/entities/user.entity.ts`
Agregar campo después de `acceptedPrivacyAt`:
```typescript
@Column({ name: 'expo_push_token', type: 'varchar', length: 500, nullable: true })
expoPushToken!: string | null;
```

### 2. `src/users/users.service.ts`
Agregar método:
```typescript
async savePushToken(userId: string, token: string): Promise<void> {
  await this.usersRepo.update({ userId }, { expoPushToken: token });
}
```

### 3. `src/users/dto/save-push-token.dto.ts` (archivo nuevo)
```typescript
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class SavePushTokenDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  token!: string;
}
```

### 4. `src/users/users.controller.ts`
Agregar import de `SavePushTokenDto` y endpoint:
```typescript
import { SavePushTokenDto } from './dto/save-push-token.dto';

// En UsersController:
@Patch('me/push-token')
@UseGuards(AuthGuard('jwt'))
@ApiOperation({ summary: 'Registrar Expo push token del dispositivo' })
async savePushToken(
  @CurrentUser() user: JwtPayload,
  @Body() dto: SavePushTokenDto,
) {
  await this.usersService.savePushToken(user.sub, dto.token);
  return { ok: true };
}
```

### 5. `src/notifications/services/expo-push.service.ts` (archivo nuevo)
```typescript
import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

const EXPO_PUSH_URL = 'https://exp.host/--/push/send';

export interface ExpoPushMessage {
  to: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  sound?: 'default' | null;
}

@Injectable()
export class ExpoPushService {
  private readonly logger = new Logger(ExpoPushService.name);

  async send(message: ExpoPushMessage): Promise<void> {
    if (!message.to.startsWith('ExponentPushToken[')) {
      this.logger.warn(`Token inválido, ignorando notificación: ${message.to}`);
      return;
    }

    try {
      await axios.post(
        EXPO_PUSH_URL,
        { ...message, sound: message.sound ?? 'default' },
        { headers: { 'Content-Type': 'application/json', Accept: 'application/json' } },
      );
      this.logger.log(`Push enviado a ${message.to}: "${message.title}"`);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.error(`Error enviando push a ${message.to}: ${msg}`);
    }
  }
}
```

### 6. `src/notifications/notification.module.ts`
Agregar `ExpoPushService` a providers y exports:
```typescript
import { ExpoPushService } from './services/expo-push.service';

@Module({
  ...
  providers: [NotificationService, AlertRulesEngine, ExpoPushService],
  exports: [NotificationService, AlertRulesEngine, ExpoPushService],
})
```

### 7. `src/imports/statement-import.module.ts`
Agregar imports:
```typescript
import { NotificationModule } from '../notifications/notification.module';
import { User } from '../users/entities/user.entity';

@Module({
  imports: [
    ConfigModule,
    StorageModule,
    NotificationModule,
    TypeOrmModule.forFeature([StatementImport, ImportLineItem, User]),
    MulterModule.register({ storage: memoryStorage() }),
  ],
  ...
})
```

### 8. `src/imports/services/statement-import.service.ts`
Agregar imports y constructor:
```typescript
import { User } from '../../users/entities/user.entity';
import { ExpoPushService } from '../../notifications/services/expo-push.service';

// En constructor:
@InjectRepository(User)
private readonly userRepo: Repository<User>,
private readonly expoPush: ExpoPushService,
```

En `processWithKread`, después de `status: 'parsed'`:
```typescript
this.sendPushNotification(record.userId, {
  title: 'Tu cartola está lista 🎉',
  body: 'Ya puedes ver tus movimientos en Walvy.',
  data: { importId: record.id, status: 'parsed' },
});
```

Después de `status: 'failed'` (dentro del `if (currentRecord?.status !== 'cancelled')`):
```typescript
this.sendPushNotification(record.userId, {
  title: 'Hubo un problema con tu cartola',
  body: 'No pudimos procesar el documento. Abre Walvy para reintentar.',
  data: { importId: record.id, status: 'failed' },
});
```

Método privado nuevo en la clase:
```typescript
private sendPushNotification(
  userId: string,
  message: { title: string; body: string; data: Record<string, unknown> },
): void {
  this.userRepo
    .findOne({ where: { userId }, select: { expoPushToken: true } })
    .then(user => {
      if (!user?.expoPushToken) return;
      return this.expoPush.send({ to: user.expoPushToken, ...message });
    })
    .catch(err => this.logger.error(`sendPushNotification error user ${userId}: ${err}`));
}
```

---

## Frontend — implementación lista para copiar

### 1. `package.json`
```
"expo-notifications": "~0.29.14"
```
Instalar con: `npx expo install expo-notifications`

### 2. `app.json`
En `ios`, agregar:
```json
"infoPlist": {
  "UIBackgroundModes": ["remote-notification"]
}
```
En `plugins`, agregar:
```json
[
  "expo-notifications",
  {
    "icon": "./assets/brand/isotipo.png",
    "color": "#1B6B73",
    "sounds": []
  }
]
```

### 3. `api/endpoints.ts`
```typescript
users: {
  ...
  pushToken: "/users/me/push-token",
}
```

### 4. `api/authService.ts`
```typescript
export async function registerPushToken(token: string): Promise<void> {
  if (isMockMode) return;
  await apiClient.patch(ENDPOINTS.users.pushToken, { token });
}
```

### 5. `hooks/useNotificationSetup.ts` (archivo nuevo)
```typescript
import { useEffect, useRef } from "react";
import { Platform } from "react-native";
import { useRouter } from "expo-router";
import * as Notifications from "expo-notifications";
import Constants from "expo-constants";
import { registerPushToken } from "@/api/authService";

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowAlert: true,
  }),
});

const PROJECT_ID =
  Constants.expoConfig?.extra?.eas?.projectId ??
  "30b2c444-e3e7-490e-9d2f-794bdf09705a";

export function useNotificationSetup(isAuthenticated: boolean) {
  const router = useRouter();
  const registeredRef = useRef(false);

  useEffect(() => {
    if (!isAuthenticated || Platform.OS === "web") return;
    if (registeredRef.current) return;
    registeredRef.current = true;

    (async () => {
      try {
        const { status: existing } = await Notifications.getPermissionsAsync();
        const finalStatus =
          existing === "granted"
            ? existing
            : (await Notifications.requestPermissionsAsync()).status;

        if (finalStatus !== "granted") return;

        const tokenData = await Notifications.getExpoPushTokenAsync({ projectId: PROJECT_ID });
        await registerPushToken(tokenData.data);
      } catch (err) {
        if (__DEV__) console.log("[Notifications] Token registration failed:", err);
      }
    })();
  }, [isAuthenticated]);

  useEffect(() => {
    if (Platform.OS === "web") return;
    const sub = Notifications.addNotificationResponseReceivedListener(
      (response: Notifications.NotificationResponse) => {
        const data = response.notification.request.content.data as { status?: string };
        if (data?.status === "parsed" || data?.status === "failed") {
          router.replace("/(tabs)");
        }
      }
    );
    return () => sub.remove();
  }, [router]);

  useEffect(() => {
    if (Platform.OS === "web") return;
    Notifications.getLastNotificationResponseAsync().then(
      (response: Notifications.NotificationResponse | null) => {
        if (!response) return;
        const data = response.notification.request.content.data as { status?: string };
        if (data?.status === "parsed" || data?.status === "failed") {
          router.replace("/(tabs)");
        }
      }
    );
  }, []);
}
```

### 6. `app/_layout.tsx`
```typescript
// Agregar imports:
import { useNotificationSetup } from "@/hooks/useNotificationSetup";
import { AuthProvider, useAuth } from "@/store/AuthProvider";

// En RootLayoutNav:
const { isAuthenticated } = useAuth();
useNotificationSetup(isAuthenticated);
```

---

## Notas de integración

- El token se registra **una vez por sesión autenticada** — el hook guarda un `ref` para no re-llamar.
- Si el usuario deniega permisos, el flujo no falla — simplemente no hay push.
- La notificación de `failed` no interfiere con el reintento: el usuario entra a `/(tabs)` y desde ahí puede volver al flow de import.
- En producción: el `expo_push_token` puede cambiar (reinstalación, reset de OS) — el hook lo re-registra cada login nuevo.
- `ExpoPushService` falla silenciosamente: un error de red al enviar el push no afecta el procesamiento de la cartola.
