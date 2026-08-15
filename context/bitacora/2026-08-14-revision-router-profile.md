# Revisión de conformidad M1 — router `profile`

**Fecha:** 2026-08-14
**Método:** endpoint → pantalla → documentación M1 → tablero → backend (mismo que router `users`)
**Alcance:** `/profile/goals` (M1). `/profile/financial` congelado hasta M2.

> **Titular:** `POST /profile/goals` respondía **500 para los seis focos del catálogo** — el único
> endpoint cableado del router nunca escribió una fila. Verificado en ejecución (§3) y **corregido
> sin migración** (§7): el focusId no iba en `goal_type` sino en `goal_focus_code`.

## Baselines

| Repo | Rama | SHA | Fecha |
|---|---|---|---|
| `walvy-org/walvy-app-backend` | `walvy/main` | `073c523a0148af7609101dc5c19727d9778c0af6` | 2026-08-13 |
| `walvy-org/walvy-app-frontend` | `walvy/main` | `4d66479a3f51e7ac7bff498a2df14ff82f11f321` | 2026-08-13 |

> El PR #85 del router `users` sigue **OPEN** en `walvy-org` — no está en este baseline.

## Fuentes

- `Walvy_M1_Matriz_Trazabilidad_Cliente_v2.6.xlsx` (`1MRRKk-hNZT0HUFios8WT2Tsrz3vkd5is`)
- `Walvy_Assessment_Validacion_M01_v1.1 (diferido_onboarding).xlsx` (`1Fd6r5xbaEl6CjEZWZd13nyXHNW1umJVt`)
- Tablero `KabeliDev/projects/10` — 79 ítems

---

## 1. Mapeo endpoint → pantalla

| Endpoint | Servicio front | Pantalla | Estado |
|---|---|---|---|
| `POST /profile/goals` | `goalsService.saveGoal` | `/(auth)/onboarding-foco` → `OnboardingFocoScreen.tsx:148` | **Único endpoint cableado** |
| `GET /profile/goals` | `goalsService.getGoal` | — | Sin consumidor |
| `GET /profile/financial` | `financialProfileService.getFinancialProfile` | — | Sin consumidor · M2 |
| `PUT /profile/financial` | `financialProfileService.upsertFinancialProfile` | — | Sin consumidor · M2 |

`financialProfileService.ts` no lo importa ningún archivo del repo. `(tabs)/profile.tsx` es un
placeholder ("Mi perfil — Próximamente").

---

## 2. `/profile/financial` — diferido a M2

Registro de lo constatado, sin acción en M1:

- Tablero: `MV-M2-01 · Perfil Financiero` y `MV-M2-02 · Mi Perfil` → **Blocked**.
- En la matriz M1 el ingreso no se declara en formulario: `M1-RN-ONB-004` y `M1-V48` lo exigen
  "detectado/**confirmado**" desde el documento cargado. No hay variante M1 que respalde captura manual.
- `IngresosDatosSheet.tsx` existe, calza exacto con el contrato del endpoint
  (`sueldoLiquido` → `monthlyIncomeEstimate`, `fijo`/`variable` → `incomeType`) y **no lo importa nadie**.
- El tipo `FinancialProfile` del front declara `currencyId`, que el backend omite a propósito y
  documenta como omitido. Latente: sin consumidor no rompe nada.
- `financialProfileCompleted` es requisito de `allDone` en el cálculo de completitud del onboarding
  y su única aparición en el frontend está en la rama **mock** de `getOnboardingStatus`. Ya levantado
  como `#68`; el ángulo nuevo es que el checkpoint que falta pertenece a este router y es de alcance M2,
  así que `#68` no cierra sin resolver antes `RM1-22`.

Brecha de tablero: ninguna tarjeta cubre `/profile/financial` como superficie de **backend**.
`MV-M2-01` es validación de frontend y `RM1-22` es la frontera.

---

## 3. Verificación funcional de `/profile/goals`

Ejecutada contra `walvy/main` en worktree aislado, Postgres local `5433/walvy`, harness e2e del
propio repo (`createTestApp` + `registerAndVerify`).

| # | Comprobación (fuente) | Esperado | Obtenido | |
|---|---|---|---|---|
| 1 | Sin token (`goals.md`) | 401 | 401 | ✅ |
| 2 | `GET` sin foco declarado (`goals.md`, M1-V29) | 404 | 404 | ✅ |
| 3 | `POST` los 6 focos del catálogo (M1-V31…V36, PD-M1-06) | 200 | **500 ×6** | ❌ |
| 4 | `POST` `focusId` inválido (`goals.md`) | 400 | 400 | ✅ |
| 5 | `POST` sobrescribe, un único foco activo (M01-RGL-006) | 200 + foco nuevo | **404** — nunca se guardó | ❌ |
| 6 | Aislamiento entre usuarios | 404 para el otro | 404 | ✅ |
| 7 | Vocabulario BD vs DTO | coincidente | **disjunto** | ❌ |

### 3.1 Causa

`user_goals` tiene un CHECK que rechaza todos los valores que el DTO acepta:

```sql
-- src/migrations/1786000008000-BaselinePerfilPresupuesto.ts:150
CONSTRAINT chk_user_goals_goal_type CHECK (goal_type = ANY (ARRAY[
  'reduce_debt', 'save_amount', 'improve_savings_capacity',
  'avoid_late_payments', 'meet_budget', 'other'
]))
```

```ts
// src/profile/dto/set-focus.dto.ts
export const VALID_FOCUS_IDS = [
  'bajar_deuda', 'ahorrar_monto', 'aumentar_margen',
  'evitar_atrasos', 'cumplir_presupuesto', 'ordenar_compromisos',
] as const;
```

Error observado en los seis casos:

```
QueryFailedError: new row for relation "user_goals" violates check constraint "chk_user_goals_goal_type"
  at GoalsService.setFocus (src/profile/services/goals.service.ts:58)
→ 500 {"statusCode":500,"message":"Error interno del servidor","path":"/profile/goals"}
```

Ninguna migración posterior altera el constraint. `user_goals` quedó en 10 filas tras 8 `POST`:
**cero inserciones**. Las 10 filas preexistentes son del seed, con vocabulario inglés y
`goal_scope` poblado (`monthly_focus`, `debt_focus`).

Son dos modelos que nunca se encontraron: la BD se diseñó con vocabulario inglés más `goal_scope`;
la capa API se escribió después con vocabulario español y sin `goal_scope`.

### 3.2 Correspondencia de vocabularios

| Catálogo cliente (PD-M1-06) | DTO | CHECK en BD |
|---|---|---|
| Bajar deuda | `bajar_deuda` | `reduce_debt` |
| Ahorrar un monto | `ahorrar_monto` | `save_amount` |
| Aumentar margen | `aumentar_margen` | `improve_savings_capacity` |
| Evitar atrasos | `evitar_atrasos` | `avoid_late_payments` |
| Cumplir presupuesto | `cumplir_presupuesto` | `meet_budget` |
| **Ordenar compromisos** | `ordenar_compromisos` | **sin equivalente** (sólo queda `other`) |

El sexto foco — confirmado vigente por el cliente en PD-M1-06 — no tiene lugar propio en la BD.

### 3.3 Por qué nadie lo detectó

`OnboardingFocoScreen.handleGuardar()` se traga el error y navega igual:

```ts
try {
  await saveGoal(selected as FocusId);              // ← lanza 500
  await advanceOnboardingStep({ …, goalsSet: true }); // ← nunca corre
} catch (err) {
  if (err?.response?.status === 401) { … return; }
  // Error no crítico — no bloqueamos el flujo de onboarding
}
router.push("/(auth)/onboarding-doc");              // ← avanza igual
```

El usuario elige foco, pulsa "Guardar mi foco", no ve error y pasa a la pantalla siguiente. No se
guardó el foco **ni** avanzó el checkpoint: `goals_set` queda en false y `current_step` no llega a
`document_upload`. La retoma lo devuelve atrás. Contradice `M01-RGL-007` — *"el checkpoint persiste;
la retoma continúa desde el punto guardado"*.

Esto explica que V28 y V31…V36 figuren "Aprobado" en la matriz: se validaron contra Figma, no contra
el backend en ejecución.

---

## 4. Hallazgos de contrato sobre `/profile/goals`

### H-A — Contradicción viva: M1-V29 (`Ajustar`)

| Fuente | Dice |
|---|---|
| Matriz, "Comportamiento esperado" | "Permitir continuar; registrar no declarado y no bloquear carga documental." |
| `M1-HU-019` CA2 | "La falta de foco no bloquea la carga documental." |
| **Validación Cliente** | **`Ajustar`** |
| **Decisión PO** | "…debe conservarse el **estado pendiente** y aplicarse la **salida de postergación**; **no corresponde describir esta acción como avance directo a carga documental**." |

`handleSalir()` hace exactamente lo desautorizado: `advanceOnboardingStep({ currentStep: "document_upload", … })`.
Y el backend no puede representar "pendiente": `goals_set` es booleano y `GET /profile/goals`
responde 404 para todo lo que no sea declarado.

Cruza con `#73 · Adoptar el modelo de puertas` (M01-RGL-007/008, M1-V58-V60).

### H-B — `M1-RN-ONB-019` pide tres estados; el contrato expresa dos

`AX-M1-002` (Aceptado Producto) cierra la redacción: *"Mantener estados declarado / no declarado /
**sugerido** … **no usar 'inferido/sugerido'**"*. Y: *"una vez aceptado, el foco persiste y no se
reemplaza automáticamente"*.

El backend sólo tiene fila-o-404. `user_goals` ya trae `goal_scope` (`monthly_focus`), `goal_status`
(`draft|active|…`), `goal_priority` y `goal_focus_code`: **todos nullable y nunca escritos** por
`setFocus()`. El comentario de la propia entidad admite que `isActive` vs `goalStatus` no lo
resuelve el esquema. Falta además el origen (`user_selected` / `system_suggested`) para sostener la
no-sustitución tras aceptación; el patrón ya existe en el esquema sobre
`user_financial_profile.active_financial_rule_source`, pero no sobre la meta.

> El **cálculo** del foco sugerido es M2 y está Blocked (`#52`). M1 sólo necesita poder
> **representar** el estado.

### H-C — El "Foco del Mes" no es mensual

`setFocus()` reutiliza la fila activa y sobrescribe `goalType`, reseteando `declaredAt`. No hay
registro por mes ni historia: al cambiar de foco el anterior es irrecuperable. `RB-FM-006` exige que
cada foco sea trazable a indicadores del Perfil Financiero y `AX-M1-002` habla de recálculo con una
nueva versión del Diagnóstico; sin historia esas reglas se quedan sin base.

### H-D — Error silenciado en el guardado

Ver §3.3. Es defecto propio, con o sin el 500: cualquier fallo distinto de 401 deja al usuario
avanzado en la UI y sin checkpoint en el backend.

### H-E — `goals_set` excluido de la completitud, con el motivo equivocado

`user-onboarding.service.ts:51` — `// goals_set excluido hasta que tenga pantalla asignada en el flujo UI`.
La pantalla existe y envía `goalsSet: true`. **Excluirlo sigue siendo correcto** — incluirlo
bloquearía el onboarding de quien no declara foco, contra CA2 de HU-019 y ONB-019. El defecto es el
comentario: da un motivo vencido que invita a revertir la exclusión.

### H-F — Cero cobertura de test

Ningún `.spec.ts` ni `.e2e-spec.ts` del repo referencia `/profile/goals`, `GoalsService`, `setFocus`
ni `focusId`. Por eso un 500 en el 100 % de los casos llegó a `main`.

---

## 5. Cruce con el tablero

| Tarjeta | Estado | Hallazgos |
|---|---|---|
| `MV-M1-08 · Foco del Mes — 9 variantes` (M1-V28…V36) · front-walvy#25 | In Progress | §3, H-A, H-B, H-C, H-D |
| `RM1-12 · Activación del onboarding y Foco del Mes` (ONB-001, 012) · back-walvy#32 | Todo | H-B, H-E |
| `RM1-22 · Frontera M1 ↔ M2 — salida a Perfil Financiero` (ONB-016) · back-walvy#42 | Todo | §2 |
| `#73 · Adoptar el modelo de puertas` (M01-RGL-007/008, V58-V60) | Todo | H-A, H-D |
| `#68 · El onboarding nunca llega a 'completed'` | Todo | §2 |

**Sin tarjeta:** el 500 de §3. No hay ítem en el tablero que cubra el vocabulario de `goal_type`
ni la ausencia de tests del router.

### M2 — no tocado

`MV-M2-01`, `MV-M2-07`, `#52` (cálculo del foco sugerido), `#48` (destino de los 6 focos). Blocked.

---

## 6. Decisiones abiertas

1. ~~**Vocabulario de `goal_type`**~~ — **cerrada**. No era un problema de vocabulario sino de
   columna: ver §7. No hubo migración.
2. **Estado del foco** — ¿M1 incorpora ya `pendiente` y `sugerido` al contrato de `/profile/goals`
   (H-A, H-B), o se difiere junto con el cálculo M2 de `#52`? V29 y V30 viven en `MV-M1-08`, que es
   M1 e In Progress. **Sigue abierta.**
3. **Historia mensual** — ¿un registro por mes o basta el foco vigente? Cambia si `setFocus`
   sobrescribe o inserta (H-C). **Sigue abierta.**

### Anotaciones de la verificación

- Worktree y spec de verificación en el scratchpad de la sesión; no se tocó la rama de trabajo.
- La corrida creó ~11 usuarios `@e2e.test` en la BD local de desarrollo (ya había 345 de corridas
  previas de la suite). No se borró nada.

---

## 7. Corrección aplicada

### 7.1 El diagnóstico inicial era equivocado

La primera recomendación fue migrar el CHECK de `goal_type` al vocabulario español. **Es incorrecta.**
Los `COMMENT ON COLUMN` de la propia migración baseline fijan el modelo:

| Columna | Comentario en la migración |
|---|---|
| `goal_type` | "Tipo de meta: `reduce_debt` \| `save_amount` \| … \| `other`." |
| `goal_focus_code` | "Código estable del **foco declarado por el usuario durante onboarding** u otros flujos guiados." |
| `goal_scope` | "Distingue si es **foco mensual**, meta de largo plazo o foco específico…" |

El focusId del catálogo va en `goal_focus_code`, no en `goal_type`. Son dos ejes, no dos nombres de
lo mismo — y que `ordenar_compromisos` no tuviera equivalente en `goal_type` era el síntoma.

Las filas del seed ya implementaban el modelo correcto:

```
goal_type='meet_budget'  goal_scope='monthly_focus'  goal_focus_code='cumplir_presupuesto'
goal_type='reduce_debt'  goal_scope='debt_focus'     goal_focus_code='tarjeta_credito'
```

Migrar el CHECK habría fijado en el esquema del cliente un modelo que su propia documentación
contradice. **El arreglo correcto no necesita migración**: las columnas ya existen y aceptan los valores.

### 7.2 Cambios

Backend — rama `fix/m1-rn-onb-020-foco-mes-persistencia`:

- `src/profile/services/goals.service.ts` — `setFocus` escribe `goal_focus_code`, `goal_scope='monthly_focus'`,
  `goal_status='active'` y el `goal_type` de la taxonomía; `getFocus` lee `goal_focus_code`. Ambas
  consultas acotadas por `goal_scope`, que además cierra un bug latente: antes `setFocus` podía
  sobrescribir una meta `long_term_goal` del mismo usuario.
- `docs/api/profile/goals.md` — sección "Modelo de datos" reescrita con la correspondencia focusId → goal_type.
- `test/profile/goals.e2e-spec.ts` — **nuevo**, 15 casos: los 6 focos del catálogo, 401/404/400,
  sobrescritura con una sola fila activa, aislamiento entre usuarios y no-interferencia con otros
  `goal_scope`.

Frontend — rama `fix/m1-rn-onb-020-foco-mes-guardado`:

- `expo/features/auth/ui/OnboardingFocoScreen.tsx` — el fallo de guardado ya no avanza de pantalla:
  muestra `AuthMessageBox` y permite reintentar. El 401 sigue yendo a login; "Continuar más tarde"
  sigue siendo el camino deliberado para no declarar foco.
- `expo/app/__tests__/onboarding-foco.test.tsx` — **nuevo**, 6 casos incluyendo los cuatro caminos
  de error.

### 7.3 Verificación

| Suite | Resultado |
|---|---|
| back — `test/profile/goals.e2e-spec.ts` | 15/15 |
| back — e2e completa | 83 pasan, 9 skip (preexistente), 0 fallos |
| back — unitarios | 122/122 |
| back — `tsc --noEmit` + eslint | limpio |
| front — `onboarding-foco.test.tsx` | 6/6 |
| front — suite completa | 120/120, 18 suites |
| front — `tsc --noEmit` + eslint | limpio |

### 7.4 Lo que no se tocó

- `/profile/financial` — congelado hasta M2 (§2).
- Estados `pendiente` / `sugerido` (H-A, H-B) e historia mensual (H-C): decisiones abiertas de §6.
- `goals_set` sigue excluido del cálculo de completitud, que es lo correcto (H-E). El comentario con
  el motivo vencido sigue ahí: cambiarlo pertenece a `RM1-12`.
