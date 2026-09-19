# Checklist previo a QA — onboarding G0→G5

**Fecha:** 2026-08-21 · **actualizado** 2026-08-22
**Base:** `back-walvy` main `99181b1` · `front-walvy` main `0cdf980`
**Para:** desarrollo, antes de entregar a QA

Esta lista **no es el plan de pruebas de QA**. Es lo que conviene verificar antes de entregar, para que QA no gaste una corrida encontrando un problema de ambiente o un camino roto. Orden pensado para cortar temprano: si falla el bloque 0, nada de lo demás tiene sentido.

Lo que entró el 21-08: back `#115` (TCR/CMF), `#116` (titularidad), `#117` (cierre del onboarding) · front `#61`–`#67`.

Lo que entró el 22-08: back `#119` (brechas G2: identidad del documento, CMF, deudas y reuso), `#121` (rechazo de documentos sin datos usables), `#122` (el 422 de Kread con el mismo mensaje) · front `#69` (retoma G4, picker Android, primera lectura sin color).

**Mapa de issues por puerta:** G2 → `#118` · G3 → `#123` · G4 → `#113` · G5 → `#124`. Transversales: `#68` (el cierre), `#114` (titularidad).

---

## 0 · Ambiente — cortar acá si algo falla

| # | Verificar | Esperado |
|---|---|---|
| 0.1 | `migration:run` sobre una base al día | Corre en este orden: `25000` supresión → **`25500` rename debt→debts** → `26000` document_kind → `27000` align → `28000` drop trigger → `30000` holder_match |
| 0.2 | `\d statement_imports` | Existen `document_kind` (NOT NULL, default `cartola`) y `holder_match` (nullable), con sus dos `CHECK` |
| 0.3 | Tabla `debts` (no `debt`) | El rename se aplicó y las FK de cronogramas y abonos siguen |
| 0.4 | `DOCUMENT_HOLDER_CHECK_ENABLED` | **Sin definir o en `false`** — es el default con el que se entrega |
| 0.5 | `DYNAMO_ENABLED=true` + tablas de dedup y tokens | Si está apagado, el dedup y el retén de rechazos no se prueban |
| 0.6 | `KREAD_BASE_URL` apunta a un Kread **con TCR y CMF** | Sin eso, los escenarios de tipo de documento no aplican |
| 0.7 | `DEV_TOOLS_ENABLED=true` en el ambiente de prueba | Habilita `POST /dev/reset-user`, que es lo que permite repetir el flujo |
| 0.8 | `GET /debts` con sesión | **200**, no `404`. `DebtsModule` se registró en `#119`: antes el import creaba filas `Debt` que nada podía listar ni confirmar |

**Al arrancar el backend, en el log:**

- 0.9 · `Verificación de titularidad deshabilitada (DOCUMENT_HOLDER_CHECK_ENABLED≠true) — holder_match queda en NULL`
- 0.10 · `GET /catalog/onboarding-parameters` devuelve `analysis_delay_soft_threshold_seconds: 45` y `analysis_delay_long_threshold_seconds: 90`

**Verificado el 22-08 sobre una base al día:** las diez migraciones pendientes corrieron en el orden de 0.1 —con la `25500` del rename antes de la `27000`— y el log de arranque trae el mensaje de 0.9.

---

## 1 · Camino feliz completo, una sola vez

Con una cartola real de un mes **ya cerrado** (para que el semáforo sea evaluable) y de un banco soportado.

| # | Paso | Verificar en la base |
|---|---|---|
| 1.1 | Bienvenida | `current_gate = G0_activacion` |
| 1.2 | Guardar foco | `current_gate = G2_carga`, `goals_set = true`, `last_completed_gate = G1_foco`, y una fila en `user_goals` con `goal_focus_code` y `goal_scope = monthly_focus` |
| 1.3 | Cargar el documento y analizar | `current_gate = G3_analisis` y **`import_attempted = true`** (esto es lo que arregló `#67`) |
| 1.4 | Termina el análisis | `statement_imports` en `parsed`, con `document_kind = cartola`; líneas en `import_line_items`; el objeto **ya no está en S3** |
| 1.5 | Pantalla de revisión | El semáforo viene del backend (`diagnosis.sufficiency`), y "Lo que detectamos" muestra los cinco indicadores |
| 1.6 | Comenzar diagnóstico | Primera lectura con su semáforo, señales y CTA dominante |
| 1.7 | **El cierre** | `onboarding_status = completed`, `last_completed_gate = G5_diagnostico`, `current_gate` nulo, `resume_state = completed`, `completed_at` con fecha, **`min_doc_threshold_met = true`** y **`financial_profile_completed` todavía en `false`** |
| 1.8 | Cerrar sesión y volver a entrar, dos veces | Va a **Home**, no al onboarding |
| 1.9 | Declarar una puerta con el onboarding cerrado (`PATCH /auth/onboarding/step`) | **409** |

Si 1.7 y 1.8 pasan, el defecto más viejo del flujo quedó cerrado. Si no, no vale seguir.

> **Aviso sobre el insumo, 22-08.** Este bloque **no se pudo completar todavía**, y no por un defecto: el cierre exige que la suficiencia llegue a `partial` o `sufficient`, y `compromisos_base` / `pagos_recurrentes` se resuelven sólo desde líneas de cartola con `flowType: 'fixed'`. Con cartola + estado de cuenta + informe CMF —12 deudas registradas— el gate queda en `insufficient / bloqueado` y el CTA dominante sigue siendo «cargar documento». **Hace falta una cartola con gastos fijos clasificados** (dividendo, cuota, seguro, suscripción) para ver 1.7 y 1.8 una sola vez. Detalle en `#124` §2 y `#113`.

---

## 2 · Los cambios recientes, uno por uno

Del 21-08 (§2.1–2.8) y del 22-08 (§2.9–2.10).

### 2.1 Titularidad (`#116`) — apagada

- Subir cualquier cartola → `holder_match` en **`NULL`** y `holderMismatchFiles` vacío; la pantalla de revisión se ve igual que antes.

### 2.2 Titularidad — encendida (`DOCUMENT_HOLDER_CHECK_ENABLED=true`, reiniciar)

- Cartola del propio RUT → `match`, sin aviso.
- Cartola de **otro** RUT → `mismatch`, el import **sigue quedando `parsed`** y la pantalla nombra el archivo en el aviso.
- Cartola sin titular legible → `unknown`, sin aviso.
- Cuenta conjunta donde el usuario es el segundo titular → `match`.
- **Revisar el log del import: ningún RUT, sólo el veredicto.**
- Volver a apagar la bandera antes de entregar.

### 2.3 Contraseñas (`#64`)

- PDF protegido que **no** abre con el RUT → pedirla a mano, verificar, analizar.
- **En web, mirar la URL al pasar a "analizando": ninguna contraseña.**
- **Y mirar también la URL al pasar de "analizando" a la revisión.** Ese segundo salto **hoy sí filtra la contraseña** (ver §4): es defecto conocido, no algo que QA deba descubrir.
- Provocar contraseña incorrecta en el upload → vuelve a pedirla y el reintento funciona.
- Salir a Home a mitad de la carga y volver → la lista pide la contraseña de nuevo.

### 2.4 Validaciones simétricas (`#63`)

- Archivo > 30 MB desde la pantalla de carga → se descarta con aviso.
- El **mismo archivo** desde "Cargar más documentos" de la revisión → **mismo comportamiento**. Este es el punto del PR.
- `cartola_may_2025.pdf` → avisa que podría estar vencida y **la sube igual**.

### 2.5 TCR y CMF (`#115`)

- **Sólo** estado de cuenta → `document_kind = estado_cuenta`, una `Debt` `unconfirmed`, y el gate bloquea por **`ingreso_faltante`** (no por `sin_documento`).
- **Sólo** informe CMF → `document_kind = cmf_deuda`, N deudas, bloqueo por ingreso **y** movimientos.
- CMF de alguien **sin deuda vigente** → import `parsed` **sin deudas**. No es error.
- **El guard de duplicados:** cartola + TCR + CMF donde la misma tarjeta aparece con el **mismo saldo** en los dos últimos → **una sola `Debt`**.
- En la lista del front, los documentos de deuda muestran su etiqueta ("Estado de cuenta" / "Informe CMF") y la cartola no.

### 2.6 Análisis: timeout y retoma (`#67`)

- Lote con un documento lento: al vencer el timeout, **los siguientes se suben igual** y el modal no muestra el error genérico.
- Salir durante el análisis y volver a entrar → retoma **ese** job, no el import más reciente.
- Forzar un fallo transitorio → el modal ofrece **Reintentar**, **Volver a revisión** y Volver al home.

### 2.7 Primera lectura sin color (`#66`)

- Cartola de un mes **en curso**, sin mes cerrado anterior → **"Sin semáforo por ahora"** con sus señales y su CTA. **No** la pantalla de error con Reintentar.

### 2.8 Dedup y retén de rechazos

- Subir dos veces el mismo archivo → el segundo reusa el import, no reprocesa, **y ahora lo avisa** (`reused: true` → `mensajeArchivoReusado`).
- Subir un documento que Kread no pueda leer, y volver a subirlo → queda `failed` con el motivo guardado, **sin volver a someterlo a Kread**.
- **Hacer las dos pruebas con un PDF protegido con contraseña**, no sólo con uno abierto. Hasta `#119` la identidad del documento se calculaba sobre la salida de qpdf, que cambiaba en cada corrida: para un PDF con clave el dedup y el retén de rechazos no funcionaban, y subir dos veces la misma cartola dejaba dos imports con las mismas líneas contadas dos veces. Es el caso normal de una cartola chilena, así que es el que hay que probar.

### 2.9 Documentos que Kread procesa pero no sirven (`#121`, `#122`)

- Subir un PDF que no es un documento financiero (un horario, un comprobante) → `failed` con el copy propio «Este archivo no nos sirvió», **no** el mensaje genérico de contraseña ni uno de falla transitoria.
- Lo mismo cuando Kread responde `422` porque no reconoce el tipo (`#122`): mismo mensaje, y **sin** reintentos infinitos.

### 2.10 Retoma de la revisión (`#69`)

- Cerrar sesión estando en G4 y volver a entrar → la tarjeta «Tus documentos» **se reconstruye** desde `listImports()`, con su tipo de documento, y el resumen se vuelve a pedir. No `0/15`.
- Incluye los imports en `pending`/`processing`, no sólo los `parsed`.
- **Caso que todavía falla:** la retoma por `resumeContext.jobId` navega con `importIds` y sin `docs`, y ahí la lista sí queda en `0/15` (ver §4).
- Picker en Android: seleccionar un archivo con extensión válida y mimetype raro → se acepta y se normaliza; uno no admitido → se rechaza con aviso, nombrando el archivo.

---

## 3 · Repetir el flujo

`POST /dev/reset-user` con el correo. Es lo único que purga DynamoDB, así que es preferible a la vía SQL. La receta manual y qué no limpia están en `specs/wiki/queries-db/resetear-onboarding-al-welcome.md`.

Después de resetear, confirmar que el usuario **vuelve a la bienvenida** y no a Home: `current_gate = G0_activacion` y `onboarding_status = in_progress`.

**Dos cosas que el reset de main todavía no purga**, y que contaminan la corrida siguiente:

- Las filas de `user_month_diagnosis_summary`. `recomputeAllMonthsForUser` sale temprano cuando el usuario ya no tiene imports `parsed`, así que el diagnóstico de la corrida anterior queda vigente y Home sigue mostrando la lectura de una cartola que ya no existe.
- Las seis columnas de presión del diagnóstico en `user_onboarding_state` (`pending_best_action`, `sufficiency_status`, `dominant_cta_code` y compañía), que las escribe `syncOnboardingPressure` y no el flujo de puertas.

Mientras eso no esté, **entre corrida y corrida conviene borrarlas a mano** o usar un usuario nuevo. Ambas purgas están resueltas en la rama del arnés (§5.1).

---

## 4 · Lo que NO conviene mandar a QA todavía

### 4.1 Sigue sin resultado esperado formal

| Qué | Por qué |
|---|---|
| Los cuatro escenarios de carga mixta (E1–E4 del cuadro de `#113`) | Dependen de Q1–Q3 y de las filas `ADM-08`–`ADM-12`, que están con el PO. Se pueden ejecutar y observar, pero `M1-DP-008` prohíbe extrapolar. **El lado de deudas sí es verificable** desde `#119`: el CMF registra sus operaciones con el tipo correcto y `/debts` responde |
| El copy del aviso de titularidad | Provisional, sin nodo de Figma. Por eso la bandera va apagada (`#114`) |
| El copy de "Sin semáforo por ahora" | Igual: sin frame (`#124` §3.3) |
| `ADM-07` a nivel de API | El límite de 15 documentos vive sólo en el cliente. Por la app pasa; contra la API no existe (`#118`, decisión 2) |
| Las variantes `M1-V49` vs `M1-V50` | «Parcial permitido» y «parcial bloqueado» no tienen etiqueta acordada en el producto, así que no son distinguibles por separado (`#124` §3.4) |

### 4.2 Defectos conocidos — que QA no los descubra

Estos ya están identificados y no conviene gastar una corrida de QA en ellos.

| Qué | Dónde | Referencia |
|---|---|---|
| **La contraseña del PDF viaja por los params de navegación** en el salto análisis → revisión. En web queda en la query string, con historial y referer. Regresión de `M1-DP-003` / `M1-V41` | front | `#118`, brecha nueva 1 |
| «Analizar mis documentos» **no tiene retén de doble toque**: un segundo toque apila otra pantalla de análisis con su propia cola de subida | front | `#118`, brecha nueva 2 |
| Las filas que llegan a la revisión **no llevan su `importId`**, así que quitar un documento lo saca de la lista y el resumen lo sigue contando | front | `#118`, brecha nueva 3 |
| La retoma por `resumeContext.jobId` deja la tarjeta en `0/15` | front | `#123` §3.2 |
| **El aviso al terminar el análisis no existe**, y `#95` se cerró como completado el 21-08 sin comentario. Los tres copys siguen prometiéndolo y `src/imports` no toca el módulo de notificaciones | ambos | `#123` §3.1 |
| La verificación de titularidad **sólo corre para cartolas**: un estado de cuenta o un informe CMF de un tercero no se verifica, ni con la bandera encendida | back | `#114` |
| La contraseña se pasa a qpdf como argumento de línea de comandos, visible en la tabla de procesos | back | `#118`, brecha 6 |
| `failure_reason` tiene tres valores para siete causas distinguibles | back | `#118` decisión 3, `#123` §3.3 |

---

## 5 · Verificación automática, antes de entregar

En los dos repos, con los comandos del CI:

```
pnpm run lint                 # --max-warnings=0, prettier incluido
pnpm run build
pnpm test                     # con caché limpio: --cacheDirectory=/tmp/jc
```

Estado al 21-08: **back `ffcf4d3`** 40 suites / 406 tests · **front `b337bdb`** 31 suites / 246 tests.
Estado al 22-08: **back `99181b1`** 43 suites / 441 tests, `tsc` limpio · **front `0cdf980`** pendiente de medir en local.

El caché de jest sirve specs viejos después de un rebase y esconde errores de tipos que el CI sí ve: correr siempre con `--cacheDirectory` nuevo antes de dar algo por verde.

### 5.1 Arnés de puertas

`scripts/onboarding-puertas.mjs` recorre G0→G5 contra la API real y **afirma** el estado esperado en cada puerta, citando la regla que respalda cada afirmación. Sale con código 1 si algo no calza. Sin `WALVY_EMAIL` registra un usuario desechable, así que no necesita credenciales de nadie ni pisa la cuenta con la que se está probando en el teléfono.

```
cd back-walvy && CMF_PDF=<ruta al informe CMF> PDF_PASSWORD=<clave> \
  node scripts/onboarding-puertas.mjs completo
```

| Escenario | Qué cubre |
|---|---|
| `completo` | G0→G5 con cartola + estado de cuenta + CMF, hasta el cierre. Afirma las seis escrituras de 1.7 |
| `bloqueado` | Sólo cartola; deja al usuario detenido en G4, que es el estado desde el que se prueba la retoma real en la app |
| `retomas` | Recorre G0…G4 sin documentos y verifica a qué pantalla mandaría el login en cada puerta, incluida la pausa explícita |
| `dedup` | El mismo archivo dos veces. **Es el que cubre §2.8** y el que falla si la identidad del documento vuelve a ser inestable |
| `no-repite` | El `409` de la fila 1.9 |

Todavía **no está en main** (rama `chore/arnes-puertas-onboarding`), así que hoy no es reproducible por el resto del equipo.
