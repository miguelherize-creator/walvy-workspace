# 🔍 UI Visual QA — `/login` savedUserBiometric (LoginScreen — modo biometric)

**Figma principal:** `3470:7080` (Login con usuario guardado + biometría)
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-05-31
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score

**90 / 100**

### Estado General

✅ **Aprobado con observaciones**

---

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|----------|-----------|
| 1 | **Título 1 línea vs 2 líneas Figma**: "Te damos la bienvenida" en lugar de "¡Hola Juancho!\nTe damos la bienvenida" — porque `firstName` viene vacío del backend/mock | Media |
| 2 | **Distribución vertical**: el botón "Entrar" debe quedar más cerca del centro/abajo (justify-between Figma). Actualmente queda pegado al subtitle | Media |
| 3 | Tamaño táctil botón Entrar (40px alto): por debajo de 44px | Baja |

---

### Recomendaciones

#### Prioridad Media

- **Bug `firstName` vacío** (mismo que en savedUserPassword): debug del flujo de datos
  - Verificar que `user.firstName` se persista correctamente en AsyncStorage
  - Verificar el mock backend / seed user
  - El código ya tiene la lógica condicional correcta:
    ```tsx
    isBiometricMode && firstName
      ? `¡Hola ${firstName}!\nTe damos la bienvenida`
      : "Te damos la bienvenida"
    ```

- **Distribución vertical (justify-between)**: replicar el comportamiento del Figma. Opciones:
  - **A)** Añadir `<View style={{ flex: 1 }} />` entre el welcomeBlock y el CTA group cuando `isBiometricMode` ⭐ (más simple)
  - **B)** Cambiar el layout del scroll para usar `justifyContent: "space-between"` cuando `isBiometricMode`
  - **C)** Aplicar `marginTop: "auto"` al CTA group en biometric mode

#### Prioridad Baja

- **Touch target botón Entrar:** consideración general del design system (40 → 44)

---

## ✅ Logros aplicados (8 fixes confirmados visualmente)

| # | Fix | Verificación |
|---|-----|--------------|
| 1 | Nuevo modo `savedUserBiometric` añadido | ✅ Pantalla distinta del savedUserPassword |
| 2 | NO card de inputs | ✅ No aparece password field |
| 3 | Subtítulo "Ingresa para ver tus metas..." | ✅ Texto correcto |
| 4 | Botón "Entrar" enabled solid teal | ✅ Visible |
| 5 | Link "Ingresar con clave" | ✅ Texto + 16px |
| 6 | Footer "¿Eres nuevo por acá?" | ✅ Texto correcto |
| 7 | Footer link "Crea tu cuenta gratis" 12px | ✅ Visible (más pequeño que 14px del modo regular) |
| 8 | `hitSlop` añadido al link "Ingresar con clave" | ✅ Aplicado en código |

---

## 🐛 Bug fix transversal: auto-detección de savedUser

**Antes:** El hook recibía `isSavedUser: false` cuando `user.email` estaba vacío, aunque `canUseBiometric` fuera true. Esto disparaba la validación "Ingresa tu correo electrónico" incorrectamente.

**Después:** El hook auto-detecta `isSavedUser = canUseBiometric || !!user?.email`. Cubre 3 escenarios:
- ✅ Biometría disponible + email guardado → savedUser
- ✅ Biometría disponible + email vacío → savedUser (no valida campo email inexistente)
- ✅ Sin biometría + email guardado → savedUser
- ✅ Sin biometría + sin email → firstTime (valida normalmente)

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Logo: posición y align | Top-left, `pt-36 px-16`, `220×82` | Match | OK | — |
| Container | `flex-col items-center` | Match | OK | — |
| Main section | `flex-1 px-16 py-36 justify-between` | `flex-1` con gap del scroll | Diferencia Media | Media |
| Distribución vertical (justify-between) | Title arriba / CTA centro / Footer abajo (3 zonas) | Title + CTA juntos arriba / Footer abajo (2 zonas) | Diferencia Media | Media |
| Title block | `col gap-8 items-start` | Match | OK | — |
| NO card | Sin card de inputs | NO card ✅ FIX APLICADO | OK | — |
| CTA group | `col gap-24 items-center` | Match | OK | — |
| Footer | `pt-60` centrado | Match | OK | — |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Title (2 líneas) | "¡Hola Juancho!\nTe damos la bienvenida" | "Te damos la bienvenida" (firstName vacío) | Diferencia Media | Media |
| Title style | Aptos SemiBold 24px `#103F43` lh-32 | Match | OK | — |
| Subtitle | "Ingresa para ver tus metas y mantener tus deudas bajo control." | Match ✅ FIX APLICADO | OK | — |
| Subtitle style | Aptos Display 16px rgba(31,42,51,0.8) lh-16 | Match | OK | — |
| Botón "Entrar" texto | Aptos SemiBold 16px `#FFFCFA` | Match | OK | — |
| Link "Ingresar con clave" | Aptos SemiBold 16px `#177E96` underline | Match ✅ FIX APLICADO | OK | — |
| Footer "¿Eres nuevo por acá?" | Aptos Display 12px rgba(31,42,51,0.8) text-center | Match ✅ FIX APLICADO | OK | — |
| Footer link "Crea tu cuenta gratis" | Aptos SemiBold 12px `#177E96` underline | 12px ✅ FIX APLICADO | OK | — |

### Fase 3 — Colores

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Background pantalla | `#fffcfa` | `#FFFCFA` | OK | — |
| Title color | `#103f43` | Match | OK | — |
| Subtitle color | `rgba(31,42,51,0.8)` | Match | OK | — |
| Botón "Entrar" bg ENABLED | `#1b6b73` | `#1B6B73` ✅ | OK | — |
| Botón texto | `#fffcfa` | Match | OK | — |
| Link "Ingresar con clave" | `#177e96` | `#177E96` | OK | — |
| Footer prompt | `rgba(31,42,51,0.8)` | Match | OK | — |
| Footer link | `#177e96` | Match | OK | — |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Logo WalvyLogo | `220×82` con tagline | Match ✅ | OK | — |
| Card de inputs | NO EXISTE en biometric mode | NO renderizada ✅ FIX APLICADO | OK | — |
| Botón "Entrar" | h-40, rounded-100, w-361, ENABLED solid | h-40, rounded-100, maxWidth 361, ENABLED | OK | — |
| Link "Ingresar con clave" wrapper | h-24, px-8 py-12.5, rounded-100 | minHeight: 24 + `hitSlop` añadido ✅ FIX APLICADO | OK | — |
| Footer prompt + link | column items-center | Match | OK | — |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| pt header (logo) | 36px | Match | OK | — |
| Logo → title | py-36 main | Match | OK | — |
| Title ↔ Subtitle | gap-8 | Match | OK | — |
| Subtitle → Botón "Entrar" | Variable (flex-1 + justify-between) | 40px fijo (form.gap) | Diferencia Media | Media |
| Botón → "Ingresar con clave" | gap-24 | Match | OK | — |
| "Ingresar con clave" → Footer | flex-1 + pt-60 | Match | OK | — |
| px container | 16px | Match | OK | — |
| py main | 36px | Match | OK | — |

### Fase 6 — Responsive

| Aspecto | Figma | Implementación (Android Samsung) | Estado | Severidad |
|---|---|---|---|---|
| Viewport reference | 393×852 | ~360×~780 dp | OK | — |
| Status bar | No visible | Visible | OK | — |
| Sin overflow | n/a | Sin overflow | OK | — |
| Subtitle wrap | 2 líneas natural | 2 líneas | OK | — |
| CTA position vertical | ~55-60% desde top (centrado) | ~35-40% desde top (pegado al subtitle) | Diferencia Media | Media |

### Fase 7 — Accesibilidad

| Aspecto | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Contraste title | 13.4:1 | Idéntico | OK | — |
| Contraste subtitle | 7.1:1 | Idéntico | OK | — |
| Contraste botón ENABLED | 6.8:1 | Idéntico | OK | — |
| Tamaño táctil botón Entrar | 40px (mínimo 44) | 40px | Diferencia Menor | Baja |
| Tamaño táctil link "Ingresar con clave" | 24px alto | 24px alto + `hitSlop` extendido ✅ FIX APLICADO | OK | — |
| Tamaño táctil footer link | 24px alto | 24px alto + `hitSlop` | OK | — |
| Jerarquía visual | Logo > Title > Subtitle > CTA > Link > Footer | Match (excepto título 1 línea) | Diferencia Menor | Baja |

---

## 🏁 Veredicto

Pantalla de login biometric **APROBADA con observaciones**. La implementación funcional es correcta. Los 2 issues Media son:

1. **Bug de datos** (firstName vacío) — afecta solo el contenido del título, no la estructura
2. **Distribución vertical** del CTA — el botón "Entrar" debería quedar más centrado verticalmente (matching justify-between del Figma)

Con esos 2 fixes, el score subiría a ~97/100.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-05-31 (#1) | **90/100** | ✅ Implementación nueva del modo biometric. 8 elementos del Figma aplicados correctamente. 2 issues Media: firstName vacío + distribución vertical del CTA. |
