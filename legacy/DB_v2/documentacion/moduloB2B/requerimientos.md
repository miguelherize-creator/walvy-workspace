# Módulo 2 — Requerimientos

**Módulo:** B2B Corporativo  
**Layer:** 5 (B2B)  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`

---

## Alcance MVP — resumen rápido

| Funcionalidad | MVP |
|---------------|-----|
| Registro y gestión de empresas | ❌ Post-MVP |
| Contratos de beneficio corporativo | ❌ Post-MVP |
| Lista blanca de empleados elegibles | ❌ Post-MVP |
| Invitaciones individuales a empleados | ❌ Post-MVP |
| Activación de cuenta vía invitación B2B | ❌ Post-MVP |
| Suscripciones de origen B2B | ❌ Post-MVP |
| Métodos de pago corporativos | ❌ Post-MVP |

> **Nota de arquitectura:** Las tablas `company`, `company_benefit_contract`, `company_eligible_employee` y `benefit_invitation` existen en el schema como **capacidad arquitectónica**. `app_config['feature_b2b_enabled'] = false` desactiva el canal B2B en producción. Este documento describe los requerimientos para la implementación futura.

---

## Requerimientos Funcionales

### RF-01 — Registro de empresa

| Campo | Detalle |
|-------|---------|
| **ID** | RF-01 |
| **Nombre** | Crear empresa contratante |
| **Descripción** | El backoffice puede registrar una empresa que contratará el acceso a Walvy para sus empleados. |
| **Inputs** | `name`, `country_id`, `document_type_id` (opcional), `document_number` (opcional), `contact_email`, `contact_person_name`, `contact_phone` |
| **Reglas** | - La razón social debe ser única por país (`UNIQUE country_id + name`). - El número de documento debe ser único por país (`UNIQUE country_id + document_number`). - `country_id` debe referenciar un país activo en la tabla `country`. |
| **Output** | `company` creada con `company_id` generado. |

---

### RF-02 — Gestión de contratos de beneficio

| Campo | Detalle |
|-------|---------|
| **ID** | RF-02 |
| **Nombre** | Crear y gestionar contrato B2B |
| **Descripción** | El backoffice puede crear un contrato entre una empresa y Walvy que define el plan y la vigencia del beneficio. |
| **Inputs** | `company_id`, `plan_code`, `starts_at`, `ends_at` (opcional), `is_active` |
| **Reglas** | - `plan_code` referencia un código de convenio negociado; no se valida contra `plan.plan_id` directamente. - `ends_at = NULL` indica vigencia indefinida. - `is_active = false` suspende el contrato sin borrar los datos. - Una empresa puede tener múltiples contratos (histórico y activos simultáneos). |
| **Output** | `company_benefit_contract` creado. |

---

### RF-03 — Carga de empleados elegibles

| Campo | Detalle |
|-------|---------|
| **ID** | RF-03 |
| **Nombre** | Registrar lista blanca de empleados |
| **Descripción** | El backoffice puede cargar (manualmente o vía CSV) la lista de empleados elegibles para un contrato. |
| **Inputs** | `contract_id`, lista de empleados: `email`, `document_type_id` (opcional), `document_number` (opcional) |
| **Reglas** | - `email` es obligatorio para poder enviar invitaciones. - Un empleado puede ser identificado también por documento para matching post-registro. - No puede haber dos entradas con el mismo email en el mismo contrato (`UNIQUE contract_id + email`). - No puede haber dos entradas con el mismo documento en el mismo contrato. - `activated_user_id = NULL` hasta que el empleado active su cuenta. |
| **Output** | Registros en `company_eligible_employee` con `invited_at = NULL`. |

---

### RF-04 — Envío de invitaciones a empleados

| Campo | Detalle |
|-------|---------|
| **ID** | RF-04 |
| **Nombre** | Invitar empleado a Walvy |
| **Descripción** | El sistema envía una invitación individual a cada empleado elegible. La invitación tiene ciclo de vida propio. |
| **Reglas** | - Al generar: crea `benefit_invitation` con `invitation_status = 'created'`. - Al enviar el email: `invitation_status = 'sent'`, `sent_at = now()`, `company_eligible_employee.invited_at = now()`. - No puede existir más de una invitación activa (`created` o `sent`) por empleado (índice único parcial). - El sistema puede reenviar generando una nueva invitación solo si la anterior está en estado `expired` o `revoked`. |
| **Output** | `benefit_invitation` creada y email enviado al empleado. |

---

### RF-05 — Activación de cuenta por empleado

| Campo | Detalle |
|-------|---------|
| **ID** | RF-05 |
| **Nombre** | Activar cuenta B2B |
| **Descripción** | Al registrarse en Walvy, si el email del nuevo usuario coincide con un empleado elegible no activado, el sistema vincula la cuenta y activa una suscripción B2B automáticamente. |
| **Reglas** | - Al completar el registro (CU-01 del Módulo 1), el backend busca en `company_eligible_employee` donde `email = nuevo_email` y `activated_user_id IS NULL`. - Si hay match, se rellena `activated_user_id = user_id`. - Se actualiza `benefit_invitation.invitation_status = 'accepted'`, `accepted_at = now()`. - Se crea una `subscription` con `origin = 'B2B'` y `company_id` correspondiente. - Si no hay match, el registro continúa como usuario B2C normal. |
| **Output** | `company_eligible_employee.activated_user_id` poblado; suscripción B2B activa. |

---

### RF-06 — Expiración de invitaciones

| Campo | Detalle |
|-------|---------|
| **ID** | RF-06 |
| **Nombre** | Expirar invitaciones vencidas |
| **Descripción** | Un job nocturno detecta invitaciones enviadas que no han sido aceptadas y las marca como expiradas. |
| **Reglas** | - Invitaciones en estado `sent` con `sent_at < now() - interval configurable` pasan a `expired`. - Una invitación expirada libera al empleado para recibir una nueva invitación. - No se borra el historial de invitaciones. |
| **Output** | `benefit_invitation.invitation_status = 'expired'` para invitaciones vencidas. |

---

### RF-07 — Revocación de invitaciones y suscripciones

| Campo | Detalle |
|-------|---------|
| **ID** | RF-07 |
| **Nombre** | Revocar acceso B2B |
| **Descripción** | El backoffice puede revocar manualmente una invitación activa o el acceso de un empleado que ya activó su cuenta. |
| **Reglas** | - Revocar invitación activa: `invitation_status = 'revoked'`. - Revocar empleado con cuenta activa: adicionalmente, cancelar la suscripción B2B del usuario (`subscription.status = cancelled`). - No se elimina la cuenta del usuario; solo pierde el beneficio corporativo. |
| **Output** | Invitación revocada y/o suscripción cancelada. |

---

## Requerimientos No Funcionales

### RNF-01 — Feature flag obligatorio
El canal B2B solo opera cuando `app_config['feature_b2b_enabled'] = true`. El backend debe verificar este flag antes de procesar cualquier flujo B2B. Si está en `false`, los endpoints B2B retornan `503 Feature not available`.

### RNF-02 — Matching de empleados en tiempo de registro
La búsqueda de empleados elegibles al momento del registro debe completarse en menos de 100ms adicionales al flujo de registro estándar. Usar índice sobre `(email)` en `company_eligible_employee`.

### RNF-03 — Idempotencia de activación
Si un usuario se registra dos veces con el mismo email (caso de error), el matching B2B debe ser idempotente: no crear dos suscripciones B2B para el mismo empleado.

### RNF-04 — Auditoría de cambios de contrato
Toda modificación en `company_benefit_contract.is_active` debe quedar registrada en `admin_audit_log` con `before_data` y `after_data`.

### RNF-05 — Privacidad del listado de empleados
El endpoint que expone `company_eligible_employee` solo debe ser accesible por roles `admin` o `super_admin`. Nunca exponer la lista completa de empleados de una empresa a usuarios finales.

### RNF-06 — Integridad referencial en cancelación
Al cancelar un contrato (`is_active = false`), el backend debe decidir la política para empleados ya activados: cancelar suscripciones inmediatamente o respetar el `ends_at` del contrato. La decisión debe documentarse en `app_config['b2b_contract_cancel_policy']`.
