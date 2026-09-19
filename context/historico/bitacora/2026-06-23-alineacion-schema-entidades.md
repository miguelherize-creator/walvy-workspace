# Opción A — Entidades = fuente de verdad: investigación de divergencias

**Fecha:** 2026-06-23
**Decisión tomada:** las entidades TypeORM mandan. `DB/schema.sql`, los docs de `DB/` y `docs/api/` deben alinearse a ellas.

## Hallazgo central

`DB/schema.sql` **no es el esquema que corre el backend**. Es un modelo distinto (el diseño "v4 / enterprise" de Kabeli). El backend, con `DB_SYNC=true`, crea sus tablas **desde las entidades**, que implementan un **subconjunto renombrado** de ese modelo.

| | Tablas |
|---|--------|
| Entidades TypeORM (lo que corre) | **52** |
| `DB/schema.sql` (el doc) | **74** |
| Coinciden por nombre exacto | ~42 |

## Las 3 categorías de divergencia

### 1. Tablas renombradas (mismo concepto, distinto nombre)
Convención: **entidades en plural / simple**, **schema en singular / enterprise**. (Mapeos a verificar, pero el patrón es claro.)

| Entidad (corre) | schema.sql (doc) |
|-----------------|------------------|
| `transactions` | `financial_movement` ✅ confirmado |
| `subscriptions` | `subscription` |
| `payment_orders` | `payment_order` |
| `subscription_plans` | `plan` (+ `plan_price`) |
| `funding_sources` | `payment_method` / `user_financial_instrument` |
| `budget_periods` / `budget_lines` | `budget_plan` / `budget_plan_item` |
| `debts` / `debt_schedules` / `debt_snowball_plan` | `debt` / `debt_payoff_schedule` / `debt_payoff_simulation` |
| `movement_classification_suggestions` | `movement_classification_history` / `movement_review_queue` |

### 2. Solo en el schema (modelo enterprise NO implementado en código)
~18 tablas que el backend no modela. Probablemente roadmap futuro (capacidad de BD ≠ feature MVP), no se borran a la ligera:
`company`, `company_benefit_contract`, `company_eligible_employee`, `benefit_invitation`, `financial_institution`, `country_currency`, `permission`, `role_permission`, `cashflow_node`, `file_upload`, `message_event`, `message_rule`, `user_message_interaction`, `user_month_*_summary` (4), `user_payment`.

### 3. Divergencias de columnas (en tablas que sí coinciden)
- PKs de catálogo: entidad **camelCase** (`statusId`, `roleId`, `documentTypeId`) vs schema **snake** (`status_id`). (Ya documentado en `docs/sql/catalog.md`.)
- Falta auditar columna-por-columna en las tablas coincidentes.

## Qué implica "alinear a entidades" (Opción A)

La divergencia es **estructural y profunda** (74 vs 52, nombres distintos, modelo distinto). Editar `schema.sql` a mano para que calce es impráctico y propenso a error. El camino correcto:

1. **Regenerar `schema.sql` DESDE las entidades.** La forma fiable: `pg_dump` de la DB local (que ya está sincronizada desde entidades con `DB_SYNC=true`), o `typeorm schema:log`. Eso produce un `schema.sql` que **calza exacto** con lo que el backend crea. → Se convierte en el nuevo schema.sql autoritativo.
   - ⚠️ Implica que `schema.sql` se vuelve **más chico** (solo lo implementado) y **pierde** las tablas enterprise + los `COMMENT ON` curados.

2. **Separar el modelo enterprise.** Las ~18 tablas no implementadas + `DB/modulo1`, `DB/modulo2` (dbml + docs) + `DB/README.md` (432 l) describen el diseño v4/Kabeli. Hay que **reetiquetarlos como "diseño objetivo / visión", NO "esquema actual"**, o moverlos, para que nadie los confunda con lo que corre.

3. **`docs/api/`** — bajo impacto. No hay docs de cashflow/categorías (los cambios de contrato que hicimos no tienen doc). Solo verificar `subscriptions.md`.

## Decisiones pendientes (para ti / Kabeli)

1. ¿Regeneramos `schema.sql` por `pg_dump` de la DB sincronizada? (requiere correr el dump contra tu DB local).
2. Las tablas enterprise (`company`, `benefit`, `permission`, summaries): ¿son roadmap futuro (se conservan como diseño) o abandonadas (se descartan)?
3. ¿`DB/modulo1`/`modulo2` se reetiquetan como "diseño v4 (no implementado)" o se archivan en workspace?

## Nota de fondo
El naming entidad↔schema (plural vs singular, `transactions` vs `financial_movement`) sugiere que el backend **evolucionó por su cuenta** y se separó del modelo que Kabeli documentó. Alinear "hacia las entidades" oficializa esa evolución. Conviene confirmarlo con Kabeli antes de descartar su modelo, porque `migration.sql`/`comments.sql` del workspace apuntan a un handoff con ellos.
