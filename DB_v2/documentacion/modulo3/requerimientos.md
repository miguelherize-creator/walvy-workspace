# Módulo 3 — Requerimientos

**Módulo:** Home (Seguimiento, Visualización y Motivación)  
**Layers:** 14 (Gamificación) · 15 (Mensajería y Recomendaciones) · 18 (Read Models) · 19 (Vistas)  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 3 (Home)

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Resumen del mes (ingresos, gastos, balance) | ✅ Incluido |
| Semáforo financiero (verde / amarillo / rojo) | ✅ Incluido |
| Gráfico por categoría de gastos (gasto hormiga) | ✅ Incluido |
| Gráfico de cumplimiento de presupuesto | ✅ Incluido |
| Gráfico de reducción de deudas | ✅ Incluido |
| Recomendaciones básicas contextuales por pantalla | ✅ Incluido |
| Gamificación básica (puntaje, logros) | ✅ Incluido |
| Visualizar logros del día | ✅ Incluido |
| Proyecciones financieras a más de 12 meses | ❌ No incluido en MVP |
| Simulaciones complejas de escenarios | ❌ No incluido en MVP |
| Modelos predictivos con machine learning | ❌ No incluido en MVP |
| Descarga / exportación de reportes | ❌ No incluido en MVP |
| Rankings públicos o competencia social | ❌ No incluido en MVP |

---

## Requerimientos Funcionales

### RF-01 — Ver resumen del home

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Cargar dashboard del home |
| **Descripción** | Al abrir la app, el usuario ve el estado consolidado del mes: semáforo, balance, capacidad de ahorro, próximos pagos y avance de deudas. |
| **Fuente de datos** | `v_user_home_month` — consolida los 4 read models en un único payload |
| **Reglas** | - El backend consulta los read models, no recalcula en tiempo real. - Si no hay datos del mes corriente (usuario nuevo), el home muestra estado vacío con CTA para importar movimientos o registrar manualmente. - El semáforo (`traffic_light_status`) se determina en el job de cálculo, no en el request. - `data_quality_level` se muestra como aviso al usuario si es `low` o `medium` ("Tu diagnóstico mejora si importas más movimientos"). |
| **Output** | Payload con semáforo, balance del mes, próximos pagos, deuda prioritaria, fugas y recomendaciones activas. |

---

### RF-02 — Semáforo financiero

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | Mostrar semáforo de salud financiera mensual |
| **Descripción** | El semáforo indica en verde/amarillo/rojo el estado financiero del mes. |
| **Reglas** | - Valor en `user_month_diagnosis_summary.traffic_light_status`. - Los `traffic_light_reason_codes` explican al usuario por qué tiene ese color. - El job recalcula el semáforo cuando cambia algún movimiento, pago o deuda del mes. - `app_user.current_financial_health_level_id` es el nivel general (distinto al semáforo mensual): se actualiza con menor frecuencia por un job separado. |
| **Output** | `traffic_light_status` + `traffic_light_reason_codes` visibles en home. |

---

### RF-03 — Gráficos del home

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | Mostrar gráficos de categorías, presupuesto y deuda |
| **Descripción** | El home expone tres gráficos: categorías de gasto (con gasto hormiga), cumplimiento de presupuesto y reducción de deuda. |
| **Fuente de datos** | - **Categorías / fugas:** `user_month_leaks_summary.top_categories` + `ant_expense_total` - **Presupuesto:** `user_month_diagnosis_summary.visible_savings_capacity_pct` + datos de `budget_plan` (Módulo 5) - **Deuda:** `user_month_debt_priority_summary` — saldo restante y fecha estimada de salida |
| **Reglas** | - Los gráficos son de solo lectura; no hay interacción de escritura desde el home. - Si no hay datos suficientes, se muestra el estado vacío correspondiente con CTA contextual. |

---

### RF-04 — Recomendaciones contextuales

| Campo | Detalle |
|-------|---------|
| **ID** | RF-04 |
| **Nombre** | Mostrar recomendaciones por pantalla |
| **Descripción** | Cada pantalla principal (home, presupuesto, deudas, pagos) muestra recomendaciones generadas por el motor de mensajería. |
| **Reglas** | - El backend filtra `message_event` por `user_id` + `context` de la pantalla + `status = created` (no mostrados aún). - Se muestran ordenados por `message_rule.priority` ASC (1 = más urgente primero). - Al mostrar: `message_event.status → shown`, `shown_at = now()`. - El job de análisis crea nuevos `message_event` cuando detecta condiciones (umbral de presupuesto cruzado, deuda sin movimiento, etc.). - `suppressed_until`: un mensaje snoozed no vuelve a aparecer hasta esa fecha. |
| **Output** | Lista de cards de recomendación con texto, `deep_link` y evidencia del `payload`. |

---

### RF-05 — Interacción con recomendación

| Campo | Detalle |
|-------|---------|
| **ID** | RF-05 |
| **Nombre** | Registrar acción del usuario sobre una recomendación |
| **Descripción** | El usuario puede abrir, descartar, posponer o completar una recomendación. |
| **Acciones** | `opened` · `dismissed` · `snoozed` · `completed` |
| **Reglas** | - `opened`: registra interacción, navega al `deep_link`. `message_event` sigue en `shown`. - `dismissed`: registra interacción. `message_event.status → suppressed`, `suppressed_until = NULL` (suprimido permanentemente). - `snoozed`: registra interacción. `suppressed_until = now() + intervalo configurable` (ej: 3 días). - `completed`: registra interacción. `message_event.status → suppressed`. El job no regenera el mismo mensaje mientras la condición que lo originó esté resuelta. |
| **Output** | `user_message_interaction` creado; `message_event` actualizado. |

---

### RF-06 — Registrar evento de gamificación

| Campo | Detalle |
|-------|---------|
| **ID** | RF-06 |
| **Nombre** | Otorgar puntos al usuario |
| **Descripción** | Cuando el usuario completa una acción valorada (ej: registrar un pago, cumplir el presupuesto), el backend registra el evento y actualiza el cache de puntos. |
| **Reglas** | - El backend busca en `gamification_rules` la regla activa con `event_type` correspondiente. - Si la regla existe y `is_active = true`: crea `gamification_events` con el snapshot de `points`. - Actualiza `user_gamification_stats.total_points` y recalcula `level`. - El log `gamification_events` es inmutable — nunca se modifica. - Si la regla no existe o `is_active = false`: no se otorgan puntos (no error). |
| **Output** | `gamification_events` creado. `user_gamification_stats` actualizado. |

---

### RF-07 — Ver puntaje y logros recientes

| Campo | Detalle |
|-------|---------|
| **ID** | RF-07 |
| **Nombre** | Mostrar gamificación en el home |
| **Descripción** | El home muestra el puntaje acumulado, el nivel actual y los logros más recientes del día. |
| **Reglas** | - `user_gamification_stats` da el total y nivel actual (cache). - `gamification_events` filtrado por `created_at >= today` da los logros del día. - El backend no recalcula el total en cada request; usa el cache de `user_gamification_stats`. - `last_computed_at` indica si el cache está fresco; si tiene más de X minutos, el backend puede forzar recalculo. |
| **Output** | `{ total_points, level, today_events: [...] }` |

---

### RF-08 — Recalcular read models (job)

| Campo | Detalle |
|-------|---------|
| **ID** | RF-08 |
| **Nombre** | Actualizar snapshots del home |
| **Descripción** | Un job periódico recalcula los 4 read models cuando detecta cambios en los datos fuente. |
| **Reglas** | - El job compara `source_watermark_at` del snapshot con el `updated_at` más reciente de las tablas fuente. - Si hay cambios: recalcula y hace UPSERT en el read model correspondiente. - `rule_version` se actualiza si cambia el algoritmo de cálculo (permite auditar cambios de regla). - En ausencia de datos suficientes: el read model queda con `data_quality_level = low` y valores en 0. - El job no bloquea la lectura del home — los snapshots anteriores siguen siendo válidos hasta que el job termine. |

---

## Requerimientos No Funcionales

### RNF-01 — Latencia del home
El endpoint del home debe responder en menos de 200ms. Los read models son la garantía: el backend solo hace SELECTs sobre snapshots pre-calculados, sin JOINs pesados en tiempo de request.

### RNF-02 — Reglas de mensajería sin deploy
Agregar o desactivar una regla de recomendación = INSERT/UPDATE en `message_rule`. No requiere código. El job de análisis la lee en el próximo ciclo.

### RNF-03 — Reglas de gamificación sin deploy
Agregar o modificar puntos de un evento = INSERT/UPDATE en `gamification_rules` desde el backoffice. El campo `updated_by_admin_id` trazabiliza quién hizo el cambio.

### RNF-04 — Inmutabilidad del log de gamificación
`gamification_events` nunca se modifica ni elimina (salvo borrado lógico del usuario). Es el registro de verdad de qué puntos ganó el usuario y cuándo.

### RNF-05 — Supresión inteligente de recomendaciones
El motor nunca debe mostrar el mismo mensaje dos veces seguidas si el usuario ya lo descartó (`dismissed`). Ni debe mostrar mensajes de un mes anterior si ya pasó el período.

### RNF-06 — Versionado de algoritmos
`rule_version` en todos los read models permite detectar snapshots calculados con una versión antigua del algoritmo. Si se cambia la lógica de cálculo, el job puede forzar el recalculo de todos los snapshots con `rule_version != 'current'`.
