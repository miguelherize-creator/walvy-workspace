# Módulo 2 — B2B Corporativo

**Layer cubierto:** 5 (B2B)  
**Estado MVP:** ❌ Post-MVP — las tablas existen en el schema como capacidad arquitectónica. `app_config['feature_b2b_enabled'] = false`.

---

## 1. Propósito del módulo

Habilita el canal de distribución empresarial de Walvy. Una empresa contrata el acceso a la plataforma para sus empleados; los empleados reciben una invitación individual, crean su cuenta y quedan vinculados a un plan pre-pagado por la empresa (origen `B2B`).

Sin este módulo, Walvy solo opera canal directo (`B2C`). Con él, una empresa puede incorporar a cientos de empleados sin que cada uno deba pagar su suscripción individualmente.

---

## 2. Diagrama de dependencias

```
country ──────────────────────────────────► company
document_type ────────────────────────────► company
                                               │
                                               ▼
                                   company_benefit_contract
                                               │
                                               ▼
                                   company_eligible_employee ──► app_user (cuando activa)
                                               │
                                               ▼
                                       benefit_invitation
```

**Dependencias entrantes desde otros módulos:**
- `country` (Módulo 1 · Layer 0)
- `document_type` (Módulo 1 · Layer 0)
- `app_user` (Módulo 1 · Layer 4) — se referencia cuando el empleado activa su cuenta

**Dependencias salientes hacia otros módulos:**
- `subscription.company_id` (Módulo 9) — suscripciones B2B tienen `origin = 'B2B'` y FK a `company`
- `payment_method.company_id` (Módulo 9) — métodos de pago corporativos

---

## 3. Diagrama ERD

Ver archivo: [`moduloB2B.dbml`](./moduloB2B.dbml)

Cubre las 4 tablas del módulo con sus Foreign Keys internas y las referencias a Módulo 1.

---

## 4. Tablas del módulo

### 4.1 `company`

Empresa contratante. Cada empresa pertenece a un país y puede tener múltiples contratos activos.

| Columna | Tipo | Notas |
|---------|------|-------|
| `company_id` | UUID PK | `gen_random_uuid()` |
| `name` | VARCHAR(200) | Razón social |
| `country_id` | BIGINT FK → country | País de la empresa |
| `document_type_id` | BIGINT FK → document_type NULL | Ej: RUT Empresa (CL), NIT (CO) |
| `document_number` | VARCHAR(50) NULL | Número de documento fiscal |
| `contact_email` | VARCHAR(320) NULL | Email del responsable del contrato |
| `contact_person_name` | VARCHAR(150) NULL | Nombre del responsable |
| `contact_phone` | VARCHAR(40) NULL | Teléfono de contacto |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

**Constraints:**
- `UNIQUE (country_id, name)` — misma razón social no puede repetirse en el mismo país
- `UNIQUE (country_id, document_number)` — documento único por país

---

### 4.2 `company_benefit_contract`

Contrato entre una empresa y Walvy. Define qué plan se ofrece a los empleados y por cuánto tiempo.

| Columna | Tipo | Notas |
|---------|------|-------|
| `contract_id` | UUID PK | |
| `company_id` | UUID FK → company | |
| `plan_code` | VARCHAR(50) | Código interno del convenio. Ej: `walvy_premium_12m` |
| `starts_at` | DATE | Inicio de vigencia |
| `ends_at` | DATE NULL | Fin de vigencia. NULL = indefinido |
| `is_active` | BOOLEAN | Flag operacional para activar/desactivar sin borrar |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

**Nota:** `plan_code` referencia un código de convenio, no directamente `plan.plan_id`. Esto permite negociar términos personalizados por empresa sin modificar el catálogo de planes públicos.

---

### 4.3 `company_eligible_employee`

Lista blanca de empleados elegibles por contrato. Un empleado puede ser registrado por email o por número de documento antes de que exista como usuario en la plataforma.

| Columna | Tipo | Notas |
|---------|------|-------|
| `eligible_employee_id` | UUID PK | |
| `contract_id` | UUID FK → company_benefit_contract | |
| `email` | VARCHAR(320) NOT NULL | Email del empleado |
| `document_type_id` | BIGINT FK → document_type NULL | |
| `document_number` | VARCHAR(50) NULL | |
| `invited_at` | TIMESTAMPTZ NULL | Timestamp del último envío de invitación |
| `activated_user_id` | UUID FK → app_user NULL | Se llena cuando el empleado activa su cuenta |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

**Índices únicos:**
- `UNIQUE (contract_id, email) WHERE email IS NOT NULL`
- `UNIQUE (contract_id, document_type_id, document_number) WHERE document_type_id IS NOT NULL AND document_number IS NOT NULL`

**Validación de elegibilidad:** Al registrarse, el backend busca si el email del nuevo usuario coincide con algún `company_eligible_employee` con `activated_user_id IS NULL`. Si hay match, vincula la cuenta y activa una suscripción B2B.

---

### 4.4 `benefit_invitation`

Invitación individual enviada a un empleado elegible. Una invitación tiene ciclo de vida propio: `created → sent → accepted / expired / revoked`.

| Columna | Tipo | Notas |
|---------|------|-------|
| `invitation_id` | UUID PK | |
| `eligible_employee_id` | UUID FK → company_eligible_employee | |
| `invitation_status` | VARCHAR(20) | `created`, `sent`, `accepted`, `expired`, `revoked` |
| `sent_at` | TIMESTAMPTZ NULL | Timestamp del envío real del email |
| `accepted_at` | TIMESTAMPTZ NULL | Timestamp de aceptación |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | Auto-set por trigger |

**Constraints:**
- `chk_invitation_sent_at` — si `status IN ('sent','accepted')` entonces `sent_at IS NOT NULL`
- `chk_invitation_accepted_at` — si `status = 'accepted'` entonces `accepted_at IS NOT NULL`

**Índice único parcial:** `UNIQUE (eligible_employee_id) WHERE invitation_status IN ('created','sent')` — garantiza que no existan dos invitaciones activas simultáneas para el mismo empleado.

---

## 5. Triggers del módulo

| Trigger | Tabla | Función | Evento |
|---------|-------|---------|--------|
| `trg_company_updated_at` | `company` | `set_updated_at()` | BEFORE UPDATE |
| `trg_company_benefit_contract_updated_at` | `company_benefit_contract` | `set_updated_at()` | BEFORE UPDATE |
| `trg_company_eligible_employee_updated_at` | `company_eligible_employee` | `set_updated_at()` | BEFORE UPDATE |
| `trg_benefit_invitation_updated_at` | `benefit_invitation` | `set_updated_at()` | BEFORE UPDATE |

---

## 6. Ciclo de vida de una invitación B2B

```
[Admin carga lista CSV]
        │
        ▼
company_eligible_employee (activated_user_id = NULL)
        │
        ▼
benefit_invitation → status: created
        │
        ▼ (job de envío o acción manual)
benefit_invitation → status: sent · sent_at = now()
company_eligible_employee.invited_at = now()
        │
        ├──► Empleado acepta
        │       benefit_invitation → status: accepted · accepted_at = now()
        │       company_eligible_employee.activated_user_id = user_id
        │       subscription creada con origin = 'B2B'
        │
        ├──► Expiración (job nocturno)
        │       benefit_invitation → status: expired
        │       Nueva invitación puede generarse
        │
        └──► Revocación (admin)
                benefit_invitation → status: revoked
                Si ya tenía cuenta: subscription se cancela
```

---

## 7. Relaciones con otros módulos

| Módulo destino | Tabla que referencia | Columna |
|----------------|---------------------|---------|
| Módulo 1 — Catálogos ISO | `company` | `country_id`, `document_type_id` |
| Módulo 1 — Auth | `company_eligible_employee` | `activated_user_id → app_user` |
| Módulo 9 — Monetización | `subscription` | `company_id` (origin = 'B2B') |
| Módulo 9 — Monetización | `payment_method` | `company_id` (owner_type = 'COMPANY') |
