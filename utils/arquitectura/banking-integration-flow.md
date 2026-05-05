# Flujo de Integración Bancaria — Degradación Controlada

> Versión: 2026-04-26  
> Garantía técnica: fallas bancarias nunca comprometen la estabilidad del core.

---

## Flujo normal vs. degradado

```mermaid
sequenceDiagram
    actor U as Usuario
    participant App  as Walvy App
    participant Core as NestJS Core API
    participant DB   as RDS PostgreSQL
    participant SQS  as SQS bank-sync-queue
    participant L    as Lambda Bank Sync / Flow
    participant DLQ  as SQS DLQ
    participant Bank as API Bancaria / Flow.cl
    participant CW   as CloudWatch

    rect rgb(220, 240, 220)
        Note over U,CW: ✅ FLUJO NORMAL — banco disponible

        U  ->>  App:  Abre balance / movimientos
        App ->> Core: GET /cashflow/summary
        Core ->> DB:  SELECT data WHERE user_id = X
        DB -->> Core: { transactions, last_sync_at, sync_status: "synced" }
        Core ->> SQS: ENQUEUE { userId, bankId, type: "balance_sync" }
        Core -->> App: { data, syncStatus: "synced", lastSyncAt }
        App -->> U:   Muestra datos actualizados ✅

        SQS  ->> L:   Consume mensaje
        L    ->> Bank: GET /accounts/{id}/movements
        Bank -->> L:  [ { id, amount, date, description } ]
        L    ->> DB:  UPDATE transactions + last_sync_at = NOW()
        L    ->> CW:  INFO bank_sync_success { userId, duration, count }
    end

    rect rgb(255, 235, 235)
        Note over U,CW: ⚠️ FLUJO DEGRADADO — banco no disponible

        U  ->>  App:  Abre balance / movimientos
        App ->> Core: GET /cashflow/summary
        Core ->> DB:  SELECT data WHERE user_id = X
        DB -->> Core: { transactions, last_sync_at: "hace 2h", sync_status: "pending" }
        Core ->> SQS: ENQUEUE { userId, bankId, type: "balance_sync", attempt: 1 }
        Core -->> App: { data, syncStatus: "pending", lastSyncAt: "hace 2h" }
        App -->> U:   Última info sincronizada ⚠️\n+ banner "Sincronización pendiente"

        SQS  ->> L:   Consume mensaje (intento 1)
        L    ->> Bank: GET /accounts/{id}/movements
        Bank --x L:   ❌ Timeout / HTTP 503

        L    ->> DB:  UPDATE sync_status = "pending", last_error = "timeout"
        L    ->> CW:  ERROR bank_sync_failed { userId, error, attempt: 1 }

        Note over SQS,L: SQS reintenta automáticamente (max 3 intentos, backoff)

        SQS  ->> L:   Consume mensaje (intento 3 — último)
        L    ->> Bank: GET /accounts/{id}/movements
        Bank --x L:   ❌ Sigue sin responder

        L    ->> DLQ: NACK → mensaje a DLQ
        L    ->> CW:  ERROR bank_sync_exhausted { userId, attempts: 3 }
        DLQ  ->> CW:  ALARM DLQ.ApproximateNumberOfMessagesVisible > 0
    end

    rect rgb(235, 235, 255)
        Note over U,CW: 🔄 RECUPERACIÓN — banco vuelve a estar disponible

        Note over SQS,L: Job programado (EventBridge cada 15 min)\nreencola usuarios con sync_status = "pending"

        SQS  ->> L:   Consume mensaje reencola
        L    ->> Bank: GET /accounts/{id}/movements
        Bank -->> L:  movimientos actualizados
        L    ->> DB:  UPDATE transactions + sync_status = "synced" + last_sync_at = NOW()
        L    ->> CW:  INFO bank_sync_recovered { userId }

        U  ->>  App:  Abre balance
        App ->> Core: GET /cashflow/summary
        Core ->> DB:  SELECT data
        DB -->> Core: { sync_status: "synced", lastSyncAt: NOW() }
        Core -->> App: datos frescos
        App -->> U:   Datos actualizados, banner desaparece ✅
    end
```

---

## Contrato de degradación

### Estado `sync_status` en base de datos

| Estado | Significado | UX en App |
|---|---|---|
| `synced` | Datos actualizados | Muestra datos sin aviso |
| `pending` | Sincronización en cola o en curso | Banner amarillo: "Actualizando..." |
| `failed` | Reintentos agotados, en DLQ | Banner rojo: "Sincronización pendiente. Última actualización: hace X" |

### Comportamiento del Core API ante falla bancaria

```
GET /cashflow/summary

→ SIEMPRE responde con los datos que tiene en DB (nunca espera al banco)
→ sync_status refleja el estado real de la última sincronización
→ El Core encola una tarea de sincronización en background (fire-and-forget)
→ Si el banco está caído, el usuario ve su última info válida + aviso
→ El Core nunca llama directamente al banco — solo a través de SQS + Lambda
```

### Registro y auditoría

Todo evento de sincronización queda en CloudWatch Logs con estructura JSON:

```json
{
  "level": "ERROR",
  "event": "bank_sync_failed",
  "userId": "uuid",
  "bankId": "banco_estado",
  "attempt": 3,
  "error": "ConnectTimeoutError: 8000ms",
  "timestamp": "2026-04-26T21:00:00Z"
}
```

Alarmas configuradas en CloudWatch:
- `DLQ.ApproximateNumberOfMessagesVisible > 0` → SNS alerta a ops
- `bank_sync_failed` rate > 10/min → posible outage bancario
- `bank_sync_exhausted` por usuario → auditoría manual

---

## Garantías técnicas cumplidas

| Garantía | Cómo se cumple |
|---|---|
| Fallas bancarias no comprometen el Core | Core no llama bancos directamente; usa SQS (async) |
| Sin bloqueo por latencia externa | Las Lambdas corren fuera del ciclo request/response del Core |
| Degradación controlada con última info | Core siempre lee de DB, nunca espera respuesta bancaria |
| Logs y auditoría de errores | CloudWatch Logs estructurado + DLQ + Alarms |
| Recuperación automática | EventBridge reencola pendientes cada 15 min |
