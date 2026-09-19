# Plan: adopción del modelo de datos de Jeaninne (v4 + incrementales)

Fecha: 2026-08-02
Rama base: `feature/db-schema-regen-migrations`
Fuentes: `workspace/utils/sql/{schema.sql,migration.sql,comments.sql,seeds.sql}`

## Decisiones tomadas

| Decisión | Valor |
|---|---|
| Alcance | **Adopción total**, incluidos renombres de tabla y PK |
| Orden de ejecución | **M5 primero** (presupuesto y movimientos) |
| `admin_users` / `admin_audit_log` | **Posponer** — falta modelar `permission` / `role_permission` |

## El número objetivo no es 71

| | Tablas |
|---|---|
| `schema.sql` de Jeaninne | 71 |
| `migration.sql` agrega | +14 |
| Ella pide eliminar | −2 (`admin_users`, `admin_audit_log`) |
| **Objetivo real** | **~83** |
| Cubierto hoy: 39 por nombre + 9 por renombre + 5 nuevas ya hechas | **53** |
| **Brecha** | **~30 tablas** |

Además el backend tiene **5 tablas que su modelo no contempla** y hay que defender o mapear
en la sesión: `bills_payable`, `funding_sources`, `financial_health_snapshots`,
`recommendation_events`, `statement_imports` (+ `import_line_items`).

---

## Principio rector: renombrar la columna, no la propiedad

El riesgo real de la adopción total no son los nombres de tabla — el nombre vive solo en
`@Entity('...')`, 1–2 archivos por tabla. El riesgo es renombrar la PK `id` → `<entidad>_id`,
porque los servicios devuelven entities directas (no hay response DTOs) y esa propiedad
viaja al contrato consumido por front-walvy y Kread.

Se resuelve renombrando **solo la columna de base de datos** y dejando la propiedad TS intacta:

```ts
// antes
@PrimaryGeneratedColumn('uuid')
id!: string;

// después — columna debt_id en DB, propiedad `id` en la API
@PrimaryGeneratedColumn('uuid', { name: 'debt_id' })
id!: string;
```

Es el patrón que `Category` ya usa (`@PrimaryGeneratedColumn('uuid', { name: 'category_id' })`).
Con esto la adopción total pasa de riesgo alto a riesgo bajo: **cero cambios en front-walvy y
Kread**, y el modelo físico queda 1:1 con el de Jeaninne.

---

## Fase 0 — Cierre de lo pendiente y preparación

Lo que hay en staged (`uq_app_user_document` + reformateo Prettier) es **ortogonal** a este
plan: no aparece en ninguno de los tres archivos de Jeaninne y no la contradice. Se commitea
aparte antes de empezar.

- [ ] Commitear `uq_app_user_document` (entity, migración, `document.utils.ts`, `users.service.ts`, `schema.sql`).
- [ ] **`UniqueUserDocument` falla hoy contra la base de desarrollo**: hay 29 cuentas activas
      con el documento `12345678-5` (país 1, tipo 1). Es data de prueba, pero el índice no se
      puede crear hasta resolverla. Verificar lo mismo en staging y producción antes de
      desplegar (la query está en el header de la migración).
- [ ] Producir el **mapa de equivalencias tabla↔tabla y campo↔campo** — es el entregable que
      desbloquea la sesión que Jeaninne pidió.
- [ ] Confirmar con ella el criterio de PK: columna `<entidad>_id` en DB, `id` en la API.

## Fase 1 — Convenciones (la base de todo lo demás)

Sin esta fase, cada tabla nueva de las fases siguientes nace con la convención equivocada.

**Corrección al plan original: "renombre" describe mal 4 de los 9 pares.** Comparando columna
a columna contra su modelo, solo `debts`→`debt` y `payment_orders`→`payment_order` son
renombres. El resto cambia de forma:

| Par | Columnas en común |
|---|---|
| `debts` → `debt` | 48/56 |
| `payment_orders` → `payment_order` | 10/14 |
| `debt_snowball_plan` → `debt_payoff_simulation` | 12/18 |
| `budget_lines` → `budget_plan_item` | 7/22 |
| `transactions` → `financial_movement` | 8/35 |
| `subscriptions` → `subscription` | 5/25 |
| `subscription_plans` → `plan` | 3/7 (los precios salen a `plan_price`) |
| `budget_periods` → `budget_plan` | 2/11 |
| `debt_schedules` → `debt_payoff_schedule` | 2/9 (otro concepto: amortización vs proyección) |

### 1a — HECHO (migración `1785699989982-AdoptJeaninneNamingPhase1a`)

Las tres tablas latentes se adoptaron con la forma completa de su modelo, no solo el nombre.
Se verificó que estaban vacías, por eso el cambio se resolvió con drop + create explícito en
lugar de `RENAME TO` más cirugía de columnas.

- `budget_periods` → `budget_plan`: `year`+`month` → `period_month DATE`, `currency` texto →
  `currency_id` FK, `uq_budget_plan_user_month`.
- `budget_lines` → `budget_plan_item`: `planned_amount` → `amount_limit`, se retira
  `subcategory_id` (`category` ya es jerárquica), `category_id` pasa a NOT NULL.
- `debt_snowball_plan` → `debt_payoff_simulation`: entran `start_date`, `simulation_status`,
  `initial_lump_sum`; salen `computed_at`, `estimated_completion`, `ordered_debt_ids` (el
  resultado de la simulación vive en `debt_payoff_schedule` y `debt_projection`).
- PKs de las 5 tablas M4 latentes: `financial_rule.id`→`financial_rule_id`,
  `debt_cycle.id`→`cycle_id`, `debt_signal.id`→`signal_id`,
  `debt_recommendation.id`→`recommendation_id`, `debt_projection.id`→`projection_id`.
- `timestamptz` y CHECK constraints de su modelo en todo lo tocado.

Verificado contra Postgres efímero: run limpio (57 tablas), `generate` posterior sin drift,
`revert` restaura un esquema byte a byte idéntico al previo.

### 1b-infra — HECHO (migración `1785700793866-InfraTablesPhase1b`)

Las tablas vivas referenciaban infraestructura ausente. Se crearon 5 de las 6 con el DDL de su
modelo, CHECK incluidos:

| Tabla | Ubicación | Desbloquea |
|---|---|---|
| `financial_institution` | `src/catalog/entities/` | `user_financial_instrument`, `financial_movement` |
| `user_financial_instrument` | `src/cashflow/entities/` | `debt`, `financial_movement` |
| `cashflow_node` | `src/cashflow/entities/` | `financial_movement` |
| `file_upload` | `src/imports/entities/` | `financial_movement` |
| `company` | `src/subscriptions/entities/` | `subscription` |

Se creó `file_upload` con el DDL base de su `schema.sql`; los 18 campos que `migration.sql`
le añade son semántica de onboarding/M4 y quedan para la Fase 3. Convive con
`statement_imports` (que tiene servicio activo e `import_line_items` colgando) hasta que M5
decida cuál queda.

`file_upload.file_status_id` apunta al dominio `file_upload` del catálogo de status, que se
sembró en `catalog-seed.service.ts` con 5 estados: `pending`, `processing`, `processed`,
`partially_processed`, `failed`.

**Además: los 7 catálogos tenían la PK en camelCase** (`countryId`, `currencyId`, `statusId`,
`statusDomainId`, `documentTypeId`, `roleId`, `financialHealthLevelId`) — artefacto de TypeORM
al no pasar `name:`. Se renombraron a snake_case en la misma migración; sin eso, cada FK nueva
habría quedado apuntando a `"currencyId"`. Las propiedades TS no cambian, así que el contrato
de API queda intacto.

Verificado contra Postgres efímero: run limpio (57 → 62 tablas), `generate` posterior sin
drift, `revert` restaura un esquema idéntico, y la app arranca con `synchronize` apagado
sembrando el catálogo sin producir drift.

### 1b-debt — HECHO (migración `1785701417775-RenameDebtPhase1b`)

`debts` → `debt` con las tres conversiones a FK del modelo:

| Antes | Ahora |
|---|---|
| `currency` varchar | `currency_id` → `currency` |
| `status` varchar | `debt_status_id` → `status` (dominio `debt`: active/paid/closed) |
| `funding_source_id` | `financial_instrument_id` → `user_financial_instrument` |

Más las 4 columnas nuevas (`debt_source_type`, `interest_rate_pct`, `estimated_payoff_date`,
`released_cashflow_amount`), 8 CHECK y las 6 FK entrantes repuntadas a `debt(debt_id)`.

A diferencia de la Fase 1a, esta migración **traspasa las filas**: `debts` tiene servicio
activo. Los `funding_sources` referenciados por alguna deuda se copian a
`user_financial_instrument` conservando el UUID — solo esos, porque `funding_sources` sigue
viva (`transactions`, `bills_payable` y su CRUD la usan) y duplicarla entera dejaría dos
copias sin sincronizar.

Verificado con datos sembrados: dos deudas (una con funding source, otra sin) sobreviven el
run con las FK resueltas, el `revert` las devuelve **idénticas** y el esquema vuelve byte a
byte al estado previo. Sin drift, y la app arranca y siembra sin duplicar el dominio `debt`.

**Contrato de API:** `POST /debts` devolvía la entidad cruda con `status` y `currency` como
texto. Ahora devuelve `DebtDetail`, igual que `PATCH` — se mantienen `status` y `currency`
como código proyectado desde el catálogo, pero la respuesta trae ~20 campos en vez de la
entidad completa. Es el único cambio de contrato de toda la Fase 1.

**`debt_type` no lleva el CHECK del modelo.** Su `debt` define cinco valores
(`consumer`, `mortgage`, `credit_card`, `line`, `other`); el producto usa los ocho de
`DEBT_TYPES`, marcados en el código como contrato compartido con front-walvy, y esos cinco no
cubren `deuda_informal`, `credito_automotriz` ni `prestamo_personal`. Se sigue validando en el
DTO. **Punto a resolver con Jeaninne.**

También se corrigieron los códigos del dominio `file_upload` sembrados en la fase anterior:
eran `pending/processing/processed/partially_processed/failed` y su modelo define
`uploaded/processing/processed/failed`.

### 1b-transactions — bloqueada por tres decisiones de producto

`transactions` → `financial_movement` no es mecánico. Comparten 8 de 35 columnas y hay tres
cosas que el modelo acordado no resuelve solo:

1. **`flow_type` (fixed/variable) no existe en su modelo.** El equivalente natural es
   `functional_tag` + `functional_tag_assignment`, que son Fase 2. Adoptarlo ahora pierde el
   atributo hasta entonces.
2. **`movement_type = 'transfer'` no tiene equivalente.** `movement_direction` es solo
   `in`/`out`; un traspaso sería `out` con `cashflow_destination_id` poblado, pero eso cambia
   cómo se excluyen los traspasos internos de las métricas de gasto.
3. **`funding_sources` (120 filas, 30 usuarios) se parte en dos**: `cashflow_node` y
   `user_financial_instrument`. Sigue usada por `bills_payable` y por su propio CRUD, así que
   hay que decidir si desaparece o convive.

Y cambia el contrato de la API: `amount` → `amount_in`/`amount_out`, `occurred_on` →
`operation_date`, `description` → `raw_description`, `categorization_status` →
`movement_status_id` + `classification_method`.

### 1b-subscriptions — bloqueada por `plan_price`

Circular: `plan_price.plan_id` referencia `plan(plan_id)`, que hoy es `subscription_plans(id)`,
y su modelo saca `price` y `currency` de la tabla de planes hacia `plan_price`. Es migración de
datos sobre el checkout de Flow.cl, no infraestructura. Arrastra a `subscriptions` y
`payment_orders`.

`debt_schedules` → `debt_payoff_schedule` no es un renombre (ver abajo).

`debt_schedules` → `debt_payoff_schedule` no es un renombre: la tabla actual es un cuadro de
amortización (`installment_no`, `planned_principal`, `planned_interest`, `due_date`) y la suya
es una proyección de salida (`sequence_order`, `estimated_close_date`,
`released_cashflow_after_close`, `simulation_id`). Son dos tablas distintas y hay que decidir
si conviven o si una reemplaza a la otra.

### 1c — CHECK constraints: convención adoptada

Se adoptan los CHECK de su modelo **además** de la validación en DTO, no en su lugar: el DTO
da un mensaje de error usable, el CHECK da la garantía a nivel de dato. Es un cambio respecto
de la convención de los commits de M4 y queda registrado como tal.

## Fase 2 — M5: presupuesto y movimientos (prioridad elegida)

**ALTER sobre tablas ya renombradas en Fase 1:**

| Tabla | Campos |
|---|---|
| `budget_plan` | +5 (`financial_rule_id`, `rule_version`, `target_margin_amount`, `budget_status`, `data_confidence_level`) |
| `budget_plan_item` | +12 (umbrales, progreso, sobreconsumo, estado de recomendación) |
| `financial_movement` | +6 (`data_origin`, `evidence_origin`, `classification_certainty`, `validation_status`, `rule_scope`, `classification_rule_version`) |

**CREATE — 6 tablas de M5:**
`budget_signal`, `budget_recommendation`, `movement_user_validation`,
`classification_learning_rule`, `recommendation_evidence`, `intermodule_derivation`.

**Dependencias que obligan a adelantar trabajo a esta fase:**

- `budget_plan_item.source_rule_parameter_id` → **`rule_parameter`** (estaba en Fase 3). Se adelanta.
- `budget_plan.financial_rule_id` → `financial_rule` ✅ ya existe.
- M5 BDD P-BDD-014 usa etiquetas funcionales → **`functional_tag` + `functional_tag_assignment`**
  se adelantan también.

Total Fase 2: 3 ALTER + **9 CREATE**.

## Fase 3 — Perfil y documentos

- `user_financial_profile` +14 campos. `current_debt_health_status_id` requiere sembrar el
  status domain `debt_health` (4 valores; está en `seeds.sql`, falta en el backend).
- **`file_upload`** — el gap más grande (18 campos, 0 cubiertos). Hay que decidir: el backend
  tiene `statement_imports` (+ `import_line_items` colgando y un servicio activo), su modelo
  tiene `file_upload`. Recomendación: crear `file_upload` conforme al modelo y planificar el
  retiro de `statement_imports`, no forzar el ALTER sobre una tabla con otra semántica.
- Seeds pendientes de `seeds.sql` ya presentes en el repo pero sin tabla destino:
  `financial_rule` (3 reglas), `rule_parameter`, `functional_tag`, status domain `debt_health`.

## Fase 4 — Resúmenes mensuales

`user_month_diagnosis_summary` (+10 campos ya especificados), `user_month_debt_priority_summary`
(+4), `user_month_leaks_summary`, `user_upcoming_payments_summary`.

## Fase 5 — Resto del modelo (hoja de ruta, fuera del MVP inmediato)

- **Identidad y permisos**: `permission`, `role_permission`. Es el prerrequisito para eliminar
  `admin_users` / `admin_audit_log` — hoy `app_user` solo tiene un `role_id` plano, así que el
  argumento de Jeaninne no se sostiene todavía sobre el modelo real.
- **Pagos e instrumentos**: `payment_method`, `user_payment`, `user_financial_instrument`,
  `financial_institution`, `plan_price`.
- **Mensajería**: `message_event`, `message_rule`, `user_message_interaction`.
- **Empresa y beneficios**: `company`, `company_benefit_contract`, `company_eligible_employee`,
  `benefit_invitation`.
- **Otros**: `cashflow_node`, `country_currency`, `movement_review_queue`,
  `movement_classification_history`.

---

## Método por fase

El mismo que validó el commit `c395203`:

1. Editar las entities — son la fuente de verdad, no el SQL.
2. `pnpm run migration:generate` (nunca escribir la migración a mano: el drift check del último
   ciclo expuso `TIMESTAMPTZ` vs `TIMESTAMP`, `COMMENT ON` faltantes y nombres de FK/índice que
   TypeORM no reconocía).
3. Verificar contra un Postgres efímero sembrado con el schema previo: `run` aplica limpio,
   un `migration:generate` posterior no reporta drift, `revert` restaura el estado original.
4. Regenerar `DB/schema/schema.sql`.
5. Un commit por fase.

Los `COMMENT ON` de `comments.sql` se incorporan como metadata `comment:` en las entities, que
es de donde `migration:generate` los emite — no como script aparte.

## Advertencia de alcance

Que una columna exista en el schema **no** significa que la feature esté en el MVP. Antes de
escribir documentación funcional de cualquiera de estos módulos, contrastar contra la fuente
del cliente, no contra el schema.

## Riesgos abiertos

| Riesgo | Mitigación |
|---|---|
| CHECK constraints duplican validación DTO | Decidir en Fase 1e y documentar como cambio de convención |
| `statement_imports` vs `file_upload` con servicio activo | Crear `file_upload` nuevo, retirar `statement_imports` en un ciclo posterior |
| 5 tablas propias no contempladas en su modelo | Llevarlas a la sesión con justificación, no eliminarlas por omisión |
| `admin_users` sin modelo de permisos que lo reemplace | Fase 5 antes de eliminar |
| Renombre de PK filtrándose a la API | Patrón `{ name: '<entidad>_id' }` con propiedad `id` — verificar en cada entity tocada |
