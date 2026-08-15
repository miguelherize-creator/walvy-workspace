# Cruce contra las fuentes originales — Matriz v2.6 y Assessment v1.1

**Fecha:** 2026-08-11
**Fuentes leídas directamente:**
- `Walvy_M1_Matriz_Trazabilidad_Cliente_v2.6.xlsx` — Drive `1MRRKk-hNZT0HUFios8WT2Tsrz3vkd5is`
- `Walvy_Assessment_Validacion_M01_v1.1 (diferido_onboarding).xlsx` — Drive `1Fd6r5xbaEl6CjEZWZd13nyXHNW1umJVt`

**Baseline del código:** backend `dd084c7`, frontend `d73d71d`.

Hasta ahora la revisión se apoyó en la Matriz de Validación (fuente 2) y en el enunciado de las tarjetas. Este cruce es la primera lectura directa de la **fuente 1**. Cambia cuatro conclusiones y desbloquea tres issues.

---

## 1. La corrección más importante: `M1-RN-ACC-004` es Conforme

En el informe de #22 dimos `M1-RN-ACC-004` como **Divergente → corregir documento**, porque la regla dice *"Con credenciales válidas, el resultado esperado es acceso al Home"* y el código tiene seis destinos según el estado del onboarding.

**Leímos sólo la columna de la regla, no la de ajuste.** La matriz ya trae esta nota sobre `M1-V02`:

> *"Las credenciales válidas no bastan para V02. Solo aplica si la cuenta está activa/verificada y no restringida. Si está `pending_verification`, derivar a V13; si está `restricted`, aplicar el tratamiento de acceso restringido (BC-005). **Con cuenta habilitada, el destino sigue dependiendo del estado: onboarding pendiente → iniciar/retomar; si corresponde → Home.**"*

Eso es exactamente lo que hace el código. **El documento no necesita corrección: ya estaba corregido.**

**Veredicto rectificado: `M1-RN-ACC-004` → `Conforme`.** Y se cae uno de los dos puntos de "corregir documento" del informe consolidado.

**Lección de método:** la matriz tiene una columna de ajuste que rectifica el texto de la regla. Leer sólo la regla produce divergencias falsas.

---

## 2. `M1-RN-ACC-031` no está pendiente de Producto — es nuestra

Lo teníamos como `Bloqueado por decisión`. La matriz lo marca **Resuelto**:

> *"Resuelto desde Producto. V03 debe usar respuesta genérica ante credenciales inválidas, mantener al usuario en Login y permitir reintento/recuperación sin revelar existencia de cuenta. La política de intentos, rate limiting, cooldown, logging y controles antiabuso **queda como parametrización/validación de Seguridad/Kabeli y no mantiene abierto el análisis de Producto.**"*

Dos consecuencias:

- **La parte funcional está definida y el backend la cumple**: `'Credenciales inválidas'` genérico, sin revelar si el correo existe.
- **La política de intentos y bloqueo es nuestra**, no del cliente. Deja de ser un pendiente de §3.3 que esperamos y pasa a ser un entregable que parametrizamos y justificamos.

**Veredicto rectificado: `M1-RN-ACC-031` → `Conforme` en lo funcional; la parametrización es entregable nuestro.**

---

## 3. `AX-M1-001` — confirmado textual, y con una salida que no teníamos

El texto completo, verificado:

> *"Baseline Walvy aceptado por Producto: OTP de 6 dígitos, TTL 10 min, reenvío a 60 s, máximo 5 intentos fallidos acumulados sin reinicio por reenvío, máximo 5 reenvíos en 15 min y cooldown de 15 min al superar el límite. Un nuevo código invalida el anterior; un código incorrecto, vencido, reutilizado o reemplazado no activa la cuenta. Kabeli debe ajustar D/E de V16 y `M1-RN-ACC-032/033`, mantener los parámetros configurables/versionados y **confirmar los valores efectivos o justificar desviaciones**. Aplicar rate limiting **al menos por cuenta/correo**, complementado por IP y, cuando sea viable, sesión/dispositivo; registrar eventos sin registrar el OTP."*

Confirma lo que teníamos en #55, **y agrega la salida**: *"confirmar los valores efectivos o justificar desviaciones"*. El TTL de 15 min contra los 10 del baseline no es automáticamente un defecto — se corrige o se justifica por escrito.

Y confirma el rate limiting **por cuenta/correo**, así que la nota de #55 sobre migrar la dimensión desde IP **se sostiene**. `M01-SEC-004` es complementario: pide que el manifest *registre* la dimensión efectiva.

### Estado del baseline OTP contra el código

| Parámetro | `AX-M1-001` | Backend | |
|---|---|---|---|
| Longitud | 6 dígitos | 6 | ✅ |
| TTL | 10 min | 15 min (default) | ❌ corregir o justificar |
| Cooldown entre reenvíos | 60 s | no existe | ❌ |
| Intentos | 5 acumulados, sin reinicio | 5 por token, se reinicia | ❌ |
| Al superar el límite | cooldown 15 min | código muerto, sin salida | ❌ |
| Tope de reenvíos | 5 en 15 min | 3/hora × 2 rutas = 6/hora | ❌ |
| Un código nuevo invalida el anterior | exigido | sí | ✅ |
| Código incorrecto/vencido/reusado no activa | exigido | sí | ✅ |
| Dimensión del rate limit | al menos cuenta/correo | sólo IP | ❌ |
| Registrar eventos sin el OTP | exigido | no existe | ❌ |

---

## 4. `M01-SEC-003` — la tolerancia estaba fijada, y la pasamos

> *"Cuenta existente/inexistente devuelve copy/código equivalentes; 20 muestras válidas por cohorte, mismo ambiente, **diferencia p95 ≤ max(250 ms, 20 % del menor p95)**, con repetición si hay ruido de infraestructura."*

`TC-M01-039` detalla: 5 de calentamiento, 20 muestras por cohorte en Login y Forgot Password, comparar `status`/`body`/`headers`/copy, calcular p95, y *"si excede, repetir controlando red; sólo una diferencia persistente es hallazgo"*.

**Nuestra medición pasa con holgura.** Con p95 menor ≈ 3 ms, el 20 % da 0,6 ms; la tolerancia efectiva es **250 ms** y la diferencia medida fue ~16 ms.

En #65 ajustamos el criterio de aceptación argumentando desde cero. **El cliente ya tenía el umbral fijado** — hay que citar ese, no el nuestro.

**Queda un entregable:** el artefacto de evidencia (CSV de tiempos, p95, respuestas, ambiente/build). `TC-M01-039` está *No iniciado*, responsable Erick.

---

## 5. `M01-SEC-006` — el criterio existe y el código diverge

> *"**Antes de verificar, el Login no crea sesión** y muestra 'Verifica tu cuenta' con envío/reenvío de código; código válido habilita acceso una sola vez; incorrecto, expirado o reutilizado no lo habilitan."*

`TC-M01-042`, paso 3: *"Confirmar que **no se cree una sesión completa** y que se muestre 'Verifica tu cuenta'"*.

La palabra **completa** es la clave: no prohíbe toda sesión, prohíbe una sin acotar — que es la opción que propusimos en #63 punto 3.

Y la matriz lo refuerza desde el otro lado: la resolución de `PD-M1-02` dice que *"V13 también pasa a Ajustar únicamente para ampliar su condición de entrada a **cuentas `pending_verification` que intentan Login**"*.

**Deja de ser pregunta y pasa a ser divergencia.** Lo que sigue abierto es sólo el alcance exacto del token acotado — el Assessment marca el control como *"Decisión funcional requerida"*.

---

## 6. `M01-PRV-002` — los campos están especificados

> *"LEGAL-V1 y LEGAL-V2 sintéticas o harness registran **`user_id` seudónimo, `document_type`, `version`, `effective_at`, `presented_at`, `channel`, `app_version`, `content_hash/reference` y `action`**."*

Y `TC-M01-034` fija la evidencia: *"Capturas + archivo/URL + **SHA-256** + manifest"*. Ahí está con qué se arma el `content_hash`.

`M01-PRV-001` exige que *"nombre/versión/hash o URL de Términos y Política estén congelados antes de ejecutar"*, y su nota advierte: *"No iniciar hasta materializar el artefacto"*.

**No falta definición, falta materializar los artefactos legales.** Está asignado a **Jose + Andrea** (`M01-PRV-001`) y **Erick + Jose** (`M01-PRV-002`).

---

## 7. Las tres reglas sin veredicto: las tres Conformes

| Regla | Texto en la matriz | Veredicto |
|---|---|---|
| `M1-RN-ACC-012` | *"Después de crear la cuenta se debe presentar el ingreso de código de verificación."* | **Conforme** — `register` devuelve `nextStep: email_verification` y el front navega a `verify-code` |
| `M1-RN-ACC-029` | *"El onboarding es posterior a la autenticación/activación y no reemplaza el alcance de acceso, registro y recuperación."* | **Conforme** — es una regla de alcance |
| `M1-RN-ACC-030` | *"El usuario debe poder continuar desde Onboarding Welcome hacia el flujo posterior definido por Producto."* | **Conforme** — la cadena `choose-alias → onboarding → doc` funciona |

**Precisión sobre #31:** `ACC-029` y `ACC-030` son reglas de **continuidad**, no de modelo de estado. El problema de la condición de cierre no vive en ellas sino en `M1-DP-009` y `M01-RGL-012`. O sea que **#31 puede emitir sus dos veredictos** y su parte bloqueada es la decisión de modelo, no las reglas.

---

## 8. `AX-M1-003` y `AX-M1-004` — insumos nuevos para el onboarding

Ninguno de los dos estaba en nuestro análisis.

**`AX-M1-003` (suficiencia).** `M01-RGL-012` es el **único gate**. Cada indicador se normaliza a `sufficient`, `pending` o `missing`, y el gate resuelve:

| Situación | Salida |
|---|---|
| Falta elemento mínimo obligatorio | `blocked` |
| Base mínima + pendiente crítico | `partial` **bloqueado** |
| Base mínima + sólo pendientes no críticos | `partial` **permitido** |
| Sin pendientes relevantes | `complete` |

⚠️ **El vocabulario no coincide con la columna.** `sufficiency_status` en la base declara `sufficient | partial | insufficient | blocked`; el anexo produce `blocked | partial | complete`. Hay que reconciliar `sufficient` ↔ `complete` y decidir qué pasa con `insufficient`.

**`AX-M1-004` (semáforo).** El color sale de un ratio canónico —egreso mensual proyectado / ingreso mensual reconocido— sobre el snapshot mensual:

| Estado | Condición |
|---|---|
| **En control** | ratio < 0,90 |
| **Atención** | 0,90 ≤ ratio < 1,00 |
| **Riesgo** | ratio ≥ 1,00, o `mora_confirmada` como único override determinista del MVP |
| **Sin diagnóstico** | no hay base suficiente — *"No usar rojo por falta de información"* |

**Esto responde la precisión 1 del borrador del correo:** `gray` corresponde a **Sin diagnóstico**, y `M1-RN-ONB-010` respalda que la insuficiencia no se pinte en rojo.

Y una advertencia repetida en las tres variantes: *"la presión y CTA se seleccionan posteriormente mediante `M01-RGL-015` y **no cambian el color por sí solas**"*.

**La precisión 2 sigue en pie.** `M01-RGL-015` gobierna presión dominante y CTA, pero **el catálogo de `dominant_pressure_code` no está enumerado** ni en la matriz ni en `AX-M1-004`. Se cita la regla, nunca sus valores.

---

## 9. Qué cambia en el tablero

| Issue | Antes | Después |
|---|---|---|
| **#22** | `ACC-004` Divergente; `ACC-031` Bloqueado | **Los dos Conformes.** La parametrización de intentos es entregable nuestro |
| **#26** | `ACC-012` sin veredicto | **Conforme.** Los cuatro criterios cerrados |
| **#31** | `ACC-029`/`030` sin veredicto | **Los dos Conformes.** Sólo queda abierta la decisión de modelo |
| **#55** | citaba `AX-M1-001` de segunda mano | Texto verificado; se suma *"confirmar o justificar desviaciones"* |
| **#65** | criterio ajustado con argumento propio | Citar el umbral del cliente: `max(250 ms, 20 % del menor p95)` |
| **#63** | *"¿qué puede hacer una cuenta sin verificar?"* | `M01-SEC-006` lo responde: no una sesión **completa** |
| **#50** | esperando definición | Los campos están; falta materializar los artefactos |

## 10. Qué queda realmente abierto

1. **El modelo de estado del onboarding.** Sigue siendo la única pregunta de fondo, ahora con dos insumos nuevos: la reconciliación del vocabulario de `sufficiency_status` y el catálogo faltante de `dominant_pressure_code`.
2. **El alcance del token de una cuenta sin verificar** — `M01-SEC-006`, marcado *"Decisión funcional requerida"*.
3. **Qué debe hacer "Cerrar sesión" con biometría activa** — `M2-V07`, sin RN formalizada.

Todo lo demás es entregable nuestro o divergencia con destino conocido.
