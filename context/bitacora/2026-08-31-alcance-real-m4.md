# M4 — alcance real contra el paquete de Walvy

**Fecha:** 2026-08-31 · **Fuente:** `Walvy_M04_Entrega_Kabeli_v1.0` (Drive, 28-ago)
**Contraste:** código de `back-walvy` en `origin/qa`
**Para:** conversación con la PM sobre la fecha del 10 de septiembre.

El plan del [`#189`](https://github.com/KabeliDev/back-walvy/issues/189) se escribió leyendo el código, no
este paquete. Con el paquete a la vista, el alcance es de otro tamaño. Este documento pone los números.

---

## 1 · El paquete en números

| Artefacto | Cantidad |
|---|---|
| Trace de la Matriz Cliente | **93** |
| Reglas Walvy (`M04-RGL-*`) | **43** |
| Contratos del motor P4 (`P4-CNT-*`) | **25** |
| Controles técnicos (`TEC-M4-*`) | **30**, todos en «Aceptado» de alcance y **«No iniciado»** de cumplimiento |
| IDs de Protección de Datos vigentes | **50**, cada uno con materialización explicable |
| Requerimientos de evidencia PD | **7 requerimientos + 31 preguntas** |
| Fixtures de QA nombrados en la guía | 16 (`TC-022`, `TC-031`, `TC-036`, …) |
| Familias de situaciones del lifecycle | **F1 a F7**, con `born/update/resolved` |

Y cuatro entregables que **no son código**, exigidos por `00_LEEME`: completar la Matriz de Trazabilidad,
declarar implementación y evidencia en los 30 controles de la Matriz de Validación Técnica, responder los
7+31 de PD, y aportar evidencia física trazada a repo/tag/commit/ambiente.

---

## 2 · El pipeline tiene diez pasos; el código tiene uno y medio

`§3` define el pipeline rector:

```
Normalización → Calidad → C → K → D → Presión base → Precedencia/floors
→ Salud por aging → Ruta (elegible/activa) → Lifecycle F1-F7
```

Búsqueda sobre `src/` de los componentes del motor:

| Componente | Archivos en el código |
|---|---|
| Headroom / capacidad residual | **0** |
| Presión (matriz C×K×D, 27 combinaciones) | **0** |
| Simulación RD-02 | **0** |
| Gate de sostenibilidad | **0** |
| `rule_version` / provenance reproducible | **0** |
| Priorización snowball | columna `snowball_priority`, sin motor |
| Salud de Deuda con aging | `debt-severity.rule.ts` calcula un semáforo por fechas de vencimiento, que **no es** la Salud del contrato |

Lo que sí existe y sirve, casi todo heredado de M1: autorización por usuario, la ingesta documental completa
con Kread y sus estados, el manejo de documentos protegidos sin persistir la contraseña, el alta manual de
deuda y los estados de confirmación y descarte. Son **5 o 6 de los 30 controles**, y ninguno es del motor.

---

## 3 · El hallazgo estructural: M04 depende de M05 y M06

Esto es lo que cambia la conversación, y está literal en `§4` y en la matriz de dependencias:

| Input | Owner | Para qué lo usa M04 |
|---|---|---|
| Ingreso mensual canónico · headroom · outcome prudencial | **M05** | Calcular **C** y **K**, y la simulación de RD-02 |
| Pagos · ciclo · recurrencia · aging | **M06** | Calcular **D** y la **Salud de Deuda** |

Las dos figuran como `DEPENDENCIA ACTIVA`. Y los controles lo repiten: `TEC-M4-007` («M05 provee ingreso»),
`TEC-M4-008` («M05 owner del output»), `TEC-M4-009` y `TEC-M4-013` («M06 owner de eventos/ciclo» y «aging
operativo»).

**M05 entrega el 23 de septiembre. M06 el 30. M04 el 10.**

Sin C, K y D no hay Presión. Sin Presión no hay Salud del contrato ni elegibilidad de Ruta, porque `§7.2`
la define como «Riesgo + gate → elegible». **El núcleo de M04 no se puede calcular antes de que lleguen los
otros dos módulos.**

En el [`#184`](https://github.com/KabeliDev/back-walvy/issues/184) escribí que M4 no dependía de ninguno de
los dos. Era una deducción del código y está mal: el código no tiene el motor, así que tampoco tenía las
dependencias a la vista.

---

## 4 · Qué sí se puede entregar el 10 de septiembre

No es «nada». Hay una isla real que no depende de M05 ni de M06:

| Entregable | Control | Estado |
|---|---|---|
| Contrato de publicación de Ruta Despeje y mapeo de columnas | `TEC-M4-014` | ✅ Hecho — [PR #192](https://github.com/KabeliDev/back-walvy/pull/192) |
| Máquina de estados de Ruta: elegibilidad, activación, continuidad, idempotencia | `TEC-M4-014` | Construible |
| Publicación del estado agregado en el perfil | — | Construible |
| Confirmación, descarte, duplicados y lote | `TEC-M4-005` | Parcial, completable |
| Alta manual e integridad, faltantes bloqueantes | `TEC-M4-004` | Parcial, completable |
| Fallbacks y no transaccionalidad | `TEC-M4-021` | Construible |
| Trazabilidad de release y ambiente | `TEC-M4-024` | Construible |

**Y hay una consecuencia que conviene aprovechar:** el fallback del contrato dice que sin datos suficientes
el estado es `pendiente_datos`. Ese es exactamente el valor que M02 mapea a «Datos por confirmar», o sea
**`M2-V60`**. Publicando ese estado —que es la lectura honesta mientras falten M05 y M06— **`M2-V60` se
cierra el 10 de septiembre sin motor P4**. `M2-V61` y `M2-V62` sí necesitan el motor.

---

## 5 · Qué no llega, y no por ritmo de trabajo

Los 25 contratos P4 del motor, las 27 combinaciones de la matriz de Presión, los floors causales
`RGL-020/021`, el detector de fragmentación, la Salud con aging, la priorización snowball, la capacidad
recuperable, la simulación RD-02 con su gate prudencial y su rollback, el `FLOW-M04-023` de cierre, y las
siete familias del lifecycle con su prioridad local.

Más los cuatro entregables de evidencia: 30 controles a declarar, 93 Trace a completar, 50 IDs de PD a
mapear y 7+31 preguntas a responder.

---

## 6 · Tres caminos, y cuál recomiendo

**A · Mover M04 después de M05 y M06.** Es lo que la dependencia pide: entregaría a fines de octubre. Rompe
el compromiso del 10 y probablemente el orden completo de septiembre.

**B · Partir M04 en dos entregas.** El 10 de septiembre va **M04-A**: Ruta Despeje completa como máquina de
estados, publicación al perfil, gestión de deuda y fallbacks — con el estado degradado `pendiente_datos`
mientras falten insumos, que es la lectura correcta y no una simulación. El motor P4 va en **M04-B**, después
del 30 de septiembre, cuando M05 y M06 estén entregados. ✅ **Es la que recomiendo.**

**C · Sostener el 10 con el alcance completo.** No lo veo posible: no es cuestión de esfuerzo, es que dos de
los tres inputs del motor no existen todavía.

La ventaja de **B** es que no rompe nada de lo que ya está comprometido: M04-A entrega valor verificable el
10, destraba `M2-V60`, y deja el motor para cuando sus insumos existan. Además ordena el mes al revés de como
está hoy: **M04-B pasa a ser el último**, que es donde la dependencia lo pone naturalmente.

---

## 7 · Lo que hay que decidir

1. **Ratificar el corte A/B** o elegir otro camino.
2. **Confirmar con Walvy el alcance de la primera entrega**, para que «M04 entregado el 10» no se lea como
   los 30 controles.
3. **Responder la discrepancia del vocabulario** (`pendiente` vs `pendiente_confirmacion`/`pendiente_datos`),
   que está en el PR #192 y condiciona si `M2-V60` y `M2-V61` son distinguibles.
