# Flujo de un documento: carga → Kread → G4 → G5

Qué hace el código **hoy** cuando alguien sube un archivo (el mismo pipeline que inspecciona `GET /dev/qa`). Contrasta la wiki por puerta y los HTML de PM (`requerimientos_PM/`), pero la numeración canónica es esta carpeta: **G3 = análisis, G4 = suficiencia, G5 = diagnóstico**.

Fuentes de código: `statement-import.service.ts`, `statement-file-type.ts`, `kread.mapper.ts`, `kread-flow-type.ts`, `semaforo-g5.ts`, `sufficiency-gate.rule.ts`.

---

## 1. Carga y validación (G2 → G3)

El front acepta PDF / XLSX / CSV, tope **30 MB**. El backend no confía en el `Content-Type` del cliente: decide el tipo por **contenido**.

```mermaid
flowchart TD
  U["Usuario elige archivo"] --> SIZE{"¿≤ 30 MB?"}
  SIZE -- no --> E1["400 · archivo demasiado grande"]
  SIZE -- sí --> SNIFF{"Firma del buffer<br/>detectStatementMimeType"}

  SNIFF -- "%PDF en 1024 B" --> PDF["mime = application/pdf"]
  SNIFF -- "ZIP + carpeta xl/" --> XLSX["mime = xlsx"]
  SNIFF -- "ZIP sin xl/" --> E2["400 · no es PDF/XLSX/CSV"]
  SNIFF -- "texto plano sin NUL" --> CSV["mime = text/csv"]
  SNIFF -- "binario desconocido" --> E2

  PDF --> PWD{"¿PDF con clave?"}
  PWD -- "check-password / qpdf" --> ASK["Pedir contraseña<br/>nunca en logs ni params"]
  ASK --> UNLOCK{"qpdf abre?"}
  UNLOCK -- no --> E3["wrong_password · volver a G2"]
  UNLOCK -- sí --> HASH
  PWD -- sin clave --> HASH["SHA-256 del buffer<br/>ya desbloqueado"]
  XLSX --> HASH
  CSV --> HASH

  HASH --> DEDUP{"Dynamo userId + fileHash"}
  DEDUP -- "ya parsed" --> REUSE["200 reused=true<br/>mismo importId · no Kread"]
  DEDUP -- "markRejected permanente" --> FAIL0["failed · mismo motivo<br/>sin reenviar a Kread"]
  DEDUP -- nuevo --> BG["Reserva pending TTL 900s<br/>S3 no-store · POST Kread<br/>HTTP /upload ya devolvió importId"]
```

| Formato | Qué se valida | Qué no corre |
|---|---|---|
| **PDF** | Firma `%PDF`, tamaño, qpdf si hay clave, hash **post-unlock** | XLSX/CSV no pasan por qpdf aunque alguien mande `pdfPassword` |
| **XLSX** | Magic ZIP `PK` **y** entrada `xl/` (un `.zip` o `.docx` se rechaza) | Contraseña PDF |
| **CSV** | Texto (sin NUL, pocos bytes de control). Windows a veces declara `ms-excel`: se ignora el header | Contraseña PDF |

Tras `/upload` el front polea `GET /statement-imports/:id/status`. El trabajo pesado (S3 + Kread) va en background.

---

## 2. Vuelta de Kread: tres buckets

Kread `POST /process-document` → poll `/status` → `GET /result` (Kread **borra** el result al leerlo; Walvy lo copia a `kread_result`).

```mermaid
flowchart TD
  JOB["waitForCompletion"] --> RES{"GET /result"}
  RES -- "422 / 400 / 415" --> REJ["KREAD_REJECTED<br/>persiste envelope en kread_result<br/>unsupported_files + group_errors"]
  REJ --> NP["failed · non_processable<br/>NOT_USEFUL_DOCUMENT<br/>NO bloquea hash 30 días"]
  RES -- "404 / 5xx / red" --> TR["failed · transient<br/>S3 se conserva · /retry permitido"]
  RES -- 200 --> BUCKET{"¿En qué bucket cayó el archivo?"}

  BUCKET -- "cartolas.files[0]" --> CART["document_kind = cartola"]
  BUCKET -- "estado_cuenta.files[0]" --> EECC["document_kind = estado_cuenta"]
  BUCKET -- "cmf_deuda.files[0]" --> CMF["document_kind = cmf_deuda"]
  BUCKET -- "ninguno / files vacíos" --> EMPTY["DOCUMENTO_SIN_DATOS_USABLES<br/>non_processable"]

  CART --> LINES{"¿Hay transacciones?"}
  LINES -- 0 --> EMPTY
  LINES -- sí --> MAP["mapKreadFile → import_line_items"]
  MAP --> AGE{"R5 vigencia: periodEnd vs 90 días"}
  AGE -- current --> OKC["parsed · líneas + holder_match"]
  AGE -- outdated --> OUT["failed · outdated"]
  AGE -- sin fecha --> UNV["failed · non_processable<br/>PERIODO_NO_VERIFICABLE"]

  EECC --> DEBT1["1 deuda unconfirmed"]
  CMF --> DEBTN["N deudas unconfirmed"]
  DEBT1 --> OKD["parsed · sin líneas de movimiento"]
  DEBTN --> OKD
```

**Qué mapea una cartola** (`NormalizedLine`):

| Campo | Origen |
|---|---|
| `occurredOn`, `amount`, `description` | transacción Kread |
| `movementType` | `abono` → `income`; `cargo`/`giro` → `expense` |
| `flowType` | ver §3 — **no** es el sentido entra/sale |
| `category` / `subcategory` | taxonomía Kread M5 v2.7 (tal cual) |
| `isTransfer` | la glosa contiene el RUT del titular → se excluye del ratio G5 |
| `classificationStatus` | `category_confidence ≥ 0.7` → `categorized`; si no `pending_review` |

Estado de cuenta e informe CMF **no** generan `import_line_items`. Crean filas `debts` (`unconfirmed`). G4 las cuenta como avance (`documentsIncluded`), no como movimientos del mes.

---

## 3. `flowType` y categorías (qué es “fijo”)

`movementType` = entra o sale. `flowType` = naturaleza del flujo.

```mermaid
flowchart TD
  TX["Transacción Kread"] --> T{"type?"}
  T -- abono --> INC["flowType = income"]
  T -- cargo o giro --> CAT{"¿categoría v2.7 periódica?"}
  CAT -- "Servicios básicos / Suscripciones y software / Seguros / Deudas y créditos" --> FIX["flowType = fixed"]
  CAT -- no --> SUB{"¿subcategoría periódica?"}
  SUB -- "Arriendo, GGCC, Dividendo, Isapre/Fonasa, imposiciones, contribuciones, colegio, universidad" --> FIX
  SUB -- "Servicios - *  o legado 2023 (Netflix, Teléfono, TC…)" --> FIX
  SUB -- resto --> VAR["flowType = variable"]
```

Ejemplos **variable** (no pintan `hasFixedExpenses`): supermercado, bencina, farmacia, transferencias, ATM.

`hasFixedExpenses` y `hasRecurringPayments` en el summary **comparten la misma regla** (`flowType === fixed`) hasta que Producto los separe.

Ingreso principal para prellenar sueldo: subcategorías **Sueldo** y **Honorarios** (no Bono ni Aguinaldos).

---

## 4. G4 — ¿hay base para diagnosticar?

G4 corre en `GET /statement-imports/summary-batch` (`evaluateSufficiencyGate`). Vocabulario persistido: `sufficient | partial | insufficient | blocked` (más angosto que los 5 nombres de Fase 3).

```mermaid
flowchart TD
  DOC{"¿Hay al menos un import parsed?"}
  DOC -- no, y hubo failed no usable --> B1["blocked · documento_no_procesable"]
  DOC -- no, sin carga --> B2["blocked · sin_documento"]
  DOC -- sí --> ING{"ingreso_principal usable?"}
  ING -- no_detectado --> B3["insufficient · ingreso_faltante"]
  ING -- desactualizado --> B4["insufficient · confianza_insuficiente"]
  ING -- sí --> MOV{"movimientos_recientes usable?"}
  MOV -- no --> B5["insufficient · movimientos_faltantes"]
  MOV -- sí --> PAR{"¿compromisos_base O pagos_recurrentes?"}
  PAR -- los dos no_detectado --> B6["insufficient · pagos_compromisos_insuficientes"]
  PAR -- al menos uno --> FULL{"¿todos detectado<br/>sin pendiente en el par<br/>confianza no insuficiente?"}
  FULL -- sí --> SUF["sufficient · diagnóstico completo"]
  FULL -- no --> PART["partial · parcial permitido"]
```

- `instrumentos_pago` **nunca bloquea**.
- `insufficient` / `blocked` en G5 se fuerzan a `no_diagnosis` (no rojo).
- `partial` **sí** deja pasar a G5 (cards de Figma si el mes cierra).

---

## 5. G5 — semáforo (lo que pinta `/dev/qa`)

Figma tiene **3 cards**. El API tiene **4 valores**. `no_diagnosis` no es una cuarta luz.

Orden en `finalizeG5Semaforo`:

1. Ratio del **mes cerrado** (M1-DP-006).
2. Mora confirmada solo **sube** `in_control` / `attention` → `risk` (no pisa `no_diagnosis`).
3. Suficiencia `insufficient`/`blocked` → `no_diagnosis`.
4. Si quedó `no_diagnosis` pero G4 ya pasó: CTA `no_dominant_cta` (no decir “en control”).

```mermaid
flowchart TD
  L["Líneas del batch · se ignoran isTransfer"] --> WIN{"Ventana de mes cerrado M1-V56"}
  WIN -- "sin día 1 o sin último día<br/>y sin mes anterior que cierre" --> ND1["no_diagnosis"]
  WIN -- mes evaluable --> INC2{"totalIncome > 0?"}
  INC2 -- no --> ND1
  INC2 -- sí --> R{"ratio = egreso / ingreso"}
  R -- "< 0.90" --> G["in_control · En control"]
  R -- "0.90 – 0.999…" --> Y["attention · Atención"]
  R -- "≥ 1.00" --> RD["risk · Riesgo"]

  G --> MORA{"¿mora_confirmada?<br/>deuda confirmed + vencida + saldo"}
  Y --> MORA
  RD --> SKIP["ya es risk · no consulta deudas"]
  ND1 --> NOMORA["mora no convierte esto en rojo"]
  MORA -- sí --> RD
  MORA -- no --> COL["color del ratio"]

  COL --> G4{"sufficiency insufficient o blocked?"}
  RD --> G4
  ND1 --> G4
  G4 -- sí --> ND2["no_diagnosis · CTA cargar/completar"]
  G4 -- no --> OUT["light + generalTrafficLightStatus<br/>nunca null"]
```

**Mes cerrado** (ambos bordes, con `occurredOn` reales, no el título del PDF ni `kread.period`):

- Fin: `maxDate` es el último día calendario de ese mes, **o** existe un mes posterior con datos (entonces el anterior cerró al final).
- Inicio: `minDate` global ≤ `YYYY-MM-01` del mes elegido.
- Si el mes vigente no cumple, se intenta **solo** el mes anterior. Si tampoco, `no_diagnosis`.

Por eso una cartola 3–28 jul o 7–31 jul (falta el 1) no pinta color aunque G4 esté en *Base suficiente*.

| Color | Condición en código |
|---|---|
| Verde `in_control` | Mes cerrado + ingreso > 0 + ratio < 0.90 + G4 no bloquea + sin mora que suba |
| Amarillo `attention` | Igual, ratio ∈ [0.90, 1.00) |
| Rojo `risk` | Ratio ≥ 1.00 **o** mora confirmada sobre un color ya evaluable |
| Sin diagnóstico `no_diagnosis` | Mes no cerrado, sin ingreso en la ventana, G4 insuficiente/bloqueado, o Kread sin datos usables. **Nunca** por “faltan datos” se pinta rojo |

---

## 6. Cómo se ve en `/dev/qa`

El panel llama, en orden: login → `users/me` + onboarding → lista de imports → `summary-batch` (G5 + G4) → `kread-result` + `/lines` del archivo seleccionado → deudas.

El recuadro amarillo de “mes no evaluable” replica la regla M1-V56 sobre las fechas de las líneas, no sobre el período que Kread puso en el PDF.
