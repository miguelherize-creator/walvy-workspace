# Requerimiento backend: flujo post-Kread

**Estado:** Parcialmente implementado — pendiente prueba con Kread real + endpoint de ingreso  
**Última actualización:** 2026-07-05  
**Módulo principal:** `back-walvy/src/imports/`  
**Módulo secundario:** `back-walvy/src/users/` (declaración de ingreso)

---

## Contexto

Cuando Kread termina de procesar una cartola (`status = "parsed"`), el frontend navega por tres pantallas antes de llegar al home. El backend soporta ese flujo con dos endpoints: uno de lectura (resumen) y uno de escritura (declaración de ingreso que el usuario introduce manualmente en un bottom sheet).

---

## Flujo frontend post-Kread

```
onboarding-analyzing
  pollStatus: GET /status → { status: "parsed" }
  → router.replace("/(auth)/onboarding-analysis", { importId })

onboarding-analysis
  GET /statement-imports/:id/summary → detected flags
  CTA "Ver mi diagnóstico"
  → router.replace("/(auth)/onboarding-first-ready", { importId })

onboarding-first-ready
  GET /statement-imports/:id/summary → semaforo
  Botón "Completar información clave" → abre IngresosDatosSheet
    └─ Sheet recopila: sueldoLiquido, salarioTipo, movimientoDescripcion
    └─ CTA "Continuemos" → POST /users/me/income-declaration  [PENDIENTE]
  CTA "Ver mi Perfil Financiero"
  → PATCH /auth/onboarding/step + router.replace("/(tabs)")
```

El `importId` viaja como param de ruta entre las tres pantallas. No hay vuelta a `listImports`.

---

## Endpoint 1: GET /statement-imports/:id/summary

**Estado:** Implementado en código — pendiente prueba con Kread real

```
GET /statement-imports/:id/summary
Authorization: Bearer <token>
```

### Precondición

El import debe estar en `status = "parsed"`. Si no, devuelve `400 Bad Request`.

### Respuesta exitosa — 200

```json
{
  "importId": "uuid",
  "transactionCount": 45,
  "periodStart": "2026-06-01",
  "periodEnd": "2026-06-30",
  "detectedMonthlyIncome": 1200000,
  "detected": {
    "hasIncome": true,
    "hasFixedExpenses": true,
    "hasRecurringPayments": true,
    "hasRecentMovements": true,
    "hasPaymentInstruments": true,
    "hasTransfers": false
  },
  "semaforo": {
    "light": "green",
    "totalIncome": 1500000,
    "totalExpense": 900000,
    "ratio": 0.6
  }
}
```

### Cálculo de `detected`

Todos los flags se derivan de `import_line_items.normalized` (JSONB).  
Las transferencias (`normalized.isTransfer = true`) se excluyen del cálculo de ingresos y gastos.

| Flag | Regla | Pantalla |
|---|---|---|
| `hasIncome` | Al menos una línea con `movementType = 'income'` AND `isTransfer = false` | "Salario líquido" |
| `hasFixedExpenses` | Al menos una línea con `flowType = 'fixed'` AND `isTransfer = false` | "Compromisos base" |
| `hasRecurringPayments` | Al menos una línea con `flowType = 'fixed'` AND `isTransfer = false` | "Pagos recurrentes" |
| `hasRecentMovements` | `transactionCount > 0` | "Movimientos recientes" |
| `hasPaymentInstruments` | Al menos una línea con `movementType = 'expense'` AND `isTransfer = false` | "Instrumentos de pago" |
| `hasTransfers` | Al menos una línea con `isTransfer = true` | Informativo |

> **Pendiente:** `hasIncome` actualmente detecta cualquier abono no-transferencia.  
> La regla de **Salario líquido** requiere lógica adicional — ver sección siguiente.

#### Salario líquido — regla definida (2026-07-05)

Se agregó **`detectedMonthlyIncome`** al summary:

```
detectedMonthlyIncome = Σ amount de líneas donde
    normalized.subcategory ∈ { "Sueldo", "Honorarios / boletas" }
    AND isTransfer = false
```

Decisiones tomadas:
- **Detección por subcategoría** (el catálogo "Ingresos" ya tiene la hoja `Sueldo`), no por glosa/monto/recurrencia.
- **Suma simple** de las líneas del período (cubre sueldo quincenal y doble empleador; el usuario corrige si un bono infló el monto). No es fuente de verdad — solo **pre-llena** el sheet.
- Incluye `Honorarios / boletas` para cubrir independientes. Excluye Transferencias recibidas, Reembolsos y Distribución de utilidades.

**Uso frontend:** `detectedMonthlyIncome` pre-llena el campo `sueldoLiquido` del `IngresosDatosSheet`.

**Caveats:**
- `detectedMonthlyIncome = 0` si Kread no clasificó ninguna línea como sueldo/honorarios (o si no llena `subcategory` — validar con Kread real).
- La suma asume período ≈ 1 mes (`periodStart`/`periodEnd`). Si la cartola trae >1 mes, sobreestima.
- `hasIncome` sigue siendo el proxy amplio (cualquier abono no-transfer); tightening a "hay sueldo" (`detectedMonthlyIncome > 0`) se hará cuando se valide que Kread llena `subcategory`.

### Cálculo del semáforo

```
totalIncome  = Σ amount donde movementType = 'income'  AND isTransfer = false
totalExpense = Σ amount donde movementType = 'expense' AND isTransfer = false

ratio = totalExpense / totalIncome   (si totalIncome = 0 → ratio = 1)

light:
  ratio < 0.80  → "green"   (En control)
  ratio < 1.00  → "yellow"  (Con atención)
  ratio ≥ 1.00  → "red"     (En riesgo)
```

### `periodStart` / `periodEnd`

Derivados del min/max de `normalized.occurredOn` de las líneas del import.  
No se persiste en `statement_imports` — se computa on-demand.

---

## Endpoint 2: declaración de ingreso

> ✅ **RESUELTO (2026-07-05):** NO se crea un endpoint nuevo. La declaración de ingreso **reusa el endpoint existente `PUT /profile/financial`** (ver `docs/api/profile/financial.md`). El "sueldo líquido declarado" es **el mismo dato** que `monthlyIncomeEstimate` (una sola fuente de verdad). Backend: se agregó la columna/campo **`income_type`** (`fijo`|`variable`) al perfil financiero. Lo que sigue documenta el contrato original propuesto; el shape real a usar es el de `PUT /profile/financial` con `{ monthlyIncomeEstimate, incomeType }`.

**Estado:** ✅ Backend listo (campo `income_type` agregado) · ⏳ falta conectar el sheet a `PUT /profile/financial`

### Motivación

El usuario declara manualmente su sueldo líquido en el bottom sheet "Ingresar datos" (`onboarding-first-ready`). Este dato es independiente de lo que Kread detectó: es la fuente de verdad del ingreso del usuario y se usa en futuras cuentas y proyecciones.

### Contrato

```
POST /users/me/income-declaration
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**

```json
{
  "declaredIncome": 1200000,
  "incomeType": "fijo"
}
```

| Campo | Tipo | Validación |
|---|---|---|
| `declaredIncome` | `number` | entero positivo, > 0 |
| `incomeType` | `"fijo" \| "variable"` | enum |

**Respuesta exitosa — 200:**

```json
{
  "declaredIncome": 1200000,
  "incomeType": "fijo",
  "updatedAt": "2026-07-05T18:30:00Z"
}
```

**Errores:**

| Código | Causa |
|---|---|
| `400` | `declaredIncome` ≤ 0 o `incomeType` inválido |
| `401` | Token ausente o expirado |

### Persistencia

El dato vive en el perfil del usuario, no en el import. Opciones (por decidir):

| Opción | Pros | Contras |
|---|---|---|
| Columnas en `users` | simple, sin join | ensucia la tabla de auth |
| Tabla `user_financial_profiles` | separación limpia, extensible | tabla extra |

Recomendación: columnas `declared_income` + `income_type` en la tabla existente de perfil (`user_profiles` si existe, o `users` si no hay tabla separada). Verificar el schema antes de implementar.

### Qué hace el frontend al recibir 200

Por ahora: cierra el sheet y no navega (`setSheetVisible(false)`). El `onConfirm` en `OnboardingFirstReadyScreen` está listo para recibir los datos — solo falta la llamada API. Cuando se implemente el endpoint, agregar `saveIncomeDeclaration(data)` antes de cerrar.

---

## Endpoint 3 (futuro): Anotación de movimiento sin categoría

**Estado:** Diseño pendiente — el sheet tiene un segundo campo para esto

### Motivación

El bottom sheet tiene un segundo input: "Movimiento de $-231.990" donde el usuario puede describir un cargo que Kread no categorizó. La lógica del frontend ya soporta mostrar este campo cuando `movimientoAmount !== null`. Hoy ese valor siempre es `null` porque no hay endpoint que devuelva movimientos pendientes de categorización.

### Requisitos para habilitar este campo

1. Un endpoint que devuelva la lista de `import_line_items` donde `normalized.category` es nulo o `"unknown"`, ordenada por `amount desc` — el más significativo primero.
2. El frontend lee el primer resultado y lo pasa como `movimientoAmount` al sheet.
3. Un endpoint `PATCH /statement-imports/:id/lines/:lineId/annotate` que reciba `{ description: string }` y lo guarde en `import_line_items`.

No bloquea el MVP — se puede implementar en una iteración posterior.

---

## Archivos relevantes

| Capa | Archivo |
|---|---|
| Servicio summary | `back-walvy/src/imports/services/statement-import.service.ts` → `getImportSummary()` |
| Controller summary | `back-walvy/src/imports/controllers/statement-import.controller.ts` → `GET :id/summary` |
| Tipo backend | `ImportSummaryDto` (en el mismo service) |
| Tipo frontend | `front-walvy/expo/api/types/cartola.ts` → `ImportSummaryResponse` |
| API call summary | `front-walvy/expo/api/statementImportService.ts` → `getImportSummary()` |
| Sheet frontend | `front-walvy/expo/features/auth/ui/IngresosDatosSheet.tsx` |
| Pantalla 1 | `front-walvy/expo/features/auth/ui/OnboardingAnalysisScreen.tsx` |
| Pantalla 2 | `front-walvy/expo/features/auth/ui/OnboardingFirstReadyScreen.tsx` |

---

## Pendientes

- [x] **Endpoint 2 — resuelto**: se reusa `PUT /profile/financial` + campo `income_type` agregado al perfil (backend listo)
- [ ] **Conectar sheet al endpoint**: en el front, `onConfirm` de `OnboardingFirstReadyScreen` debe llamar a `PUT /profile/financial` con `{ monthlyIncomeEstimate: sueldoLiquido, incomeType: salarioTipo }`
- [x] **Regla de Salario líquido definida**: `detectedMonthlyIncome` = Σ subcategorías `Sueldo`/`Honorarios/boletas` (suma simple, isTransfer=false). Pre-llena el sheet. Falta validar `subcategory` con Kread real.
- [ ] **Probar con Kread real**: validar que `normalized.flowType` y `normalized.isTransfer` llegan correctamente
- [ ] **Evaluar flags distintos**: `hasFixedExpenses` y `hasRecurringPayments` usan hoy la misma regla (`flowType = 'fixed'`) — ¿deberían diferenciarse?
- [ ] **Decidir persistencia** de `periodStart/periodEnd/bank` en `statement_imports` o siempre computar on-demand
- [ ] **Endpoint 3 (futuro)**: movimiento sin categoría — habilitar segundo campo del sheet
