# -*- coding: utf-8 -*-
"""Parchea la matriz revisada de Walvy con los 7 ajustes de alcance -> v1.1.

Sólo se editan las columnas que le corresponden a Kabeli:
  C Control a validar · D Subcriterios · E Origen · F Relación funcional M1
  P Acción / complemento requerido
NO se toca:
  I/J (validación y comentario de alcance de Walvy) ni N/O (cumplimiento),
  ni R Estado de cierre, que es FÓRMULA derivada de I y N: se actualizará sola
  cuando Walvy ponga "Aceptado" en la revisión final acotada.
"""
B = "• "   # bullet, misma convención que el archivo original
NL = "\n"

def bullets(*items):
    return NL.join(B + i for i in items)

AJUSTES = {}

AJUSTES["TEC-M1-003"] = dict(
    C="Los documentos obligatorios deben abrirse y aceptarse desde el propio documento; "
      "la aceptación debe quedar trazable y versionada, y ese mismo acto afirmativo debe "
      "servir de evidencia del consentimiento financiero central sin introducir una UX adicional.",
    D=bullets(
      "Apertura de cada documento; «Aceptar» se habilita sólo al alcanzar el final del contenido (M01-RGL-002).",
      "Cerrar o volver antes de aceptar conserva el documento pendiente. El silencio no constituye aceptación.",
      "«Crear mi cuenta» sólo con formulario válido y ambas aceptaciones registradas.",
      "La aceptación no puede registrarse desde el formulario de Registro (M01-PRV-003).",
      "Obligatorio vs opcional distinguido por documento.",
      "Evidencia por aceptación: user_id seudónimo, document_type, version, effective_at, "
      "presented_at, channel, app_version, content_hash/referencia y action (M01-PRV-002).",
      "Nombre/versión/hash o URL de T&C y Política congelados antes de ejecutar la validación (M01-PRV-001).",
      "El mismo acto afirmativo M01 registra el consentimiento financiero central: alcance/finalidad "
      "y versiones documentales asociadas (M01-DAT-061, TR-CONS-01). Sin pantalla, modal ni checkbox adicional.",
      "Reaceptación exigible sólo cuando cambia la versión o la regla aplicable.",
    ),
    E="Producto v2.6 + Solicitud técnica Walvy + Paquete Protección de Datos (TR-CONS-01)",
    F="M1-V09 / M1-V11 / M1-V12 + M01-RGL-002 + M01-PRV-001/002/003",
    P="Gate B (evidencia): RT-08. Dependencia Walvy/Legal: texto y alcance del consentimiento, "
      "y efecto funcional de no aceptar una versión obligatoria." + NL +
      "Dependencia bloqueante declarada: M01-PRV-001 exige artefactos legales congelados con versión "
      "y hash. Hoy no existen, así que M01-PRV-002 / TC-M01-035 no pueden pasar y cualquier aceptación "
      "que se registre queda referida a un texto que no es el oficial. Asignado a Jose + Andrea "
      "(M01-PRV-001) y Erick + Jose (M01-PRV-002); no es un pendiente de Kabeli.",
)

AJUSTES["TEC-M1-007"] = dict(
    C="El usuario debe poder guardar/salir o postergar sin avanzar indebidamente y retomar desde un "
      "checkpoint útil, conservando sólo el estado y la correlación mínimos necesarios para la retoma.",
    D=bullets(
      "«Guardar y salir» conserva la información ingresada y sale del flujo; no se describe como una "
      "omisión que avanza al paso siguiente (M1-V25).",
      "Postergar el Foco del Mes conserva el estado pendiente y aplica la salida de postergación; "
      "no avanza directo a carga documental (M1-V29).",
      "Retoma en los tres puntos de pausa: antes de la carga, tras carga parcial o procesada, "
      "y durante el análisis (M1-V58 / M1-V59 / M1-V60).",
      "No se repiten pasos completados ni se duplican documentos o jobs; cada checkpoint reabre "
      "en el destino y estado correctos (M01-RGL-008).",
      "No se genera una primera lectura concluyente mientras no se complete la base requerida; "
      "sólo los estados permitidos por el gate habilitan avance (M01-RGL-012).",
      "Contenido del checkpoint: sólo estado y correlación mínima de retoma. No duplica payload "
      "financiero ni documentos.",
      "Lifecycle del checkpoint: se limpia o reemplaza al quedar obsoleto y al cerrar el onboarding "
      "(M01-RGL-016).",
    ),
    E="Producto v2.6 + Paquete Protección de Datos (PP-07 · minimización del metadato de continuidad)",
    F="M1-DP-009 (referencia principal) + M1-V58 / M1-V59 / M1-V60 + M01-RGL-008 / 012 / 016 · "
      "auxiliares: M1-V25 / M1-V29",
    P="Gate B Kabeli: store/schema del checkpoint, lifecycle y prueba de limpieza y retoma (RT-04.1). "
      "La ventana de 90 días no se duplica acá: vive en TEC-M1-021." + NL +
      "Propuesta de reasignación: M1-V44 (progreso durante el procesamiento) deja de ser relación de "
      "este control y pasa como auxiliar a TEC-M1-012, cuyo eje es M01-RGL-014 — la misma regla que "
      "gobierna V44. Queda a confirmación de Walvy en la revisión final.",
)

AJUSTES["TEC-M1-013"] = dict(
    C="M01-RGL-012 debe actuar como gate único de suficiencia, resolviendo sobre una matriz única "
      "de indicadores y motivos, con salida determinista.",
    D=bullets(
      "Normalización previa de cada indicador a sufficient / pending / missing, conservando "
      "detection_status, data_origin, confidence y evidence (M01-RGL-013).",
      "Cuatro salidas del gate: falta elemento mínimo obligatorio → blocked; base mínima + pendiente "
      "crítico → partial bloqueado; base mínima + sólo pendientes no críticos → partial permitido; "
      "sin pendientes relevantes → complete.",
      "Cobertura por variante: V48 revisión/suficiencia previa al Diagnóstico (no cierre del "
      "onboarding), V49 partial permitido, V50 partial bloqueado, V51 blocked por datos clave, "
      "V52 blocked sin base documental y sin ruta manual sustitutiva.",
      "Fronteras documentadas: movimientos recientes pendientes bloquean; pagos recurrentes pendientes "
      "pueden permitir parcial cuando ingreso, movimientos y compromisos están suficientemente "
      "establecidos; la ausencia de instrumentos de pago no bloquea por sí sola.",
      "«Sin diagnóstico» (V56) se resuelve por estos gates y no como cuarta tarjeta equivalente "
      "a En control / Atención / Riesgo.",
      "reason explicativo por salida. Sin ramas no documentadas ni combinaciones extrapoladas fuera "
      "de reglas y fixtures.",
      "Los cinco indicadores núcleo con valores canónicos; «detectado» no equivale a «confirmado»; "
      "trazabilidad reproducible entre UI y payload (M01-RGL-013).",
    ),
    F="M1-V48 / V49 / V50 / V51 / V52 + M01-RGL-011 / 012 / 013 + AX-M1-003 + M1-DP-008 / M1-DP-009",
    P="Mapeo de vocabulario: DECLARADO. La salida canónica del gate es blocked / partial bloqueado / "
      "partial permitido / complete (AX-M1-003, M01-RGL-012); el CHECK de la base declara "
      "sufficient / partial / insufficient / blocked. La proyección entre ambos quedó declarada y "
      "probada en código, sin migrar el CHECK ni tocar el contrato expuesto. insufficient y blocked "
      "proyectan los dos a blocked canónico: la base es más fina y distingue «no había documento "
      "usable» de «faltaba un indicador obligatorio»." + NL +
      "No conformidad 1 · ABIERTA — partial bloqueado no se emite. Cuando un indicador crítico no es "
      "usable la regla devuelve insufficient con el diagnóstico parcial deshabilitado, así que el caso "
      "de V50 sale como blocked. El comportamiento es el que V50 espera, pero la etiqueta canónica no "
      "aparece y no hay dónde ponerla: el modo de diagnóstico y el permiso de parcial se calculan y se "
      "descartan, no se persisten, así que desde la columna sola la distinción no es recuperable." + NL +
      "No conformidad 2 · CORREGIDA — se resolvía complete donde la frontera de V50 dice parcial. "
      "Causa raíz: la cláusula «basta uno del par» gobierna el bloqueo (si hay base mínima) y se había "
      "reutilizado para decidir la completitud, que es otra pregunta. El arreglo distingue ausente de "
      "pendiente: un miembro del par ausente con el otro detectado sigue siendo completo; uno por "
      "confirmar, inferido o manual asistido degrada a parcial." + NL +
      "Ninguna de las dos reabre Producto: no es que dos documentos de Walvy se contradigan, es la "
      "implementación divergiendo de una frontera que Walvy ya dejó escrita." + NL +
      "V48 debe retirar sus asociaciones de diagnóstico/cierre (HU-025; RN-ONB-009/011/012/016) y "
      "alinearse a revisión/suficiencia (HU-024), conforme la decisión PO de V48.",
)

AJUSTES["TEC-M1-014"] = dict(
    C="El estado financiero debe calcularse con la regla canónica, y la presión principal y el CTA "
      "dominante aplicarse después del estado sin alterarlo.",
    D=bullets(
      "Precondición: M01-RGL-012 habilita Diagnóstico. La secuencia es suficiencia → estado → presión/CTA.",
      "Ratio canónico sobre el snapshot mensual: egreso mensual proyectado / ingreso mensual reconocido.",
      "ratio < 0,90 → En control (V53); 0,90 ≤ ratio < 1,00 → Atención (V54); ratio ≥ 1,00 → Riesgo (V55).",
      "mora_confirmada (obligación vencida + saldo pendiente + evidencia suficiente) es el único "
      "override determinista de Riesgo aprobado para el MVP.",
      "Datos por confirmar, movimientos pendientes, fugas o compromisos no pintan estado por sí solos: "
      "la calidad y completitud pertenecen al gate de suficiencia; las señales económicas explican "
      "presión y CTA después de determinar el estado. Un partial permitido puede seguir mostrando "
      "En control si el ratio está bajo el umbral.",
      "Una única presión principal y un único CTA dominante; el resto queda como información "
      "secundaria (V57, M01-RGL-015 / M01-RGL-016).",
      "Riesgo no activa automáticamente M04: Ruta Despeje conserva sus propios criterios de deuda "
      "confirmada, suficiencia y presión.",
      "Versionamiento: rule/config version y timestamp de evaluación asociados al estado calculado.",
      "Evitar doble conteo de inputs.",
    ),
    F="M1-V53 / V54 / V55 + M1-V57 + M1-DP-006 + AX-M1-004 + M01-RGL-012 / 015 / 016",
    P="Dependencia declarada: el catálogo de valores de dominant_pressure_code no está enumerado ni en "
      "la Matriz v2.6 ni en AX-M1-004; se cita la regla M01-RGL-015 pero nunca sus valores. Sin ese "
      "catálogo el determinismo de la presión y el CTA no es demostrable en Etapa 2. No modifica la "
      "regla de estado ni reabre Producto." + NL +
      "V56 («Sin diagnóstico») queda asignada a TEC-M1-013, no a este control: su decisión PO establece "
      "que se resuelve por los gates de suficiencia previos al diagnóstico.",
)

AJUSTES["TEC-M1-016"] = dict(
    C="Aplicar las medidas técnicas mínimas para credenciales, secretos y acceso a los componentes del "
      "M1 bajo responsabilidad de Kabeli, sin absorber la capa de infraestructura AWS que acredita Walvy.",
    D=bullets(
      "Kabeli · Contraseña con hash adaptativo y salt; sin plaintext ni cifrado reversible "
      "(M01-SEC-001, PP-05).",
      "Kabeli · Secretos fuera de código, build y logs; consumo desde Vault/Secrets Manager o "
      "equivalente aprobado.",
      "Kabeli · Cifrado en tránsito en todas las superficies de aplicación.",
      "Kabeli · Autorización efectiva en backend: mínimo privilegio y owner check por recurso, con "
      "matriz de autorización verificable caso A / caso B (M01-AUT-001).",
      "Kabeli · Seguridad móvil aplicable: almacenamiento local, credenciales, comunicaciones y uso "
      "de APIs del dispositivo (TR-MOB-01).",
      "Kabeli · MFA y RBAC exigibles sólo si existe superficie o API administrativa dentro del "
      "alcance del M1.",
      "Walvy · IAM de infraestructura, cifrado de servicios y KMS, red, servicio de base de datos "
      "administrado, backups/PITR, hardening y logging/monitoreo de AWS (TR-AWS-01, TR-DB-01).",
      "Walvy · Rotación de llaves y secretos de la capa de infraestructura.",
    ),
    E="Contractual – Anexo 2 + Paquete Protección de Datos (TR-SEC-01 / TR-MOB-01 / TR-AWS-01 / TR-DB-01)",
    F="Transversal M1 + M01-SEC-001 / M01-AUT-001 + TR-SEC-01 / TR-MOB-01 / TR-AWS-01 / TR-DB-01",
    P="Gate B Kabeli: app/backend/mobile y consumo de secretos (RT-01, RT-05). En los controles "
      "compartidos cada parte acredita su capa, sin fusionar ownership." + NL +
      "Precisión para no perder cobertura del Anexo 2: cuentas nominativas, altas/bajas y "
      "revisión/revocación periódica de permisos siguen cubiertas en TEC-M1-020 (soberanía) y no se "
      "eliminan del alcance al reasignar la capa de infraestructura a Walvy." + NL +
      "Pendiente de confirmación: si existe o no superficie/API administrativa en el M1, para cerrar "
      "la aplicabilidad de MFA/RBAC.",
)

AJUSTES["TEC-M1-021"] = dict(
    C="El tratamiento de datos personales del M1 debe cumplir las obligaciones del Anexo 10 y el "
      "lifecycle definido por Walvy en el paquete de Protección de Datos, distinguiendo los plazos de "
      "lifecycle de los plazos de SLA contractual.",
    D=bullets(
      "Cliente = Responsable; Kabeli = Encargado bajo instrucciones documentadas.",
      "Subencargados sólo con autorización previa escrita y obligaciones equivalentes.",
      "QA con datos anonimizados o seudonimizados cuando aplique. Segregación de ambientes.",
      "La ventana de 90 días comienza ÚNICAMENTE con el fin efectivo del derecho de acceso/licencia y "
      "opera como recuperación/reactivación con tratamiento funcional congelado. La mera inactividad o "
      "un fallo de pago mientras el acceso siga vigente no la gatillan (TR-RET-01).",
      "Solicitud confirmada de supresión: cese funcional y supresión sin esperar los 90 días. La "
      "existencia y el alcance de una retención residual los define Walvy/Legal, y debe quedar "
      "segregada y fuera de todo uso funcional.",
      "No-resurrección: tras un restore/PITR ejecutado por Walvy, la aplicación conserva las "
      "supresiones previas y no reactiva datos suprimidos.",
      "M01-DAT-021 (documento original cargado en M01) NO hereda el plazo de 24 h aplicable a los "
      "originales M04/M05/M06 procesados por K-read; su regla transitoria es propia de M01 y no "
      "convierte a Walvy en repositorio permanente (TR-DOC-01).",
      "El plazo de 72 h de aviso ante incidente de software con PII es un SLA contractual de "
      "notificación del Anexo 10, no un parámetro de lifecycle ni de retención.",
      "Retorno o eliminación segura a requerimiento o al término, con evidencia.",
    ),
    E="Contractual – Anexo 10 + Paquete Protección de Datos (TR-RET-01 / TR-DOC-01)",
    F="Transversal M1 + M01-DAT-021 / M01-DAT-061 + TR-RET-01 / TR-DOC-01",
    P="Gate B Kabeli: inventario de stores y persistencias de aplicación, lifecycle funcional y prueba "
      "E2E de congelamiento, reactivación y supresión (RT-04.1 a RT-04.5, RT-04.9)." + NL +
      "Dependencias Walvy: catálogo de triggers comerciales que constituyen fin efectivo de acceso "
      "(RT-04.2), conclusión de Legal sobre residual y transferencias (RT-04.8, RT-03), y ejecución de "
      "restore/PITR en AWS — RT-04.6 y RT-04.7 son prueba coordinada, no entregable unilateral de "
      "Kabeli." + NL +
      "Consulta para la revisión final: el comentario de alcance abre con «Anexo 3.10». Confirmar si "
      "refiere al Anexo 10 o al punto 10 del Anexo 3, para citar la fuente correcta.",
)

AJUSTES["TEC-M1-023"] = dict(
    C="Los marcos de seguridad se aplican por componente y tecnología realmente desplegada en el M1, "
      "con controles seleccionados y justificados. No constituye certificación CIS, ASVS ni MASVS "
      "del módulo.",
    D=bullets(
      "Inventario de componentes y tecnologías efectivamente desplegados en M1, con versión.",
      "Por componente: marco o benchmark aplicable → controles seleccionados → aplica / no aplica con "
      "justificación / excepción aprobada → evidencia.",
      "OWASP ASVS y MASVS para aplicación, API y móvil. CIS Benchmark para la tecnología y versión "
      "efectivamente desplegada cuando exista.",
      "No se declara nivel L1/L2 ni nivel ASVS/MASVS completo, ni como baseline ni como resultado.",
      "Remediación sólo de hallazgos aplicables y acordados; excepciones registradas y justificadas.",
      "Para PostgreSQL, CIS valida la configuración segura del servicio/motor en la capa operada por "
      "Walvy y no traslada a Walvy la responsabilidad de Kabeli sobre modelo, esquema y arquitectura "
      "lógica de datos (TR-CIS-01).",
    ),
    E="Solicitud técnica Walvy – no requisito contractual explícito + Paquete Protección de Datos (TR-CIS-01)",
    F="Transversal M1 + TR-CIS-01",
    P="Dependencia Walvy Seguridad, bloqueante del alcance: selección de controles y aplicabilidad por "
      "componente, más el CIS de AWS, del servicio de base de datos y de la infraestructura. "
      "Gate B Kabeli: evidencia de su capa (app, API y móvil) una vez definida esa selección. "
      "Este control no puede pasar de «Por validar» a «Aplica» antes de recibir la selección.",
)

# Traza para la hoja 05: (resumen del comentario Walvy, qué se ajustó, estado en código)
TRAZA = {
 "TEC-M1-003": (
   "Completar M1-V09/V11/V12 + M01-RGL-002 + M01-PRV-001/002/003. Usar el acto afirmativo M01 para el "
   "consentimiento financiero central, sin nueva UX. Registrar M01-DAT-061, evento/fecha-hora, versiones "
   "T&C/Política y alcance. Reaceptación sólo por versión/regla. Gate B: RT-08.",
   "Relación ampliada a V09/V11/V12 + RGL-002 + PRV-001/002/003. Subcriterios completados con los campos "
   "mínimos de evidencia de M01-PRV-002, el congelamiento previo de artefactos de M01-PRV-001 y la regla "
   "de reaceptación. Origen complementado con TR-CONS-01.",
   "Esquema presente y sólido (legal_document_version + user_legal_acceptance, con hash SHA-256, "
   "seudónimo y versión). Faltan la columna de alcance/finalidad y el estado de revocación. "
   "Bloqueante externo: los artefactos legales congelados no existen."),
 "TEC-M1-007": (
   "Referencia principal M1-DP-009 + V58-V60 + M01-RGL-008/012/016; V25/V29 auxiliares y V44 no principal. "
   "Checkpoint mínimo, con limpieza al quedar obsoleto o al completar onboarding. Gate B Kabeli. "
   "90 días: TEC-M1-021.",
   "Relación reanclada a DP-009 + V58/V59/V60 + RGL-008/012/016, con V25/V29 declarados auxiliares. "
   "Subcriterios completados con el contenido y el lifecycle del checkpoint. Se propone reasignar V44 "
   "a TEC-M1-012.",
   "Sin verificar en esta ronda: la revisión de código se centró en el paquete de Protección de Datos."),
 "TEC-M1-013": (
   "Ampliar la relación a V48-V52 + M01-RGL-012/013 + AX-M1-003. El gate cubre complete, partial "
   "permitido, partial bloqueado y blocked; no sólo V50.",
   "Relación ampliada a V48-V52 + RGL-011/012/013 + AX-M1-003 + DP-008/009. Subcriterios reescritos con "
   "las cuatro salidas, la cobertura por variante y las fronteras documentadas. Se declaran dos no "
   "conformidades en la columna de acción.",
   "Proyección canónica declarada y probada (PR #101). No conformidad 2 CORREGIDA (PR #103): un pendiente "
   "del par ya degrada a parcial. No conformidad 1 ABIERTA: partial permitido / partial bloqueado no "
   "tiene dónde persistirse."),
 "TEC-M1-014": (
   "Completar relación con V53-V55 + V57 + M1-DP-006 / AX-M1-004 + M01-RGL-015. Mantener la secuencia "
   "suficiencia → estado → presión/CTA.",
   "Relación completada a V53/V54/V55 + V57 + DP-006 + AX-M1-004 + RGL-012/015/016. Subcriterios "
   "reescritos con el ratio canónico, los tres umbrales, el único override y la secuencia. V56 "
   "reasignada a TEC-M1-013.",
   "Regla canónica y override de mora_confirmada presentes; rule_version existe desde la migración 018. "
   "Falta el catálogo de dominant_pressure_code, que es dependencia de Producto."),
 "TEC-M1-016": (
   "Agregar M01-SEC-001 / M01-AUT-001. MFA/RBAC sólo si existe superficie/API admin. Gate B Kabeli: "
   "app/backend/mobile y consumo de secretos. Walvy/Infra: IAM/KMS/red/DB administrada/backups-PITR/"
   "hardening/logging AWS.",
   "Control reformulado para acotar la capa Kabeli. Subcriterios separados por capa, con SEC-001 y "
   "AUT-001 incorporados y MFA/RBAC condicionados. Origen y relación complementados con los "
   "transversales TR-*. Se precisa que TEC-M1-020 conserva cuentas nominativas y revisión de permisos.",
   "Verificado: bcrypt con 12 rondas y tope de 72 bytes validado en los tres DTOs; owner check "
   "implementado; secretos fuera del repositorio. Pendiente confirmar si existe superficie/API admin."),
 "TEC-M1-021": (
   "PD M01: 90 días sólo desde fin efectivo de acceso; inactividad o fallo de pago vigente no gatillan; "
   "la ventana es tratamiento congelado. Supresión confirmada no espera. No-resurrección post PITR. "
   "M01-DAT-021 no hereda las 24 h de K-read. 72 h es sólo SLA contractual.",
   "Control reformulado para distinguir lifecycle de SLA. Subcriterios completados con el gatillo real de "
   "los 90 días, el congelamiento, la no-resurrección, la exclusión de la herencia de las 24 h y la "
   "naturaleza contractual de las 72 h. Se separan las dependencias de Walvy en la columna de acción.",
   "Lifecycle NO implementado: no hay endpoint de supresión, ni ventana de 90 días, ni estado de "
   "congelamiento, ni reconciliación post-restore. Existen las columnas deleted_at pero nada las mueve. "
   "El enum de suscripción sí distingue past_due de cancelled/expired."),
 "TEC-M1-023": (
   "No asumir CIS L1/L2 ni nivel ASVS/MASVS completo como baseline o certificación. Por componente y "
   "tecnología real: marco → controles seleccionados → aplica/N-A-excepción → evidencia. "
   "Walvy Seguridad: selección/aplicabilidad y CIS de AWS/DB/infra.",
   "Control reformulado como aplicación por componente, sin declaración de nivel. Subcriterios reescritos "
   "con la secuencia de cuatro pasos y la precisión de PostgreSQL de TR-CIS-01. Aplicabilidad se mantiene "
   "en «Por validar».",
   "No iniciable hasta recibir de Walvy Seguridad la selección de controles por componente."),
}
