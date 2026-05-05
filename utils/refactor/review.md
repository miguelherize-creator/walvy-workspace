# Code Review — Frontend `rork-checkapp/expo`

> Revisión técnica basada en el estado actual del branch `main` del frontend.
> Fecha: 2026-04-30 · Revisor: Tech Lead (Claude)

---

## Resumen ejecutivo

| Área | Estado | Crítico | Medio | Bajo |
|---|---|---|---|---|
| Arquitectura Feature-First | ✅ Sólida | 0 | 0 | 0 |
| Rutas (`app/`) | ✅ Limpias | 0 | 0 | 2 |
| Dependencias entre capas | ⚠️ 1 violación | 0 | 1 | 0 |
| Design tokens / colores | ❌ Incompleto | 0 | 4 | 3 |
| Cobertura de tests | ❌ Baja (~25%) | 0 | 3 | 2 |
| API layer | ⚠️ Frágil | 0 | 2 | 1 |
| Tipado TypeScript | ⚠️ Parcial | 0 | 1 | 2 |
| Performance | ✅ Aceptable | 0 | 0 | 2 |
| Accesibilidad | ⚠️ Básica | 0 | 1 | 2 |

---

## P1 — Sin bloqueos críticos

No se encontraron vulnerabilidades de seguridad, memory leaks evidentes, ni violaciones que rompan el comportamiento en producción.

---

## P2 — Medio (should fix antes del siguiente sprint)

### 2.1 Violación de dependencia hacia arriba: `AuthScreenShell` → `features/`

**Archivo:** `components/AuthScreenShell.tsx:3`

```typescript
// ❌ Un componente shared importa desde un feature — viola la regla de capas
import AuthBlobBackground from "@/features/auth/ui/AuthBlobBackground";
```

**Regla violada:** `components/` no puede importar de `features/`. El flujo es:
```
ui/ → hooks/ → data/ → api/
components/ → constants/, utils/    ← solo hacia abajo
```

**Fix:** Mover `AuthBlobBackground` a `components/` (es reutilizable — ya lo usan `ProfileScreen`, `NotificationSettingsScreen`, `ChangePasswordScreen`).

```
components/
  AuthBlobBackground.tsx   ← mover aquí
  AuthScreenShell.tsx      ← actualizar import
```

Actualizar todos los imports existentes en `features/auth/ui/` y `features/profile/ui/`.

---

### 2.2 Constantes de color sin token en `ProfileScreen`

**Archivos:** `features/profile/ui/ProfileScreen.tsx` líneas 47–82

Las siguientes constantes locales deberían vivir en `constants/colors.ts` y consumirse vía `useTheme()`:

| Constante local | Valor | Token propuesto |
|---|---|---|
| `FIGMA_DATOS_CARD_BG_LIGHT` | `"#FFFDFD"` | `theme.profileDatosCardBg` |
| `FIGMA_DATOS_CARD_BORDER` | `"#E6DED2"` | ya existe: `theme.subscriptionCardBorder` |
| `READONLY_NAME_LIGHT` | `"rgba(16,63,67,0.5)"` | `theme.profileReadonlyText` |
| `FIGMA_AVATAR_BG_LIGHT` | `"#F7F4EB"` | `theme.profileAvatarBg` |
| `hubCardShadowDark` shadow | `"#202B35"` | `theme.profileShadowDark` |
| `ICON_SLOT_LIGHT_BG` | `"#F6F6F6"` | ya existe: `theme.profileIconSlot` |

**Nota sobre `ICON_SLOT_LIGHT_BG`:** El token `theme.profileIconSlot` ya está definido en `colors.ts:148` con el mismo valor `"#F6F6F6"`. `IconSlot` puede simplificar a `backgroundColor: theme.profileIconSlot` (funciona en ambos modos porque `darkColors.profileIconSlot` también está definido en `:251`).

**Fix mínimo:** Añadir a `colors.ts` los 4 tokens faltantes y eliminar las constantes locales en `ProfileScreen`.

---

### 2.3 Cobertura de tests: hooks y capa de datos

**Estado actual:** ~25% de cobertura estimada. Los tests existentes cubren mayoritariamente componentes UI y la capa de rutas.

**Sin tests:**

| Archivo | Prioridad | Razón |
|---|---|---|
| `features/profile/hooks/useProfileForm.ts` | Alta | Lógica de validación, mutación, isDirty, handleSave |
| `features/profile/hooks/useNotificationSettings.ts` | Media | Toggle + persistencia |
| `features/home/hooks/useAppHeader.ts` | Media | Logout + navegación desde header global |
| `features/home/hooks/useHomeScreen.ts` | Baja | Animaciones + lecturas del auth |
| `features/auth/data/authRepository.ts` | Alta | Wrappers de authService con mock toggle |
| `features/profile/data/profileRepository.ts` | Alta | Wrap de profileService |
| `store/AuthProvider.tsx` | Alta | Biometric flow + session restore + token rotation |

**Tests de integración faltantes:**
- Flujo completo login → biométrico → home
- Flujo updateProfile con validación client-side + API success/error

---

### 2.4 API: endpoints hardcodeados y ausencia de esquema de respuesta

**Archivos:** `api/authService.ts`, `api/profileService.ts`, `api/subscriptionService.ts`

**Problema 1 — Endpoints como strings literales dispersos:**
```typescript
// api/authService.ts línea 41 — hardcoded, no hay un punto centralizado
const { data } = await apiClient.post("/auth/register", payload);
```
Si cambia la versión de la API (`/v2/auth/register`), hay que buscar y reemplazar en N archivos.

**Fix:** Crear `api/endpoints.ts`:
```typescript
export const API = {
  auth: {
    register: "/auth/register",
    login:    "/auth/login",
    me:       "/users/me",
    logout:   "/auth/logout",
    // ...
  },
  profile: { update: "/users/me" },
  subscriptions: { plans: "/subscriptions/plans", me: "/subscriptions/me" },
} as const;
```

**Problema 2 — Respuestas tipadas como `any` en cambio de contraseña:**
```typescript
// api/authService.ts línea ~129
const response: any = await apiClient.post("/auth/change-password", ...);
```
Un error de shape en la respuesta no se detecta hasta runtime.

**Fix:** Definir el tipo de retorno explícito o usar Zod para parsear la respuesta en el boundary.

---

### 2.5 `goHub` en ProfileScreen — guarda silenciosa con lógica incorrecta

**Archivo:** `features/profile/ui/ProfileScreen.tsx:192–195`

```typescript
const goHub = useCallback(() => {
  if (isDirty && !handleSave()) return;  // ← handleSave() es async; devuelve Promise, no boolean
  setViewMode("hub");
}, [handleSave, isDirty]);
```

`handleSave` retorna `Promise<boolean>` pero se usa como síncrono. El `!handleSave()` siempre es truthy (una Promise es truthy), así que el guard nunca bloquea la navegación.

**Fix:**
```typescript
const goHub = useCallback(async () => {
  if (isDirty) {
    const saved = await handleSave();
    if (!saved) return;
  }
  setViewMode("hub");
}, [handleSave, isDirty]);
```

---

## P3 — Bajo (next iteration / tech debt)

### 3.1 Rutas placeholder con lógica inline en `app/(tabs)/`

**Archivos:** `app/(tabs)/chatbot.tsx`, `movimiento.tsx`, `movimientos.tsx`, `presupuesto.tsx`

Cada uno tiene un componente de pantalla completo inline (~20 líneas con StyleSheet). Cuando llegue el sprint de implementación real, esto se tendría que reescribir de cero.

**Fix progresivo:** Mover cada placeholder a `features/<nombre>/ui/<Nombre>Screen.tsx` con el mismo contenido. La ruta queda como 2-line delegate desde ahora, y cuando llegue el sprint solo se reemplaza el contenido del Screen.

---

### 3.2 Strings de UI hardcodeadas en pantallas

**Archivos:** múltiples pantallas de `features/profile/ui/`

Subtítulos, labels de secciones y mensajes como `"Mantén tus datos al día..."`, `"Seguridad"`, `"Personaliza tus alertas..."` están como literales en el código. No hay soporte i18n planeado hoy, pero extraerlos a `constants/strings.ts` simplifica futuros cambios de copy sin tocar lógica.

**Fix:** Crear `constants/strings.ts` con objetos por módulo:
```typescript
export const strings = {
  profile: {
    hubSubtitle: "Mantén tus datos al día para que Walvy trabaje mejor por ti.",
    darkModeHint: "Si prefieres una interfaz visualmente más cómoda...",
    // ...
  },
} as const;
```

---

### 3.3 `as never` en `router.push` / `router.replace` (20 instancias)

**Archivos:** múltiples hooks y pantallas

```typescript
router.push("/change-password" as never);  // ← cast para silenciar TS
```

**Por qué ocurre:** Expo Router genera un tipo estricto `Href` pero solo cuando hay un archivo `expo-env.d.ts` con `typedRoutes: true` en el config. Con esa opción activa, el cast desaparece.

**Fix:** En `app.json` / `app.config.js`:
```json
{ "expo": { "experiments": { "typedRoutes": true } } }
```
Después regenerar `expo-env.d.ts` con `npx expo customize` y eliminar los `as never`.

**Riesgo:** Es un breaking change que puede descubrir paths incorrectos actualmente silenciados.

---

### 3.4 Console logs en producción (17 instancias en `AuthProvider`)

**Archivo:** `store/AuthProvider.tsx`

Todos usan el prefijo `[Auth]` — aceptable para desarrollo, pero en producción generan noise en servicios de monitoreo (Sentry, Datadog).

**Fix:** Envolver en utilidad de log:
```typescript
// utils/logger.ts
const isDev = __DEV__;
export const log = {
  auth: (...args: unknown[]) => isDev && console.log("[Auth]", ...args),
  api:  (...args: unknown[]) => isDev && console.log("[API]",  ...args),
};
```

---

### 3.5 Falta `useBackHandler` para Android en vista "datos" de ProfileScreen

**Archivo:** `features/profile/ui/ProfileScreen.tsx`

Cuando el usuario está en `viewMode === "datos"` y presiona el botón físico "Atrás" de Android, la navegación va hacia atrás en el stack (sale del perfil) en lugar de volver al hub.

**Fix:**
```typescript
import { BackHandler } from "react-native";

useEffect(() => {
  if (viewMode !== "datos") return;
  const sub = BackHandler.addEventListener("hardwareBackPress", () => {
    goHub();
    return true; // consume el evento
  });
  return () => sub.remove();
}, [viewMode, goHub]);
```

---

### 3.6 Accesibilidad: falta `accessibilityHint` en acciones destructivas

**Archivo:** `features/profile/ui/ProfileScreen.tsx` botón "Cerrar sesión"

El `AppButton` de logout tiene `testID` pero no `accessibilityHint`. Screen readers no dan contexto de la consecuencia de la acción.

**Fix:**
```tsx
<AppButton
  title="Cerrar sesión"
  accessibilityHint="Cierra tu sesión activa y te redirige al inicio de sesión"
  onPress={handleLogout}
  // ...
/>
```

---

## Hallazgos positivos (a mantener)

- ✅ **Feature-First correctamente implementado** — todas las capas respetan el orden `ui/ → hooks/ → data/ → api/`. Cero violaciones detectadas entre las 5 features.
- ✅ **Todas las rutas de `app/` son 2-line delegates** — pantallas implementadas correctamente.
- ✅ **Mock mode robusto** — `EXPO_PUBLIC_USE_MOCK_MODE` + health probe con fallback automático. Los mocks mantienen la misma firma que los servicios reales.
- ✅ **Tokens de tema bien estructurados** — `colors.ts` documenta cada token con referencia a Figma. Los tokens nuevos para perfil (`profileCyanAccent`, `profileIconSlot`, etc.) están definidos en ambos modos.
- ✅ **Animaciones de entrada con `Animated.parallel`** — correcto, no usa `useNativeDriver` cuando no corresponde.
- ✅ **Logs con prefijo** — todos los `console.log` tienen `[Tag]` prefix, no hay logs sueltos en producción.
- ✅ **`WalvyTabBar` completo** — emite `tabPress` y `tabLongPress` correctamente, `onLongPress` implementado.
- ✅ **Tests de rutas actualizados** — `profile.test.tsx` refleja el nuevo flujo hub → datos.

---

## Deuda técnica total (estimado de esfuerzo)

| Item | Esfuerzo | Sprint |
|---|---|---|
| Mover `AuthBlobBackground` a `components/` | 1h | Próximo |
| Añadir 4 tokens faltantes a `colors.ts` | 30m | Próximo |
| Usar `theme.profileIconSlot` en lugar de `ICON_SLOT_LIGHT_BG` | 15m | Próximo |
| Fix `goHub` async | 15m | Urgente |
| `api/endpoints.ts` centralizado | 2h | Sprint 2 |
| Tests para hooks y datos | 1 día | Sprint 2 |
| `typedRoutes: true` + eliminar `as never` | 2h | Sprint 3 |
| Mover placeholders a `features/` | 1h | Antes de cada sprint |
| `useBackHandler` Android | 30m | Sprint 2 |
| `constants/strings.ts` | 3h | Sprint 3 |
| Logger utility | 1h | Sprint 3 |
