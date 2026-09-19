# M4 — plan de actividades por prioridad

**Fecha:** 2026-08-31 · **Responsable:** Miguel Herize · **Entrega:** jueves 10 de septiembre
**Base verificada:** `back-walvy` `origin/qa` · **Días hábiles disponibles:** 9

> ⚠️ **SUPERADO el 2026-08-31.** Este plan se escribió leyendo el código, antes de tener el paquete
> `Walvy_M04_Entrega_Kabeli_v1.0`. Con el contrato a la vista el alcance es de otro tamaño y la
> dependencia con M05 y M06 invalida su secuencia. Se conserva como antecedente.
>
> **Vigentes:** [`2026-08-31-alcance-real-m4.md`](2026-08-31-alcance-real-m4.md) para los números, y
> [`back-walvy#189`](https://github.com/KabeliDev/back-walvy/issues/189) para los requerimientos y el plan.

Contexto del día: el kickoff ya ocurrió, `qa` quedó tageada con la versión de entrega de M2, Leonardo está
en documentación ([#187](https://github.com/KabeliDev/back-walvy/issues/187)) y Sergio en el día 1 de
onboarding. M4 puede avanzar sin cruzarse con ninguno de los dos.

---

## El punto de partida — qué existe y qué no

Verificado en `origin/qa`, no en la documentación de diseño:

| Pieza | Estado |
|---|---|
| Tablas de deuda, cronogramas, abonos, plan bola de nieve | ✅ Existen desde la baseline `1786000009000` |
| `DebtsModule` wireado, con 7 endpoints | ✅ |
| `debt-severity.rule.ts` — semáforo con `redirectTarget` | ✅ Ya calcula, incluido `ruta_despeje` |
| Columnas `route_eligibility_status`, `functional_debt_state`, `route_activation_allowed`, `minimum_data_ready`, `pressure_rule_met` | ⚠️ **Existen en la base con su `CHECK`, pero la entidad `Debt` no mapea ninguna** |
| Columnas de Ruta Despeje en `user_financial_profile` | ❌ No existen |
| Regla de elegibilidad y de agregación por usuario | ❌ No existen |
| Mapping a etiquetas visibles en el front | ✅ Ya construido, con guardrails y tests, esperando el dato |

**La foto en una frase:** el vocabulario está sembrado, el consumidor está listo, y falta el eslabón del
medio — que alguien calcule, agregue y publique el estado del usuario. Eso es M4.

---

## P0 · Hoy y mañana — lo que desbloquea a otros

Nada de esto es el núcleo de M4, y por eso va primero: son las tres cosas que, si no salen, dejan a alguien
esperando.

### A1 · Cerrar por escrito el contrato de agregación M4 → M2 — **hoy**

Es una decisión, no código, y es la de mayor impacto de la semana: destraba `M2-V60`, `M2-V61` y `M2-V62`,
que hoy figuran como **No implementado** en la matriz del cliente. El front ya tiene el mapping construido y
probado; solo espera el dato.

[#181](https://github.com/KabeliDev/back-walvy/issues/181) deja tres preguntas abiertas. Propuesta a
ratificar:

**1 · Dónde se publica.** Columnas en `user_financial_profile`, **simétricas a `debt_health_*`**:
`route_state`, `route_basis`, `route_reason_codes`, `route_updated_at`.

> Por qué y no un endpoint propio de M4: el patrón ya existe y funciona —Salud de Deuda se publica así—, el
> perfil resuelve con una sola lectura sin sumar una llamada de red, y el guardrail de ausencia del lado M2
> ya está implementado contra esa forma.

**2 · Con qué precedencia se agregan varias deudas.** Gana **el estado más avanzado de la ruta**, no el peor:

```
activa > elegible > pendiente_datos > pendiente_confirmacion > no_elegible / cerrada
```

> Acá la convención de «lo peor manda» —que sí usamos en severidad y en presión dominante— no aplica: esto
> no es una lectura de riesgo, es qué oferta mostrarle al usuario. Si una de sus deudas tiene ruta activa,
> el usuario **está** en una ruta, y decir otra cosa sería falso.

**3 · Si acompaña un motivo.** Sí: `basis` y `reason_codes`, igual que Salud de Deuda. Es lo que sostiene la
explicación contextual que piden `M2-V60` y `M2-V61`; sin eso las dos quedan a medias aunque llegue el estado.

**Salida:** comentario en el #181 con las tres respuestas, y actualización del contrato.
⚠️ **Ojo con el archivo:** el contrato vive hoy en `docs/api/profile/ruta-despeje.md`, dentro del área que
Leonardo está tocando en el #187. Escribir el lado M4 en un archivo nuevo —`docs/api/debts/ruta-despeje.md`—
o esperar a que su PR entre. No editar el mismo archivo hoy.

### A2 · Los dos compromisos del kickoff que son míos — **hoy y mañana**

Bloquean a Leonardo y a Sergio, así que van antes que cualquier línea de M4.

- **Catálogo completo de acciones sugeridas**, en una sola migración. Rango M4: desde `1786000034000`.
- **Firma de la interfaz de señales** hacia el motor de diagnóstico, publicada para que los otros dos
  programen contra ella.

### A3 · Mapear las cinco columnas en la entidad `Debt` — **media hora**

`route_eligibility_status`, `functional_debt_state`, `route_activation_allowed`, `minimum_data_ready` y
`pressure_rule_met`. **No hace falta migración: las columnas ya existen.** Es el cambio más barato del plan
y sin él no se puede escribir ni leer nada de lo que sigue.

---

## P1 · Esta semana — el núcleo de M4

### B1 · Migración de las columnas de Ruta Despeje en `user_financial_profile`

Las cuatro de A1, simétricas a `debt_health_*`. Dentro del rango reservado de M4.

### B2 · Regla de elegibilidad por deuda

Función pura, con `RULE_VERSION` y `reasonCodes`, siguiendo el patrón ya establecido en
`debt-severity.rule.ts` y `dominant-pressure.rule.ts`.

Tiene que respetar el guardrail que **la base ya impone** por `CHECK`:
`route_activation_allowed` solo puede ser verdadero si la deuda está `confirmed`, con `minimum_data_ready` y
`pressure_rule_met` en verdadero. La base rechaza cualquier otra combinación, así que la regla no puede
inventar activaciones aunque quiera.

### B3 · Agregación por usuario y publicación en el perfil

La precedencia de A1, más el escritor que deja el estado en `user_financial_profile`. Idempotente, con
`route_updated_at`, y sin escribir nunca un estado más favorable ante ausencia de datos.

---

## P2 · Semana del 7 — integración y cierre

### C1 · Conectar la señal de deuda en el motor de diagnóstico

`hasDebtConfirmedUnderPressure` y `hasDebtDetectedUnconfirmed` están hoy en `false` a propósito, esperando
que M4 exista. Es mi archivo, así que lo conecto yo — los otros dos no lo tocan.

### C2 · Endpoints de M4 pendientes

Confirmar alcance: hoy hay 7 endpoints de deuda y ninguno de ruta. Definir cuáles entran en esta entrega.

### C3 · Avisar que `M2-V60`, `M2-V61` y `M2-V62` quedan desbloqueadas

Cuando B3 esté en `qa`, esas tres variantes pasan de «No implementado» a cableables. **Es valor inmediato
en la entrega de M2**, no solo en M4, y conviene que la PM lo sepa apenas ocurra.

---

## P3 · Fuera de esta entrega, o a confirmar

- **Plan bola de nieve completo.** La entidad `debt_snowball_plan` existe. Confirmar si entra en el alcance
  del 10 de septiembre o queda para después.
- **[#169](https://github.com/KabeliDev/back-walvy/issues/169) — decisión de Producto sobre «Sana».** No
  bloquea nada de lo anterior.
- **Foco sugerido (`M2-V53`, `M2-V66`).** Requiere la cadena M04 → M06 → M05 completa. No existe el insumo;
  no entra en septiembre.

---

## Resumen ejecutable

| Prioridad | Actividad | Cuándo | Desbloquea |
|---|---|---|---|
| P0 | Contrato de agregación M4→M2, escrito | hoy | `M2-V60/61/62` y el front, que ya espera |
| P0 | Catálogo de acciones + firma de la interfaz de señales | hoy y mañana | Leonardo y Sergio |
| P0 | Mapear las cinco columnas en `Debt` | hoy, 30 min | Todo lo que sigue |
| P1 | Columnas de ruta en el perfil | esta semana | B3 |
| P1 | Regla de elegibilidad por deuda | esta semana | B3 |
| P1 | Agregación por usuario y publicación | esta semana | C1 y C3 |
| P2 | Señal de deuda en el diagnóstico | semana del 7 | El CTA dominante real |
| P2 | Endpoints de ruta | semana del 7 | — |
| P2 | Avisar variantes desbloqueadas | al llegar a `qa` | Entrega de M2 |

**El orden importa:** A1 primero, porque es una decisión que otros están esperando y no cuesta código. A3
después, porque es media hora y habilita todo. El núcleo de M4 arranca recién cuando esos dos están.

---

## Lo que hoy NO hay que tocar

- **`docs/`** — es de Leonardo hoy (#187). Cualquier documentación de M4 va en archivos nuevos.
- **Las pantallas de M5 y M6** en el front — ya tienen dueño.
- **La rama `qa`** — quedó tageada con la entrega de M2. Todo entra por PR contra `main`.
