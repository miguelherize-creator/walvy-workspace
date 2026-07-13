# Propuesta a Kread: soporte multi-documento en un solo endpoint

**Fecha:** 2026-07-10
**De:** Walvy (Miguel Herize)
**Para:** Equipo Kread
**Estado:** Propuesta — pendiente de validación con Kread
**Contexto interno:** extiende el contrato Kread v2.0.0 documentado en `context/specs/cartola-extraction.md`

---

## Resumen

Hoy Kread solo procesa cartolas de movimiento bancario (`GET /kartola/{job_id}/result` → `metadata` + `summary` + `transactions`). Walvy necesita sumar 3 tipos de documento nuevos:

1. Cartola de tarjeta de crédito
2. Informe de deuda consolidada de la CMF (Comisión para el Mercado Financiero)
3. Documento bancario genérico que no calce en ninguna categoría anterior

Kread propuso un **endpoint separado por tipo de documento**. Nuestra contrapropuesta: mantener un **único endpoint de ingesta** (`POST /kartolas-api/kartola`, sin cambios) y que Kread clasifique el tipo de documento igual que hoy clasifica el banco (`detected_bank` / `detection_confidence`).

## Por qué un solo endpoint

- El front ya sube archivos sin saber a qué banco pertenecen — pedirle que además sepa si es "cartola de banco" vs "cartola de tarjeta" vs "informe CMF" *antes* de subir es exactamente el trabajo que hoy delega en Kread. Kread ya resuelve un problema de clasificación (banco); esto es la misma clase de problema (tipo de documento), no uno nuevo.
- Hoy un usuario sube un lote mixto (hasta 15 archivos) en una sola operación. Con endpoints separados, el front tendría que pre-clasificar y trocear el batch antes de llamar a Kread — trabajo duplicado y una fuente más de error, justo lo que la ingesta dinámica (N archivos, un solo POST) vino a evitar.
- Es 100% aditivo sobre el contrato v2.0.0: no toca `POST /kartola` ni `GET /status`, y no cambia la arquitectura de Walvy (Lambda → Kread → callback).

## Contrato propuesto

### 1. Nuevo discriminador por archivo: `document_type`

En `GET /kartola/{job_id}/result`, cada elemento de `files[]` agrega dos campos:

```json
{
  "document_type": "credit_card_statement",
  "document_type_confidence": 0.94
}
```

Valores: `bank_statement` (el caso ya soportado hoy) · `credit_card_statement` · `cmf_report` · `other`.

Mismo patrón que ya usan para `detected_bank` / `detection_confidence` en el flujo de error — no es un concepto nuevo, es extender la clasificación que ya hacen a un eje adicional (tipo de documento, no solo banco).

### 2. Qué buckets vienen poblados según `document_type`

| `document_type` | `metadata` / `account_holder` | `summary` | `transactions` | `debts` |
|---|---|---|---|---|
| `bank_statement` | ✅ (sin cambios) | ✅ (sin cambios) | ✅ (sin cambios) | vacío |
| `credit_card_statement` | ✅ | vacío (no aplica "saldo de cuenta") | ✅ (movimientos de la tarjeta) | ✅ (1 elemento: la deuda de esa tarjeta) |
| `cmf_report` | ✅ (parcial — puede no traer `account_number`) | vacío | vacío (un informe CMF no lista movimientos) | ✅ (N elementos, uno por institución acreedora reportada) |
| `other` | según lo que se pueda leer | vacío | vacío | vacío |

`bank_statement` queda **idéntico** al contrato de hoy — cero breaking changes para lo que ya está en producción.

### 3. Nuevo array: `debts`

Reemplaza lo que en nuestro borrador inicial separaba `debt` y `CMR` en dos buckets — son el mismo concepto (una obligación de deuda). La única diferencia real es la cardinalidad: una cartola de tarjeta produce 1 elemento, un informe CMF produce N (uno por acreedor).

```json
"debts": [
  {
    "institution": "Banco Falabella",
    "product_type": "credit_card",
    "product_type_confidence": 0.91,
    "current_balance": 850000,
    "minimum_payment": 42000,
    "interest_rate_pct": 2.8,
    "installments_total": 12,
    "installments_remaining": 5,
    "due_day": 5,
    "next_due_date": "2026-07-05",
    "currency": "CLP"
  }
]
```

Ajustes vs. el borrador que circulamos primero, y el motivo de cada uno:

| Campo original | Campo propuesto | Motivo |
|---|---|---|
| `name: "Préstamo Pedro"` | `institution` | Kread extrae lo que lee del documento (el emisor/acreedor). Un label tipo "Préstamo Pedro" es algo que el usuario escribe en la app, no algo que un PDF contenga. Walvy arma el nombre final combinando `institution` + `product_type`. |
| `debtType: "prestamo_personal"` | `product_type` con enum cerrado `consumer \| mortgage \| credit_card \| line \| other` | Ese enum ya está definido en el schema de nuestro módulo de deudas (M4 — schema listo, en implementación). Si Kread manda valores libres, alguien tiene que mantener una tabla de traducción que se desincroniza con el tiempo. Preferimos que Kread emita directamente uno de estos 5 valores, con su propio `product_type_confidence` (mismo patrón que `category_confidence`). |
| *(no existía)* | `interest_rate_pct` | Sin tasa de interés no podemos correr la estrategia Avalanche (ordena las deudas por mayor tasa). Es un dato que normalmente está impreso en la cartola o el informe — pedimos que se extraiga si está disponible, `null` si no. |
| `nextDueDate` | `next_due_date` + `due_day` | Son dos cosas distintas en nuestro modelo: `next_due_date` es la próxima fecha puntual impresa en el documento; `due_day` es el día fijo del mes (1–31) cuando el documento lo indica explícitamente como pago recurrente. Si solo hay una fecha puntual, basta con `next_due_date` y `due_day: null`. |
| *(no existía)* | `currency` | Mismo patrón que ya usan en `metadata.currency`. |

### 4. `general` — reservado, sin implementar en v1

Confirmado con Kread: en v1 este array siempre viene vacío, no se construye extracción para `other` todavía. Lo dejamos documentado en el contrato para no tener que renegociarlo cuando se implemente a futuro:

```json
"general": []
```

Shape tentativo para cuando se active en una v2 (**no es parte de este requerimiento**, solo referencia para no cerrar puertas):

```json
{ "kind": "string", "fields": { "campo": "valor" }, "confidence": 0.0 }
```

## Ejemplo completo — archivo `cmf_report`

```json
{
  "filename": "informe_deuda_cmf.pdf",
  "error": null,
  "document_type": "cmf_report",
  "document_type_confidence": 0.97,
  "metadata": {
    "bank": null,
    "account_type": null,
    "account_number": null,
    "statement_number": null,
    "currency": "CLP",
    "issued_at": "2026-06-30",
    "extracted_at": "2026-07-10T10:00:00",
    "source_format": "pdf",
    "detection_confidence": 0.97
  },
  "account_holder": { "name": "Juan Pérez", "rut": "12.345.678-9", "email": null },
  "summary": null,
  "transactions": null,
  "debts": [
    {
      "institution": "Banco de Chile",
      "product_type": "credit_card",
      "product_type_confidence": 0.95,
      "current_balance": 620000,
      "minimum_payment": 31000,
      "interest_rate_pct": 3.1,
      "installments_total": null,
      "installments_remaining": null,
      "due_day": null,
      "next_due_date": null,
      "currency": "CLP"
    },
    {
      "institution": "CMR Falabella",
      "product_type": "consumer",
      "product_type_confidence": 0.88,
      "current_balance": 340000,
      "minimum_payment": 20000,
      "interest_rate_pct": 2.5,
      "installments_total": 24,
      "installments_remaining": 9,
      "due_day": null,
      "next_due_date": "2026-07-15",
      "currency": "CLP"
    }
  ],
  "general": []
}
```

## Ejemplo completo — archivo `credit_card_statement`

```json
{
  "filename": "cartola_visa_junio.pdf",
  "error": null,
  "document_type": "credit_card_statement",
  "document_type_confidence": 0.94,
  "metadata": {
    "bank": "Banco Santander",
    "account_type": "Tarjeta de Crédito Visa",
    "account_number": "4551********1234",
    "statement_number": "202406",
    "currency": "CLP",
    "issued_at": "2026-06-30",
    "extracted_at": "2026-07-10T10:00:00",
    "source_format": "pdf",
    "detection_confidence": 0.94
  },
  "account_holder": { "name": "Juan Pérez", "rut": "12.345.678-9", "email": null },
  "summary": null,
  "transactions": [
    {
      "id": 1,
      "global_id": "4551_202406_1",
      "date": "2026-06-05",
      "operation_number": "556677",
      "raw_description": "COMPRA FALABELLA RETAIL",
      "type": "cargo",
      "amount": 89000,
      "balance_after": null,
      "branch": null,
      "category": "Gastos Personales",
      "subcategory": "Ropa",
      "category_confidence": 0.85
    }
  ],
  "debts": [
    {
      "institution": "Banco Santander",
      "product_type": "credit_card",
      "product_type_confidence": 0.96,
      "current_balance": 410000,
      "minimum_payment": 22000,
      "interest_rate_pct": 3.4,
      "installments_total": null,
      "installments_remaining": null,
      "due_day": 20,
      "next_due_date": "2026-07-20",
      "currency": "CLP"
    }
  ],
  "general": []
}
```

## Preguntas abiertas para Kread

1. **`other` en v1 — ¿éxito con buckets vacíos, o error?** Nuestra recomendación: es un éxito (Kread sí leyó el archivo, solo que todavía no extrae estructura de él), no un `error` como `BANK_NOT_IDENTIFIED`. ¿Coinciden con este criterio?
2. **¿Nuevo código de error `DOCUMENT_TYPE_NOT_IDENTIFIED`?** Análogo a `BANK_NOT_IDENTIFIED`, para cuando ni siquiera se puede determinar si es cartola/tarjeta/CMF/otro (documento ilegible, por ejemplo).
3. **¿El mismo pipeline (Gemini + reglas deterministas) que ya usan para detectar banco sirve para clasificar `document_type`?** O necesita un modelo/prompt distinto — nos ayuda a estimar confianza esperada y tiempos de proceso.
4. **¿`product_type` como enum cerrado (`consumer|mortgage|credit_card|line|other`) es viable de su lado?** O prefieren mandar texto libre y Walvy hace el mapeo — es negociable si su clasificación no calza limpio en 5 categorías.
5. **Tamaño de batch:** ¿el mismo límite de 15 archivos / 100MB aplica igual mezclando tipos, o un informe CMF (típicamente más largo) necesita un límite distinto?

## Compatibilidad

100% aditivo. Ningún cliente que integra hoy contra `bank_statement` ve cambios — `document_type` y `debts` son campos nuevos, `general` siempre vacío en v1. No se toca `POST /kartola` ni `GET /status`.

## Próximos pasos

- [ ] Validar con Kread las 5 preguntas abiertas
- [ ] Kread confirma factibilidad y estimación de `document_type` + `debts`
- [ ] Walvy actualiza `KreadResult`/`KreadFileResult` en `back-walvy/src/imports/kread/kread.service.ts` cuando el contrato quede cerrado
- [ ] Extender `kread.mapper.ts` con el mapeo `debts` → modelo interno (M4, `back-walvy/src/debts/` — módulo aún no implementado)
- [ ] Coordinar con front-walvy el cambio de tipos en `expo/api/types/cartola.ts` (mismo patrón ya usado para `NormalizedLine`/`RawRow`)
