# Perfil financiero y pagos/consumos recurrentes — cómo se registra y cómo se lee

Última actualización: 2026-07-08
Estado: verificado contra código
Fuentes:
- `back-walvy/src/profile/` (perfil financiero)
- `back-walvy/src/imports/kread/kread.mapper.ts` (clasificación al importar cartola)
- `back-walvy/src/imports/services/statement-import.service.ts` (summary)

---

## Parte 1 — Perfil financiero (`/profile/financial`)

Relación **1:1 con el usuario**: la tabla `user_financial_profile` tiene `user_id` como PK, un usuario tiene a lo sumo **una** fila. El `userId` siempre sale del **JWT** (`user.sub`), nunca del body/URL → un usuario solo ve/edita **su** perfil.

### Cómo se LEE — `GET /profile/financial`

```
1. AuthGuard('jwt') → user.sub = userId
2. findByUserId(userId) → findOne({ where: { userId } })
3. Sin fila → 404 "El perfil financiero aún no ha sido completado"
4. Con fila → toResponse(profile) → 200
```

Response:
```json
{
  "userId": "uuid",
  "monthlyIncomeEstimate": 1200000,
  "incomeType": "fijo",
  "stableExpensesNote": null,
  "estimatedPaymentCapacity": null,
  "updatedAt": "2026-07-07T21:11:50.000Z"
}
```

| Campo | Tipo | Notas |
|-------|------|-------|
| `monthlyIncomeEstimate` | number \| null | Sueldo líquido declarado (transformer decimal→number) |
| `incomeType` | `"fijo"` \| `"variable"` \| null | Naturaleza del ingreso |
| `stableExpensesNote` | string \| null | Nota libre |
| `estimatedPaymentCapacity` | number \| null | Capacidad de pago estimada |
| `updatedAt` | ISO date | Última edición |

- **`currencyId` NO se expone** (`toResponse` lo omite; es detalle de DB).
- **`404` = estado esperado**, no error: el usuario aún no completó el paso. El front lo trata como "pendiente".

### Cómo se REGISTRA — `PUT /profile/financial` (upsert)

```json
{ "monthlyIncomeEstimate": 1200000, "incomeType": "fijo" }
```

- **Upsert:** crea la fila si no existe, si no la actualiza.
- **Parcial:** solo pisa los campos presentes (`if (dto.x !== undefined)`).
- **Moneda:** el front manda código ISO (`"CLP"`); el backend lo mapea a `currency_id` interno (400 si la moneda no existe). Al **crear** sin moneda → default **CLP**.
- `incomeType` valida contra enum estricto (`fijo` | `variable`) → 400 si otro valor.

---

## Parte 2 — Pagos / consumos recurrentes

"Recurrente/fijo" **no es una tabla ni un campo declarado por el usuario**: es un atributo derivado de cada movimiento, `flowType = 'fixed'`, que se calcula al **importar la cartola** (en el mapper de Kread) y queda guardado en `import_line_items.normalized`.

### Cómo se REGISTRA — clasificación en `resolveFlowType(tx)`

Se decide **por línea**, al mapear el resultado de Kread:

```
1. tx.type === 'abono'                          → 'income'    (ingreso, nunca recurrente)
2. subcategory EMPIEZA con "Servicios - "       → 'fixed'
3. subcategory ∈ FIXED_SUBCATEGORIES            → 'fixed'
4. resto                                         → 'variable'
```

Un movimiento es **recurrente/fijo** solo si es **egreso** (`cargo`/`giro`) y su `subcategory` cae en uno de dos grupos:

**Grupo A — Servicios del hogar (prefijo `"Servicios - "`)**
Arriendo, Luz, Agua, Internet, Gas, Netflix, GGCC, etc.
> Match por **prefijo exacto**. `"Servipag"` (sin `- `) NO entra.

**Grupo B — `FIXED_SUBCATEGORIES` (match exacto)**
```
Crédito de Consumo · Hipotecario · Tarjeta de Crédito · Pago TC ·
Prestamos · Automotriz · Linea de Crédito ·
Seguros · Seguro auto · Imposiciones · Telefono
```

**NO son recurrentes (→ variable):** supermercado, restaurantes, entretenimiento, retail, efectivo, y — dentro de `Créditos` — se excluyen a propósito `Nota de crédito`, `Intereses`, `Educación`, `Impuesto`.

> Entrada manual: `POST /transactions` acepta `flowType` directamente en el body, así que un movimiento creado a mano puede marcarse `fixed` sin pasar por esta heurística.

### Cómo se LEE — flags en `GET /statement-imports/:id/summary`

Al recorrer las líneas, si un **egreso** tiene `flowType === 'fixed'` se prenden **ambos** flags (hoy comparten regla, pendiente diferenciarlos por negocio):

```json
"detected": {
  "hasFixedExpenses": true,
  "hasRecurringPayments": true
}
```

El detalle línea a línea (con su `flowType`, `category`, `subcategory`) se obtiene en `GET /statement-imports/:id/lines`.

---

## ⚠️ Fragilidad a recordar

- La clasificación fija depende del **string `subcategory` que emite Kread**, con match **exacto y case-sensitive** (sin lowercase ni sin-acentos). `"Teléfono"` ≠ `"Telefono"` → cae como `variable`.
- Requiere que la taxonomía de Kread use **exactamente** los nombres del catálogo del cliente (`seeds.sql`). Cualquier desalineación de nombres degrada la clasificación **en silencio**.
- Si egresos que "deberían" ser recurrentes aparecen como variables → casi seguro es un nombre de subcategoría que no matchea al pie de la letra. Verificar con un query a `import_line_items`.
