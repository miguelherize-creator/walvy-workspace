# Base de Datos Walvy — Índice

**Motor:** PostgreSQL 16 · **Total tablas:** 71 · **Capas:** 19 (L0–L18)

---

## Fuentes de verdad

| Recurso | Ruta | Confianza |
|---------|------|-----------|
| Schema SQL activo (M1-M2) | `back-walvy/DB/schema.sql` | ✅ Producción |
| DBML completo | `back-walvy/DB/walvy-full.dbml` | ✅ Producción |
| Documentación M1 | `back-walvy/DB/modulo1/` | ✅ Producción |
| Documentación M2 | `back-walvy/DB/modulo2/` | ✅ Producción |
| Schema SQL extendido (M1-M10) | `legacy/DB_v2/schema.sql` | 📋 Referencia |
| Documentación M3-M10, B2B | `legacy/DB_v2/documentacion/` | 📋 Referencia |
| Q&A revisión Jeaninne Rivera | `context/db/QA-jeaninne.md` | 📋 Referencia |
| Decisión: admin_users / admin_audit_log | `workspace/utils/admin-tables-decision.md` | 📋 Decisión |

> **Producción** = en uso en el backend, source of truth.  
> **Referencia** = borradores bien encaminados, abiertos a cambios según diseño y cliente.

---

## Módulos y layers

| Módulo | Nombre | Layers | Estado | Archivo |
|--------|--------|--------|--------|---------|
| M1 | Identidad y Auth | 0-4 | ✅ Producción | [modulo1.md](modulo1.md) |
| M2 | Perfil y Configuración | 6 | ✅ Producción | [modulo2.md](modulo2.md) |
| M3 | Home / Dashboard | 14,15,18,19 | 📋 Referencia | [modulo3.md](modulo3.md) |
| M4 | Deudas (Bola de Nieve) | 11 | 📋 Referencia | [modulo4.md](modulo4.md) |
| M5 | Cashflow (Movimientos e Ingesta) | 7,8,9 | 📋 Referencia | [modulo5.md](modulo5.md) |
| M6 | Presupuesto | 10 | 📋 Referencia | [modulo6.md](modulo6.md) |
| M7 | Pagos y Agenda | 12 | 📋 Referencia | [modulo7.md](modulo7.md) |
| M8 | Asistente IA | 16 | 📋 Referencia | [modulo8.md](modulo8.md) |
| M9 | Administración y Auditoría | 17 | 📋 Referencia | [modulo9.md](modulo9.md) |
| M10 | Monetización | 13 | ✅ Producción (parcial) | [modulo10.md](modulo10.md) |
| B2B | Corporativo | 5 | 📋 Referencia | [moduloB2B.md](moduloB2B.md) |

---

## Patrones transversales (aplican a todos los módulos)

### Status Domain Pattern
Los estados NO son ENUMs nativos de PostgreSQL.
```sql
status_domain (code: 'user', 'debt', 'subscription', ...)
    └── status (code: 'active', 'paused', ... UNIQUE dentro del dominio)
```
Trigger `enforce_status_domain(expected_domain_code, p_status_id)` valida la FK en INSERT/UPDATE.  
Agregar un nuevo estado = solo un `INSERT` en `status`, sin `ALTER TABLE`.

### Soft Delete
`deleted_at TIMESTAMPTZ NULL` en: `app_user`, `financial_movement`, `debt`.  
**Nunca DELETE físico** en estas tablas.

### Precios Bitemporales
`plan_price` con `valid_from DATE` / `valid_to DATE NULL`.  
Precio vigente = `valid_from <= now() AND (valid_to IS NULL OR valid_to >= now())`.

### Timestamps automáticos
Función `set_updated_at()` + trigger `trg_<tabla>_updated_at` en todas las tablas con `updated_at`.

### CQRS Read Models (Layer 18)
4 tablas de summary pre-calculadas para el Home. Las pantallas leen de estas, no de las tablas operacionales.

### Idempotencia de webhooks
`payment_order.commerce_order UNIQUE` previene duplicados en webhooks de Flow.cl.

### PKs
- UUID con `gen_random_uuid()` en tablas de negocio
- BIGSERIAL en catálogos del sistema (Layer 0-3)
