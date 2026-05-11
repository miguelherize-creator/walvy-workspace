# Módulo 9 — Casos de Uso

**Módulo:** Administración y Auditoría  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 9

**Actores:**
- **Super admin** — acceso total al backoffice
- **Operador** — acceso a catálogos y reglas; sin gestión de admins

---

## CU-01 — Login de administrador

**Actor:** Super admin / Operador

```
1. Admin accede a la URL del backoffice.
2. Ingresa email y contraseña.
3. Backend valida contra admin_users (bcrypt).
4. Si válido: genera JWT con { admin_id, role }.
5. Actualiza last_login_at.
6. Admin accede al dashboard.
```

---

## CU-02 — Gestionar reglas de gamificación

**Actor:** Operador / Super admin  
**Ref:** CU-07 de Módulo 3

```
1. Admin navega a "Gamificación" → "Reglas".
2. Ve listado de gamification_rules (event_type, points, is_active).
3. Puede:
   a. Editar puntos de una regla → UPDATE gamification_rules.
   b. Desactivar una regla → is_active = false.
   c. Crear una nueva regla → INSERT.
4. Cada acción genera INSERT en admin_audit_log (before_data/after_data).
5. Los cambios aplican en el próximo evento (no retroactivos).
```

---

## CU-03 — Gestionar reglas de mensajería

**Actor:** Operador / Super admin  
**Ref:** CU-06 de Módulo 3

```
1. Admin navega a "Recomendaciones" → "Reglas".
2. Ve listado de message_rule (code, context, priority, is_active).
3. Puede activar/desactivar, cambiar prioridad o editar deep_link.
4. El cambio toma efecto en el próximo ciclo del job de análisis.
5. INSERT en admin_audit_log.
```

---

## CU-04 — Ver auditoría de operadores

**Actor:** Super admin

```
1. Super admin navega a "Auditoría".
2. Filtra por operador, entidad o rango de fechas.
3. App llama GET /admin/audit-log.
4. Backend retorna admin_audit_log con before_data/after_data.
5. Super admin puede ver exactamente qué cambió cada operador.
```

---

## CU-05 — Ver reportes del backoffice

**Actor:** Super admin

```
1. Admin navega a "Reportes".
2. Selecciona tipo de reporte y período.
3. Backend busca report_snapshots por report_type + period.
4. Si el snapshot existe: retorna el payload JSON.
5. Si no existe: muestra "Reporte pendiente de generación".
```

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Login de administrador | Admin | RF-01 | ✅ |
| CU-02 | Gestionar reglas de gamificación | Operador | RF-02 | ✅ |
| CU-03 | Gestionar reglas de mensajería | Operador | RF-03 | ✅ |
| CU-04 | Ver auditoría de operadores | Super admin | RF-04 | ✅ |
| CU-05 | Ver reportes del backoffice | Admin | RF-05 | ✅ |
