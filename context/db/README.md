# Base de Datos Walvy — Índice

**Motor:** PostgreSQL 16 · **Total tablas:** 71 · **Capas:** 19 (L0–L18)

> ⚠️ **La numeración de esta carpeta NO es la del cliente, y desde M5 está corrida.**
> `modulo5.md` es **Cashflow**; el M05 del cliente es **Presupuesto Vivo**, que acá es
> `modulo6.md`. El M06 del cliente (**Pagos**) es `modulo7.md`, y el M07 (**Agente IA**)
> es `modulo8.md`. Antes de abrir un archivo por su número, confirmar de qué numeración
> se está hablando — el mapa completo está en [`../../CLAUDE.md`](../../CLAUDE.md).

---

## Fuentes de verdad

| Recurso | Ruta | Confianza |
|---------|------|-----------|
| **Migraciones TypeORM — lo que realmente corre** | `back-walvy/src/migrations/` (36) | ✅ Producción |
| **Entities TypeORM** | `back-walvy/src/*/entities/` | ✅ Producción |
| Schema y modelo | `back-walvy/DB/schema/` · `back-walvy/DB/model/` | ✅ Producción |
| Decisiones del baseline | `back-walvy/DB/DECISIONES-BASELINE.md` | ✅ Producción |
| Documentación M1 · M2 | `back-walvy/DB/modulo1/` · `back-walvy/DB/modulo2/` | ✅ Producción |
| Q&A revisión de schema | [`QA.md`](QA.md) | 📋 Referencia |

> **Producción** = en uso en el backend, source of truth.
> **Referencia** = borradores bien encaminados, abiertos a cambios según diseño y cliente.
>
> **Ante una discrepancia gana el código**, no estos archivos: son documentación de
> diseño y varios describen tablas con nombres que las entities no usan. El caso
> documentado está en
> [`../modulo05-cashflow/deuda-tecnica/README.md`](../modulo05-cashflow/deuda-tecnica/README.md).
> Y antes de migrar, leer los `COMMENT ON COLUMN`: el esquema documenta el modelo
> previsto.

> **Corregido el 2026-09-06.** Esta tabla listaba cinco rutas que no existen
> (`DB/schema.sql`, `DB/walvy-full.dbml`, `legacy/DB_v2/`, `QA-jeaninne.md`,
> `workspace/utils/admin-tables-decision.md`).

---

## Módulos y layers

| Módulo | Nombre | Layers | Estado | Archivo |
|--------|--------|--------|--------|---------|
| M1 | Identidad y Auth | 0-4 | ✅ Producción | [modulo1.md](modulo1.md) |
| M2 | Perfil y Configuración | 6 | ✅ Producción | [modulo2.md](modulo2.md) |
| M3 | Home / Dashboard | 14,15,18,19 | 📋 Referencia | [modulo3.md](modulo3.md) |
| M4 | Deudas (Bola de Nieve) | 11 | 📋 Referencia | [modulo4.md](modulo4.md) |
| M5 | Cashflow (Movimientos e Ingesta) · **no es el M05 del cliente** | 7,8,9 | 📋 Referencia | [modulo5.md](modulo5.md) |
| M6 | Presupuesto · **= M05 del cliente** | 10 | 📋 Referencia | [modulo6.md](modulo6.md) |
| M7 | Pagos y Agenda · **= M06 del cliente** | 12 | 📋 Referencia | [modulo7.md](modulo7.md) |
| M8 | Asistente IA · **= M07 del cliente** | 16 | 📋 Referencia | [modulo8.md](modulo8.md) |
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
