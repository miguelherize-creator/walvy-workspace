# Borradores Jira · épica Seguridad (15-10)

**Publicados el 15-10 a las 15:55** tras reconectar Atlassian con escritura. BUG-83, 44, 82 y 36 pasaron a «En revisión Kabeli»; BUG-22 sigue «En corrección».

| Ticket | Acción |
|---|---|
| BUG-44 | Comentar y pasar a «En revisión Kabeli» |
| BUG-82 | Comentar y pasar a «En revisión Kabeli» |
| BUG-36 | Comentar y pasar a «En revisión Kabeli» |
| BUG-22 | Solo comentar; queda «En corrección» |
| BUG-83 | Después del merge de back#383: comentar el SHA nuevo y pasar a revisión |

---

## BUG-44

**Listo para revisión · código en `qa`**

KabeliDev/back-walvy#375 mergeado en `qa` (merge `d11b557`). La evidencia del comentario anterior (14-10) aplica tal cual:

- `test/auth/artefactos-mock.e2e-spec.ts`, 14 casos: el backend rechaza tokens, JWT e identidades mock, y nunca emite `devToken`/`devCode`.
- `receta-artefactos-mock.sh` contra `api-qa.sonark.tech`: 5/5 casos rechazados.
- Del lado del cliente, el modo mock exige `__DEV__`: un build release no entra en mock aunque la variable quede activa (KabeliDev/front-walvy#233).

Único cambio desde el comentario anterior: el archivo del e2e se reformateó para pasar el lint de CI (`6d9fd25`), sin cambios en las pruebas. CI de #375 en verde antes del merge.

---

## BUG-82

**Listo para revisión · código en `qa`**

KabeliDev/back-walvy#375 mergeado en `qa` (merge `d11b557`), con el commit `735ef06` del comentario anterior.

- ADR: `docs/adr/0001-dependencia-imports-health.md` (Imports es dueño del contrato normalizado; Health solo lee; Imports consulta a Health solo vía `DiagnosisQueryService`; sin puerto nuevo).
- Pruebas de contrato: `src/health/contracts/imports-health.contract.spec.ts`, 3/3, incluidas en la suite que pasó en CI antes del merge.

Las pruebas de contrato siguen pasando después de los refactors de BUG-36 que entraron en el mismo PR.

---

## BUG-36

**Listo para revisión · código en `qa`**

KabeliDev/back-walvy#375 mergeado en `qa` (merge `d11b557`), con los dos cortes de los comentarios anteriores: Pagos (`3d15fed`) y Deudas (`fc1f6a6`).

**Contra el criterio de cierre** («la ingesta debe poder cambiarse y probarse sin escribir directamente entidades de múltiples dominios; cada efecto con owner y pruebas de contrato»):

| Dominio destino | Antes | Ahora | Pruebas |
|---|---|---|---|
| Pagos e historial (M06) | `paymentRepo` y `paymentHistoryRepo` directos | `ImportCommitmentWriter` | `statement-import-commitments.spec.ts`, 9 casos |
| Deudas | `debtRepo` directo | `ImportDebtWriter` | `statement-import-debts.spec.ts`, 6 casos |
| Movimientos financieros | ya pasaba por `FinancialMovementsService.create` (API del dueño) | sin cambio | — |

- Las únicas escrituras directas que quedan en `StatementImportService` son `importRepo` y `lineRepo`, del propio dominio de Imports.
- Las pruebas de caracterización se escribieron y pasaron sobre el código original antes de cada refactor, y siguieron pasando después.
- Suite completa de back-walvy en verde en CI antes del merge.

**Límite conocido:** el servicio sigue siendo grande (~2.470 líneas). El criterio de cierre es de propiedad de los efectos, no de tamaño; reducirlo más sería un refactor aparte.

---

## BUG-22 (solo comentario, sigue «En corrección»)

**Avance · código en `qa` (cierre parcial)**

KabeliDev/back-walvy#376 mergeado en `qa` (merge `edc52ec`).

| Acción requerida | Estado |
|---|---|
| Persistir intent/`commerceOrder` antes de mutar el proveedor | ✅ El checkout guarda la orden `pending` antes de llamar a Flow y completa el token después. Si Flow falla o hace timeout, la orden queda `pending` con su `commerceOrder`; no se cancela, porque Flow pudo haber aceptado |
| Deadline explícito | ✅ Todas las llamadas a Flow con timeout de 15 s |
| Política retry/no-retry | ✅ Sin reintento automático de `payment/create`: una segunda llamada podría crear una segunda orden |
| Callback inbox/replay durable para recurrentes | ✅ Tabla `flow_callback_inbox` (migración `1786000076000`). Se guarda antes de procesar; si falla queda `failed` y la reconciliación lo reintenta (hasta 5 intentos, ventana 2 min–48 h). Un reintento cuyo cobro ya existe se marca procesado sin cobrar otra vez |
| Reconciliación por `commerceOrder` | ⏳ Pendiente: requiere confirmar el endpoint de Flow |
| Recuperación de cancel intent | ⏳ Pendiente |

**Pruebas:** 46 en `src/subscriptions`. Migración aplicada sobre PostgreSQL 16 con la cadena completa; reejecución sin pendientes; revert y reaplicación OK.

**Sigue en «En corrección»:** faltan la reconciliación por `commerceOrder`, la cancelación y la prueba funcional, bloqueada mientras el flujo de pagos esté apagado en el frontend.

---

## BUG-83 (comentar y pasar a «En revisión Kabeli»; #383 ya mezclado)

**Listo para revisión · evidencia regenerada sobre `qa`**

KabeliDev/back-walvy#375 y KabeliDev/back-walvy#383 mergeados en `qa` (merge de #383: `cc91713`).

**Por qué hubo un segundo PR:** al regenerar la evidencia sobre la cabeza de `qa` (`d11b557`), el harness falló en el paso 10. `DB/baseline/schema-completo.sql` registraba 79 migraciones y la cadena tiene 80, porque la migración `CrearFlowCallbackInbox` (BUG-22) entró sin regenerar el consolidado. El harness lo detectó como debía: fail-closed, `RESULTADO GLOBAL: FALLA`.

**Corrección (#383)**
- `7d36c40`: consolidado regenerado con `DB/baseline/generar-consolidado.sh`. El único cambio de estructura es `flow_callback_inbox` y su índice.
- `74b8081`: `DB/evidencia/EVIDENCIA-EJECUCION.log` regenerado sobre `7d36c40` desde base limpia.

| Criterio | Resultado |
|---|---|
| Harness, fixture y log en el mismo SHA | `7d36c40` |
| PostgreSQL | 16.14 |
| Verificaciones | **28 pasan, 0 fallan** |
| Resultado global | **PASA** |

Las desalineaciones del comentario del 14-10 siguen corregidas: `app_user` con `password_hash` y aceptación legal, `debts` en lugar de `debt`, y `financial_nature` en el fixture.
