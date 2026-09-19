# Respuesta a las observaciones de Walvy sobre el cierre formal de Módulo 01

**Fecha:** 2026-08-25
**Motivo:** el cliente reconoce el material entregado (estructura formal, plan de pruebas, informes Android/iOS, release notes, documentación, evidencias) pero no lo considera suficiente para el cierre formal de M1. Pide: (1) evidencia de las tres dimensiones — código/configuración, reglas de negocio, funcionamiento/experiencia — y (2) un cruce explícito entre casos de prueba declarados y evidencia entregada.
**Fuentes usadas para esta respuesta:** `2026-08-11-informe-consolidado-bloque-acceso.md`, `2026-08-11-cruce-matriz-assessment.md`, `2026-08-20-respuestas-evidencia-rt.md` (RT-01 a RT-09), `2026-08-20-pendientes-proteccion-datos.md`, `2026-08-19-g4-suficiencia-por-tipo-de-documento.md`, `2026-08-24-g5-senales-alcance-parcial.md`, `matriz-estado-modulos.md`, `qa-audits/README.md`, memoria `project_matriz_impacto_m1_22_puntos` (revisión 2026-08-25 de los 22 puntos de la Matriz Interna de Impacto).

**Nota de proceso:** este documento es una síntesis de trabajo ya hecho, no una nueva auditoría de código. Antes de enviarlo al cliente, conviene una pasada de verificación puntual sobre los estados marcados como "pendiente de confirmar en código actual" — están fechados y pueden haberse resuelto desde entonces.

---

## Cuerpo de la respuesta (borrador)

Jose Miguel / equipo Walvy, gracias por el detalle de la observación — la aceptamos en los términos en que la plantean: el material entregado hasta ahora acredita con solidez la capa funcional y visual, pero no cierra por sí solo las tres dimensiones que definen, y el cruce explícito entre casos de prueba y evidencia no llegó como un artefacto único y navegable. Los dos puntos son correctos y no los vamos a defender; abajo va lo que sí tenemos para cada dimensión, y una propuesta concreta para resolver la trazabilidad.

### 1 · Código y configuración

Este es el trabajo menos visible en el paquete original porque vivía repartido en informes internos. Lo consolidamos:

- **Alineación esquema ↔ entidades.** 87 tablas de baseline, 6 módulos activos que cubren los 35 endpoints de M1 (`catalog`, `auth`, `imports`, `profile`, `notifications`, `users`), verificados en las dos direcciones: ninguna entidad declara una columna inexistente en su tabla, ninguna tabla tiene una columna no declarada por su entidad (`matriz-estado-modulos.md`, 2026-08-10).
- **Workbook de evidencia técnica RT-01 a RT-09**, respondido el 2026-08-20 con archivo/línea/PR por cada requerimiento — es, en los hechos, el primer cruce formal caso-de-prueba↔evidencia que construimos, aunque no llegó identificado como tal en la entrega. Cubre: release y ambiente trazado (RT-01), dataflow e2e con K-read y deduplicación (RT-02), ciclo de vida y supresión de cuenta en 4 fases —2 en `main`, 2 en PR— con inventario de 55 tablas (RT-04), redacción de datos sensibles en logs con 3 exposiciones corregidas (RT-05, PR #99), autenticación biométrica conforme por diseño (RT-06), y modelo de evidencia de consentimiento legal construido y verificado de punta a punta (RT-08).
- **Controles de seguridad de base de datos:** cifrado en reposo de BD y almacenamiento de documentos; contraseñas, tokens de sesión y OTP sólo como hash; BD sin acceso público en subred aislada; credenciales en gestor de secretos; verificación de propiedad del dato en cada acceso; anti fuerza bruta por ruta; datos de prueba sintéticos que no pueden correr contra producción.
- **Lo que declaramos abierto, sin maquillarlo:**
  - Registro de auditoría (`audit_log`) existe en el modelo pero ningún componente le escribe todavía — no avanzamos por cuenta propia porque qué eventos entran es definición de Seguridad del cliente.
  - La redacción de logs es por convención en los puntos de borde, no cableada en el transporte del logger (H3, `2026-08-20-pendientes-proteccion-datos.md`).
  - Divergencia de esquema en el módulo de suscripciones (nombres de tabla entidad vs. migración) y `SubscriptionsModule` no importado en `AppModule` — bloquea la señal comercial de fin de acceso.
  - Verificación de infraestructura (cifrado en tránsito, privilegios de la cuenta de aplicación, ambientes no productivos) en curso — la definición de infra tiene ~2 meses de atraso contra el código actual y preferimos no reportar como hallazgo algo que el ambiente real ya pueda no tener.
  - Artefactos legales (T&C/Política con versión y hash congelados) no materializados — bloquea que el modelo de consentimiento, ya construido, llegue a Conforme.

### 2 · Reglas de negocio

Esta es la dimensión que el paquete original más dejó fuera, y donde concentramos el trabajo de las últimas semanas:

- **Cruce directo contra las dos fuentes oficiales** (`Matriz de Trazabilidad Cliente v2.6` y `Assessment de Validación M01 v1.1`), no contra resúmenes de segunda mano — hecho el 2026-08-11 sobre el bloque de acceso (14 endpoints, tarjetas #22–#31): de 30 reglas con veredicto, **21 conformes**, 7 divergentes con issue, esfuerzo y dueño asignados, 2 bloqueadas por una decisión de Producto/Seguridad pendiente del lado Walvy (§3.3 del correo maestro).
- **Revisión de los 22 puntos de la Matriz Interna de Impacto** (18 Ajustes + 4 Brechas), a pedido explícito de Walvy, contra el código vigente el 2026-08-25: **11 ya implementados** de origen (login/registro/OTP/recuperación/biometría/checkpoint), y de los 11 restantes que quedaban por confirmar, **9 resultaron ya resueltos** al revisar contra la rama correcta. Queda **un solo punto grande sin resolver: V30, Foco del Mes sugerido/inferido** (sin lógica en back ni en front, estimado 40–64 HH). El resto se cerró esta misma semana (V50 el 25-08).
- **Reglas de suficiencia y semáforo de diagnóstico (G4/G5)**, documentadas escenario por escenario con el catálogo cerrado de estados y las reglas de agregación entre tipos de documento (cartola, TCR, CMF) — con las preguntas puntuales que faltan resolver del lado de Producto explicitadas una por una, no como bloqueo genérico.
- **Lo que declaramos abierto:** el modelo de estado del onboarding (puertas vs. checkpoints) sigue siendo la decisión de fondo pendiente; el catálogo de `dominant_pressure_code` no está enumerado en ninguna fuente; los estados parciales de señales G5 (`observation`, `leaks_detected`, `needs_attention`, el set extendido de `high`) están documentados pero sin disparador implementado — el motor no inventa umbrales que Producto no ha fijado.

### 3 · Funcionamiento y experiencia

Es la dimensión mejor cubierta por la entrega original, y la sostenemos: auditorías pixel-perfect contra Figma por pantalla, con puntaje y hallazgos priorizados — **92.9/100 de promedio** en las 8 pantallas de M1/Auth, con historial de iteración por pantalla. Podemos extender el mismo formato a las pantallas de onboarding que aún no tienen auditoría propia si es útil para el cierre.

---

### 4 · El cruce explícito que falta — propuesta

Coincidimos: reconstruir la relación manualmente, como hicimos para responder esta observación, no es lo mismo que tenerla como artefacto. Proponemos entregar una **Matriz de Trazabilidad de Evidencia M1** de una sola hoja, con estas columnas:

| Caso de prueba / control | Regla o requerimiento (M1-RN-\* / M01-\* / TEC-M1-\* / RT-\*) | Estado | Evidencia (archivo:línea, PR, captura, dataset) | Fecha | Responsable |
|---|---|---|---|---|---|

Se construye a partir de lo que ya existe — el informe consolidado del bloque de acceso, el workbook RT-01/09 y la revisión de la Matriz de Impacto — sin re-derivar nada desde cero. Con eso, un caso no queda acreditado como probado sólo por figurar en el inventario de pantallas o en el plan general: cada fila cita su evidencia puntual.

**Propuesta de plazo:** entrega en un plazo corto (ej. 5 días hábiles), cubriendo primero el bloque de acceso y protección de datos (donde el cruce ya está reconstruido) y sumando onboarding/diagnóstico en una segunda pasada.

---

### 5 · Qué necesitamos de Walvy para cerrar

Sin repetir el detalle ya enviado por punto: artefactos legales congelados (T&C/Política con versión y hash), catálogo de `dominant_pressure_code`, resolución de §3.3 (política de sesión y accesos), modelo de estado de onboarding, catálogo de gatillos comerciales de fin de acceso, y las definiciones puntuales de G4/G5 listadas en el documento técnico de suficiencia.

---

## Notas de redacción (no van al cliente)

- **Por qué no se disputa el diagnóstico del cliente.** Es correcto en ambos puntos: la evidencia de reglas de negocio vivía dispersa en informes internos, no en el paquete de entrega, y no existía un artefacto único de trazabilidad. Discutirlo costaría más que reconocerlo y mostrar lo que sí hay.
- **Por qué se cita RT-01/09 como "primer cruce formal".** Porque literalmente lo es — tiene columnas Estado/Archivo/Comentarios por requerimiento — pero se entregó como respuesta a un workbook de Walvy, no identificado ante el cliente como la matriz de trazabilidad que están pidiendo ahora. Vale la pena nombrarlo así explícitamente.
- **Por qué V30 se menciona como el único punto grande pendiente.** Es el estado más reciente verificado (2026-08-25, contra la rama correcta `origin/main` de KabeliDev). Antes de enviar, confirmar que sigue siendo así — la corrección de rama del 25-08 mostró que varios puntos que parecían pendientes ya estaban resueltos; vale la pena in a última pasada rápida antes de firmar el correo.
- **Qué queda deliberadamente fuera de este borrador.** No se ofrece fecha de cierre total de M1 — depende de las 6 definiciones de Producto/Seguridad listadas en §5, que no controlamos. Ofrecer fecha sin esas definiciones repetiría el error que motivó esta observación del cliente.
