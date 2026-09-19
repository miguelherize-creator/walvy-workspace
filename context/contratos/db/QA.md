# Q&A — Revisión de DB

Respuestas técnicas a preguntas sobre el diseño de base de datos y arquitectura de Walvy MVP.

---

## Q1 — ¿Son lo mismo `user_financial_profile` y `budget_plan`? ¿Se pueden fusionar?

**Contexto:** Notó que ambas tablas parecen manejar metas y presupuestos del usuario y quería saber si podían fusionarse.

**Respuesta:** No son lo mismo y no deben fusionarse. Tienen niveles de abstracción y propósitos completamente distintos.

---

### Las tres entidades involucradas

#### 1. `user_financial_profile` — Perfil declarado

**Layer:** 6 — Perfil y Alertas de Usuario  
**Módulo:** Módulo 2 — Perfil y Configuración  
**Endpoint:** `GET /profile/financial` · `PUT /profile/financial` *(pendiente de implementar)*

Es el **contexto financiero base del usuario**. El usuario lo completa una vez durante el onboarding y lo actualiza cuando su situación cambia.


| Columna                    | Qué representa                                 |
| -------------------------- | ---------------------------------------------- |
| `estimated_monthly_income` | Cuánto gana el usuario al mes                  |
| `payment_capacity`         | Cuánto puede destinar a pagar deudas           |
| `stable_expenses`          | Gastos fijos inamovibles (arriendo, servicios) |


- Cardinalidad: **1:1 con `app_user`** — un único registro por usuario, sin período
- No tiene fecha de corte mensual
- Es input para otros sistemas: el motor de deudas lo usa para calcular cuánto extra puede abonar; el diagnóstico financiero lo cruza con los movimientos reales

---

#### 2. `budget_plan` + `budget_plan_item` — Presupuesto mensual

**Layer:** 10 — Presupuesto  
**Módulo:** Módulo 4 (sin iniciar)  
**Endpoint:** Sin implementar aún

Es la **herramienta operacional de planificación mensual**. El usuario define cuánto puede gastar por categoría cada mes, y el sistema lo contrasta con sus movimientos reales.


| Columna clave                       | Qué representa                                      |
| ----------------------------------- | --------------------------------------------------- |
| `period_month`                      | Primer día del mes al que aplica (ej: `2026-05-01`) |
| `budget_plan_item.amount_limit`     | Límite de gasto para una categoría ese mes          |
| `budget_plan_item.planned_min/max`  | Rango de gasto esperado                             |
| `budget_plan_item.suggested_by_app` | Si la app generó el ítem basado en historial        |


- Cardinalidad: **N por usuario** — un plan por mes, histórico preservado
- Tiene período explícito — permite comparar presupuestos entre meses
- Se contrasta con `financial_movement` para saber si el usuario respetó su presupuesto

---

#### 3. `user_goals` — Metas financieras

**Layer:** 6 — Perfil y Alertas de Usuario  
**Módulo:** Módulo 2 — Perfil y Configuración  
**Endpoint:** `GET /profile/goals` · `POST /profile/goals` *(pendiente de implementar)*

Son los **objetivos de largo plazo** del usuario: reducir deuda, ahorrar una cantidad, evitar pagos tardíos. No son ni perfil ni presupuesto.


| Campo            | Qué representa                                            |
| ---------------- | --------------------------------------------------------- |
| `goal_type`      | `reduce_debt`, `save_amount`, `avoid_late_payments`, etc. |
| `target_amount`  | Meta numérica (ej: ahorrar $500.000)                      |
| `progress_cache` | Métricas calculadas sin queries pesados                   |


---

### Tabla comparativa


|                  | `user_financial_profile`         | `budget_plan`                               | `user_goals`                    |
| ---------------- | -------------------------------- | ------------------------------------------- | ------------------------------- |
| **¿Qué es?**     | "¿Cuánto gano?"                  | "¿Cuánto asigno a cada categoría este mes?" | "¿Qué quiero lograr?"           |
| **Cardinalidad** | 1:1 con el usuario               | N por usuario (1 por mes)                   | N por usuario                   |
| **Temporalidad** | Sin período — estado actual      | Mensual (`period_month`)                    | Sin período fijo                |
| **Lo escribe**   | El usuario en onboarding         | El usuario + sugerencias de la app          | El usuario en onboarding        |
| **Lo lee**       | Motor de deudas, diagnóstico, IA | Dashboard de presupuesto, alertas           | Pantalla de metas, gamificación |
| **Layer DB**     | Layer 6                          | Layer 10                                    | Layer 6                         |


---

### Corrida en frío

Escenario: Ana se registra en Walvy y completa el flujo completo hasta tener un presupuesto activo.

```
┌─────────────────────────────────────────────────────────────┐
│  PASO 1 — Registro y onboarding                             │
│                                                             │
│  POST /auth/register                                        │
│  { email: "ana@walvy.cl", password: "Walvy2024", ... }      │
│                                                             │
│  → DB crea: app_user (user_id: uuid-ana)                    │
│             user_onboarding_state (onboarding_status:       │
│             'in_progress', current_step: 'email_            │
│             verification')                                  │
│             biometric_preferences (enabled: false)          │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  PASO 2 — Completa perfil financiero (Módulo 2, Layer 6)    │
│                                                             │
│  PUT /profile/financial  ← (pendiente de implementar)       │
│  {                                                          │
│    estimated_monthly_income: 1500000,  ← $1.500.000 CLP    │
│    payment_capacity: 200000,           ← puede pagar deuda  │
│    stable_expenses: 450000             ← arriendo + luz     │
│  }                                                          │
│                                                             │
│  → DB escribe: user_financial_profile                       │
│    user_id: uuid-ana                                        │
│    estimated_monthly_income: 1500000                        │
│    payment_capacity: 200000                                 │
│    stable_expenses: 450000                                  │
│                                                             │
│  Este registro es ÚNICO para Ana. No tiene mes.             │
│  El motor de deudas lo leerá para calcular cuánto puede     │
│  abonar de más.                                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  PASO 3 — Define metas (Módulo 2, Layer 6)                  │
│                                                             │
│  POST /profile/goals  ← (pendiente de implementar)          │
│  { goal_type: "reduce_debt", target_amount: 3000000 }       │
│                                                             │
│  → DB crea: user_goals                                      │
│    user_id: uuid-ana                                        │
│    goal_type: "reduce_debt"                                 │
│    target_amount: 3000000   ← quiere bajar $3M en deudas   │
│    progress_cache: { paid_so_far: 0, percent: 0 }           │
│                                                             │
│  Esta meta no tiene mes. Es un objetivo de largo plazo.     │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  PASO 4 — Crea presupuesto de mayo (Módulo 4, Layer 10)     │
│                                                             │
│  POST /budget/plans  ← (sin implementar, Módulo 4)          │
│  { period_month: "2026-05-01" }                             │
│                                                             │
│  → DB crea: budget_plan                                     │
│    user_id: uuid-ana                                        │
│    period_month: 2026-05-01                                 │
│                                                             │
│  POST /budget/plans/:id/items                               │
│  { category: "Alimentación", amount_limit: 200000 }         │
│  { category: "Transporte",   amount_limit: 80000  }         │
│  { category: "Entretención", amount_limit: 50000  }         │
│                                                             │
│  → DB crea: budget_plan_item × 3                            │
│    (uno por categoría, con su amount_limit para mayo)       │
│                                                             │
│  Este presupuesto SOLO aplica a mayo 2026.                  │
│  En junio se creará uno nuevo (puede diferir).              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  ESTADO FINAL EN DB — tres tablas, tres propósitos          │
│                                                             │
│  user_financial_profile (1 fila, sin mes):                  │
│    income: 1.500.000 · payment_capacity: 200.000            │
│                                                             │
│  user_goals (1 fila, sin mes):                              │
│    reduce_debt: meta $3.000.000                             │
│                                                             │
│  budget_plan mayo 2026 + 3 budget_plan_items:               │
│    Alimentación: límite $200.000                            │
│    Transporte:   límite $80.000                             │
│    Entretención: límite $50.000                             │
│                                                             │
│  → Si se fusionara todo en una tabla:                       │
│    ¿qué mes tiene el "income: 1.500.000"?                   │
│    ¿el límite de alimentación aplica siempre o solo mayo?   │
│    El modelo colapsa.                                       │
└─────────────────────────────────────────────────────────────┘
```

---

### Resumen

> `user_financial_profile` es "¿cuánto gano?", `budget_plan` es "¿cuánto gasto por categoría este mes?" y `user_goals` es "¿qué quiero lograr?". Son tres niveles distintos: contexto permanente, planificación mensual y objetivos de largo plazo.

---

### Nota técnica — Estado de implementación en v1

Las tres tablas de esta pregunta están **definidas en el schema y con seeds listos**, pero el backend actual no tiene ningún endpoint que las use. El schema se diseñó completo desde el inicio para evitar migraciones destructivas después, pero el backend solo implementa lo necesario para el MVP de auth + suscripciones.

**Tablas actualmente usadas por el backend (Módulo 1 + Módulo 2 parcial):**


| Tabla                            | Layer | Usado en v1 | Endpoint                                        |
| -------------------------------- | ----- | ----------- | ----------------------------------------------- |
| `app_user`                       | 4     | ✅           | Todos los flujos de auth                        |
| `refresh_tokens`                 | 4     | ✅           | login, refresh, logout                          |
| `email_verification_tokens`      | 4     | ✅           | `/auth/email-verification/`*                    |
| `password_reset_tokens`          | 4     | ✅           | `/auth/forgot-password`, `/auth/reset-password` |
| `biometric_preferences`          | 4     | ✅           | `PATCH /auth/biometric`                         |
| `user_onboarding_state`          | 4     | ✅           | `GET/PATCH /auth/onboarding`                    |
| `plan` + `plan_price`            | 13    | ✅           | `GET /subscriptions/plans`                      |
| `subscription` + `payment_order` | 13    | ✅           | checkout + webhook Flow                         |


**Tablas de esta Q1 — schema listo, sin endpoint:**


| Tabla                              | Layer | Módulo   | Por qué está pendiente                           |
| ---------------------------------- | ----- | -------- | ------------------------------------------------ |
| `user_financial_profile`           | 6     | Módulo 2 | Sin pantalla aprobada por diseño                 |
| `user_goals`                       | 6     | Módulo 2 | Diseño en borrador, regla de negocio sin definir |
| `budget_plan` / `budget_plan_item` | 10    | Módulo 4 | Módulo sin iniciar                               |


---

## Q3 — ¿Pueden tener un mapeo visual de la base de datos con colores (como en Figma)?

**Contexto:** Preguntó si podían implementar un sistema de colores para la base de datos, similar al que usan en Figma (verde claro = en revisión, verde oscuro = revisado, azul = cerrado), para saber qué tablas están terminadas, cuáles en progreso y cuáles pendientes.

**Respuesta:** Sí, y ya está hecho — se generaron tres entregables: un archivo DBML consolidado con colores nativos para importar en dbdiagram.io, un mapa visual en HTML con tarjetas por tabla agrupadas por layer, y un diagrama interactivo de conexiones FK agrupadas por layer con zoom y collapse.

---

### Convención de colores (mapeada desde Figma)


| Color        | Hex       | Significado en DB                                  | Equivalente Figma |
| ------------ | --------- | -------------------------------------------------- | ----------------- |
| Verde oscuro | `#27AE60` | Implementado — schema + endpoints operativos en v1 | Revisado          |
| Amarillo     | `#F0B429` | Schema listo — endpoint pendiente de implementar   | En revisión       |
| Azul         | `#5B9BD5` | Schema definido — módulo sin iniciar               | Cerrado (roadmap) |


---

### Estado actual de cada tabla

**Verde oscuro — Implementado** (Layer 0–4 + Layer 13 parcial)


| Tabla                                                                              | Layer |
| ---------------------------------------------------------------------------------- | ----- |
| `country`, `currency`, `country_currency`, `document_type`                         | 0     |
| `status_domain`, `status`                                                          | 1     |
| `role`, `permission`, `role_permission`                                            | 2     |
| `financial_health_level`, `app_config`                                             | 3     |
| `app_user`, `refresh_tokens`, `password_reset_tokens`, `email_verification_tokens` | 4     |
| `biometric_preferences`, `user_onboarding_state`                                   | 4     |
| `plan`, `plan_price`, `subscription`, `payment_order`                              | 13    |


**Amarillo — Schema listo, endpoint pendiente** (Layer 6)


| Tabla                    | Layer | Módulo   |
| ------------------------ | ----- | -------- |
| `user_financial_profile` | 6     | Módulo 2 |
| `user_goals`             | 6     | Módulo 2 |
| `alert_preferences`      | 6     | Módulo 2 |
| `notification_queue`     | 6     | Módulo 2 |


**Azul — Schema definido, módulo sin iniciar** (Layers 5, 7–12, 13 parcial, 14–18)


| Tablas                                                                                                                           | Layer |
| -------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `company`, `company_benefit_contract`, `company_eligible_employee`, `benefit_invitation`                                         | 5     |
| `financial_institution`, `user_financial_instrument`, `cashflow_node`, `category`, `ant_expense_rules`                           | 7     |
| `file_upload`, `import_line_items`, `movement_classification_suggestions`                                                        | 8     |
| `financial_movement`, `movement_review_queue`, `movement_classification_history`                                                 | 9     |
| `budget_plan`, `budget_plan_item`                                                                                                | 10    |
| `debt`, `debt_schedules`, `debt_payments`, `debt_attachments`, `debt_payoff_simulation`, `debt_payoff_schedule`                  | 11    |
| `user_payment`, `recurring_payment_suggestions`                                                                                  | 12    |
| `payment_method`                                                                                                                 | 13    |
| `gamification_rules`, `gamification_events`, `user_gamification_stats`, `user_score_history`                                     | 14    |
| `message_rule`, `message_event`, `user_message_interaction`                                                                      | 15    |
| `ai_conversations`, `ai_messages`, `ai_tool_invocations`, `ai_context_snapshots`, `faq_articles`                                 | 16    |
| `admin_users`, `admin_audit_log`, `audit_log`, `report_snapshots`                                                                | 17    |
| `user_month_diagnosis_summary`, `user_month_debt_priority_summary`, `user_upcoming_payments_summary`, `user_month_leaks_summary` | 18    |


---

## Q2 — ¿Conviene dejar la configuración de alertas para el final del desarrollo?

**Contexto:** Planteó si no era más eficiente dejar toda la configuración de alertas y gatilladores para el final del proyecto (en lugar de irla haciendo módulo a módulo), porque a medida que avanza el diseño aparecen cosas nuevas que obligan a rehacer lo que ya se configuró.

**Respuesta:** La preocupación es válida en sistemas donde los triggers de alerta están hardcodeados. En Walvy no aplica, porque el sistema de alertas está diseñado en capas separadas donde cada parte puede avanzar independientemente sin generar rework.

---

### Cómo está diseñado el sistema de alertas

El sistema no es una sola pieza — son cuatro capas con responsabilidades distintas:


| Capa                     | Tabla(s)                         | Layer | Módulo           | Qué hace                                                                                                     |
| ------------------------ | -------------------------------- | ----- | ---------------- | ------------------------------------------------------------------------------------------------------------ |
| Preferencias del usuario | `alert_preferences`              | 6     | Módulo 2         | Guarda solo las sobreescrituras del usuario — lo que quiere recibir y con qué intensidad                     |
| Defaults del sistema     | `app_config`                     | 3     | Módulo 1         | Qué alertas están activas por defecto. Cambiar un default = UPDATE en DB, sin deploy                         |
| Cola de despacho         | `notification_queue`             | 6     | Módulo 2         | Cualquier módulo deposita notificaciones aquí; un worker las consume                                         |
| Reglas contextuales      | `message_rule` + `message_event` | 15    | Post-MVP inicial | Mensajería basada en reglas semánticas (`leaks_detected`, `pay_next`). Las reglas son filas en DB, no código |


---

### La división recomendada


| Qué                                                        | Cuándo construirlo                    | Razón                                                                                               |
| ---------------------------------------------------------- | ------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `alert_preferences` + endpoint `GET/PATCH /profile/alerts` | Módulo 2 (ahora)                      | Es parte del scope MVP del módulo; `estimated_payment_capacity` lo necesita para el Motor de Deudas |
| `notification_queue`                                       | Módulo 2 (ahora)                      | Módulo 7 (Pagos) y Módulo 5 (Presupuesto) escriben aquí — si no existe, bloquea módulos posteriores |
| Worker `in_app` + `email`                                  | Módulo 2 o 3                          | Canales simples, sin infraestructura externa                                                        |
| Worker `push` (FCM/APNs)                                   | Post-MVP o cuando se defina proveedor | Requiere decisión de infraestructura y credenciales externas                                        |
| Nuevas reglas en `message_rule`                            | Con cada módulo que las necesite      | Solo un INSERT — cero rework                                                                        |


---

### Corrida en frío — cómo un módulo posterior agrega una alerta sin tocar código existente

Escenario: se implementa el Módulo 5 (Presupuesto) y necesita alertar cuando el usuario llega al 80% de su límite de categoría.

```
┌─────────────────────────────────────────────────────────────┐
│  Módulo 5 ya existe: budget_plan + budget_plan_item          │
│  El motor detecta: gasto en "Alimentación" = $160.000        │
│  Límite: $200.000 → 80% alcanzado                           │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Backend consulta preferencias de Ana                        │
│                                                             │
│  SELECT enabled FROM alert_preferences                      │
│  WHERE user_id = uuid-ana                                   │
│    AND alert_type = 'budget_threshold'                      │
│    AND channel = 'in_app'                                   │
│                                                             │
│  Si no hay fila → aplica default de app_config              │
│  (budget_threshold_enabled = true por defecto)              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Backend escribe en notification_queue                       │
│                                                             │
│  INSERT INTO notification_queue (                           │
│    user_id:        uuid-ana,                                │
│    channel:        'in_app',                                │
│    payload:        { title: "80% del presupuesto",          │
│                      body: "Alimentación: $160K / $200K",   │
│                      deep_link: "/budget/may-2026" },       │
│    scheduled_for:  now(),                                   │
│    reference_type: 'budget_plan_item',                      │
│    reference_id:   uuid-item-alimentacion                   │
│  )                                                          │
│                                                             │
│  → No se modificó alert_preferences                         │
│  → No se modificó el worker                                 │
│  → No se modificó ninguna tabla del Módulo 2                │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Worker (ya existente desde Módulo 2) despacha               │
│                                                             │
│  SELECT * FROM notification_queue                           │
│  WHERE sent_at IS NULL                                      │
│    AND scheduled_for <= now()                               │
│                                                             │
│  → Encuentra la fila de Ana                                 │
│  → Despacha por in_app                                      │
│  → UPDATE sent_at = now()                                   │
└─────────────────────────────────────────────────────────────┘
```

El Módulo 5 agregó una alerta nueva sin modificar nada de lo que ya existía.

---

### Resumen

> Diferir el **schema** y la **cola** de alertas genera el problema contrario al que describe: los módulos posteriores no tienen dónde depositar sus notificaciones y hay que hacer integración retroactiva. Lo que sí conviene diferir es el **worker de push** (FCM/APNs), que es infraestructura real con dependencias externas. Las reglas nuevas (`message_rule`) se agregan con cada módulo mediante INSERT — sin rework.

