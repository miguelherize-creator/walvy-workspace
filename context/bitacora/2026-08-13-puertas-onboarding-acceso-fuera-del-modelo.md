# Onboarding: puertas, checkpoints y retoma — alineación con la doc del cliente

**Fecha:** 2026-08-13
**Para:** PMO / José Miguel
**Backend:** `walvy-org/walvy-app-backend`, rama `feature/m1-onboarding-foco-contrato`, SHA `203aec4` (M1-RN-ONB-014)
**Frontend:** `walvy-org/walvy-app-frontend`, rama `main`, SHA `1615dfb`

**Fuentes cliente:**
- `Walvy_M1_Matriz_Trazabilidad_Cliente_v2.6.xlsx` — variantes V01–V60, HU, CA y decisiones PO.
- `Walvy_Assessment_Validacion_M01_v1.1 (diferido_onboarding).xlsx` — hoja `02_Reglas_M01` (reglas `M01-RGL-*`), hoja `08_Fixtures_Diagnostico` (bloque **«Matriz de continuidad y reutilización de evidencia»** = la `MatrizContinuidadM01`), hoja `11_Remediacion_Global` (hallazgos `CG-*`).

---

## 1. La pregunta que hay que responder

José Miguel lo acotó así: *«Lo que hay que garantizar es que el usuario siga el flujo que está en figma y que pueda retomarlo donde quedó»*, y agregó que eso *«en la matriz está separado en varias reglas y escenarios»*.

Eso reordena el problema. No es una discusión de cuántas puertas hay ni de cómo se llaman: es demostrar que cada punto de salida del flujo tiene un destino de retoma correcto. Y esa tabla ya existe del lado del cliente — sección 4.

## 2. La matriz separa acceso de onboarding — no es una decisión nuestra

La matriz v2.6 organiza las 60 variantes en trece flujos. El corte entre acceso y onboarding ya está hecho ahí:

| Bloque | Flujos | Variantes |
|---|---|---|
| Acceso | Acceso / Login, Biometría, Registro, Verificación de cuenta, Recuperación de acceso | V01–V23 |
| Primer ingreso | Primer ingreso | V24–V26 |
| Onboarding | Onboarding, Foco del Mes, Carga documental, Procesamiento, Suficiencia, Diagnóstico | V27–V57 |
| Retoma | Retoma | V58–V60 |

Las siete puertas del backend cubren exactamente los bloques Onboarding y Retoma. Verificación de cuenta, Biometría y Primer ingreso son flujos propios, con sus HU, CA y reglas — existen como requisito, pero no son puertas del onboarding. El backend eliminó `email_verification`, `biometric_setup` y `profile_basic` del estado de onboarding siguiendo ese mismo corte.

## 3. Hay tres vocabularios en juego, y ninguno es el de las puertas

| Vocabulario | Dónde vive | Valores |
|---|---|---|
| **Puertas** | Anexo Fase 3 BDD §6.1 → backend `current_gate` | `G0_activacion` … `G6_retoma` |
| **Checkpoints** | Matriz de trazabilidad v2.6 y reglas `M01-RGL-*` | «checkpoint» como concepto, sin enum |
| **Estados de checkpoint** | `MatrizContinuidadM01`, columna *Estado antes* | `focus_saved`, `documents_selected`, `document_processing`, `diagnostic_processing`, `completed` |

Dato concreto: `G0_activacion`…`G6_retoma` tienen **cero apariciones** en la matriz de trazabilidad del cliente. «Checkpoint» aparece 16 veces. «Puerta» aparece **una sola vez**, en el CA1 de M1-HU-029 — *«Se guarda la última puerta completada y la siguiente mejor acción»*, que es el origen literal de los campos `lastCompletedGate` y `pendingBestAction`.

Conclusión práctica: los nombres `G0..G6` son vocabulario interno del anexo, no de lo que el cliente valida. Renombrar `currentStep` → `currentGate` no toca ninguna regla aprobada. Lo que sí es contrato es la tabla de continuidad.

## 4. La `MatrizContinuidadM01` del cliente — verbatim

**Dónde está:** hoja `08_Fixtures_Diagnostico` del Assessment, bloque «Matriz de continuidad y reutilización de evidencia». Las reglas la citan como `MatrizContinuidadM01` y los hallazgos como «08 MatrizContinuidad».

**De dónde salió:** es la remediación del hallazgo **CG-07** (severidad Alta, paquete PR-03, área «Continuidad y duplicidad»), cuya decisión aplicada fue *«Crear una matriz única checkpoint × mecanismo de salida × destino de retoma»*. Resultado registrado: *«Cerrado en precisión documental»*, con la observación *«No equivale a prueba funcional ejecutada»*. Las siete filas están en estado **Pendiente**.

| Checkpoint | Mecanismo | Estado antes | Destino de retoma | Caso | Regla de no duplicidad |
|---|---|---|---|---|---|
| Foco guardado | Cerrar app | `focus_saved` | **Carga documental** | TC-M01-010 | No repetir en TC-049 |
| Foco guardado | Cerrar sesión | `focus_saved` | **Carga documental** | TC-M01-010 | No repetir en TC-049 |
| Archivo agregado sin análisis | Cerrar app/logout | `documents_selected` | Revisión/lista | TC-M01-010 | No repetir en TC-049 |
| Procesamiento documental demorado | Cerrar app/logout | `document_processing` | Mismo job o resultado | TC-M01-014 | No repetir en TC-049 |
| Análisis de diagnóstico | Cerrar app | `diagnostic_processing` | Mismo job o resultado | TC-M01-022 | No repetir en TC-049 |
| Análisis de diagnóstico | Cerrar sesión | `diagnostic_processing` | Mismo job o resultado | TC-M01-022 | No repetir en TC-049 |
| Diagnóstico completado | Cerrar app/logout | `completed` | Primera lectura / Home-Inicio | TC-M01-026/051 | **No reabrir onboarding** |

Tres lecturas que importan:

1. **La matriz empieza en «Foco guardado».** No hay ninguna fila para verificación de correo, biometría ni primer ingreso. La continuidad que el cliente exige arranca en el onboarding — es el respaldo más directo a la decisión del backend.
2. **El mecanismo de salida es una dimensión propia.** «Cerrar app» y «Cerrar sesión» son filas separadas con evidencia separada (`EVD-TC-M01-017-A` vs `-B`). Nuestro modelo no registra cómo salió el usuario: `resumeState` solo dice que hay algo pendiente.
3. **El destino se deriva del checkpoint completado, no del que está en curso.** `focus_saved` → Carga documental. Eso es exactamente la semántica de `lastCompletedGate`.

El contrato de eventos lo refuerza: `onboarding.resume` exige *«Campos base + checkpoint + mechanism + original_job_id»* (M01-RGL-017, validador Erick).

## 5. M01-RGL-007 completa

| Campo | Contenido |
|---|---|
| Regla ID | M01-RGL-007 |
| Subárea | Omisión/postergación |
| Tipo de control | Continuidad explícita |
| Regla a verificar | «Permitir salir desde un checkpoint no concluido, guardar el avance y retornar a Inicio sin generar una primera lectura concluyente.» |
| Resultado esperado | «CTA y modal coinciden con la referencia; el checkpoint persiste; Inicio refleja estado pendiente y la retoma continúa desde el punto guardado.» |
| Fuente principal | SRC-21 / SRC-22 / SRC-26 |
| Ubicación fuente | Figma modal `6670:13499` + `DATA-M01-PARTIAL-01` + **`MatrizContinuidadM01`** |
| Estado documental | Cerrado |
| Prioridad | Must — **bloqueante si falla** |
| Validador | Jose |
| Evidencia requerida | «Video de dos puntos de salida + capturas de CTA/modal/Home + checkpoint persistido» |
| Caso de prueba | TC-M01-009 |

En la v2.6 esa misma regla se registra como *«Aplicada en V24–V36 y V58»*, con variantes `M1-V25, M1-V29, M1-V58`. **M1-V25 es Primer ingreso** — y ahí está la única inconsistencia real: la regla lista una variante de primer ingreso, pero el artefacto que la propia regla cita como fuente no tiene fila para ese checkpoint. Es la pregunta concreta para el PMO, no una objeción al modelo de puertas.

## 6. Mapeo puerta → pantalla, y la continuidad de lado nuestro

| Puerta | Pantalla | Checkpoint del cliente |
|---|---|---|
| `G0_activacion` | `/(auth)/onboarding` — bienvenida + concientización (4 láminas) | — |
| `G1_foco` | `/(auth)/onboarding-foco` | `focus_saved` al guardar |
| `G2_carga` | `/(auth)/onboarding-doc` | `documents_selected` |
| `G4_analisis` | `/(auth)/onboarding-analyzing` | `document_processing` |
| `G3_revision` | `/(auth)/onboarding-analysis` — revisión de indicadores | — |
| `G5_diagnostico` | `/(auth)/onboarding-first-ready` — primera lectura | `diagnostic_processing` → `completed` |
| `G6_retoma` | no es pantalla — se expresa con `resumeState` | mecanismo de salida |

Las etiquetas `G3` y `G4` están cruzadas respecto del recorrido: la revisión de indicadores ocurre después del análisis, porque no se pueden revisar indicadores que aún no se extrajeron. La tabla está en orden de flujo; el intercambio de etiquetas va a la reconciliación de dominios del §16 del anexo.

Y los tres checkpoints de acceso, que no están en la matriz del cliente pero la app sí debe resolver:

| Situación | Pantalla | Señal | Regla que lo pide |
|---|---|---|---|
| Cuenta creada, correo sin verificar | `/(auth)/verify-code` | cuenta en `pending_verification`; llega como `nextStep: 'email_verification'` | M1-V13 (decisión PO) |
| Correo verificado, biometría no ofrecida | `/(auth)/biometric-setup` | `biometricPrompted === false` | M1-V26 (PD-M1-04) |
| Primer ingreso sin completar | `/(auth)/choose-alias` | perfil sin nombre/apellido/alias | M1-V25 (decisión PO) |

La retoma al acceso ya está pedida, y pedida por estado de cuenta: M1-V13 la define por `pending_verification`, y M1-V06 cierra que *«una autenticación exitosa permite iniciar sesión, pero no debe fijarse universalmente el destino como Home; la continuidad depende del estado funcional del usuario»*. Es el mismo mecanismo que quedó en el backend.

## 7. Dos brechas concretas contra la matriz del cliente

**A. `focus_saved` debe retomar en Carga documental, no en Foco.** La matriz del cliente es explícita en sus dos primeras filas. Hoy `main` cumple: al guardar el foco escribe el paso siguiente (`document_upload`), así que un usuario que cierra la app ahí reabre en Carga documental. Pero el flujo documentado del contrato nuevo escribe `{ currentGate: 'G1_foco', goalsSet: true }` en ese momento y solo después `G2_carga` — y en la app guardar el foco y avanzar son **la misma acción**. Si la app llegara a quedarse en `G1_foco`, la retoma volvería a Foco y contradiría la matriz. Hay que fijar que `currentGate` es la puerta que se **entra**, y dejar el foco completado en `lastCompletedGate`.

**B. La selección documental no sobrevive al cierre de la app.** RGL-008 exige *«Recuperar el mismo checkpoint, selección documental, job o resultado después de cerrar la app o cerrar sesión»*, y la matriz tiene la fila `documents_selected` → Revisión/lista. En la app la lista de archivos vive solo en estado local y viaja por parámetros de ruta: al reabrir en `G2_carga` la pantalla llega vacía. Los documentos ya subidos sí se recuperan del servidor — la pantalla de análisis consulta los imports del usuario —, pero los archivos agregados y no enviados se pierden. Es la fila 3 de la matriz sin cubrir.

## 8. Lo que hay que decidir

1. **Resolver la inconsistencia de alcance de RGL-007** (sección 5): la regla lista M1-V25 entre sus variantes, la `MatrizContinuidadM01` que cita no tiene fila de primer ingreso. Si el checkpoint de primer ingreso entra a la matriz, hay que definir de qué campo sale su persistencia; si no entra, corregir la lista de variantes de la regla.
2. **Registrar el mecanismo de salida.** La matriz y el contrato de eventos distinguen «cerrar app» de «cerrar sesión»; `resumeState` no lo hace y `onboarding.resume` pide el campo `mechanism`. Definir si se agrega al estado o si queda solo en el evento.
3. **Cerrar la brecha B** — persistir la selección documental, o acordar que `documents_selected` se limita a los documentos ya subidos.
4. **Trazabilidad del embudo de acceso.** Mientras el usuario está en registro, verificación, biometría o primer ingreso, todas las cuentas quedan indistinguibles en `user_onboarding_state` (`not_started`, `currentGate = null`). Si el reporte de embudo necesita medir esa caída, es un campo nuevo y va al §16 — no se resuelve en frontend.
5. **Despliegue conjunto.** El cambio rompe el contrato: la `main` de frontend manda `currentStep`/`resumeSurface` y recibiría `400`.

**Nota sobre M1-BC-001.** La brecha registra que la secuencia de concientización posterior a la bienvenida no fue levantada. La app sí la tiene: la bienvenida es un carrusel de cuatro láminas con avance automático, dentro de `G0_activacion`. La brecha es de la matriz de variantes, no del producto.
