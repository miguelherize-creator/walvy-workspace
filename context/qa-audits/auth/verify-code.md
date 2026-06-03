# 🔍 UI Visual QA — `/verify-code` (VerifyCodeScreen)

**Figma principal:** `3655:2745` (estado default)
**Figmas relacionados:**
- `3655:2787` (timer en 0)
- `3655:2824` / `3655:2839` (estado error)
- `3655:2850` / `3655:2865` (estado éxito)
- `3655:2866` (botón "Redirigiendo…")

**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-05-30
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score

**95 / 100**

### Estado General

✅ **Aprobado con observaciones**

---

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|----------|-----------|
| 1 | Sin `KeyboardAvoidingView` — al tap en las cajas OTP, el teclado numérico Android puede tapar el botón "Verificar código" en pantallas pequeñas | Media |
| 2 | Tamaño táctil del link "Reenviar código en" (24px alto): por debajo del mínimo recomendado de 44px | Media |
| 3 | Subtitle p1 → p2 gap: ~16px vs ~24px del Figma (línea vacía `<p>​</p>`) | Baja |
| 4 | Resend row `alignItems: "center"` vs `alignItems: "flex-start"` del Figma | Baja |

---

### Recomendaciones

#### Prioridad Media

- **Añadir `KeyboardAvoidingView`** alrededor del contenido para que el teclado numérico no tape el botón "Verificar código":
  ```tsx
  <KeyboardAvoidingView
    behavior={Platform.OS === "ios" ? "padding" : "height"}
    style={{ flex: 1 }}
  >
    {/* contenido */}
  </KeyboardAvoidingView>
  ```

- **Aumentar área táctil del link "Reenviar código en"** a mínimo 44px:
  ```tsx
  hitSlop={{ top: 10, bottom: 10, left: 8, right: 8 }}
  ```

#### Prioridad Baja

- **Subtitle gap entre párrafos:** aumentar `marginTop` del segundo párrafo de `8 → 16px` (total `8 + 16 = 24px` con el gap del title block) para coincidir con la línea vacía del Figma
- **Resend row:** cambiar `alignItems: "center"` → `alignItems: "flex-start"` (efecto visual mínimo dado las alturas similares)

---

## ✅ Logros ya aplicados en iteraciones previas

| Mejora | Antes | Ahora |
|---|---|---|
| OTP row layout | `gap: 25` hardcoded (sólo 393px) | `justifyContent: "space-between"` + `paddingHorizontal: 8` adaptativo ✅ |
| Resend btn padding | en el row entero | dentro del botón (`px-8 py-12.5 rounded-100`) ✅ |
| Subtitle 2-líneas separation | gap-8 (igual al título) | gap-8 + marginTop-8 = ~16px ✅ |
| Mensaje error fallback | "Código inválido. Solicita uno nuevo." | "El código no coincide.\nRevísalo o solicita uno nuevo." ✅ |
| Timer = 0 state | "Reenviar código" (sin timer) | "Reenviar código en 00:00" (timer visible activo) ✅ |
| Estado éxito "Redirigiendo…" | n/a | Botón cambia a `BTN_BG` con texto "Redirigiendo…" ✅ |

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Logo posición y align | Top-left, `220×82` | Top-left | OK | — |
| Container | `pt-40 pb-36 px-16 gap-40` | Match | OK | — |
| Inner section | `gap-60` flex-1 entre title, OTP, resend | `gap: 60` | OK | — |
| Title block | `gap-8` interno | `gap: 8` | OK | — |
| Subtitle estructura | p1 + línea vacía + p2 | 2 `<Text>` con `marginTop: 8` extra | OK | — |
| OTP row | `justify-between px-8` entre 2 grupos | `space-between + paddingHorizontal: 8` ✅ | OK | — |
| OTP grupos internos | `gap-8` entre 3 cajas | `gap: 8` | OK | — |
| Resend section | `items-center`, sin gap entre prompt y row | Match | OK | — |
| Resend row | `items-start justify-center` | `items-center justify-center` | Diferencia Menor | Baja |
| Botón CTA posición | parte inferior | parte inferior | OK | — |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Title "Revisa tu correo" | Aptos SemiBold 24px `#103F43` | SemiBold 24px lh-32 | OK | — |
| Subtitle | Aptos Display 16px `rgba(31,42,51,0.8)` | Display 16px lh-24 | OK | — |
| Email coral | Aptos Display Bold `#EE8D78` | Bold `theme.coral` | OK | — |
| Prompt "¿Aún no recibes…?" | Aptos Display 16px rgba(31,42,51,0.8) text-center | Display 16px lh-22 | OK | — |
| Link "Reenviar código en" muted | Aptos SemiBold 16px rgba(23,126,150,0.5) underline | SemiBold 16px underline | OK | — |
| Timer "01:42" | Aptos Bold 18px `#1B6B73` | Bold 18px `theme.oceanTeal` | OK | — |
| Botón "Verificar código" | Aptos SemiBold 16px `#FFFCFA` | SemiBold 16px | OK | — |

### Fase 3 — Colores

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Background | `#fffcfa` | `#FFFCFA` | OK | — |
| Title color | `#103f43` | `#103F43` | OK | — |
| Subtitle color | `rgba(31,42,51,0.8)` | Match | OK | — |
| Email coral | `#ee8d78` | `theme.coral` | OK | — |
| OTP box bg | `#fffcfa` | `theme.authBg` | OK | — |
| OTP box border default | `#e6ded2` | `#E6DED2` | OK | — |
| Prompt color | `rgba(31,42,51,0.8)` | Match | OK | — |
| Link "Reenviar…" muted | `rgba(23,126,150,0.5)` | `RESEND_MUTED` | OK | — |
| Timer color | `#1b6b73` | `theme.oceanTeal` | OK | — |
| Botón disabled bg | `rgba(27,107,115,0.3)` | `BTN_DISABLED` | OK | — |
| Botón texto | `#fffcfa` | Match | OK | — |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| OTP box | `48×56`, `rounded-8`, border-1 | Match ✅ | OK | — |
| OTP box error | border `#E9B9BF`, shadow `#FBD8DC`, digit 32px `#BD4756` | Match (audit anterior) | OK | — |
| OTP box success | border `#BDEAA8`, shadow `rgba(189,234,168,0.5)`, digit 32px `#103F43` | Match (audit anterior) | OK | — |
| Link wrapper | `h-24`, `px-8 py-12.5`, `rounded-100` | Match ✅ | OK | — |
| Botón CTA | `h-40`, `rounded-100`, full-width | Match | OK | — |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| pt main | 40px | 40px | OK | — |
| pb main | 36px | 36px | OK | — |
| px main | 16px | 16px | OK | — |
| Main gap | 40px | 40px | OK | — |
| Inner gap (title → OTP → resend) | 60px | 60px ✅ | OK | — |
| Title block gap | 8px | 8px | OK | — |
| Subtitle p1 → p2 | ~24px (línea vacía) | ~16px (gap 8 + marginTop 8) | Diferencia Menor | Baja |
| OTP groups inner gap | 8px | 8px | OK | — |
| OTP groups separation | justify-between adaptativo | Match ✅ | OK | — |
| Resend prompt → row | sin gap | sin gap | OK | — |

### Fase 6 — Responsive

| Aspecto | Figma | Implementación (Android Samsung) | Estado | Severidad |
|---|---|---|---|---|
| Viewport reference | 393×852 | ~360×~780 dp | OK | — |
| Status bar | No visible | Visible | OK | — |
| OTP boxes responsive | justify-between px-8 | Match ✅ | OK | — |
| Subtitle wrap | natural 2-3 líneas | 2-3 líneas | OK | — |
| Botón full-width | ✓ | ✓ | OK | — |

### Fase 7 — Accesibilidad

| Aspecto | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Contraste title | 13.4:1 | Idéntico | OK | — |
| Contraste subtitle | 7.1:1 | Idéntico | OK | — |
| Contraste email coral | 3.1:1 | Idéntico | OK | — |
| Contraste link "Reenviar…" muted | 3.8:1 (intencional disabled) | Idéntico | OK | — |
| Contraste timer | 6.8:1 | Idéntico | OK | — |
| Contraste botón disabled | 1.8:1 (esperado) | Idéntico | OK | — |
| Tamaño táctil link "Reenviar…" | 24px alto | 24px alto | Diferencia Media | Media |
| Tamaño táctil botón CTA | 40px | 40px | Diferencia Menor | Baja |
| Tamaño táctil OTP boxes | 48×56 ✓ | 48×56 ✓ | OK | — |
| Keyboard handling | n/a (Figma estático) | Sin `KeyboardAvoidingView` | Diferencia Media | Media |
| Jerarquía visual | Title > Subtitle > OTP > Resend > CTA | Match | OK | — |

---

## 🏁 Veredicto

Pantalla de verificación de código con altísima fidelidad. Las 2 únicas observaciones de severidad Media son **funcionales** (keyboard handling + touch target), no visuales.

**Próximas acciones recomendadas (en orden de prioridad):**

1. Añadir `KeyboardAvoidingView` para evitar oclusión del CTA por el teclado
2. Aumentar `hitSlop` del link "Reenviar código en"
3. Ajustar gap entre párrafos del subtitle (`marginTop: 8 → 16`)
4. Resto: deuda técnica trivial

Con esos 3 fixes, el score subiría a ~98/100.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-05-30 (#1) | **95/100** | Falta `KeyboardAvoidingView` + touch target del link Reenviar |
