# ADR-003 — PostgreSQL con Status Domain Pattern y 19 Layers

| Campo | Valor |
|-------|-------|
| **Número** | ADR-003 |
| **Título** | PostgreSQL con Status Domain Pattern y 19 Layers |
| **Estado** | Accepted |
| **Fecha** | 2026-05-14 |
| **Autores** | Equipo Walvy |
| **Revisores** | — |

---

## Contexto

Al diseñar el schema de base de datos de Walvy se identificaron los siguientes requisitos:

- **Multi-país desde el inicio**: Walvy comienza en Chile pero el diseño debe soportar expansión a otros mercados (Perú, Colombia, México) sin cambios estructurales en el schema.
- **Multi-moneda**: soportar CLP, USD y otras monedas. Los montos deben ser precisos (sin pérdida de punto flotante).
- **Extensibilidad de estados sin deploys**: agregar un nuevo estado a una entidad (e.g., un nuevo estado de suscripción) no debe requerir un `ALTER TYPE` en un ENUM de PostgreSQL ni un deployment del backend.
- **Auditoría y trazabilidad**: nunca eliminar datos históricos de usuarios, movimientos financieros ni deudas.
- **Precios históricos**: el historial de precios de planes debe conservarse para que las suscripciones pasadas tengan referencia al precio que se cobró en su momento.
- **Performance de lectura**: las consultas de dashboard y reportes no deben hacer múltiples JOINs costosos en tiempo real.

---

## Decisión

Se adopta un schema PostgreSQL con **Status Domain Pattern**, **19 layers de abstracción**, **precios bitemporales**, **soft deletes**, **CQRS read models** y **vistas SQL**.

### Status Domain Pattern

En lugar de ENUMs nativos de PostgreSQL, los estados de entidades se gestionan mediante dos elementos:

**Tabla `status_domain`:**
```sql
CREATE TABLE status_domain (
  domain  VARCHAR(50) NOT NULL,   -- e.g., 'subscription', 'user', 'payment_order'
  status  VARCHAR(50) NOT NULL,   -- e.g., 'active', 'suspended', 'pending'
  label   VARCHAR(100),           -- etiqueta legible por humanos
  PRIMARY KEY (domain, status)
);
```

**Trigger `enforce_status_domain()`:**  
En cada tabla que tiene una columna `status`, un trigger before-insert/update verifica que el valor de `status` exista en `status_domain` para el dominio correspondiente. Si no existe, la operación falla.

```sql
-- El trigger se añade a cada tabla con columna status
CREATE TRIGGER check_status_subscription
  BEFORE INSERT OR UPDATE ON subscription
  FOR EACH ROW EXECUTE FUNCTION enforce_status_domain('subscription');
```

**Ventaja clave**: para agregar el estado `'trial'` a suscripciones, basta con insertar una fila en `status_domain`. No se requiere `ALTER TYPE`, no se requiere deployment.

### 19 Layers

El schema se organiza en 20 capas de abstracción (0 a 19) que reflejan las dependencias entre tablas:

| Layer | Categoría | Tablas principales |
|-------|-----------|-------------------|
| 0 | Catálogos base | `country`, `currency`, `doc_type` |
| 1 | Dominios y configuración | `status_domain`, `app_config` |
| 2 | Roles y seguridad | `role`, `permission` |
| 3 | Niveles de salud financiera | `health_level` |
| 4 | Identidad y auth | `app_user`, `refresh_tokens`, `otp_tokens`, `biometric_credentials`, `onboarding_state` |
| 5 | B2B | `company`, `benefits` |
| 6 | Perfil financiero | `financial_profile`, `goals`, `alerts`, `notifications` |
| 7 | Instituciones financieras | `financial_institution`, `institution_category` |
| 8 | Categorías de movimientos | `movement_category` |
| 9 | Movimientos financieros | `financial_movement`, `movement_dedup` |
| 10 | Presupuesto | `budget`, `budget_category` |
| 11 | Deudas | `debt`, `debt_payment_plan` |
| 12 | Pagos | `payment_history` |
| 13 | Monetización | `plan`, `plan_price`, `subscription`, `payment_order` |
| 14 | Gamificación | `gamification_rule`, `gamification_event`, `user_stats`, `stats_history` |
| 15 | Mensajería | `message_thread`, `message` |
| 16 | AI assistant | `ai_conversation`, `ai_message` |
| 17 | Backoffice admin | `admin_audit_log`, `admin_action` |
| 18 | Read models CQRS | `rm_user_dashboard`, `rm_cashflow_summary`, `rm_budget_status`, `rm_debt_overview` |
| 19 | Vistas SQL | `v_user_financial_health`, `v_monthly_summary`, `v_debt_snowball`, `v_subscription_status` |

### Precios bitemporales (plan_price)

La tabla `plan_price` almacena el precio de cada variante de plan con vigencia temporal:

```sql
CREATE TABLE plan_price (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id     UUID NOT NULL REFERENCES plan(id),
  period      VARCHAR(20) NOT NULL,      -- 'monthly', 'annual'
  amount      NUMERIC(12,2) NOT NULL,
  currency    VARCHAR(3) NOT NULL,       -- 'CLP', 'USD'
  valid_from  TIMESTAMPTZ NOT NULL,
  valid_to    TIMESTAMPTZ,               -- NULL = vigente actualmente
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

Para obtener el precio actual: `WHERE valid_from <= NOW() AND (valid_to IS NULL OR valid_to > NOW())`.

Las suscripciones guardan referencia a `plan_price_id` al momento de la contratación, preservando el precio histórico aunque el plan cambie de precio después.

### Montos monetarios

Todas las columnas de dinero usan `NUMERIC(12,2)` — nunca `FLOAT` ni `DOUBLE PRECISION`. Esto evita errores de punto flotante en cálculos financieros.

En TypeORM, se aplica el transformer `decimalToNumberTransformer` que convierte el string que retorna pg a `number` en JavaScript:

```typescript
export const decimalToNumberTransformer: ValueTransformer = {
  to: (value: number) => value,
  from: (value: string) => parseFloat(value),
};
```

### Soft deletes

Las siguientes entidades **nunca se eliminan físicamente**:

| Entidad | Motivo |
|---------|--------|
| `app_user` | Auditoría, datos de suscripción históricos, GDPR (derecho al olvido se implementa como anonimización, no eliminación) |
| `financial_movement` | Integridad de reportes históricos y deduplicación |
| `debt` | Historial de deudas saldadas o canceladas |

Implementación: columna `deleted_at TIMESTAMPTZ` — `NULL` = activo, valor = fecha de eliminación lógica.

TypeORM: `@DeleteDateColumn({ name: 'deleted_at' })` — las queries excluyen automáticamente registros con `deleted_at IS NOT NULL`.

### CQRS read models (Layer 18)

Los 4 read models son tablas desnormalizadas que se actualizan via triggers o jobs cuando los datos fuente cambian. Permiten consultas de dashboard sin JOINs complejos:

- `rm_user_dashboard`: resumen financiero del usuario (saldo, gastos del mes, progreso de metas)
- `rm_cashflow_summary`: totales por categoría agrupados por mes
- `rm_budget_status`: estado actual de presupuesto vs gasto real
- `rm_debt_overview`: resumen del plan bola de nieve

### DB_SYNC

```bash
DB_SYNC=false   # producción y staging SIEMPRE
DB_SYNC=true    # solo permitido en desarrollo local TRANSITORIAMENTE
```

Con `DB_SYNC=true`, TypeORM sincroniza el schema automáticamente con las entidades — útil en desarrollo para prototipar sin escribir SQL. **Nunca usar en producción** (puede alterar o eliminar columnas inesperadamente).

---

## Soft delete — regla de implementación

```typescript
// Correcto: soft delete
await this.userRepository.softRemove(user);
// o
await this.userRepository.update(userId, { deletedAt: new Date() });

// INCORRECTO: nunca usar en app_user, financial_movement, debt
await this.userRepository.delete(userId);
await this.userRepository.remove(user);
```

Los queries de TypeORM con `findOne`, `find`, `findAndCount` excluyen automáticamente los soft-deleted cuando se usa `@DeleteDateColumn`.

---

## Estado de migrations

A la fecha (2026-05-14) **no existe carpeta `migrations/`**. El schema se mantiene sincronizado via `DB_SYNC=true` en desarrollo.

**Antes del primer deploy a producción es obligatorio:**

1. Deshabilitar `DB_SYNC` (`DB_SYNC=false`)
2. Generar la migration inicial: `typeorm migration:generate -n InitialSchema`
3. Revisar la migration generada manualmente (verificar que no drope datos)
4. Añadir la migration al pipeline de CI/CD
5. Toda modificación futura al schema requiere una nueva migration

---

## Consecuencias

### Ventajas

- **Sin ALTER TYPE para nuevos estados**: nuevos estados de suscripción, usuario o pago se agregan con un INSERT en `status_domain`, sin deployment.
- **Multi-tenant ready**: `country` y `currency` como catálogos en Layer 0 permiten escalar a múltiples mercados.
- **Trazabilidad completa**: soft deletes + precios bitemporales garantizan que ningún dato histórico se pierde.
- **Performance de lectura**: los read models CQRS evitan JOINs costosos en el dashboard del usuario.
- **Extensible**: agregar un nuevo módulo (e.g., gamificación) solo requiere agregar tablas en el layer correspondiente.

### Desventajas

- **Complejidad del schema**: 19 layers con ~40 tablas requieren conocimiento previo del diseño para navegar sin perderse.
- **Curva de aprendizaje**: el Status Domain Pattern es menos intuitivo que ENUMs nativos para desarrolladores nuevos.
- **Overhead de triggers**: cada INSERT/UPDATE en tablas con status tiene overhead del trigger. En práctica, el volumen de Walvy no lo hace significativo.

---

## Alternativas consideradas

### Opción 1: ENUMs nativos de PostgreSQL

```sql
CREATE TYPE subscription_status AS ENUM ('active', 'cancelled', 'expired');
```

**Rechazada porque**: añadir un nuevo valor requiere `ALTER TYPE ... ADD VALUE` — una operación DDL que en producción puede bloquear la tabla brevemente y requiere un deployment del backend para que TypeORM reconozca el nuevo valor.

### Opción 2: Columnas de status como VARCHAR sin validación

- Sin tabla de dominios, sin trigger.
**Rechazada porque**: cualquier string sería aceptado como status, generando inconsistencias de datos difíciles de detectar.

### Opción 3: Tabla de configuración de estados por código

- Similar al Status Domain Pattern pero sin trigger.
**Rechazada porque**: la validación en aplicación (en lugar de en DB) puede omitirse si el código tiene un bug o si alguien hace una query directa a la DB.

---

## Mejoras futuras

- Implementar carpeta `migrations/` antes del primer deploy a producción.
- Considerar `pg_partitioning` en `financial_movement` si el volumen supera los 10M de filas por usuario.
- Evaluar `TimescaleDB` para series temporales de movimientos financieros si el volumen lo justifica.
- Los read models del Layer 18 actualmente son hipotéticos (no implementados en M1). Implementar a partir de M3 (cashflow).
