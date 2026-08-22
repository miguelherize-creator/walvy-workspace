# Ajustes a la Matriz de Validación Técnica M1 — los 7 controles marcados por Walvy

**Fecha:** 2026-08-20
**Origen:** correo de Jose Miguel Rodríguez + `Walvy_M1_Matriz_Validacion_Tecnica_v1.0_revisada.xlsx` (Drive `19dv7StnHioxz_aezno4JmJBSP5VReWJW`, modificada 2026-08-20).
**Resultado de la Etapa 1 de Walvy:** 15 Aceptado · 7 Ajustar control · 1 Diferido aprobado. Ninguno de los 7 requiere volver a Producto.

**Fuentes usadas para redactar (leídas, no citadas de memoria):**
- `specs/matriz-v2.6/variantes-m1.psv` — Matriz de Trazabilidad Cliente v2.6, V01–V60.
- `specs/matriz-v2.6/anexos-y-decisiones.psv` — hoja `02_Reglas_M01` del Assessment M01 v1.1.
- `Walvy_Clasificacion_y_Requisitos_Proteccion_Datos_para_Implementacion_v1_0.xlsx` — 233 IDs, perfiles `PP-*`, transversales `TR-*`.
- `Walvy_Requerimientos_Evidencia_Tecnica_Kabeli_v1_0.xlsx` — bloques `RT-01..RT-09`.

**Alcance de este documento:** sólo Etapa 1 (alcance de controles). Las columnas de Etapa 2 —«Cómo está implementado», «Evidencia presentada», «Resultado revisión Kabeli»— quedan intactas. Walvy pidió precisión de trazabilidad y complemento de criterios, no acreditación de cumplimiento.

**Verificación de IDs.** Todos los IDs que Walvy manda citar existen: `M1-V01..V60`, `AX-M1-001..004`, `M1-DP-002..011`, `M01-RGL-001..018`, `M01-LOG-001`. `M01-SEC-001`, `M01-AUT-001` y `M01-PRV-001/002/003` no están en el subset exportado a `matriz-v2.6/` (que cubre `02_Reglas_M01`) sino en la hoja Priv/Sec del Assessment M01 v1.1; son válidos.

---

## Convención de edición

Se editan cuatro columnas por fila: **Control a validar**, **Subcriterios incluidos**, **Relación funcional M1** y **Acción / complemento requerido**. Se complementa **Origen** cuando el criterio proviene del paquete de Protección de Datos.

No se toca «ETAPA 1 · Validación alcance Walvy» ni «Comentario alcance Walvy»: son de Walvy y las actualiza él en la revisión final acotada. **Estado de cierre** pasa de `Pendiente definición alcance` a `Ajuste incorporado – pendiente revisión final` en los 7; no se auto-promueve a `Pendiente cumplimiento`, que es decisión de Walvy.

Se propone además una hoja nueva **`05 Ajustes v1.1`** con la traza comentario Walvy → ajuste incorporado, para que la revisión final sea acotada y verificable. La hoja `04 Nuevos Cambios` no sirve para esto: está reservada a solicitudes nuevas `CAM-M1-xxx`.

---

## TEC-M1-003 · Registro y privacidad

**Comentario Walvy:** completar `M1-V09/V11/V12` + `M01-RGL-002` + `M01-PRV-001/002/003`. Usar el acto afirmativo M01 para consentimiento financiero central, sin nueva UX. Registrar `M01-DAT-061`, evento/fecha-hora, versiones T&C/Política y alcance. Reaceptación sólo por versión/regla; silencio no acepta. Gate B: `RT-08`. Walvy/Legal: texto/alcance y efecto de no aceptar versión obligatoria.

**Control a validar (nuevo):**
> Los documentos obligatorios deben abrirse y aceptarse desde el propio documento; la aceptación debe quedar trazable y versionada, y ese mismo acto afirmativo debe servir de evidencia del consentimiento financiero central sin introducir una UX adicional.

**Subcriterios incluidos (nuevos):**
- Apertura de cada documento; «Aceptar» se habilita sólo al alcanzar el final del contenido (`M01-RGL-002`).
- Cerrar o volver antes de aceptar conserva el documento pendiente. El silencio no constituye aceptación.
- «Crear mi cuenta» sólo con formulario válido y ambas aceptaciones registradas.
- La aceptación no puede registrarse desde el formulario de Registro (`M01-PRV-003`).
- Obligatorio vs opcional distinguido por documento.
- Evidencia por aceptación: `user_id` seudónimo, `document_type`, `version`, `effective_at`, `presented_at`, `channel`, `app_version`, `content_hash`/referencia y `action` (`M01-PRV-002`).
- Nombre/versión/hash o URL de T&C y Política congelados antes de ejecutar la validación (`M01-PRV-001`).
- El mismo acto afirmativo M01 registra el consentimiento financiero central: alcance/finalidad y versiones documentales asociadas (`M01-DAT-061`, `TR-CONS-01`). Sin pantalla, modal ni checkbox adicional.
- Reaceptación exigible sólo cuando cambia la versión o la regla aplicable.

**Relación funcional M1:** `M1-V09 / M1-V11 / M1-V12 + M01-RGL-002 + M01-PRV-001/002/003`
**Origen:** Producto v2.6 + Solicitud técnica Walvy + Paquete Protección de Datos (`TR-CONS-01`)

**Acción / complemento requerido:** Gate B (evidencia): `RT-08`. Dependencia Walvy/Legal: texto y alcance del consentimiento, y efecto funcional de no aceptar una versión obligatoria.
**Dependencia bloqueante declarada:** `M01-PRV-001` exige artefactos legales congelados con versión y hash o URL. Hoy no existen. Mientras no se materialicen, cualquier aceptación que se registre queda referida a un texto que no es el oficial, y `M01-PRV-002` / `TC-M01-035` no pueden pasar. Está asignado a Jose + Andrea (`M01-PRV-001`) y Erick + Jose (`M01-PRV-002`) — no es un pendiente de Kabeli.

---

## TEC-M1-007 · Onboarding y continuidad

**Comentario Walvy:** referencia principal `M1-DP-009` + `V58-V60` + `M01-RGL-008/012/016`; `V25`/`V29` auxiliares y `V44` no principal. Checkpoint: sólo estado/correlación mínima de retoma, sin duplicar payload/documentos; limpiar/reemplazar al quedar obsoleto o completar onboarding. Gate B Kabeli: store/schema, lifecycle y prueba de limpieza/retoma. 90 días: `TEC-M1-021`.

**Control a validar (nuevo):**
> El usuario debe poder guardar/salir o postergar sin avanzar indebidamente y retomar desde un checkpoint útil, conservando sólo el estado y la correlación mínimos necesarios para la retoma.

**Subcriterios incluidos (nuevos):**
- «Guardar y salir» conserva la información ingresada y sale del flujo. No se describe como una omisión que avanza al paso siguiente (`M1-V25`, decisión PO).
- Postergar el Foco del Mes conserva el estado pendiente y aplica la salida de postergación; no avanza directo a carga documental (`M1-V29`).
- Retoma en los tres puntos de pausa: antes de la carga, tras carga parcial o procesada, y durante el análisis (`M1-V58` / `M1-V59` / `M1-V60`).
- No se repiten pasos completados ni se duplican documentos o jobs; cada checkpoint reabre en el destino y estado correctos (`M01-RGL-008`).
- No se genera una primera lectura concluyente mientras no se complete la base requerida; sólo los estados permitidos por el gate habilitan avance (`M01-RGL-012`).
- Contenido del checkpoint: sólo estado y correlación mínima de retoma. No duplica payload financiero ni documentos.
- Lifecycle del checkpoint: se limpia o reemplaza al quedar obsoleto y al cerrar el onboarding (`M01-RGL-016`).

**Relación funcional M1:** `M1-DP-009 (referencia principal) + M1-V58 / M1-V59 / M1-V60 + M01-RGL-008 / 012 / 016 · auxiliares: M1-V25 / M1-V29`
**Origen:** Producto v2.6 + Paquete Protección de Datos (`PP-07`, minimización del metadato de continuidad)

**Acción / complemento requerido:** Gate B Kabeli: store/schema del checkpoint, lifecycle y prueba de limpieza y retoma (`RT-04.1`). La ventana de 90 días no se duplica aquí: vive en `TEC-M1-021`.
**Propuesta de reasignación:** `M1-V44` (progreso durante el procesamiento) deja de ser relación de este control y pasa como auxiliar a `TEC-M1-012`, cuyo eje es `M01-RGL-014` — la misma regla que gobierna V44. Queda a confirmación de Walvy en la revisión final.

---

## TEC-M1-013 · Motor de reglas · gate de suficiencia

**Comentario Walvy:** ampliar la relación a `V48-V52` + `M01-RGL-012/013` + `AX-M1-003`. El gate cubre `complete`, `partial permitido`, `partial bloqueado` y `blocked`; no sólo `V50`.

**Control a validar (nuevo):**
> `M01-RGL-012` debe actuar como gate único de suficiencia, resolviendo sobre una matriz única de indicadores y motivos, con salida determinista.

**Subcriterios incluidos (nuevos):**
- Normalización previa de cada indicador a `sufficient` / `pending` / `missing`, conservando `detection_status`, `data_origin`, `confidence` y `evidence` (`M01-RGL-013`).
- Cuatro salidas del gate: falta elemento mínimo obligatorio → `blocked`; base mínima + pendiente crítico → `partial bloqueado`; base mínima + sólo pendientes no críticos → `partial permitido`; sin pendientes relevantes → `complete`.
- Cobertura por variante: `V48` revisión/suficiencia previa al Diagnóstico —no cierre del onboarding—, `V49` partial permitido, `V50` partial bloqueado, `V51` blocked por datos clave, `V52` blocked sin base documental y sin ruta manual sustitutiva. (Los subcriterios describen el requisito. Lo que la implementación hoy resuelve distinto va declarado más abajo, no corregido acá.)
- Fronteras documentadas: movimientos recientes pendientes bloquean; pagos recurrentes pendientes pueden permitir parcial cuando ingreso, movimientos y compromisos están suficientemente establecidos; la ausencia de instrumentos de pago no bloquea por sí sola.
- «Sin diagnóstico» (`V56`) se resuelve por estos gates y no como cuarta tarjeta equivalente a En control / Atención / Riesgo.
- `reason` explicativo por salida. Sin ramas no documentadas ni combinaciones extrapoladas fuera de reglas y fixtures.
- Los cinco indicadores núcleo con valores canónicos; «detectado» no equivale a «confirmado»; trazabilidad reproducible entre UI y payload (`M01-RGL-013`).

**Relación funcional M1:** `M1-V48 / V49 / V50 / V51 / V52 + M01-RGL-011 / 012 / 013 + AX-M1-003 + M1-DP-008 / M1-DP-009`
> Se incluyen `M01-RGL-011` y `M1-DP-008/009` además de lo que Walvy enumera literalmente, porque son las reglas que la propia Matriz v2.6 asocia a `V48-V52` en su columna «Regla Walvy validada». Se señala explícitamente en la hoja de ajustes para que Walvy lo confirme o lo recorte.

**Acción / complemento requerido:**

- **Mapeo de vocabulario: declarado.** La salida canónica del gate es `blocked` / `partial bloqueado` / `partial permitido` / `complete` (`AX-M1-003`, `M01-RGL-012`); el CHECK de la base declara `sufficient` / `partial` / `insufficient` / `blocked`. La proyección entre ambos quedó declarada y probada en código, sin migrar el CHECK ni tocar el contrato expuesto. `insufficient` y `blocked` proyectan los dos a `blocked` canónico: la base es más fina y distingue «no había documento usable» de «faltaba un indicador obligatorio».

- **No conformidad declarada 1 · `partial bloqueado` no se emite.** Cuando un indicador crítico no es usable, la regla devuelve `insufficient` con el diagnóstico parcial deshabilitado, así que el caso de `V50` sale como `blocked`. El comportamiento es el que `V50` espera —no habilitar el diagnóstico parcial— pero la etiqueta canónica no aparece. Y no hay dónde ponerla: el modo de diagnóstico y el permiso de parcial se calculan y se descartan, no se persisten, así que desde la columna `sufficiency_status` sola la distinción permitido/bloqueado no es recuperable.

- **No conformidad declarada 2 · se resuelve `complete` donde la frontera documentada dice parcial.** Verificado ejecutando la regla, no leyéndola. Con `pagos_recurrentes` en `por_confirmar` y el resto de los indicadores establecidos, el gate resuelve `sufficient` → `complete`, aunque registre el pendiente como advertencia. La decisión PO de `V50` documenta ese caso al revés: *«pagos recurrentes pendientes pueden permitir parcial cuando ingreso, movimientos y compromisos están suficientemente establecidos»*. El caso simétrico —`compromisos_base` pendiente— se comporta igual.

  **Causa raíz:** la cláusula «basta uno del par» de la Fase 3 §8 gobierna el **bloqueo** —si hay base mínima—, y la implementación la reutilizó también para decidir la **completitud**. Son preguntas distintas: que uno del par esté detectado alcanza para tener base mínima, no para llamar completa una lectura cuyo otro miembro está pendiente.

  **Esto no reabre Producto.** No es que dos documentos de Walvy se contradigan: es la implementación divergiendo de una frontera que Walvy ya dejó escrita. La corrección es de Kabeli y el «No» de la columna «¿Requiere volver a Producto?» se mantiene.

  **Estado: corregido.** El arreglo distingue *ausente* de *pendiente*, que es la distinción que usa la frontera: un miembro del par ausente con el otro detectado sigue siendo completo —exigir los dos dejaría fuera a quien no tiene pagos recurrentes—, y un miembro por confirmar, inferido o manual asistido degrada a parcial. `instrumentos_pago` conserva su comportamiento de sumar advertencia sin impedir completo. Los casos afectados pasan a `partial`, valor ya válido del CHECK, así que no hubo migración.

- **Consecuencia para la Etapa 2.** (2) queda corregido, así que el subcriterio de las cuatro salidas se sostiene salvo por (1), que sigue abierto: falta resolver dónde vive la distinción `partial permitido` / `partial bloqueado`, que hoy no se persiste. Van declarados acá para que Walvy los vea en el ajuste de alcance y no los descubra al validar cumplimiento; el propio paquete de Protección de Datos advierte que un pendiente no habilita a asumir Cumple ni No Aplica, y el mismo criterio se aplica al alcance.

- `V48` debe retirar sus asociaciones de diagnóstico/cierre (HU-025; RN-ONB-009/011/012/016) y alinearse a revisión/suficiencia (HU-024), conforme la decisión PO de `V48`.

---

## TEC-M1-014 · Motor de reglas · estado financiero

**Comentario Walvy:** completar relación con `V53-V55` + `V57` + `M1-DP-006` / `AX-M1-004` + `M01-RGL-015`. Mantener la secuencia suficiencia → estado → presión/CTA.

**Control a validar (nuevo):**
> El estado financiero debe calcularse con la regla canónica, y la presión principal y el CTA dominante aplicarse después del estado sin alterarlo.

**Subcriterios incluidos (nuevos):**
- Precondición: `M01-RGL-012` habilita Diagnóstico. La secuencia es suficiencia → estado → presión/CTA.
- Ratio canónico sobre el snapshot mensual: egreso mensual proyectado / ingreso mensual reconocido.
- `ratio < 0,90` → En control (`V53`); `0,90 ≤ ratio < 1,00` → Atención (`V54`); `ratio ≥ 1,00` → Riesgo (`V55`).
- `mora_confirmada` —obligación vencida + saldo pendiente + evidencia suficiente— es el único override determinista de Riesgo aprobado para el MVP.
- Datos por confirmar, movimientos pendientes, fugas o compromisos no pintan estado por sí solos: la calidad y completitud pertenecen al gate de suficiencia; las señales económicas explican presión y CTA después de determinar el estado. Un `partial permitido` puede seguir mostrando En control si el ratio está bajo el umbral.
- Una única presión principal y un único CTA dominante; el resto queda como información secundaria (`V57`, `M01-RGL-015` / `M01-RGL-016`).
- Riesgo no activa automáticamente M04: Ruta Despeje conserva sus propios criterios de deuda confirmada, suficiencia y presión.
- Versionamiento: `rule/config version` y timestamp de evaluación asociados al estado calculado.
- Evitar doble conteo de inputs.

**Relación funcional M1:** `M1-V53 / V54 / V55 + M1-V57 + M1-DP-006 + AX-M1-004 + M01-RGL-012 / 015 / 016`

**Acción / complemento requerido:**
- **Dependencia declarada:** el catálogo de valores de `dominant_pressure_code` no está enumerado ni en la Matriz v2.6 ni en `AX-M1-004`; se cita la regla `M01-RGL-015` pero nunca sus valores. Sin ese catálogo, el determinismo de presión y CTA no es demostrable en Etapa 2. No modifica la regla de estado ni reabre Producto.
- `V56` («Sin diagnóstico») queda asignada a `TEC-M1-013`, no a este control: su decisión PO establece que se resuelve por los gates de suficiencia previos al diagnóstico.

---

## TEC-M1-016 · Seguridad técnica

**Comentario Walvy:** agregar `M01-SEC-001` / `M01-AUT-001`: contraseña con hash adaptativo + salt; secretos fuera de código/build/logs; transporte seguro, mínimo privilegio y owner check; mobile seguro si aplica. MFA/RBAC sólo si existe superficie/API admin. Gate B Kabeli: app/backend/mobile y consumo de secretos. Walvy/Infra: IAM/KMS/red/DB administrada/backups-PITR/hardening/logging AWS.

**Control a validar (nuevo):**
> Aplicar las medidas técnicas mínimas para credenciales, secretos y acceso a los componentes del M1 bajo responsabilidad de Kabeli, sin absorber la capa de infraestructura AWS que acredita Walvy.

**Subcriterios incluidos (nuevos) — capa Kabeli:**
- Contraseña con hash adaptativo y salt; sin plaintext ni cifrado reversible (`M01-SEC-001`, `PP-05`).
- Secretos fuera de código, build y logs; consumo desde Vault/Secrets Manager o equivalente aprobado.
- Cifrado en tránsito en todas las superficies de aplicación.
- Autorización efectiva en backend: mínimo privilegio y owner check por recurso, con matriz de autorización verificable caso A / caso B (`M01-AUT-001`).
- Seguridad móvil aplicable: almacenamiento local, credenciales, comunicaciones y uso de APIs del dispositivo (`TR-MOB-01`).
- MFA y RBAC exigibles sólo si existe superficie o API administrativa dentro del alcance del M1.

**Subcriterios — capa Walvy · Infraestructura/Seguridad, se acredita por separado:**
- IAM de infraestructura, cifrado de servicios y KMS, red, servicio de base de datos administrado, backups/PITR, hardening y logging/monitoreo de AWS (`TR-AWS-01`, `TR-DB-01`).
- Rotación de llaves y secretos de la capa de infraestructura.

**Relación funcional M1:** `Transversal M1 + M01-SEC-001 / M01-AUT-001 + TR-SEC-01 / TR-MOB-01 / TR-AWS-01 / TR-DB-01`
**Origen:** Contractual – Anexo 2 + Paquete Protección de Datos (`TR-SEC-01`, `TR-MOB-01`, `TR-AWS-01`, `TR-DB-01`)

**Acción / complemento requerido:** Gate B Kabeli: app/backend/mobile y consumo de secretos (`RT-01`, `RT-05`). En los controles compartidos cada parte acredita su capa, sin fusionar ownership.
**Precisión para no perder cobertura del Anexo 2:** cuentas nominativas, altas/bajas y revisión/revocación periódica de permisos siguen cubiertas en `TEC-M1-020` (soberanía) y no se eliminan del alcance al reasignar la capa de infraestructura a Walvy.
**Pendiente de confirmación:** si existe o no superficie/API administrativa en el M1, para cerrar la aplicabilidad de MFA/RBAC.

---

## TEC-M1-021 · Protección de datos personales

**Comentario Walvy:** Anexo 3.10. PD M01: 90 días sólo desde fin efectivo de acceso; inactividad/fallo de pago vigente no gatillan; ventana = tratamiento congelado. Supresión confirmada no espera 90 días; residual = Walvy/Legal. No-resurrección post PITR. `M01-DAT-021` no hereda 24 h K-read. 72 h sólo SLA contractual. Gate B: lifecycle/stores + supresión E2E. Walvy: trigger comercial, Legal/transferencias, AWS/PITR.

**Control a validar (nuevo):**
> El tratamiento de datos personales del M1 debe cumplir las obligaciones del Anexo 10 y el lifecycle definido por Walvy en el paquete de Protección de Datos, distinguiendo los plazos de lifecycle de los plazos de SLA contractual.

**Subcriterios incluidos (nuevos):**
- Cliente = Responsable; Kabeli = Encargado bajo instrucciones documentadas.
- Subencargados sólo con autorización previa escrita y obligaciones equivalentes.
- QA con datos anonimizados o seudonimizados cuando aplique. Segregación de ambientes.
- La ventana de 90 días comienza **únicamente** con el fin efectivo del derecho de acceso/licencia y opera como recuperación/reactivación con **tratamiento funcional congelado**. La mera inactividad o un fallo de pago mientras el acceso siga vigente no la gatillan (`TR-RET-01`).
- Solicitud confirmada de supresión: cese funcional y supresión sin esperar los 90 días. La existencia y el alcance de una retención residual los define Walvy/Legal, y debe quedar segregada y fuera de todo uso funcional.
- No-resurrección: tras un restore/PITR ejecutado por Walvy, la aplicación conserva las supresiones previas y no reactiva datos suprimidos.
- `M01-DAT-021` (documento original cargado en M01) **no** hereda el plazo de 24 h aplicable a los originales M04/M05/M06 procesados por K-read; su regla transitoria es propia de M01 y no convierte a Walvy en repositorio permanente (`TR-DOC-01`).
- El plazo de 72 h de aviso ante incidente de software con PII es un **SLA contractual de notificación** del Anexo 10, no un parámetro de lifecycle ni de retención.
- Retorno o eliminación segura a requerimiento o al término, con evidencia.

**Relación funcional M1:** `Transversal M1 + M01-DAT-021 / M01-DAT-061 + TR-RET-01 / TR-DOC-01`
**Origen:** Contractual – Anexo 10 + Paquete Protección de Datos (`TR-RET-01`, `TR-DOC-01`)

**Acción / complemento requerido:** Gate B Kabeli: inventario de stores y persistencias de aplicación, lifecycle funcional y prueba E2E de congelamiento, reactivación y supresión (`RT-04.1` a `RT-04.5`, `RT-04.9`).
**Dependencias Walvy:** catálogo de triggers comerciales que constituyen fin efectivo de acceso (`RT-04.2`), conclusión de Legal sobre residual y transferencias (`RT-04.8`, `RT-03`), y ejecución de restore/PITR en AWS — `RT-04.6` y `RT-04.7` son prueba coordinada, no entregable unilateral de Kabeli.
**Consulta para la revisión final:** el comentario abre con «Anexo 3.10». Confirmar si refiere al Anexo 10 o al punto 10 del Anexo 3, para citar la fuente correcta.

---

## TEC-M1-023 · Seguridad técnica complementaria

**Comentario Walvy:** no asumir CIS L1/L2 ni nivel ASVS/MASVS completo como baseline/certificación. Por componente/tecnología real: marco o benchmark → controles seleccionados → aplica / N-A-excepción → evidencia. OWASP/ASVS/MASVS para app/API/móvil; CIS para tecnología real. Gate B Kabeli: evidencia de su capa. Walvy Seguridad: selección/aplicabilidad y CIS de AWS/DB/infra.

**Control a validar (nuevo):**
> Los marcos de seguridad se aplican por componente y tecnología realmente desplegada en el M1, con controles seleccionados y justificados. No constituye certificación CIS, ASVS ni MASVS del módulo.

**Subcriterios incluidos (nuevos):**
- Inventario de componentes y tecnologías efectivamente desplegados en M1, con versión.
- Por componente: marco o benchmark aplicable → controles seleccionados → aplica / no aplica con justificación / excepción aprobada → evidencia.
- OWASP ASVS y MASVS para aplicación, API y móvil. CIS Benchmark para la tecnología y versión efectivamente desplegada cuando exista.
- No se declara nivel L1/L2 ni nivel ASVS/MASVS completo, ni como baseline ni como resultado.
- Remediación sólo de hallazgos aplicables y acordados; excepciones registradas y justificadas.
- Para PostgreSQL, CIS valida la configuración segura del servicio/motor en la capa operada por Walvy y no traslada a Walvy la responsabilidad de Kabeli sobre modelo, esquema y arquitectura lógica de datos (`TR-CIS-01`).

**Relación funcional M1:** `Transversal M1 + TR-CIS-01`
**Origen:** Solicitud técnica Walvy – no requisito contractual explícito + Paquete Protección de Datos (`TR-CIS-01`)
**Aplicabilidad:** se mantiene en `Por validar`.

**Acción / complemento requerido:** **Dependencia Walvy Seguridad, bloqueante del alcance:** selección de controles y aplicabilidad por componente, más el CIS de AWS, del servicio de base de datos y de la infraestructura. Gate B Kabeli: evidencia de su capa —app, API y móvil— una vez definida esa selección. Este control no puede pasar de `Por validar` a `Aplica` antes de recibir la selección.

---

## Lo que estos 7 ajustes no cierran

1. **`M1-DP-009` — modelo de estado del onboarding.** Es la referencia principal de `TEC-M1-007` y también la referencia de `V48-V52` en `TEC-M1-013`. Incorporar la trazabilidad no resuelve la condición de cierre del onboarding, que sigue siendo la única pregunta de fondo abierta. Se cita correctamente; no se declara resuelta.
2. **Artefactos legales de `M01-PRV-001`.** Sin T&C y Política congelados con versión y hash, `TEC-M1-003` no puede alcanzar Conforme en Etapa 2. La dependencia es de Walvy/Legal.
3. **Catálogo de `dominant_pressure_code`.** Falta enumerarlo; sin él `TEC-M1-014` no es demostrable en Etapa 2.

3b. **`partial permitido` / `partial bloqueado` no tiene dónde persistirse.** La otra no conformidad del gate —`complete` donde la frontera de `V50` dice parcial— quedó corregida. Esta sigue abierta: el modo de diagnóstico y el permiso de parcial se calculan y se descartan, así que desde `sufficiency_status` la distinción no es recuperable. No reabre Producto, pero `TEC-M1-013` no llega a Conforme sin resolverlo.
4. **Selección de controles de `TEC-M1-023`.** Depende de Walvy Seguridad y mantiene el control en `Por validar`.

Los cuatro se declaran en la columna «Acción / complemento requerido» en lugar de dejarlos implícitos. El propio paquete de Protección de Datos advierte que un pendiente de runtime no habilita a asumir Cumple ni No Aplica; el mismo criterio se aplica aquí al alcance.

## Siguiente paso

Emitir `Walvy_M1_Matriz_Validacion_Tecnica_v1.1.xlsx` parcheando sobre el archivo revisado —para conservar formato y las 16 filas no tocadas— con las cuatro columnas editadas en estas 7 filas, `Estado de cierre` actualizado y la hoja `05 Ajustes v1.1`.
