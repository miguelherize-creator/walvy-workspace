# Integración Onboarding — Cambios de backend

Última actualización: 2026-07-06
Para: equipo frontend (onboarding · import de cartola · primer diagnóstico)
Docs canónicas (backend): `back-walvy/docs/api/statement-imports/` y `back-walvy/docs/api/profile/`

---

## TL;DR de lo que cambió

1. **Flujo de cartola arreglado.** Se corrigió el `409 "Token inválido o expirado"` de Kread (era un header con mayúsculas; ahora va `x-walvy-file-hash` en minúsculas — **interno del backend, el front no cambia nada**). El flujo `upload → parsed` ya funciona de punta a punta.
2. **`/upload` ahora es síncrono en el submit.** Devuelve `status: "processing"` + `kreadJobId` de una. El polling/resultado sigue en background.
3. **Se consulta el estado con el `importId`, NUNCA con el `job_id` de Kread.** El `kreadJobId` es de uso interno del backend.
4. **`/summary` trae `detectedMonthlyIncome`** para pre-llenar el sueldo declarado.
5. **`PUT /profile/financial` acepta `incomeType`** (`fijo` | `variable`).
6. **Endpoint de reset para pruebas:** `POST /dev/reset-user` deja un usuario como recién registrado (borra cartolas + transacciones + deudas + Dynamo). Solo en dev.

---

## Resumen de endpoints

| Método | Ruta | Rol en onboarding |
|--------|------|-------------------|
| `POST` | `/statement-imports/upload` | Subir cartola PDF → inicia clasificación |
| `GET`  | `/statement-imports/:id/status` | Polling del estado (usar **importId**) |
| `GET`  | `/statement-imports/:id/summary` | Primer diagnóstico: semáforo + ingreso detectado |
| `GET`  | `/statement-imports/:id/lines` | Movimientos clasificados |
| `PUT`  | `/profile/financial` | Declarar sueldo líquido + tipo de ingreso |
| `GET`  | `/categories/with-subcategories` | Catálogo (para entrada manual / reclasificar) |
| `POST` | `/dev/reset-user` | **Solo dev** — reiniciar usuario para re-probar |

---

## 1. `POST /statement-imports/upload`

Sube el PDF e inicia el procesamiento. El submit a Kread es **síncrono**; el resultado llega por polling.

**Request** — `multipart/form-data`, `Authorization: Bearer <token>`

| Campo | Tipo | Req | Notas |
|-------|------|-----|-------|
| `file` | PDF | ✅ | Máx 10 MB, solo `application/pdf` |
| `pdfPassword` | string | ❌ | Si el PDF tiene clave |

**Response 201**
```json
{
  "id": "6075c187-561d-461d-bf96-661997a2f308",
  "status": "processing",
  "kreadJobId": "766655a5-9819-4f12-b11f-9bebcd1f7f08",
  "fileKey": "uploads/<userId>/<ts>_<archivo>.pdf",
  "originalFilename": "Cartola.pdf",
  "errorMessage": null,
  "parsedAt": null,
  "createdAt": "2026-07-06T21:11:41Z",
  "updatedAt": "2026-07-06T21:11:44Z"
}
```

- **Guardá `id` (= importId).** Es el que se usa en `/status`, `/summary`, `/lines`.
- `kreadJobId` es **informativo/interno** — no se manda en ninguna URL del backend.
- `status: "failed"` en el 201 significa que el submit a Kread falló (se puede `POST /:id/retry`).

**Errores:** `400` (sin archivo / PDF inválido / `[WRONG_PASSWORD]`), `401`, `409` (mismo PDF ya procesado — dedup por SHA-256).

---

## 2. `GET /statement-imports/:id/status`

Polling liviano. **Se consulta con el `importId`** (el `id` del upload), no con el `kreadJobId`.

**Response 200**
```json
{
  "id": "6075c187-...",
  "status": "processing",
  "kreadJobId": "766655a5-...",
  "errorMessage": null,
  "parsedAt": null,
  "kread": { "progress": 100, "message": "1 file(s) processed successfully.", "completed": true, "hasErrors": false }
}
```

| Campo | Notas |
|-------|-------|
| `status` | `pending` \| `processing` \| `parsed` \| `failed` \| `cancelled` |
| `kread` | Progreso **en vivo** de Kread mientras está en curso; `null` en estados terminales o si Kread no responde |
| `errorMessage` | Solo en `failed`; prefijado (`[SERVICE_ERROR]`, `[UNSUPPORTED_BANK]`, `[WRONG_PASSWORD]`, `[UNKNOWN_ERROR]`) |

Sondear hasta `parsed` / `failed` / `cancelled`. Estrategia de polling recomendada en `back-walvy/docs/api/statement-imports/get-status.md`.

**Errores:** `400` (id no UUID), `401`, `404` (no existe o no es del usuario → suele ser por mandar el `job_id` en vez del `importId`).

---

## 3. `GET /statement-imports/:id/summary`

Primer diagnóstico. Precondición: `status = "parsed"` (si no, `400`).

**Response 200**
```json
{
  "importId": "uuid",
  "transactionCount": 45,
  "periodStart": "2026-06-01",
  "periodEnd": "2026-06-30",
  "detectedMonthlyIncome": 1200000,
  "detected": {
    "hasIncome": true,
    "hasFixedExpenses": true,
    "hasRecurringPayments": true,
    "hasRecentMovements": true,
    "hasPaymentInstruments": true,
    "hasTransfers": false
  },
  "semaforo": { "light": "green", "totalIncome": 1500000, "totalExpense": 900000, "ratio": 0.6 }
}
```

- **`detectedMonthlyIncome`**: ingreso principal detectado (Σ de subcategorías `Sueldo`/`Honorarios`). Usar para **pre-llenar** el sueldo declarado — no es fuente de verdad, el usuario lo confirma.
- `semaforo.light`: `green` (<0.80), `yellow` (<1.0), `red` (≥1.0), según `gasto/ingreso`.
- Nota: hoy `hasFixedExpenses` y `hasRecurringPayments` comparten regla (`flowType = fixed`); pendiente diferenciarlos por negocio.

---

## 4. `GET /statement-imports/:id/lines`

Movimientos clasificados que quedaron guardados. Se consulta con el **importId**.
Cada línea trae `movementType` (`income`/`expense`), `flowType`, `amount`, `category`, `subcategory`, `description`, `occurredOn`.

---

## 5. `PUT /profile/financial`

Declarar sueldo líquido + tipo de ingreso (paso de perfil del onboarding).

**Request**
```json
{ "monthlyIncomeEstimate": 1200000, "incomeType": "fijo" }
```

| Campo | Tipo | Notas |
|-------|------|-------|
| `monthlyIncomeEstimate` | number | Sueldo líquido declarado |
| `incomeType` | `"fijo"` \| `"variable"` | **Nuevo.** Enum estricto (400 si otro valor) |

Devuelve el perfil actualizado. `GET /profile/financial` lo lee.

---

## 6. `GET /categories/with-subcategories`

Catálogo del cliente (público, sin token). Útil para entrada manual y reclasificación.

**Response 200** — 11 padres, 97 subcategorías
```json
[
  { "id": "uuid", "code": "EMPLEADOR", "name": "Empleador",
    "subcategories": [ { "id": "uuid", "code": "EMPLEADOR_SUELDO", "name": "Sueldo" }, ... ] }
]
```
Resolver los IDs por `code` (estable), no por posición ni nombre.

---

## 7. `POST /dev/reset-user` — solo pruebas

Reinicia un usuario para volver a correr el onboarding desde cero. **Requiere `DEV_TOOLS_ENABLED=true` en el backend (403 en prod).**

**Request**
```json
{ "email": "miguel.herize@kabeli.cl" }
```
(o `{ "userId": "..." }`)

**Qué hace:** onboarding → `not_started`, `email_verified_at → null`, borra cartolas (imports + líneas + sugerencias), transacciones, deudas y purga DynamoDB (dedup + tokens) por userId. **No borra al usuario.**

**Response 200**
```json
{
  "userId": "...", "email": "...",
  "onboardingReset": true, "emailVerificationCleared": true,
  "cartolas": { "importsBorrados": 2, "lineasBorradas": 670, "sugerenciasBorradas": 12, "dynamoDedupBorrados": 2, "dynamoTokensBorrados": 2 },
  "transaccionesBorradas": 3, "deudasBorradas": 1
}
```

Útil para testear onboarding repetido sin que el `409` de dedup bloquee re-subir la misma cartola.

---

## Notas clave para el front

- **importId vs kreadJobId:** el front solo conoce el **importId**. El `kreadJobId` vive dentro del backend.
- **Header casing de Kread:** fue un fix interno del backend; el front no toca nada.
- **Dedup:** la misma cartola (por contenido SHA-256) da `409`. Para re-probar, usar otra cartola o `POST /dev/reset-user`.
