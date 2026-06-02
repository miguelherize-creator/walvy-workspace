# Módulo 5 — Catálogos, Ingesta y Movimientos

**Layers cubiertos:** 7 (Catálogos Financieros) · 8 (Pipeline de Ingesta) · 9 (Movimientos)  
**Corresponde a:** CSV Módulo 5 — Movimientos e Ingesta  
**Estado MVP:** ✅ Incluido

---

## 1. Propósito del módulo

El Módulo 5 es el **núcleo transaccional** de Walvy. Gestiona:
- Los catálogos de instituciones financieras, instrumentos del usuario y categorías (Layer 7).
- El pipeline de importación de cartolas y archivos bancarios (Layer 8).
- Los movimientos financieros — fuente de verdad de ingresos y gastos (Layer 9).

Sin datos de este módulo, los read models del home (Módulo 3) no tienen nada que mostrar.

---

## 2. Diagrama de dependencias

```
financial_institution (catálogo) ──────────────────────────────────────┐
user_financial_instrument (cuenta/tarjeta del usuario) ─────────────── ┤
cashflow_node (nodo semántico origen/destino) ──────────────────────── ┤
category (jerarquía recursiva) ──── ant_expense_rules ──────────────── ┤
                                                                        ▼
file_upload ──► import_line_items ──► movement_classification_suggestions
                                                │
                                                ▼
                                    financial_movement (fuente de verdad)
                                         │              │
                              ┌──────────┘              └──────────────────┐
                              ▼                                            ▼
                    movement_review_queue               movement_classification_history
                     (revisión pendiente)                  (auditoría de reclasificaciones)
```

---

## 3. Diagrama ERD

Ver archivo: [`modulo5.dbml`](./modulo5.dbml)

---

## 4. Tablas del módulo

### Layer 7 — Catálogos Financieros

#### 4.1 `financial_institution`

Catálogo global/por país de instituciones financieras. Administrado por el equipo de Walvy.

| Columna | Tipo | Notas |
|---------|------|-------|
| `financial_institution_id` | UUID PK | |
| `name` | VARCHAR(200) NOT NULL | Ej: "Banco Santander Chile" |
| `country_id` | BIGINT FK → country | |
| `institution_type` | VARCHAR(20) | `bank`, `wallet`, `retail`, `broker`, `cooperative`, `other` |
| `contact_email` | VARCHAR(320) NULL | |
| `contact_phone` | VARCHAR(40) NULL | |
| `has_api` | BOOLEAN DEFAULT false | Si la institución tiene integración API |
| `api_base_url` | VARCHAR(500) NULL | Obligatorio si `has_api = true` |
| `api_notes` | TEXT NULL | Notas técnicas de la integración |
| `is_active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Constraint:** UNIQUE `(country_id, name)`. CHECK: si `has_api = false` → `api_base_url IS NULL`.

---

#### 4.2 `user_financial_instrument`

Cuentas, tarjetas y otros instrumentos financieros registrados por el usuario.

| Columna | Tipo | Notas |
|---------|------|-------|
| `financial_instrument_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `financial_institution_id` | UUID NULL FK → financial_institution | Institución (opcional si es efectivo/informal) |
| `instrument_type` | VARCHAR(30) | `checking_account`, `credit_card`, `debit_card`, `cash`, `credit_line`, `investment`, `loan`, `other` |
| `instrument_name` | VARCHAR(120) NOT NULL | Ej: "Tarjeta Visa BCI" |
| `monthly_cost` | NUMERIC(19,4) NULL | Costo mensual del instrumento (comisión, mantención) |
| `benefits_notes` | TEXT NULL | Notas de beneficios (cashback, puntos) |
| `is_active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

---

#### 4.3 `cashflow_node`

Nodos semánticos que representan el origen o destino del dinero en un movimiento. Permite clasificar "de dónde viene" y "a dónde va" sin depender de categorías.

| Columna | Tipo | Notas |
|---------|------|-------|
| `cashflow_node_id` | UUID PK | |
| `name` | VARCHAR(120) NOT NULL | Ej: "Sueldo", "Supermercado Unimarc", "Cuenta Ahorro" |
| `node_type` | VARCHAR(20) | `origin`, `destination`, `instrument`, `third_party`, `pocket` |
| `is_liquidity_source` | BOOLEAN | True si este nodo inyecta liquidez (ingresos) |
| `is_internal_node` | BOOLEAN | True si es una transferencia interna (no cambia riqueza neta) |
| `owner_user_id` | UUID NULL FK → app_user | NULL = nodo del sistema; UUID = nodo personalizado del usuario |
| `is_active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

---

#### 4.4 `category`

Categorías de gasto con jerarquía recursiva. Reemplaza las tablas `categories` + `subcategories` de DB v1.

| Columna | Tipo | Notas |
|---------|------|-------|
| `category_id` | UUID PK | |
| `parent_category_id` | UUID NULL FK → category | NULL = categoría raíz |
| `name` | VARCHAR(120) NOT NULL | Ej: "Alimentación", "Supermercado" |
| `is_leaf` | BOOLEAN DEFAULT true | Solo las hojas pueden asignarse a movimientos |
| `icon` | TEXT NULL | Nombre del icono |
| `color` | TEXT NULL | Color hex |
| `owner_user_id` | UUID NULL FK → app_user | NULL = categoría del sistema; UUID = personalizada por usuario |
| `governance_scope` | VARCHAR(20) | `system`, `user`, `suggested`, `approved` |
| `sort_order` | INT DEFAULT 0 | Orden de visualización |
| `is_active` | BOOLEAN DEFAULT true | |
| `replaced_by_category_id` | UUID NULL FK → category | Si esta categoría fue fusionada/reemplazada |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Índices únicos:**
- `(parent_category_id, name)` WHERE `owner_user_id IS NULL` — unicidad de categorías del sistema
- `(parent_category_id, owner_user_id, name)` WHERE `owner_user_id IS NOT NULL` — unicidad de categorías de usuario

---

#### 4.5 `ant_expense_rules`

Reglas configuradas por el usuario para marcar automáticamente gastos como "hormiga" (pequeños gastos recurrentes que drenan liquidez).

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `max_amount` | NUMERIC(19,4) NULL | Monto máximo para considerar gasto hormiga |
| `category_id` | UUID NULL FK → category | Categoría donde aplica la regla |
| `is_active` | BOOLEAN DEFAULT true | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

---

### Layer 8 — Pipeline de Ingesta

#### 4.6 `file_upload`

Registro de archivos subidos por el usuario para importar movimientos (PDFs de cartola, CSVs bancarios).

| Columna | Tipo | Notas |
|---------|------|-------|
| `file_upload_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `source_type` | VARCHAR(20) | `document`, `manual`, `integration` |
| `provider` | VARCHAR(80) NULL | Ej: `bank_santander_cl`, `csv_generic`, `fintoc` |
| `storage_path` | VARCHAR(800) NOT NULL | Ruta en S3 |
| `original_filename` | VARCHAR(255) NOT NULL | |
| `mime_type` | VARCHAR(120) NULL | |
| `file_status_id` | BIGINT FK → status | Dominio: `file_upload`. Estados: `pending`, `processing`, `processed`, `failed` |
| `records_total` | INT NULL | Total de registros en el archivo |
| `records_success` | INT NULL | Importados exitosamente |
| `records_failed` | INT NULL | Fallidos |
| `error_summary` | TEXT NULL | Resumen de errores |
| `error_details_path` | VARCHAR(800) NULL | Ruta al archivo de errores detallados |
| `uploaded_at` | TIMESTAMPTZ | |
| `processing_started_at` | TIMESTAMPTZ NULL | |
| `processed_at` | TIMESTAMPTZ NULL | |
| `correlation_id` | VARCHAR(120) NULL | Para trazabilidad distribuida |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Constraint:** `records_total = records_success + records_failed` (cuando no son NULL).

---

#### 4.7 `import_line_items`

Filas individuales de un archivo importado, pendientes de revisión del usuario. Cada fila es un posible movimiento.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `file_upload_id` | UUID FK → file_upload | |
| `row_index` | INT NULL | Número de fila en el archivo original |
| `raw_row` | JSONB NULL | Fila sin procesar |
| `normalized` | JSONB NULL | Datos normalizados por el parser |
| `user_review_status` | VARCHAR(20) | `pending`, `accepted`, `rejected`, `edited` |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

---

#### 4.8 `movement_classification_suggestions`

Sugerencias automáticas de clasificación generadas por el motor de IA/reglas. El usuario **siempre** confirma antes de que se cree el movimiento.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `import_line_id` | UUID NULL FK → import_line_items | |
| `suggested_target` | VARCHAR(20) | `debt_plan`, `bills_payable`, `transaction` |
| `confidence` | NUMERIC(4,3) NULL | Score de confianza (0.000–1.000) |
| `rule_matched` | TEXT NULL | Regla que generó la sugerencia |
| `user_decision` | VARCHAR(15) NULL | `accepted`, `ignored`, `corrected` |
| `decided_at` | TIMESTAMPTZ NULL | |
| `created_at` | TIMESTAMPTZ | |

---

### Layer 9 — Movimientos

#### 4.9 `financial_movement`

**Fuente de verdad** de todos los movimientos financieros del usuario. Combina lo mejor de Edificate (cashflow_node, classification_method) con lo operacional de Walvy (is_ant_expense, deleted_at).

| Columna | Tipo | Notas |
|---------|------|-------|
| `movement_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `operation_date` | DATE NOT NULL | Fecha del movimiento (no la fecha de procesamiento) |
| `posted_at` | TIMESTAMPTZ NULL | Fecha de acreditación en el banco |
| `raw_description` | TEXT NOT NULL | Glosa tal como vino del archivo |
| `bank_description` | TEXT NULL | Glosa del banco (si difiere) |
| `movement_direction` | VARCHAR(3) | `in` (ingreso) · `out` (egreso) |
| `amount_in` | NUMERIC(19,4) DEFAULT 0 | Monto de ingreso |
| `amount_out` | NUMERIC(19,4) DEFAULT 0 | Monto de egreso |
| `currency_id` | BIGINT FK → currency | |
| `category_id` | UUID NULL FK → category | Categoría raíz asignada |
| `category_leaf_id` | UUID NULL FK → category | Subcategoría hoja asignada |
| `classification_method` | VARCHAR(10) | `auto`, `manual`, `assisted`, `inherited` |
| `classification_confidence` | NUMERIC(5,2) NULL | 0–100 |
| `is_ant_expense` | BOOLEAN DEFAULT false | Marcado como gasto hormiga |
| `cashflow_origin_id` | UUID NULL FK → cashflow_node | De dónde proviene el dinero |
| `cashflow_destination_id` | UUID NULL FK → cashflow_node | A dónde va el dinero |
| `financial_institution_id` | UUID NULL FK → financial_institution | |
| `payment_instrument_type` | VARCHAR(15) NULL | `cash`, `debit`, `credit`, `transfer`, `other` |
| `financial_instrument_id` | UUID NULL FK → user_financial_instrument | |
| `source_type` | VARCHAR(20) | `document`, `manual`, `integration` |
| `source_reference` | VARCHAR(200) NULL | Referencia en la fuente original |
| `source_fingerprint` | VARCHAR(200) NULL | Hash para deduplicación en importaciones |
| `potential_duplicate_flag` | BOOLEAN DEFAULT false | Posible duplicado detectado |
| `file_upload_id` | UUID NULL FK → file_upload | Archivo de origen |
| `movement_status_id` | BIGINT FK → status | Dominio: `movement`. Estados: `active`, `pending_review`, `voided` |
| `deleted_at` | TIMESTAMPTZ NULL | Borrado lógico |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

**Constraints:**
- `amount_in >= 0 AND amount_out >= 0`
- Exactamente uno de los dos > 0 (no ambos)
- `movement_direction = 'in'` → `amount_in > 0 AND amount_out = 0`

**Índices únicos para deduplicación:**
- `(user_id, source_fingerprint)` WHERE `source_fingerprint IS NOT NULL AND deleted_at IS NULL`
- `(user_id, source_type, source_reference)` WHERE `source_reference IS NOT NULL`

---

#### 4.10 `movement_review_queue`

Cola de movimientos pendientes de revisión del usuario (no categorizados, posibles duplicados, etc.).

| Columna | Tipo | Notas |
|---------|------|-------|
| `review_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `movement_id` | UUID FK → financial_movement | |
| `review_reason` | VARCHAR(30) | `uncategorized`, `possible_duplicate`, `instrument_conflict`, `loan_ambiguity`, `ant_expense_check`, `other` |
| `priority_level` | SMALLINT (1–5) DEFAULT 3 | 1 = más urgente |
| `review_status_id` | BIGINT FK → status | Dominio: `review_queue`. Estados: `pending`, `resolved`, `skipped` |
| `resolved_at` | TIMESTAMPTZ NULL | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

---

#### 4.11 `movement_classification_history`

Log de auditoría de cada reclasificación de movimiento. Permite ver quién cambió la categoría y cuándo.

| Columna | Tipo | Notas |
|---------|------|-------|
| `classification_history_id` | UUID PK | |
| `movement_id` | UUID FK → financial_movement | |
| `old_category_id` | UUID NULL FK → category | |
| `new_category_id` | UUID NULL FK → category | |
| `old_leaf_id` | UUID NULL FK → category | |
| `new_leaf_id` | UUID NULL FK → category | |
| `change_reason` | VARCHAR(120) NULL | |
| `changed_by` | UUID NULL FK → app_user | |
| `changed_at` | TIMESTAMPTZ NOT NULL | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

---

## 5. Triggers del módulo

| Trigger | Tabla | Evento |
|---------|-------|--------|
| `trg_financial_institution_updated_at` | `financial_institution` | BEFORE UPDATE |
| `trg_user_financial_instrument_updated_at` | `user_financial_instrument` | BEFORE UPDATE |
| `trg_cashflow_node_updated_at` | `cashflow_node` | BEFORE UPDATE |
| `trg_category_updated_at` | `category` | BEFORE UPDATE |
| `trg_ant_expense_rules_updated_at` | `ant_expense_rules` | BEFORE UPDATE |
| `trg_file_upload_updated_at` | `file_upload` | BEFORE UPDATE |
| `trg_file_upload_status_domain` | `file_upload` | BEFORE INSERT OR UPDATE — valida dominio `file_upload` |
| `trg_import_line_items_updated_at` | `import_line_items` | BEFORE UPDATE |
| `trg_financial_movement_updated_at` | `financial_movement` | BEFORE UPDATE |
| `trg_fin_mov_status_domain` | `financial_movement` | BEFORE INSERT OR UPDATE — valida dominio `movement` |
| `trg_movement_review_queue_updated_at` | `movement_review_queue` | BEFORE UPDATE |
| `trg_review_queue_status_domain` | `movement_review_queue` | BEFORE INSERT OR UPDATE — valida dominio `review_queue` |
| `trg_movement_classification_history_updated_at` | `movement_classification_history` | BEFORE UPDATE |

---

## 6. Relaciones con otros módulos

| Módulo | Relación |
|--------|----------|
| Módulo 1 — Auth | `app_user` como FK base |
| Módulo 3 — Home | `financial_movement` alimenta `user_month_diagnosis_summary` y `user_month_leaks_summary` |
| Módulo 4 — Deudas | `debt_payments.movement_id` → `financial_movement`; `debt.financial_instrument_id` → `user_financial_instrument` |
| Módulo 6 — Presupuesto | `financial_movement` + `category` → cálculo de gasto real vs límite en `budget_plan_item` |
| Módulo 7 — Pagos | `user_payment.movement_id` → `financial_movement` |

---

## 7. Notas de diseño

- **Deduplicación:** `source_fingerprint` es el hash del movimiento tal como viene del banco. El índice único previene dobles importaciones del mismo archivo.
- **Categorías recursivas:** la jerarquía es indefinida en teoría, pero en práctica se limita a 2 niveles (categoría raíz → subcategoría hoja). Solo `is_leaf = true` puede asignarse a movimientos.
- **is_ant_expense:** campo desnormalizado para performance. Se recalcula por el job de ingesta según `ant_expense_rules` del usuario.
- **cashflow_node:** permite análisis de flujo de caja más rico que solo categorías. Por ejemplo, distinguir "transferencia entre cuentas propias" de "pago a proveedor" aunque ambos sean `out`.
