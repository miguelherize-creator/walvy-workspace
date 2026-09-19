# 2026-09-10 · RD-01 — «Salud de deuda» lee el ingreso equivocado

Detectado probando RD-01 (Ruta Despeje · Resumen) con la cuenta de QA
`semaforo-rojo@ejemplo-walvy.cl`, sembrada por
`entregas/set-datos-prueba-m04-semaforo.sql`.

**Estado: bloqueado por ruling de producto. No se corrige desde el código.**
Lo que sí se cerró en la misma pasada —el criterio de la deuda prioritaria— va
en la PR contra `qa` de `fix/m04-prioridad-bola-de-nieve`, y no toca este punto.

## El síntoma

La card «Tu estado actual» muestra

> *Agrega tu ingreso mensual en tu Perfil Financiero para ver este dato.*

aunque el motor P4 ya concluyó una lectura de presión y de salud para ese
usuario. El usuario lee «me falta un dato» cuando el dato existe y ya se usó.

## La causa

`expo/features/debts/hooks/useDebtRoute.ts` calcula el ratio en el cliente:

```
capacityPct = totalMinPayment / profile.monthlyIncomeEstimate
```

`monthlyIncomeEstimate` es el ingreso **declarado** en el Perfil Financiero
(M02). El motor P4 no usa ése: el ratio C se calcula sobre el **ingreso canónico
de M05** —suma de `financial_movement` de entrada en la categoría raíz `CAT_01`
del mes vigente, `back-walvy/src/budget/adapters/pressure-inputs.adapter.ts`—.
Son dos ingresos distintos y pueden diferir en presencia y en monto: un usuario
con movimientos cargados y sin declaración en M02 tiene lectura de presión y
mensaje de «falta el dato» al mismo tiempo, que es exactamente el caso de QA.

## Por qué no se corrige acá

Cambiar la fuente sin cambiar el rótulo no arregla el problema, porque el rótulo
también está en disputa. Son dos decisiones y ninguna es de implementación.

**1. El rótulo choca con dos reglas.** RD-01 dice «Capacidad de pago comprometida
al X%». Es el mismo ratio C que el frame del Resultado (Figma 10272:54344 /
54408 / 54533) rotula «% de capacidad de ahorro comprometida». Contra el paquete
documental:

- La **capacidad de ahorro** general es de Presupuesto (Fase 2 §4 en
  `documentacion/modulo04`). M04 no la calcula ni la posee. El propio contrato
  se cuida de repetirlo: §8.2 y M04-RGL-027 dicen que la capacidad recuperable
  «no equivale a capacidad de ahorro de M05», y el tipo del backend lo marca en
  el código (`RecoverableCapacity.isSavings: false`).
- El output de **Salud de Deuda** es un **estado**, no una cifra: §7.1 de la
  Guía Backend define `Sana / Requiere atención / Presionada`. Un porcentaje bajo
  ese encabezado promete una precisión que la regla no entrega.

**2. El backend no publica el ratio.** `GET /debts/route/current` expone
`health.status` y `pressure.reading` —estados—, y ninguna cifra de C. Si producto
resolviera que el porcentaje se muestra, no alcanza con cambiar la fuente en el
front: hay que agregar el campo en `route.service.ts`, con su versión de regla.
Hoy el % que se ve en pantalla es una cuenta propia del cliente, no el número del
motor.

## Lo que hay que preguntarle a producto

1. ¿RD-01 muestra un **estado** de Salud de Deuda (`health.status`, el camino que
   ya tomó el Resultado tras el ajuste de los frames) o una **cifra**?
2. Si es cifra: ¿cómo se rotula sin invadir la capacidad de ahorro de M05, y se
   agrega C al contrato de `/debts/route/current` con su `ruleVersion`?
3. En cualquiera de los dos casos: ¿el mensaje «Agrega tu ingreso mensual en tu
   Perfil Financiero» sigue existiendo, dado que el ingreso que manda es el
   canónico de M05 y no el declarado en M02? Hoy deriva al lugar equivocado.

Mientras tanto el hallazgo queda anotado en el docstring de `capacityPct` en
`useDebtRoute.ts`, para que la próxima persona que lo lea no lo «arregle»
cambiando sólo la fuente.

## De paso, en la misma card

`DebtRouteScreen.tsx` pinta **«Presión financiera: Alta» hardcodeado**: el texto y
el color están fijos en el JSX y no leen `pressure.reading` de
`/debts/route/current`. A un usuario `en_control` le dice que su presión es alta.
Es la misma familia de defecto que #159 y no depende de ningún ruling —el
contrato ya está publicado y `resultVariant.ts` ya sabe leerlo—, pero es un
cambio aparte de la PR del criterio de prioridad.
