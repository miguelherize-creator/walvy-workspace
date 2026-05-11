# Módulo 5 — Requerimientos

**Módulo:** Catálogos, Ingesta y Movimientos  
**Layers:** 7 · 8 · 9  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 5

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Registrar movimiento manualmente | ✅ Incluido |
| Importar cartola (PDF/CSV) | ✅ Incluido |
| Categorizar movimiento | ✅ Incluido |
| Revisión de importación (línea por línea) | ✅ Incluido |
| Marcar gasto como hormiga | ✅ Incluido |
| Gestionar instrumentos financieros propios | ✅ Incluido |
| Categorías personalizadas de usuario | ✅ Incluido |
| Historial de reclasificaciones | ✅ Incluido |
| Integración automática con bancos (Open Banking) | ❌ No incluido en MVP |
| Clasificación IA automática sin confirmación | ❌ No incluido en MVP |

---

## Requerimientos Funcionales

### RF-01 — Registrar movimiento manual

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Crear movimiento financiero manualmente |
| **Descripción** | El usuario registra un ingreso o egreso de forma manual. |
| **Inputs** | `operation_date`, `raw_description`, `movement_direction`, `amount_in` o `amount_out`, `currency_id`, `category_id`, `category_leaf_id` (opt), `financial_instrument_id` (opt), `payment_instrument_type` (opt) |
| **Reglas** | - `source_type = 'manual'`. - `movement_status_id → active`. - Solo uno de `amount_in`/`amount_out` > 0. - Si `category_id` es NULL: agrega a `movement_review_queue` con `review_reason = uncategorized`. |

---

### RF-02 — Importar cartola

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | Cargar archivo de movimientos |
| **Descripción** | El usuario sube un archivo (PDF o CSV) de su banco. El backend parsea y crea `import_line_items` para revisión. |
| **Reglas** | - Crea `file_upload` con `file_status = pending`. - El job de ingesta parsea el archivo → crea `import_line_items` con `user_review_status = pending`. - `source_fingerprint` se calcula por línea para detectar duplicados. - Dispara `gamification_events: statement_imported` al completar. |

---

### RF-03 — Revisar y confirmar importación

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | Revisar ítems de importación |
| **Descripción** | El usuario revisa las líneas importadas, acepta o rechaza cada una. Al aceptar se crea el `financial_movement`. |
| **Reglas** | - `user_review_status = accepted` → INSERT en `financial_movement` con `source_type = document`. - `user_review_status = rejected` → no se crea movimiento. - `user_review_status = edited` → el usuario modificó el ítem antes de aceptar. - El sistema muestra `movement_classification_suggestions` con la sugerencia de categoría. |

---

### RF-04 — Categorizar movimiento

| Campo | Detalle |
|-------|---------|
| **ID** | RF-04 |
| **Nombre** | Asignar categoría a movimiento |
| **Descripción** | El usuario asigna o cambia la categoría de un movimiento. |
| **Reglas** | - Solo categorías `is_leaf = true` pueden asignarse. - Al cambiar: INSERT en `movement_classification_history`. - `classification_method = 'manual'` si el usuario lo hizo manualmente; `'assisted'` si aceptó una sugerencia. - Si el movimiento estaba en `movement_review_queue` por `uncategorized`: marcar como `resolved`. |

---

### RF-05 — Gestionar instrumentos financieros

| Campo | Detalle |
|-------|---------|
| **ID** | RF-05 |
| **Nombre** | CRUD de instrumentos financieros del usuario |
| **Descripción** | El usuario registra sus cuentas y tarjetas para asociarlas a movimientos y deudas. |
| **Reglas** | - CRUD sobre `user_financial_instrument`. - `financial_institution_id` es opcional (puede ser efectivo u otro instrumento sin institución). - Desactivar (`is_active = false`) no borra; los movimientos asociados se conservan. |

---

### RF-06 — Configurar reglas de gasto hormiga

| Campo | Detalle |
|-------|---------|
| **ID** | RF-06 |
| **Nombre** | Definir reglas de ant_expense |
| **Descripción** | El usuario configura qué movimientos se marcan automáticamente como gastos hormiga. |
| **Reglas** | - INSERT/UPDATE en `ant_expense_rules`. - El job de ingesta evalúa `ant_expense_rules` y actualiza `financial_movement.is_ant_expense`. - Si `max_amount` definido: movimientos con `amount_out <= max_amount` de esa categoría = hormiga. |

---

## Requerimientos No Funcionales

### RNF-01 — Deduplicación de importaciones
El índice único `(user_id, source_fingerprint)` impide crear el mismo movimiento dos veces desde el mismo archivo. El sistema retorna un 409 si el movimiento ya existe.

### RNF-02 — El usuario siempre confirma
El motor de clasificación automática crea `movement_classification_suggestions` pero **nunca** crea `financial_movement` sin la acción explícita del usuario (`user_review_status = accepted`).

### RNF-03 — Auditoría de reclasificaciones
Cada cambio de categoría en un movimiento existente genera un `movement_classification_history`. No se puede editar ni borrar este log.

### RNF-04 — Categorías del sistema vs usuario
Las categorías con `owner_user_id IS NULL` son del sistema (no modificables por el usuario). Las del usuario son privadas y pueden tener el mismo nombre que las del sistema sin colisión.
