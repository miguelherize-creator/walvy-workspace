# Spec: Módulo de Cashflow

> **Módulo:** `cashflow`
> **Backend:** NestJS 10 — `src/cashflow/`
> **Sprint frontend:** Sprint 4
> **Última revisión:** 2026-05-14

---

## 1. Descripción funcional

El módulo de cashflow es el núcleo financiero de Walvy. Gestiona el registro y clasificación de movimientos de dinero (ingresos y gastos), organizados por categorías, subcategorías y fuentes de fondos. También incluye la importación de estados de cuenta bancarios en PDF para clasificación automática.

**Para el PM:** Los usuarios registran sus ingresos y gastos, los organizan en categorías (como "Alimentación", "Transporte", "Sueldo") y pueden importar su estado de cuenta del banco para que Walvy clasifique las transacciones automáticamente. El home muestra un resumen de la salud financiera basado en estos datos.

**Para el desarrollador:** El módulo tiene 5 sub-módulos: `transactions`, `categories`, `subcategories`, `funding-sources` y `statement-import`. Las categorías tienen dos tipos: globales (sembradas, no editables por usuario) y de usuario (creadas por el usuario). Las transacciones usan soft delete.

---

## 2. Transacciones — CRUD

### Entidad Transaction

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador único |
| `userId` | UUID | Dueño de la transacción |
| `type` | Enum | `income` o `expense` |
| `amount` | Decimal | Monto en CLP |
| `date` | Date | Fecha de la transacción |
| `description` | String | Descripción libre |
| `categoryId` | UUID | Categoría (obligatoria) |
| `subcategoryId` | UUID | Subcategoría (opcional) |
| `fundingSourceId` | UUID | Fuente de fondos (obligatoria) |
| `statementLineId` | UUID | Referencia a línea de estado de cuenta (si fue importada) |
| `deletedAt` | Timestamp | Soft delete |

### Endpoints

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/cashflow/transactions` | JWT | Lista transacciones del usuario (paginadas) |
| GET | `/cashflow/transactions/:id` | JWT | Detalle de una transacción |
| POST | `/cashflow/transactions` | JWT | Crea una transacción |
| PATCH | `/cashflow/transactions/:id` | JWT | Actualiza una transacción |
| DELETE | `/cashflow/transactions/:id` | JWT | Soft delete de transacción |

### Query params de listado

| Param | Tipo | Descripción |
|-------|------|-------------|
| `page` | number | Número de página (default: 1) |
| `limit` | number | Items por página (default: 20, máx: 100) |
| `type` | `income \| expense` | Filtrar por tipo |
| `categoryId` | UUID | Filtrar por categoría |
| `fundingSourceId` | UUID | Filtrar por fuente de fondos |
| `from` | Date (ISO8601) | Fecha inicio (inclusive) |
| `to` | Date (ISO8601) | Fecha fin (inclusive) |

### Create transaction — Request body

```json
{
  "type": "income | expense",
  "amount": "number (positivo, requerido)",
  "date": "ISO8601 date (requerido)",
  "description": "string (requerido)",
  "categoryId": "uuid (requerido)",
  "subcategoryId": "uuid (opcional)",
  "fundingSourceId": "uuid (requerido)"
}
```

### Reglas

- Soft delete: `DELETE` marca `deletedAt`, el registro no se elimina físicamente
- Una transacción no puede referenciar una categoría global que no pertenezca al scope del usuario
- Las transacciones importadas desde estado de cuenta tienen `statementLineId` poblado; las manuales no
- El `amount` siempre es positivo; el `type` determina si es ingreso o gasto

---

## 3. Categorías

### Tipos de categorías

| Tipo | Descripción | Editable por usuario |
|------|-------------|----------------------|
| Global | Sembradas en el sistema (ej: Alimentación, Transporte, Sueldo) | No — solo lectura |
| Usuario | Creadas por el usuario para necesidades específicas | Sí — CRUD completo |

### Entidad Category

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | Identificador |
| `name` | String | Nombre de la categoría |
| `type` | Enum | `income` o `expense` (para qué tipo de transacción aplica) |
| `isGlobal` | Boolean | `true` = global, `false` = del usuario |
| `userId` | UUID | Null si global, UUID si es del usuario |
| `icon` | String | Nombre del icono (ej: `food`, `transport`) |
| `color` | String | Color hex para UI |

### Endpoints

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/cashflow/categories` | JWT | Lista categorías globales + del usuario |
| GET | `/cashflow/categories/:id` | JWT | Detalle de una categoría |
| POST | `/cashflow/categories` | JWT | Crea categoría de usuario |
| PATCH | `/cashflow/categories/:id` | JWT | Actualiza categoría del usuario (no globales) |
| DELETE | `/cashflow/categories/:id` | JWT | Elimina categoría del usuario (no globales) |

### Reglas

- Las categorías globales (`isGlobal = true`) no son modificables por ningún usuario
- `GET /cashflow/categories` retorna tanto globales como las propias del usuario
- No se puede eliminar una categoría que tenga transacciones asociadas (retorna 409)
- Una categoría sin subcategorías es una "categoría raíz"

---

## 4. Subcategorías

Las subcategorías siempre pertenecen a una categoría padre. Permiten granularidad adicional (ej: Categoría "Alimentación" → Subcategorías "Supermercado", "Restaurante", "Delivery").

### Endpoints

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/cashflow/categories/:categoryId/subcategories` | JWT | Lista subcategorías de una categoría |
| POST | `/cashflow/categories/:categoryId/subcategories` | JWT | Crea subcategoría |
| PATCH | `/cashflow/categories/:categoryId/subcategories/:id` | JWT | Actualiza subcategoría |
| DELETE | `/cashflow/categories/:categoryId/subcategories/:id` | JWT | Elimina subcategoría |

### Reglas

- Una subcategoría no puede existir sin una categoría padre
- No se puede eliminar una subcategoría con transacciones asociadas (retorna 409)
- Las subcategorías de categorías globales no son editables (heredan la regla de la categoría padre)

---

## 5. Fuentes de fondos (Funding Sources)

Representan las cuentas o billeteras del usuario desde donde salen o entran los fondos (ej: cuenta corriente, cuenta de ahorro, efectivo).

### Sembrado inicial

Al crear un usuario, se siembran automáticamente dos fuentes de fondos:

| Slug | Nombre |
|------|--------|
| `checking` | Cuenta Corriente |
| `savings` | Cuenta de Ahorro |

El usuario puede crear fuentes adicionales (ej: "Efectivo", "Cuenta RUT").

### Endpoints

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/cashflow/funding-sources` | JWT | Lista fuentes de fondos del usuario |
| GET | `/cashflow/funding-sources/:id` | JWT | Detalle de una fuente |
| POST | `/cashflow/funding-sources` | JWT | Crea una fuente de fondos |
| PATCH | `/cashflow/funding-sources/:id` | JWT | Actualiza una fuente |
| DELETE | `/cashflow/funding-sources/:id` | JWT | Elimina una fuente (no las sembradas) |

### Reglas

- Las fuentes sembradas (`checking`, `savings`) no pueden eliminarse
- No se puede eliminar una fuente con transacciones asociadas (retorna 409)

---

## 6. Importación de estados de cuenta (Statement Import)

Permite al usuario subir su estado de cuenta bancario en PDF (actualmente soportado: Santander Chile) para importar transacciones automáticamente.

### Flujo de importación

```
App                     Backend
 │                          │
 ├─ POST /statements/upload ─►
 │   (multipart/form-data)   ├─ Almacena PDF
 │                           ├─ Parsea el PDF
 │                           ├─ Extrae líneas de transacciones
 │                           ├─ Clasifica automáticamente
 │                           └─ Crea StatementImport + StatementLines
 │◄─── import_id ────────────┤
 │                           │
 ├─ GET /statements/:id ─────►
 │◄─── estado del import ────┤
 │                           │
 ├─ GET /statements/:id/lines►
 │◄─── líneas clasificadas ──┤
 │                           │
 ├─ POST /statements/:id/lines/:lineId/reclassify
 │   (reclasificación manual)►
 │◄─── línea actualizada ────┤
```

### Endpoints

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/cashflow/statements/upload` | JWT | Sube PDF y dispara importación |
| GET | `/cashflow/statements` | JWT | Lista importaciones del usuario |
| GET | `/cashflow/statements/:id` | JWT | Detalle y estado de una importación |
| GET | `/cashflow/statements/:id/lines` | JWT | Líneas extraídas del estado de cuenta |
| POST | `/cashflow/statements/:id/lines/:lineId/reclassify` | JWT | Reclasifica manualmente una línea |
| DELETE | `/cashflow/statements/:id` | JWT | Elimina una importación |

### Estados de una importación

| Estado | Descripción |
|--------|-------------|
| `uploading` | PDF recibido, en procesamiento |
| `processing` | Parseando y clasificando |
| `completed` | Procesado exitosamente |
| `failed` | Error en el procesamiento |

### Reclasificación

El usuario puede corregir la clasificación automática de una línea:

**Request body POST .../reclassify:**
```json
{
  "categoryId": "uuid",
  "subcategoryId": "uuid (opcional)"
}
```

---

## 7. Reglas generales del módulo

- Todos los endpoints requieren JWT; los datos son siempre del usuario autenticado (nunca se accede a datos de otros usuarios)
- Los `amount` en respuestas se retornan como `number` (transformer `decimalToNumber`)
- Las categorías globales se pueden listar pero no modificar
- El soft delete en transacciones no elimina la categoría ni la fuente de fondos asociada
- La clasificación automática de estados de cuenta usa reglas basadas en el texto de la descripción de cada línea
