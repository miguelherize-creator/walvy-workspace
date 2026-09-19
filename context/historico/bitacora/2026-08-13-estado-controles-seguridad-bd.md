# Estado de los controles de seguridad y privacidad sobre la BD

**Fecha:** 2026-08-13
**Evidencia del baseline:** back-walvy `walvy/main` `073c523` (2026-08-13) · walvy-platform-infra `origin/main` `20f30db` (2026-06-10)
**Origen:** correo de José Miguel Rodríguez del 2026-08-13 — cierre técnico de M01 y Ley 21.719
**Alcance:** persistencia y su cadena de custodia — RDS PostgreSQL, S3 de cartolas, DynamoDB de dedup, y el código que los toca

---

## 0 · Qué contesta este documento y qué no

El PMO pide trazabilidad **control requerido → implementación → prueba/evidencia → resultado de validación**. Este documento entrega las tres primeras columnas con evidencia citable a nivel de archivo y línea. La cuarta —*resultado de validación*— no la puede llenar ingeniería sola: requiere que Seguridad/Legal declare cuál es el umbral de aceptación de cada control.

**Advertencia sobre la mitad de infraestructura.** Los hallazgos 1, 2, 3 y 6 salen del CDK en `walvy-platform-infra`, cuyo último commit es del **2026-06-10** — dos meses antes que el `main` del backend. Ese repo describe la intención, no necesariamente lo desplegado. **Antes de llevar estos cuatro puntos a un informe al cliente hay que confirmarlos contra el ambiente real:**

```bash
aws ecs describe-task-definition --task-definition walvy-task-dev --query 'taskDefinition.containerDefinitions[0].{env:environment,secrets:secrets}'
```

```bash
aws rds describe-db-instances --db-instance-identifier walvy-postgres-dev --query 'DBInstances[0].{Encrypted:StorageEncrypted,Public:PubliclyAccessible,MultiAZ:MultiAZ,Backup:BackupRetentionPeriod,PG:DBParameterGroups}'
```

---

## 1 · Controles implementados, con evidencia

Esto es lo que ya se puede presentar como cerrado.

| # | Control | Implementación | Evidencia |
|---|---|---|---|
| C-01 | Cifrado en reposo — BD | RDS con `storageEncrypted: true` | `lib/construct/rds/index.ts:48` |
| C-02 | Cifrado en reposo — cartolas | S3 `BucketEncryption.S3_MANAGED`, `blockPublicAccess: BLOCK_ALL`, `enforceSSL: true` | `lib/construct/storage/index.ts:20-23` |
| C-03 | Aislamiento de red de la BD | RDS en subredes `PRIVATE_ISOLATED`, `publiclyAccessible: false`; SG solo acepta 5432 desde ECS y Lambda | `rds/index.ts:29,45` · `security/index.ts:63-75` |
| C-04 | Credenciales de BD fuera del código | `rds.Credentials.fromGeneratedSecret` en Secrets Manager | `rds/index.ts:42-44` |
| C-05 | Retención de cartolas | Lifecycle S3 de 30 días **y** borrado explícito del PDF al terminar de procesar | `storage/index.ts:26-33` · `statement-import.service.ts:326,757` |
| C-06 | Contraseñas | bcrypt; la columna `password_hash` va con `select: false`, no sale en queries por defecto | `user.entity.ts:45-51` |
| C-07 | Tokens de sesión y OTP | Almacenados como hash SHA-256, nunca en claro; refresh con rotación y TTL 30 d, OTP TTL 15 min | `common/utils/crypto.utils.ts` · `refresh-token.entity.ts:23` |
| C-08 | Anti fuerza bruta | `ThrottlerGuard` en el router de auth con límites por ruta (login 5/min, forgot-password 5/min, reenvíos 20/h) | `auth.controller.ts:37,91-186` |
| C-09 | Ambientes no productivos — datos sintéticos | Fixture con dominio inexistente `@ejemplo-walvy.cl`, RUT válidos en formato pero de nadie; se niega a correr con `NODE_ENV=production` y exige `ALLOW_TEST_DATA_SEED=true` | `database/fixtures/datos-prueba.ts:314-322` |
| C-10 | Herramientas de desarrollo fuera de producción | `DevModule` excluido del bootstrap si `NODE_ENV=production`, más `DevOnlyGuard` | `app.module.ts:157` · `dev/guards/dev-only.guard.ts` |
| C-11 | Validación de entrada | `ValidationPipe` con `whitelist` + `forbidNonWhitelisted`; helmet; redirect 80→443 en el ALB | `main.ts:26-33,13` · `alb/index.ts:62-66` |
| C-12 | Escaneo automatizado | semgrep y trivy en CI | `.github/workflows/backend-checker.yml:25` · `container-image-check.yml` |
| C-13 | Aislamiento por titular | Verificación de propiedad en servicio antes de devolver o mutar (`getOwned` compara `userId` y lanza 403) | `debts/services/debts.service.ts:126-135` |

---

## 2 · Brechas

### 2.1 · Altas — bloquean el cierre

**H-01 · La contraseña de la BD viaja como variable de entorno en claro.**
`ecs/index.ts:132-138` hace `.unsafeUnwrap()` sobre el secreto de RDS y arma `DATABASE_URL` a mano, que se inyecta en el bloque `environment:` (línea 155) en lugar de `secrets:`. La task definition resuelta queda con la contraseña legible para cualquiera con `ecs:DescribeTaskDefinition`. Las demás credenciales —JWT, Flow, SMTP— **sí** van por `secrets:` (líneas 159-165): la de base de datos es la única excepción.

**H-02 · La aplicación se conecta con el usuario maestro de RDS.**
`rds/index.ts:42` genera `walvy_admin` como usuario maestro y `ecs/index.ts:133` lo usa tal cual para la conexión de la app. No hay rol de aplicación con privilegios mínimos. Sin ese rol, cualquier inyección o compromiso del contenedor tiene `DROP TABLE`, no solo `SELECT`.

**H-03 · TLS a la BD sin validar el certificado, y el servidor acepta texto plano.**
La URL lleva `?sslmode=no-verify` (`ecs/index.ts:138`). Verificado en las dependencias: `pg-connection-string/index.js:153` traduce ese modo a `rejectUnauthorized: false`, y `pg/lib/connection-parameters.js:60` hace que lo parseado del connection string **sobrescriba** el `ssl` que pasa TypeORM. O sea, el tráfico va cifrado pero sin autenticar el extremo. Además la instancia RDS no tiene parameter group con `rds.force_ssl=1`, así que el servidor también acepta conexiones sin cifrar.
Lo llamativo: el repo ya trae el CA bundle (`global-bundle.pem`, 165 KB) y el camino de TLS verificado está escrito (`app.module.ts:97-104`, activado por `DB_SSL=true`) — simplemente no está encendido en el despliegue. `DB_SSL` no aparece en ninguna parte del repo de infra.

**H-04 · `audit_log` existe en la base y nunca se escribe.**
La tabla se crea en `migrations/1786000004000-BaselineIdentidadAcceso.ts:457`, con el comentario *"Para compliance y debugging"*, y la entidad está registrada en `app.module.ts:135`. **No hay una sola escritura desde el código de aplicación.** Es exactamente el control de *logs* que nombra el correo: hoy no existe trazabilidad de quién accedió o modificó qué dato personal. Mismo caso con `admin_audit_log`, `admin_user` y `report_snapshot`: entidades sin módulo que las use.

**H-05 · No existe eliminación de cuenta.**
No hay `DELETE /users/me` ni equivalente en ningún router. `app_user` tiene `deleted_at` con `@DeleteDateColumn` (`user.entity.ts:162`) y el índice único de documento está construido para permitir reutilizar un RUT tras una baja (`user.entity.ts:32-36`) — la base está preparada, pero nada dispara la baja. El derecho de supresión del titular no tiene implementación.

**H-06 · `DB_SYNC: 'true'` en el ambiente DEV.**
`ecs/index.ts:156` pone `DB_SYNC: isProd ? 'false' : 'true'`, y `app.module.ts:150` lo pasa a `synchronize` de TypeORM. En DEV, TypeORM altera el esquema solo, según lo que digan las entidades: deriva de las migraciones y puede eliminar columnas con datos. Es también lo que hace que el CI necesite declarar índices en la entidad además de en la migración (comentario en `user.entity.ts:22-31`).

**H-07 · Un endpoint marcado `[DEV]` cruza usuarios y llega a producción.**
`DELETE /statement-imports/dev/dedup/:hash` está solo bajo `AuthGuard('jwt')` — no bajo `DevOnlyGuard` ni dentro de `DevModule`. Su propio Swagger dice *"sin importar qué usuario la generó"* (`statement-import.controller.ts:298-307`), y la implementación lo confirma: `purgeDedupByHash` no recibe `userId` (`statement-import.service.ts:767`). Cualquier usuario autenticado puede borrar entradas de dedup de otro.

### 2.2 · Medias

| # | Brecha | Dónde | Nota |
|---|---|---|---|
| H-08 | Swagger publicado en producción, sin guard de entorno | `main.ts:52` | Expone la superficie completa de la API, incluidos los endpoints `[DEV]` de H-07 |
| H-09 | Sin Row Level Security | `DB/model/schema.sql:2069-2071` | La recomendación quedó escrita como comentario y nunca se implementó. El aislamiento vive solo en código (C-13) |
| H-10 | Sin política de retención ni purga | — | `@nestjs/schedule` ni siquiera está en dependencias. Tokens vencidos, OTP usados, `notification_queue`, `audit_log` y los read models se acumulan sin límite. La nota del propio schema lo pedía (`schema.sql:2072`). También: los ítems `processed` de dedup en Dynamo quedan permanentes a propósito (`dynamo-dedup.service.ts:20,174`) |
| H-11 | Correo en logs de aplicación | `payment-processing.service.ts:187` | Escribe `flowStatus.payer` (correo del pagador) a CloudWatch. El resto del código es disciplinado y loguea `userId` |
| H-12 | Sin seudonimización ni cifrado de columna | `user.entity.ts`, `user-financial-profile.entity.ts` | RUT, nombres, correo e ingreso estimado en claro. `crypto.utils.ts` solo hashea tokens; no hay ninguna utilidad de ofuscación en el código |
| H-13 | Disponibilidad y resiliencia | `rds/index.ts:46,51,52` | `multiAz: false`, backup 7 días en prod, Performance Insights apagado, sin `cloudwatchLogsExports`. Sin ese export no hay log de conexiones de PostgreSQL — que es justamente lo que serviría como evidencia de accesos a la BD. El correo nombra "disponibilidad y resiliencia" de forma literal |
| H-14 | Minimización sin declarar | esquema baseline | 55 entidades incluyendo IA, gamificación, B2B y read models. Falta declarar qué recolecta M01 y qué queda fuera de alcance |

---

## 3 · Lo que hay que decidir, y quién

| Pregunta | La responde |
|---|---|
| ¿Cuál es el plazo de conservación de cada familia de datos? (movimientos, cartolas, logs, tokens, cuentas dadas de baja) | Legal / Seguridad |
| ¿Baja de cuenta = anonimización o supresión física? ¿Qué se conserva por obligación tributaria de la suscripción? | Legal / Producto |
| ¿Qué eventos entran a `audit_log`? Mínimo sugerido: login, cambio de contraseña, alta/baja de cuenta, exportación, acceso administrativo | Seguridad |
| ¿RLS en tablas financieras o basta la verificación en código? | Arquitectura |
| ¿El RUT es dato necesario en M01? | Producto / Legal |

---

## 4 · Orden sugerido de remediación

1. **H-01, H-02, H-03** — van juntos, es un solo cambio en el CDK y su despliegue: mover `DATABASE_URL` a `secrets:` o componerla desde `ecs.Secret`, crear el rol de aplicación con privilegios mínimos, y pasar a TLS verificado (`DB_SSL=true` + parameter group con `rds.force_ssl=1`).
2. **H-07** — un guard. Es el hallazgo más barato de cerrar y el único con impacto cruzado entre usuarios.
3. **H-06, H-08** — dos flags de entorno.
4. **H-04, H-05** — trabajo de aplicación real: interceptor de auditoría y flujo de baja de cuenta. Son los dos que el regulador pediría primero.
5. **H-09 a H-14** — según lo que responda la sección 3.

---

## 5 · Ambiente de desarrollo

**Corregido el 2026-08-14.** Una versión anterior de esta sección levantaba las cartolas de `Kread-Kartolas/cartolas/` como hallazgo de datos reales en la estación de desarrollo. **No lo son:** son cartolas personales del propio desarrollador, no versionadas y fuera de todo repositorio. El titular del dato es quien las tiene, así que no hay tratamiento de datos de terceros ni hallazgo que reportar. Queda anotado para que la observación no se reintroduzca en una revisión posterior.

El frente de datos en desarrollo y QA (`M01-DEV-001`) queda entonces **sin reservas**: el fixture usa dominio inexistente `@ejemplo-walvy.cl`, documentos válidos en formato pero de nadie, y se niega a ejecutarse con `NODE_ENV=production` salvo `ALLOW_TEST_DATA_SEED=true` (`database/fixtures/datos-prueba.ts:314-322`). Lo que falta es el `ManifestDatosQAM01`, que es trabajo documental.

**Dos llaves privadas de Apple sueltas:** `AuthKey_H334MGQ6T6.p8` y `AuthKey_N9CSRSNWDJ.p8` en `/Users/miguelherize/Documents/Walvy/`. No están versionadas —ese directorio no es un repo— pero son credenciales del proyecto y corresponde moverlas a un gestor de secretos.

Nada de esta sección va al correo al cliente. Es gestión interna.

---

## 6 · Addendum — inventario con el lente ancho

*Agregado el 2026-08-13 a raíz del correo maestro, punto 3.*

El correo objeta, con razón, que el análisis de datos personales *"tiende a concentrarse en campos como RUT, correo, nombre o apellido"*. La sección 2 de este documento tenía ese sesgo: H-12 estaba redactado sobre RUT, nombre, correo e ingreso. El universo real de Walvy tiene tres capas más, y las tres están en el modelo.

### 6.1 · Documentación

| Qué | Dónde vive | Estado |
|---|---|---|
| El PDF de la cartola | S3, `uploads/{userId}/{timestamp}_{nombre}` | Cifrado, borrado al terminar de procesar, lifecycle 30 d |
| Metadatos del documento | `file_upload` — `storage_path`, `original_filename`, `file_hash`, `period_start/end`, `data_origin`, banderas de contraseña | **Sin retención definida** |
| **La fila original de cada línea, tal como llegó** | `import_line_items.raw_row` (JSONB) | **Sin retención definida.** El comentario de la migración dice *"No se modifica"* |

Esto último es lo que el lente estrecho no ve: **el PDF se borra a los 30 días, pero el contenido de cada línea de la cartola queda en la base indefinidamente.** La retención efectiva del dato financiero no es 30 días, es infinita. No es un defecto —hace falta para reconstruir movimientos— pero es una decisión de conservación que hoy nadie tomó explícitamente.

### 6.2 · Información financiera vinculable

`financial_movement`, `transaction`, `debt`, `debt_payment`, `debt_schedule`, `bill_payable`, `funding_source`, `budget_line`, `budget_period`, `user_financial_profile` (ingreso estimado, capacidad de pago, nota de gastos estables), `payment_order`, `subscription`.

Todo en claro. No hay cifrado de columna ni ofuscación en ninguna. Es el estado esperado para un MVP; lo que falta es la declaración de si corresponde o no, que es lo que traerá el marco transversal.

### 6.3 · Datos derivados del procesamiento — la capa que faltaba

Estos son inferencias sobre la persona, no datos que la persona entregó. Bajo la Ley 21.719 son datos personales igual, y varios constituyen elaboración de perfil.

| Tabla | Qué infiere | ¿Se escribe hoy? |
|---|---|---|
| `movement_classification_suggestions` | Categoría sugerida por movimiento, con `confidence` y `rule_matched` | **Sí**, en cada importación |
| `user_financial_profile.debt_health_status` / `debt_health_reason_codes` | Estado de salud de deuda y los códigos de por qué | Sí |
| `user_financial_profile.profile_data_quality_level` | Calidad del perfil: `insufficient` a `high` | Sí |
| `ant_expense_rule` | Reglas de gasto hormiga | Sí |
| `user_gamification_stats` | Estadísticas de comportamiento | Sí, al inicializar la cuenta |
| `financial_health_snapshot` | Nivel de salud financiera en el tiempo | **No** — tabla sin escritor |
| `recommendation_event` | Recomendaciones emitidas | **No** |
| `user_score_history`, `gamification_event` | Puntaje y eventos de comportamiento | **No** |
| Read models `user_month_diagnosis_summary`, `user_month_debt_priority_summary`, `user_month_leaks_summary` | Diagnóstico mensual, ranking de deudas, fugas detectadas con categorías | **No** — read models sin job |
| `ai_conversation`, `ai_message`, `ai_context_snapshot`, `ai_tool_invocation` | Conversaciones e insumos de IA | **No** — no existe `AiModule`; las entidades están en el esquema, dormidas |

Que la mayoría esté dormida es una ventaja de tiempo: **el marco transversal puede definir clasificación, finalidad y retención de estas tablas antes de que tengan una sola fila.** Es más barato ahora que después.

### 6.4 · Flujo hacia un componente externo

El PDF de la cartola sale del backend hacia Kread: `POST {KREAD_BASE_URL}/kartola` con el archivo como multipart (`kread/kread.service.ts:137-144`). El estado y el resultado se consultan con `fetch` sobre la misma base.

Dos observaciones:

- La firma HMAC es **opcional y viene apagada**: `KREAD_AUTH_SIGNED` por defecto `'false'`, y si `WALVY_KREAD_SHARED_SECRET` está vacío el servicio registra una advertencia y **envía sin firma** (`kread.service.ts:261-274`). En `.env.example` el secreto está vacío.
- `KREAD_BASE_URL` no valida esquema en el código, así que nada impide un `http://`.

Independiente de la relación societaria con Kread, es un flujo de documentación financiera hacia un componente fuera del backend, y el marco transversal va a necesitar tratarlo como tal: finalidad, base de licitud, retención del lado receptor y evidencia del tratamiento.

### 6.5 · Estado con los cinco PR integrados

*Verificado el 2026-08-13 integrando `72 · 73 · 74 · 81 · 84` sobre `073c523` en un árbol desechable.*

**Ninguna de las brechas altas se cierra con estos cinco PR.** Verificado sobre el árbol integrado: cero servicios escriben `audit_log`, cero endpoints `@Delete` en el router de usuarios, Swagger sin guard de entorno, `@nestjs/schedule` ausente. Lo que sí mueven es el frente `M01-SEC-*` (PR 84) y el de seudonimización y minimización (PR 74).

**Dos hallazgos que solo aparecen al integrar:**

**I-01 · Los PR 72 y 81 no pueden mezclarse ambos sin resolución manual.** GitHub los declara `MERGEABLE` porque evalúa cada uno contra `main` por separado, no entre sí. Chocan en `src/database/fixtures/datos-prueba.ts`, y no es un conflicto trivial: el 81 elimina `current_step` y `resume_surface` del esquema, así que la siembra que agrega el 72 está escrita contra vocabulario que dejará de existir. **Orden: primero el 81, después rehacer la siembra del 72 sobre el vocabulario de puertas.** Al revés, el 72 entra en verde y el 81 lo rompe.

**I-02 · El límite de 5 intentos por minuto es compartido por toda la plataforma.** `main.ts` no configura `trust proxy` (verificado en el árbol integrado). Detrás del balanceador, `req.ip` es la dirección de éste, no la del usuario, así que la dimensión IP del throttler colapsa en un solo balde. En `/auth/login` y `/auth/forgot-password` el límite de esa dimensión es `5/min`, y el contador vive en memoria del proceso porque `ThrottlerModule` va sin `storage` compartido. Límite efectivo ≈ 5 × tasks × nodos del balanceador, **para todos los usuarios juntos**. Con una task, la plataforma entera tiene cinco inicios de sesión por minuto antes de responder `429`.

El PR 84 no lo introduce —el límite ya estaba en `main`— y lo documenta explícitamente, dejándolo fuera de alcance por ser un cambio de comportamiento global. Pero conviene no perderlo de vista: es un defecto de **disponibilidad**, y disponibilidad es una de las cuatro propiedades que la Ley 21.719 nombra de forma literal en el texto que citó el PMO. El PR 84 sí mitiga la parte de seguridad, porque la nueva dimensión por cuenta funciona sobre el correo del cuerpo y no depende de la IP.

### 6.6 · Reemplaza a H-12

H-12 queda redactado así: **no hay seudonimización ni ofuscación en ninguna de las tres capas** —documentación, información financiera vinculable, y datos derivados—, con una sola excepción: `user_pseudonym` en el registro de aceptación legal que entrega `M01-PRV-002`. La pregunta abierta no es "¿ciframos el RUT?" sino qué control corresponde a cada capa según su clasificación, y ésa la responde el marco transversal.
