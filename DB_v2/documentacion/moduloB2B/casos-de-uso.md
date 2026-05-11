# Módulo 2 — Casos de Uso

**Módulo:** B2B Corporativo  
**Estado MVP:** ❌ Post-MVP — todos los casos de uso requieren `app_config['feature_b2b_enabled'] = true`

**Actores:**
- **Administrador** — operador del backoffice interno de Walvy
- **Sistema** — procesos automáticos del backend (jobs, triggers)
- **Empleado** — usuario final que recibe el beneficio corporativo

> Todos los casos de uso de este módulo son **Post-MVP**. Se documentan para guiar la implementación futura.

---

## CU-01 — Registrar empresa contratante

**Actor principal:** Administrador  
**Precondiciones:** El administrador tiene rol `admin` o `super_admin`. El país de la empresa existe en `country`.

### Flujo principal

```
1. Administrador accede al backoffice y navega a "Empresas".
2. Administrador completa el formulario: razón social, país, documento fiscal (opcional),
   datos de contacto.
3. Sistema valida:
   a. Nombre único en el país (UNIQUE country_id + name).
   b. Número de documento único en el país (si se proporciona).
4. Sistema crea registro en company.
5. Sistema registra acción en admin_audit_log.
6. Administrador ve confirmación con company_id.
```

### Flujos alternativos

**3a — Razón social duplicada en el país:**
```
→ Error 409 "Ya existe una empresa con ese nombre en el país seleccionado."
```

**3b — Documento duplicado en el país:**
```
→ Error 409 "Ya existe una empresa con ese número de documento en el país seleccionado."
```

### Postcondiciones
- Existe un registro en `company`.
- Queda trazabilidad en `admin_audit_log`.

---

## CU-02 — Crear contrato de beneficio

**Actor principal:** Administrador  
**Precondiciones:** La empresa ya existe en `company`. El `plan_code` del convenio ha sido negociado.

### Flujo principal

```
1. Administrador selecciona una empresa y toca "Nuevo contrato".
2. Administrador ingresa: plan_code, starts_at, ends_at (opcional).
3. Sistema valida que starts_at <= ends_at (si ends_at está presente).
4. Sistema crea company_benefit_contract con is_active = true.
5. Administrador puede comenzar a cargar empleados en el contrato.
```

### Flujos alternativos

**Contrato de duración indefinida:**
```
→ Administrador deja ends_at vacío → ends_at = NULL → vigencia indefinida.
```

**Desactivar contrato temporalmente:**
```
1. Administrador edita el contrato y cambia is_active = false.
2. Sistema registra cambio en admin_audit_log con before/after.
3. Nuevas invitaciones del contrato quedan bloqueadas.
4. Empleados ya activados mantienen suscripción según política en app_config['b2b_contract_cancel_policy'].
```

### Postcondiciones
- Existe un registro en `company_benefit_contract` con `is_active = true`.

---

## CU-03 — Cargar lista de empleados elegibles

**Actor principal:** Administrador  
**Precondiciones:** El contrato existe y tiene `is_active = true`.

### Flujo A — Carga manual

```
1. Administrador accede al contrato y toca "Agregar empleado".
2. Administrador ingresa email del empleado (y opcionalmente tipo/número de documento).
3. Sistema valida unicidad dentro del contrato.
4. Sistema crea company_eligible_employee con activated_user_id = NULL, invited_at = NULL.
```

### Flujo B — Carga masiva por CSV

```
1. Administrador sube archivo CSV con columnas: email, document_type_code, document_number.
2. Sistema procesa fila a fila:
   a. Valida formato de email.
   b. Valida unicidad en el contrato.
   c. Inserta filas válidas.
   d. Agrupa filas con error para reporte.
3. Sistema retorna resumen: N insertados, M con error + detalle.
```

### Postcondiciones
- Existen registros en `company_eligible_employee` con `activated_user_id = NULL`.

---

## CU-04 — Enviar invitaciones a empleados

**Actor principal:** Administrador / Sistema  
**Precondiciones:** Existen registros en `company_eligible_employee` sin invitación activa.

### Flujo principal

```
1. Administrador selecciona empleados y toca "Enviar invitaciones".
2. Para cada empleado elegible seleccionado:
   a. Sistema crea benefit_invitation con invitation_status = 'created'.
   b. Sistema encola email de invitación.
3. Job de envío procesa la cola:
   a. Sistema envía email al empleado con link/instrucciones para registrarse.
   b. Sistema actualiza benefit_invitation.invitation_status = 'sent', sent_at = now().
   c. Sistema actualiza company_eligible_employee.invited_at = now().
```

### Flujos alternativos

**Empleado ya tiene invitación activa:**
```
→ Sistema omite ese empleado. El índice único parcial evita duplicados.
```

**Error de entrega de email:**
```
→ Sistema registra el error. invitation_status permanece en 'created' para reintento.
```

### Postcondiciones
- Cada empleado invitado tiene un registro en `benefit_invitation` con `invitation_status = 'sent'`.

---

## CU-05 — Empleado activa su cuenta Walvy

**Actor principal:** Empleado  
**Precondiciones:** El empleado recibió una invitación. `benefit_invitation.invitation_status = 'sent'`.

### Flujo principal

```
1. Empleado recibe email de invitación con instrucciones para registrarse en Walvy.
2. Empleado descarga la app y se registra con el mismo email de la invitación.
3. Sistema ejecuta flujo estándar de registro (CU-01 del Módulo 1).
4. Al finalizar el registro, Sistema busca en company_eligible_employee:
   WHERE email = nuevo_email AND activated_user_id IS NULL
5. Si hay match:
   a. Sistema actualiza company_eligible_employee.activated_user_id = user_id.
   b. Sistema actualiza benefit_invitation.invitation_status = 'accepted',
      accepted_at = now().
   c. Sistema crea subscription con origin = 'B2B', company_id correspondiente,
      plan según plan_code del contrato.
   d. Empleado obtiene acceso premium sin pago individual.
6. App lleva al empleado al onboarding estándar.
```

### Flujo alternativo — Email no coincide con ningún elegible

```
4. No hay match en company_eligible_employee:
→ Registro continúa como usuario B2C estándar.
→ No se notifica al empleado que no fue encontrado en ninguna lista.
```

### Flujo alternativo — Invitación expirada

```
2. Empleado intenta registrarse pero la invitación ya expiró.
→ Se crea la cuenta B2C normal (sin beneficio corporativo).
→ El empleado debe contactar a su empresa para que reenvíen la invitación.
```

### Postcondiciones
- `company_eligible_employee.activated_user_id` está poblado.
- `benefit_invitation.invitation_status = 'accepted'`.
- El empleado tiene una suscripción activa con `origin = 'B2B'`.

---

## CU-06 — Expirar invitaciones vencidas (job nocturno)

**Actor principal:** Sistema  
**Precondiciones:** Existen invitaciones en estado `sent` más antiguas que el umbral configurado.

### Flujo principal

```
1. Job nocturno se ejecuta (ej: 02:00 UTC).
2. Sistema busca:
   SELECT * FROM benefit_invitation
   WHERE invitation_status = 'sent'
   AND sent_at < now() - interval app_config['b2b_invitation_expiry_days']
3. Para cada invitación encontrada:
   Sistema actualiza invitation_status = 'expired'.
4. Sistema registra en log de jobs la cantidad de invitaciones expiradas.
```

### Postcondiciones
- Las invitaciones vencidas tienen `invitation_status = 'expired'`.
- Los empleados correspondientes pueden recibir nuevas invitaciones.

---

## CU-07 — Revocar acceso B2B

**Actor principal:** Administrador  
**Precondiciones:** El administrador tiene rol `admin` o `super_admin`.

### Flujo A — Revocar invitación pendiente

```
1. Administrador selecciona un empleado con invitación en estado 'created' o 'sent'.
2. Administrador selecciona "Revocar invitación" con motivo.
3. Sistema actualiza benefit_invitation.invitation_status = 'revoked'.
4. Sistema registra en admin_audit_log.
```

### Flujo B — Revocar acceso de empleado activo

```
1. Administrador selecciona un empleado con activated_user_id poblado.
2. Administrador selecciona "Revocar beneficio corporativo".
3. Sistema cancela la suscripción B2B del usuario:
   subscription.status = 'cancelled' (o según política de cancelación).
4. Sistema registra en admin_audit_log con before/after.
5. La cuenta del usuario permanece activa en Walvy (no se elimina).
   El usuario pasa a estado sin suscripción activa (puede contratar B2C).
```

### Postcondiciones
- **Flujo A:** `benefit_invitation.invitation_status = 'revoked'`.
- **Flujo B:** Suscripción B2B cancelada; cuenta de usuario intacta.

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Registrar empresa contratante | Administrador | RF-01 | ❌ Post-MVP |
| CU-02 | Crear contrato de beneficio | Administrador | RF-02 | ❌ Post-MVP |
| CU-03 | Cargar lista de empleados elegibles | Administrador | RF-03 | ❌ Post-MVP |
| CU-04 | Enviar invitaciones a empleados | Administrador / Sistema | RF-04 | ❌ Post-MVP |
| CU-05 | Empleado activa su cuenta Walvy | Empleado | RF-05 | ❌ Post-MVP |
| CU-06 | Expirar invitaciones vencidas | Sistema | RF-06 | ❌ Post-MVP |
| CU-07 | Revocar acceso B2B | Administrador | RF-07 | ❌ Post-MVP |
