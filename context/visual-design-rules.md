# Visual Design Rules — Walvy

Reglas de referencia para auditorías visuales. Cubren tokens de color, tipografía, componentes y dark mode.
Todo cambio de UI debe verificarse contra este documento.

**Fuente de verdad de tokens:** `front-walvy/expo/constants/colors.ts`
**Figma file key:** `v45c4HTKnPnU0XABMa5vjY`

---

## 1. Tokens de color — light → dark

| Token (`theme.X`) | Light | Dark | Notas |
|---|---|---|---|
| `bg` | `#FAF9F6` | `#1F2A33` | Fondo global |
| `card` | `#FFFFFF` | `#2C3A46` | Cards, modales, inputs |
| `inputBg` | `#FFFFFF` | `#1F2A33` | Fondo de inputs |
| `border` | `#E5E7EB` | `#506372` | Bordes y dividers |
| `textHeading` | `#103F43` | `#CDECE2` | H1/H2 |
| `textPrimary` | `#374151` | `rgba(205,236,226,0.8)` | Body texto |
| `textSecondary` | `#4B5563` | `rgba(205,236,226,0.55)` | Subtítulos |
| `textMuted` | `#6B7280` | `rgba(205,236,226,0.35)` | Captions |
| `authBg` | `#FFFCFA` | `#1F2A33` | Fondo auth screens |
| `authLinkText` | `#177E96` | `#CDECE2` | Links y botones terciarios |
| `authMutedText` | `rgba(31,42,51,0.8)` | `rgba(205,236,226,0.55)` | Textos de pie en auth |
| `authDisplayAccent` | `#103F43` | `#33AEA8` | Títulos de auth screens |
| `inputLabelText` | `#3F484A` | `rgba(205,236,226,0.55)` | Labels de inputs figmaLogin |
| `inputPlaceholderText` | `rgba(16,63,67,0.6)` | `rgba(205,236,226,0.35)` | Placeholder figmaLogin |
| `profileCyanAccent` | `#1B6B73` | `#33AEA8` | Acento cyan perfil e íconos |
| `profileTabInactiveTint` | `#103F43` | `rgba(51,174,168,0.6)` | Tab bar ítem inactivo |
| `profileHubRowTitle` | `#103F43` | `#FFFCFA` | Título de fila en hub |
| `profileHubRowHint` | `rgba(31,42,51,0.8)` | `#E2E0DA` | Subtítulo de fila en hub |
| `profileSectionTitle` | `rgba(16,63,67,0.8)` | `#33AEA8` | Heading de sección (Mis preferencias) |
| `profileIconSlot` | `#F6F6F6` | `#485C6C` | Fondo del slot 40×40 del ícono |
| `passwordRequirementsPanelBg` | `#F8F4ED` | `#1A2C2E` | Panel de requisitos de contraseña |
| `navBar` | `#FAF9F6` | `#1F2A33` | Fondo de la barra inferior |

---

## 2. Auth Screens — reglas compartidas

Aplica a: **Login**, **Register**, **ForgotPassword**, **ResetPassword**, **ChangePassword**, y cualquier pantalla futura que use `AuthScreenLayout`.

### 2.1 Layout y tamaños (iguales en light y dark)

| Elemento | Valor |
|---|---|
| Logo | `width: 160, height: 92` |
| Scroll `paddingTop` | `36` |
| Scroll `paddingHorizontal` | `16` |
| Card `borderRadius` | `16` |
| Card `padding` | `16` |
| Card `gap` entre inputs | `8` |
| Input `height` | `52` |
| Input `borderRadius` | `8` |
| Botón primario `height` | `40` |
| Botón primario `borderRadius` | `100` |

### 2.2 Tipografía (iguales en light y dark)

| Elemento | `fontFamily` | `fontSize` | Notas |
|---|---|---|---|
| Título de pantalla | `fontFamily.semiBold` | `24` | **NUNCA** `.bold`; lineHeight: 32 |
| Subtítulo | `fontFamily.display` | `16` | lineHeight: 16 |
| Label de input | `fontFamily.semiBold` | `12` | letterSpacing: 0.6 |
| Texto input placeholder | `fontFamily.regular` italic | `16` | Solo en estado vacío |
| Texto input filled | `fontFamily.semiBold` | `16` | Al tener valor |
| Botón primario | `fontFamily.semiBold` | `16` | |
| Link "¿Olvidaste?" | `fontFamily.semiBold` | `12` | |
| Link "¿Recordaste?" | `fontFamily.display` | `12` | No underline |
| "Inicia sesión" link | `fontFamily.semiBold` | `12` | underline |

### 2.3 Colores dinámicos (light → dark)

| Elemento | Light | Dark | Cómo |
|---|---|---|---|
| Título | `#103F43` | `theme.authDisplayAccent` | `isDark ? theme.authDisplayAccent : TITLE_COLOR` |
| Subtítulo | `rgba(31,42,51,0.8)` | `theme.textSecondary` | `isDark ? theme.textSecondary : SUBTITLE_COLOR` |
| Card background | `#FFFDFD` | `theme.card` | `isDark ? theme.card : CARD_BG` |
| Card border | `#E6DED2` | `theme.border` | `isDark ? theme.border : CARD_BORDER` |
| **Card shadowColor** | `#1B6B73` | `#202B35` | **INLINE**: `isDark ? "#202B35" : "#1B6B73"` — nunca hardcoded |
| Label de input | `#3F484A` | `rgba(205,236,226,0.55)` | `theme.inputLabelText` (automático) |
| Placeholder | `rgba(16,63,67,0.6)` | `rgba(205,236,226,0.35)` | `theme.inputPlaceholderText` (automático) |
| Texto filled | `theme.deepTeal` | `theme.textPrimary` | AppInput lo maneja |
| Input background | `#FFFCFA` | `theme.inputBg` | AppInput lo maneja |
| Input border | `#E6DED2` | `theme.border` | AppInput lo maneja |
| Input border activo | `#1B6B73` | `theme.border` | AppInput — en dark no hay diferencia visual |
| Links terciarios | `theme.authLinkText` | `theme.authLinkText` | Automático por token |
| Texto muted de pie | `theme.authMutedText` | `theme.authMutedText` | Automático por token |
| Botón primario bg | `#1B6B73` | `#1B6B73` | Igual en ambos modos |
| Botón disabled | `rgba(27,107,115,0.3)` | `rgba(27,107,115,0.3)` | Igual en ambos modos |

### 2.4 Estados de error (AppInput con `figmaLogin`)

| Elemento | Valor | Modo |
|---|---|---|
| Border de error | `#E9B9BF` | Mismo en light y dark |
| Texto de error | `#BD4756` | Mismo en light y dark |

### 2.5 Modales de auth

| Elemento | Light | Dark |
|---|---|---|
| Card background | `#FFFCFA` | `theme.card` |
| Card border | `#E6DED2` | `theme.border` — **INLINE**, no en StyleSheet |
| Mascota circle bg | `#F2EFE9` | `theme.card` — **INLINE** |
| Overlay | `rgba(0,0,0,0.55)` | `rgba(0,0,0,0.55)` |

---

## 3. Componente AppInput (`figmaLogin`)

| Propiedad | Comportamiento |
|---|---|
| `labelColor` | Siempre `theme.inputLabelText` — no aplicar `isDark` propio |
| `labelFigma.fontFamily` | `fontFamily.semiBold` (SemiBold 600, no Bold 700) |
| `labelFigma.fontSize` | `12` |
| `labelFigma.letterSpacing` | `0.6` |
| Placeholder | italic (`fontStyle: "italic"`) mientras `!filled` |
| Texto filled | `fontFamily.semiBold`, no italic |
| Android dark | `backgroundColor: "transparent"` en el TextInput |

---

## 4. Tab Bar (`WalvyTabBar`)

| Elemento | Light | Dark |
|---|---|---|
| Tint activo | `theme.oceanTeal (#1B6B73)` | `theme.profileCyanAccent (#33AEA8)` |
| Tint inactivo | `theme.deepTeal (#103F43)` | `theme.profileTabInactiveTint (rgba(51,174,168,0.6))` |
| Background | `theme.authBg (#FFFCFA)` | `theme.navBar (#1F2A33)` |
| Border top | `theme.coral` | `theme.coral` |
| noTabFocused | — | Usar `activeTint` para todos los ítems visibles |

> **noTabFocused**: cuando la ruta activa es una tab oculta (ej. perfil), ningún ítem visible queda "focused" → todos mostrarían `inactiveTint` apagado. Detectar con `!TAB_VISUALS.some(t => t.name === state.routes[state.index]?.name)` y usar `activeTint` como fallback.

---

## 5. Profile Hub

### 5.1 Cards

| Elemento | Light | Dark |
|---|---|---|
| Card background | `theme.card` | `theme.card (#2C3A46)` |
| Card border | `theme.border` | `theme.border (#506372)` |
| Card shadow | `cardShadow` (styles) | `hubCardShadowDark` (styles) |
| `overflow` | **Nunca `"hidden"`** | Bloquea shadows iOS |

### 5.2 DarkModeToggle

| Estado | Track bg | Border | Thumb |
|---|---|---|---|
| Dark ON | `theme.bg (#1F2A33)` | `theme.profileCyanAccent (#33AEA8)` | `theme.profileCyanAccent` |
| Dark OFF | `theme.bg (#1F2A33)` | `theme.border (#506372)` | `theme.border` |
| Light ON | `theme.oceanTeal` | `theme.oceanTeal` | `theme.oceanTeal` |
| Light OFF | `#FFFCFA` | `#E6DED2` | `#E6DED2` |

---

## 6. Register — Checkboxes

| Estado | Light | Dark |
|---|---|---|
| Checked border | `theme.oceanTeal` | `theme.oceanTeal` |
| Checked bg | `theme.oceanTeal` | `theme.oceanTeal` |
| Unchecked border | `rgba(27,107,115,0.4)` | `theme.border` |
| Unchecked bg | `rgba(230,222,210,0.4)` | `transparent` |
| Label texto | `rgba(0,82,89,1)` | `theme.textPrimary` |

---

## 7. Checklist de bugs recurrentes

Verificar en TODA pantalla antes de subir cambios de UI:

| # | Bug | Verificación |
|---|---|---|
| B01 | **Logo tamaño incorrecto** | `width: 160, height: 92` en auth screens |
| B02 | **Título con `fontFamily.bold`** | Debe ser `fontFamily.semiBold` (SemiBold 600, no Bold 700) |
| B03 | **`shadowColor` hardcoded `#1B6B73`** | Mover a inline style: `isDark ? "#202B35" : "#1B6B73"` |
| B04 | **`overflow: "hidden"` en card con shadow** | Eliminar; bloquea shadows en iOS |
| B05 | **Checkbox unchecked en dark con beige** | `bg: transparent`, `border: theme.border` |
| B06 | **Modal card border hardcoded** | `borderColor: isDark ? theme.border : "#E6DED2"` inline |
| B07 | **Mascota circle bg hardcoded** | `backgroundColor: isDark ? theme.card : "#F2EFE9"` inline |
| B08 | **Label input con `authDisplayTypography`** | No mezclar; siempre `theme.inputLabelText` sin overrides |
| B09 | **Tab bar sin `noTabFocused`** | Al navegar a tab oculta, todos los ítems deben mostrar `activeTint` |
| B10 | **Hex inline en JSX** | Usar tokens de `theme.*`; hex solo para constantes declaradas arriba del componente |

---

## 8. Referencia rápida — cómo leer los tokens en código

```tsx
// ✅ Correcto
const { theme, isDark } = useTheme();
const titleColor = isDark ? theme.authDisplayAccent : TITLE_COLOR;
const shadowColor = isDark ? "#202B35" : "#1B6B73"; // inline en style={}

// ❌ Incorrecto
shadowColor: "#1B6B73"  // en StyleSheet.create — no puede ser dinámico
fontFamily: fontFamily.bold  // en títulos de auth — debe ser .semiBold
width: 220, height: 82  // logo auth — debe ser 160×92
```
