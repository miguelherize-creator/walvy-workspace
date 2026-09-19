# Módulo B2B — Corporativo

**Layer:** 5 (Empresas y Beneficios)  
**Estado:** 📋 Referencia — fuera de scope MVP, abierto a cambios  
**Docs originales:** `legacy/DB_v2/documentacion/moduloB2B/`

---

## Propósito
Soporte para el modelo corporativo: una empresa contrata Walvy como beneficio para sus empleados. La empresa paga el plan; los empleados acceden con su cuenta personal.

> ⚠️ **Fuera del MVP actual.** `app_config.feature_b2b_enabled = false`. Estas tablas están en el schema pero ningún módulo NestJS las implementa.

---

## Dependencias

```
country (M1) ──► company
app_user (M1) ──► company_admin (empleado que administra)
plan / subscription (M10) ──► company_benefit_contract

company_benefit_contract ──► company_eligible_employee
                          ──► benefit_invitation
app_user ──► benefit_invitation (empleado que acepta)
```

---

## Tablas

### `company`
| Columna | Notas |
|---------|-------|
| `company_id` UUID PK | |
| `name` VARCHAR(200) | Razón social |
| `document_type_id` FK NULL | RUT empresa u equivalente |
| `document_number` VARCHAR(50) NULL | |
| `country_id` FK | |
| `is_active` BOOLEAN | |

### `company_admin`
Empleados de la empresa con acceso al backoffice corporativo.

| Columna | Notas |
|---------|-------|
| `company_id` FK, `user_id` FK | PK compuesta |
| `role` VARCHAR(20) | `owner`, `admin`, `viewer` |

### `company_benefit_contract`
Contrato activo entre empresa y Walvy.

| Columna | Notas |
|---------|-------|
| `contract_id` UUID PK | |
| `company_id` FK | |
| `plan_id` FK | |
| `max_employees` INT NULL | Límite de beneficiarios |
| `starts_at` / `ends_at` TIMESTAMPTZ | Vigencia del contrato |
| `status` VARCHAR(15) | `active`, `suspended`, `expired` |

### `company_eligible_employee`
Lista de empleados habilitados para recibir el beneficio.

| Columna | Notas |
|---------|-------|
| `contract_id` FK | |
| `email` TEXT | Email corporativo del empleado |
| `invited_at` TIMESTAMPTZ NULL | |
| `accepted_at` TIMESTAMPTZ NULL | |
| `user_id` UUID NULL FK → app_user | Vinculado al aceptar |

### `benefit_invitation`
Invitaciones enviadas a empleados.

| Columna | Notas |
|---------|-------|
| `contract_id` FK | |
| `email` TEXT | |
| `token_hash` TEXT UNIQUE | Token de invitación |
| `expires_at` TIMESTAMPTZ | |
| `accepted_at` TIMESTAMPTZ NULL | |

---

## Flujo B2B (cuando se implemente)
1. Empresa firma contrato → `company_benefit_contract`
2. Admin carga lista de empleados → `company_eligible_employee`
3. Sistema envía invitaciones → `benefit_invitation`
4. Empleado acepta → crea cuenta → `subscription` se activa automáticamente con `company_id`
