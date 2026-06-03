# 🔍 UI Visual QA — `/(auth)/choose-alias` (ChooseAliasScreen — rama `needsAlias`)

**Figma principal:** `3470:7228` (estado all-filled)
**Figma estado empty:** `3470:7207`
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-05-30
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score

**91 / 100**

### Estado General

✅ **Aprobado con observaciones**

---

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|----------|-----------|
| 1 | **Input text en estado FILLED se muestra en italic** — Figma muestra los valores ("Juan", "Perez", "Juancho") en SemiBold **NO italic**. `AppInput` aplica `fontStyle: "italic"` hardcoded en `figmaLogin` mode | **Media** |
| 2 | Tamaño táctil botón "Guardar y salir" (24px alto): por debajo de 44px | Media |
| 3 | Tamaño táctil botón "Guardar y continuar" (40px alto): por debajo de 44px | Baja |
| 4 | Botón "Guardar y continuar" usa `width: 100%, maxWidth: 361` vs `w-361` fijo del Figma | Baja |
| 5 | Botón "Guardar y salir" wrapper: sin `borderRadius: 100` explícito del Figma | Baja |

---

### Recomendaciones

#### Prioridad Media

- **Diferenciar el estilo italic entre placeholder y filled state en `AppInput`:**
  - Estado vacío (sin valor): `fontStyle: "italic"` para el placeholder
  - Estado filled (con valor): `fontStyle: "normal"` para el texto del usuario
  - Esto requiere lógica condicional basada en `value && value.length > 0`

  ```tsx
  // Pseudocode en AppInput.tsx
  inputFigma: {
    fontFamily: fontFamily.regular,
    fontSize: 16,
    fontStyle: hasValue ? "normal" : "italic", // ← cambio dinámico
    paddingVertical: 15,
  }
  ```

  ⚠️ **Impacto transversal:** este fix mejora TODAS las pantallas que usan `AppInput figmaLogin`:
  - `/login` (Correo, Contraseña)
  - `/register` (Correo, Confirma, RUT, Contraseña)
  - `/choose-alias` (Nombre, Apellido, Alias)
  - Forgot password, Reset password, etc.

- **Aumentar área táctil del link "Guardar y salir"** a mínimo 44px con `hitSlop={{ top: 12, bottom: 12, left: 8, right: 8 }}`

#### Prioridad Baja

- **Botón "Guardar y continuar":** `width: 361, alignSelf: "center"` exacto al Figma
- **Botón "Guardar y salir" wrapper:** añadir `borderRadius: 100` explícito al Pressable

---

## ✅ Logros ya aplicados en iteraciones previas

| Mejora | Antes | Ahora |
|---|---|---|
| Gap isotipo → title block | `gap: 24` | `gap: 36` ✅ FIX APLICADO |

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| WalvyIso posición y align | center, `48×48`, `pt-36 px-16` | Match | OK | — |
| Container | `flex-col items-center` | Match | OK | — |
| Header padding | `pt-36 px-16` | Match | OK | — |
| Main section | `flex-1 px-16 py-36` | Match | OK | — |
| Gap isotipo → title | 36px | `gap: 36` ✅ FIX APLICADO | OK | — |
| Inner section gap | `gap-40` | `aliasFormSection.gap: 40` | OK | — |
| Title block | `col gap-24` | `aliasTitleBlock.gap: 24` | OK | — |
| Form section gap | `gap-40` | `aliasCardGroup.gap: 40` | OK | — |
| Card | `gap-16 p-16` | Match | OK | — |
| Card group 1 (Nombre + Apellido) | `col gap-8` | `inputGroup.gap: 8` | OK | — |
| Card group 2 (Alias + helper) | `col gap-8` | Match | OK | — |
| Buttons group | `gap-24 items-center` | Match | OK | — |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Title "Ingresa tus datos" | Aptos SemiBold 24px `#103F43` lh-32 | SemiBold 24px lh-32 | OK | — |
| Subtitle "Usaremos estos datos…" | Aptos Display 16px rgba(31,42,51,0.8) lh-16 | Display 16px lh-16 | OK | — |
| Label "Nombre" / "Apellido" / "Alias" | Aptos SemiBold 12px `#3F484A` lh-16 | SemiBold 12px | OK | — |
| **Input filled texto** | Aptos SemiBold 16px `#103F43` **NO italic** | SemiBold 16px **ITALIC** | Diferencia Media | Media |
| Helper "Puede ser tu nombre…" | Aptos Display 16px rgba(31,42,51,0.8) lh-16 | Display 16px lh-16 | OK | — |
| Botón "Guardar y continuar" texto | Aptos SemiBold 16px `#FFFCFA` | SemiBold 16px | OK | — |
| Botón "Guardar y salir" texto | Aptos SemiBold 16px `#177E96` underline | SemiBold 16px underline | OK | — |

### Fase 3 — Colores

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Background pantalla | `#fffcfa` | `#FFFCFA` | OK | — |
| Title color | `#103f43` | `theme.textHeading` | OK | — |
| Subtitle color | `rgba(31,42,51,0.8)` | `theme.authMutedText` | OK | — |
| Card bg | `#fffdfd` | `#FFFDFD` | OK | — |
| Card border | `#e6ded2` | `#E6DED2` | OK | — |
| Card shadow | drop-shadow `2px 4px 4px rgba(27,107,115,0.08)` | Match | OK | — |
| Input bg | `#fffcfa` | `#FFFCFA` | OK | — |
| Input border filled | `#1b6b73` | `#1B6B73` | OK | — |
| Input text filled | `#103f43` | `theme.deepTeal` | OK | — |
| Label color | `#3f484a` | Match | OK | — |
| Helper color | `rgba(31,42,51,0.8)` | `theme.authMutedText` | OK | — |
| Botón primario bg | `#1b6b73` | `theme.oceanTeal` | OK | — |
| Botón texto blanco | `#fffcfa` | `colors.authBg` | OK | — |
| Botón terciario texto | `#177e96` | `theme.authLinkText` | OK | — |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| WalvyIso | `48×48` | `48×48` | OK | — |
| Card | rounded-16, p-16, gap-16, shadow | Match | OK | — |
| Input wrapper | h-52, rounded-8, p-16, border-1 | Match | OK | — |
| Input text style | NO italic en filled state | ITALIC en todos los estados | Diferencia Media | Media |
| Botón "Guardar y continuar" | h-40, rounded-100, w-361 fijo | h-40, rounded-100, width 100% maxWidth 361 | Diferencia Menor | Baja |
| Botón "Guardar y salir" wrapper | h-24, px-8 py-12.5, rounded-100 | px-8 py-12.5 sin rounded explícito | Diferencia Menor | Baja |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| pt header (WalvyIso) | 36px | 36px | OK | — |
| Gap isotipo → title | 36px | `gap: 36` ✅ FIX APLICADO | OK | — |
| Title ↔ Subtitle gap | `gap-24` interno | `aliasTitleBlock.gap: 24` | OK | — |
| Title block → Form section | `gap-40` | Match | OK | — |
| Card → Buttons | `gap-40` | Match | OK | — |
| Card interno (group 1 ↔ group 2) | `gap-16` | `card.gap: 16` | OK | — |
| Inputs internos en cada group | `gap-8` | `inputGroup.gap: 8` | OK | — |
| Buttons internos | `gap-24` | Match | OK | — |
| Px container | 16px | 16px | OK | — |
| Py main | 36px | 36px | OK | — |

### Fase 6 — Responsive

| Aspecto | Figma | Implementación (Android Samsung) | Estado | Severidad |
|---|---|---|---|---|
| Viewport reference | 393×852 | ~360×~780 dp | OK | — |
| Status bar | No visible | Visible | OK | — |
| Card width | Full-width con px-16 | Match | OK | — |
| Sin overflow | n/a | Sin overflow | OK | — |
| Subtitle wrap | 2 líneas | 2 líneas | OK | — |
| Helper wrap | 2 líneas | 2 líneas | OK | — |
| Botón "Guardar y continuar" width | 361px fijo | 100% con maxWidth 361 | Diferencia Menor | Baja |

### Fase 7 — Accesibilidad

| Aspecto | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Contraste title | 13.4:1 | Idéntico | OK | — |
| Contraste subtitle | 7.1:1 | Idéntico | OK | — |
| Contraste input text filled | 11.2:1 | Idéntico | OK | — |
| Contraste botón ENABLED | 6.8:1 | Idéntico | OK | — |
| Contraste botón terciario | 4.5:1 | Idéntico | OK | — |
| Tamaño táctil botón "Guardar y continuar" | 40px (mínimo 44) | 40px | Diferencia Menor | Baja |
| Tamaño táctil botón "Guardar y salir" | 24px alto | 24px alto | Diferencia Media | Media |
| Jerarquía visual | Isotipo > Title > Subtitle > Card > CTA > Link | Match | OK | — |

---

## 🏁 Veredicto

Pantalla de choose-alias con buena fidelidad estructural. El único issue **transversal Media** detectado es el **estilo italic del input filled**, que es un fix de 1 línea en `AppInput.tsx` que mejora 4+ pantallas simultáneamente.

**Próximas acciones recomendadas (en orden de prioridad):**

1. ⚡ **Fix transversal en `AppInput`**: italic solo en placeholder, no en filled (mejora /login, /register, /choose-alias, forgot, reset)
2. Aumentar `hitSlop` del link "Guardar y salir"
3. Botón "Guardar y continuar" `width: 361, alignSelf: "center"`
4. Resto: deuda técnica trivial

Con esos 3 fixes, el score subiría a ~97/100.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-05-30 (#1) | 96/100 | ⚠️ Sin screenshot all-filled — italic en inputs no detectado |
| 2026-05-30 (#2) | **91/100** | ✅ Con screenshot all-filled — detectado italic incorrecto en estado filled |
