# Contexto — correo de Jose Miguel del 11-ago: dónde queda la evidencia de Seguridad y Privacidad

**Fecha:** 2026-08-13
**Origen:** correo de Jose Miguel Rodriguez del 2026-08-11 07:28 (a Ana, con copia a Miguel, Andrea, Jeaninne, Victoria, M. Ángel Tort, Eduardo)
**Baseline de código:** back-walvy `walvy/main` `073c523` (2026-08-13, *fix(release): align DEV image with ECS arm64* #83)
**PR abiertos considerados:** #72, #73, #74, #81 — ver §2b. Todo lo marcado como estado "en `main`" excluye estos PR salvo indicación expresa.
**Fuentes Drive** (carpeta `1sUPEYdV1dPVuG4djcGX3NsnYGKoMVEPi`):
- `Walvy_Assessment_Validacion_M01_v1.1 (diferido_onboarding).xlsx` — `1Fd6r5xbaEl6CjEZWZd13nyXHNW1umJVt` (v1.22 interna)
- `Walvy_M1_Matriz_Trazabilidad_Cliente_v2.6.xlsx` — `1MRRKk-hNZT0HUFios8WT2Tsrz3vkd5is`
- `Plan_Pruebas_Integral_Modulo1_iOS_Android.pdf`, `Plantilla_ReleaseNote_QA.pdf`, informes de ejecución iOS/Android

**Documentos propios que ya cubren parte de esto:** [`2026-08-13-estado-controles-seguridad-bd.md`](2026-08-13-estado-controles-seguridad-bd.md) (13 controles con evidencia + 14 brechas), [`2026-08-11-cruce-matriz-assessment.md`](2026-08-11-cruce-matriz-assessment.md), [`../../../../entregas/correo-a-jose-miguel-final-20260812.md`](../../../../entregas/correo-a-jose-miguel-final-20260812.md).

---

## 1 · La pregunta ya tiene respuesta en el propio Assessment

Jose Miguel pregunta: *"¿dónde quedará reflejada esta evidencia: matriz, casos de prueba, evidencias QA, tickets técnicos o documentación complementaria?"*.

**No es una disyuntiva: el Assessment v1.1 ya define las cinco capas y cada una tiene su hoja.** La respuesta correcta es citar la estructura que él mismo aprobó, no proponer una nueva.

| Capa | Hoja del Assessment | Qué registra |
|---|---|---|
| Catálogo de controles | `04_Privacidad_Seguridad` | 19 controles Priv/Sec con gate, criterio de cierre, tipo de validación, **evidencia requerida**, responsable y caso asociado |
| Contratos y parámetros congelados | `09_Contratos_PrivSec` | Contrato mínimo de eventos, parámetros de identidad (TTL, intentos, rate limit), manifest legal, matriz de autorización, manifests de datos QA |
| Registro oficial de ejecución | `03_Casos_Prueba_M01` | Estado de ejecución, resultado QA, severidad, **ticket Jira**, observaciones — 49 casos `TC-M01-001..049` |
| Ubicación física de la evidencia | `10_Evidencia_Readiness` | Por caso: `Evidencia ID` (`EVD-TC-M01-0NN`), formato mínimo, **ruta `Jira/<ticket>/TC-M01-0NN/`**, owner, ambiente/build, readiness |
| Remediación y revalidación | `11_Remediacion_Global` / `12_Revalidacion_Global` | Hallazgo → decisión aplicada → evidencia → residual → resultado |

Distribución de los 19 controles: **10 cierre M01 · 6 antes de producción · 3 deuda técnica controlada**.

El dictamen de `12_Revalidacion_Global` ya dice lo que hoy bloquea: `C-GLOBAL-05` está *"Cumple con prerrequisitos"* y su residual es **"Completar manifests/config/accesos"**. Es decir: la estructura documental está cerrada; lo que falta es materializar manifests, congelar parámetros y dar acceso técnico. Eso es exactamente lo que este documento aporta desde el código.

---

## 2 · Mapa punto por punto del correo

Los nueve puntos que lista Jose Miguel mapean 1-a-1 contra controles ya existentes. Ninguno es nuevo.

| # | Punto del correo | Control | Gate | Caso | Estado real en `main` `073c523` |
|---|---|---|---|---|---|
| 1 | Versión exacta aceptada de Términos/Política | `M01-PRV-002` | Cierre M01 | TC-M01-035 | ⚠️ **Modelo de datos resuelto en PR #74** (sin mergear); falta capa de aplicación |
| 2 | Separación obligatorias/opcionales, sin aceptación directa | `M01-PRV-003` | Cierre M01 | TC-M01-036 | ❌ **Contradicho por el código** |
| 3 | Hash adaptativo, salt y parámetros documentados | `M01-SEC-001` | Preproducción | TC-M01-037 | ✅ Implementado y evidenciable hoy |
| 4a | Validación de OTP y recuperación | `M01-SEC-002` | Cierre M01 | TC-M01-038/048 | ⚠️ Implementado, **asimétrico** entre los dos OTP |
| 4b | Rate limiting | `M01-SEC-004` | Preproducción | TC-M01-040 | ⚠️ Existe, **dimensión equivocada** |
| 4c | Prevención de enumeración | `M01-SEC-003` | Cierre M01 | TC-M01-002/039 | ⚠️ Login OK; **dos fugas fuera del login** |
| 5 | Sesiones: refresh, logout, logout all, expiración, revocación, replay | `M01-SEC-005` | Preproducción | TC-M01-041 | ⚠️ Comportamiento OK, **modelo de datos insuficiente** |
| 6 | Logs sin secretos ni identificadores directos | `M01-LOG-001` | Preproducción | TC-M01-029 | ❌ **Sin contrato de eventos ni auditoría** |
| 7 | Archivos: extensión, MIME real, límites, rechazo seguro | `M01-DOCSEC-001/002` | Cierre M01 / Preprod | TC-M01-045/046 | ⚠️ **MIME declarado, no real** |
| 8 | Datasets sintéticos o seudonimizados en QA | `M01-DEV-001` | Cierre M01 | TC-M01-043 | ✅ Implementado; falta el manifest |
| 9 | Eliminación de cuenta y derechos del titular | `M01-PRV-004/005` | Deuda técnica | DEBT-PRV-004/005 | ❌ No existe (ya aceptado como deuda) |

### Detalle por control

**1 · `M01-PRV-002` — versionamiento legal.** En `main` la BD sólo tiene dos columnas de fecha en `app_user`: `accepted_terms_at` y `accepted_privacy_at` (`migrations/1786000004000-BaselineIdentidadAcceso.ts:48-49`). Ninguna de las 87 tablas del baseline registra versión de artefacto legal, así que hoy sólo se acredita *cuándo* aceptó, nunca *qué versión*.

**PR #74 resuelve el modelo de datos y cubre los nueve campos del control** — ver §2b. Lo que sigue abierto es la capa de aplicación: el PR trae sólo la migración, así que ninguna entidad, servicio ni endpoint escribe todavía en las tablas nuevas, y `register` sigue sellando las dos fechas de `app_user`.

**2 · `M01-PRV-003` — aceptación con apertura y lectura.** El control dice textual: *"Las aceptaciones obligatorias no pueden registrarse directamente desde el formulario"*. El backend hace exactamente lo contrario: `RegisterDto` recibe dos booleanos `acceptTerms`/`acceptPrivacy` (`auth/dto/register.dto.ts:51,55`) y `AuthService.register` los sella con `now` sin ninguna noción de apertura, scroll ni versión (`auth/auth.service.ts:59-68,93-94`). No es una brecha de evidencia: es una divergencia funcional. Y arrastra la alerta ya enviada el 12-ago — los textos legales siguen siendo plantilla genérica con `"[Nombre de la Empresa]"`.

**3 · `M01-SEC-001` — contraseñas.** Cerrado y documentado: bcrypt con **12 rondas** (`users/users.service.ts:25,71`), tope de 72 bytes validado en DTO para que bcrypt no trunque en silencio (`common/validators/max-bytes.validator.ts:15`), columna `password_hash` con `select: false`, y el parámetro está escrito en la propia migración: `COMMENT ON COLUMN app_user.password_hash IS 'Hash bcrypt ≥12 rondas...'`. Evidencia entregable hoy sin ejecutar nada.

**4a · `M01-SEC-002` — OTP.** Ambos OTP son de 6 dígitos con distribución uniforme (`crypto.utils.ts`), se guardan **hasheados con SHA-256** —nunca en claro—, son de un solo uso y un código nuevo invalida el anterior. La asimetría: la **verificación de correo ya cumple `AX-M1-001` completo** (TTL 10 min, cooldown 60 s entre envíos, 5 envíos por ventana de 15 min, intentos acumulados, cooldown de 15 min al superar el límite — `email-verification.service.ts:21-24,147-169,215-218`), mientras que la **recuperación de contraseña no**: TTL 15 min, sin cooldown, sin tope de envíos, y los intentos se reinician con cada código nuevo (`password-management.service.ts:14,39,43-47`).
> ⚠️ Esto **corrige** la tabla del [cruce del 11-ago](2026-08-11-cruce-matriz-assessment.md#3-ax-m1-001--confirmado-textual-y-con-una-salida-que-no-teníamos), levantada sobre `dd084c7`. El endurecimiento entró después, en #71.

**4b · `M01-SEC-004` — rate limiting.** `ThrottlerGuard` a nivel de router (`auth.controller.ts:37`) con **5/min en login y forgot-password** (líneas 91, 118) — el valor exacto que pide el contrato. También 5/min en `reset-password` (línea 128) y 10/min en `verify-reset-code`. Dos observaciones para el manifest: la **dimensión efectiva es IP**, y `AX-M1-001` pide *"al menos por cuenta/correo"*; y **`/auth/register` no tiene throttle propio**, cae al global de 100/min (`app.module.ts:70`).

**4c · `M01-SEC-003` — enumeración.** El login está correcto: `'Credenciales inválidas'` idéntico para usuario inexistente y contraseña errada (`auth.service.ts:124,132`), y `forgot-password` responde el mensaje genérico y **envía el correo sin `await` a propósito**, con el comentario que explica que esperar el envío delataba la rama del correo registrado (`password-management.service.ts:31-37,64-68`). Quedan dos fugas fuera del login:
- `POST /auth/register` devuelve `409 "Ya existe una cuenta con este correo electrónico"` y también por documento (`users/users.service.ts:66,81`) → oráculo de existencia, sin rate limit propio.
- `reset-password` y `verify-reset-code` responden `"Te quedan N intentos"` cuando el correo existe y `"Código inválido o expirado"` cuando no (`password-management.service.ts:81-82,104-112,147-148,166-178`) → oráculo diferencial tras un `forgot-password`.

La medición temporal de `TC-M01-039` **ya pasa el umbral del cliente** (`max(250 ms, 20 % del menor p95)`): diferencia medida ~16 ms. Falta el artefacto de evidencia (CSV de tiempos, p95, ambiente/build). Responsable: Erick.

**5 · `M01-SEC-005` — sesiones.** El comportamiento cumple: refresh rota el token (revoca el usado y emite par nuevo), **reutilizar un token revocado revoca todas las sesiones del usuario** (`auth.service.ts:183-186`), `logout` local y `logoutAll` funcionan, restablecer o cambiar contraseña revoca todas las sesiones (`password-management.service.ts:118`, `auth.service.ts:255`), y desde #71 el refresh revalida el estado de la cuenta, así que suspender ahora sí acota las sesiones vivas.

Dos precisiones para el manifest, que hoy figuran como *"Falta configuración"*:

| Parámetro del contrato | Valor efectivo en `main` | Fuente |
|---|---|---|
| `access_token_ttl` | `JWT_EXPIRES_IN`, default **15 min** | `auth.service.ts:309` |
| `refresh_token_ttl` | `REFRESH_EXPIRES_DAYS`, default **30 días** | `auth.service.ts:296` |
| `recovery_otp_length` | **6 dígitos** | `crypto.utils.ts` |
| `recovery_otp_ttl` | `PASSWORD_RESET_EXPIRES_MINUTES`, default **15 min** | `password-management.service.ts:43-46` |
| `recovery_otp_attempts` | **5 por token**, sin ventana ni cooldown | `password-management.service.ts:14` |
| `rate_limit_login` / `forgot_password` | **5/min, dimensión IP** | `auth.controller.ts:91,118` |

> ⚠️ **Bloqueo real:** el contrato de eventos de `09_Contratos_PrivSec` exige que `auth.refresh_rotated` lleve `session_id`, `device_id` y `token_family_id`, y `auth.refresh_replay_detected` lleve `token_family_id` y `affected_sessions`. La tabla `refresh_tokens` tiene sólo `id, user_id, token_hash, expires_at, revoked_at, created_at` — **no existe ninguno de esos tres campos**. El control no se puede evidenciar como está escrito sin cambiar el modelo de datos.

**6 · `M01-LOG-001` — logs y auditoría.** Es el punto más descubierto de los nueve, por tres razones distintas:
- **No hay contrato de eventos implementado.** El Assessment define 13 eventos con campos obligatorios (`correlation_id`, `pseudonymous_user_id`, `build_version`, `result`...). En el código no hay event emitter, ni logging estructurado, ni `correlation_id` en auth — sólo `Logger` de Nest con texto libre. `correlation_id` existe únicamente en `file_upload`.
- **`audit_log` existe en la BD y nunca se escribe.** La tabla se crea en la migración 004 y la entidad está registrada en `app.module.ts:135`, pero **no hay una sola escritura desde la aplicación**. Hoy no hay trazabilidad de quién accedió o modificó qué dato personal. Igual con `admin_audit_log`, `admin_user` y `report_snapshot`.
- **Lo que sí se loguea usa el `userId` crudo**, no un seudónimo hasheado como pide el contrato. Y hay un correo de pagador escrito a CloudWatch (`payment-processing.service.ts:187`).

Lo positivo y demostrable: **ningún OTP, token ni contraseña llega al log** — los códigos se hashean antes de persistir y los mensajes registran vigencia, no el valor.

**7 · `M01-DOCSEC-001` — archivos.** El control pide *"extensión, MIME real y límites"*. Hoy hay límite (**10 MB**, `statement-import.controller.ts:57`) y filtro de tipo, pero el filtro compara `file.mimetype`, que es **el Content-Type declarado por el cliente**, no el tipo real del contenido (`statement-import.controller.ts:59,101,151`). No hay dependencia de detección por *magic bytes* (`file-type` no está en `package.json`). Renombrar un ejecutable a `.pdf` con Content-Type falseado pasa el filtro. `M01-DOCSEC-002` (ciclo de vida) depende del `PaqueteArquitecturaDocumentalM01`, que el propio Assessment marca *"Falta materializar"*.

**8 · `M01-DEV-001` — datasets QA.** Implementado y con buena evidencia: fixture con dominio inexistente `@ejemplo-walvy.cl`, RUT válidos en formato pero de nadie, hash bcrypt declarado en claro a propósito y anotado como tal, y guardas duras — se niega a correr con `NODE_ENV=production` y exige `ALLOW_TEST_DATA_SEED=true` (`database/fixtures/datos-prueba.ts:314-322`). Lo que falta es el `ManifestDatosQAM01` con owner, finalidad, URI, SHA-256, ambiente, build, retención y eliminación. Es trabajo documental, no de código.

**9 · `M01-PRV-004/005` — eliminación y derechos.** No existe endpoint de baja de cuenta. La BD **sí está preparada**: `app_user.deleted_at` con `@DeleteDateColumn`, y el índice único de documento excluye las bajas para permitir reutilizar un RUT. Pero la migración fija una postura que Legal tiene que validar: `COMMENT ON COLUMN app_user.deleted_at IS 'Soft delete. Nunca se ejecuta DELETE físico en esta tabla.'` — **borrado lógico permanente no es lo mismo que derecho de supresión**. Ambos ya están aceptados como deuda técnica controlada (`DEBT-PRV-004/005`, gate: primera release productiva), así que el entregable de M01 es el diseño y el ticket, no la implementación.

---

## 2b · Los cuatro PR abiertos contra `main`

Verificados rama por rama contra `walvy/main` `073c523`. Dos cambian conclusiones de la sección anterior; los otros dos aportan evidencia sin alterar el diagnóstico.

| PR | Rama | Tamaño | Efecto sobre los nueve controles |
|---|---|---|---|
| **#74** | `feature/M01-PRV-002-versionamiento-legal` | +243, **1 archivo** | **Cierra el modelo de datos de `M01-PRV-002`** |
| **#81** | `feature/m1-onboarding-foco-contrato` | +1505/−5803, 20 archivos | No toca controles Priv/Sec, pero **rompe el contrato con el frontend** |
| **#72** | `feature/m1-evidencia-persistencia` | +101, 1 archivo | Refuerza `M01-DEV-001` y la evidencia de persistencia |
| **#73** | `feature/m1-fk-app-user` | +99, 2 archivos | Refuerza la corrección de `admin_surface` |

**#74 — `M01-PRV-002`.** Crea `legal_document_version` y `user_legal_acceptance`. Cruzados contra los nueve campos que exige el control, **están los nueve**:

| Campo exigido | Columna |
|---|---|
| `user_id` seudónimo | `user_legal_acceptance.user_pseudonym` |
| `document_type` | `legal_document_version.document_type` (CHECK `terms`/`privacy`) |
| `version` | `legal_document_version.version` |
| `effective_at` | `legal_document_version.effective_at` |
| `presented_at` | `user_legal_acceptance.presented_at` |
| `channel` | `user_legal_acceptance.channel` |
| `app_version` | `user_legal_acceptance.app_version` |
| `content_hash` / referencia | `content_hash_sha256` (CHECK `^[0-9a-f]{64}$`) + `content_url` |
| `action` | `acceptance_action` (CHECK `presented`/`accepted`/`declined`) |

Tres decisiones de modelo que conviene conocer antes de responder:
- **Historial de sólo inserción**: presentar y aceptar la misma versión son dos filas. La unicidad es un índice parcial sobre las filas `accepted`, no una restricción sobre `(usuario, versión)` — que habría prohibido justamente el par `presented` + `accepted` que el control pide.
- **`content_body` o `content_url`, con CHECK que exige al menos uno.** El modelo soporta las dos salidas de la pregunta abierta con Legal —documento externo versionado o contenido en la app— sin una segunda migración.
- **`requires_user_reacceptance`** anticipa la política de re-aceptación, que sigue sin definición de Legal (punto 3 del correo del 12-ago).
- Un trigger bloquea cambios de contenido, hash, versión y vigencia en filas ya publicadas.

⚠️ **El PR trae sólo la migración.** No hay entidad TypeORM, servicio ni endpoint: las tablas quedan creadas y vacías, y `register` sigue escribiendo las dos fechas de `app_user`. `M01-PRV-003` —apertura, lectura y aceptación separada— no lo toca nadie.

**#81 — modelo de puertas del onboarding.** Reemplaza `current_step`/`resume_surface` por `current_gate`/`resume_state`, y saca `email_verification`, `biometric_setup` y `profile_basic` del onboarding porque son Acceso, no Onboarding. Su propio cuerpo lo advierte: *"Rompe el contrato con el frontend"*, backend y app tienen que salir juntos. **Impacto directo en la evidencia**: cualquier caso ejecutado antes de #81 queda contra un contrato distinto. Refuerza el punto del build congelado (§3.3). También quita el avance automático del onboarding al verificar el correo — relevante para el encuadre de `M01-SEC-006`, sin cambiar el comportamiento del OTP.

**#72 — datos de prueba.** Siembra las cuatro tablas de M01 que quedaban vacías (`file_upload`, `user_goals`, `password_reset_tokens`, `payment_order`), enlaza `file_upload → statement_imports/import_line_items → financial_movement` para que la cadena de carga documental sea visible en los datos, y corrige tres cuentas que estaban en estados que el flujo real no puede producir. Inserciones idempotentes. **Sube el piso de `M01-DEV-001`**: no sólo hay guardas de entorno, ahora hay recorrido acreditable en los datos.

**#73 — FK a `app_user`.** Agrega las tres foreign keys que faltaban y renombra `report_snapshots.generated_by_admin_id` a `generated_by_user_id`, todas con `ON DELETE SET NULL` por ser referencias de auditoría. Su propio cuerpo confirma la corrección de §3.1: las columnas *"están vacías en todos los ambientes, porque no existe módulo administrativo que las escriba"*.

**Lo que ninguno de los cuatro toca**, y por tanto sigue igual que en §2: escrituras a `audit_log`, contrato de eventos, MIME real de archivos, `token_family_id`/`device_id`/`session_id` en `refresh_tokens`, las dos fugas de enumeración, la dimensión IP del rate limit y el cooldown ausente en recuperación de contraseña.

---

## 3 · Tres correcciones que hay que meter en la adenda

Divergencias entre lo que dicen los documentos y lo que hace el código. Las tres van en el mismo paquete que las rutas ya corregidas el 12-ago.

1. **`admin_surface`.** `09_Contratos_PrivSec` afirma *"No implementada; `src/admin/` vacío y bloqueado por RBAC"*. Es inexacto: `src/admin/` tiene **cinco entidades** (`admin_user`, `admin_audit_log`, `app_config`, `audit_log`, `report_snapshot`) registradas en `app.module.ts`. Lo correcto —y sigue cumpliendo `M01-SEC-007` / `RDY-SEC-007`— es *"sin controladores ni rutas expuestas; existen entidades declaradas sin módulo que las consuma"*. No hay superficie administrativa; sí hay tablas.
2. **`logout_all`.** El contrato dice `POST /auth/logout/all`; el backend expone `POST /auth/logout-all`. Ya notificado el 12-ago, con la petición de **no ejecutar `TC-M01-041` subescenario C ni `TC-076`** antes de la corrección: contra la ruta documentada devuelven `404` y ese `404` se leería como *"no revoca la sesión global"* en un control con gate bloqueante.
3. **Parámetros marcados *"Falta configuración"*.** Los seis de la tabla del punto 5 ya son determinables desde `main` y se pueden congelar en el manifest sin esperar nada.

---

## 4 · El punto CIS L1/L2

Jose Miguel sugiere *"regirnos por los controles L1, los que sean aplicables L2 del CIS Benchmarks"* y ofrece apoyo con los audit files.

Conviene aceptar el ofrecimiento acotando el alcance, porque **CIS Benchmarks no cubre ninguno de los nueve puntos que él mismo listó**. Los Benchmarks son guías de *hardening de plataforma* —sistema operativo, motor de BD, contenedor, cuenta cloud—; los nueve controles del correo son de *aplicación* (contrato de aceptación legal, OTP, sesiones, enumeración, logs de negocio). Son capas complementarias, no sustitutas: aplicar CIS L1 completo no cierra `M01-PRV-002`, y cerrar los 19 controles Priv/Sec no dice nada sobre la configuración de PostgreSQL.

Los benchmarks aplicables al stack y quién puede ejecutarlos:

| Benchmark | Aplicabilidad | Nota |
|---|---|---|
| CIS AWS Foundations | **Alta** — la más útil | Cuenta, IAM, CloudTrail, KMS, S3. Requiere acceso a la cuenta AWS |
| CIS PostgreSQL 16 | **Parcial** | RDS es gestionado: buena parte de L1 (SO, permisos de archivos, instalación) es del proveedor. Aplican logging, `rds.force_ssl`, roles y privilegios |
| CIS Docker / Amazon Linux | **Baja** | Fargate; no hay host administrado por nosotros |

Y hay un dato que conviene poner sobre la mesa en la misma respuesta: **un audit de CIS AWS Foundations levantaría hoy los mismos hallazgos que ya tenemos documentados** en [`2026-08-13-estado-controles-seguridad-bd.md`](2026-08-13-estado-controles-seguridad-bd.md) — la contraseña de BD en `environment:` en vez de `secrets:` (H-01), la app conectando con el usuario maestro de RDS (H-02), `sslmode=no-verify` sin `rds.force_ssl` (H-03), y sin `cloudwatchLogsExports` en RDS (H-13, que es justamente lo que serviría de evidencia de accesos a la BD). Llegar con esos cuatro identificados y priorizados es mejor que recibirlos en un informe externo.

> ⚠️ Esos cuatro salen del CDK de `walvy-platform-infra`, último commit **2026-06-10**. Describen la intención, no necesariamente lo desplegado. Confirmar contra el ambiente real antes de citarlos al cliente (comandos en el §0 de ese documento).

---

## 5 · Qué se puede ofrecer y qué hay que pedir

**Entregable ahora, sin ejecutar pruebas** — evidencia de revisión de código y configuración, con cita a archivo y línea sobre `main` `073c523`:
`M01-SEC-001` (bcrypt 12 rondas + tope 72 bytes), los seis parámetros del manifest de identidad, `M01-SEC-004` (configuración de throttle), la mitad de `M01-SEC-002` (verificación de correo cumpliendo `AX-M1-001` completo), `M01-DEV-001` (guardas del fixture) y `M01-SEC-007` con la redacción corregida.

**Requiere decisión de Legal/Producto antes de poder ejecutarse:** `M01-PRV-001/002/003` — el artefacto legal oficial no existe todavía, y sin él cualquier aceptación que registremos queda referida a un texto que no es el definitivo. Es el mismo punto urgente del correo del 12-ago, y el único que no se resuelve con una decisión tomada en sesión.

**Requiere cambio de modelo de datos, no sólo de código:** queda **uno solo**, el contrato de eventos de sesión de `M01-SEC-005` (`token_family_id`, `device_id`, `session_id` en `refresh_tokens`). El de `M01-PRV-002` ya está resuelto y esperando merge en el PR #74. Conviene decirlo ahora y no en la revalidación: es exactamente el escenario que Jose Miguel quiere evitar —*"cualquier remediación posterior en BBDD o código podría requerir nuevas pruebas QA"*—. Para `M01-SEC-005` hay salida sin migración si se acepta acotar el criterio de evidencia a lo que el modelo actual sí acredita: rotación, replay y revocación global.

**Hay que pedir:** el umbral de aceptación de cada control (§0 de `2026-08-13-estado-controles-seguridad-bd.md`: ingeniería puede llenar *control → implementación → evidencia*, pero no *resultado de validación*), la definición de qué eventos entran a `audit_log`, y la postura de Legal sobre baja lógica vs supresión física.

---

## 6 · Estado de ejecución, para calibrar el tono

Del `00_Resumen_M01`: **17 casos no iniciados, 1 en ejecución, 8 completados, 23 diferidos**. De los 49 casos del cierre acotado, los de privacidad y seguridad (`TC-M01-034` en adelante) están casi todos en *"Falta fixture/materialización"* o *"Falta acceso técnico"* según `10_Evidencia_Readiness`.

Conviene ser explícito en que la evidencia de estos controles **no está pendiente de que QA ejecute**: está pendiente de tres prerrequisitos que no dependen de QA — el artefacto legal oficial, los manifests de parámetros y datos, y el acceso técnico a API/código/config/logs para los casos cuyo responsable es Erick.
