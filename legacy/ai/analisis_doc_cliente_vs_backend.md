# Análisis: Documento del Cliente vs. Backend + Spec Leonardo
**Fecha:** 2026-04-19  
**Fuente cliente:** "Descripción funcional y levantamiento estructural del Excel de Mentoría en Finanzas Personales" v1.0  
**Fuente backend:** `Backend/backend/src/` (auth, users, cashflow)  
**Fuente Leonardo:** Especificación funcional – Carga de cartolas bancarias (Módulos 01–08)

---

## Resumen ejecutivo

El backend actual cubre bien la **capa de autenticación** y los **CRUD base de cashflow** (transacciones, categorías, subcategorías, fuentes de fondos). El modelo de datos está sorprendentemente alineado con el Excel del cliente porque los seeds ya replican sus categorías y cuentas. Sin embargo, la **capa analítica, el motor de presupuestos, el motor de deudas y el motor de mensajes** están prácticamente ausentes.

La spec de Leonardo cubre la ingesta de cartolas como pipeline de entrada, lo que alimenta correctamente la base transaccional. Pero el diagnóstico final que describe Leonardo depende de módulos backend que aún no existen.

**Cobertura estimada por capa:**

| Capa | Cobertura |
|------|-----------|
| Auth / Registro / Perfil | ✅ 100% |
| Transacciones CRUD + tipos | ✅ 85% |
| Categorías y subcategorías | ✅ 80% |
| Fuentes de fondos (cuentas) | ✅ 75% |
| Modelo CashFlow red (Origen → Destino) | ⚠️ 40% |
| Gastos Hormiga (reglas + analytics) | ⚠️ 35% |
| Analítica e indicadores financieros | ❌ 5% |
| Módulo Presupuesto (Sprint 5) | ❌ 0% |
| Motor de Deudas BLDN (Sprint 6) | ❌ 0% |
| Motor de mensajes / recomendaciones | ❌ 0% |
| Etiquetas funcionales (tags) | ❌ 0% |
| Carga de cartolas – pipeline entrada | ✅ Leonardo cubre el flujo UI |

---

## 1. Lo que el backend YA cubre bien

### 1.1 Transacciones

El `Transaction` entity + `CreateTransactionDto` mapean bien al núcleo del Excel:

| Campo Excel (A. CashFlow-BD) | Campo backend | Estado |
|------------------------------|---------------|--------|
| Fecha | `occurredOn` | ✅ |
| Descripción Banco | `description` / `externalRef` | ⚠️ ver gap #1 |
| Egreso / Ingreso | `amount` + `movementType: expense/income` | ✅ |
| Movimiento (Egreso/Ingreso) | `movementType: income/expense/transfer` | ✅ |
| Tipo Movimiento (Fijo/Variable) | `flowType: fixed/variable` | ✅ |
| Categoría | `categoryId` | ✅ |
| Subcategoría | `subcategoryId` | ✅ |
| Institución Financiera | `fundingSourceId` | ✅ |
| Gastos Hormiga flag | `isAntExpense` | ✅ |
| Traspaso entre cuentas | `movementType: transfer` | ✅ (parcial) |
| Soft delete | `deletedAt` | ✅ |

### 1.2 Categorías y subcategorías

Los seeds (`category.seed.json`) replican exactamente las categorías del Excel:
- Empleador, Hogar, Familia, Entretenimiento, Inversiones, Gastos_Personales, Creditos, Efectivo, Otros, Movilizacion

La estructura jerárquica (category → subcategory) y el soporte de categorías de sistema vs. usuario están implementados.

### 1.3 Fuentes de fondos

Los seeds crean por defecto: `cc` (checking), `lc` (credit_line), `tc` (credit_card), `inv_01` (investment) — que mapean a los instrumentos principales del Excel (Cuenta Corriente, Línea de Crédito, Tarjeta de Crédito, Inversiones).

### 1.4 Regla de gastos hormiga

Existe la entidad `AntExpenseRule` con `maxAmount` y `categoryId`. Cubre el concepto base.

---

## 2. Gaps por área

---

### GAP #1 — Descripción banco vs. descripción procesada (CRÍTICO)

**Qué dice el cliente:** La "Descripción Banco" es el insumo principal de auto-categorización. Debe conservarse como dato original intacto. Es diferente de la "Descripción General" calculada (concatenación de categoría + subcategoría + glosa).

**Situación actual:** Solo existe un campo `description` (texto libre) y `externalRef`. No hay separación entre glosa original del banco y descripción editada por el usuario.

**Impacto:** La auto-categorización del pipeline de Leonardo necesita la glosa original para hacer matching. Si el usuario la edita, se pierde. También afecta la detección de duplicados y el cálculo de Fijo/Variable.

**Solución:** Añadir campo `bankDescription TEXT NULL` en la entidad Transaction para conservar la glosa original del banco. El campo `description` queda para la descripción procesada/editada.

---

### GAP #2 — Modelo CashFlow red: Origen + Flujo de Efectivo (CRÍTICO)

**Qué dice el cliente:** Los campos `Origen` (¿de dónde sale el dinero?) y `Flujo de Efectivo` (¿adónde va?) son **estructurales**, no decorativos. Permiten trazar el viaje del dinero como una red de nodos. Ejemplos:
- Pago tarjeta: Origen = Cuenta Corriente, Destino = Tarjeta de Crédito  
- Compra en café: Origen = Tarjeta de Crédito, Destino = Tercero/Comercio
- Traspaso: Origen = Cuenta Corriente, Destino = Cuenta Corriente (otro)

**Situación actual:** Solo existe `fundingSourceId` (fuente de origen). No hay campo para el **destino** del flujo. Para transferencias entre cuentas propias no se puede registrar adónde fue el dinero.

**Impacto:** Las vistas "Presupuesto Vivo", "Impacto Real" y el cashflow anual filtran por Flujo de Efectivo. Sin este campo, esas vistas no se pueden construir correctamente.

**Solución:** Añadir `destinationFundingSourceId UUID NULL` en Transaction (FK a funding_sources, SET NULL on delete). Puede ser NULL para transacciones simples; se llena en transfers y en casos donde el destino es una cuenta propia.

---

### GAP #3 — Estado "Categorizar" (pendiente de clasificación) (IMPORTANTE)

**Qué dice el cliente:** "Categorizar" es un estado funcional válido, no un error. Los movimientos sin categorizar deben mantenerse visibles como backlog para revisión manual o asistida. No deben perderse ni ocultarse.

**Situación actual:** `categoryId` es nullable. No hay flag ni estado explícito para diferenciar "no tiene categoría porque fue creado sin ella" vs. "está en cola para categorización pendiente".

**Impacto:** No se puede filtrar "movimientos sin categorizar" ni mostrar una alerta de calidad de dato. El pipeline de Leonardo necesita marcar transacciones importadas como "pendientes de revisión" si la confianza de categorización es baja.

**Solución:** Añadir `categorizationStatus VARCHAR(20) DEFAULT 'categorized'` en Transaction: `'categorized'` | `'pending_review'` | `'uncategorized'`. Los movimientos importados desde cartola con confianza baja se crean en `pending_review`.

---

### GAP #4 — Saldo en cuenta (MODERADO)

**Qué dice el cliente:** El campo `Saldo en Cuenta` es funcionalmente requerido aunque en el Excel no tiene fórmula activa visible.

**Situación actual:** No existe en la entidad Transaction.

**Nota:** Este campo se puede calcular a posteriori sumando ingresos y restando egresos por funding_source. No es necesariamente un campo que se persiste por transacción; puede ser una vista calculada. **Recomendación: implementar como endpoint analítico, no como campo en la tabla.**

---

### GAP #5 — Tipo `mortgage` en FundingSourceKind (MENOR)

**Qué dice el cliente:** El Excel menciona "Hipotecario" como destino de flujo posible en `Flujo de Efectivo`.

**Situación actual:** El enum `FundingSourceKind` tiene: `checking`, `credit_line`, `credit_card`, `investment`, `cash`, `other`. No tiene `mortgage`.

**Solución:** Añadir `mortgage` al enum. Impacto mínimo.

---

### GAP #6 — Lógica de detección Fijo/Variable (IMPORTANTE)

**Qué dice el cliente:** Un movimiento es "Fijo" si la misma glosa (descripción banco) aparece más de una vez en el histórico (COUNTIF). Es "Variable" si es único.

**Situación actual:** El campo `flowType` existe pero es un campo libre que el usuario o el sistema de importación debe llenar manualmente. No hay lógica automática de detección.

**Impacto:** Las reglas de mensajes como "costo fijo detectado por recurrencia > 3 veces" y la etiqueta "Recurrente" dependen de esto.

**Solución:** Implementar en `TransactionsService` una lógica que al crear/importar una transacción, consulte si la `bankDescription` ha aparecido antes (> 1 vez → Fijo, si > 3 → candidato a "Recurrente"). Puede ejecutarse en background al importar cartola.

---

### GAP #7 — Reglas completas de Gastos Hormiga (IMPORTANTE)

**Qué dice el cliente:** Un gasto es "hormiga" si:
1. Es egreso (no ingreso, no traspaso)
2. Monto ≤ CLP 16.000
3. No es un traspaso entre cuentas
4. No está en subcategorías excluidas (ej: préstamos)

**Situación actual:** La entidad `AntExpenseRule` solo tiene `maxAmount` y `categoryId`. El campo `isAntExpense` en Transaction es un boolean que alguien debe setear.

**Impacto:** Sin la lógica completa, se marcarán como hormiga transacciones que no deberían (ej: un traspaso de CLP 10.000).

**Solución:** El servicio de transacciones debe calcular automáticamente `isAntExpense` al crear/importar, aplicando las 4 condiciones. La entidad `AntExpenseRule` debería añadir un campo `excludedSubcategoryIds UUID[]` o una tabla de exclusiones.

---

### GAP #8 — Detección de movimientos duplicados (MODERADO)

**Qué dice el cliente:** Si coinciden monto + fecha y hay alta similitud contextual → marcar para validación del usuario.

**Situación actual:** No existe ninguna lógica de detección de duplicados.

**Solución:** Al importar desde cartola (pipeline Leonardo), antes de guardar cada movimiento, verificar si ya existe un registro con el mismo `amount`, `occurredOn` y `bankDescription` similar para el mismo usuario → marcar con `categorizationStatus: 'pending_review'` y `duplicateFlag: true`.

---

### GAP #9 — Módulo Presupuesto (Sprint 5) — AUSENTE COMPLETO

**Qué dice el cliente:** La pestaña D. Reporte de Gastos Mensuales compara egreso real vs. presupuesto asignado por mes y categoría, mostrando variación en $ y %.

**Situación actual:** No existe tabla `budgets` ni lógica de presupuesto.

**Entidades necesarias:**
```
budgets: id, user_id, period_year, period_month, created_at, updated_at
budget_items: id, budget_id, category_id, subcategory_id?, amount, notes
```

**Endpoints necesarios:**
- `POST /budgets` — crear presupuesto mensual
- `GET /budgets/:year/:month` — obtener presupuesto con comparativo real vs. planeado
- `GET /budgets/:year/:month/variance` — variaciones por categoría

---

### GAP #10 — Motor de Deudas BLDN (Sprint 6) — AUSENTE COMPLETO

**Qué dice el cliente:** La pestaña B. BLDN ordena y proyecta la salida de deudas con lógica híbrida (no bola de nieve pura). Combina: monto total, cuotas restantes, pago mínimo, tasa de interés (CAE). Muestra fecha estimada de liquidación y capacidad de ahorro liberada acumulada.

**Situación actual:** No existen tablas ni lógica para deudas.

**Entidades necesarias:**
```
debts: id, user_id, name, principal_amount, current_balance, installments_total, 
       installments_remaining, interest_rate_pct, minimum_payment, acquired_at,
       priority_score, is_active, created_at, updated_at

debt_simulations: id, user_id, extra_monthly_payment, one_time_payment,
                  calculated_at, result_json
```

**Lógica de priorización (4 criterios del Excel):**
1. Por total deuda (rank ascendente)
2. Por N° cuotas restantes (priorizar las que quedan < 3)
3. Por pago mínimo
4. Por CAE/tasa (tramos: 40-43%=1, 43-46%=2, 46-49%=3, 49-70%=4)
5. Score final = promedio ponderado de los 4 rankings

---

### GAP #11 — Motor de mensajes y recomendaciones — AUSENTE COMPLETO

**Qué dice el cliente:** 15+ reglas de activación con condición, umbral, mensaje, tipo, prioridad, frecuencia y estado (mostrado/leído/aceptado/descartado). Tipos: Alertas, Focos, Recomendaciones, Educativos, Validaciones.

**Situación actual:** No existe ninguna entidad ni servicio para mensajes.

**Entidades necesarias (simplificadas para MVP):**
```
messages: id, user_id, rule_key, type (alert/insight/recommendation/validation),
          priority (1-5), title, body, cta_label, cta_action,
          source_indicator, source_value, period_ref,
          status (pending/shown/read/accepted/dismissed/snoozed),
          expires_at, shown_at, read_at, actioned_at, created_at

message_rules: id, rule_key, name, source, condition_expr, threshold,
               message_template, type, default_priority, 
               frequency (once/daily/weekly/monthly), is_active
```

**Reglas prioritarias para MVP** (ordenadas por impacto):
1. Sobreconsumo presupuestario por categoría
2. Capacidad de ahorro negativa
3. Movimiento sin categorizar (calidad de dato)
4. Aumento de gastos hormiga
5. Presión del crédito sobre cashflow
6. Semáforo del mes (síntesis)

---

### GAP #12 — Etiquetas funcionales (tags) — AUSENTE

**Qué dice el cliente:** Etiquetas simples que se superponen a transacciones/categorías sin reemplazar la categoría contable:
- `fuga_activa` — microgasto recurrente que erosiona el mes
- `recurrente` — glosa repetida > 3 veces
- `planificable` — gasto previsible
- `no_planificado` — gasto sin presupuesto
- `urgente` — pago próximo o acción dominante
- `recuperable` — corrección que libera ahorro visible

**Solución más simple:** Añadir `tags TEXT[] NULL` a la entidad Transaction y una tabla `transaction_tags` o simplemente un array de enum values. No requiere una tabla compleja.

---

### GAP #13 — Endpoints de analítica — AUSENTE COMPLETO

**Qué dice el cliente:** Las pantallas del dashboard necesitan:

| Vista | Indicadores necesarios |
|-------|------------------------|
| Tu mes hoy | Capacidad de ahorro, impacto CF, semáforo |
| Presupuesto vivo | Real vs. presupuesto por categoría, variación |
| Impacto real | CF sin créditos, ahorro liberado estimado |
| Gastos hormiga | Total mes, distribución, recurrencia |
| Motor de deudas | Priorización, fecha liquidación, flujo liberado |

**Situación actual:** El único endpoint de consulta es `GET /transactions` (lista plana). No hay ningún endpoint de agregación o analítica.

**Endpoints prioritarios para Sprint 4+:**
```
GET /analytics/summary?year=&month=          → resumen del mes (income, expenses, savings)
GET /analytics/categories?year=&month=       → distribución por categoría
GET /analytics/cashflow?year=&month=         → indicadores Capacidad Ahorro + Impacto CF
GET /analytics/ant-expenses?year=&month=     → total hormiga + detalle
GET /analytics/spending-report?year=&month=  → real vs presupuesto
```

---

### GAP #14 — Gobernanza de subcategorías personalizadas (MENOR)

**Qué dice el cliente:** El usuario puede crear subcategorías personalizadas solo dentro de categorías existentes, con un **límite de 5 subcategorías activas por categoría por usuario** en MVP.

**Situación actual:** El `SubcategoriesService` crea subcategorías sin validar el límite de 5.

**Solución:** En `SubcategoriesService.create()`, antes de guardar, contar las subcategorías activas del usuario para esa categoría. Si ≥ 5, lanzar `BadRequestException`.

---

## 3. Relación con la spec de Leonardo

La spec de Leonardo cubre la **ingesta** (módulos 01–08: propuesta → formato → carga → extracción → categorización → revisión → diagnóstico → resultado). Se integra con el backend así:

| Módulo Leonardo | Endpoint backend que consume | Estado |
|-----------------|------------------------------|--------|
| 04 - Extracción | `POST /cartolas/upload` (a implementar) | ❌ No existe |
| 04 - Polling estado | `GET /cartolas/jobs/:id/status` (a implementar) | ❌ No existe |
| 06 - Revisión usuario | `POST /transactions/bulk` (a implementar) | ❌ No existe |
| 07 - Generar diagnóstico | `POST /analytics/diagnostic` (a implementar) | ❌ No existe |
| 08 - Ver diagnóstico | `GET /analytics/diagnostic/:id` (a implementar) | ❌ No existe |

El diagnóstico de Leonardo (módulo 07) produce: semáforo, presupuesto sugerido, capacidad de pago, recomendaciones y detección de deudas. Todo esto requiere los GAP #9, #10 y #11 resueltos primero.

**Observación clave:** Leonardo asume que el backend Python procesa el archivo y devuelve movimientos normalizados. El NestJS necesita un endpoint de ingesta bulk (`POST /transactions/bulk`) que reciba esa lista y la persista con `categorizationStatus: 'pending_review'` para transacciones de baja confianza.

---

## 4. Priorización de gaps para MVP

### Bloque 1 — Necesario ANTES de Sprint 4 (transacciones)
| # | Gap | Esfuerzo |
|---|-----|----------|
| 1 | Añadir `bankDescription` a Transaction | Bajo |
| 2 | Añadir `destinationFundingSourceId` a Transaction | Bajo |
| 3 | Añadir `categorizationStatus` a Transaction | Bajo |
| 5 | Añadir `mortgage` a FundingSourceKind | Muy bajo |
| 6 | Lógica auto-detección Fijo/Variable | Medio |
| 7 | Lógica completa Gastos Hormiga (con exclusiones) | Medio |

### Bloque 2 — Necesario para Sprint 4 (análitica básica)
| # | Gap | Esfuerzo |
|---|-----|----------|
| 13 | Endpoints analítica: resumen mes, distribución, indicadores | Alto |
| 4 | Balance en cuenta (como endpoint calculado) | Medio |
| 8 | Detección duplicados en ingesta bulk | Medio |

### Bloque 3 — Sprint 5 (presupuesto)
| # | Gap | Esfuerzo |
|---|-----|----------|
| 9 | Módulo Presupuesto: tablas + endpoints | Alto |
| 14 | Límite 5 subcategorías personalizadas | Muy bajo |

### Bloque 4 — Sprint 6 (deudas)
| # | Gap | Esfuerzo |
|---|-----|----------|
| 10 | Motor BLDN: tablas + lógica priorización + simulación | Muy alto |

### Bloque 5 — Sprint 6-7 (mensajes)
| # | Gap | Esfuerzo |
|---|-----|----------|
| 11 | Motor de mensajes: entidades + reglas prioritarias | Alto |
| 12 | Etiquetas funcionales en transacciones | Bajo |

---

## 5. Cambios de schema requeridos (Bloque 1)

```sql
-- En transactions: 3 campos nuevos
ALTER TABLE transactions 
  ADD COLUMN bank_description TEXT NULL,
  ADD COLUMN destination_funding_source_id UUID NULL 
    REFERENCES funding_sources(id) ON DELETE SET NULL,
  ADD COLUMN categorization_status VARCHAR(20) NOT NULL DEFAULT 'categorized';

-- Valores: 'categorized' | 'pending_review' | 'uncategorized'

-- Nuevo enum en funding_sources
-- Añadir 'mortgage' al CHECK constraint o al enum de TypeORM
```

---

## 6. Conclusión

El backend es una **buena base** pero actualmente solo implementa el plano de datos. Los módulos de negocio que dan valor al usuario (analítica, presupuesto, deudas, mensajes) están todos pendientes según el sprint plan (Sprints 4–8). El documento del cliente define exactamente las reglas de negocio que esos sprints deben implementar.

La **mayor deuda técnica inmediata** es añadir los 3 campos al schema de `transactions` (Bloque 1) antes de que el equipo de Python empiece a enviar movimientos desde cartolas — si no, no habrá forma de guardar la glosa original ni el estado de categorización.
