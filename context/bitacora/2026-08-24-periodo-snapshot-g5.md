# RN propuestas — Período temporal del diagnóstico G5

**Fecha:** 2026-08-24  
**Estado:** **Cerrado funcionalmente por PM.** Pendiente de aprobación explícita del cliente para quedar como RN vigente de M1. `summary.period` como fuente gobernante de G5 es consistente con la doc (período documental ≠ fechas de movimientos) pero **no está escrito hoy** como regla aprobada.

**Origen:** contrastación documental PM + propuesta Desarrollo (Kread `summary.period`) + dos ajustes PM (ingreso atribuible, batch multi-documento).

**Fuentes:** M1-RN-ONB-004/006/010, M1-V56, modelo estado de cuenta (`statement_date`, `billing_period_from`/`to` vs `date` del movimiento), extracción Kread `summary.period`.

---

## Orden lógico (no es una puerta nueva)

G4 y G5 consumen **la misma** referencia temporal. El período se resuelve **antes** de cerrar suficiencia, para no repetir `G4 = suficiente` → G5 descubre que falta ingreso → `no_diagnosis`.

```text
Documento procesado
        ↓
Resolver período documental (summary.period)
        ↓
G3  calidad / vigencia / evidencia
        ↓
G4  ¿ingreso, movimientos y base crítica son utilizables para ese período?
        ↓
Sí → G5 calcula el semáforo sobre esa ventana
No → ingreso_faltante / blocked / no_diagnosis
```

---

## RN-G5-PER-001 – Período temporal del diagnóstico

Para documentos que declaren un período financiero válido, el período de evaluación de G5 será el informado por el documento y normalizado por Kread (`period.start_date` – `period.end_date`). **No** se infiere desde min/max de movimientos. **No** está obligado a coincidir con el primer y último día de un mes calendario.

```text
snapshot_period.start = summary.period.start_date
snapshot_period.end   = summary.period.end_date

min(occurredOn) ≠ inicio de cobertura
max(occurredOn) ≠ fin de cobertura
```

Ejemplo: período 01/07–31/07, txs 7 / 15 / 22 / 31 → cobertura **01/07–31/07**, no 07–31.

Eliminado como RN: `start_date` debe ser día 1 y `end_date` último día del mes.

Ciclos válidos (no son mes calendario): `02/01/2024 → 31/01/2024`, `07/07/2026 → 06/08/2026`.

---

## RN-G5-PER-002 – Movimientos del snapshot

Los movimientos de G5 son los atribuibles al período según `occurredOn` (`>= start` y `<= end`). La ausencia de txs en uno o más días **no** implica falta de cobertura documental. Las txs llenan la ventana; no la crean. Siguen las reglas vigentes (transferencias internas, clasificación, etc.).

---

## RN-G5-PER-003 – Ingreso del snapshot

Debe existir un **ingreso principal usable y atribuible al período evaluado**. No se exige una tx de ingreso cuyo `occurredOn` caiga exactamente entre `start_date` y `end_date`.

- **Atribuible:** evidencia documental válida, recurrencia detectada o confirmación permitida, con confianza suficiente para representar el ingreso del ciclo (p. ej. sueldo el 01/01 con cartola 02/01–31/01).
- **No disponible / no atribuible:** G4 `ingreso_faltante` → blocked → `no_diagnosis` → completar información (M1-RN-ONB-004/006/010).

No repetir el defecto del “día 1” recortando un ingreso del ciclo porque cayó un día fuera de los bordes del PDF.

---

## RN-G5-PER-004 – Múltiples documentos

Ventana de referencia = documento usable con `end_date` válido **más reciente**. Los demás documentos usables **no se descartan**: pueden aportar indicadores y movimientos **atribuibles a esa ventana**.

Ejemplo: A `01/07–31/07` + B `05/07–04/08` → ventana `05/07–04/08`; de A solo lo atribuible a esa ventana.

Períodos incompatibles o calidad insuficiente → bajar confianza / ir a confirmación (G3/G4). **No** inventar ventana desde min/max `occurredOn`. M1 admite uno o más documentos soportados.

---

## Código hoy vs esta propuesta

| Pieza | Motor actual (criterio técnico) | Propuesta RN |
|---|---|---|
| Ventana | Mes `YYYY-MM` de `occurredOn` más reciente | `summary.period` de Kread |
| `periodStart`/`End` del summary G5 | min/max de líneas | Período documental |
| Ingreso | Tx de ingreso en esa ventana o `ingreso_faltante` | Atribuible al ciclo, no solo `occurredOn` dentro de bordes |
| Batch | Todas las líneas; mes más reciente de esas fechas | Ventana del `end_date` más reciente; resto aporta si es atribuible |

Kread `summary.period` ya se mapea y solo alimenta R5 (90 días). G5 aún no lo consume.

**Implementación:** no entra a productivo como RN hasta aprobación del cliente. Si Desarrollo adelanta el criterio, debe etiquetarse igual que antes: técnico, alineado a esta propuesta, no RN M1 vigente.
