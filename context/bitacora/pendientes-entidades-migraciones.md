# Pendientes — alineación de entidades con las migraciones

**Fecha:** 2026-08-10
**Contexto:** PR #66 (migraciones), #67 (entidades de catálogo y usuario), #68
(reducción de superficie a Módulo 1) y #69 (corte de CI + entidades de M1).
Erick aprobó el #67 y el #68 dejando constancia de que los puntos abiertos
quedan en esta lista.

**Estado al cierre del #69:** Módulo 1 alineado, 0 desajustes en las 9 tablas de
sus 35 endpoints. 0 entidades declaran columnas inexistentes.

---

## A. Alcance retirado en el #68 — reconectar en su momento

El #68 descargó `CashflowModule`, `DebtsModule` y `SubscriptionsModule` de
`app.module` para que el backend arrancara sin entidades desalineadas. **No es
descarte: hay que reconectarlos.** Cubre transactions, funding-sources,
categories, subscriptions y debts.

Decisión de producto ya tomada y registrada: **las cuentas nacen sin orígenes de
fondo** — `user-initialization.service` dejó de sembrar `funding_sources`.

Al reconectar cada módulo hay que realinear sus entidades contra el esquema de
las migraciones. La coincidencia de columnas medida contra la tabla candidata
dice si alcanza con repuntar el `@Entity` o si hay que escribir una entidad
nueva:

| Entidad | Tabla candidata | Coincidencia | Al reconectar |
|---|---|---|---|
| `AdminAuditLog` | `audit_log` | 88% | Repuntar |
| `Debt` | `debt` | 82% | Repuntar |
| `PaymentOrder` | `payment_order` | 79% | Repuntar |
| `BudgetLine` | `budget_plan_item` | 64% | Revisar caso a caso |
| `Subscription` | `subscription` | 45% | Entidad nueva |
| `Transaction` | `financial_movement` | 44% | Ya reemplazada, ver abajo |
| `FundingSource` | `user_financial_instrument` | 44% | Entidad nueva |
| `BudgetPeriod` | `budget_plan` | 33% | Entidad nueva |
| `SubscriptionPlan` | `plan` | 30% | Entidad nueva |
| `DebtSnowballPlan` | `debt_payoff_simulation` | 29% | Entidad nueva |
| `AdminUser` | — | sin candidata | Bloqueado, ver §C |

Por debajo del 50% no es la misma tabla con otro nombre: es otro modelo.
Repuntar el `@Entity` ahí deja una entidad que miente sobre la tabla.

**`Transaction` es el caso especial.** El #69 ya creó `FinancialMovement` sobre
`financial_movement`. Cuando `CashflowModule` vuelva, su controlador y su
servicio tienen que apuntar a `FinancialMovement`; reconectar `Transaction` a esa
misma tabla dejaría dos entidades con dos juegos de metadata y de relaciones
sobre una sola tabla.

---

## B. Preguntas para BBDD y producto

| # | Punto | Por qué importa |
|---|---|---|
| B1 | `admin_users` no existe en ninguna de las 87 tablas del esquema | `AdminUser` no se puede realinear: o el modelo la omitió o la funcionalidad se descartó |
| B2 | `admin_audit_log` tampoco existe, pero sí `audit_log` con su propia entidad | Dos conceptos de auditoría duplicados; cuál queda |
| B3 | `file_upload` tiene `requires_password` y `password_required`, ambas NOT NULL DEFAULT false | Nada en las migraciones las diferencia. Se mapearon las dos porque omitir una haría que `migration:generate` la borre |
| B4 | `user_goals` tiene `is_active` y `goal_status`, que se pisan | `goal_status` ya trae `active`, `paused` y `dismissed` |
| B5 | `import_line_items` cuelga de dos padres: `import_id` a `statement_imports` y `file_upload_id` a `file_upload` | Dos tablas de documento en paralelo, la de la aplicación y la del modelo |
| B6 | `financial_movement` tiene dos CHECK sobre `payment_instrument_type`, uno redundante | Inocuo, pero es ruido en el esquema |
| B7 | El front manda `category` y `subcategory` como texto; `financial_movement` los guarda como UUID | Verificado el 2026-08-10: front-walvy no llama a `/categories`, solo lleva los nombres en el payload de la cartola. La traducción hay que resolverla al cablear movimientos |
| B8 | **No se registra qué versión de términos y privacidad aceptó cada usuario** | Ver detalle abajo. Planteado a Jeannine el 2026-08-10 |

### B8 — Versionado de términos y condiciones

El esquema guarda **solo el momento** de la aceptación: `app_user.accepted_terms_at`
y `app_user.accepted_privacy_at`, dos timestamps. Verificado el 2026-08-10: no
existe ninguna otra columna ni tabla que registre **qué versión** se aceptó, y no
hay tabla de versionado legal en las 87.

Consecuencias, si el texto cambia:

- No se puede saber qué versión aceptó cada usuario
- No hay mecanismo para exigir una nueva aceptación a quienes aceptaron la anterior
- No queda evidencia de a qué se obligó cada cuenta

Es definición de modelo antes que de código, y conviene resolverla antes de que
haya usuarios reales. Cubre las reglas M1-RN-ACC-010 y M1-RN-ACC-011, tarjeta
RM1-05 de la revisión de conformidad.

---

## C. Deuda técnica del código

| # | Punto |
|---|---|
| C1 | Borrar `scripts/verificar-entidades.ts` al terminar la alineación de entidades. Es andamiaje temporal; Erick aprobó el #67 sobre esa base |
| C2 | El CI no corre `entities:check` ni después del #69. El e2e valida contra el esquema de las migraciones, pero la deriva entre entidad y tabla sigue sin detectarse sola |
| C3 | `goal_type` y `onboarding_status` siguen declarados como `string` teniendo CHECK. Pasarlos a unión, como se hizo con el resto en el #69 |
| C4 | Transformers duplicados en tres entidades, y las dos copias de `decimalToNumber` discrepan: una devuelve `0` para null y la otra `null`. El #69 dejó `src/common/utils/column-transformers.util.ts` para lo nuevo; falta unificar las locales |

---

## D. Trabajo de entidades que queda

### 43 tablas sin entidad

| Bloque | Tablas |
|---|---|
| Deuda (Módulo 4) | 7 |
| Movimientos y clasificación | 7 |
| Suscripciones y pagos | 6 |
| Reglas, catálogo y permisos | 6 |
| Presupuesto (Módulo 5) | 4 |
| Read-models mensuales | 4 |
| B2B y beneficios | 4 |
| Mensajería | 3 |
| Transversal | 2 |

Prioridad sugerida: los 7 de movimientos y clasificación más
`user_month_diagnosis_summary`. No hacen falta para los 35 endpoints de M1, pero
sí para **implementar** las reglas de onboarding, y continúan lo que el #69 ya
cableó con `financial_movement`.

### 7 columnas sin declarar en 6 entidades

| Tabla | Columna |
|---|---|
| `notification_queue` | `user_payment_id` — la única en un módulo que hoy arranca |
| `category` | `replaced_by_category_id` |
| `ant_expense_rules` | `updated_at` |
| `debt_payments` | `movement_id` |
| `app_config` | `value_type` |
| `audit_log` | `before_data`, `after_data` |

---

## E. Consecuencia operativa

**No correr `migration:generate` hasta cerrar §A y §D.** Con 43 tablas sin
entidad propondría borrarlas; con las 11 huérfanas, recrear tablas que ya
existen; con las 7 columnas, borrarlas.
