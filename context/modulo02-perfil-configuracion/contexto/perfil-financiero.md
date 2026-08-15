# Pantalla: Perfil Financiero

**Ruta:** `/(auth)/financial-profile`
**Archivo principal:** `front-walvy/expo/features/profile/ui/FinancialProfileScreen.tsx`
**Hook:** `front-walvy/expo/features/profile/hooks/useFinancialProfile.ts`

---

## 1. Propósito

La pantalla "Tu perfil financiero" consolida la lectura financiera del usuario a partir de dos fuentes de datos: el perfil manual (declarado en onboarding) y la cartola importada (statement-imports). Muestra ingresos, disponible, compromisos, recurrentes e instrumentos, adaptando el contenido según cuántos datos están disponibles.

---

## 2. Los 4 casos de perfil

La pantalla tiene **4 estados distintos** derivados de la combinación de datos disponibles.

| Caso | Condición | Qué muestra | Acción principal |
|------|-----------|-------------|------------------|
| **A** | Sin perfil manual + sin cartola | Vista difuminada con datos falsos | Comenzar onboarding |
| **B** | Sin perfil manual + con cartola | Datos reales de cartola + CTA de mejora | Completar onboarding |
| **C** | Con perfil manual + cartola insuficiente | Banner de advertencia + datos de perfil | Continuar onboarding |
| **D** | Con perfil manual + cartola con ingreso | Resumen completo sin fricción | Editar perfil |

### Lógica de derivación — `deriveCase()`

```typescript
export function deriveCase(
  profile: FinancialProfile | null,
  metrics: FinancialMetrics | null,
  summary: ImportSummaryResponse | null,
): ProfileCase {
  const hasProfile    = !!profile;
  const hasCartola    = !!metrics;
  // Si summary no cargó pero hay cartola, asumir suficiente (optimista)
  const sufficientDoc = hasCartola && (summary === null || summary.detected.hasIncome);

  if (!hasProfile && !hasCartola)    return "A";
  if (!hasProfile && hasCartola)     return "B";
  if (hasProfile  && !sufficientDoc) return "C";
  return "D";
}
```

**Por qué optimista en `summary === null`:** Si `getImportSummary` falla por error de red pero hay cartola, no queremos degradar al usuario a Caso C cuando sus datos pueden estar bien. Se asume suficiente y se verifica en el siguiente load.

---

## 3. Fuentes de datos

### Hook: `useFinancialProfile`

Llama a **3 endpoints en paralelo** al montar:

| Endpoint | Función | Resultado |
|----------|---------|-----------|
| `GET /profile/financial` | `getFinancialProfile()` | `FinancialProfile` — ingreso declarado, capacidad de pago, nota de compromisos |
| `GET /statement-imports` → líneas | `listImports()` + `getImportLines(id)` | `FinancialMetrics` — calculado desde movimientos |
| `GET /statement-imports/:id/summary` | `getImportSummary(id)` | `ImportSummaryResponse` — semáforo y flags de detección |

**Flujo de carga:**

```
mount → Promise.allSettled([getFinancialProfile(), loadMetricsAndSummary()])
         ↓
loadMetricsAndSummary():
  listImports() → toma el último con status="parsed"
  Promise.allSettled([getImportLines(id), getImportSummary(id)])
  calcMetrics(lines) → FinancialMetrics
```

`Promise.allSettled` en ambos niveles garantiza que un fallo parcial no bloquea el resto.

### Tipos clave

```typescript
// Perfil manual (onboarding)
interface FinancialProfile {
  monthlyIncomeEstimate: number;
  estimatedPaymentCapacity: number;
  stableExpensesNote: string;
}

// Calculado desde líneas de cartola
interface FinancialMetrics {
  totalIncome: number;
  totalExpense: number;
  disponible: number;
  compromisos: CompromisoItem[];        // gastos fijos agrupados (top 5)
  totalCompromisos: number;
  topRecurrentes: RecurrentItem[];      // ant expenses agrupados (top 6)
  instrumentos: string[];               // Efectivo, Débito, Crédito, Transferencia
}

// Del endpoint /summary
interface ImportSummaryResponse {
  detected: {
    hasIncome: boolean;
    hasFixedExpenses: boolean;
    hasRecurringPayments: boolean;
    hasRecentMovements: boolean;
    hasPaymentInstruments: boolean;
    hasTransfers: boolean;
  };
  semaforo: {
    light: 'green' | 'yellow' | 'red';
    totalIncome: number;
    totalExpense: number;
    ratio: number;
  };
}
```

### `calcMetrics()` — qué calcula

| Métrica | Fuente en líneas | Criterio |
|---------|-----------------|---------|
| `totalIncome` | `movementType === "income"` | Suma de montos |
| `totalExpense` | `movementType === "expense"` | Suma de montos |
| `disponible` | `totalIncome - totalExpense` | Puede ser negativo |
| `compromisos` | `flowType === "fixed" && !isTransfer` | Top 5 por monto, agrupados por descripción |
| `topRecurrentes` | `isAntExpense === true` | Top 6 por monto, agrupados por descripción |
| `instrumentos` | heurística por `branch` y `description` | Inferencia por palabras clave |

---

## 4. Arquitectura de componentes

La pantalla sigue el **patrón de sub-componentes nombrados** — funciones definidas antes del export principal.

```
FinancialProfileScreen
├── BlurAmount              — wrapper con BlurView absoluteFill (iOS blur nativo)
├── Chip                    — etiqueta de instrumento detectado
├── IngresoRow              — tarjetas duales: Ingreso principal + Disponible
├── AlertsRow               — Salud de deuda + Ruta despeje (siempre visible)
├── CompromisosCard         — lista de gastos fijos con total
├── TopRecurrentesCard      — scroll horizontal de gastos hormiga
├── InstrumentosCard        — chips de instrumentos detectados
├── CompletarPerfilCta      — CTA teal para completar perfil (Caso D)
├── ContinuarOnboardingBanner — banner amarillo de advertencia (Caso C)
├── MejorarPrecisionCta     — CTA teal para mejorar precisión (Caso B)
├── PrepararPerfilCta       — CTA con lista de features, primer onboarding (Caso A)
├── BlurredProfileView      — vista completa con datos falsos difuminados (Caso A)
├── NoDataModal             — modal "Aún no podemos mostrar tu perfil" (Caso A)
└── EditModal               — sheet bottom para editar perfil manual
```

### Props pattern

Cada sub-componente recibe `isDark: boolean`, `theme: any` (del ThemeProvider) y `cs: CardStyle` (helper `getCardStyle(isDark, theme)`) para no calcular el estilo dinámico en cada uno.

```typescript
type CardStyle = { bg: string; border: string; shadow: object };

function getCardStyle(isDark: boolean, theme: any): CardStyle {
  return {
    bg:     isDark ? theme.card : CARD_BG,
    border: isDark ? theme.border : CARD_BORDER,
    shadow: Platform.select({ ios: { shadowColor: isDark ? "#202B35" : TEAL, ... } }),
  };
}
```

> **Regla B03:** `shadowColor` va inline, nunca en `StyleSheet.create`. Dark usa `#202B35`, light usa `TEAL (#1B6B73)`.

---

## 5. Caso A — Vista difuminada (`BlurredProfileView`)

Cuando no hay ningún dato, en lugar de una pantalla vacía se muestra una **preview con datos falsos difuminados** para comunicar qué verá el usuario cuando complete su perfil.

### Técnica de blur

React Native no soporta `filter: blur()` por elemento. El patrón usado:

```tsx
// BlurAmount: el contenido se renderiza primero, luego BlurView lo tapa
function BlurAmount({ children, isDark, wrapStyle }) {
  return (
    <View style={[styles.blurAmountWrap, wrapStyle]}>  {/* overflow: hidden */}
      {children}
      <BlurView
        intensity={isDark ? 16 : 22}
        tint={isDark ? "dark" : "light"}
        style={StyleSheet.absoluteFillObject}   // cubre exactamente el padre
      />
    </View>
  );
}
```

Se usa `overflow: hidden` en el wrapper para que el blur no se escape. `BlurView` se pone **después** de `children` en el árbol para quedar encima en z-order y difuminar lo que hay debajo.

**Prop `wrapStyle`:** Necesario porque el wrapper base tiene `alignSelf: flex-start`, lo que rompe hijos con `flex: 1`. Para filas con etiqueta + monto:
- Etiqueta: `wrapStyle={{ flex: 1 }}`
- Monto: `wrapStyle={{ alignSelf: "flex-end" }}`

Para secciones completas (Top recurrentes) se usa un `BlurView absoluteFill` directo sobre el contenedor:
```tsx
<View style={styles.blurSection}>   {/* overflow: hidden, position: relative */}
  {/* contenido */}
  <BlurView intensity={20} tint="light" style={StyleSheet.absoluteFillObject} />
</View>
```

---

## 6. Modal "Sin onboarding" (`NoDataModal`)

Se dispara automáticamente en **Caso A**. Diseño de Figma `4340:10425`.

### Reglas de disparo

```typescript
// 1. Carga inicial — cuando loading termina por primera vez
useEffect(() => {
  if (!loading && profileCase === "A") setShowOnboardingModal(true);
}, [loading]);

// 2. Re-entrada — cada vez que la pantalla gana foco (volver desde otra pantalla)
useFocusEffect(
  React.useCallback(() => {
    if (!loading && profileCase === "A") setShowOnboardingModal(true);
  }, [loading, profileCase])
);
```

`useFocusEffect` es de `expo-router` y se ejecuta en cada navegación hacia la pantalla, no solo en el mount. Esto garantiza que si el usuario cierra el modal con "Ahora no", sale a `/profile`, y vuelve a entrar, el modal reaparece.

### Diseño del modal

- **Siempre light** — colores estáticos, no adapta a dark mode (decisión de diseño)
- Overlay: `rgba(39,57,59,0.7)` — del teal oscuro de Walvy
- Card: `bg=#FFFDFD`, `border=#E6DED2`, `border-radius=16`
- Mascota en círculo: `160x160`, `bg=#F2EFE9`, `border-radius=80`
- "Ahora no": estilo terciario — `color=#177E96 (LINK_TERCIARIO)`, subrayado

### Navegación desde el modal

```typescript
function handlePrepare() {
  setShowOnboardingModal(false);
  router.push("/(auth)/onboarding");
}
```

---

## 7. Routing por caso en el JSX principal

```tsx
{loading ? <ActivityIndicator />
: error   ? <ErrorText />
: profileCase === "A" ? <BlurredProfileView onPrepare={handlePrepare} ... />
: profileCase === "B" ? (
    <>
      <IngresoRow ingresoMensual={metrics.totalIncome} hasManualIncome={false} ... />
      <AlertsRow hasMetrics={true} hasProfile={false} ... />
      <CompromisosCard ... />
      <TopRecurrentesCard ... />
      <InstrumentosCard ... />
      <MejorarPrecisionCta onPress={handleMejorar} ... />
    </>
  )
: profileCase === "C" ? (
    <>
      <ContinuarOnboardingBanner onPress={handleContinuarOnboarding} ... />
      <IngresoRow ingresoMensual={profile.monthlyIncomeEstimate} hasManualIncome={true} ... />
      <AlertsRow hasMetrics={false} hasProfile={true} ... />
      <CompletarPerfilCta onPress={handleContinuarOnboarding} ... />
    </>
  )
: /* Caso D */ (
    <>
      <IngresoRow ... />
      <AlertsRow hasMetrics={true} hasProfile={true} ... />
      <CompromisosCard ... />
      <TopRecurrentesCard ... />
      <InstrumentosCard ... />
      <CompletarPerfilCta onPress={handleOpenModal} ... />   {/* editar perfil */}
    </>
  )
}
```

**Diferencia Caso B vs D en `IngresoRow`:**
- B: `ingresoMensual = metrics.totalIncome`, `hasManualIncome = false` → subtítulo "Calculado"
- D: `ingresoMensual = profile.monthlyIncomeEstimate ?? metrics.totalIncome`, `hasManualIncome = !!profile.monthlyIncomeEstimate` → subtítulo "Sueldo" si hay dato manual

---

## 8. Tokens de diseño

| Token | Valor | Uso |
|-------|-------|-----|
| `DEEP_TEAL` | `#103F43` | Títulos en light mode |
| `TEAL` | `#1B6B73` | Botones primarios, sombras light |
| `CARD_BG` | `#FFFDFD` | Fondo de tarjetas en light |
| `CARD_BORDER` | `#E6DED2` | Borde de tarjetas en light |
| `AMOUNT_COLOR` | `rgba(16,63,67,0.8)` | Montos en light |
| `SUBTITLE_COLOR` | `rgba(31,42,51,0.8)` | Subtítulos en light |
| `LINK_TERCIARIO` | `#177E96` | "Ahora no", "Ver todos los pagos" |
| `RED_BORDER` | `#EF6060` | Tarjeta Salud de deuda |
| `RED_TEXT` | `#AB3737` | Texto en alerta roja |
| `YELLOW_BORDER` | `#DDBF50` | Tarjeta Ruta despeje, banner Caso C |
| `YELLOW_TEXT` | `#99812C` | Texto en alerta amarilla |

**Fuentes:**
```typescript
fontFamily.semiBold  = "Aptos-SemiBold"  // títulos, labels, montos
fontFamily.display   = "Aptos-Display"   // montos grandes
fontFamily.regular   = "Aptos"           // body, subtítulos
fontFamily.bold      = "Aptos-Bold"      // totales
```

---

## 9. Pendiente / Futuro (Módulo 4)

| Feature | Dato disponible | Estado |
|---------|----------------|--------|
| Semáforo de salud de deuda | `summary.semaforo.light` | Sin UI — dato ya llega del backend |
| Ratio ingreso/gasto | `summary.semaforo.ratio` | Sin UI |
| Ruta despeje | `summary.semaforo` + perfil | Módulo 4 |
| Score de confianza del perfil | — | Por definir |

La `AlertsRow` ya muestra los placeholders ("Requiere atención", "Datos por confirmar") listos para conectarse a `summary.semaforo.light` cuando el Módulo 4 los implemente.

---

## 10. Archivos relevantes

| Archivo | Descripción |
|---------|-------------|
| `front-walvy/expo/features/profile/ui/FinancialProfileScreen.tsx` | Pantalla principal + todos los sub-componentes |
| `front-walvy/expo/features/profile/hooks/useFinancialProfile.ts` | Hook: datos, `deriveCase`, `ProfileCase` type |
| `front-walvy/expo/api/financialProfileService.ts` | `getFinancialProfile`, `upsertFinancialProfile` |
| `front-walvy/expo/api/statementImportService.ts` | `listImports`, `getImportLines`, `getImportSummary` |
| `front-walvy/expo/api/types/cartola.ts` | `ImportSummaryResponse`, `ImportLineItem`, `NormalizedLine` |
| `front-walvy/expo/constants/profileStyles.ts` | `profileLayout`, `profileTypography`, `getProfileColors` |
| `front-walvy/expo/app/(auth)/financial-profile.tsx` | Entry point de ruta (render de `FinancialProfileScreen`) |
| `front-walvy/expo/app/(auth)/onboarding.tsx` | Destino de todas las CTAs de onboarding |
