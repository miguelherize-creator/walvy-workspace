# Matriz de trazabilidad — protección del dato en su ciclo de vida

**Fecha:** 2026-08-14
**Origen:** correo de Jose Miguel Rodriguez del 2026-08-14 y sus precisiones por WhatsApp del mismo día
**Baseline:** back-walvy `walvy/main` `073c523` (2026-08-13). PR 84 abierto, sin mergear
**Infraestructura:** walvy-platform-infra `origin/main` `20f30db` (2026-06-10) — ⚠️ dos meses más antiguo que el backend; describe la intención, no necesariamente lo desplegado

**Qué es y qué no.** Esto responde lo que el correo pide textualmente: *"qué aplica, qué está implementado, qué evidencia lo demuestra, qué fue probado y qué queda pendiente"*. **No es una declaración de cumplimiento de la Ley 21.719** — esa determinación es del marco transversal que el propio PMO está redactando. Acá va la traza técnica de lo construido.

Ver [`2026-08-13-estado-controles-seguridad-bd.md`](2026-08-13-estado-controles-seguridad-bd.md) para el detalle de cada hallazgo y el §6 para el inventario de las tres capas de dato.

---

## 1 · El hallazgo estructural: tres frentes sin control asignado

El correo percibe el foco concentrado en autenticación. Es correcto, y tiene una causa: **el catálogo de 19 controles Priv/Sec del Assessment es auth-céntrico**. Al mapear los siete frentes contra la hoja `04_Privacidad_Seguridad`:

| Frente del correo | Control existente | Cobertura |
|---|---|---|
| Datos personales/financieros en logs | `M01-LOG-001` | Completa |
| Uso de datos en DEV/QA | `M01-DEV-001` | Completa |
| Supresión | `M01-PRV-004` / `M01-PRV-005` | Completa, como deuda técnica con gate |
| Segregación de accesos | `M01-AUT-001` + `M01-SEC-007` | **Parcial** — sólo BOLA sobre endpoints entregados y superficie administrativa |
| Retención | `M01-DOCSEC-002` | **Parcial** — sólo ciclo de vida documental |
| **Minimización** | — | **Ninguno** |
| **Cifrado / seudonimización / enmascaramiento** | — | **Ninguno** |

Ejecutar mejor los 19 controles no cubre los tres últimos. Hay que agregarlos al catálogo. Propuesta en §4.

---

## 2 · La matriz

### 2.1 · Minimización

| | |
|---|---|
| **Qué aplica** | Que el modelo recolecte y conserve sólo lo necesario para la finalidad declarada de cada módulo |
| **Implementado** | `ValidationPipe` global con `whitelist` + `forbidNonWhitelisted`: un campo no declarado en el DTO se rechaza, no se persiste en silencio. `password_hash` va con `select: false` |
| **Evidencia** | `main.ts:26-33` · `users/entities/user.entity.ts` |
| **Probado** | Sí, en los e2e de registro y perfil |
| **Pendiente** | **La declaración de alcance.** El baseline crea **87 tablas**; el módulo raíz registra **41 entidades**. El resto —IA, gamificación, B2B, read models mensuales— no tiene código que las lea ni escriba. Falta declarar qué recolecta M01, qué queda fuera de alcance y qué se elimina del esquema |

> **Ventaja de tiempo:** que la mayoría de esas tablas esté dormida permite definir clasificación, finalidad y retención **antes de que tengan una sola fila**. Es más barato ahora que después, y es el argumento más fuerte que se le puede dar al cliente.

### 2.2 · Cifrado, seudonimización y enmascaramiento

| | |
|---|---|
| **Qué aplica** | Protección del dato en reposo y en tránsito, y desvinculación cuando la finalidad no exige identificar al titular |
| **Implementado** | Cifrado en reposo: RDS `storageEncrypted`, S3 `S3_MANAGED` con `blockPublicAccess: BLOCK_ALL` y `enforceSSL`. Contraseñas con bcrypt 12 rondas. Tokens de sesión y OTP como hash SHA-256, nunca en claro. Seudonimización: `user_pseudonym` en el registro de aceptación legal |
| **Evidencia** | `rds/index.ts:48` · `storage/index.ts:20-23` · `users/users.service.ts:25,71` · `common/utils/crypto.utils.ts` · migración `VersionamientoLegal` (PR 74) |
| **Probado** | Los hashes, sí, por unitarios. El cifrado en reposo **no** — sale del CDK, hay que confirmarlo contra el ambiente desplegado |
| **Pendiente** | **No hay cifrado de columna ni ofuscación en ninguna de las tres capas** — documentación, financiero vinculable, datos derivados. `crypto.utils` sólo hashea tokens; no existe utilidad de ofuscación. TLS a la base va con `sslmode=no-verify`: cifra sin autenticar el extremo |

> El caso de `user_pseudonym` merece destacarse en la respuesta, porque **es exactamente el patrón que el PMO describe**: *"datos seudonimizados no serán necesarios ser ofuscados o suprimidos, pero sí aquellos que vinculen directamente al usuario"*. Al eliminar la cuenta, `user_id` pasa a nulo y la fila sobrevive identificada por el pseudónimo: se suprime la identidad, la evidencia del consentimiento persiste.

### 2.3 · Segregación de accesos

| | |
|---|---|
| **Qué aplica** | Que un titular sólo alcance sus datos, y que los accesos internos estén acotados por rol |
| **Implementado** | Verificación de propiedad en la capa de servicio antes de devolver o mutar: compara el `userId` del token contra el dueño del objeto y lanza 403. Aislamiento de red: RDS en subredes privadas, sin acceso público, grupo de seguridad que sólo acepta 5432 desde ECS y Lambda |
| **Evidencia** | `debts/services/debts.service.ts:133` · `cashflow/services/categories.service.ts:96,156` · `rds/index.ts:29,45` · `security/index.ts:63-75` |
| **Probado** | Parcialmente. `M01-AUT-001` pide A/B por cada fila de la matriz de autorización; `TC-M01-044` está sin iniciar |
| **Pendiente** | **Sin Row Level Security** — el aislamiento vive sólo en código, y la recomendación quedó escrita como comentario en el esquema sin implementarse. **La aplicación conecta con el usuario maestro de RDS**, no con un rol de privilegio mínimo: una inyección o un compromiso del contenedor tiene `DROP TABLE`, no sólo `SELECT`. **No hay superficie administrativa** — las entidades existen (`admin_user`, `admin_audit_log`, `app_config`, `report_snapshot`) sin módulo que las consuma |

### 2.4 · Datos personales o financieros en logs

| | |
|---|---|
| **Qué aplica** | Que las trazas técnicas no expongan más de lo que corresponde |
| **Implementado** | Disciplina de registrar identificador interno y nada más. **Barrido completo del backend el 2026-08-14: cero montos, glosas, saldos, `raw_row` o volcados de objeto completo.** Ningún OTP, token ni contraseña llega al log: los códigos se hashean antes de persistir y los mensajes registran vigencia, no valor |
| **Evidencia** | Barrido sobre `src/**/*.ts` de todas las llamadas a `logger.*` con interpolación. `email-verification.service.ts:239` como ejemplo del patrón: registra el evento y la vigencia, nunca el código |
| **Probado** | Revisión de código exhaustiva. `TC-M01-029` (`M01-LOG-001`) está **sin iniciar**, responsable Erick, gate Preproducción |
| **Pendiente** | **Dos excepciones puntuales**: el webhook de Flow escribe el correo del pagador (`subscriptions/services/payment-processing.service.ts:187`), y el módulo de desarrollo escribe el correo del usuario (`dev/dev.service.ts:74`, no se carga en producción). La primera es un fix de una línea. **Y el contrato de eventos no está implementado**: el Assessment define 13 eventos con `correlation_id`, identificador seudónimo, `build_version` y `result`; hoy hay registro en texto libre y el identificador es el `userId` crudo, no un seudónimo |

> Esto responde su pregunta directa —*"¿ese log solo revela información técnica o habla más de lo que corresponde?"*— y la respuesta es buena: **sólo información técnica**, con dos excepciones acotadas y ya identificadas.

### 2.5 · Uso de datos en DEV y QA

| | |
|---|---|
| **Qué aplica** | Que los ambientes no productivos no traten datos reales |
| **Implementado** | Set de datos íntegramente sintético: dominio inexistente `@ejemplo-walvy.cl`, documentos válidos en formato pero de nadie. Guardas duras: el sembrado se niega a ejecutarse con `NODE_ENV=production` y exige `ALLOW_TEST_DATA_SEED=true` |
| **Evidencia** | `database/fixtures/datos-prueba.ts` — función `verificarHabilitado` |
| **Probado** | Sí. Y el PR 72, en revisión, amplía la siembra a las cuatro tablas de M01 que quedaban vacías, dejando visible la cadena `file_upload → statement_imports → financial_movement` |
| **Pendiente** | El `ManifestDatosQAM01` con owner, finalidad, URI, SHA-256, ambiente, build, retención y eliminación. Es trabajo documental, no de código |

Es el frente que mejor se contesta.

### 2.6 · Retención

| | |
|---|---|
| **Qué aplica** | Plazo de conservación por familia de dato y proceso que lo haga efectivo |
| **Implementado** | El PDF de la cartola: lifecycle de S3 a 30 días **y** borrado explícito al terminar de procesar |
| **Evidencia** | `storage/index.ts:26-33` · `statement-import.service.ts:326,757` |
| **Probado** | No |
| **Pendiente** | **No existe política ni proceso de purga.** `@nestjs/schedule` no está siquiera en dependencias. Tokens vencidos, OTP usados, `notification_queue`, `audit_log` y los read models se acumulan sin límite. Los ítems procesados de dedup en Dynamo quedan permanentes a propósito |

> **La asimetría que conviene poner sobre la mesa:** el PDF se borra a los 30 días, pero `import_line_items.raw_row` —la fila original de cada línea de la cartola, tal como llegó— queda en la base indefinidamente. La migración la marca *"No se modifica"*. **La retención efectiva del dato financiero no son 30 días, es infinita.** No es un defecto: hace falta para reconstruir movimientos. Es una decisión de conservación que hoy nadie tomó explícitamente, y es de las primeras que el marco tiene que fijar.

### 2.7 · Supresión

| | |
|---|---|
| **Qué aplica** | Que el titular pueda ejercer supresión y que se pueda comprobar cómo se identifican y eliminan sus datos en cada componente |
| **Implementado** | El modelo está preparado: `app_user.deleted_at` con `@DeleteDateColumn`, y el índice único de documento excluye las bajas para permitir reutilizar un RUT. 41 claves foráneas hacia `app_user` en `CASCADE`. El PR 74 resuelve el caso difícil: la aceptación legal pasa `user_id` a nulo y conserva la fila por `user_pseudonym` |
| **Evidencia** | `users/entities/user.entity.ts` · migración `VersionamientoLegal` (PR 74, en revisión) |
| **Probado** | No |
| **Pendiente** | **No existe eliminación de cuenta.** No hay `DELETE /users/me` ni equivalente en ningún router: la base está preparada pero nada dispara la baja. Y hay una postura del modelo que Legal tiene que validar: la migración fija `COMMENT ON COLUMN app_user.deleted_at IS 'Soft delete. Nunca se ejecuta DELETE físico en esta tabla.'` — **baja lógica permanente no es lo mismo que derecho de supresión** |

---

## 3 · Lo que no tiene respuesta hoy

Dos brechas que el correo va a tocar y donde ingeniería no puede ofrecer evidencia:

**`audit_log` existe en la base y ninguna parte de la aplicación escribe en ella.** La tabla se crea en la migración 004 con el comentario *"Para compliance y debugging"* y la entidad está registrada en `app.module.ts:135`. Cero escrituras. A la pregunta *"quién puede acceder a ellos"* y *"quién accedió o modificó qué dato personal"*, hoy no hay respuesta. Igual con `admin_audit_log`.

**No existe eliminación de cuenta.** Es la otra que un regulador pide primero.

Ninguna de las dos se cierra con los cinco PR en vuelo.

---

## 4 · Propuesta: tres controles nuevos en el catálogo

Para que los siete frentes queden cubiertos por el mismo instrumento que ya usa el proyecto, y con la misma estructura de gate, criterio de cierre, evidencia y caso asociado:

| ID propuesto | Control | Gate sugerido | Por qué ahí |
|---|---|---|---|
| `M01-DAT-001` | Declarar el alcance de recolección: qué tablas pobla M01, cuáles quedan fuera y cuáles se retiran del esquema | Cierre M01 | Es declarativo y se puede cerrar sin código |
| `M01-DAT-002` | Definir el control que corresponde a cada capa de dato según su clasificación: cifrado de columna, seudonimización o enmascaramiento | Preproducción | Depende del marco transversal; no se puede cerrar antes |
| `M01-DAT-003` | Política de retención y proceso de purga por familia de dato, incluida la asimetría documento/línea | Preproducción | Requiere plazo definido por Legal más implementación |

Los tres dependen del marco transversal para su criterio de cierre. Proponerlos ahora sirve igual: deja registrado que el frente existe y que su cierre está bloqueado por una definición del cliente, no por trabajo pendiente nuestro.

---

## 5 · Baselines: ASVS, MASVS y CIS

Aceptar el ofrecimiento, acotando el reparto por capa:

| Baseline | Capa | Quién | Nota |
|---|---|---|---|
| **OWASP ASVS** | Aplicación y backend | Kabeli backend | El que más rinde para estos siete frentes. Nivel 2 como objetivo; L3 sólo donde el marco lo justifique |
| **OWASP MASVS** | Aplicación móvil | Kabeli mobile | Cubre almacenamiento local, biometría y comunicación — complementa `M01-BIO-001` |
| **CIS Benchmarks** | Infraestructura | Kabeli infra + Walvy | AWS Foundations es el aplicable; PostgreSQL 16 sólo parcialmente porque RDS es gestionado; Docker y sistema operativo casi no aplican porque es Fargate |

La forma de entrega que él propone —*"identificar su aplicabilidad y dejar trazabilidad de lo implementado, exceptuado o pendiente"*— es la correcta y es la que evita la trampa de perseguir controles que no aplican.

**Anticipar lo que un audit de CIS AWS Foundations levantaría hoy**, para que llegue por nuestra parte: credencial de base de datos en variable de entorno en vez de referencia a secreto; la aplicación conectando con el usuario maestro de la instancia; TLS a la base sin validar el certificado y sin forzar cifrado en el servidor; y sin exportación de logs de PostgreSQL, que es justamente lo que serviría como evidencia de accesos a la base. Los tres primeros se remedian en un solo cambio de infraestructura.

⚠️ Los cuatro salen del CDK con último commit del 2026-06-10. Confirmar contra el ambiente desplegado antes de citarlos al cliente.

---

## 6 · Qué pedir en la respuesta

1. **El marco transversal**, que es prerrequisito de `M01-DAT-002` y `M01-DAT-003` y del criterio de cierre de todo este frente.
2. **Los plazos de conservación por familia de dato** — movimientos, líneas de cartola, documentos, logs, tokens, cuentas dadas de baja.
3. **La postura sobre baja de cuenta**: si la baja lógica permanente satisface el derecho de supresión o si hace falta anonimización, y qué se conserva por obligación tributaria de la suscripción.
4. **Qué eventos entran a la auditoría.** Mínimo sugerido: inicio de sesión, cambio de contraseña, alta y baja de cuenta, exportación y acceso administrativo.
5. **El umbral de aceptación de cada control**, sin el cual se puede entregar evidencia pero no declarar resultado.
