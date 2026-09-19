# Pendientes tras la revisión de Protección de Datos — estado al 2026-08-20

Continuación de los dos informes del día: `2026-08-20-revision-codigo-proteccion-datos.md`
(hallazgos H1–H9) y `2026-08-20-ajustes-matriz-validacion-tecnica-m1.md` (los 7 ajustes).

**Baseline:** `back-walvy` `origin/main` de KabeliDev. **Advertencia vigente:** `walvy-org/main`
sigue muy atrás; nada de lo mergeado es visible en el repositorio que audita el cliente.

## Entregables listos para enviar

- `Walvy_M1_Matriz_Validacion_Tecnica_v1.1.xlsx` — los 7 ajustes incorporados, con hoja
  `05 Ajustes v1.1` de trazabilidad. Pendiente sólo de revisión de contenido interna.
- `2026-08-20-inventario-persistencia-rt04.md` — inventario de 55 tablas, responde `RT-04.1`.

## Mergeado

`#99` logs sin dato personal ni financiero · `#100` `CacheControl` de originales ·
`#101` proyección canónica del gate · `#102` purga del original en fallo permanente ·
`#103` pendiente del par degrada a parcial.

## En revisión

`#106` y `#107` quedaron mergeados. Sigue abierta una pila de cuatro, en este orden:

- `#108` fase 3: supresión con registro y resultado por componente. Base `main`, **CI verde**.
- `#109` fase 4a: reconciliación post-restore. Apilada sobre `#108`.
- `#110` fase 4b: regla de acceso efectivo, sin cablear. Apilada sobre `#109`.
- `#111` evidencia: suite e2e del ciclo de vida. Apilada sobre `#110`.

Los apilados no tienen CI porque `pr-check.yml` sólo dispara en `pull_request` contra `main`; su
CI corre al reapuntarse tras mergear el padre. La pila completa se verificó local: 390 unitarios
y 114 e2e en verde sobre la rama de `#111`. **Mergear en orden y esperar el CI de cada uno.**

## Fase 3 — supresión (nuestra, desbloqueada)

1. Endpoint de supresión con su orquestación. `RT-04.4` pide orden, idempotencia, manejo de
   errores y reintentos, y resultado por componente. Con la fase 1 aplicada la cascada hace el
   trabajo pesado; lo que falta es la orquestación y el registro del resultado.
2. Registro de supresiones. `audit_log` es el hogar natural —existe, tiene `before_data`/
   `after_data` y su `user_id` es nullable— pero **hoy nadie le escribe**. Es la base de la
   no-resurrección: tiene que sobrevivir al restore.
3. Consumidor de `listExpiredWindows` que suprima al vencer la ventana. La identificación ya
   está hecha en la fase 2.

## Fase 4 — no-resurrección y gatillo comercial

4. Reconciliación post-restore: compara el registro contra el estado restaurado y re-aplica lo
   que reapareció. Nuestra; el restore lo ejecuta Walvy, así que `RT-04.6`/`RT-04.7` son prueba
   coordinada.
5. Mapeo estado de suscripción → fin efectivo de acceso, externalizado en configuración.
   **Bloqueado** por el catálogo de gatillos de Walvy. El enum ya distingue `past_due` de
   `cancelled`/`expired`, que es la distinción que `TR-RET-01` exige.

## Fase 5 — retorno de datos: CORREGIDO, no es lo que decía este documento

6. La versión anterior de este punto decía «exportación de datos del usuario», y era una mala
   lectura. El subcriterio «retorno o eliminación segura a requerimiento o al término, con
   evidencia» está en la lista de obligaciones del Anexo 10 cuyo primer ítem es «Cliente =
   Responsable; Kabeli = Encargado bajo instrucciones documentadas», y todos los demás son
   obligaciones del Encargado: subencargados, QA seudonimizado, segregación de ambientes, aviso
   de incidente en 72 h.

   O sea que «retorno» es **devolver el dataset al Responsable** a su requerimiento o al
   término del contrato. No es portabilidad para el titular. Se verificó además que el paquete
   de Protección de Datos no menciona portabilidad, retorno ni derechos del titular en ninguna
   parte.

   Consecuencia: **no hay una exportación de datos que construir.** Walvy opera el servicio de
   base de datos en AWS (`TR-DB-01`), así que el retorno del dato es una capacidad que ya tiene.
   Lo que le corresponde a Kabeli es el modelo lógico documentado y un procedimiento de
   extracción reproducible, y buena parte de eso ya está entregado: las 23 migraciones con
   `COMMENT ON` y el inventario de `RT-04.1`.

   Queda por confirmar con Walvy si consideran cubierta la obligación con eso, o si esperan un
   procedimiento de extracción escrito aparte.

## Pruebas que son la evidencia — HECHAS (PR #111)

7. Suite e2e comprometida en `test/users/account-lifecycle.e2e-spec.ts`, 16 casos, sobre el
   arnés que el proyecto ya tenía. Cubre `RT-04.3`, `RT-04.5` y `RT-04.7` de punta a punta, con
   el usuario registrándose por HTTP para que la evidencia legal que sobrevive a la supresión la
   cree el flujo real.

   **No corre en CI**, igual que el resto de los e2e del proyecto: `pr-check.yml` ejecuta sólo
   los unitarios y lo dice explícitamente. Corre con `pnpm test:e2e` contra base real. Conviene
   no asumir que el CI cubre la evidencia.

## Hallazgos nuevos del 20-08 (tarde)

- **Una cuenta en ventana responde 404 en la sesión y 401 en el login, no 403.** El filtro de
  soft delete la vuelve invisible para las búsquedas. Eso deja una tensión entre dos controles
  que Walvy ya aceptó: `TEC-M1-002` pide no revelar si una cuenta existe —y 401 lo cumple mejor
  que un 403— pero `M1-BC-005` pide un mensaje único para cualquier estado que impida el acceso,
  y el front mapea 403 a «Acceso restringido» con salida a soporte. Con 401 el usuario cree que
  escribió mal la contraseña. Hoy se resuelve a favor de la no divulgación **por efecto del
  filtro, no por decisión**. Es pregunta de Producto: cambiarlo toca `M1-BC-005`. Fijado por test
  en PR #111.

- **`SubscriptionsModule` no está importado en `AppModule`.** El módulo de suscripciones existe
  en el código pero no corre, y `Subscription` no figura entre las entidades registradas. Es el
  bloqueante de fondo del gatillo comercial, más profundo que el catálogo pendiente de Walvy: no
  hay señal comercial que observar.

- **Los nombres de tabla del módulo de suscripciones difieren entre migraciones y entidades**:
  `subscription` contra `subscriptions`, `plan` contra `subscription_plans`, y `payment_orders`
  no existe en el esquema migrado. `app.module` usa `synchronize: DB_SYNC`. Material directo
  para `TEC-M1-015`, que pide trazabilidad entre modelo lógico y BBDD real.

## Abierto de otros hallazgos

- **H3** — cablear la redacción en el transporte del logger. Las fugas concretas están tapadas,
  pero la garantía es por convención y no por construcción.
- **H4a** — TTL del original en fallo transitorio o sin clasificar. Necesita el plazo M01 de
  Walvy o una regla de lifecycle en el bucket, que es capa de infraestructura.
- **H5** — columna de alcance/finalidad y estado de revocación en la evidencia de
  consentimiento. Necesita definición de Privacidad sobre qué alcance se registra.
- **H8 (c)** — dónde se persiste la distinción `partial permitido` / `partial bloqueado`. Hoy se
  calcula y se descarta. Toca el esquema.
- **H6** — M07 no existe: sin proveedor de STT ni de IA, y el esquema no tiene dónde apoyar el
  límite de 24h. Es alcance de producto, no deuda técnica.
- **front-walvy** — `computeCompleteness` exige `hasPaymentInstruments` para `green`, que la
  regla del backend declara que nunca impide completo. Otro repositorio, otro PR.

## Definiciones que dependen de Walvy y bloquean el cierre

1. Artefactos legales congelados con versión y hash (`M01-PRV-001`) — Jose + Andrea. Sin ellos
   `TEC-M1-003` no llega a Conforme.
2. Catálogo de valores de `dominant_pressure_code` — bloquea `TEC-M1-014`.
3. Selección de controles por componente y CIS de infraestructura — bloquea `TEC-M1-023`.
4. Modelo de estado del onboarding (`M1-DP-009`) — referencia de `TEC-M1-007` y `TEC-M1-013`.
5. Catálogo de gatillos comerciales de fin efectivo de acceso — bloquea la fase 4.
6. Legal: si existe retención residual y su alcance (`RT-04.8`).
7. Ejecución de restore/PITR para la prueba coordinada (`RT-04.6`).
8. TTL del original M01 (`M01-DAT-021`).
9. Consulta menor: si «Anexo 3.10» refiere al Anexo 10 o al punto 10 del Anexo 3.

## Decisiones internas pendientes

- **Sincronizar el código a `walvy-org`.** Es la más urgente: define si podemos decir
  «corregido» y que el cliente lo verifique.
- Confirmar las dos propuestas de la matriz que van más allá de lo que Walvy pidió: reasignar
  `M1-V44` a `TEC-M1-012`, e incluir `M01-RGL-011` y `M1-DP-008/009` en `TEC-M1-013`.
- **¿Debe poder autenticarse una cuenta en ventana para reactivarse por sí misma?** La fase 2
  asume que no, porque admitirlo cambiaría `M1-BC-005` que Walvy ya aceptó. Es pregunta de
  Producto y está declarada como tal en el código.
- Alcance de la exportación de datos (punto 6).
