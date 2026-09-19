# M4 — Motor de Deudas (Bola de Nieve)

**Layer:** 11 (Deudas)  
**Estado:** 📋 Referencia — abierto a cambios  
**Docs originales:** `legacy/DB_v2/documentacion/modulo4/`

---

## Propósito
Registra y gestiona deudas del usuario. Genera cronograma de cuotas, registra abonos y simula el payoff proyectando la fecha de liquidación total usando estrategia Bola de Nieve (menor saldo primero) o Avalanche (mayor tasa primero).

---

## Dependencias

```
app_user (M1) ──────────────────────────────► debt
user_financial_profile.estimated_payment_capacity (M2) ─► debt_payoff_simulation
financial_movement (M5) ────────────────────► debt_payments.movement_id
user_financial_instrument (M5) ─────────────► debt.financial_instrument_id

debt ──► debt_schedules (cuotas)
     ──► debt_payments (abonos)
     ──► debt_attachments (documentos)
     ──► debt_payoff_simulation ──► debt_payoff_schedule
```

---

## Tablas

### `debt`
| Columna | Tipo | Notas |
|---------|------|-------|
| `debt_id` | UUID PK | |
| `user_id` | UUID FK | |
| `name` | VARCHAR(200) | "Tarjeta Falabella" |
| `debt_type` | VARCHAR(20) | `consumer`, `mortgage`, `credit_card`, `line`, `other` |
| `current_balance` | NUMERIC(19,4) NOT NULL | Actualizado por abonos |
| `apr_annual` | NUMERIC(7,4) NULL | Tasa anual equivalente |
| `interest_rate_pct` | NUMERIC(10,4) NULL | Tasa mensual pactada |
| `minimum_payment` | NUMERIC(19,4) NULL | Pago mínimo mensual |
| `installments_total` / `remaining` | INT NULL | Cuotas totales y pendientes |
| `due_day` | INT NULL (1–31) | Día de vencimiento mensual |
| `next_due_date` | DATE NULL | Próxima fecha de vencimiento |
| `estimated_payoff_date` | DATE NULL | **Calculado** por backend |
| `released_cashflow_amount` | NUMERIC(19,4) NULL | Liquidez liberada al cerrar |
| `snowball_priority` | INT NULL | Posición en Bola de Nieve (1 = mayor prioridad) |
| `debt_status_id` | BIGINT FK → status | Dominio: `debt`. `active`, `paused`, `settled`, `written_off` |
| `deleted_at` | TIMESTAMPTZ NULL | Soft delete |

**Índice:** `(user_id, debt_status_id)` WHERE `deleted_at IS NULL`

### `debt_schedules`
Cuotas proyectadas de la deuda.

| Columna | Notas |
|---------|-------|
| `debt_id` FK | |
| `installment_number` INT | Número de cuota |
| `due_date` DATE | |
| `principal_amount` NUMERIC(19,4) | Capital de la cuota |
| `interest_amount` NUMERIC(19,4) | Interés de la cuota |
| `total_amount` NUMERIC(19,4) | Total a pagar |
| `status` VARCHAR(15) | `pending`, `paid`, `overdue` |

### `debt_payments`
Abonos registrados por el usuario.

| Columna | Notas |
|---------|-------|
| `debt_id` FK, `user_id` FK | |
| `movement_id` UUID NULL FK → financial_movement | Movimiento que evidencia el pago |
| `amount` NUMERIC(19,4) | |
| `payment_date` DATE | |
| `type` VARCHAR(20) | `minimum`, `extra`, `full_payment` |

### `debt_payoff_simulation`
Simulación del plan completo de liquidación.

| Columna | Notas |
|---------|-------|
| `user_id` FK | |
| `strategy` VARCHAR(15) | `snowball`, `avalanche` |
| `extra_monthly_payment` NUMERIC(19,4) | Del `estimated_payment_capacity` de M2 |
| `total_interest_saved` NUMERIC(19,4) | Interés ahorrado vs mínimos |
| `payoff_date` DATE | Fecha estimada de deuda 0 |
| `created_at` TIMESTAMPTZ | |

### `debt_payoff_schedule`
Plan detallado por deuda dentro de la simulación.

| Columna | Notas |
|---------|-------|
| `simulation_id` FK | |
| `debt_id` FK | |
| `payoff_month` DATE | Mes estimado de liquidación de esta deuda |
| `total_paid` / `interest_paid` NUMERIC(19,4) | |
| `order_in_plan` INT | Posición en la secuencia snowball/avalanche |

---

## Relaciones salientes
- `debt_payments.movement_id` → M5 (evidencia el pago con un movimiento real)
- Read model `user_month_debt_priority_summary` (M3) consume este módulo
