# Diagnóstico del Onboarding — Flujo C contra la documentación del cliente

**Fecha:** 2026-08-12
**Alcance:** los cuatro endpoints del `🧭 Flujo C — Onboarding (primera vez)` del Postman
`GET /auth/onboarding` · `PATCH /auth/onboarding/step` · `POST /statement-imports/upload` · `POST /profile/goals`

**Código revisado:** `walvy-org/walvy-app-backend` rama `main`, SHA `dd084c7`.
**Fuentes:** `Walvy_M1_Matriz_Trazabilidad_Cliente_v2.6.xlsx` (Drive `1MRRKk-hNZT0HUFios8WT2Tsrz3vkd5is`),
`Walvy_Assessment_Validacion_M01_v1.1 (diferido_onboarding).xlsx` (Drive `1Fd6r5xbaEl6CjEZWZd13nyXHNW1umJVt`),
tablero `KabeliDev/projects/10`.

---

## 1. El tamaño real del hueco

La matriz v2.6 dedica **34 de sus 60 variantes** al onboarding: `M1-V27` a `M1-V60`, agrupadas en siete subflujos —
Bienvenida, Foco del Mes, Carga documental, Procesamiento, Suficiencia, Diagnóstico y Retoma.
Las gobiernan **25 reglas** `M1-RN-ONB-001..025` y **13 reglas de assessment** `M01-RGL-005..019`.

El backend implementa, de ese conjunto, la **mecánica de transporte**: subir un PDF, mandarlo a Kread, guardar
las líneas clasificadas, y un par de flags booleanos que el cliente declara por su cuenta.

Lo que **no existe** es la capa que la documentación considera el onboarding propiamente tal:

| Concepto del cliente | Regla | ¿Existe en backend? |
|---|---|---|
| Gate de suficiencia (`complete` / `partial permitido` / `partial bloqueado` / `blocked`) | `M01-RGL-012`, `AX-M1-003` | ❌ |
| Trazabilidad por indicador (estado, origen, confianza, evidencia) | `M1-RN-ONB-008`, `M01-RGL-013` | ❌ |
| Estado financiero canónico (ratio egreso/ingreso sobre snapshot mensual) | `AX-M1-004`, `M01-RGL-015` | ⚠️ hay un cálculo, con otros umbrales |
| Presión dominante única + CTA dominante | `M1-RN-ONB-011/012`, `M01-RGL-015` | ❌ |
| Umbrales de demora del análisis (45 s / 90 s) | `M1-RN-ONB-013`, `M01-RGL-014` | ⚠️ sembrados en BD, nadie los lee |
| Retoma sin reinicio desde el punto de mayor valor | `M1-RN-ONB-014`, `M01-RGL-008` | ❌ |
| Cierre del onboarding = persistir la primera lectura | `M1-RN-ONB-016`, `M01-RGL-016` | ❌ (cierra por otra condición) |
| `rule_version` / `evaluated_at` en cada evaluación | `M1-RN-ONB-018` | ❌ |
| Eventos mínimos de carga/análisis/diagnóstico/CTA/pausa/cierre | `M01-RGL-017` | ❌ |

**La base de datos sí tiene dónde guardar casi todo esto** — `user_month_diagnosis_summary` trae
`rule_version`, `traffic_light_status`, `sufficiency_status`, `dominant_pressure_code`, `dominant_cta_code`
y un CHECK que enumera nueve `dominant_cta_type`. No hay entidad TypeORM que la toque. La capacidad está
en el esquema; el alcance no está en el código.

---

## 2. Endpoint por endpoint

### 2.1 `GET /auth/onboarding` — `auth.controller.ts:211`

Devuelve nueve campos de `user_onboarding_state`: `onboardingStatus`, `currentStep`, `resumeSurface`,
`resumeContext`, los cinco checkpoints booleanos y `completedAt`.

**Qué falla**

1. **Siete columnas de la entidad no se exponen ni se escriben nunca**: `currentGate`, `lastCompletedGate`,
   `resumeState`, `pendingBestAction`, `diagnosticStatus`, `sufficiencyStatus`, `generalTrafficLightStatus`,
   `dominantPressureCode`, `dominantCtaCode`. Verificado por `git grep`: sólo aparecen en la declaración de
   la entidad. Son exactamente los campos que `RM1-16` a `RM1-20` piden poblar.
2. **404 cuando no hay fila.** El front lo trata como "primer acceso" (`useLoginForm.ts:187`). Un 404 no
   distingue "usuario nuevo" de "fila perdida"; la decisión de ruta post-login (`M1-V02`, ajuste del PO)
   depende de este contrato.
3. **No expone nada de retoma real.** `M1-RN-ONB-014` y `M01-RGL-008` piden retomar "desde el punto de mayor
   valor pendiente", recuperando checkpoint, selección documental, job y resultado. Hoy `resumeSurface` es un
   string libre que escribe el cliente.

### 2.2 `PATCH /auth/onboarding/step` — `user-onboarding.service.ts:31`

Este es el problema estructural del módulo.

**El servidor no decide nada: transcribe lo que el cliente le declara.** Los cinco checkpoints se escriben
tal cual vienen en el body. De los cuatro que componen la condición de cierre, sólo `biometricPrompted`
tiene una escritura de servidor (`updateBiometric`). `financialProfileCompleted`, `importAttempted` y
`minDocThresholdMet` **no los escribe nadie más que el propio cliente** vía este PATCH.

Consecuencias concretas:

1. **`currentStep` acepta cualquier string** — el DTO sólo valida `@IsString()`. No hay registro de pasos.
2. **La condición de cierre no es la del cliente.** El código cierra con
   `financialProfileCompleted && importAttempted && biometricPrompted && minDocThresholdMet`
   (`user-onboarding.service.ts:52-57`), con `goalsSet` explícitamente excluido por comentario.
   `M01-RGL-016` dice otra cosa: *"Persistir la primera lectura, cerrar el onboarding y aterrizar en
   Home/Inicio de M01"*, y `M1-RN-ONB-016`: *"El onboarding se cumple al mostrar diagnóstico inicial y
   próxima acción"*. **El cierre debe colgar del diagnóstico, no de cuatro banderas.**
3. **`financialProfileCompleted` es un requisito de M2 metido en el cierre de M1.** El Perfil Financiero es
   frontera `RM1-22`. Con la condición actual, M1 no puede cerrar sin un artefacto de M2.
4. **Un cliente puede autocompletarse el onboarding** con un solo PATCH poniendo los cuatro flags en `true`,
   sin haber subido un documento. Es la contracara de que el servidor no valide nada.

Esto es el issue **#68** del tablero, aunque su enunciado se queda corto: no es sólo que "nunca llega a
completed", es que **el modelo de estado completo es declarativo cuando la documentación lo pide derivado**.

### 2.3 `POST /statement-imports/upload` — `statement-import.controller.ts:56`

Es la parte mejor construida: hash SHA-256 del contenido, dedupe en Dynamo con reserva/confirmación,
submit a Kread en background, retry sobre el mismo registro, cancelación, desbloqueo de PDF con contraseña.

**Divergencias con la documentación**

| Punto | Documento | Código |
|---|---|---|
| Cantidad de documentos | máx. 15 (`M1-RN-ONB-021`) | 1 por request |
| Formatos | PDF / Excel / CSV | sólo `application/pdf` |
| Tamaño | hasta 30 MB | 10 MB (`limits.fileSize`) |
| Contraseña automática por RUT | tres variantes, en orden (`M1-DP-003`) | dos, en orden inverso — issue **#62** |
| Documento no procesable vs fallo técnico | *"no debe mezclarse"* (`M1-DP-005`) | ambos terminan en `status='failed'` |
| Fallo determinista | conservar huella/motivo/versión para bloquear reproceso idéntico (`M1-DP-004`) | `handleProcessingFailure` llama `releasePending` siempre → se puede resubir el mismo archivo inútil sin límite |
| Documento desactualizado | no debe mejorar la suficiencia (`M1-RN-ONB-023`, `M1-V42`) | no existe el concepto de vigencia de período |
| Umbrales de demora 45 s / 90 s | `M1-RN-ONB-013`, `M1-V45`/`V46` | sembrados en `rule_parameter` (migración `...014000`), ningún consumidor |
| Salir durante el análisis sin perder el job | `M1-V60`, `M01-RGL-008` | no hay estado de retoma asociado al import |

Los límites de la fila 1-3 vienen marcados en la matriz como *"deben ratificarse técnicamente antes del
cierre"*: no son necesariamente defectos, pero **hay que cerrarlos por escrito o corregirlos**.

Y el upload **no toca el estado de onboarding**: no marca `importAttempted` ni evalúa `minDocThresholdMet`.

### 2.4 `POST /profile/goals` — `goals.controller.ts:32`

Guarda un `UserGoal` activo con el `goalType` = uno de los seis focos. El catálogo de seis coincide
exactamente con `M1-RN-ONB-020` (bajar deuda, ahorrar un monto, aumentar margen, evitar atrasos, cumplir
presupuesto, ordenar compromisos). Eso está bien.

**Qué falta**

1. **No modela los tres estados del foco** que exige `M1-RN-ONB-019`: *declarado*, *no declarado*,
   *inferido/sugerido*. Hoy sólo existe "declarado". Las columnas para distinguirlos ya están en
   `user_goals` (`goal_scope`, `goal_focus_code`, `goal_priority`, `goal_status`) y ninguna se usa.
2. **`M1-V29` (foco no declarado) está marcada "Ajustar" por el PO**: *"si el usuario posterga la selección
   de foco, debe conservarse el estado pendiente y aplicarse la salida de postergación; no corresponde
   describir esta acción como avance directo a carga documental"*. No hay estado pendiente que conservar.
3. **`M1-V30` (foco sugerido)** tiene decisión de Producto cerrada — prioridad M04 → M06 → M05, CTA
   *"Usar este foco"* — pero `RB-FM-004` advierte que *"la selección específica del foco requiere una lógica
   determinista de Producto todavía pendiente"*. Es el issue **#52** del tablero.
4. **No aplica el guardrail `RB-FM-002`/`RB-FM-005`**: *"una señal crítica de salud financiera siempre
   prevalece sobre el foco declarado"*. Sin motor de presión/CTA, no hay dónde aplicarlo.
5. **No escribe `goalsSet`.** El servicio de goals y el de onboarding no se hablan.
6. El comentario del DTO dice *"definidos con el frontend"*; el catálogo es del cliente
   (`M1-RN-ONB-020`, Figma `6670:13227`). Conviene citar la regla, no al front.

---

## 3. El semáforo: la divergencia numérica

`computeSummary` (`statement-import.service.ts:609`) calcula
`ratio = totalExpense / totalIncome` y devuelve `green` si `< 0.8`, `yellow` si `< 1.0`, `red` si no.

`AX-M1-004` fija la regla canónica:

| Estado | Condición del cliente | Código |
|---|---|---|
| En control | ratio **< 0,90** | `< 0.80` ❌ |
| Atención | 0,90 ≤ ratio < 1,00 | 0,80 ≤ r < 1,00 ❌ |
| Riesgo | ratio ≥ 1,00 **o `mora_confirmada`** | ratio ≥ 1,00, sin override ❌ |
| Sin diagnóstico | no hay base suficiente | **no existe** ❌ |

Tres problemas encadenados:

1. **El umbral verde está en 0,80 y debe estar en 0,90.**
2. **No existe el cuarto estado.** Cuando `totalIncome` es 0, el código hace `ratio = 1` y pinta **rojo**.
   `M1-RN-ONB-010` lo prohíbe explícitamente: *"La insuficiencia produce Sin diagnóstico/bloqueo, no un
   estado rojo financiero"*, y `M1-V56` insiste: *"No usar rojo por falta de información"*.
   **Hoy un usuario cuya cartola no trae ingresos detectables ve Riesgo.**
3. **El ratio no es el canónico.** El cliente pide *egreso mensual proyectado / ingreso mensual reconocido*
   sobre el **snapshot mensual**; el código suma todo lo que venga en los PDFs cargados, sin recorte de
   período ni proyección.

Y el resultado **no se persiste**: vive en la respuesta de `/summary`, sin `rule_version` ni `evaluated_at`
(`M1-RN-ONB-018`, issue **RM1-21**), pese a que `user_month_diagnosis_summary` existe para eso.

---

## 4. Qué cubre el tablero y qué no

Sí hay tareas. El épico es **RM1-00** y la franja de onboarding va de **RM1-11** a **RM1-22**:

| Issue | Título | Estado |
|---|---|---|
| #31 RM1-11 | Continuidad a Onboarding Welcome y modelo de estado | In Progress |
| #32 RM1-12 | Activación del onboarding y Foco del Mes | Todo |
| #33 RM1-13 | Carga documental y ruta preferente (Kread) | Todo |
| #34 RM1-14 | Estados de procesamiento y umbrales de demora | Todo |
| #35 RM1-15 | Documento no procesable y carga insuficiente | Todo |
| #36 RM1-16 | Revisión de indicadores y trazabilidad del dato | Todo |
| #37 RM1-17 | Suficiencia y modos de diagnóstico | Todo |
| #38 RM1-18 | Semáforo general del onboarding | Todo |
| #39 RM1-19 | Presión principal única y CTA dominante | Todo |
| #40 RM1-20 | Retoma sin reinicio y cierre con valor | Todo |
| #41 RM1-21 | Versionamiento (`rule_version` / `evaluated_at`) | Todo |
| #42 RM1-22 | Frontera M1 ↔ M2 — salida a Perfil Financiero | Todo |

Más los hallazgos sueltos: **#68** (el onboarding nunca cierra), **#52** (foco sugerido), **#62** (variantes
de contraseña por RUT), **#48 front** (5 pantallas de foco sin diseñar), **#70** (las 12 reglas nuevas de la
v2.6 nunca se bajaron a las tarjetas).

**El hueco del tablero:** RM1-11..RM1-22 son tarjetas de **revisión de conformidad**, no de implementación.
Producen veredictos. No existe todavía el backlog de construcción — que es lo que sale de **#46 RM1-26**
(*Informe consolidado y backlog de remediación*, In Progress). Y **#70** confirma que el alcance de las
tarjetas está desactualizado respecto de la v2.6.

---

## 5. Decisiones que siguen abiertas y bloquean

1. **Catálogo de `dominant_pressure_code`.** `M01-RGL-015` gobierna la presión dominante pero **ni la matriz
   ni `AX-M1-004` enumeran sus valores**. Sin catálogo no se puede implementar `RM1-19`.
   (El CHECK de `user_month_diagnosis_summary.dominant_cta_type` sí trae nueve valores candidatos para el
   CTA — sirve como propuesta a validar, no como fuente.)
2. **Vocabulario de suficiencia.** La columna declara `sufficient | partial | insufficient | blocked`;
   `AX-M1-003` produce `blocked | partial | complete`. Hay que reconciliar `sufficient` ↔ `complete` y
   decidir qué pasa con `insufficient`, más el matiz *partial permitido* vs *partial bloqueado* que la
   columna no distingue.
3. **Ratificación de los límites de carga** (15 documentos / PDF-Excel-CSV / 30 MB) — o corregir el código,
   o justificar la desviación por escrito, como pide la matriz.
4. **Qué significa `financialProfileCompleted` para M1** — `RM1-22`, frontera con M2.

---

## 6. Orden de trabajo propuesto

**Ola 1 — cerrar el modelo de estado (desbloquea todo lo demás)**
- Invertir la dirección de `PATCH /auth/onboarding/step`: el servidor deriva los checkpoints de hechos
  observables (hay import parseado → `importAttempted`; el gate de suficiencia dice `complete`/`partial
  permitido` → `minDocThresholdMet`; hay foco activo → `goalsSet`). El PATCH queda para navegación y
  postergación, no para declarar completitud.
- `@IsIn()` sobre `currentStep` con el registro de pasos derivado de `M1-V27..V60`.
- Reemplazar la condición de cierre por la de `M01-RGL-016`: primera lectura persistida.
- Sacar `financialProfileCompleted` del cierre de M1 hasta resolver `RM1-22`.

**Ola 2 — suficiencia y diagnóstico**
- Normalizar cada indicador a `sufficient | pending | missing` con origen, confianza y evidencia.
- Implementar `M01-RGL-012` como gate único con sus cuatro salidas y sus `reasons`.
- Corregir el semáforo a los umbrales canónicos, agregar **Sin diagnóstico** y el override `mora_confirmada`.
- Persistir en `user_month_diagnosis_summary` con `rule_version` y `evaluated_at`.

**Ola 3 — carga documental y procesamiento**
- Separar `no procesable` de `fallo técnico transitorio` en el estado del import.
- Huella persistente para el fallo determinista (`M1-DP-004`).
- Consumir los umbrales 45/90 s desde `rule_parameter` y exponer el estado de demora en `/status`.
- Vigencia de período del documento (`M1-RN-ONB-023`).
- Tercera variante de contraseña por RUT y orden correcto (#62).

**Ola 4 — foco, presión y retoma**
- Tres estados del foco, con postergación que conserva el pendiente.
- Presión dominante y CTA — **bloqueado** hasta que exista el catálogo de `dominant_pressure_code`.
- Retoma desde el punto de mayor valor, con `resumeState` real.
- Eventos mínimos de `M01-RGL-017`.

---

## 7. Nota de método

Las 34 variantes traen una columna de **Decisión PO** que rectifica el texto de la regla. Varias de ellas
(V29, V30, V41, V43, V44, V47, V50, V52, V53, V54, V55) cambian el comportamiento esperado respecto de lo
que dice la columna "Comportamiento esperado". Leer sólo la regla produce divergencias falsas —lección ya
registrada en `2026-08-11-cruce-matriz-assessment.md`— y también divergencias omitidas.
