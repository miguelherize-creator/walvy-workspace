# Informe consolidado — Bloque Acceso · entrega parcial

**Fecha:** 2026-08-11
**Evidencia del baseline:** back-walvy `dd084c7` · front-walvy `d73d71d` · ambiente local
**Alcance:** los 14 endpoints del router `/auth` — tarjetas #22, #23, #26, #28, #29, #30, #31

---

## 0 · Por qué esta entrega es parcial, y qué la desbloquea

Este issue dice, textual: *"Esta no empieza hasta que RM1-23 y RM1-24 estén resueltas"*, y depende de RM1-01 a RM1-25. Hoy:

| | |
|---|---|
| Tarjetas de revisión con informe emitido | **7** — #22, #23, #26, #28, #29, #30, #31 |
| Tarjetas de revisión sin empezar | **14** — #27, #32 a #42, #45, y los habilitadores #20/#21 |
| Decisiones de las que depende | **#43 y #44, ambas `Todo`** |

O sea que **#46 no puede cerrarse todavía**, y no por falta de trabajo nuestro: falta revisar todo el bloque de onboarding (RM1-12 a RM1-22) y falta que Producto responda §3.3.

Lo que sí se puede entregar ya, y es lo que sigue, es el consolidado del **bloque de acceso**: está completo, tiene los 14 endpoints revisados con evidencia citable, y su backlog de remediación es accionable sin esperar ninguna decisión. Sirve para empezar a corregir mientras el resto avanza.

**Corrección a la línea base de este issue.** El objetivo habla de *"las 48 filas de la matriz"*. Según #54 la matriz vigente tiene **60 reglas y 34 HU**, no 48 y 29. El recuento de abajo va contra la matriz nueva; el criterio de aceptación *"48 reglas, 48 veredictos"* hay que actualizarlo antes de cerrar el epic.

---

## 1 · Recuento por veredicto

Reglas del bloque de acceso con veredicto emitido y evidencia `archivo:línea`:

| Veredicto | Reglas | Cuáles |
|---|---|---|
| `Conforme` | **21** | `ACC-001`, `002`, `003`, `005`, `006`, `008`, `009`, `010`, `013`, `014`, `015`, `019`, `020`*, `021`, `022`, `023`, `024`, `025`, `026`, `027`, `M1-DP-001` |
| `Divergente` | **7** | `ACC-004`, `ACC-028`, `ACC-035`, `M1-BC-005`, `M1-DP-003`, `M1-DP-009`, `M1-DP-011` |
| `Bloqueado por decisión` | **2** | `ACC-031`, política de sesión (§3.3) |
| **Sin veredicto** — falta el texto literal | **3** | `ACC-012`, `ACC-029`, `ACC-030` |

\* `ACC-020` es *Conforme con reserva*: el mensaje no revela si el correo existe, pero el tiempo de respuesta sí (#65).

**Las tres sin veredicto son el mismo bloqueo:** no tenemos exportada la **Matriz de Trazabilidad M1** (fuente 1), sólo la de Validación (fuente 2). Los veredictos de conformidad se sostienen —son controles presentes o ausentes, verificables a ojo— pero estas tres dependen de la redacción exacta. **Es el insumo más barato de destrabar de toda la lista.**

---

## 2 · Backlog de remediación — 16 tarjetas

### Clasificación

| Clase | Cantidad | Tarjetas |
|---|---|---|
| `corregir código` | **13** | #47✅, #48✅, #49✅, #55, #56, #60, #61, #62, #63, #64, #65, #66, #67, #68, #69 |
| `corregir documento` | **2** | `route-map.md` ↔ `ACC-026`; `ACC-004` ↔ retoma |
| `decisión de producto` | **4** | #50 (bloqueada), #51, #52, #53 |

Tres ya están cerradas: **#47, #48 y #49** se corrigieron en `main` con `5540498` y las verifiqué contra el código.

### Lo que hay que corregir, por prioridad

**`prio:alta` — 3 tarjetas**

| # | Qué | Dónde | Esfuerzo |
|---|---|---|---|
| **#63** | El estado de la cuenta se verifica **sólo al hacer login**. Suspender no cierra sesiones abiertas, y como `refresh` rota con vencimiento nuevo, una sesión en uso **no caduca nunca**. Además una cuenta sin verificar tiene acceso completo al API | backend | **S** el arreglo mínimo (validar estado en `refresh`); **M** acotar el token de `pending_verification` |
| **#64** | Dos peticiones que expiran a la vez **cierran la sesión en todos los dispositivos**: el cliente no serializa el refresh y el backend lo toma por replay | front + back | **S** — la mitad de cliente **ya está resuelta** en `walvy-org/walvy-app-frontend#68` |
| **#68** | El onboarding **nunca llega a `completed`**: la condición exige dos checkpoints que nadie escribe. Y los checkpoints los declara el cliente, sin verificación | backend | **M** — derivar los dos del dato real y cerrar el DTO |

**`prio:media` — 7 tarjetas**

| # | Qué | Dónde | Esfuerzo |
|---|---|---|---|
| #55 | El reenvío de OTP reinicia el contador de intentos. **Causa identificada:** `resend` y `request` son el mismo método. Trae de yapa que el tope real es **6 códigos/hora, no 3** | backend | S |
| #60 | El tope de contraseña del frontend (64 caracteres) no coincide con los 72 **bytes** del backend | frontend | S — **resuelto en PR #68** |
| #62 | Los candidatos de contraseña del RUT son dos y en orden inverso; `M1-DP-003` pide tres | frontend | S |
| #65 | `reset-password` **sin throttle** mientras su gemelo de sólo lectura sí lo tiene; y `forgot-password` revela el correo por tiempo de respuesta | backend | S |
| #66 | El restablecimiento **no se registra ni se notifica**, como exige `M1-DP-011` | backend | M — el registro definitivo depende de `M01-LOG-001` |
| #67 | La biometría se activa por dos caminos y **sólo uno avisa al backend**; desactivarla no está conectado | frontend | M |
| #56 | El error de cuenta suspendida **expone el motivo interno**. Verificado que llega literal al banner del usuario | backend | S |

**`prio:baja` — 2 tarjetas**

| # | Qué | Dónde | Esfuerzo |
|---|---|---|---|
| #61 | El frontend normaliza el RUT a minúsculas y el backend a mayúsculas. Latente | frontend | S — **resuelto en PR #68** |
| #69 | El frontend declara y llama un `GET /auth/email-verification/confirm/:token` que **el backend no expone** | frontend | S, tras decidir si el enlace sigue en alcance |

### Orden propuesto

1. **#64 backend + #63.** Los dos tocan `refresh` y son los únicos con impacto directo en usuarios reales hoy. Conviene un solo cambio en `auth.service.ts`.
2. **Cerrar PR #68** (#60 y #61 ya adentro, más la mitad de cliente de #64).
3. **#56 y #65 juntas.** Las dos son endurecimiento de acceso, las dos son de una sentada.
4. **#55**, que arrastra la nota de `IsNull()` en `email-verification.service.ts`.
5. **#68**, que necesita acordar con Jeaninne cómo se derivan los dos checkpoints.
6. **#66 y #67**, que dependen de definiciones (`M01-LOG-001` y `M2-V34`).
7. **#62 y #69** al final.

**Nota sobre el reparto de repos:** PR #68 está en `walvy-app-frontend` y puede recibir todas las correcciones de frontend. Las de backend (#63, #65, #66, #56, #55, #68, y la mitad de servidor de #64) necesitan su propio PR en `walvy-app-backend`.

---

## 3 · Adenda al documento — lo que hay que corregir del lado documental

Cinco puntos, todos con evidencia en los informes de las tarjetas:

**1 · `route-map.md` describe una re-autenticación obligatoria que no es tal.** Dice que la sesión restaurada fuerza contraseña. Es cierto que va a `/login`, pero con biometría activa se entra al Home sin escribir nada. La descripción vale sólo para la rama sin biometría. → informe de #29.

**2 · `M1-RN-ACC-004` dice "dirigir a Home" y el código tiene seis destinos.** El código es el correcto: es la retoma funcionando. La regla debería **remitir** a la definición de continuidad que ya existe (`M1-DP-009`, `M01-RGL-008`/`012`/`016`) en vez de afirmar un destino único. → informe de #22.

**3 · La política de OTP hay que subirla al documento.** §3.3 la declara pendiente y el código la tiene decidida hace tiempo: 6 dígitos, 15 min, 5 intentos por token, invalidación al agotar. La tabla del informe de #26 sirve de borrador tal cual.

**4 · El controlador documenta "máximo 3 reenvíos por hora" y son 6.** Hay dos rutas con throttle independiente que hacen exactamente lo mismo. Corregir el texto o el código — va con #55.

**5 · `GET /auth/email-verification/confirm/:token` no existe.** Figuraba en el inventario de rutas del módulo porque el **cliente** lo declara. Es una ruta fantasma. → #69.

### Y una divergencia de parámetros que necesita respuesta antes de redactar

`AX-M1-001` fija el baseline del OTP. Contra el código:

| Parámetro | `AX-M1-001` | Backend | Frontend |
|---|---|---|---|
| Longitud | 6 dígitos | 6 | 6 |
| `verification_otp_ttl` | **10 min** | **15 min** | — |
| `verification_resend_cooldown` | **60 s** | throttle `3/hora` ×2 rutas | **300 s** |
| `verification_max_attempts` | **5 acumulados** | 5 **por token** | — |
| El reenvío no reinicia intentos | exigido | **reinicia** | — |

El cooldown es el caso más claro: **tres controles distintos y ningún número en común**. `M1-DP-010` dice que vigencia y temporizador de reenvío son cosas separadas, pero no autoriza tres valores sin relación. Y falta saber si `AX-M1-001` rige también el TTL del **reset** de contraseña, que usa 15 min.

---

## 4 · Decisiones que faltan, con dueño

| Qué | Dueño | Bloquea |
|---|---|---|
| Los 5 pendientes de §3.3 sobre acceso y seguridad | Producto + Seguridad → **#43** | `ACC-031`, la política de sesión, el enrolamiento de biometría |
| Modelo de estado del onboarding: puertas vs checkpoints | Producto + Arquitectura → **#31** | RM1-17, RM1-20, RM1-21 |
| Versionamiento de T&C y Privacidad | Ya definido por el cliente; falta bajarlo al modelo → **#50** | `M01-PRV-002`/`TC-M01-035` |
| Alcance del cambio de correo | Producto → **#53** | `M2-V19` |
| Qué debe hacer "Cerrar sesión" con biometría activa | Producto → informe de #30 | `M2-V07` |
| Si la confirmación por enlace sigue en alcance | Producto → **#69** | limpieza de la superficie muerta |

**Una recomendación sobre el modelo de estado**, porque cambia el costo de la decisión: las nueve columnas de puertas, suficiencia, diagnóstico y semáforo **ya existen** en `user_onboarding_state`, con el vocabulario del documento y sus `CHECK`. Están vacías. Adoptar el modelo documental **no requiere migrar nada**: requiere empezar a escribir columnas que ya están. Eso vuelve la decisión mucho más barata de lo que el planteo original de #31 sugería.

---

## 5 · Recomendación de aprobación

Este issue pide una recomendación explícita. Para el **bloque de acceso**, y sólo para él:

> ### Aprobable con adenda.

**Por qué aprobable.** De 30 reglas con veredicto, **21 son conformes**. Las siete divergencias tienen issue abierto con clasificación y dueño, y ninguna invalida el diseño: son defectos de implementación o desalineaciones de texto, no reglas mal concebidas. Los controles que más importan —RUT con módulo 11 fallando en cerrado, política de contraseña, mensaje genérico en credenciales inválidas y en recuperación, almacenamiento seguro en Keychain/Keystore— están bien resueltos.

**Por qué con adenda y no como está.** Los cinco puntos de la §3 anterior son correcciones al documento, no al código, y dos de ellos —`route-map.md` y `ACC-004`— describen comportamientos que hoy el lector interpretaría mal. Sin la adenda, el documento aprueba una descripción que no coincide con el producto.

**Lo que no se aprueba todavía.** Las tres reglas sin veredicto (`ACC-012`, `029`, `030`) y las dos bloqueadas por §3.3. Son cinco de sesenta, y las tres primeras se destraban con un export de la matriz.

**Lo que esta recomendación no cubre.** El bloque de onboarding entero, RM1-12 a RM1-22. Las cinco aprobaciones pendientes de §7 del documento **no se desbloquean sólo con esto**.

---

## 6 · Qué hace falta para cerrar #46 de verdad

En orden de lo que más destraba:

1. **Exportar la Matriz de Trazabilidad M1** — destraba tres veredictos acá y es requisito para todas las tarjetas que siguen. Es lo más barato de la lista.
2. **Actualizar el criterio de aceptación de este issue** de 48 reglas a 60 (#54).
3. **Revisar RM1-12 a RM1-22** — 11 tarjetas, todo el bloque de onboarding.
4. **Resolver #43 y #44**, de las que este informe depende formalmente.
5. **Una prueba en dispositivo** para `ACC-028` (#30), que no se verifica leyendo código.

Mientras tanto, el backlog de la §2 se puede empezar a ejecutar: **ninguna de las 13 correcciones de código espera una decisión**, salvo #66 y #67 en su parte final.
