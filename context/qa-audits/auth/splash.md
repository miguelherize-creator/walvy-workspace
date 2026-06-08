# 🔍 UI Visual QA — `/splash` (SplashScreen)

**Figma principal:** `3689:3266` ("Mes en claro")
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-06-03
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score
**93 / 100**

### Estado General
⚠️ **Aprobado con observaciones** — diferencia menor de distribución vertical corregida en esta misma iteración; queda pendiente un watermark de background muy sutil.

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|---|---|
| 1 | Distribución vertical del body usaba `space-between`: mascot quedaba más centrado verticalmente que en Figma (en Figma el mascot está pegado al subtitle, con todo el espacio extra arriba del footer). | Media |
| 2 | Falta watermark de background `Frame 427318425` — Walvy iso azul + boca coral, opacity 0.2 con Gaussian blur 60px, posicionado 985×996 desplazado fuera de pantalla. Visualmente casi imperceptible en el render Figma. | Baja |

### Recomendaciones

#### Prioridad Alta
- _(ninguna)_

#### Prioridad Media
- ✅ **Aplicado en esta iteración:** body cambia de `justifyContent: "space-between"` a `flex-start`; `videoWrap` recibe `marginTop: 32` (gap subtitle→mascot ≈ Figma); `footer` recibe `marginTop: "auto"` para empujarlo al bottom. Resultado visual: title + mascot agrupados arriba, footer al pie — alineado con `gap-[432px]` + mascot absolute del Figma.

#### Prioridad Baja
- Considerar añadir el watermark SVG (`Frame 427318425.svg`) como capa decorativa de fondo. Con `opacity: 0.2` y un equivalente al `blur 60px` (vía `expo-blur` o un PNG ya pre-blureado), el efecto es muy sutil — no bloquea aceptación. Se puede dejar para una segunda iteración si se valida con el Designer si lo considera crítico.

---

## 📋 Detalle por Fases

### Fase 1 — Layout

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Container size | 393×852 | match (full screen) | OK | — |
| Header `3689:3269` | `h-84 pt-36 px-16 items-center justify-center` | match | OK | — |
| Body `3689:3271` | `flex-col gap-432 px-16 py-36`, h=768 | refactor: `flex-start` + `marginTop: auto` en footer + `marginTop: 32` en videoWrap | OK (post-fix) | Media (resuelto) |
| TitleBlock `3689:3272` | `gap-16`, full width | match (`gap: 16, width: "100%"`) | OK | — |
| VideoWrap (mascot) `3689:3279` | `301×301` centrado, top:234 inside body | `301×301`, marginTop 32, alignItems center | OK (post-fix) | — |
| Footer `3689:3277` | bottom of body, text 2 líneas centered | `marginTop: "auto"`, textAlign center | OK (post-fix) | — |

### Fase 2 — Tipografía

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Title h1 | `Aptos:Bold 48 / leading-none / center` | `Aptos-Bold 48 / lineHeight 48 / center` | OK | — |
| Title coral | `text-[#ee8d78]` | `TITLE_CORAL = "#EE8D78"` | OK | — |
| Title deep teal | `text-[#103f43]` | `TITLE_DEEP_TEAL = "#103F43"` | OK | — |
| Subtitle | `Aptos:SemiBold 18 / leading-normal / center` | `Aptos 18 / fontWeight 600 / lineHeight 24` | OK | — |
| Footer | `Aptos:SemiBold 14 / leading-normal / center` | `Aptos 14 / fontWeight 600 / lineHeight 20` | OK | — |

### Fase 3 — Colores

| Token | Figma | Implementación | Estado |
|---|---|---|---|
| Background container | `#fffcfa` | `BG_COLOR = "#FFFCFA"` | OK |
| Title teal | `#103f43` | `#103F43` | OK |
| Title coral | `#ee8d78` | `#EE8D78` | OK |
| Subtitle/Footer | `rgba(31,42,51,0.8)` | `rgba(31,42,51,0.8)` | OK |
| Watermark teal | `#2A9DA8` (opacity 0.2, blur 60) | _ausente_ | Diferencia Menor |
| Watermark coral | `#FF5530` (opacity 0.2, blur 60) | _ausente_ | Diferencia Menor |

### Fase 4 — Componentes

| Componente | Figma | Implementación | Estado |
|---|---|---|---|
| WalvyIso 48×48 | `brand/isotipo-new.png` o equivalente | `assets/images/brand/isotipo-new.png` | OK |
| Mascot animation | Composición estática (mascot + cards + bell + chart + receipt + dashed circle) | Lottie animado `walvy-splash-animated.json` (mismo arte, animado por Designer) | OK (animado por diseño, vectorial 380×380, alpha nativo) |

### Fase 5 — Espaciado

| Espacio | Figma | Implementación | Estado |
|---|---|---|---|
| Header pt | `pt-36` | `paddingTop: 36` | OK |
| Body px | `px-16` | `paddingHorizontal: 16` | OK |
| Body py | `py-36` | `paddingVertical: 36` | OK |
| TitleBlock gap | `gap-16` | `gap: 16` | OK |
| Subtitle → mascot | ≈ 34px (calculado de top:234) | `marginTop: 32` | OK (post-fix, Δ=2px) |
| Mascot → footer | ≈ 149px (calculado de body 768 − py 36 − mascot end 549) | `marginTop: "auto"` (variable según device) | OK funcional (post-fix) |

### Fase 6 — Responsive

| Device | Comportamiento esperado | Observación |
|---|---|---|
| iPhone 393×852 (Figma base) | Layout exacto al Figma | OK con fix aplicado |
| Android 360×780 | Body se contrae, footer queda más cerca del mascot | OK (`marginTop: auto` se ajusta automáticamente) |
| iPhone Pro Max 430×932 | Body se expande, hay más espacio entre mascot y footer | OK — el espacio extra cae después del mascot, igual que en Figma |

### Fase 7 — Accesibilidad

| Check | Figma | Implementación | Estado |
|---|---|---|---|
| Contraste título teal sobre cream | 13.4:1 | match | OK |
| Contraste subtitle | rgba(31,42,51,0.8) → ~9:1 sobre #FFFCFA | match | OK |
| Touch targets | N/A (splash sin interacción) | N/A | OK |
| Tamaños de texto legibles | 48 / 18 / 14 | match | OK |

---

## 🏁 Veredicto

Implementación muy fiel al diseño Figma 3689:3266. La única diferencia visualmente perceptible era la distribución vertical del body — `justify-content: space-between` centraba el mascot a la mitad entre título y footer, cuando el Figma lo posiciona pegado al subtítulo con todo el espacio sobrante después del mascot. Esta diferencia se corrigió en la misma iteración con `marginTop: auto` en el footer.

La única observación pendiente es el watermark de background (W blureado a opacity 0.2), un detalle decorativo casi imperceptible en el render Figma que no bloquea aceptación. Recomendado validarlo con el Designer antes de invertir tiempo en exportar/optimizar el SVG.

Con esos N=0 fixes adicionales requeridos, el score actual es **93/100 — Aprobado con observaciones**. Subiría a ~98/100 si se añade el watermark de background.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-06-03 (#1) | 93/100 | Fix de distribución vertical aplicado en misma iteración; watermark de background pendiente (baja prioridad). |
