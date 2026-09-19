# Daily 2026-09-10 · M04 — el motor está listo, faltan insumos de M05 y M06

## Cerrado

**#260** · RGL-022 (detector de fragmentación) y retirada del
`NullPressureInputsAdapter`. Los tres casos del Anexo BDD §A.5 pasan con sus cifras
literales. El detector se publica aparte de `pressure` en `/debts/route/current`,
con conteo, ratio, parámetros 4/8 y versión. 488/488 en unitarios.

**#261** · los dos e2e de Ruta Despeje que fallaban en `qa` desde que el alta
manual nace confirmada. Suite de deudas en 14/14 contra base real.

**#264** · seed de QA con los cinco estados del Resultado, sembrados y verificados
contra los endpoints reales.

## Lo que necesito

### Leo (M06) — el writer de `debt_cycle`. Es el bloqueo grande.

`debt_cycle` está en **0 filas en todas las bases**, incluida la de QA que está al
día con `qa`. Sin ciclo no hay eje D; sin D la presión de **toda** deuda queda
`null` y el agregado degrada a `no_calculable`. O sea: card neutra para todos los
usuarios, siempre.

El motor ya calcula bien los cuatro estados —lo verifiqué contra los endpoints
reales, no en unitarios— y lo único que falta para que el front vea los colores
sin andamio es que alguien escriba esa tabla. Alcanza con dos columnas:
`payment_status_cycle` y `billing_cycle_close_date`; `payment_pattern_frequency`
sólo hace falta para llegar a D2.

Mientras tanto el seed de #264 lo desbloquea (`scripts/seed-estados-presion.mjs`),
pero es andamio y hay que retirarlo cuando M06 escriba ciclos de verdad.

**Ojo con un supuesto que circula:** el docstring de `DebtCycle` dice que es
«tabla ya existente en el baseline (con datos reales)». En ningún ambiente local
hay una sola fila. Si esa afirmación venía del plan técnico y no de una
verificación, conviene corregirla antes de que alguien planifique QA sobre ella.

### Sergio (M05) — subcategoría de entrada para liquidez financiada.

`RGL-021` necesita «naturaleza financiada» y la taxonomía v2.7 no la tiene: las
siete `ING_*` de entrada son ingreso ordinario, y `DEU_05` (línea de crédito /
sobregiro) está declarada `direction: 'out'` — captura el **pago** de la línea, no
su uso como liquidez. Falta la entrada.

Es cambio de taxonomía y el contrato de categorías está con el dev nuevo, así que
va como pedido formal, no como comentario al pasar. No lo toco por inferencia.

### Producto / PMO — cómo se declara la finalidad (RGL-020).

Necesita un vínculo deuda→deuda *confirmado* y nada lo captura hoy. Lo único
inferible es proximidad temporal y monto igual, y P4-CNT-009 lo nombra
explícitamente como el caso negativo: «no prueban causalidad».

No necesita cambios de regla: el motor ya distingue `inferred` de `confirmed` y
trata lo no sustentado como contexto, no como floor. Necesita **quién declara el
hecho**.

Mientras tanto los floors no elevan y la presión **subreporta**. Es la degradación
honesta; lo contrario —empujar a Riesgo por causalidad fabricada— es justo lo que
el contrato prohíbe.

## Datos para la reunión

**`debt_signal` es callejón sin salida.** La Matriz de Trazabilidad apunta ahí para
R020/021/022 y la tabla existe en el baseline con las columnas justas. Parece el
camino, pero §13.1 del Anexo BDD lo descarta: esas tres reglas son *reasons* y «no
generan por sí solas señales autónomas». Si alguien lo propone, ya está
descartado.

**La Ruta no exige mora.** `D0/C3/K1` y `D0/C2/K0` dan Riesgo estando al día: se
llega por C×K. Un fixture de QA armado asumiendo que Riesgo implica atraso no
reproduce el caso. Está cubierto en el seed (`riesgo-al-dia`).

**En Control exige que todas las deudas concluyan.** Una sola en Riesgo pinta
Riesgo aunque el resto no concluya, pero si una queda sin evaluar el agregado cae
a `no_calculable`, no a verde (§10.1: un faltante material bloquea En Control).

## Menor, no bloqueante

**Migraciones desalineadas en ambientes viejos.** Alguien renombró una migración
reutilizando el timestamp `1786000036000`: la base registra
`AgregarRutaDespejeAlPerfil` y el código tiene `ExigirCamposMinimosDeRegistro`.
`M04SchemaCompleto1786000037000` reintenta entonces `route_eligibility_status` y
muere con «column already exists». Desde cero las 43 corren limpias, así que un
deploy nuevo no se entera — pero cualquier ambiente anterior al rename queda
trabado. Vale chequear QA y staging.

**Persistencia de R022.** §6.6 pide conservar conteo, ratio, parámetros y versión.
Hoy salen en la respuesta pero no se persisten: no hay columna. Sería migración
sobre tabla con owner M02.
