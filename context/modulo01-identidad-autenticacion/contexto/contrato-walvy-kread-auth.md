# Contrato de Integración — Walvy ↔ Kread
**Mecanismo de Autenticación y Deduplicación de Documentos**

| | |
|---|---|
| Versión | 1.1 |
| Fecha | 2026-07-04 |
| Estado | Borrador para revisión |
| Clasificación | Confidencial |

---

## 1. Contexto

Walvy permite subir cartolas bancarias (PDF, Excel, CSV) que Kread procesa. Hoy el endpoint `POST /statement-imports/upload` reenvía el archivo a Kread sin autenticación ni deduplicación.

Este documento define los cambios para:
1. **Autenticar** que el request proviene de Walvy (no de terceros)
2. **Detectar documentos duplicados** antes de procesarlos
3. **Limitar la validez** de cada request en el tiempo (ventana de 10 minutos)

### Decisión de arquitectura (v1.1)

Se usan **dos tablas DynamoDB** con responsabilidades separadas:

| Tabla | Propósito | Consumidor principal |
|---|---|---|
| `walvy-platform-v1-doc-dedup-{env}` | Registro de documentos ya procesados (deduplicación) | Walvy |
| `walvy-platform-v1-kread-tokens-{env}` | Token efímero de un solo uso para validar el request | Walvy (escribe) · Kread (lee + elimina) |

---

## 2. Flujo

```
Walvy Backend              doc-dedup          kread-tokens              Kread
      │                        │                    │                    │
  Recibe archivo               │                    │                    │
  fileHash = SHA256(bytes)     │                    │                    │
      │                        │                    │                    │
  GET pk="walvy#{fileHash}" ──►│                    │                    │
  ← status=processed? → 409 ──│                    │                    │
      │                        │                    │                    │
  PUT { pk, status:pending } ─►│  (ConditionExpression: attribute_not_exists(pk))
  ← ConditionalCheckFailed → 409                    │                    │
      │                        │                    │                    │
  token = HMAC(fh+importId+ts) │                    │                    │
  PUT { pk, importId, ttl } ───────────────────────►│                    │
      │                        │                    │                    │
  POST archivo ───────────────────────────────────────────────────────────►
  X-Walvy-Signature: <token>   │                    │         ① Verifica HMAC
  X-Walvy-FileHash:  <hash>    │                    │         ② Timestamp < 10min
  X-Walvy-ImportId:  <uuid>    │                    │         ③ GET pk en kread-tokens
  X-Walvy-Timestamp: <iso>     │                    │◄────────④ DELETE pk
      │                        │                    │         ⑤ Procesa documento
      │                        │                    │                    │
  ← 200 OK ───────────────────────────────────────────────────────────────│
      │                        │                    │                    │
  UPDATE { status:processed } ─►│  (elimina ttl)     │                    │
      │                        │                    │                    │
  ← error / timeout ───────────│                    │                    │
  DELETE pk (status:pending) ─►│                    │                    │
```

**Resumen por tabla**

- **doc-dedup:** Walvy consulta y reserva el hash al inicio; confirma o libera según el resultado.
- **kread-tokens:** Walvy escribe el token antes del POST; Kread lo valida y lo elimina (uso único).

---

## 3. Headers HTTP (Walvy → Kread)

| Header | Tipo | Descripción |
|---|---|---|
| `X-Walvy-Signature` | hex 64 chars | `HMAC-SHA256(fileHash + importId + timestamp, sharedSecret)` |
| `X-Walvy-FileHash` | hex 64 chars | SHA-256 del contenido binario del archivo |
| `X-Walvy-ImportId` | UUID v4 | ID del registro en `statement_imports` de Walvy |
| `X-Walvy-Timestamp` | ISO 8601 UTC | Momento de generación. Kread rechaza si supera 10 min |

---

## 4. Esquema DynamoDB

Ambas tablas comparten la misma partition key: `pk` (String). Prefijo `walvy#` para multitenancy futuro.

### 4.1 Tabla `doc-dedup` — deduplicación

**Nombre en dev:** `walvy-platform-v1-doc-dedup-dev`

```json
{
  "pk":         "walvy#<sha256-del-archivo>",
  "importId":   "<uuid>",
  "userId":     "<uuid>",
  "status":     "pending | processed",
  "createdAt":  "2026-06-23T15:30:00.000Z",
  "processedAt": "2026-06-23T15:32:00.000Z",
  "ttl":        1751234567
}
```

| Campo | Reglas |
|---|---|
| `status` | `pending` al reservar el hash; `processed` tras éxito de Kread |
| `ttl` | Solo en `pending`: `now + 900s` (15 min) como red de seguridad si Walvy no confirma ni libera |
| `processedAt` | Se escribe al pasar a `processed` |
| Items `processed` | **Sin TTL** — permanecen hasta rotación manual o política futura |

**Operaciones Walvy**

| Momento | Operación | Condición |
|---|---|---|
| Inicio del upload | `GET` | Si `status = processed` → `409` |
| Inicio del upload | `PUT` con `status: pending` | `ConditionExpression: attribute_not_exists(pk)` → falla → `409` |
| Kread responde OK | `UPDATE` → `status: processed`, `processedAt`, eliminar `ttl` | — |
| Kread falla / timeout | `DELETE` | Solo si `status = pending` |

### 4.2 Tabla `kread-tokens` — token efímero

**Nombre en dev:** `walvy-platform-v1-kread-tokens-dev`

```json
{
  "pk":        "walvy#<sha256-del-archivo>",
  "importId":  "<uuid>",
  "userId":    "<uuid>",
  "createdAt": "2026-06-23T15:30:00.000Z",
  "ttl":       1751234567
}
```

| Campo | Reglas |
|---|---|
| `ttl` | `now + 600s` (10 minutos) |
| Uso | Kread **elimina el item** tras validarlo (uso único) |
| Fallback | Si Kread no elimina, DynamoDB lo purga al vencer el TTL |

**Operaciones**

| Actor | Operación |
|---|---|
| Walvy | `PUT` antes del POST a Kread |
| Kread | `GET` → validar `importId` → `DELETE` |

> **Nota:** `pk` es el mismo formato en ambas tablas (`walvy#<sha256>`), pero son registros independientes con distinto ciclo de vida.

---

## 5. Algoritmo HMAC

```
toSign = fileHash + importId + timestamp   // concatenación sin separadores
sig    = HMAC-SHA256(toSign, sharedSecret).hexdigest()
```

**Node.js**
```js
const sig = createHmac('sha256', sharedSecret)
  .update(fileHash + importId + timestamp)
  .digest('hex')
```

**Python**
```python
sig = hmac.new(secret.encode(), (fh+iid+ts).encode(), hashlib.sha256).hexdigest()
```

> El orden `fileHash + importId + timestamp` es parte del contrato. Cualquier variación produce una firma distinta.

---

## 6. Validaciones en Kread (en orden)

Kread **solo accede a `kread-tokens`**. No lee ni escribe `doc-dedup`.

| # | Validación | Falla si… | Error |
|---|---|---|---|
| 1 | Headers presentes | Alguno de los 4 falta o está vacío | `400` |
| 2 | Timestamp válido | `now − timestamp > 10 min` | `401` |
| 3 | Firma HMAC válida | Recomponer y comparar en **tiempo constante** | `401` |
| 4 | Registro en `kread-tokens` | No existe o `importId` no coincide | `409` |
| 5 | Eliminar registro | Ejecutar DELETE en `kread-tokens` (si falla, continuar igual) | — |

---

## 7. Cambios en Walvy Backend

### Nuevo: `DynamoDedupService` (`doc-dedup`)

- `checkDuplicate(fileHash): Promise<boolean>` — GET; retorna `true` si `status = processed`
- `reserveDocument(fileHash, importId, userId): Promise<void>` — PUT condicional con `status: pending` y TTL 900s
- `confirmProcessed(fileHash): Promise<void>` — UPDATE a `status: processed`, set `processedAt`, eliminar `ttl`
- `releasePending(fileHash): Promise<void>` — DELETE si el import falló

### Nuevo: `DynamoTokenService` (`kread-tokens`)

- `writeToken(fileHash, importId, userId): Promise<void>` — PUT con TTL 600s

### Cambios en `StatementImportsService.upload()`

1. `fileHash = sha256(buffer)`
2. `checkDuplicate(fileHash)` → si true, lanzar `ConflictException`
3. `reserveDocument(fileHash, importId, userId)` → si falla condicional, `ConflictException`
4. `timestamp = new Date().toISOString()`
5. `signature = HMAC(fileHash + importId + timestamp, secret)`
6. `writeToken(fileHash, importId, userId)`
7. Agregar los 4 headers al request HTTP a Kread
8. **Si Kread responde OK:** `confirmProcessed(fileHash)`
9. **Si Kread falla o timeout:** `releasePending(fileHash)` + propagar error

### Variables de entorno nuevas

| Variable | Descripción |
|---|---|
| `WALVY_KREAD_SHARED_SECRET` | Secret compartido. Guardar en AWS Secrets Manager |
| `DYNAMO_DEDUP_TABLE_NAME` | Tabla de deduplicación. Dev: `walvy-platform-v1-doc-dedup-dev` |
| `DYNAMO_KREAD_TOKENS_TABLE_NAME` | Tabla de tokens. Dev: `walvy-platform-v1-kread-tokens-dev` |
| `DYNAMO_TOKEN_TTL_SECONDS` | TTL del token en `kread-tokens`. Default: `600` |
| `DYNAMO_DEDUP_PENDING_TTL_SECONDS` | TTL de reservas `pending` en `doc-dedup`. Default: `900` |
| `AWS_REGION` | Región de las tablas. Dev: `us-east-2` |

### Permisos IAM para Walvy

**`doc-dedup`**
- `dynamodb:GetItem`
- `dynamodb:PutItem`
- `dynamodb:UpdateItem`
- `dynamodb:DeleteItem`

**`kread-tokens`**
- `dynamodb:PutItem`

---

## 8. Cambios en Kread

### Middleware de autenticación Walvy
Interceptar todos los requests de Walvy y ejecutar las 5 validaciones de la sección 6 contra **`kread-tokens` únicamente**.

### Variables de entorno nuevas

| Variable | Descripción |
|---|---|
| `WALVY_KREAD_SHARED_SECRET` | Mismo valor que Walvy |
| `DYNAMO_KREAD_TOKENS_TABLE_NAME` | Mismo nombre que Walvy. Dev: `walvy-platform-v1-kread-tokens-dev` |
| `AWS_REGION` | Misma región. Dev: `us-east-2` |
| `WALVY_TOKEN_TTL_MINUTES` | Ventana de aceptación. Default: `10` |

### Permisos IAM para Kread

**`kread-tokens` únicamente**
- `dynamodb:GetItem`
- `dynamodb:DeleteItem`

---

## 9. Manejo de errores

**Walvy → Frontend**
- `409` → "Este documento ya fue procesado anteriormente."
- `503` → "No se pudo iniciar el análisis. Inténtalo nuevamente."

**Kread → Walvy**
- `400` → Error de implementación en Walvy, no reintentar, alertar equipo
- `401` → Firma inválida o timestamp expirado, investigar desincronización de relojes
- `409` → Token no encontrado en `kread-tokens`, investigar posible race condition

**Limpieza en Walvy (fallo del upload)**
- Si Kread rechaza o hay timeout: `releasePending(fileHash)` libera la reserva en `doc-dedup`
- El token en `kread-tokens` expira solo (TTL 600s); no requiere limpieza activa por Walvy

---

## 10. Bootstrap del secreto compartido

1. Walvy genera: `node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"`
2. Walvy guarda en AWS Secrets Manager
3. Walvy entrega a Kread por canal seguro (1Password, Vault). **Nunca por email o Slack**
4. Kread guarda en su secrets manager
5. Ambos confirman con un request de prueba en sandbox
6. Rotación futura: ventana de gracia de 30 min con ambos secrets activos simultáneamente

---

## 11. Firmas

| Rol | Nombre | Firma | Fecha |
|---|---|---|---|
| Walvy Backend Lead | | | |
| Kread Lead | | | |
