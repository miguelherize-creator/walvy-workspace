# Contrato de Integración — Walvy ↔ Kread
**Mecanismo de Autenticación y Deduplicación de Documentos**

| | |
|---|---|
| Versión | 1.0 |
| Fecha | 2026-06-23 |
| Estado | Borrador para revisión |
| Clasificación | Confidencial |

---

## 1. Contexto

Walvy permite subir cartolas bancarias (PDF, Excel, CSV) que Kread procesa. Hoy el endpoint `POST /statement-imports/upload` reenvía el archivo a Kread sin autenticación ni deduplicación.

Este documento define los cambios para:
1. **Autenticar** que el request proviene de Walvy (no de terceros)
2. **Detectar documentos duplicados** antes de procesarlos
3. **Limitar la validez** de cada request en el tiempo (ventana de 10 minutos)

---

## 2. Flujo

```
Walvy Backend                      DynamoDB              Kread
      │                                │                    │
  Recibe archivo                       │                    │
  fileHash = SHA256(bytes)             │                    │
      │                                │                    │
  GET pk="walvy#{fileHash}" ──────────►│                    │
  ← existe? → 409 Duplicado ──────────│                    │
      │                                │                    │
  token = HMAC(fh+importId+ts, secret) │                    │
  PUT { pk, importId, userId, ttl } ──►│                    │
      │                                │                    │
  POST archivo ─────────────────────────────────────────────►
  X-Walvy-Signature: <token>           │                    │
  X-Walvy-FileHash:  <hash>            │         ① Verifica HMAC
  X-Walvy-ImportId:  <uuid>            │         ② Timestamp < 10min
  X-Walvy-Timestamp: <iso>             │         ③ GET fileHash en DynamoDB
                                       │◄────────④ DELETE fileHash
                                                  ⑤ Procesa documento
```

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

```json
{
  "pk":        "walvy#<sha256-del-archivo>",
  "importId":  "<uuid>",
  "userId":    "<uuid>",
  "createdAt": "2026-06-23T15:30:00.000Z",
  "ttl":       1751234567
}
```

- PK con prefijo `walvy#` para multitenancy futuro
- TTL = `now + 600s` (10 minutos)
- Kread **elimina el item** tras validarlo (uso único)
- Si Kread no elimina, DynamoDB lo purga al vencer el TTL

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

| # | Validación | Falla si… | Error |
|---|---|---|---|
| 1 | Headers presentes | Alguno de los 4 falta o está vacío | `400` |
| 2 | Timestamp válido | `now − timestamp > 10 min` | `401` |
| 3 | Firma HMAC válida | Recomponer y comparar en **tiempo constante** | `401` |
| 4 | Registro en DynamoDB | No existe o `importId` no coincide | `409` |
| 5 | Eliminar registro | Ejecutar DELETE (si falla, continuar igual) | — |

---

## 7. Cambios en Walvy Backend

### Nuevo: `DynamoTokenService`
- `checkDuplicate(fileHash): Promise<boolean>` — GET en DynamoDB
- `writeToken(fileHash, importId, userId): Promise<void>` — PUT con TTL

### Cambios en `StatementImportsService.upload()`
1. `fileHash = sha256(buffer)`
2. `checkDuplicate(fileHash)` → si true, lanzar `ConflictException`
3. `timestamp = new Date().toISOString()`
4. `signature = HMAC(fileHash + importId + timestamp, secret)`
5. `writeToken(fileHash, importId, userId)`
6. Agregar los 4 headers al request HTTP a Kread

### Variables de entorno nuevas
| Variable | Descripción |
|---|---|
| `WALVY_KREAD_SHARED_SECRET` | Secret compartido. Guardar en AWS Secrets Manager |
| `DYNAMO_TABLE_NAME` | Nombre de la tabla (confirmar con DevOps) |
| `DYNAMO_TOKEN_TTL_SECONDS` | TTL en segundos. Default: `600` |
| `AWS_REGION` | Región de la tabla |

---

## 8. Cambios en Kread

### Middleware de autenticación Walvy
Interceptar todos los requests de Walvy y ejecutar las 5 validaciones de la sección 6.

### Variables de entorno nuevas
| Variable | Descripción |
|---|---|
| `WALVY_KREAD_SHARED_SECRET` | Mismo valor que Walvy |
| `DYNAMO_TABLE_NAME` | Mismo nombre de tabla |
| `AWS_REGION` | Misma región |
| `WALVY_TOKEN_TTL_MINUTES` | Ventana de aceptación. Default: `10` |

### Permisos IAM para Kread
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
- `409` → Duplicado o token no encontrado, investigar posible race condition

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
