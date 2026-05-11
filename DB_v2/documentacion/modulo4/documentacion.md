# Módulo 4 — Motor de Deudas (Bola de Nieve)

**Layer cubierto:** 11 (Deudas)  
**Corresponde a:** CSV Módulo 4 — Gestión de Deudas  
**Estado MVP:** ✅ Incluido

---

## 1. Propósito del módulo

El Módulo 4 implementa el **motor de deudas** de Walvy, basado en la estrategia Bola de Nieve. Permite al usuario registrar y gestionar sus deudas, visualizar un cronograma de cuotas, registrar abonos y ejecutar simulaciones de payoff proyectando la fecha de liquidación total.

Las tablas de este módulo son de **escritura activa** — el usuario crea y actualiza deudas directamente. Los read models de prioridad (`user_month_debt_priority_summary`) se calculan en Módulo 3.

---

## 2. Diagrama de dependencias

```
app_user (M1) ──────────────────────────────► debt
                                               │
                              ┌────────────────┼────────────────────┐
                              ▼                ▼                    ▼
                       debt_schedules   debt_payments       debt_attachments
                         (cuotas)        (abonos)           (documentos)
                                                                    
debt + app_user ──────────────────────► debt_payoff_simulation
                                                │
                                                ▼
                                       debt_payoff_schedule
                                         (plan por deuda)

financial_movement (M5) ───────────────► debt_payments.movement_id
user_financial_instrument (M5) ────────► debt.financial_instrument_id
```

---

## 3. Diagrama ERD

Ver archivo: [`modulo4.dbml`](./modulo4.dbml)

---

## 4. Tablas del módulo

### 4.1 `debt`

Deuda principal del usuario. Soporta todos los tipos de crédito chilenos: consumo, hipotecario, tarjeta, línea de crédito.

| Columna | Tipo | Notas |
|---------|------|-------|
| `debt_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `name` | VARCHAR(200) NOT NULL | Nombre de la deuda. Ej: "Tarjeta Falabella" |
| `creditor_label` | TEXT NULL | Nombre del acreedor si no es institución formalizada |
| `debt_type` | VARCHAR(20) | `consumer`, `mortgage`, `credit_card`, `line`, `other` |
| `debt_source_type` | VARCHAR(20) NULL | `bank`, `retail`, `person`, `other` |
| `principal_initial` | NUMERIC(19,4) NULL | Capital inicial (puede ser NULL si solo se sabe el saldo) |
| `current_balance` | NUMERIC(19,4) NOT NULL | Saldo actual. Actualizado por abonos o manualmente |
| `currency_id` | BIGINT FK → currency | |
| `apr_annual` | NUMERIC(7,4) NULL | Tasa anual equivalente |
| `interest_rate_pct` | NUMERIC(10,4) NULL | Tasa de interés mensual o pactada |
| `minimum_payment` | NUMERIC(19,4) NULL | Pago mínimo mensual |
| `installments_total` | INT NULL | Total de cuotas |
| `installments_remaining` | INT NULL | Cuotas pendientes |
| `due_day` | INT NULL (1–31) | Día del mes de vencimiento |
| `next_due_date` | DATE NULL | Próxima fecha de vencimiento |
| `estimated_payoff_date` | DATE NULL | Estimación de liquidación (calculada) |
| `released_cashflow_amount` | NUMERIC(19,4) NULL | Liquidez mensual liberada al cerrar esta deuda |
| `financial_instrument_id` | UUID NULL FK → user_financial_instrument | Instrumento asociado (tarjeta, cuenta) |
| `snowball_priority` | INT NULL | Posición en el orden Bola de Nieve. 1 = mayor prioridad |
| `debt_status_id` | BIGINT FK → status | Dominio: `debt`. Estados: `active`, `paused`, `settled`, `written_off` |
| `metadata` | JSONB DEFAULT '{}' | Datos adicionales no estructurados |
| `deleted_at` | TIMESTAMPTZ NULL | Borrado lógico |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

**Índices:**
- `(user_id, debt_status_id)` WHERE deleted_at IS NULL
- `(user_id, snowball_priority ASC)` WHERE deleted_at IS NULL

---

### 4.2 `debt_schedules`

Cronograma de cuotas planificado para una deuda. Append-only — se crea al registrar la deuda y no se modifica.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `debt_id` | UUID FK → debt | |
| `installment_no` | INT NOT NULL | Número de cuota (1, 2, 3...) |
| `due_date` | DATE NOT NULL | Fecha de vencimiento de la cuota |
| `planned_principal` | NUMERIC(19,4) NULL | Capital planificado para esta cuota |
| `planned_interest` | NUMERIC(19,4) NULL | Interés planificado para esta cuota |
| `created_at` | TIMESTAMPTZ | |

**Índice:** `(debt_id)`

---

### 4.3 `debt_payments`

Log **inmutable** de abonos realizados a una deuda. Una fila por abono, nunca se modifica ni elimina.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `debt_id` | UUID FK → debt | |
| `paid_at` | TIMESTAMPTZ NOT NULL | Fecha/hora del abono |
| `amount` | NUMERIC(19,4) NOT NULL | Monto abonado (> 0) |
| `movement_id` | UUID NULL FK → financial_movement | Movimiento financiero asociado (si se importó) |
| `notes` | TEXT NULL | Notas del usuario |
| `created_at` | TIMESTAMPTZ | |

**Índice:** `(debt_id, paid_at DESC)`

---

### 4.4 `debt_attachments`

Archivos adjuntos a una deuda: cartolas, estados de cuenta, documentos de crédito.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `debt_id` | UUID NULL FK → debt | NULL si el archivo aún no está vinculado |
| `storage_key` | TEXT NOT NULL | Ruta en S3/storage |
| `mime_type` | TEXT NULL | Tipo MIME del archivo |
| `original_filename` | TEXT NULL | Nombre original del archivo subido |
| `uploaded_at` | TIMESTAMPTZ NOT NULL | |
| `parsed_summary` | JSONB NULL | Resultado del OCR/parsing. Ej: `{"balance": 450000, "institution": "BCI"}` |

**Índice:** `(debt_id)`

---

### 4.5 `debt_payoff_simulation`

Configuración de una simulación de payoff. El usuario puede tener varias simulaciones (`draft`, `active`, `archived`).

| Columna | Tipo | Notas |
|---------|------|-------|
| `simulation_id` | UUID PK | |
| `user_id` | UUID FK → app_user | |
| `start_date` | DATE NOT NULL | Fecha de inicio de la simulación |
| `extra_monthly_payment` | NUMERIC(19,4) DEFAULT 0 | Abono extra mensual disponible |
| `initial_lump_sum` | NUMERIC(19,4) DEFAULT 0 | Pago único inicial |
| `simulation_status` | VARCHAR(20) | `draft` · `active` · `archived` |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

**Índice:** `(user_id, created_at DESC)`

---

### 4.6 `debt_payoff_schedule`

Plan de liquidación por deuda dentro de una simulación. Una fila por deuda en la simulación. Constrain UNIQUE `(simulation_id, debt_id)`.

| Columna | Tipo | Notas |
|---------|------|-------|
| `schedule_id` | UUID PK | |
| `simulation_id` | UUID FK → debt_payoff_simulation | |
| `debt_id` | UUID FK → debt | |
| `sequence_order` | INT NOT NULL (> 0) | Orden en que se liquida la deuda en el plan |
| `estimated_months_to_close` | INT NOT NULL | Meses estimados para liquidar |
| `estimated_close_date` | DATE NULL | Fecha estimada de cierre |
| `released_cashflow_after_close` | NUMERIC(19,4) DEFAULT 0 | Liquidez mensual disponible tras cerrar esta deuda |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

---

## 5. Triggers del módulo

| Trigger | Tabla | Evento |
|---------|-------|--------|
| `trg_debt_updated_at` | `debt` | BEFORE UPDATE |
| `trg_debt_status_domain` | `debt` | BEFORE INSERT OR UPDATE — valida dominio `debt` |
| `trg_debt_payoff_simulation_updated_at` | `debt_payoff_simulation` | BEFORE UPDATE |
| `trg_debt_payoff_schedule_updated_at` | `debt_payoff_schedule` | BEFORE UPDATE |

---

## 6. Relaciones con otros módulos

| Módulo | Relación |
|--------|----------|
| Módulo 1 — Auth | `app_user` como FK base |
| Módulo 3 — Home | `debt` alimenta `user_month_debt_priority_summary` (read model) |
| Módulo 5 — Movimientos | `debt_payments.movement_id` → `financial_movement`; `debt.financial_instrument_id` → `user_financial_instrument` |
| Módulo 7 — Pagos | `user_payment.debt_id` → `debt` (pagos vinculados a deuda) |

---

## 7. Notas de diseño

- **`debt_payments` es inmutable:** nunca se modifica ni elimina. Es el log de auditoría de abonos.
- **`current_balance` en `debt`:** se actualiza cada vez que se registra un abono vía `debt_payments`. El balance no se recalcula desde los abonos en cada request — el trigger o el job mantiene el cache.
- **`deleted_at` en `debt`:** borrado lógico. Las deudas borradas no se muestran al usuario, pero sus `debt_payments` se conservan para auditoría.
- **Múltiples simulaciones:** el usuario puede tener varias simulaciones (`draft`/`archived`), pero solo una `active`. La simulación activa es la que alimenta los read models del home.
