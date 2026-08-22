# Revisión de código contra el paquete de Protección de Datos (puntos 2 y 3)

**Fecha:** 2026-08-20
**Baseline revisado:** `back-walvy` **`ddde3ed`** · `front-walvy` **`34c7da8`** — ambos `origin/main` de **KabeliDev**, por decisión explícita.
**Advertencia de alcance del baseline:** `walvy-org/main` está detrás (`cc38d4a` back, `e5c9078` front): 37 archivos de diferencia en backend y 48 en frontend. Toda evidencia que se emita desde este informe corresponde al código de KabeliDev, **no** al repositorio que audita el cliente. Si la evidencia se entrega a Walvy hay que sincronizar primero o declarar el SHA de KabeliDev en cada artefacto.

**Documentos contra los que se revisa:**
- Punto 2 — `Walvy_Clasificacion_y_Requisitos_Proteccion_Datos_para_Implementacion_v1_0.xlsx` (233 IDs, perfiles `PP-01..PP-10`, transversales `TR-*`).
- Punto 3 — `Walvy_Requerimientos_Evidencia_Tecnica_Kabeli_v1_0.xlsx` (`RT-01..RT-09`, 43 subpreguntas).

---

## Estado de remediación

Rama `fix/redaccion-logs-datos-personales` sobre `back-walvy` (base `0489f0e`, `origin/main` de KabeliDev — avanzó desde el `ddde3ed` con que se levantaron los hallazgos; los cuatro se reverificaron en HEAD antes de tocar nada).

| Hallazgo | Estado |
|---|---|
| H2 · número de cuenta en logs | **Resuelto** |
| H3 · redacción no transversal | **Resuelto parcialmente** — lista de claves endurecida; el cableado en el transporte del logger sigue pendiente |
| H4b · `CacheControl` en originales | **Resuelto** |
| H8 · vocabulario de `sufficiency_status` | **(a) (b) (d) resueltos** — proyección canónica declarada y probada, y la divergencia contra la frontera de V50 corregida; (c) sigue abierta porque la distinción permitido/bloqueado no se persiste |
| H7 · correos en logs | **Resuelto** |
| H4a · original no purgado en ruta de error | **Resuelto para fallos permanentes** — el transitorio necesita el TTL M01 de Walvy o una regla de lifecycle en el bucket |
| H1, H5, H6 | Abiertos — requieren definición, ver el orden de trabajo al final |

`tsc` limpio, `eslint` limpio, 295 tests en 33 suites.

## Resumen

| Bloque | Estado en el código |
|---|---|
| `RT-01` release y ambiente | Producible hoy |
| `RT-02` K-read | Integración existe; borrado del original incompleto |
| `RT-03` regiones y proveedores | No respondible desde código |
| `RT-04` fin de acceso, supresión, no-resurrección | **No implementado** |
| `RT-05` logging y redaction | Utilidad existe, cobertura parcial, 3 fugas concretas |
| `RT-06` biometría local | **Conforme por diseño** |
| `RT-07` M07 · voz/STT | **No existe** |
| `RT-08` consentimiento versionado | Base fuerte, dos campos ausentes |
| `RT-09` M07 · contexto 24h | Esquema sin lógica |

Nueve hallazgos abiertos y seis controles que ya se sostienen. Los hallazgos van ordenados por severidad.

---

## H1 · El lifecycle completo de `RT-04` / `TR-RET-01` no está implementado

Es el hallazgo mayor y condiciona `TEC-M1-021`.

Lo que existe: columnas `deleted_at` en `app_user`, `financial_movement`, `transaction` y `debt`, con `COMMENT ON COLUMN app_user.deleted_at` = *«Soft delete. Nunca se ejecuta DELETE físico en esta tabla»*, y un índice único parcial que ya excluye las filas borradas.

Lo que no existe, verificado por ausencia en `ddde3ed`:

- **No hay endpoint ni servicio de supresión de cuenta.** `users.controller.ts` expone `GET me`, `PATCH me`, `POST me/avatar`, `PATCH profile`, `PATCH me/password`. No hay `@Delete`.
- **No hay ventana de 90 días.** Ninguna referencia a plazo de recuperación, `grace_period` ni equivalente en `src/`.
- **No hay estado de congelamiento.** Nada implementa «tratamiento funcional congelado»: no existe un estado que bloquee nuevos diagnósticos, recomendaciones y alertas conservando la cuenta.
- **No hay reactivación** ni **reconciliación de no-resurrección** post-restore.
- **No hay consumo del trigger comercial.** `subscription-status.enum.ts` declara `trialing`, `active`, `past_due`, `cancelled`, `expired`, pero ningún código mapea esos estados a un fin efectivo de acceso ni a un cese funcional.

Consecuencia para la evidencia: `RT-04.2` a `RT-04.8` no son respondibles hoy con «Cumple parcial». La respuesta honesta es *no implementado en el release vigente*, y el propio paquete advierte que un pendiente no habilita a asumir Cumple ni No Aplica.

**Nota favorable sobre la frontera.** El enum de suscripción ya distingue `past_due` de `cancelled`/`expired`, que es exactamente la distinción que `TR-RET-01` exige —un fallo de pago con acceso vigente no gatilla la ventana—. La materia prima está; falta la regla que la consuma, y el catálogo de triggers lo debe entregar Walvy (`RT-04.2`).

---

## H2 · El número de cuenta bancaria se registra en claro en los logs

`src/imports/services/statement-import.service.ts:442`

```
Import ${record.id} OK — ${mapped.transactionCount} movimientos | cuenta ${mapped.accountNumber}
```

`mapped.accountNumber` viene de `kread.mapper.ts:125` (`file.metadata.account_number`), sin enmascarar. Se emite en la ruta de éxito de toda importación de cartola.

Contraviene tres requisitos a la vez: `PP-02` —*«No registrar payload financiero completo»*—, `PP-10` —*«Identificador completo de tarjeta/cuenta, si existiera, debe separarse y tratarse como Restringido»*— y `TR-LOG-01`. Es la respuesta que hoy tendría `RT-05.3` si se tomaran muestras reales.

Corrección de una línea: eliminar el campo o enmascararlo dejando los últimos dígitos.

---

## H3 · La redacción de logs existe pero no es transversal

`src/common/utils/log-redaction.util.ts` define `redactSensitiveText` con una lista razonable —`authorization`, `cookie`, `password`, `secret`, `token`, `apikey`, `api_key`, claves S3, `jwt_secret`, `flow_secret_key`—, patrón `Bearer` y enmascaramiento parcial de correo.

El problema es la cobertura. La utilidad se invoca en **dos** lugares: el filtro global de excepciones (`http-exception.filter.ts`) y `flow.service.ts`. En el resto del backend hay **126 llamadas a `this.logger.*` en 21 archivos**, ninguna redactada. La redacción está en el borde de error, no en el transporte, así que cualquier `logger.log()` que interpole un valor lo escribe tal cual — que es exactamente cómo se produce H2.

Además, la lista de claves **no incluye `otp`, `code` ni `verification_code`**. Hoy no se registra ningún OTP —verificado: `code` sólo viaja a `mailService.sendEmailVerificationCode`—, así que `PP-05` se cumple, pero por convención y no por construcción: el día que alguien logee el payload de verificación, el filtro no lo detiene.

`RT-05.2` pide *«filtros/allowlists/redaction efectivos por componente y ambiente»*. Con dos call sites no se puede acreditar.

---

## H4 · El original financiero no se elimina en la ruta de error, y se sube marcado como cacheable un año

Dos problemas sobre `M01-DAT-021` (Restringido, `PP-06`, *«transitorio y no repositorio permanente»*) y `TR-DOC-01`.

**a) Ruta de error — RESUELTO.** El borrado ocurría en éxito (tras marcar `parsed`) y en cancelación (best-effort). `handleProcessingFailure` no borraba nada, porque `/retry` relee el archivo desde S3.

La salida no exigió inventar un TTL —`M01-DAT-021` deja el plazo M01 «dependiente de la fuente específica M01», o sea sin definir por Walvy— porque la propia clasificación de fallos ya resolvía la pregunta. `StatementImportFailureReason` distingue `transient`, `non_processable` y `outdated`, y el código ya afirmaba que las dos últimas son permanentes: *«Es permanente, así que NO se clasifica como transient — reintentar el mismo archivo da el mismo 4xx»*. Si un reintento no puede cambiar el resultado, el original no le sirve a nadie: se purga al fallar, sin política de retención de por medio.

Tres hechos que hicieron esto seguro, verificados y no supuestos:

- **El front ya discrimina.** En `OnboardingAnalyzingScreen.tsx`, `unsupported_bank` y `outdated_document` ofrecen «Subir otro documento»; sólo el caso por defecto —el transitorio— llama a `/retry`. Purgar en fallo permanente no toca el flujo real.
- **La ausencia del objeto ya era un estado soportado.** `retryImport` capturaba `NoSuchKey`, marcaba el import `cancelled` y devolvía «El archivo ya no está disponible». La purga no introduce un camino nuevo.
- **`reason` puede ser `null`.** El fallback de `classifyFailure` deja `null` cuando no reconoce la causa. Ese caso conserva el original: descartarlo por un error que no supimos leer es peor que guardarlo un rato más.

Se agregó además una guarda en `/retry` para los fallos permanentes, que responde con el `errorMessage` original en vez de dejar que `getBuffer` falle con «el archivo ya no está disponible» — que diría algo distinto de lo que pasó. Es defensa en profundidad para cualquier caller que no sea la app.

Lo que **sigue abierto** de este punto: el original de un fallo **transitorio** o **sin clasificar** permanece en S3 sin TTL. Acotarlo requiere el plazo M01 que Walvy no ha definido, o una regla de lifecycle en el bucket, que es capa de infraestructura y por lo tanto responsabilidad Walvy (`TR-AWS-01`). El requisito de `RT-02.6` queda cubierto para la ruta permanente y declarado como dependencia para la transitoria.

**b) Metadata de caché.** `s3.service.ts:38` aplica `CacheControl: 'public, max-age=31536000, immutable'` en **todos** los uploads. `uploadBuffer` lo usan tanto los avatares (`users.service.ts:315`) como los originales de cartola (`statement-import.service.ts:239`). Una directiva pensada para avatares queda instruyendo a cualquier caché intermedia a conservar un documento financiero por un año y a considerarlo inmutable. Choca de frente con «superficie temporal mínima, no repositorio permanente».

Corrección: parametrizar `CacheControl` por tipo de objeto y decidir el lifecycle del original en la ruta fallida —purga con TTL corto, o retención acotada declarada y evidenciada—.

---

## H5 · La evidencia de consentimiento no registra alcance/finalidad ni modela revocación

La migración `1786000017000-VersionamientoLegal.ts` es lo mejor construido del baseline para estos documentos, y su comentario de cabecera ya razona sobre `M01-PRV-002`, `TC-M01-035` y los derechos ARCO de la Ley 21.719. `legal_document_version` trae `version`, `content_hash_sha256` con CHECK de formato, `effective_at`, `requires_user_reacceptance`, índice único parcial de versión activa y CHECK de fuente de contenido. `user_legal_acceptance` trae `user_pseudonym`, `presented_at`/`accepted_at` con CHECK de coherencia y de orden, `acceptance_source`, `acceptance_action`, `channel` y `app_version`, y usa `ON DELETE SET NULL` para conservar la evidencia al suprimir la identidad.

Contra los campos mínimos de `RT-08.2` quedan dos ausencias:

- **Alcance/finalidad del consentimiento.** `RT-08.2` y `TR-CONS-01` exigen registrar *«alcance/finalidad»*. No hay columna. La tabla acredita la aceptación de un documento versionado, pero no el alcance del consentimiento financiero central que ese acto afirmativo debe soportar según `TRT-WAL-006`. Sin ese campo, el vínculo entre el acto y el tratamiento financiero es inferido, no registrado.
- **Revocación.** `chk_ula_action` admite `presented`, `accepted` y `declined`. `declined` es no aceptar algo que se presenta; no es revocar un consentimiento previamente otorgado. `RT-08.3` pregunta por revocación y reaceptación y por su vínculo con el cese funcional.

Nada de esto exige rediseño: la tabla es un historial de solo inserción, así que se resuelve con una columna de alcance y un valor más en el CHECK.

**Dependencia externa que sigue mandando.** `M01-PRV-001` exige artefactos legales congelados con versión y hash. La migración `1786000020000-SeedDocumentosLegalesV1.ts` siembra documentos v1, pero el artefacto oficial es de Walvy/Legal. El modelo soporta las dos salidas —`content_body` embebido o `content_url` externo, con CHECK de que exista al menos uno— y el propio comentario de la migración declara esa definición como pendiente. Es el punto que ya se levantó en `TEC-M1-003`.

---

## H6 · M07 no existe: `RT-07` sin código, `RT-09` con esquema y sin lógica

- **`RT-07` (voz/STT).** No hay proveedor de speech-to-text, ni manejo de audio, ni dependencia relacionada. Búsqueda negativa de `whisper|speech|transcri|audio|deepgram|assemblyai` en `src/`: sin resultados funcionales. Tampoco hay proveedor de IA: sin coincidencias de `anthropic|openai|bedrock|gemini` en código ni en `package.json`. Las nueve subpreguntas `RT-07.1..RT-07.9` se responden *no implementado*.
- **`RT-09` (contexto conversacional 24h).** Aquí hay un matiz que conviene no confundir. `src/ai/` contiene **sólo entidades**: `ai-conversation`, `ai-message`, `ai-context-snapshot`, `ai-tool-invocation`, `faq-article`. Están registradas en `app.module.ts` y creadas por la migración `1786000012000`. No hay servicio, ni controlador, ni consumo.

  Y el esquema **no soporta el requisito**: `ai_conversations` tiene `id`, `user_id`, `title`, `created_at`, `updated_at` y nada más. No existe `expires_at`, `last_interaction_at` ni TTL. La continuidad funcional máxima de 24h desde la última interacción que pide `TR-M07-02` no sólo no está implementada: no hay columna donde apoyarla.

  Que la tabla exista no es evidencia de que la funcionalidad exista. Al responder `RT-09` hay que decir las dos cosas por separado, o Walvy leerá el esquema como implementación.

  Detalle menor: `ai_conversations.created_at`/`updated_at` son `timestamp without time zone`, mientras la migración `1786000019000-NormalizarAuditoriaTimestamptz` normalizó la auditoría a `timestamptz`. Las tablas `ai_*` quedaron fuera de esa normalización.

---

## H7 · Dos fugas menores de dato personal en logs

- `src/subscriptions/services/payment-processing.service.ts` — **dos** ocurrencias, no una: `[webhook] subscription charge status ... payer=${flowStatus.payer}` y `[webhook] no user for payer ${flowStatus.payer}`. El `payer` de Flow es el correo del pagador —se busca por `email` unas líneas más abajo— y se escribía completo en la ruta de webhook, que es producción. `PP-01` pide evitar valores personales completos en logs.
- `src/dev/dev.service.ts:86` — `[dev] reset-user — usuario ${userId} (${user.email})`. Correo completo. Mitigado por `DevOnlyGuard`, que exige `NODE_ENV !== 'production'` **y** `DEV_TOOLS_ENABLED === 'true'`, así que no se emite en producción. Pero el módulo sigue compilado y registrado en la aplicación: la protección es de configuración, no de build.

Buena práctica que conviene preservar y citar como evidencia: `payment-processing.service.ts:120` registra `Object.keys(body)` y no el body — es la forma correcta y contrasta con H2.

---

## H8 · `sufficiency_status`: el desajuste no es sólo de vocabulario

La primera lectura de este hallazgo se quedó corta. Al revisar `src/health/` apareció que el gate **sí está implementado**, en `rules/sufficiency-gate.rule.ts`, como función pura con `RULE_VERSION`, tabla de indicadores, motivos de bloqueo y advertencias, y con sus enums tomados literalmente del documento Fase 3 de Walvy. El CHECK aparece además en **dos** tablas: `user_onboarding_state` y `user_month_diagnosis_summary`.

Con eso a la vista, el desajuste se descompone en cuatro cosas de peso muy distinto.

**a) `sufficient` vs `complete` — sólo nombre.** Sin impacto de comportamiento.

**b) `insufficient` + `blocked` → `blocked` canónico.** La base es *más fina* que el vocabulario canónico: distingue «no había documento usable» de «había documento pero faltaba un indicador obligatorio». No es un conflicto, es un refinamiento, pero hay que declararlo o Walvy buscará un `blocked` y encontrará dos valores.

**c) `partial bloqueado` no se emite.** Cuando un indicador crítico no es usable la regla devuelve `insufficient` con `partialDiagnosticAllowed: false`, así que el caso de `M1-V50` sale como `blocked`. El **comportamiento coincide** con lo que V50 espera —no habilitar el diagnóstico parcial—, pero la etiqueta que Walvy va a buscar no existe. Y no hay dónde ponerla: `diagnosticMode` y `partialDiagnosticAllowed` se calculan y se descartan, no se persisten. Desde la columna `sufficiency_status` sola, la distinción permitido/bloqueado no es recuperable.

**d) Divergencia real, no de nombres: se emite `complete` donde Walvy documentó parcial.** Verificado ejecutando la regla, no leyéndola. Con `pagos_recurrentes` en `por_confirmar` y el resto de los indicadores establecidos, `allFullyDetected` resulta verdadero por la cláusula «basta uno del par», la regla devuelve `sufficient` y proyecta a `complete` — **aunque `warningReasons` registre el pendiente**. El caso simétrico, `compromisos_base` pendiente, se comporta igual.

Lo que lo vuelve grave es que no es sólo el canónico genérico: la decisión PO de `V50` documenta ese caso exacto, y al revés — *«pagos recurrentes pendientes pueden permitir parcial cuando ingreso, movimientos y compromisos están suficientemente establecidos»*.

**Causa raíz:** la cláusula «basta uno del par» de la Fase 3 §8 gobierna el **bloqueo** —si existe base mínima—, y la implementación la reutilizó también para decidir la **completitud**. Son preguntas distintas: que uno del par esté detectado alcanza para tener base mínima, no para llamar completa una lectura cuyo otro miembro está pendiente. No es que dos documentos de Walvy se contradigan; es la implementación divergiendo de una frontera que Walvy ya dejó escrita, así que la corrección es de Kabeli y no reabre Producto.

**Hallazgo lateral: un motivo de advertencia miente.** `NOT_USABLE` agrupa `no_detectado` y `desactualizado`, y para los dos se empuja el motivo `dato_desactualizado`. Un indicador que nunca se detectó se reporta como desactualizado. Los `reason` por salida son justo lo que `M01-RGL-012` exige validar, así que conviene corregirlo — pero el motivo correcto tiene que salir de la sección 18 del documento Fase 3, no inventarse acá, que es la regla que el propio archivo se puso.

### Lo que se hizo

Se declaró la proyección en código, sin migrar el CHECK del cliente, sin tocar el contrato expuesto (`DiagnosisBlockDto`, que no incluye `sufficiencyStatus`) y sin inventar el mapeo hacia `diagnostic_status`, que no tiene equivalencia aprobada por Producto:

- `CanonicalSufficiencyOutcome` = `blocked` / `partial_bloqueado` / `partial_permitido` / `complete`, con la cita a `AX-M1-003` y `M01-RGL-012`.
- `toCanonicalOutcome(result)`, función pura, con las dos asimetrías documentadas en el propio JSDoc.
- Tests que cubren las cuatro salidas y que **fijan las divergencias en vez de esconderlas**: uno deja constancia de que el caso de `M1-V50` sale como `blocked`, y otro de que se emite `complete` con pendientes no críticos donde el canónico esperaría `partial_permitido`.

Migrar el CHECK sigue siendo el último recurso y no se tocó. Cambiar (c) o (d) es decisión de Producto: toca la semántica del semáforo, no un nombre, y `TEC-M1-013` está todavía en «Ajustar control», o sea que el alcance ni siquiera está cerrado.

---

## H9 · `RT-02` y `RT-03`: los hechos técnicos de terceros no están en el código

La integración existe y su dataflow es documentable: `src/imports/kread/` con `POST /process-document`, `GET /process-document/{jobId}/status` y `GET /process-document/{jobId}/result`, más `dynamo-dedup.service.ts` con reserva condicional y TTL de 900 s para evitar procesos duplicados del mismo documento.

Pero **región, hosting, subprocesadores y contrato no son deducibles del repositorio**: `KREAD_BASE_URL` es una variable de entorno (`kread.service.ts:180`) y `S3_REGION` tiene default `us-east-1` en código (`s3.service.ts:20`), que es un default, no la región efectiva. `RT-02.1`, `RT-02.3`, `RT-02.7`, `RT-03.1` y `RT-03.2` se responden con configuración de despliegue y documentos contractuales, no con código, y el mapa consolidado que pide `RT-03` requiere el aporte de infraestructura.

Dato relevante y verificable: un comentario en `statement-import.service.ts` afirma que *«Kread borra su /result tras leerlo»*. Es una afirmación sobre el lifecycle del tercero que hoy sólo consta como comentario; `RT-02.5` y `RT-02.6` exigen acreditarla con configuración o evidencia del proveedor.

---

## Controles que ya se sostienen

Vale citarlos porque son evidencia entregable, no supuestos.

1. **`RT-06` / `TR-BIO-01` / `EXC-WAL-001` — biometría local: conforme por diseño.** `expo/services/biometrics.ts` usa `LocalAuthentication.authenticateAsync` y devuelve **sólo un booleano** (`result.success`). Lo único que se persiste es la preferencia `walvy_biometric_enabled` = `"true"`/`"false"`. Ninguna plantilla, vector ni característica biométrica sale del dispositivo, porque la API del SO no la expone a la app. `disableDeviceFallback: true` mantiene el fallback en la contraseña de Walvy, consistente con `TEC-M1-006`. Falta sólo el artefacto: prueba de red negativa.
2. **`EXC-WAL-002` — N° de cliente M06: ausente.** Búsqueda negativa de `customer_number|customerNumber|numero_cliente|client_number` en `src/`: sin resultados. La exclusión MVP se cumple en el esquema y en el código.
3. **`PP-05` / `M01-SEC-001` — contraseña.** `bcrypt` con `BCRYPT_ROUNDS = 12` (`users.service.ts:24,198`), y `COMMENT ON COLUMN app_user.password_hash` documenta *«Hash bcrypt ≥12 rondas»*. Además `MaxBytes(72)` en los tres DTOs que reciben contraseña, con el comentario correcto: bcrypt ignora en silencio lo que exceda 72 bytes, así que truncar sin validar sería un downgrade invisible de entropía.
4. **`M01-AUT-001` / `TR-SEC-01` — owner check.** Todos los controladores salvo `health.controller.ts` declaran `UseGuards`. El patrón de autorización por recurso está implementado: `categories.service.ts` hace fetch y luego verifica `ownerUserId !== userId → ForbiddenException`, distinguiendo además el catálogo de sistema (`ownerUserId IS NULL`, no editable) de las categorías propias.
5. **Secretos fuera del repositorio.** Sólo `.env.example` está versionado. El hash bcrypt del fixture de pruebas está en claro a propósito y anotado como tal, con supresión explícita de semgrep — decisión declarada, no filtración.
6. **`RT-04.9` / `TR-DB-01` / `TEC-M1-015` — arquitectura lógica de datos: el punto más fuerte.** 23 migraciones versionadas, PK/FK/CHECK/índices explícitos, índices únicos parciales que respetan el soft-delete, y `COMMENT ON TABLE` / `COMMENT ON COLUMN` en todo el modelo documentando finalidad por campo. Es exactamente lo que `RT-04.9` pide y se entrega sin trabajo adicional. Es también la mejor defensa de la frontera `TR-DB-01`: acredita que la arquitectura lógica es de Kabeli y está gobernada.

---

## Orden de trabajo que sugiere el hallazgo

Barato y de impacto inmediato en evidencia:
1. H2 — quitar o enmascarar `accountNumber` del log. Una línea.
2. H7 — quitar `payer` y el correo del log de dev. Dos líneas.
3. H3 — agregar `otp|code|verification_code` a `SENSITIVE_KEYS` y decidir si la redacción se aplica en el transporte del logger en vez de por call site.
4. H4b — parametrizar `CacheControl` por tipo de objeto.

Requieren definición antes de código:
5. H5 — columna de alcance/finalidad y valor `revoked`: definir con Walvy/Privacidad qué alcance se registra.
6. H4a — lifecycle del original en ruta fallida: TTL corto o retención acotada declarada.
7. H8 — reconciliar el vocabulario de `sufficiency_status` con `AX-M1-003`.

Dependen de decisión de Walvy y no deben iniciarse asumiendo:
8. H1 — el lifecycle de `RT-04` completo necesita el catálogo de triggers comerciales de fin efectivo de acceso, la instrucción de Legal sobre residual, y coordinación para las pruebas de restore/PITR.
9. H6 — M07 es alcance de producto, no deuda técnica.
