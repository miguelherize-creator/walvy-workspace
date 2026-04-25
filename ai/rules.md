# Rules — Cómo trabajar en el repo Walvy

Reglas operativas para código y producto. Junto con `CLAUDE.md` y `ai/context.md`.

## Jerarquía de fuentes

1. **MVP:** `utils/organizacion/docs/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`
2. **Convenciones técnicas:** `CLAUDE.md`
3. **Contexto y estado:** `ai/context.md`
4. **UI/UX:** esta misma sección (alineada a `expo/constants/colors.ts` y `theme.ts`)

---

## Backend (`Backend/backend`)

- DTOs + **class-validator** en el límite HTTP; no sustituir solo por lógica en servicios.
- Un **módulo por feature** (`auth`, `users`, `cashflow`, …).
- **Contraseñas:** reglas en DTOs de usuarios (8+ chars, mayúscula, minúscula, número, especial).
- **JWT:** access + refresh, refresh hasheado y rotación.
- **TypeORM:** sync en dev; migraciones en producción (salvo `DB_SYNC` transitorio acordado).
- **Health:** no autenticar `GET /health` ni el `GET /` informativo; mantenerlos ligeros para el probe del cliente.

---

## Frontend (`Frontend/rork-checkapp/expo`)

### Arquitectura — Feature-First

La regla más importante: **toda la lógica y UI de un módulo vive en `features/<nombre>/`**. Los archivos en `app/` son delegates de 2 líneas.

#### Capas y sus responsabilidades

| Capa | Archivo | Puede importar |
|------|---------|----------------|
| `ui/` | `<X>Screen.tsx` | `hooks/`, `@/components/`, `@/constants/`, librerías UI |
| `hooks/` | `use<X>.ts` | `data/`, `@/store/`, `@/utils/` |
| `data/` | `<X>Repository.ts` | `@/api/` únicamente |
| `api/` | `xService.ts` | `api/client`, `api/config`, `api/mocks/` |

#### Regla de dependencias (solo hacia abajo)

```
ui/ → hooks/ → data/ → api/
```

- `api/` **no conoce** `features/`.
- `features/` distintas **no se importan entre sí** directamente; se comunican a través de `@/store/` o `@/utils/`.
- Nunca importar desde una capa "superior" a la actual.

#### Contratos públicos (`index.ts`)

Cada feature expone solo lo necesario en su `index.ts` raíz. El resto son detalles de implementación privados:

```typescript
// features/profile/index.ts — solo lo que el exterior necesita
export { ProfileScreen, SettingsScreen } from "./ui";
```

#### Delegates en `app/`

```typescript
// app/profile.tsx — exactamente 2 líneas
import { ProfileScreen } from "@/features/profile";
export default ProfileScreen;
```

### Imports

- Siempre **`@/`** para imports cross-feature o cross-layer: `import { useAuth } from "@/store/AuthProvider"`.
- Dentro de la misma feature, rutas relativas cortas: `import { updateProfile } from "../data/profileRepository"`.
- Nunca `../../..` ni imports relativos que salgan de `features/<nombre>/`.

### Validaciones

- **Genéricas** (email, password, extractApiErrorMessage): `@/utils/validation.ts`.
- **Específicas de un dominio** (ej. parseRegisterIdentifier): `features/<nombre>/utils/`.
- Los hooks hacen la validación; los screens no validan directamente.

### Naming

| Tipo | Convención | Ejemplo |
|------|------------|---------|
| Screens | PascalCase + `Screen` | `ProfileScreen` |
| Hooks | camelCase + `use` | `useProfileForm` |
| Repository functions | camelCase verbo | `updateProfile()` |
| Constantes estáticas en screen | `UPPER_SNAKE` | `MENU_ITEMS` |

### Checklist para agregar una nueva feature

```
□ api/<nombre>Service.ts              — endpoints reales + isMockMode check
□ api/mocks/<nombre>Mock.ts           — implementación mock del service
□ api/mockService.ts                  — re-exportar nuevas funciones mock
□ features/<nombre>/data/<X>Repository.ts
□ features/<nombre>/hooks/use<X>.ts
□ features/<nombre>/ui/<X>Screen.tsx
□ features/<nombre>/ui/index.ts
□ features/<nombre>/index.ts          — contrato público
□ app/<nombre>.tsx                    — delegate 2 líneas
□ app/_layout.tsx                     — registrar Stack.Screen
□ app/__tests__/<nombre>.test.tsx     — tests de integración de pantalla
□ features/<nombre>/__tests__/        — tests de hook y componentes
```

### Tests

- Correr: `bun run test` (todos) / `bun run test --watch` / `bun run test --coverage`.
- Los tests de pantallas van en `app/__tests__/` e importan vía `@/app/<nombre>` (que delega a la feature).
- Los tests de componentes de una feature van en `features/<nombre>/__tests__/`.
- Los tests de componentes compartidos van en `components/__tests__/`.
- Usar `renderWithProviders` de `@/test/test-utils` (wrappea QueryClient + Theme + Auth).
- Mockear `expo-router`, `react-native-safe-area-context` y stores de auth en tests de screens.

### Bun

- Usar **Bun** en `expo/` para dependencias y scripts. No usar npm/yarn en el frontend.

---

## UI y UX — Walvy

**Fuente de verdad en código:** `expo/constants/colors.ts` y `expo/constants/theme.ts`.
**Assets de marca:** `expo/assets/images/walvy/`, kit en `utils/brand/Walvy_assets_cerrados_final/`.

### Paleta (no inventar hex fuera de esta tabla sin actualizar `colors.ts`)

> Fuente de verdad: Figma Design System v1.0 — node 2533:1056

#### Light Mode

| Token | Hex | Uso (sección DS) |
|--------|-----|------------------|
| `bg` | `#FAF9F6` | Fondo principal — Color Palette / Background |
| `card` / `modal` / `inputBg` | `#FFFFFF` | Superficies elevadas — Color Palette / Container |
| `border` | `#E5E7EB` | Divisores y bordes — Cards & Components |
| `inputBorder` | `#D1D5DB` | Borde de campos de texto |
| `textHeading` | `#103F43` | H1 (30px) / H2 (24px) / H3 (20px) — Typography |
| `textPrimary` | `#374151` | Body Regular 16px — Typography |
| `textSecondary` | `#4B5563` | Body Small 14px — Typography |
| `textMuted` | `#6B7280` | Caption 12px / hints — Typography |
| `cardTextPrimary` | `#374151` | Texto principal dentro de tarjetas |
| `cardTextSecondary` | `#4B5563` | Texto secundario dentro de tarjetas |
| `cardTextMuted` | `#6B7280` | Hints dentro de tarjetas |
| `navBar` | `#FAF9F6` | Fondo barra de navegación inferior |
| `deepTeal` | `#103F43` | Primary — botones, headers, íconos activos — Buttons |
| `oceanTeal` | `#1B6B73` | Mid teal (variantes, gradientes) |
| `mintSoft` | `#CDECE2` | Accent — bg botón secundario, badges de íconos — Buttons |
| `coral` | `#EE8D78` | **Único acento cálido** (un foco por pantalla) |
| `red` / `yellow` / `green` | `#D94452` / `#E5A82E` / `#16A34A` | Error / aviso / éxito (transacciones positivas) |

#### Dark Mode

| Token | Hex / rgba | Uso (sección DS) |
|--------|------------|------------------|
| `bg` | `#0D191A` | Fondo dark — Color Palette / Dark / Background |
| `card` / `modal` / `inputBg` | `#162A2C` | Container dark — Color Palette / Dark / Container |
| `border` | `#1E3538` | Borde sutil en dark |
| `inputBorder` | `#2A4548` | Borde de campos en dark |
| `textPrimary` | `rgba(205,236,226,0.8)` | Main Text 80% — Figma Dark Mode |
| `textSecondary` | `rgba(205,236,226,0.55)` | Secundario |
| `textMuted` | `rgba(205,236,226,0.35)` | Caption / hints |
| `cardTextPrimary` | `rgba(205,236,226,0.8)` | Texto en tarjetas dark |
| `navBar` | `#0D191A` | Barra inferior dark |
| `deepTeal` | `#103F43` | Botón primario + badge de ícono dark |

### Reglas de uso

- Usar tokens vía `useTheme()` en pantallas para que el dark mode aplique automáticamente. Evitar `colors.*` directos en JSX de pantallas.
- **Texto en tarjetas (dark mode):** dentro de `View` con fondo `theme.card`, usar `theme.cardTextPrimary` / `theme.cardTextSecondary`, no `theme.textPrimary`.
- **No** reintroducir el acento neón `#b6fc1e` como identidad principal.
- **Espaciado y radios:** usar `spacing.*` y `borderRadius.*` de `theme.ts`.
- **Tipografía:** tokens `fontSize` en `theme.ts`; System (SF / Roboto) como fallback.
- **Jerarquía:** un nivel claro título → cuerpo → secundario; no saturar con muchos pesos de coral/teal en la misma vista.

### Layout raíz

El `Stack` en `app/_layout.tsx` usa fondo acorde a la marca; nuevas pantallas deben alinearse a la misma base salvo modales u overlays.

---

## Base de datos (`DB/`)

Cambios de esquema: alinear `schema.sql` y entidades TypeORM simultáneamente.

---

## Alcance y calidad

- Cambios mínimos y enfocados; sin refactors masivos no pedidos.
- Tests: `npm test` / `npm run build` (backend), `bun run lint && bun run test` (frontend) según área tocada.
- **`utils/`:** respetar estructura `prompts-rork/`, `organizacion/`, etc.

---

## Comunicación al usuario (app)

Tono **orientativo**, sin asesoría certificada ni promesas de resultado (alineado al CSV).
