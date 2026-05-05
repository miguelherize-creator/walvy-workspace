# Plan de Refactor — Frontend Walvy (5 días)

> **Contexto:** La app tiene Módulos 1 (auth) y 2 (perfil) completados.
> Feature-First implementado. Theming light/dark operativo. API client con mock mode.
> Este plan ataca los **gaps reales identificados en la review**, no rehace lo que ya funciona.
>
> **Fecha inicio:** Semana del 5 de mayo 2026
> **Desarrollador:** 1 FE senior

---

## Principios de este refactor

1. **No romper lo que funciona.** Ningún día cambia la arquitectura existente.
2. **Quick wins primero.** Los días 1–2 son mejoras de impacto inmediato en calidad y mantenibilidad.
3. **Tests antes de extracciones.** Cualquier hook que se vaya a refactorizar tiene test primero.
4. **Un PR por día.** Facilita revisión y rollback si es necesario.

---

## Día 1 — Token System & Dependencias de capa

**Objetivo:** Eliminar colores hardcodeados y corregir la violación de dependencia `components/ → features/`.

### Tareas

#### 1.1 Mover `AuthBlobBackground` a `components/`

```
components/
  AuthBlobBackground.tsx   ← mover desde features/auth/ui/
  AuthScreenShell.tsx      ← actualizar import (mismo directorio)
```

Actualizar imports en:
- `features/auth/ui/AccountConfirmedScreen.tsx`
- `features/auth/ui/ChangePasswordScreen.tsx`
- `features/profile/ui/ProfileScreen.tsx` (línea 32)
- `features/profile/ui/NotificationSettingsScreen.tsx` (línea 6)

**Verificación:** `grep -r "features/auth/ui/AuthBlobBackground" .` → cero resultados.

#### 1.2 Añadir 4 tokens faltantes a `constants/colors.ts`

Tokens a agregar en el objeto `light` y en `darkColors`:

```typescript
// En colors (light)
profileDatosCardBg:   "#FFFDFD",   // Figma nodo 2927:758 — card surface datos
profileReadonlyText:  "rgba(16,63,67,0.5)", // Figma — nombre/RUT read-only
profileAvatarBg:      "#F7F4EB",   // Figma nodo 2927:759 — avatar placeholder
profileShadowDark:    "#202B35",   // solo para ios shadowColor en dark

// En darkColors
profileDatosCardBg:   "#162A2C",   // card surface datos — dark
profileReadonlyText:  "rgba(51,174,168,0.45)",
profileAvatarBg:      "#1E3840",
profileShadowDark:    "#202B35",   // igual en ambos modos
```

**Nota:** `FIGMA_DATOS_CARD_BORDER = "#E6DED2"` ya tiene token: `theme.subscriptionCardBorder`. Usar ese en lugar de la constante local.

#### 1.3 Limpiar constantes locales en `ProfileScreen`

Reemplazar en `features/profile/ui/ProfileScreen.tsx`:

| Constante a eliminar | Reemplazar por |
|---|---|
| `ICON_SLOT_LIGHT_BG` | `theme.profileIconSlot` (ya existe en ambos modos) |
| `FIGMA_DATOS_CARD_BG_LIGHT` | `theme.profileDatosCardBg` |
| `FIGMA_DATOS_CARD_BORDER` | `theme.subscriptionCardBorder` |
| `READONLY_NAME_LIGHT` | `theme.profileReadonlyText` |
| `FIGMA_AVATAR_BG_LIGHT` | `theme.profileAvatarBg` |
| `hubCardShadowDark` shadow `"#202B35"` | `theme.profileShadowDark` |
| `PREFS_TITLE_LIGHT_COLOR` | considerar añadir como token o usar `theme.profileReadonlyText` |

Verificar `WalvyTabBar.tsx:124` — `shadowColor: "#000"` → reemplazar por token o extraer a constante nombrada.

#### 1.4 Fix urgente: `goHub` async en ProfileScreen

```typescript
// features/profile/ui/ProfileScreen.tsx:192
const goHub = useCallback(async () => {
  if (isDirty) {
    const saved = await handleSave();
    if (!saved) return;
  }
  setViewMode("hub");
}, [handleSave, isDirty]);
```

### Resultado esperado (DoD)
- `grep -r "features/auth/ui/AuthBlobBackground" .` → 0 resultados
- `grep -rn '"#[0-9A-Fa-f]\{3,8\}"' features/profile/ui/ProfileScreen.tsx` → solo shadowColor permitido
- Test `profile.test.tsx` sigue en verde (18/18)
- `bun run lint` sin errores nuevos

---

## Día 2 — API Layer: endpoints centralizados + tipos de respuesta

**Objetivo:** Centralizar paths de API, eliminar `any` en respuestas, y preparar para versionado.

### Tareas

#### 2.1 Crear `api/endpoints.ts`

```typescript
// api/endpoints.ts
export const ENDPOINTS = {
  auth: {
    register:       "/auth/register",
    login:          "/auth/login",
    me:             "/users/me",
    logout:         "/auth/logout",
    refreshToken:   "/auth/refresh",
    forgotPassword: "/auth/forgot-password",
    resetPassword:  "/auth/reset-password",
    changePassword: "/auth/change-password",
    verifyEmail:    "/auth/verify-email",
    resendVerification: "/auth/resend-verification",
  },
  profile: {
    update: "/users/me",
  },
  subscriptions: {
    plans:    "/subscriptions/plans",
    me:       "/subscriptions/me",
    checkout: "/subscriptions/checkout",
  },
} as const;
```

Reemplazar todos los strings literales en `authService.ts`, `profileService.ts`, `subscriptionService.ts`.

#### 2.2 Tipado de respuestas en `changePassword` y `forgotPassword`

Identificar todos los `any` en `api/authService.ts` (al menos líneas 87–88, 129) y reemplazar con tipos explícitos definidos en `api/types.ts`.

```typescript
// api/types.ts — agregar
export interface MessageResponse {
  message: string;
}

export interface ChangePasswordResponse {
  success: boolean;
}
```

#### 2.3 Variables de entorno para URLs base

Verificar que `api/config.ts` use correctamente `EXPO_PUBLIC_BACKEND_BASE_URL` y no tenga `localhost` como único fallback para staging/prod. Añadir un fallback de staging si aplica.

```typescript
// api/config.ts — revisar
const BACKEND_BASE_URL =
  process.env.EXPO_PUBLIC_BACKEND_BASE_URL ??
  (Platform.OS === "android" ? "http://10.0.2.2:3000" : "http://localhost:3000");
```

Documentar en `ai/skills.md` las variables de entorno necesarias por ambiente.

#### 2.4 Añadir tests de regresión para endpoints

Verificar que `api/__tests__/authService.test.ts` cubra las paths renombradas. Añadir al menos un test por servicio que verifique que se llama el endpoint correcto.

### Resultado esperado (DoD)
- `grep -rn '"/auth/\|"/users/\|"/subscriptions/' api/*.ts` → 0 resultados (todos usan `ENDPOINTS.*`)
- `grep -rn ": any" api/authService.ts` → 0 resultados
- Tests API siguen en verde
- `bun run lint` sin errores

---

## Día 3 — Test coverage: hooks críticos y data layer

**Objetivo:** Cubrir la lógica de negocio que hoy no tiene tests (hooks y repositorios).

### Tareas

#### 3.1 Tests para `useProfileForm`

**Archivo:** `features/profile/hooks/__tests__/useProfileForm.test.ts`

Casos a cubrir:
- `isDirty` es false cuando alias y email no cambian
- `isDirty` es true cuando se modifica alias o email
- `handleSave` retorna false si email vacío / inválido
- `handleSave` llama al repositorio con los campos correctos
- `handleSave` devuelve true y actualiza `setUser` en éxito
- `handleSave` muestra `apiError` en fallo de API
- `handleLogout` llama `logout` y navega a `/login`
- `legalNameDisplay` y `rutDisplay` muestran fallback cuando no hay datos

#### 3.2 Tests para `useAppHeader`

**Archivo:** `features/home/hooks/__tests__/useAppHeader.test.ts`

Casos a cubrir:
- `userInitial` usa `firstName` si existe, `email` como fallback, `"U"` como último recurso
- `handleLogout` llama `logout`, luego `router.replace("/login")`
- `handleLogout` navega a login aunque `logout()` falle
- `onToggle` abre/cierra el menú
- `onClose` siempre cierra el menú

#### 3.3 Tests para `authRepository` y `profileRepository`

**Archivos:** `features/auth/data/__tests__/authRepository.test.ts`, `features/profile/data/__tests__/profileRepository.test.ts`

Casos a cubrir:
- Llaman al servicio real cuando mock mode está off
- Llaman al mock cuando mock mode está on
- Propagan errores del servicio hacia el hook

#### 3.4 Test mínimo para `AuthProvider` — biometric flow

**Archivo:** `store/__tests__/AuthProvider.test.tsx`

Casos críticos:
- `enableBiometric` guarda flag en SecureStore
- `disableBiometric` limpia flag de SecureStore
- `authenticateWithBiometric` retorna false si el dispositivo cancela
- Session restore en mount cuando hay token válido en SecureStore

### Resultado esperado (DoD)
- `npx jest --coverage` muestra `features/profile/hooks/` ≥ 70% coverage
- `npx jest --coverage` muestra `store/AuthProvider` ≥ 50% coverage
- Todos los tests pasan, incluyendo los anteriores

---

## Día 4 — Responsive design & breakpoints

**Objetivo:** Preparar la app para diferentes tamaños de pantalla (phones + tablets) sin hardcodear píxeles.

### Tareas

#### 4.1 Crear `utils/responsive.ts`

```typescript
// utils/responsive.ts
import { Dimensions, PixelRatio } from "react-native";

const { width: SCREEN_WIDTH } = Dimensions.get("window");

export type Breakpoint = "sm" | "md" | "lg";

export function getBreakpoint(): Breakpoint {
  if (SCREEN_WIDTH < 380) return "sm";   // small phones (SE, mini)
  if (SCREEN_WIDTH < 600) return "md";   // standard phones
  return "lg";                           // tablets / large phones
}

/** Escala un valor base según el ancho de pantalla. */
export function rs(base: number): number {
  const scale = SCREEN_WIDTH / 390; // diseño base en 390px (iPhone 14)
  return Math.round(PixelRatio.roundToNearestPixel(base * Math.min(scale, 1.3)));
}

export const isTablet = SCREEN_WIDTH >= 600;
```

#### 4.2 Auditar literales de píxeles en componentes críticos

Archivos de mayor impacto (headers, cards, tab bar):
- `components/WalvyTabBar.tsx` — `paddingTop: 17`, `maxWidth: 400`
- `features/home/ui/HomeHeader.tsx` — `minHeight: 46`, `width: 36`
- `features/profile/ui/ProfileScreen.tsx` — `minHeight: 48`, `width: 40`, `height: 40`

**Criterio:** No reemplazar todos los literales — solo los que afectan el layout en tablets. Los borderRadius y padding finos pueden quedarse.

Reemplazar con `rs()`:
```typescript
// Antes
minHeight: 48,
// Después
minHeight: rs(48),
```

#### 4.3 Adaptar `WalvyTabBar` para tablets

En tablets (`isTablet === true`) el tab bar centrado con `maxWidth: 400` ya funciona. Verificar que en iPad el `paddingHorizontal` no deje los tabs demasiado separados. Ajustar si es necesario:

```typescript
// WalvyTabBar.tsx
const maxTabWidth = isTablet ? 480 : 400;
// ...
<View style={[styles.row, { maxWidth: maxTabWidth }]}>
```

#### 4.4 Adaptar textos a breakpoints

En `constants/theme.ts` añadir variantes de escala de tipografía:

```typescript
// Solo para sm breakpoint — tipografías reducidas
export const fontSizeSm = {
  xs: 11, sm: 13, md: 15, lg: 18, xl: 22, xxl: 26, xxxl: 30,
} as const;
```

Y hook `useFontSize()` que devuelve el set correcto según breakpoint.

### Resultado esperado (DoD)
- La app se ve correctamente en iPhone SE (375px), iPhone 14 Pro (393px), iPad mini (768px)
- Test `constants/__tests__/theme.test.ts` actualizado con nuevas utilidades
- `bun run lint` sin errores

---

## Día 5 — Performance, Logging y `typedRoutes`

**Objetivo:** Eliminar deuda técnica de tipado, preparar logging para producción, y memoizar componentes pesados.

### Tareas

#### 5.1 Activar `typedRoutes` en Expo Router

En `app.json` (o `app.config.js`):
```json
{
  "expo": {
    "experiments": { "typedRoutes": true }
  }
}
```

Ejecutar `npx expo customize` para regenerar `expo-env.d.ts`.

Eliminar todos los `as never` en `router.push`/`router.replace` (20 instancias identificadas). Corregir cualquier path que TypeScript marque como inválido.

**Archivos a actualizar:**
- `features/auth/hooks/useBiometricLogin.ts`
- `features/auth/hooks/useLoginForm.ts`
- `features/auth/ui/ChooseAliasScreen.tsx`
- `features/auth/ui/LoginScreen.tsx`
- `features/home/hooks/useAppHeader.ts`
- `features/profile/ui/ProfileScreen.tsx`
- `features/profile/ui/SettingsScreen.tsx`
- `features/profile/ui/FinancialGoalScreen.tsx`
- `features/splash/ui/SplashScreen.tsx`
- `components/WalvyTabBar.tsx`

#### 5.2 Crear `utils/logger.ts`

```typescript
// utils/logger.ts
type Tag = "Auth" | "API" | "Mock" | "Login" | "Register" | "Profile" | "Nav";

const isDev = __DEV__;

export const logger = {
  log: (tag: Tag, ...args: unknown[]) =>
    isDev && console.log(`[${tag}]`, ...args),
  warn: (tag: Tag, ...args: unknown[]) =>
    console.warn(`[${tag}]`, ...args),      // warn sí va a producción
  error: (tag: Tag, ...args: unknown[]) =>
    console.error(`[${tag}]`, ...args),     // error también
};
```

Reemplazar todos los `console.log("[Auth]", ...)` en `store/AuthProvider.tsx` (17 instancias) y análogos en hooks de auth.

#### 5.3 `React.memo` en componentes pesados del home

Componentes candidatos (renderean listas o tienen subárboles grandes):
- `features/home/ui/SummaryCarousel.tsx`
- `features/home/ui/FinanceCard.tsx`
- `features/home/ui/FinancialHealthRings.tsx`

```typescript
export default React.memo(SummaryCarousel);
```

Solo aplicar si el padre (`HomeScreen`) re-renderiza frecuentemente por cambio de estado no relacionado.

#### 5.4 Mover placeholders a `features/`

Crear pantallas placeholder en sus features correspondientes antes de que arranquen los sprints:

```
features/transactions/ui/TransactionsScreen.tsx   ← placeholder
features/budget/ui/BudgetScreen.tsx               ← placeholder
features/assistant/ui/AssistantScreen.tsx         ← placeholder
```

Actualizar `app/(tabs)/movimientos.tsx`, `presupuesto.tsx`, `chatbot.tsx`, `movimiento.tsx` para que sean 2-line delegates.

#### 5.5 `useBackHandler` para Android en ProfileScreen datos-view

```typescript
// features/profile/ui/ProfileScreen.tsx
import { BackHandler } from "react-native";

useEffect(() => {
  if (viewMode !== "datos") return;
  const sub = BackHandler.addEventListener("hardwareBackPress", () => {
    void goHub();
    return true;
  });
  return () => sub.remove();
}, [viewMode, goHub]);
```

### Resultado esperado (DoD)
- `grep -rn "as never" features/ components/ app/` → 0 resultados
- `grep -rn "console\.log" store/ features/ api/authService.ts` → 0 resultados (usan `logger.*`)
- Placeholders son 2-line delegates
- `bun run test` → todos los tests pasan
- `bun run lint` → 0 errores

---

## Resumen de impacto por día

| Día | Área | Archivos cambiados | Tests afectados | Riesgo |
|---|---|---|---|---|
| 1 | Tokens + deps | `colors.ts`, `ProfileScreen`, `AuthScreenShell`, 4 screens | 18 existentes | Bajo |
| 2 | API layer | `endpoints.ts` (nuevo), 3 services, tests API | Tests API | Medio |
| 3 | Tests | 4 test files nuevos | +30 tests aprox. | Bajo |
| 4 | Responsive | `responsive.ts` (nuevo), `theme.ts`, tabbar, header | 2 tests actualizados | Bajo |
| 5 | TS + perf | 10 files `as never`, `logger.ts`, memos, placeholders | Todos los tests | Medio |

---

## Riesgos y mitigaciones

| Riesgo | Probabilidad | Mitigación |
|---|---|---|
| `typedRoutes` descubre paths incorrectos (Día 5) | Alta | Revisar antes de mergear; el build falla rápido, no silenciosamente |
| Cambio de breakpoints rompe layouts existentes (Día 4) | Media | Testear en simulador SE + iPad antes del PR |
| Mover `AuthBlobBackground` rompe pantallas auth (Día 1) | Baja | `grep` previo; los tests de login/register cubren el render |
| Tests de `AuthProvider` con SecureStore son lentos (Día 3) | Media | Mockear `expo-secure-store` completo; los tests de biométrico deben ser unitarios |

---

## Dependencias entre días

```
Día 1 (tokens) ─────────────────────────────────────────── independiente
Día 2 (API) ────────────────────────────────────────────── independiente
Día 3 (tests) ──── requiere Día 1 completado (ProfileScreen estable)
Día 4 (responsive) ─────────────────────────────────────── independiente
Día 5 (TS + perf) ─── requiere Día 2 (endpoints OK antes de tipado estricto)
```

Los días 1, 2 y 4 pueden hacerse en cualquier orden. El día 3 va después del 1. El día 5 después del 2.

---

## Herramientas recomendadas (sin cambiar el stack)

| Herramienta | Para | Estado |
|---|---|---|
| Zod | Validación de schema de respuestas API | No instalado — añadir en Día 2 si el equipo lo aprueba |
| `@testing-library/react-hooks` | Tests de hooks aislados | Ya disponible vía RNTL |
| Expo Router typed routes | Eliminar `as never` | Día 5 |
| `react-native-device-info` | Detectar tablet vs phone | Alternativa a `Dimensions` manual — opcional |
