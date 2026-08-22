# -*- coding: utf-8 -*-
"""Respuestas de Kabeli a Walvy_Requerimientos_Evidencia_Tecnica_Kabeli_v1_0.xlsx.

Se completan las tres columnas de la hoja 01_Requerimientos: Estado,
Archivo/enlace entregado y Comentarios. La hoja 02_Detalle no tiene columnas de
respuesta —su "Comentarios / referencia" lo escribió Walvy— así que no se toca.

Regla de honestidad que atraviesa todo el archivo: se distingue lo que está en
`KabeliDev/main` de lo que está en un PR abierto, y se declara que
`walvy-org/main` está 99 commits atrás, así que hoy nada de esto es verificable
en el repositorio que audita el cliente. Un documento de evidencia que no lo
diga vale poco.
"""
NL = "\n"

BASE = ("Baseline: back-walvy KabeliDev/main 04a9cdd (2026-08-20) · "
        "front-walvy 050cb8d · 24 migraciones · 390 tests unitarios y 114 e2e en verde.")

SYNC = ("ADVERTENCIA DE VERIFICABILIDAD: walvy-org/main está en cc38d4a, 99 commits atrás. "
        "Nada de lo referenciado acá es visible todavía en el repositorio que audita Walvy; "
        "la sincronización es una decisión pendiente de Kabeli.")

RESPUESTAS = {}

RESPUESTAS["RT-01"] = dict(
    estado="Respondido",
    enlace="back-walvy · KabeliDev/main · commit 04a9cdd · 24 migraciones en src/migrations",
    comentario=(
        "Release y ambiente trazados. " + BASE + NL + NL +
        "El ambiente que se pretende acreditar es el construido desde las migraciones "
        "versionadas, no desde synchronize. Se deja constancia de una divergencia relevante "
        "para TEC-M1-015: el esquema que crean las migraciones y el que declaran las entidades "
        "no coinciden en el módulo de suscripciones (subscription contra subscriptions, plan "
        "contra subscription_plans, y payment_orders no existe en el esquema migrado), y "
        "app.module usa synchronize gobernado por DB_SYNC. Antes de fijar un ambiente como "
        "acreditable conviene resolver cuál de los dos esquemas es el de referencia." + NL + NL +
        SYNC
    ),
)

RESPUESTAS["RT-02"] = dict(
    estado="Respondido parcialmente",
    enlace="src/imports/kread/ (kread.service.ts, kread.mapper.ts, dynamo-dedup.service.ts) · PR #102",
    comentario=(
        "Lo que sí se puede acreditar desde el código: el dataflow end-to-end con K-read "
        "(POST /process-document, GET /status, GET /result), la deduplicación por huella de "
        "contenido con reserva condicional y TTL de 900 s, y el lifecycle del original bajo "
        "nuestro control." + NL + NL +
        "Sobre el lifecycle del original (RT-02.5/RT-02.6): el borrado ocurría al parsear con "
        "éxito y al cancelar, pero no al fallar. Se corrigió — PR #102, ya mergeado — de modo "
        "que un fallo permanente (non_processable, outdated) purga el original, porque un "
        "reintento del mismo archivo da el mismo resultado. Un fallo transitorio lo conserva, "
        "porque /retry lo reutiliza, y un fallo sin clasificar también por precaución. Queda "
        "abierto el plazo máximo para esos dos casos: depende del TTL de M01 que M01-DAT-021 "
        "deja «dependiente de la fuente específica M01», o de una regla de lifecycle en el "
        "bucket, que es capa de infraestructura Walvy." + NL + NL +
        "Lo que NO es respondible desde el código y queda como dependencia: rol contractual y "
        "DPA de K-read, hosting y región de procesamiento, subprocesadores, y logs y retención "
        "del tercero. KREAD_BASE_URL es una variable de entorno; la región efectiva sale de la "
        "configuración de despliegue, no del repositorio." + NL + NL +
        "Nota verificable: el código afirma en un comentario que «Kread borra su /result tras "
        "leerlo». Es una afirmación sobre el lifecycle del tercero que hoy sólo consta como "
        "comentario y debe acreditarse con configuración o evidencia del proveedor."
    ),
)

RESPUESTAS["RT-03"] = dict(
    estado="Fuera del alcance Kabeli / requiere infraestructura y contratos",
    enlace="—",
    comentario=(
        "No es respondible desde el repositorio. Las integraciones bajo nuestro alcance se "
        "configuran por variables de entorno (KREAD_BASE_URL, S3_REGION — cuyo valor en código "
        "es sólo un default), así que el mapa de regiones, países, hops y subprocesadores sale "
        "de la configuración de despliegue y de los contratos, no del código." + NL + NL +
        "Kabeli puede aportar el inventario de integraciones y su dataflow lógico; el mapa "
        "efectivo de regiones requiere la configuración de infraestructura, que es capa Walvy, "
        "y la conclusión jurídica sobre transferencias es de Walvy/Legal como el propio "
        "documento establece."
    ),
)

RESPUESTAS["RT-04"] = dict(
    estado="Respondido parcialmente · implementado en cuatro etapas, dos en main y dos en revisión",
    enlace=(
        "En KabeliDev/main: migración 1786000025000-HabilitarSupresionDeCuenta · "
        "src/users/account-lifecycle.ts · account-lifecycle.service.ts · "
        "guardias en diagnosis-summary-writer.service.ts y notification.service.ts. "
        "En PR abierto: #108 supresión · #109 reconciliación · #110 regla de acceso · "
        "#111 suite e2e. Documento: inventario de persistencia (RT-04.1)."
    ),
    comentario=(
        "RT-04.1 · inventario: entregado como documento derivado del esquema, no escrito a mano: "
        "55 tablas con vínculo directo a app_user, agrupadas por acción de borrado, con el "
        "propósito que documenta cada COMMENT ON TABLE." + NL + NL +
        "Hallazgo que condicionaba todo lo demás: la supresión NO era ejecutable por ninguna vía, "
        "porque el esquema documentaba dos modelos incompatibles. La migración 004 declara que en "
        "app_user «nunca se ejecuta DELETE físico»; la 017 declara ON DELETE SET NULL en la "
        "evidencia legal justificándolo con que «la eliminación de la cuenta pone user_id en NULL "
        "y conserva la fila con user_pseudonym». El mecanismo de la 017 sólo dispara con un DELETE "
        "físico, que la 004 prohíbe — y con sólo soft delete las 41 cascadas quedaban dormidas, "
        "así que marcar deleted_at no suprimía nada aguas abajo. Además seis claves foráneas sin "
        "ON DELETE declarado hacían fallar el DELETE. Se resolvió en nuestra capa, que es la que "
        "TR-DB-01 nos asigna, con un modelo de dos etapas: deleted_at marca el cierre y abre la "
        "ventana; la supresión es el borrado físico." + NL + NL +
        "RT-04.2 · fin efectivo de acceso: NO implementado como gatillo automático, y el "
        "bloqueante es más profundo que el catálogo pendiente de Walvy — SubscriptionsModule no "
        "está importado en la aplicación, así que hoy no hay señal comercial que observar. Se deja "
        "escrita y probada la regla de acceso efectivo (PR #110), que es temporal y no de estado: "
        "el acceso vale mientras el período no venza, así que una suscripción cancelada o morosa "
        "con período vigente CONSERVA acceso, tal como TR-RET-01 exige. Falta que Walvy confirme "
        "que ese criterio es el fin efectivo del derecho de acceso." + NL + NL +
        "RT-04.3 · congelamiento y reactivación: implementado y en main. La ventana se abre con "
        "endAccess, su plazo se lee de configuración con 90 días por defecto, y el congelamiento "
        "impide producir diagnóstico nuevo y encolar avisos conservando el dato intacto. La "
        "reactivación es idempotente y se rechaza si la ventana ya venció." + NL + NL +
        "RT-04.4 y RT-04.5 · supresión con resultado por componente: implementado, en revisión "
        "(PR #108). El inventario de tablas se descubre del catálogo de PostgreSQL en tiempo de "
        "ejecución y no de una lista escrita a mano, porque una lista se desactualiza en silencio "
        "y el modo de falla sería informar éxito habiendo dejado dato atrás. La supresión reporta "
        "filas eliminadas por tabla y residuo, es idempotente, y elimina también los objetos en "
        "almacenamiento —avatar y originales de cartola— que la cascada no alcanza." + NL + NL +
        "RT-04.6 y RT-04.7 · no-resurrección: implementado, en revisión (PR #109), CON UNA "
        "DEPENDENCIA QUE NO PODEMOS RESOLVER. El registro de supresiones vive en audit_log, o sea "
        "en la misma base, y un PITR lo retrocede junto con todo lo demás: leerlo para reconciliar "
        "sería preguntarle al testigo que el restore acaba de borrar. Por eso la reconciliación no "
        "lee el registro, lo recibe como entrada, y el registro se exporta para persistirlo FUERA "
        "de la base. Esa persistencia externa es capa de infraestructura, o sea Walvy según "
        "TR-AWS-01. Sin ella la no-resurrección NO es acreditable por más código que escribamos. "
        "Es el control compartido que RT-04.6 describe." + NL + NL +
        "RT-04.8 · retención residual: no implementada, y correctamente. Su existencia y alcance "
        "los define Walvy/Legal, y no corresponde a Kabeli decidir si existe obligación residual." + NL + NL +
        "RT-04.9 · arquitectura lógica de datos: entregado. 24 migraciones versionadas con PK, FK, "
        "CHECK e índices explícitos, índices únicos parciales que respetan el soft delete, y "
        "COMMENT ON TABLE y COMMENT ON COLUMN documentando finalidad por campo." + NL + NL +
        "Evidencia reproducible: suite e2e (PR #111) que recorre entrada a la ventana, acciones "
        "bloqueadas, reactivación, supresión con evidencia pre/post por componente, supervivencia "
        "del registro sin identidad, supervivencia de la evidencia de consentimiento "
        "seudonimizada, y reconciliación tras un restore simulado. No corre en CI: los e2e del "
        "proyecto se ejecutan con pnpm test:e2e contra base real." + NL + NL +
        SYNC
    ),
)

RESPUESTAS["RT-05"] = dict(
    estado="Respondido parcialmente",
    enlace="src/common/utils/log-redaction.util.ts + spec · PR #99 (mergeado)",
    comentario=(
        "Se encontraron y corrigieron tres exposiciones concretas (PR #99, mergeado): el número "
        "de cuenta bancaria se escribía en claro en el log de toda importación exitosa, tomado de "
        "la metadata que devuelve K-read; el correo del pagador se escribía completo en el webhook "
        "de pagos; y la herramienta de reset de dev escribía el correo del usuario." + NL + NL +
        "La lista de claves redactadas no cubría el OTP, que viaja bajo el nombre de campo `code`. "
        "Se agregó con un límite a la izquierda para que statusCode y error_code sigan apareciendo "
        "en el log: endurecer el OTP no puede pagarse cegando el diagnóstico de errores. Los "
        "nombres compuestos que sí llevarían un secreto (verification_code, otp_code, reset_code) "
        "van en la lista por sufijo." + NL + NL +
        "Lo que queda abierto y conviene declarar: la redacción se aplica en el borde de error y "
        "en llamadas puntuales, no en el transporte del logger. Sobre 126 llamadas a logger en 21 "
        "archivos, la utilidad se invoca en unas pocas. O sea que hoy la garantía es por convención "
        "y no por construcción, y cablearla en el transporte es trabajo pendiente de Kabeli." + NL + NL +
        "Buena práctica que sí conviene citar como evidencia: el webhook de pagos registra las "
        "claves del payload y no su contenido."
    ),
)

RESPUESTAS["RT-06"] = dict(
    estado="Respondido · conforme por diseño, falta un artefacto",
    enlace="front-walvy 050cb8d · expo/services/biometrics.ts · expo/features/auth/hooks/useBiometricLogin.ts",
    comentario=(
        "Conforme por diseño y verificable por revisión de código. La autenticación usa "
        "LocalAuthentication.authenticateAsync del sistema operativo y lo único que devuelve es un "
        "booleano: la API del SO no expone la plantilla a la aplicación, así que ningún artefacto "
        "biométrico puede salir del dispositivo. Lo único que se persiste es la preferencia "
        "walvy_biometric_enabled con valor true o false, en almacenamiento seguro del dispositivo. "
        "Los tokens de sesión también van en almacenamiento seguro, no en almacenamiento plano." + NL + NL +
        "disableDeviceFallback está activo, así que el fallback es la contraseña de Walvy y no el "
        "PIN del dispositivo, consistente con lo que TEC-M1-006 exige." + NL + NL +
        "Falta el artefacto que pide RT-06.3: la traza de red negativa sobre el flujo biométrico "
        "exitoso y fallido. Es trabajo de Kabeli y no depende de nadie más."
    ),
)

RESPUESTAS["RT-07"] = dict(
    estado="No implementado en el release vigente",
    enlace="—",
    comentario=(
        "No existe en el código: sin proveedor de speech-to-text, sin manejo de audio y sin "
        "dependencia relacionada. Búsqueda negativa de whisper, speech, transcri, audio, deepgram "
        "y assemblyai en src/ sin resultados funcionales, y tampoco hay proveedor de IA — sin "
        "coincidencias de anthropic, openai, bedrock ni gemini en código ni en package.json." + NL + NL +
        "Las nueve subpreguntas RT-07.1 a RT-07.9 se responden «no implementado». Se declara así "
        "y no como «no aplica»: el propio paquete advierte que un pendiente no habilita a asumir "
        "Cumple ni No Aplica. Cuando M07 se construya, estas preguntas siguen vigentes."
    ),
)

RESPUESTAS["RT-08"] = dict(
    estado="Respondido parcialmente · bloqueado por artefactos legales",
    enlace="src/migrations/1786000017000-VersionamientoLegal.ts · src/legal/ · PR #99",
    comentario=(
        "El modelo de evidencia está construido y es sólido. legal_document_version guarda "
        "versión, título, content_hash_sha256 con CHECK de formato, effective_at, "
        "requires_user_reacceptance, índice único parcial de versión activa y CHECK de fuente de "
        "contenido. user_legal_acceptance guarda user_pseudonym, presented_at y accepted_at con "
        "CHECK de coherencia y de orden, acceptance_source, acceptance_action, channel y "
        "app_version, y usa ON DELETE SET NULL para conservar la evidencia al suprimir la "
        "identidad — verificado de punta a punta: tras suprimir una cuenta la fila sobrevive con "
        "user_id en NULL y el seudónimo intacto. El registro de aceptación lo crea el flujo de "
        "registro, no un proceso aparte." + NL + NL +
        "Faltan dos campos contra los mínimos de RT-08.2: el ALCANCE O FINALIDAD del "
        "consentimiento no se registra, y la REVOCACIÓN no está modelada — acceptance_action "
        "admite presented, accepted y declined, y «declined» es no aceptar lo que se presenta, no "
        "revocar lo otorgado. Ninguno de los dos exige rediseño: la tabla es un historial de sólo "
        "inserción, así que se resuelven con una columna de alcance y un valor más en el CHECK. "
        "Antes de agregarlos hace falta que Walvy/Privacidad defina qué alcance se registra." + NL + NL +
        "DEPENDENCIA BLOQUEANTE, y no es de Kabeli: M01-PRV-001 exige que Términos y Política "
        "estén congelados con versión y hash antes de validar. Hoy no existen. Mientras no se "
        "materialicen, cualquier aceptación que registremos queda referida a un texto que no es "
        "el oficial, y este requerimiento no puede llegar a Conforme por más que el esquema esté "
        "completo. Está asignado a Jose + Andrea (M01-PRV-001) y Erick + Jose (M01-PRV-002)."
    ),
)

RESPUESTAS["RT-09"] = dict(
    estado="No implementado · el esquema no soporta el requisito",
    enlace="src/ai/entities/ (sólo entidades) · migración 1786000012000",
    comentario=(
        "Conviene separar dos cosas que es fácil confundir. src/ai/ contiene SÓLO entidades: "
        "ai_conversation, ai_message, ai_context_snapshot, ai_tool_invocation y faq_article. "
        "Están registradas y las crea la migración 1786000012000, pero no hay servicio, ni "
        "controlador, ni consumo. Que la tabla exista no es evidencia de que la funcionalidad "
        "exista." + NL + NL +
        "Y el esquema no soporta el requisito: ai_conversations tiene id, user_id, title, "
        "created_at y updated_at, y nada más. No existe expires_at ni last_interaction_at ni TTL. "
        "La continuidad funcional máxima de 24 horas desde la última interacción que exige "
        "TR-M07-02 no sólo no está implementada: no hay columna donde apoyarla. Implementarla "
        "requiere migración." + NL + NL +
        "Detalle menor de trazabilidad: created_at y updated_at de las tablas ai_* son timestamp "
        "sin zona, mientras la migración 1786000019000 normalizó la auditoría a timestamptz. Esas "
        "tablas quedaron fuera de esa normalización."
    ),
)


# Resumen para la celda de Comentarios. El detalle completo va a la hoja nueva:
# con texto ajustado, un comentario de 4.000 caracteres deja la fila ilegible.
RESUMENES = {
 "RT-01": (
   "Release trazado: back-walvy KabeliDev/main 04a9cdd, front-walvy 050cb8d, 24 migraciones "
   "versionadas. Se levanta una divergencia que conviene resolver antes de fijar el ambiente "
   "acreditable: el esquema de las migraciones y el de las entidades no coinciden en el módulo "
   "de suscripciones. Ver hoja 04."),
 "RT-02": (
   "Dataflow con K-read documentable desde el código, incluida la deduplicación por huella. El "
   "lifecycle del original se corrigió: un fallo permanente ahora purga el archivo. Rol "
   "contractual, región, subprocesadores y logs del tercero no son respondibles desde el "
   "repositorio. Ver hoja 04."),
 "RT-03": (
   "No respondible desde el repositorio: las integraciones se configuran por variables de "
   "entorno, así que el mapa de regiones y subprocesadores sale de la configuración de "
   "despliegue y de los contratos. Kabeli aporta el dataflow lógico. Ver hoja 04."),
 "RT-04": (
   "Implementado en cuatro etapas: la ventana y el congelamiento están en main; la supresión, la "
   "reconciliación y la evidencia e2e están en PRs abiertos (#108 a #111). Se resolvió una "
   "contradicción del esquema que hacía la supresión inejecutable. El gatillo automático y la "
   "persistencia externa del registro siguen abiertos, el segundo por depender de "
   "infraestructura. Ver hoja 04, que es la respuesta más extensa del archivo."),
 "RT-05": (
   "Tres exposiciones concretas encontradas y corregidas, entre ellas el número de cuenta "
   "bancaria en claro en los logs. La lista de claves redactadas ahora cubre el OTP. Queda "
   "pendiente cablear la redacción en el transporte del logger: hoy la garantía es por "
   "convención y no por construcción. Ver hoja 04."),
 "RT-06": (
   "Conforme por diseño y verificable por revisión de código: la API del sistema operativo sólo "
   "devuelve un booleano, así que ningún artefacto biométrico puede salir del dispositivo. Falta "
   "el artefacto que pide RT-06.3, la traza de red negativa. Ver hoja 04."),
 "RT-07": (
   "No implementado en el release vigente: no hay proveedor de speech-to-text, ni manejo de "
   "audio, ni proveedor de IA. Las nueve subpreguntas se responden así y no como «no aplica»: "
   "siguen vigentes para cuando M07 se construya. Ver hoja 04."),
 "RT-08": (
   "El modelo de evidencia está construido y verificado de punta a punta, incluida la "
   "supervivencia seudonimizada tras suprimir la cuenta. Faltan dos campos de los mínimos de "
   "RT-08.2: alcance del consentimiento y revocación. Bloqueante externo: los artefactos legales "
   "congelados de M01-PRV-001 no existen. Ver hoja 04."),
 "RT-09": (
   "No implementado, y el esquema no soporta el requisito: las tablas ai_* existen pero sin "
   "servicio ni consumo, y no hay columna donde apoyar el límite de 24 horas. Que la tabla "
   "exista no es evidencia de que la funcionalidad exista. Ver hoja 04."),
}
