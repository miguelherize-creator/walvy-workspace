# G4 Revisión / Suficiencia — resultado esperado por escenario de carga

**Fecha:** 2026-08-19
**Para:** PO / PMO · **De:** Kabeli (revisión de conformidad del onboarding, paso 5)
**Motivo:** Kread quedó funcional para estado de cuenta de tarjeta (TCR) e informe CMF. La regla del gate no cambia, pero cambia el **origen** de la evidencia, y ningún fixture del Assessment cubre las combinaciones.

**Fuentes:**
- Matriz de Trazabilidad Cliente v2.6 — `M1-V48`–`V52` (suficiencia), `M1-V56` (sin diagnóstico), export local en `specs/matriz-v2.6/variantes-m1.psv`.
- `M1-DP-008` / `AX-M1-003` — decisión de Producto cerrada registrada en `M1-V50`.
- Assessment M01 v1.1 — `M01-RGL-011`, `M01-RGL-012`, `M01-RGL-013`; fixtures `IND-*`; Matriz de admisión M01 (`ADM-01..07`, `EXC-01`).
- Propuesta multi-documento a Kread (`bitacora/propuesta-kread-multi-documento.md`), hoy implementada por Kread.

---

## 1. La regla que se aplica, sin cambios

`M01-RGL-012` es el **único gate de suficiencia**. Cada indicador conserva `detection_status`, `data_origin`, `confidence` y `evidence`, y **se normaliza primero** a `sufficient | pending | missing`; el gate evalúa después disponibilidad mínima y criticidad funcional.

| Situación | Salida del gate | Variante | Pantalla / CTA |
|---|---|---|---|
| Sin pendientes relevantes | `complete` | `M1-V48` | Base suficiente · «Comenzar diagnóstico» |
| Base mínima + sólo pendientes no críticos | `partial permitido` | `M1-V49` | Faltan datos por confirmar · CTA principal completar, secundario comenzar con esta base |
| Base mínima + pendiente crítico | `partial bloqueado` | `M1-V50` | Bloquear diagnóstico parcial hasta confirmar |
| Falta un elemento mínimo obligatorio | `blocked` | `M1-V51` | Aún faltan datos clave · completar/cargar más información |
| No hay documento usable | `blocked` | `M1-V52` | «Falta información para tu diagnóstico» · CTA «Cargar documentos» |

**Elementos mínimos obligatorios** (`V51`): documento usable · ingreso · movimientos recientes · base mínima de compromisos/pagos.

**Fronteras ya documentadas:**
- Movimientos recientes pendientes → **bloquean**.
- Pagos recurrentes pendientes → **pueden permitir parcial** cuando ingreso, movimientos y compromisos están suficientemente establecidos.
- Ausencia de instrumentos de pago → **no bloquea por sí sola** (fixture `IND-NO-INSTRUMENTS-01`).
- `M01-RGL-011`: un documento usable con base parcial o insuficiente **se conserva como avance** y no se reclasifica como no procesable.
- `M1-V56`: sin base suficiente **no se usa rojo por falta de información** — el diagnóstico va a «Sin diagnóstico», no a Riesgo.
- Cierre de `DP-008`: **no extrapolar combinaciones no cubiertas por reglas o fixtures.**

---

## 2. Qué puede aportar cada tipo de documento

| Tipo | metadata | summary | transactions | debts | Indicadores que puede alimentar |
|---|---|---|---|---|---|
| Cartola bancaria | ✅ | ✅ | ✅ | — | ingreso · movimientos · compromisos/recurrentes · instrumentos (cuenta) |
| Estado de cuenta TCR | ✅ | vacío | ✅ (movimientos de la tarjeta) | ✅ 1 | compromisos · instrumentos (la tarjeta) · deuda |
| Informe CMF | parcial | vacío | **vacío** | ✅ N | compromisos (deuda vigente por institución) · deuda |

Ningún tipo salvo la cartola puede aportar **ingreso**. Sólo la cartola y el TCR traen movimientos; el CMF no trae ninguno.

---

## 3. Cuadro de resultado esperado

`S` = sufficient · `P` = pending · `M` = missing · `?` = requiere decisión del PO (ver §5)

| # | Escenario | Ingreso | Movim. recientes | Compromisos / pagos | Instrumentos | Deuda | Salida del gate | Variante | Semáforo G5 |
|---|---|---|---|---|---|---|---|---|---|
| E1 | Cartola + TCR + CMF | S | S | S | S | 1 + N | **complete** | `V48` | Evaluable, sólo con líneas de la cartola (§4) |
| E2a | Solo cartola, con recurrentes | S | S | S | S/P | — | **complete** | `V48` | Evaluable |
| E2b | Solo cartola, sin recurrentes detectados | S | S | P | S/P | — | **partial permitido** | `V49` | Evaluable |
| E3 | Solo estado de cuenta TCR | **M** | ? | S | S | 1 | **blocked** — motivo `income_missing` | `V51` | No evaluable → «Sin diagnóstico» (`V56`) |
| E4 | Solo informe CMF | **M** | **M** | S | P | N | **blocked** — motivos `income_missing` + `recent_movements_missing` | `V51` | No evaluable → «Sin diagnóstico» (`V56`) |
| E5 | Cartola + TCR | S | S | S | S | 1 | **complete** | `V48` | Evaluable, sólo cartola (§4) |
| E6 | Cartola + CMF | S | S | S | P | N | **complete** | `V48` | Evaluable |
| E7 | TCR + CMF | **M** | ? | S | S | 1 + N | **blocked** — motivo `income_missing` | `V51` | No evaluable → «Sin diagnóstico» (`V56`) |
| E8 | Sin documentos | — | — | — | — | — | **blocked** | `V52` | No aplica |

**Lecturas del cuadro:**

1. **Ningún escenario sin cartola llega a diagnóstico.** E3, E4 y E7 bloquean por el mismo elemento mínimo: el ingreso. El bloqueo es correcto, pero el copy no puede ser el genérico de `V51`: el usuario subió un documento válido y hay que decirle exactamente qué falta.
2. **E4 no es `V52`.** Un informe CMF es documento usable, así que la pantalla debe reflejar avance conservado (`RGL-011`), no «no hay base documental».
3. **La deuda se registra siempre**, incluso cuando el gate bloquea: es insumo de M04 y `EXC-01` ya decía que el contenido TCR/CMF «se revalida en M04».
4. **Los instrumentos nunca cambian el resultado** — están en el cuadro sólo para trazabilidad.

---

## 4. Reglas de agregación que hacen falta (propuesta de Kabeli)

Con más de un tipo de documento, el resumen combinado necesita reglas que hoy no existen en ninguna fuente. Proponemos:

| # | Regla propuesta | Por qué |
|---|---|---|
| A1 | **Sólo la cartola alimenta el ratio ingreso/gasto** del semáforo. El TCR alimenta compromisos y deuda; el CMF sólo deuda. | Sin esto hay doble conteo: el pago de la tarjeta ya viene como cargo en la cartola, y el TCR agrega además cada compra individual. El ratio se infla y el diagnóstico se corre a Atención o Riesgo sin que la situación cambie. |
| A2 | **Deduplicación de deuda por institución + tipo de producto**, con precedencia CMF > TCR para monto vigente y TCR > CMF para detalle de movimientos. | La misma tarjeta llega por los dos documentos. Es el mismo criterio de `M1-DP-004`, pero aplicado a la deuda en vez del archivo. |
| A3 | **El abono de pago de la tarjeta no es ingreso.** En un TCR, los abonos reducen el saldo y no deben encender el indicador de ingreso. | Riesgo abierto: si se clasifican como `income`, E3 y E7 dejan de bloquear y el diagnóstico se arma sobre un ingreso inexistente. |
| A4 | **Cada indicador declara qué documento lo aportó** (`data_origin` + `evidence`). | Es lo que `M01-RGL-013` ya pide, y sin eso no se puede explicar «te falta ingreso» a quien subió sólo la tarjeta. |

---

## 5. Decisiones que faltan para poder validar

| # | Pregunta | Bloquea |
|---|---|---|
| Q1 | ¿Los movimientos de un estado de cuenta de tarjeta satisfacen el elemento mínimo «movimientos recientes», o ese elemento exige cartola bancaria? | E3, E7 (celdas `?`) |
| Q2 | ¿Un informe CMF satisface «base mínima de compromisos/pagos» sin ningún movimiento asociado? | E4, y la columna Compromisos de E7 |
| Q3 | ¿Se aprueban las reglas de agregación A1–A4? | E1, E5, E6 y todo el semáforo del batch |
| Q4 | ¿Copy propio para el bloqueo por tipo de documento? Ej.: «Ya registramos tus deudas; para tu diagnóstico necesitamos tu cartola». Hoy caería en el genérico de `V51`. | E3, E4, E7 |
| Q5 | `EXC-01` de la Matriz de admisión excluye TCR/CMF y quedó obsoleta. ¿Se reemplaza por controles `ADM` por tipo de documento, con admisión, procesamiento esperado y nodo de Figma? | Toda la ejecución de QA |
| Q6 | `V37`–`V43` y `V48`–`V52` no tienen variantes por tipo de documento. ¿Se agregan, o se documentan los ocho escenarios como fixtures del gate? | La trazabilidad de los ocho escenarios |

---

## 6. Fixtures que habría que materializar

Los que existen asumen un solo tipo de documento. Siguiendo la convención del Assessment, faltarían:

| Fixture propuesto | Escenario | Resultado esperado |
|---|---|---|
| `IND-MIX-FULL-01` | E1 | `complete`, ratio calculado sólo con la cartola, deuda deduplicada |
| `IND-CARD-ONLY-01` | E3 | `blocked` con motivo único `income_missing`, documento conservado, 1 deuda registrada |
| `IND-CMF-ONLY-01` | E4 | `blocked` con `income_missing` + `recent_movements_missing`, N deudas registradas |
| `IND-CARD-CMF-01` | E7 | `blocked` por ingreso, deuda deduplicada entre ambos |
| `IND-CARD-INCOME-TRAP-01` | E3 | El abono de pago de la tarjeta **no** enciende el indicador de ingreso (verifica A3) |

---

## 7. Brechas de nuestro lado, para no mezclarlas con lo anterior

Son cambios nuestros, no decisiones del PO:

1. El tipo `KreadFileResult` del backend es `{ metadata, summary, transactions }`: **no lee `document_type` ni `debts`**, así que hoy lo que Kread agregó se ignora en silencio.
2. Todo `detected.*` se deriva de las líneas de transacción: `hasRecentMovements` es «hay alguna línea» y `hasPaymentInstruments` es «hay algún gasto». No hay estado `pending` ni origen por indicador, así que la pantalla no puede distinguir `V49` de `V50`.
3. `hasFixedExpenses` y `hasRecurringPayments` comparten la misma regla (`flowType = fixed`), y la frontera de `DP-008` distingue compromisos de pagos recurrentes: con el contrato actual esa frontera no es evaluable.
4. El semáforo ya devuelve «no evaluable» cuando no hay ingreso o el mes no cierra — eso es coherente con `V56` y no hay que tocarlo.
