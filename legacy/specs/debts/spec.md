# Spec: Motor de Deudas

> **Módulo:** `debts`
> **Estado:** Solo entidades TypeORM — sin módulo ni controller
> **Diferenciador clave de Walvy:** Motor snowball/avalanche
> **Última revisión:** 2026-05-14

---

## 1. Propósito

El módulo de deudas permite a los usuarios registrar sus deudas (créditos de consumo, tarjetas, préstamos hipotecarios, deudas informales) y simular estrategias de pago para salir de ellas en el menor tiempo posible o pagando el menor interés.

**Para el PM:** Los usuarios agregan sus deudas con monto, tasa de interés y cuota mínima. Walvy puede simular dos estrategias: Bola de Nieve (pagar primero la deuda más pequeña para ganar momentum psicológico) y Avalancha (pagar primero la deuda con mayor interés para ahorrar más dinero a largo plazo). Esta funcionalidad es un diferenciador clave de Walvy en el mercado chileno de finanzas personales.

**Para el desarrollador:** El módulo tiene un motor de simulación que proyecta mes a mes cuánto se pagará a cada deuda con el dinero extra disponible. Las entidades ya existen en TypeORM. Se necesita implementar el módulo, controller, service y el algoritmo de simulación.

---

## 2. Entidades en base de datos

### Debt

Representa una deuda del usuario.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador |
| `userId` | UUID | Dueño de la deuda |
| `creditorName` | String | Nombre del acreedor (ej: "Banco Santander", "ABCDIN") |
| `description` | String | Descripción libre (opcional) |
| `currentBalance` | Decimal | Saldo pendiente actual en CLP |
| `interestRate` | Decimal | Tasa de interés anual (ej: 24.5 = 24.5%) |
| `minimumPayment` | Decimal | Cuota mínima mensual en CLP |
| `payoffStrategy` | Enum | `snowball` o `avalanche` (preferencia del usuario) |
| `active` | Boolean | Si la deuda está activa (false = pagada) |
| `deletedAt` | Timestamp | Soft delete |

### DebtSchedule

Cuotas programadas de una deuda (plan de pagos).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador |
| `debtId` | UUID | Deuda asociada |
| `dueDate` | Date | Fecha de vencimiento de la cuota |
| `amount` | Decimal | Monto de la cuota |
| `paid` | Boolean | Si fue pagada |
| `paidAt` | Timestamp | Cuándo fue pagada |

### DebtPayment

Pagos realizados a deudas.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador |
| `debtId` | UUID | Deuda asociada |
| `amount` | Decimal | Monto pagado |
| `paymentDate` | Date | Fecha del pago |
| `fundingSourceId` | UUID | Desde qué cuenta se pagó |
| `notes` | String | Notas del pago (opcional) |

### DebtAttachment

Documentos adjuntos a una deuda (contrato, cartola).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador |
| `debtId` | UUID | Deuda asociada |
| `fileUrl` | String | URL del documento |
| `filename` | String | Nombre del archivo |
| `uploadedAt` | Timestamp | Fecha de subida |

### DebtSnowballPlan

Resultado de una simulación de payoff.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador |
| `userId` | UUID | Usuario de la simulación |
| `strategy` | Enum | `snowball` o `avalanche` |
| `monthlyExtraPayment` | Decimal | Dinero extra disponible por mes |
| `totalMonths` | Integer | Meses totales para pagar todas las deudas |
| `totalInterestPaid` | Decimal | Total de intereses pagados |
| `projectionData` | JSON | Proyección mes a mes (array) |
| `createdAt` | Timestamp | Cuándo se generó la simulación |

---

## 3. Endpoints a implementar

> Estos endpoints **no están implementados**. El módulo aún no existe en el backend.

### CRUD de deudas

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/debts` | JWT | Lista deudas activas del usuario |
| GET | `/debts/:id` | JWT | Detalle de una deuda |
| POST | `/debts` | JWT | Registra una nueva deuda |
| PATCH | `/debts/:id` | JWT | Actualiza una deuda |
| DELETE | `/debts/:id` | JWT | Soft delete de deuda |
| PATCH | `/debts/:id/mark-paid` | JWT | Marca la deuda como pagada |

### Pagos

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/debts/:id/payments` | JWT | Historial de pagos de una deuda |
| POST | `/debts/:id/payments` | JWT | Registra un pago realizado |

### Simulación

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/debts/simulate` | JWT | Genera proyección de payoff |
| GET | `/debts/payoff-plan` | JWT | Obtiene la última simulación guardada |

---

## 4. Contratos de simulación

### POST /debts/simulate — Request

```json
{
  "strategy": "snowball | avalanche",
  "monthlyExtraPayment": "number (dinero extra disponible por mes en CLP, requerido)",
  "saveResult": "boolean (guardar la proyección, opcional)"
}
```

### POST /debts/simulate — Response

```json
{
  "strategy": "snowball",
  "totalMonths": 18,
  "totalInterestPaid": 450000,
  "debtFreeDate": "2027-11-01",
  "monthlyExtraPayment": 100000,
  "projection": [
    {
      "month": 1,
      "date": "2026-06-01",
      "payments": [
        {
          "debtId": "uuid",
          "creditorName": "Banco Santander",
          "paymentAmount": 85000,
          "remainingBalance": 415000,
          "isMinimumOnly": false
        }
      ],
      "totalPaid": 285000,
      "totalRemainingDebt": 1215000
    }
  ]
}
```

---

## 5. Algoritmos de payoff

### Estrategia Snowball (Bola de Nieve)

**Principio:** Pagar primero la deuda con el saldo más pequeño (independiente de la tasa de interés).

**Algoritmo mes a mes:**
1. A cada deuda, asignar su `minimumPayment`
2. El dinero extra (`monthlyExtraPayment`) va enteramente a la deuda con el saldo más bajo
3. Cuando una deuda se paga completamente, su `minimumPayment` se libera y se suma al extra para la siguiente
4. Repetir hasta que todas las deudas lleguen a saldo 0

**Ventaja:** Mayor motivación psicológica (elimina deudas más rápido).
**Desventaja:** Se paga más interés total a largo plazo.

---

### Estrategia Avalanche

**Principio:** Pagar primero la deuda con la tasa de interés más alta.

**Algoritmo mes a mes:**
1. A cada deuda, asignar su `minimumPayment`
2. El dinero extra va enteramente a la deuda con la tasa de interés más alta
3. Cuando una deuda se paga, su mínimo se libera y se suma al extra para la siguiente
4. Repetir hasta que todas las deudas lleguen a saldo 0

**Ventaja:** Se paga el menor total de intereses.
**Desventaja:** Puede tardar más en ver resultados (si las deudas de mayor interés tienen saldo alto).

---

## 6. Reglas de negocio

- Un usuario puede tener múltiples deudas activas simultáneamente
- La simulación usa el `currentBalance` actual de cada deuda al momento de generarse
- `minimumPayment` debe ser mayor que 0; si es 0, el algoritmo lo trata como deuda sin cuota mínima
- Los pagos realizados (`DebtPayment`) actualizan el `currentBalance` de la deuda
- Soft delete en deudas: `deletedAt` se marca, el registro no se elimina físicamente
- Una deuda marcada como pagada (`active = false`) no aparece en el listado principal ni en las simulaciones

---

## 7. Relación con cashflow

Los pagos de deudas usan `fundingSourceId` de cashflow. Al registrar un pago de deuda, opcionalmente se puede crear automáticamente una transacción de tipo `expense` en cashflow en la categoría "Pago de deuda" para mantener coherencia en el dashboard financiero.

Esta integración es opcional para MVP y puede implementarse en una iteración posterior.
