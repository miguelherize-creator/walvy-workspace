# Matriz de estado por módulo — estructura en BD vs integración en backend

**Fecha:** 2026-08-10
**Para:** punto 6 de la revisión de Jeannine
**Medido sobre:** `main` con #66, #67 y #68 mergeados, más #69 en revisión
**Esquema:** 87 tablas construidas por 14 migraciones

Una tabla creada en la base no equivale a un módulo integrado. Hay **cuatro
estados distintos**, no dos:

| Estado | Qué significa |
|---|---|
| **Activo** | Módulo Nest registrado en `app.module`, endpoints sirviendo |
| **Desacoplado en el #68** | El módulo existe y estaba registrado; se quitó para reducir la superficie a Módulo 1. Vuelve en su iteración |
| **Solo entidades** | Hay entidades mapeadas y TypeORM las conoce, pero **no existe archivo `.module.ts`**: nunca hubo controlador ni servicio |
| **Solo tablas** | La tabla existe en el baseline y no tiene entidad |

---

## Módulos activos

| Módulo | Tablas en baseline | Entidades alineadas | Estado | Pendiente |
|---|---|---|---|---|
| `catalog` | 8 | 8 de 8 | Activo | — |
| `auth` | 5 | 5 de 5 | Activo | — |
| `imports` | 4 | 4 de 4 | Activo | — |
| `profile` | 2 | 2 de 2 | Activo | — |
| `notifications` | 2 | 2 de 2 | Activo | Falta declarar `notification_queue.user_payment_id` |
| `users` | 1 | 1 de 1 | Activo | — |

Estos seis cubren los 35 endpoints de Módulo 1. **Alineación verificada en las
dos direcciones**: ninguna entidad declara una columna que la tabla no tenga, y
ninguna tabla tiene una columna que la entidad no declare.

---

## Desacoplados en el #68 — vuelven en su iteración

| Módulo | Tablas en baseline | Entidades alineadas | Estado | Pendiente |
|---|---|---|---|---|
| `cashflow` | 10 | 3 de 10 | Desacoplado | 7 tablas sin entidad; `Transaction` y `FundingSource` apuntan a tablas inexistentes |
| `debts` | 10 | 3 de 10 | Desacoplado | 7 sin entidad; `Debt` y `DebtSnowballPlan` huérfanas |
| `subscriptions` | 6 | 0 de 6 | Desacoplado | 6 sin entidad; sus 3 entidades son huérfanas |

Se quitaron de `app.module` en el #68 para que el backend arrancara sin
entidades desalineadas. La decisión de producto asociada, ya tomada: **las
cuentas nacen sin orígenes de fondo**.

Caso a tener presente al reconectar `cashflow`: el #69 creó `FinancialMovement`
sobre `financial_movement`. El controlador de transacciones debe apuntar a esa
entidad; la vieja `Transaction` coincide solo en 44% de sus columnas con esa
tabla y no debe reconectarse.

---

## Solo entidades, sin módulo Nest

Estas carpetas tienen `entities/` pero **no tienen `.module.ts`**. Sus entidades
están registradas y mapean bien contra el esquema, pero no hay controlador ni
servicio: no son módulos desacoplados, nunca se integraron.

| Carpeta | Tablas en baseline | Entidades alineadas | Pendiente |
|---|---|---|---|
| `ai` | 5 | 5 de 5 | Integración completa |
| `gamification` | 4 | 4 de 4 | Integración completa |
| `admin` | 3 | 3 de 3 | `AdminUser` y `AdminAuditLog` huérfanas; falta declarar `app_config.value_type` y `audit_log.before_data/after_data` |
| `health` | 2 | 2 de 2 | Integración completa |
| `payments` | 2 | 2 de 2 | Integración completa |
| `budget` | 4 | 0 de 4 | `BudgetLine` y `BudgetPeriod` huérfanas; 4 tablas sin entidad |

---

## Solo tablas, sin dueño asignado

Tablas del baseline que no pertenecen a ninguna carpeta de módulo existente:

| Bloque | Tablas |
|---|---|
| Reglas y catálogo transversal | `financial_rule`, `functional_tag`, `functional_tag_assignment`, `country_currency` |
| Autorización | `permission`, `role_permission` |
| Read-models mensuales | `user_month_diagnosis_summary`, `user_month_debt_priority_summary`, `user_month_leaks_summary`, `user_upcoming_payments_summary` |
| Mensajería | `message_event`, `message_rule`, `user_message_interaction` |
| B2B y beneficios | `company`, `company_benefit_contract`, `company_eligible_employee`, `benefit_invitation` |
| Transversal | `intermodule_derivation`, `recommendation_evidence` |

---

## Resumen numérico

| | |
|---|---|
| Tablas en el baseline | 87 |
| Tablas con entidad | 44 |
| Tablas sin entidad | 43 |
| Entidades que apuntan a tablas inexistentes | 11 |
| Entidades que declaran columnas inexistentes | **0** |
| Columnas de tabla sin declarar en su entidad | 7, en 6 entidades |
| Módulos con endpoints sirviendo | 6 |

**Consecuencia operativa:** no correr `migration:generate` hasta cerrar las 43
tablas sin entidad y las 11 huérfanas. Hoy propondría borrar las 43 tablas y las
7 columnas, y recrear tablas que ya existen.
