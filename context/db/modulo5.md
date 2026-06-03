# M5 — Cashflow (Catálogos, Ingesta y Movimientos)

**Layers:** 7 (Catálogos Financieros) · 8 (Pipeline de Ingesta) · 9 (Movimientos)  
**Estado:** 📋 Referencia — abierto a cambios  
**Docs originales:** `legacy/DB_v2/documentacion/modulo5/`

---

## Propósito
El **núcleo transaccional** de Walvy. Sin datos de este módulo los read models del Home no tienen nada que mostrar.
- **Layer 7:** catálogos de instituciones, instrumentos del usuario y árbol de categorías
- **Layer 8:** pipeline de importación de cartolas bancarias (PDF/CSV)
- **Layer 9:** movimientos financieros — fuente de verdad de ingresos y gastos

---

## Dependencias

```
financial_institution ──► user_financial_instrument
category (árbol recursivo) ──► ant_expense_rules
cashflow_node ──────────────────────────────────────────────────────────────────┐
                                                                                ▼
file_upload ──► import_line_items ──► movement_classification_suggestions ──► financial_movement
                                                                                │
                                            ┌───────────────────────────────────┤
                                            ▼                                   ▼
                                  movement_review_queue      movement_classification_history
```

---

## Layer 7 — Catálogos Financieros

### `financial_institution`
| Columna | Notas |
|---------|-------|
| `financial_institution_id` UUID PK | |
| `name` VARCHAR(200) | "Banco Santander Chile" |
| `country_id` FK | |
| `institution_type` VARCHAR(20) | `bank`, `wallet`, `retail`, `broker`, `cooperative`, `other` |
| `has_api` BOOLEAN | Si tiene integración API. `api_base_url` obligatorio si true |

### `user_financial_instrument`
Cuentas y tarjetas del usuario.

| Columna | Notas |
|---------|-------|
| `financial_instrument_id` UUID PK | |
| `user_id` FK | |
| `institution_id` FK NULL | |
| `instrument_type` VARCHAR(20) | `checking`, `savings`, `credit_card`, `wallet`, `cash`, `other` |
| `alias` VARCHAR(100) NULL | "Cuenta BCI", "Tarjeta Visa" |
| `currency_id` FK | |
| `is_active` BOOLEAN | |

### `category`
Árbol recursivo de categorías (sistema + custom por usuario).

| Columna | Notas |
|---------|-------|
| `category_id` UUID PK | |
| `parent_id` UUID NULL FK → category | NULL = raíz |
| `owner_user_id` UUID NULL FK → app_user | NULL = categoría del sistema |
| `name` VARCHAR(100) | |
| `type` VARCHAR(10) | `income`, `expense`, `transfer` |
| `is_system` BOOLEAN | Categorías del sistema no editables |
| `is_leaf` BOOLEAN | Solo hojas asignables a movimientos |
| `icon` / `color` TEXT NULL | |

### `cashflow_node`
Nodo semántico origen/destino de un movimiento (más granular que categoría).

### `ant_expense_rules`
Reglas para detectar "gastos hormiga" — pequeños gastos frecuentes que se acumulan.

---

## Layer 8 — Pipeline de Ingesta

### `file_upload`
| Columna | Notas |
|---------|-------|
| `file_upload_id` UUID PK | |
| `user_id` FK | |
| `institution_id` FK NULL | |
| `file_type` VARCHAR(10) | `pdf`, `csv`, `xls` |
| `status` VARCHAR(20) | `pending`, `processing`, `completed`, `failed` |
| `total_rows` / `processed_rows` / `failed_rows` INT | |
| `storage_path` TEXT | Ruta en storage (S3/local) |

### `import_line_items`
Líneas extraídas del archivo antes de convertirse en movimientos.

| Columna | Notas |
|---------|-------|
| `file_upload_id` FK | |
| `raw_text` TEXT | Texto original de la línea |
| `parsed_date` DATE NULL | |
| `parsed_amount` NUMERIC(19,4) NULL | |
| `parsed_description` TEXT NULL | |
| `classification_status` VARCHAR(20) | `unclassified`, `auto_classified`, `user_confirmed`, `rejected` |
| `movement_id` UUID NULL FK → financial_movement | Null hasta confirmar |

### `movement_classification_suggestions`
Sugerencias de categoría generadas por el algoritmo antes de que el usuario confirme.

---

## Layer 9 — Movimientos

### `financial_movement` ← **Tabla central**
| Columna | Tipo | Notas |
|---------|------|-------|
| `movement_id` | UUID PK | |
| `user_id` | UUID FK | |
| `instrument_id` | UUID NULL FK → user_financial_instrument | |
| `category_id` | UUID FK → category | Solo hojas (`is_leaf = true`) |
| `cashflow_node_id` | UUID NULL FK → cashflow_node | |
| `amount` | NUMERIC(19,4) NOT NULL > 0 | Siempre positivo |
| `type` | VARCHAR(10) | `income`, `expense`, `transfer` |
| `description` | TEXT NULL | |
| `movement_date` | DATE NOT NULL | |
| `source` | VARCHAR(10) | `manual`, `import`, `api` |
| `source_fingerprint` | TEXT UNIQUE NULL | Hash para deduplicación de importaciones |
| `movement_status_id` | BIGINT FK → status | Dominio: `movement` |
| `deleted_at` | TIMESTAMPTZ NULL | Soft delete |

### `movement_review_queue`
Movimientos importados que requieren revisión manual del usuario.

### `movement_classification_history`
Auditoría de cada reclasificación: quién cambió la categoría, de qué a qué.

---

## Relaciones salientes
- `financial_movement` → M3 read models, M4 (evidencia de abonos), M6 presupuesto, M7 pagos
- `user_financial_instrument` → M4 deudas, M7 pagos
