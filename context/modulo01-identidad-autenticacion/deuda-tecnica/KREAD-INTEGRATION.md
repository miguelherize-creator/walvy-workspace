# Kread Integration — Referencia técnica

Módulo: `statement-imports`  
Última actualización: 2026-07-04

---

## Estado actual

| Componente | Estado |
|------------|--------|
| Walvy — contrato v1.1 (4 headers + HMAC) | ✅ Implementado y probado |
| Walvy — deduplicación DynamoDB (`doc-dedup`) | ✅ Activa |
| Walvy — retención S3 para retry | ✅ Activa |
| Walvy — endpoints `/status` y `/retry` | ✅ Funcionando |
| Kread — `DYNAMO_TOKENS_TABLE` configurada | ❌ **PENDIENTE — causa 409** |

Walvy está lista. El único bloqueante es que Kread configure su tabla de tokens (ver sección [Lo que necesita Kread](#lo-que-necesita-kread)).

---

## Contrato de autenticación (v1.1 — activo)

Walvy envía 4 headers en cada upload a Kread:

| Header | Valor |
|--------|-------|
| `X-Walvy-FileHash` | SHA-256 hex del PDF (ya desbloqueado si tenía password) |
| `X-Walvy-ImportId` | UUID del registro en `statement_imports` |
| `X-Walvy-Timestamp` | ISO 8601 UTC del momento del upload |
| `X-Walvy-Signature` | `HMAC-SHA256(secret, fileHash + importId + timestamp)` |

El HMAC se calcula concatenando los tres valores **sin separadores**:
```
firma = HMAC-SHA256(WALVY_KREAD_SHARED_SECRET, fileHash + importId + timestamp)
```

Verificación manual:
```bash
python3 -c "
import hmac, hashlib
secret     = 'walvy-kread-dev-sandbox-only-not-for-prod-2026'
file_hash  = '<sha256-hex>'
import_id  = '<uuid>'
timestamp  = '<iso-utc>'
print(hmac.new(secret.encode(), (file_hash+import_id+timestamp).encode(), hashlib.sha256).hexdigest())
"
```

---

## Lo que necesita Kread

Para desbloquear el flujo completo, Kread debe configurar **3 cosas**:

### 1. Variable de entorno

```env
DYNAMO_TOKENS_TABLE=walvy-platform-v1-kread-tokens-dev
```

> El nombre exacto de la variable puede variar según el código de Kread (`DYNAMO_TOKENS_TABLE` o `DYNAMO_KREAD_TOKENS_TABLE_NAME`). El nombre de la tabla es el que importa.

### 2. Variables de entorno adicionales

```env
AWS_REGION=us-east-2
WALVY_KREAD_SHARED_SECRET=walvy-kread-dev-sandbox-only-not-for-prod-2026
WALVY_TOKEN_TTL_MINUTES=10
```

### 3. Permisos IAM

El rol de Kread necesita permisos sobre `walvy-platform-v1-kread-tokens-dev`:

```json
{
  "Effect": "Allow",
  "Action": [
    "dynamodb:GetItem",
    "dynamodb:DeleteItem"
  ],
  "Resource": "arn:aws:dynamodb:us-east-2:*:table/walvy-platform-v1-kread-tokens-dev"
}
```

### Cómo funciona el token (para Kread)

Cuando Kread recibe un upload de Walvy:

1. Lee `X-Walvy-FileHash` del request
2. Busca `GET walvy-platform-v1-kread-tokens-dev` donde `pk = "token#<fileHash>"`
3. Verifica que `importId` del item coincida con `X-Walvy-ImportId`
4. `DELETE` el item (token de uso único)
5. Continúa procesando el PDF

El item en la tabla tiene TTL de 600s como red de seguridad si Kread no lo lee.

---

## Variables de entorno — Walvy

| Variable | Valor dev | Estado |
|----------|-----------|--------|
| `KREAD_BASE_URL` | `https://ai.kabeli.cl/kread-kartolas` | ✅ |
| `WALVY_KREAD_SHARED_SECRET` | `walvy-kread-dev-sandbox-only-not-for-prod-2026` | ✅ |
| `DYNAMO_ENABLED` | `true` | ✅ |
| `AWS_REGION` | `us-east-2` | ✅ |
| `AWS_ACCESS_KEY_ID` | `AKIAZCEUDGDKE7HWJ6X4` | ✅ |
| `AWS_SECRET_ACCESS_KEY` | — | ✅ |
| `DYNAMO_DEDUP_TABLE_NAME` | `walvy-platform-v1-doc-dedup-dev` | ✅ |
| `DYNAMO_KREAD_TOKENS_TABLE_NAME` | `walvy-platform-v1-kread-tokens-dev` | ✅ |
| `DYNAMO_TOKEN_TTL_SECONDS` | `600` | ✅ |
| `DYNAMO_DEDUP_PENDING_TTL_SECONDS` | `900` | ✅ |
| `S3_BUCKET` | `walvy-platform-dev` | ✅ |

---

## Flujo completo

### Fase 1 — Recepción (síncrona, responde 201 inmediato)

```
1. POST /statement-imports/upload  (multipart PDF)

2. [opcional] Si pdfPassword → desbloquear con qpdf → 400 si contraseña incorrecta

3. SHA-256(buffer) → fileHash

4. DynamoDB GET doc-dedup  pk = "doc#{fileHash}"
   → status = "processed" → 409 (mismo PDF ya fue procesado)
   → no existe → continuar

5. INSERT statement_imports  status = "pending"

6. DynamoDB PUT doc-dedup
   pk = "doc#{fileHash}", status = "pending", TTL = now+900s
   ConditionExpression: attribute_not_exists(pk)
   → falla → race condition → 409

7. S3 uploadBuffer(fileKey, buffer)
   → falla → releasePending + status = "failed" + 500

8. Responder 201 { id, status: "pending" }
```

### Fase 2 — Procesamiento (asíncrona, fire-and-forget)

```
9.  UPDATE statement_imports  status = "processing"

10. timestamp = new Date().toISOString()

11. DynamoDB PUT kread-tokens
    pk = "token#{fileHash}", importId, userId, TTL = now+600s

12. POST /kartola  (Kread)
    Headers:
      X-Walvy-FileHash:  {fileHash}
      X-Walvy-ImportId:  {importId}
      X-Walvy-Timestamp: {timestamp}
      X-Walvy-Signature: HMAC-SHA256(secret, fileHash+importId+timestamp)
    Body: multipart/form-data  campo "archivos" = buffer PDF

    Kread valida:
      ① Headers presentes
      ② Timestamp < 10 min (no expirado)
      ③ HMAC válido
      ④ GET kread-tokens → importId coincide  ← BLOQUEADO ACÁ (tabla no configurada)
      ⑤ DELETE kread-tokens (uso único)
      ⑥ Procesa PDF → { job_id }

13. Polling GET /kartola/{job_id}/status
    Intervalo: 3s inicial, backoff x1.5 hasta cap 15s, timeout 4 min

14. GET /kartola/{job_id}/result → transactions[], metadata, summary

15. [Éxito]
    INSERT import_line_items (batches de 100)
    DynamoDB UPDATE doc-dedup → status = "processed", REMOVE ttl
    UPDATE statement_imports → status = "parsed", parsedAt = now
    S3 deleteObject(fileKey)  — el PDF ya no es necesario

    [Fallo]
    DynamoDB DELETE doc-dedup (si status = "pending")  — libera para reintento
    UPDATE statement_imports → status = "failed", errorMessage = [PREFIX] mensaje
```

### Fase 3 — Frontend detecta el resultado

```
16. Polling: GET /statement-imports/{id}/status
    Fase pre-modal  (0–15 s):  5 s fijo × 3 checks
    Fase post-modal (15 s–2 min): 10 s fijo
    Timeout UX: 2 min → modal "Tu cartola sigue en proceso" → home

    → pending | processing → continuar
    → parsed   → navegar a pantalla de resultados
    → failed   → mostrar errorMessage + botón "Reintentar"
    → cancelled → router.replace("/(auth)/onboarding-doc")

    Si el usuario pulsa "Reintentar":
      POST /statement-imports/{id}/retry
      → 200 { status: "pending" } → reanudar polling
      → 400 (archivo no en S3)   → router.replace("/(auth)/onboarding-doc")
```

---

## Máquina de estados

```
upload OK   ┌─────────────────────────────────┐
[inicio] ──►│ pending                          │
            └──────────────────┬──────────────┘
                     async     │
                         ┌─────▼──────┐
              DELETE /cancel          │
           ┌──────────────┤ processing │
           │              └─────┬──────┘
           ▼                    │
       cancelled           Kread termina
                      ┌─────────┴──────────┐
                    éxito               error
                      │                   │
                      ▼                   ▼
                   parsed              failed
                                         │
                              POST /retry│
                                    ┌────▼────┐
                                    │ pending │ (vuelve al ciclo)
                                    └─────────┘
```

---

## Tablas DynamoDB

### `walvy-platform-v1-doc-dedup-dev`

```json
{
  "pk":          "doc#<sha256-hex>",
  "importId":    "<uuid>",
  "userId":      "<uuid>",
  "status":      "pending | processed",
  "createdAt":   "ISO 8601",
  "processedAt": "ISO 8601",
  "ttl":         1751234567
}
```

- `pending` → TTL 900s (red de seguridad si Walvy crashea)
- `processed` → sin TTL (permanente — impide resubida del mismo archivo)

### `walvy-platform-v1-kread-tokens-dev`

```json
{
  "pk":        "token#<sha256-hex>",
  "importId":  "<uuid>",
  "userId":    "<uuid>",
  "createdAt": "ISO 8601",
  "ttl":       1751234567
}
```

- TTL 600s (Kread lo elimina al validarlo; TTL es red de seguridad)

---

## Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| `POST` | `/statement-imports/upload` | Subir cartola PDF — responde 201 con `status: "pending"` |
| `POST` | `/statement-imports/unlock-preview` | Desbloquear PDF protegido (validación previa, no procesa) |
| `GET` | `/statement-imports` | Listar imports del usuario |
| `GET` | `/statement-imports/:id/status` | **Polling** — solo `{ id, status, errorMessage, parsedAt }` |
| `POST` | `/statement-imports/:id/retry` | **Retry** — reintentar `failed` sin re-subir el archivo |
| `GET` | `/statement-imports/:id` | Detalle completo |
| `GET` | `/statement-imports/:id/lines` | Movimientos clasificados |
| `GET` | `/statement-imports/:id/lines/pending` | Movimientos pendientes de revisión |
| `PATCH` | `/statement-imports/:id/lines/:lineId/reclassify` | Reclasificar movimiento |
| `DELETE` | `/statement-imports/:id` | Cancelar import |

---

## Archivos clave

| Archivo | Responsabilidad |
|---------|-----------------|
| `kread/kread.service.ts` | HTTP a Kread, headers HMAC, polling con backoff |
| `kread/dynamo-dedup.service.ts` | Tabla `doc-dedup` — deduplicación |
| `kread/dynamo-token.service.ts` | Tabla `kread-tokens` — token efímero para Kread |
| `services/statement-import.service.ts` | Orquestación completa del flujo |
| `controllers/statement-import.controller.ts` | Endpoints REST |
| `storage/s3.service.ts` | Upload/download/delete de PDFs en S3 |

---

## Diagnóstico rápido

```bash
# Ver registros en doc-dedup
aws dynamodb scan \
  --table-name walvy-platform-v1-doc-dedup-dev \
  --region us-east-2

# Ver tokens pendientes (debería estar vacío entre requests)
aws dynamodb scan \
  --table-name walvy-platform-v1-kread-tokens-dev \
  --region us-east-2

# Verificar HMAC manualmente
python3 -c "
import hmac, hashlib
secret    = 'walvy-kread-dev-sandbox-only-not-for-prod-2026'
file_hash = '<hash>'
import_id = '<uuid>'
timestamp = '<iso>'
print(hmac.new(secret.encode(), (file_hash+import_id+timestamp).encode(), hashlib.sha256).hexdigest())
"

# Probar el endpoint de status directamente
curl <host>/statement-imports/<id>/status \
  -H 'Authorization: Bearer <token>'
```
