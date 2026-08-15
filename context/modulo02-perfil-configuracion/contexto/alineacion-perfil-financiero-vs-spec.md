# Perfil Financiero — Alineación implementación vs especificación del cliente

Última actualización: 2026-07-08
Estado: análisis verificado contra código
Compara:
- **Spec cliente:** `Walvy_Perfil_Financiero_Reglas_Alineacion_v1_0.docx` (+ UX Perfil Financiero v1.0, Anexo BDD Fase 3 M5)
- **Backend real:** `perfil-financiero-y-recurrentes.md` (M01) — `/summary`, mapper de Kread, `/profile/financial`
- **Frontend real:** `perfil-financiero.md` (M02) — `calcMetrics()`, `useFinancialProfile`

> **Nomenclatura:** el cliente llama a esta pantalla **Perfil Financiero**; el equipo la llama "Módulo 1". Son lo mismo. Los 5 indicadores obligatorios: Ingreso principal, Compromisos base, Pagos recurrentes, Movimientos sin categorizar, Instrumentos de pago.

Leyenda de alineación: 🟢 alineado · 🟡 parcial · 🔴 desalineado / inventamos regla propia.

---

## Tabla maestra de alineación

| # | Indicador | Spec cliente | Backend (`/summary` + mapper) | Frontend (`calcMetrics`) | Alineación |
|---|-----------|--------------|-------------------------------|--------------------------|-----------|
| 1 | **Ingreso principal** | Parcial (sin regla de desempate multi-fuente) | `detectedMonthlyIncome` = Σ subcats `Sueldo`+`Honorarios` | usa `detectedMonthlyIncome` / perfil manual | 🟡 |
| 2 | **Compromisos base** | Parcial (sin catálogo cerrado) | `hasFixedExpenses` = ∃ egreso `flowType=fixed` | `compromisos` = `flowType=fixed && !isTransfer`, Top 5 | 🟡 |
| 3 | **Pagos recurrentes** | Pendiente (sin regla técnica de recurrencia) | `hasRecurringPayments` = **idéntico** a fixed | `topRecurrentes` = `isAntExpense`, Top 6 | 🔴 backend / 🟡 frontend |
| 4 | **Movimientos sin categorizar** | Definida (C-01..C-04, 3 niveles de certeza) | `resolveStatus`: **2 niveles** (≥0.7 categorized / resto pending) | contador desde líneas `pending_review` | 🔴 |
| 5 | **Instrumentos de pago** | Parcial | `hasPaymentInstruments` = ∃ **cualquier** egreso | `instrumentos` = heurística por `branch`/`description` | 🔴 backend / 🟡 frontend |

---

## Detalle por indicador

### 1. Ingreso principal 🟡
- **Spec:** "no existe regla documentada de desempate cuando hay múltiples fuentes" → **Pendiente** de Producto.
- **Nosotros:** el backend **ya inventó una regla** — suma de las subcategorías `Sueldo` + `Honorarios` (excluye `Bono`, `Aguinaldos`, transferencias). Nos adelantamos a una decisión que el cliente marca como abierta.
- **Riesgo:** si el "ingreso principal" real es pensión, honorarios recurrentes o una transferencia mensual, hoy da **0** (como se vio en pruebas). La spec pide etiqueta del **tipo** de ingreso + origen; el backend solo da un número.
- **Acción:** validar con Producto la regla de desempate y ampliar `SALARY_SUBCATEGORIES` / exponer el tipo de ingreso detectado.

### 2. Compromisos base 🟡
- **Spec:** arriendo, dividendo, gasto común, servicios, pensiones, seguros, colegiatura. Sin catálogo cerrado.
- **Nosotros:** `flowType=fixed` = prefijo `"Servicios - "` + `FIXED_SUBCATEGORIES` (créditos, seguros, imposiciones, teléfono). Cubre razonablemente los ejemplos de la spec.
- **Gap:** falta pensión/colegiatura explícitos en el set; y la separación real vs recurrentes depende del punto 3.

### 3. Pagos recurrentes — 🔴 el desalineamiento más importante
- **Spec (regla explícita):** compromisos base y pagos recurrentes son **categorías distintas, no duplicables**. Recurrentes = hábitos (no compromisos), Top 5 con % sobre ingreso.
- **Backend:** `hasRecurringPayments` es **idéntico** a `hasFixedExpenses` (ambos = `flowType=fixed`). **Viola la regla del cliente**: duplica compromisos base como si fueran recurrentes.
- **Frontend:** sí los separa — `topRecurrentes` sale de `isAntExpense` (gastos hormiga), distinto de `compromisos` (`flowType=fixed`). Más alineado, pero:
  - "gasto hormiga" (`isAntExpense`) ≠ exactamente "pago recurrente que perfila hábito" (Netflix, gym…). Concepto cercano pero no idéntico.
  - Frontend hace **Top 6**, la spec pide **Top 5**; falta el **% sobre ingreso**.
- **Ambos:** la **regla técnica de recurrencia** (frecuencia mínima, ventana de meses, tolerancia de monto) es **Pendiente** en la spec → ni backend ni frontend la implementan; se usan proxies (`flowType`/`isAntExpense`).
- **Acción:** (a) corregir el flag `hasRecurringPayments` del backend para que NO sea un alias de fixed; (b) cerrar con Producto la definición técnica de recurrencia.

### 4. Movimientos sin categorizar 🔴
- **Spec (Definida, C-01..C-04):** **3 niveles de certeza** — alta → auto con trazabilidad; **media → pide validación**; baja → "sin categorizar". Contador en UI. Severidad D-03: críticos sin categorizar bloquean conclusiones de sobreconsumo.
- **Backend:** `resolveStatus` tiene **solo 2 niveles** (`confidence ≥ 0.7 → categorized`, resto `pending_review`). **Falta el tramo "certeza media → pide validación"** (C-02). No hay lógica de severidad ni bloqueo D-03 en `/summary`.
- **Gap:** `/summary` no expone un **contador** de sin-categorizar (solo `hasRecentMovements` = líneas>0). El conteo real hay que sacarlo de `/lines/pending`.
- **Acción:** introducir el nivel intermedio de certeza (umbral medio) y exponer contador de pendientes + regla D-03.

### 5. Instrumentos de pago 🔴 backend / 🟡 frontend
- **Spec:** chips con mecanismos (efectivo, transferencia, crédito, débito). Evitar inventario técnico.
- **Backend:** `hasPaymentInstruments` = ∃ **cualquier** egreso → **no detecta instrumentos**, es un flag mal nombrado.
- **Frontend:** `instrumentos` = heurística por `branch`/`description` que infiere Efectivo/Débito/Crédito/Transferencia → alineado en intención.
- **Gap:** la detección vive **solo en el frontend** (heurística de strings), no en el backend; sin regla de agregación cuando el mismo instrumento aparece en varios documentos (spec lo marca Parcial).

---

## Bloques transversales

### Origen y calidad del dato
- **Spec:** fuente preferente = cartola/documentos; manual = complementaria (no reemplaza). ✅ El frontend respeta esto (Casos A–D combinan perfil manual + cartola, priorizando cartola).
- **Badge de completitud (alto/medio/bajo):** 🔴 **no existe** ni en backend ni en `/summary`. La spec lo pide (umbrales Pendientes). Gap claro.

### Semáforo del mes (Home)
- **Spec:** multi-señal — pagos próximos + fugas + presupuesto/margen + Salud de Deuda; **una sola señal dominante**; Perfil Financiero aporta la "base de confianza".
- **Backend:** `semaforo` de `/summary` = **solo** `ratio = totalExpense/totalIncome` (green <0.80 / yellow <1.0 / red ≥1.0). 🔴 Es un **diagnóstico local por cartola**, NO el semáforo de Home de la spec. Además los umbrales (0.80/1.0) los **inventamos** — la spec no los define (el único set numérico cerrado es el de % de avance de presupuesto de M5, que es otra métrica).
- **Acción:** aclarar que el `semaforo` de `/summary` no es el de Home; el de Home (multi-señal) aún no está implementado.

---

## Dónde nos adelantamos / inventamos regla (para escalar a Producto)

| Tema | Estado en spec | Qué hicimos igual | Riesgo |
|------|----------------|-------------------|--------|
| Ingreso principal multi-fuente | Pendiente | Suma `Sueldo`+`Honorarios` | Da 0 para pensión/honorarios/transferencia |
| Recurrencia técnica | Pendiente | Proxy `flowType`/`isAntExpense` | Top 5 no refleja recurrencia real |
| Umbrales de semáforo | Pendiente (multi-señal) | Ratio 0.80/1.0 por cartola | No es el semáforo de Home |
| Certeza de categorización | Definida (3 niveles) | Solo 2 niveles | Falta C-02 "media → validación" |
| Badge de completitud | Pendiente umbral | No implementado | Falta indicador de confianza |

---

## Top acciones de alineación

1. 🔴 **`hasRecurringPayments` ≠ `hasFixedExpenses`** en el backend — hoy son idénticos; la spec los exige distintos. (Ya identificado en la auditoría de código.)
2. 🔴 **Tercer nivel de certeza** (C-02 media → validación) en `resolveStatus`.
3. 🔴 **Instrumentos y completitud**: mover/definir en backend (hoy instrumentos solo en front, completitud en ningún lado).
4. 🟡 **Ingreso principal**: cerrar regla de desempate + exponer tipo/origen.
5. 🟡 **Semáforo de Home** (multi-señal) es un módulo aparte no implementado; el de `/summary` es solo un proxy por cartola.

> Todos los puntos 🔴/🟡 dependen de **decisiones de Producto aún abiertas** (recurrencia, umbrales, completitud). Conviene llevarlos como preguntas cerradas a la reunión de alineación antes de tocar código.
