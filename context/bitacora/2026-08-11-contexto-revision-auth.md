# Contexto para la revisión del router Auth

**Fecha:** 2026-08-11
**Para:** sesión nueva que continúe la revisión endpoint por endpoint de `/auth`.
**Estado: los 14 endpoints están revisados.** `register` (#23), `login` (#22), `refresh`/`logout`/`logout-all` (#30), recuperación (#28), biometría (#29), onboarding (#31) y verificación de correo (#26).

Ningún issue espera trabajo de código nuestro. Los que siguen abiertos esperan **insumos externos**: el texto literal de las reglas desde la Matriz de Trazabilidad (#22, #31, #26), una prueba en dispositivo (#30), una decisión de modelo de Producto (#31) y la respuesta sobre el cierre de sesión con biometría (#30).

**Informe consolidado del bloque:** emitido en `KabeliDev/back-walvy#46` el 2026-08-11, con copia local en [`2026-08-11-informe-consolidado-bloque-acceso.md`](2026-08-11-informe-consolidado-bloque-acceso.md). Recomendación formal: **aprobable con adenda**, sólo para el bloque de acceso. #46 **no cierra** — depende de RM1-12 a RM1-22 (sin empezar) y de #43/#44.

Este documento es autocontenido. No hace falta leer la sesión anterior.

---

## 1. La regla, antes que nada

> **El código que se revisa es siempre `main` de walvy-org**, backend y frontend. No las ramas de feature, no `develop`, no `origin` de KabeliDev.

Esta regla la fijó Miguel y aplica a todos los endpoints que siguen.

Setup al empezar la sesión:

```bash
cd /Users/miguelherize/Documents/Walvy/back-walvy && git fetch walvy && git checkout main && git reset --hard walvy/main
```

```bash
cd /Users/miguelherize/Documents/Walvy/front-walvy && git fetch walvy && git checkout walvy-main && git reset --hard walvy/main
```

Verificar antes de sacar conclusiones — el estado cambia entre sesiones:

```bash
cd /Users/miguelherize/Documents/Walvy/back-walvy && git log -1 --format='%h %ad %s' --date=short
```

Referencia de esta revisión: backend `dd084c7` (2026-08-11), frontend **`d73d71d`** (2026-08-11).

⚠️ El baseline de frontend **cambió a media revisión**. Los endpoints 1 y 2 (`register` y `login`) se revisaron contra `be1036a`, que no incluía el PR de walvy-org #61; ese PR se mergeó el 2026-08-11 a las 19:51 UTC como `d73d71d`. Los hallazgos que en esos informes figuran como *"ya resuelto en PR #61"* **hoy están resueltos en `main`**. Del endpoint 3 en adelante se revisa contra `d73d71d` y ese desdoblamiento desaparece — ver §3.

---

### Evidencia exigida por el cliente

Jose Miguel (PO del cliente) aceptó `main` como baseline consolidado, **con una condición**: cada validación debe identificar claramente **commit, build y ambiente revisado**. Anotarlo en todo informe.

---

## 2. Reglas de trabajo acordadas con el cliente

Fijadas por **Jose Miguel Rodriguez** (PO) por correo el **2026-08-11**, con copia a Jeaninne, Ana, Andrea, Erick y Victoria.

### El reparto de decisiones

| Frente | Cómo se resuelve |
|---|---|
| Producto, reglas funcionales, **Seguridad y Privacidad** | **En conjunto con el cliente.** No decidir por nuestra cuenta |
| BBDD, APIs, entidades, migraciones, implementación técnica | **Directo con Jeaninne Rivera.** Escalar sólo si la solución técnica implica una definición o cambio de comportamiento del producto |

El disparador de escalamiento es explícito: **ownership, acceso, eliminación, privacidad o comportamiento funcional**. Si un cambio técnico toca alguno, deja de ser técnico.

### El método: reutilizar antes que levantar

Textual de Jose Miguel:

> *"cuando vaya apareciendo un punto nuevo, primero podamos revisar si ya existe una definición o control asociado y reutilizarlo. Si realmente aparece una necesidad funcional que no esté cubierta, la levantamos como brecha o decisión nueva según corresponda."*

El propósito declarado es **evitar reabrir definiciones ya documentadas** y evitar decisiones paralelas. En la práctica esto cambia cómo trabajamos:

**Antes de abrir un issue de decisión, buscar primero el control existente** en la matriz de trazabilidad y en el assessment. Sólo si no existe, levantarlo como brecha.

Ya nos pasó: el issue #50 propone desde cero un modelo de versionamiento de T&C, y Jose Miguel responde que el tema **ya está definido** en `M01-PRV-002` / `TC-M01-035` y `M01-PRV-003` / `TC-M01-036`. Lo que falta no es la definición sino bajarla al modelo y evidenciarla en QA.

### Estado por tema, según el cliente

| Tema | Estado | Códigos de referencia | Quién decide |
|---|---|---|---|
| Versionamiento de T&C, Privacidad y consentimientos | **Ya definido** — falta bajarlo al modelo y evidenciarlo en QA | `M1-HU-005`, `M1-HU-006`, `M01-RGL-002`, `M01-PRV-002`/`TC-M01-035`, `M01-PRV-003`/`TC-M01-036` | Producto + Seguridad/Privacidad; implementación con Jeaninne |
| Checkpoints, retoma y cierre de onboarding | **Ya definido funcionalmente** — falta garantizarlo técnicamente | `M1-DP-009`, `M01-RGL-008`, `M01-RGL-012`, `M01-RGL-016` | Criterio funcional en conjunto; solución técnica Miguel + Jeaninne |
| Roles, permisos y autorización | **Parcialmente definido** — hay RBAC y controles, pero **no** una matriz transversal rol → permiso | `M01-AUT-001`/`TC-M01-044`, `M01-SEC-007`/`RDY-SEC-007` | **En conjunto**, Producto + Seguridad |
| Persistencia del flujo M01 | Contemplado — cruzar el dump contra los controles | `M01-RGL-005`, `006`, `008`, `009`, `013`, `016` | Nosotros preparamos evidencia; ellos revisan cobertura |
| FK hacia `app_user` | **No hay RN funcional** que las prescriba | controles de trazabilidad, auditoría y autorización | Miguel + Jeaninne |
| `DB_SYNC=false` y gobierno del esquema | **No hay RN funcional** | — | Miguel + Jeaninne |
| APIs, entidades TypeORM, contratos técnicos | Los casos fijan comportamiento, **no** implementación física | `03_Casos_Prueba_M01`, `04_Privacidad_Seguridad` | Miguel + Jeaninne |
| Seguridad y Privacidad de datos | Frente identificado — falta **materializar y evidenciar** | `M01-SEC-*`, `M01-PRV-*`, `M01-LOG-001`, `M01-AUT-001`, `M01-DOCSEC-*` | **En conjunto**, PO + Miguel + Jeaninne |
| Módulos activos, desacoplados o no integrados | M01 mantiene ownership separado | `14_Soporte_QA` | Miguel + Jeaninne; revisar juntos si contradice alcance |
| `main` como baseline | De acuerdo | — | Miguel + Jeaninne, con commit/build/ambiente identificado |

Advertencia sobre la fila de Seguridad: dice explícitamente que **no debe tratarse únicamente como una decisión de estructura de BBDD**. Resolver un control de privacidad agregando una columna y dándolo por cerrado no cumple el criterio.

---

## 3. Dos remotes, y una trampa

Los dos repos locales tienen **dos remotes independientes, sin relación de fork**:

| Remote | back-walvy | front-walvy |
|---|---|---|
| `origin` | `KabeliDev/back-walvy` | `KabeliDev/front-walvy` |
| `walvy` | `walvy-org/walvy-app-backend` | `walvy-org/walvy-app-frontend` |

**KabeliDev** es la organización de Kabeli (la consultora): ahí viven **los issues y el tablero**. Miguel es `member`.
**walvy-org** es la organización del cliente: ahí vive **el código y los PRs**. Miguel es `member` con `WRITE`.

### La trampa

Los números de issue **colisionan entre las dos organizaciones**. `#20`, `#23`, `#24`, `#49`, `#50` existen en ambas y significan cosas distintas — en walvy-org son PRs de Dependabot ya mergeados.

**Nunca poner `#NN` a secas en un commit o PR que va a walvy-org.** Citar sólo la regla de negocio (`M1-RN-ACC-008`), que es el único identificador que significa lo mismo en ambos lados porque el cliente tiene el documento. Ya pasó una vez: los commits `f49f6c4` y `b497b1b` de PR #65 quedaron enlazando a PRs ajenos.

La colisión también muerde **dentro de este documento**: `#61` es la tarjeta de remediación del RUT en KabeliDev, y `PR #61` es el pull request de frontend en walvy-org. Son cosas distintas. Convención acá: **`#NN` a secas = issue de KabeliDev**; el de walvy-org siempre lleva `PR` adelante o el repo completo.

### Estado de sincronización

- **back-walvy `main`**: alineado con walvy-org. Para actualizarlo cuando el cliente avance:
  ```bash
  cd /Users/miguelherize/Documents/Walvy/back-walvy && git fetch walvy && git fetch origin && git merge-base --is-ancestor origin/main walvy/main && git push origin walvy/main:refs/heads/main
  ```
- **front-walvy `main`**: las dos historias **no tienen ancestro común** (KabeliDev se sembró con un initial commit propio). 104 commits sólo en KabeliDev, 46 sólo en walvy-org. No se puede alinear sin destruir un lado. Decisión tomada: **no tocarla**.

### El PR de walvy-org #61 ya está en `main` — cerrado

`walvy-org/walvy-app-frontend#61` — *Bugfix/modulo1 registro recuperacion onboarding* — se **mergeó el 2026-08-11 19:51 UTC** como `d73d71d`.

| | |
|---|---|
| URL | https://github.com/walvy-org/walvy-app-frontend/pull/61 |
| Rama | `bugfix/modulo1-registro-recuperacion-onboarding` → `main` |
| Merge commit | `d73d71d` |
| Autor | `leonardosalas-kabeli` |
| Tamaño | 22 archivos, +281 / −133 |

**Qué significa para los informes ya escritos.** Los endpoints 1 y 2 se revisaron contra `be1036a`, anterior al merge, y sus hallazgos de copy y biometría llevan la marca *"ya resuelto en PR #61"*. Esa marca hay que leerla hoy como **resuelto en `main`**: no son deuda pendiente y no necesitan tarjeta. Del endpoint 3 en adelante no hay desdoblamiento — se revisa `d73d71d` y punto.

**Qué arregló** (ya en `main`, sirve para no volver a levantarlo):

| Área | Cambio | Regla / hallazgo citado en el PR |
|---|---|---|
| T&C y Privacidad | El botón "Acepto" del sheet exige **haber recorrido el documento** (tolerancia 24 px); el checkbox ya no se puede marcar sin abrirlo — sólo desmarcar | BUG-4 · `TC-M01-003` |
| Login | Tras **3 intentos biométricos fallidos** fuerza fallback a credenciales (`MAX_BIOMETRIC_ATTEMPTS`) | `M1-RN-ACC-027` · `MV-M1-02` / `M1-V07` |
| Login | Copy: "Crea tu cuenta", placeholder en minúscula, `capitalize` aplicado a todo el `displayName` | BUG-3, BUG-7 · `TC-M01-002`, `TC-M01-006` |
| Recuperación | Validación de formato de correo en pantalla + `router.push` en vez de `replace`, para que el back vuelva a Forgot y no a Login | BUG-6 · `TC-M01-005` |
| OTP | Cooldown pasa a **reloj de pared** (`cooldownEndAt`) y se recalcula al volver de background vía `AppState` — antes el contador se congelaba con la app suspendida | — |
| Onboarding | Estado **rojo bloquea el avance** a la primera lectura (falta el ingreso principal) | `M1-V51` |
| Onboarding | Carrusel avanza solo cada 5 s | BUG-8 |
| Alias | Botón "Omitir y continuar" — avanzar sin completar ningún dato | `M1-V25` · `RN-ACC-016` |
| Alias | El alias exige al menos un carácter alfanumérico | BUG-5 · `TC-M01-004` |
| Registro | Errores de correo van a `emailError` (bajo el campo) y no al banner general | BUG-5 · `TC-M01-004` |

**Lo que NO arregló.** Verificado archivo por archivo antes del merge: **ninguna de las divergencias de `/auth/register` (§7) quedó resuelta.** `registerIdentifier.ts` no estaba entre los archivos tocados, y `maxLength={64}` y `TERMS_CONTENT` siguieron igual.

Ojo con una: el PR endureció la **captura** del consentimiento (scroll obligatorio, checkbox no marcable a mano) pero los textos legales siguen siendo constantes en el bundle. Eso mejora `TC-M01-003` sin tocar `M01-PRV-002` / `TC-M01-035`, que es lo que exige versionamiento. **No dar el tema por cerrado por este PR.**

**Un pendiente que quedó sin levantar.** El commit `chore: limpieza de comentarios` borró comentarios que sí explican el *porqué* y que ningún test al fallar revelaría — entre otros, el bug de buffer duplicado de teclados Android en `useRegisterForm.onRutChange`, y el guard de `resetRegisterError` que evita re-renderizar toda la app en cada tecla. Al mergearse sin revisión de esto, esos comentarios se perdieron en `main`. Si vale recuperarlos, ya es un cambio nuevo.

### Rama de remediación — PR de walvy-org #68, abierto

`bugfix/M1-RN-ACC-008-009-contrato-registro-frontend` → https://github.com/walvy-org/walvy-app-frontend/pull/68

Aplica **#60** y **#61** (mitad de frontend del contrato de contraseña y del RUT): un commit por regla más el merge de `d73d71d`. 11 archivos, +181/−18. Nomenclatura según el modelo de Erick (`bugfix/<ticket>-<descripción>`, Conventional Commits) y sin `#NN` en los mensajes ni en el cuerpo del PR, sólo la regla de negocio.

CI en verde: `frontend-quality` (install, lint, typecheck, test, build) pasó. Localmente, 17 suites / 111 tests.

`bun run lint` **sólo corre desde `front-walvy/expo`**. Desde la raíz del repo resuelve al `lint` del SDK de Android y sale con código 2 — parece un fallo del proyecto y no lo es.

`bun run lint` **sólo corre desde `front-walvy/expo`**. Desde la raíz del repo resuelve al `lint` del SDK de Android y sale con código 2 — parece un fallo del proyecto y no lo es.

---

## 4. Dónde está el trabajo

**Tablero único:** https://github.com/orgs/KabeliDev/projects/10 — *Walvy — Revisión y Validación M1/M2*, 62 items de ambos repos. El tablero personal fue borrado; este es el único vigente.

Campos: `Status` (Todo · In Progress · In Review · Blocked · Done), `Tipo`, `Módulo`, `Prioridad`, `Bloque`, `Reglas cubiertas`.

| `Tipo` | Qué es | Dónde |
|---|---|---|
| `revisión` (28) | Contraste documento ↔ código, tarjetas `RM1-*` | `KabeliDev/back-walvy#20-46`, `#54` |
| `validación` (24) | Variantes de las matrices, tarjetas `MV-M1-*` / `MV-M2-*` | `KabeliDev/front-walvy#18-41` |
| `remediación` (16) | Defectos de código a corregir | `back-walvy#47-50`, `#55`, `#56`, `#60-69` |
| `decisión` (4) | Bloqueadas esperando Producto | `back-walvy#51`, `#53`; `front-walvy#48` |

Los defectos de **frontend** también se abren en `back-walvy`, con la etiqueta `area:frontend`. Es donde vive la taxonomía de la revisión (`tipo:remediacion`, `bloque:*`, `prio:*`); `front-walvy` sólo tiene las tarjetas de validación de variantes.

Estado de las remediaciones al 2026-08-11:

| Issue | Qué es | Estado |
|---|---|---|
| #47 | RUT sin normalizar al persistir | **Done** — en `main` |
| #48 | Validación de documento falla en abierto | **Done** — cerrado hoy, arreglado en `5540498` |
| #49 | Sin tope de contraseña (bcrypt trunca en 72 bytes) | **Done** — cerrado hoy, arreglado en `5540498` |
| #50 | No se persiste qué versión de T&C se aceptó | **Blocked** — Producto |
| #55 | El reenvío de OTP reinicia el contador de intentos | Todo |
| #56 | El error de cuenta suspendida expone el motivo interno | Todo |
| #60 | Tope de contraseña del frontend: 64 vs 72 bytes | Todo · `area:frontend` |
| #61 | RUT: front minúsculas, backend mayúsculas | Todo · `area:frontend` |
| #62 | Candidatos de contraseña del RUT: dos y en orden inverso | Todo · `area:frontend` |
| #63 | El estado de la cuenta se verifica sólo al hacer login | Todo · **`prio:alta`** |
| #64 | Dos peticiones que expiran a la vez cierran la sesión en todos los dispositivos | Todo · **`prio:alta`** |
| #65 | `reset-password` sin throttle + fuga por tiempo en `forgot-password` | Todo |
| #66 | El reset no se registra ni se notifica (`M1-DP-011`) | Todo |
| #67 | La preferencia de biometría se activa por dos caminos y sólo uno avisa al backend | Todo |
| #68 | El onboarding nunca llega a `completed`; los checkpoints los declara el cliente | Todo · **`prio:alta`** |
| #69 | El frontend llama un `GET .../confirm/:token` que el backend no expone | Todo · `prio:baja` |

**El tablero se desincroniza del código.** #48 y #49 estaban en *In Review* con el arreglo ya mergeado en `main` desde el 2026-08-10. Antes de trabajar un issue de remediación, verificar el archivo — no el estado de la tarjeta.

Issues de Auth relevantes en `KabeliDev/back-walvy`:

| Issue | Tarjeta | Endpoint que cubre |
|---|---|---|
| #22 | `RM1-02` Pantalla de acceso y login | `/auth/login` |
| #23 | `RM1-03` Registro — contrato y RUT | `/auth/register` ✅ revisado |
| #24 | `RM1-04` Política de contraseña | transversal a register/reset/change |
| #25 | `RM1-05` T&C y Privacidad | `/auth/register` |
| #26 | `RM1-06` Verificación de cuenta (OTP) | `email-verification/*` |
| #28 | `RM1-08` Recuperación de acceso | `forgot-password`, `verify-reset-code`, `reset-password` |
| #29 | `RM1-09` Usuario guardado y biometría | `/auth/biometric` |
| #30 | `RM1-10` Persistencia de sesión | `refresh`, `logout`, `logout-all` |
| #31 | `RM1-11` Continuidad y modelo de estado | `/auth/onboarding`, `onboarding/step` |
| #43 | `RM1-23` Decisiones de acceso y seguridad | transversal |

---

## 5. Jerarquía de fuentes documentales

Cuando dos fuentes se contradicen, gana la de más arriba:

1. **Matriz de Trazabilidad WALVY M1** — revisada y **cerrada por el Cliente**, 2026-08. Es la fuente vigente. 60 reglas, 34 HU, 60 variantes (42 `Aprobado` / 18 `Ajustar`), 13 decisiones `M1-DP-*` todas resueltas, 4 anexos `AX-M1-*` con parámetros.
   `https://docs.google.com/spreadsheets/d/1MRRKk-hNZT0HUFios8WT2Tsrz3vkd5is/edit`
2. **Matrices de Validación M1 y M2** — 60 + 84 variantes con nodos de Figma.
   M1: `https://docs.google.com/spreadsheets/d/12eazr53al6LpeoMLvtPxr_kdSnlcsmIq/edit`
   M2: `https://docs.google.com/spreadsheets/d/1bSjP-RwUvTtw6reC_scQ6Ey-maOTR3o8/edit`
3. **Documentación Formal M1 v3.0** — base original del epic. **Superada** en reglas (48 vs 60) y HU (29 vs 34), pero sigue siendo la única fuente de las historias con sus criterios de aceptación.
   `https://docs.google.com/document/d/1gBJzAuobWVK2h2qdNxBuoranpgxdmlLR/edit`
4. **Figma** — `https://www.figma.com/design/v45c4HTKnPnU0XABMa5vjY/Walvi-APP---Edificate-Inteligente`. Los `node-id` por variante están en `variantes-validacion.psv`, en esta misma carpeta.

Copia local de las 144 variantes con sus nodos: `variantes-validacion.psv` (formato `MOD|FLUJO|VID|ESCENARIO|CONDICION|COMPORTAMIENTO|CLASIF|REGLA|NODO`).

---

## 6. Método de revisión

Por cada endpoint, contrastar **cuatro frentes**: documento ↔ backend ↔ frontend ↔ Figma. Veredicto por regla:

| Veredicto | Cuándo |
|---|---|
| `Conforme` | Las fuentes dicen lo mismo |
| `Divergente` | Implementado, distinto de lo declarado → issue de remediación |
| `No implementado` | Declarado y ausente |
| `No aplica` | Regla de UI pura sin contraparte backend, o viceversa |
| `Bloqueado por decisión` | Depende de un pendiente de Producto |

**Todo veredicto exige evidencia citable** — `archivo:línea`, endpoint o `node-id`. Sin evidencia no se cierra.

**Una divergencia nunca se arregla dentro de la revisión.** Se registra, se clasifica (`corregir código` / `corregir documento` / `decisión de producto`) y se abre issue hijo.

**Verificar antes de afirmar.** Ya pasó dos veces en `/auth/register`, y las dos en la misma dirección — reportar como faltante algo que sí está:

- El control mostrar/ocultar contraseña: `RegisterScreen` sólo tiene `secureTextEntry`, pero el control vive en `AppInput.tsx:134-148`.
- La confirmación de correo: se reportó ausente y está en `RegisterScreen.tsx:393`, bloqueando el submit vía `isFormReady`.

Antes de concluir que un control falta: leer el componente compartido, y `grep` del concepto en toda la pantalla — no sólo del `label` que uno espera.

---

## 7. Endpoint 1 — `POST /auth/register` ✅ revisado

Revisión completa en `KabeliDev/back-walvy#23`, comentario del 2026-08-11.

**Conforme:** `M1-RN-ACC-008` (RUT con módulo 11, falla en cerrado), `M1-RN-ACC-009` (los tres requisitos de `PasswordHints.tsx:12-14` son idénticos al DTO), `M1-RN-ACC-010`, `M1-DP-001`.

**Divergencias — estado al 2026-08-11, todas con destino:**

| # | Divergencia | Estado |
|---|---|---|
| 1 | Confirmación de correo ausente | **Descartada — era falso positivo** |
| 2 | Tope de contraseña: front 64 caracteres / backend 72 bytes | → **#60** (`prio:media`) |
| 3 | RUT normalizado en direcciones opuestas | → **#61** (`prio:baja`) |
| 4 | `M1-DP-003` a medias — dos candidatos y en orden inverso | → **#62** (`prio:media`) |
| 5 | Textos legales como constante en el bundle | → **#50**, bloqueado en Producto |

Detalle de cada una:

1. ~~No existe confirmación de correo~~ — **sí existe.** `RegisterScreen.tsx:393`, campo *"Confirma tu correo electrónico"*; compara en `:289`, avisa en `:398`, y entra en `isFormReady` (`:338`) que gobierna el `disabled` del botón (`:483`). Que no esté en `RegisterDto` es correcto: la confirmación es control de captura del cliente y no viaja al API. `M1-RN-ACC-006` queda **`Conforme`**.
2. **Tope de contraseña incoherente** — front `maxLength={64}` caracteres en tres inputs (`RegisterScreen.tsx:445`, `ResetPasswordScreen.tsx:110` y `:122`), backend `@MaxBytes(72)` bytes en los tres DTOs, y el mensaje del backend promete 72 caracteres. El borde UTF-8 queda descubierto en el cliente.
3. **RUT normalizado en direcciones opuestas** — front `.toLowerCase()` (`registerIdentifier.ts:7`), backend `.toUpperCase()` (`rut.validator.ts:12`). Latente, no activo: el backend renormaliza al persistir y el login es email-only.
4. **`M1-DP-003` a medias** — `getRutPasswordCandidates` devuelve `[first4, last4]`; la decisión exige tres (RUT completo sin DV → últimos 4 → primeros 4) y en ese orden. El test congela el comportamiento incorrecto. Impacta el auto-desbloqueo de cartolas en el onboarding.
5. **Textos legales en el bundle** — `TERMS_CONTENT` es constante en `RegisterScreen.tsx`, no links versionados. Bloquea el modelo de #50.

Las tres tarjetas nuevas son **frontend puro**: el backend ya quedó correcto con #47 y #49. **Ninguna quedó resuelta por el PR de walvy-org #61** (ver §3); siguen vivas en `d73d71d`.

La 1 conviene tenerla presente como patrón, no como caso aislado: es el segundo falso positivo del mismo tipo, después del toggle de mostrar/ocultar contraseña que vive en `AppInput.tsx:134-148`. En este frontend, no ver el control en la pantalla no significa que no esté.

---

## 7 bis. Endpoint 2 — `POST /auth/login` ✅ revisado

Revisión completa en `KabeliDev/back-walvy#22`, comentario del 2026-08-11. Node-id de Figma completados desde `variantes-validacion.psv`: `M1-V01` `3470:6974` · `M1-V02` `3361:2744` · `M1-V03` `3677:2837` · `M1-V04` `3470:7098` · `M1-V08` `3470:7249` · `M1-V17` `3470:7010`.

**Conforme:** `M1-RN-ACC-001`, `002` (frontend puro), `003`, `005`, `025`.

**El hallazgo grande — #63, `prio:alta`.** El estado de la cuenta se verifica **sólo en la puerta del login**. `JwtStrategy.validate` (`jwt.strategy.ts:18-27`) sólo mira que el payload traiga `sub` y `email`; `refresh()` (`auth.service.ts:161-186`) emite tokens nuevos sin consultar `userStatusId`; y nada llama a `revokeAllRefreshForUser` al suspender. De ahí:

- **Suspender no cierra sesiones abiertas.** Y `refresh()` rota el token con vencimiento nuevo a 30 días (`:243`), así que una sesión en uso no caduca nunca. Rompe `M1-BC-005`.
- **Una cuenta sin verificar tiene acceso completo al API.** El login emite tokens en `pending_verification` (`:127`) sin acotarlos; `emailVerifiedAt` no se consulta en ningún guard.

El arreglo mínimo —validar estado en `refresh`— cierra `M1-BC-005` sin depender de ninguna definición pendiente.

**Los otros cuatro hallazgos, todos con destino:**

| Hallazgo | Clasificación | Va a |
|---|---|---|
| `M1-RN-ACC-004` dice "dirigir a Home"; el código tiene seis destinos por la retoma (`useLoginForm.ts:142-192`). El código es el correcto | corregir documento | #46 |
| El login acepta **sólo correo** (`@IsEmail`, `findByEmailWithPassword`); las variantes dicen "correo/usuario" | pregunta de alcance al PM | — |
| El `403` de cuenta suspendida se pinta literal en el banner (`useLoginForm.ts:206-210` → `LoginScreen.tsx:202-204`) | evidencia | #56 |
| El throttle `5/60s` es **por IP**, no por cuenta: no frena un ataque distribuido y castiga a usuarios tras un mismo CGNAT | decisión en código que el doc no recoge | #43 |

**Ya resuelto en `main` por el PR de walvy-org #61, sin tarjeta:** placeholder con mayúscula intermedia, los dos textos distintos del link de registro, `capitalize()` aplicado sólo al fallback del correo, y el tope de 3 reintentos biométricos (`M1-RN-ACC-027` / `M1-V07`).

**Lo que falta para cerrar #22:** el texto literal de `M1-RN-ACC-001` a `005`. Los veredictos se apoyan en las variantes de la Matriz de Validación (fuente 2), no en la de Trazabilidad (fuente 1), que **no está exportada localmente**. Las conformidades aguantan; el veredicto de `004` y la pregunta de "correo/usuario" dependen de la redacción exacta.

---

## 7 ter. Endpoints 3-5 — `refresh`, `logout`, `logout-all` ✅ revisados

Revisión completa en `KabeliDev/back-walvy#30` (RM1-10), comentario del 2026-08-11. **Primer informe con baseline de frontend `d73d71d`.**

**El hallazgo grande — #64, `prio:alta`.** Dos peticiones que fallan con `401` a la vez cierran la sesión del usuario **en todos sus dispositivos**. El interceptor no serializa el refresh (`api/client.ts:54-93`): cada `401` lee el mismo token y lanza su propio `POST /auth/refresh`. El backend rota y trata la reutilización como replay (`auth.service.ts:169-172`) con `revokeAllRefreshForUser`. Con access de `15m`, basta volver a la app y que dos queries se monten juntas. El arreglo del cliente —refresh en un solo vuelo— no toca el backend.

### La política de sesión efectiva (lo que #30 pedía documentar)

| Parámetro | Valor real |
|---|---|
| Access token | **15 min** (`JWT_EXPIRES_IN`) |
| Refresh token | **30 días** (`REFRESH_EXPIRES_DAYS`) |
| Rotación | en cada refresh, **con vencimiento nuevo** |
| Caducidad de una sesión en uso | **ninguna** — ventana deslizante |
| Sesiones concurrentes | **sin límite** |
| Revocación automática | reset y cambio de contraseña, replay detectado |
| Revocación por suspensión | **no existe** (#63) |
| Limpieza de tokens vencidos | **no existe** — sin job ni cron |

Dos consecuencias que no estaban a la vista: los 30 días **no son la vida de la sesión sino el máximo de inactividad**, y `refresh_tokens` crece sin techo (≈100 filas por día por usuario activo). Las dos alimentan #43.

### Los otros tres hallazgos

| Hallazgo | Clasificación | Va a |
|---|---|---|
| **"Cerrar sesión" con biometría activa no cierra nada.** La rama `bioEnabled && !forceComplete` de `AuthProvider.tsx:263-266` está **vacía**: no llama a `logoutUser()`, no borra tokens. Sólo limpia memoria — y el interceptor sigue adjuntando el access token a cualquier request | `M2-V07` declara la RN **pendiente** → sin tarjeta, se pregunta primero | Producto |
| **`/auth/logout-all` no lo consume nadie.** Implementado con guard JWT, cero llamadas en `expo/` | `M2-V44` ya declara la brecha; el endpoint ya existe, falta la UI | Producto (`M2-V44`) |
| **La entidad TypeORM de `refresh_tokens` no declara índices.** El único sobre `token_hash` existe sólo en la migración (`1786000004000:178`) | nota de migraciones, no defecto de runtime | Jeaninne |

**Lo que falta para cerrar #30:** `M1-RN-ACC-028` (minimizar y retomar) **exige evidencia en dispositivo** — no se verifica leyendo código. Del código sí se sabe que no hay persistencia de borradores: el estado vive en `useState` y sólo hay dos suscriptores de `AppState` (cooldown del OTP y conectividad).

---

## 7 quater. Endpoints 6-8 — recuperación de acceso ✅ revisados

Revisión completa en `KabeliDev/back-walvy#28` (RM1-08), comentario del 2026-08-11. Baseline frontend `d73d71d`. **#28 pasó a In Review: los dos criterios de aceptación están cubiertos.**

**Conforme:** `M1-RN-ACC-019`, `020` (con reserva), `021`, `022`, `023`, `024`, y `M1-V19` (modal de soporte con `soporte@walvy.cl`, coherente con `M1-DP-011`).

**La pregunta central del issue tiene respuesta: sí.** El frontend usa `verify-reset-code` antes de `reset-password` — `useVerifyCodeForm.ts:109-114` valida y sólo navega si el backend confirma. El backend acompaña: `verifyResetCode` no marca `usedAt` y el código se revalida en el reset. `M1-RN-ACC-021` **Conforme**.

**Dos tarjetas nuevas, las dos backend:**

| Issue | Hallazgo | Prio |
|---|---|---|
| **#65** | El throttle está en el endpoint equivocado: `verify-reset-code` (sólo valida) tiene `10/60s`, `reset-password` (valida **y cambia la contraseña**) **no tiene ninguno**. Y `forgot-password` no revela el correo por mensaje pero **sí por tiempo** — la rama del correo registrado espera el `await` del SMTP | media |
| **#66** | `M1-DP-011` pide renovar credenciales, invalidar sesiones, **registrar y notificar**. El código hace las dos primeras. No hay correo de aviso ni registro del evento — y la misma decisión deriva a soporte, que hoy no tiene insumo | media |

### Parámetros del flujo de reset, para #43

| Parámetro | Valor | Origen |
|---|---|---|
| TTL del código | **15 min** | `PASSWORD_RESET_EXPIRES_MINUTES` |
| Intentos por código | **5**, compartidos entre `verify-reset-code` y `reset-password` | `MAX_ATTEMPTS` |
| Códigos activos por usuario | **uno** — `delete({ userId })` antes de emitir | `:39` |
| Tras agotar intentos | pedir código nuevo reinicia `attempts` a 0 | `:39-56` |

**Pregunta abierta al PM:** `AX-M1-001` fija `verification_otp_ttl` en **10 min** para el OTP de verificación; el de recuperación usa **15**. ¿El baseline rige los dos flujos o el reset tiene parámetro propio? No bloquea nada — sólo define si hay una divergencia más.

---

## 7 quinquies. Endpoint 9 — `PATCH /auth/biometric` ✅ revisado

Revisión completa en `KabeliDev/back-walvy#29` (RM1-09), comentario del 2026-08-11. **In Review: los tres criterios de aceptación están cubiertos.**

**La divergencia central del issue está resuelta: el documento desactualizado es `route-map.md`, no la regla.** Es cierto que una sesión restaurada nunca entra directo al Home (`SplashScreen.tsx:64-67` manda a `/login`), pero *ir a login* no es *pedir contraseña*: con biometría activa, `LoginScreen.tsx:67-71` arranca en modo `savedUserBiometric` y la huella lleva al Home sin escribir nada. La re-auth por contraseña **sólo** aplica cuando no hay biometría. → corregir documento, va a #46.

Precisión que conviene tener escrita: `loginWithBiometric` **no vuelve a autenticar contra el backend**. Verifica la huella, lee el access token de `SecureStore` y llama a `getMe()`. El gate biométrico es **enteramente del cliente** — por eso el backend no participa de nada de este flujo.

**Conforme:** `M1-RN-ACC-025`, `026`, `027`.

**El hallazgo — #67, `prio:media`: la preferencia de biometría no tiene un único dueño.**

| Camino de activación | Local | Backend |
|---|---|---|
| Onboarding (`BiometricPromptScreen.tsx:55-56`) | ✅ | ✅ `setupBiometric` |
| Oferta post-login (`useBiometricLogin.ts:49`) — que es `M1-RN-ACC-035` | ✅ | **nada** |

Y **desactivarla no está conectado**: `disableBiometric` existe en el `AuthProvider` y no lo llama nadie; no hay pantalla de Seguridad en `expo/features/profile`. *"Cambiar de usuario"* la apaga escribiendo la preferencia local a mano, sin avisar al backend.

No rompe el login —el backend no consulta `biometric_preferences` para decidir nada— pero deja mal el dato en todos los que activaron desde la oferta post-login.

**Verificado y correcto, para no volver a levantarlo:**

- **`M1-RN-ACC-027` no encierra al usuario.** Tope de 3 en el cliente (`MAX_BIOMETRIC_ATTEMPTS`), fallback a contraseña o a `firstTime`, y el contador se reinicia al remontar la pantalla. **El tope es sólo del cliente**: el backend no cuenta intentos biométricos → dato para #43.
- **El fix de `secureStorage` está aplicado** en `d73d71d`. `ensureWebStorageIsDevOnly()` (`:17-28`) lanza fuera de `__DEV__` en vez de degradar a storage inseguro; en nativo todo va por Keychain/Keystore.

---

## 7 sexies. Endpoints 10-11 — onboarding ✅ revisados

Revisión completa en `KabeliDev/back-walvy#31` (RM1-11), comentario del 2026-08-11. Sigue **In Progress**: falta el texto de `M1-RN-ACC-029`/`030` y la decisión de modelo, que es de Producto.

### La corrección que cambia el planteo

El issue daba por inexistentes las columnas de puertas, suficiencia y diagnóstico. **Existen: nueve, con el vocabulario exacto del documento** — `current_gate`, `last_completed_gate`, `resume_state`, `pending_best_action`, `diagnostic_status`, `sufficiency_status`, `general_traffic_light_status`, `dominant_pressure_code`, `dominant_cta_code`. En la entidad (`:69-125`) y en la migración `1786000004000:343-362`, con sus `CHECK`.

**Y cero código las toca.** Conté los usos de cada una fuera de la entidad: todos en cero. `toOnboardingPublic` devuelve sólo el modelo viejo de checkpoints.

Así que la pregunta del issue —*¿extendemos el modelo o corregimos el documento?*— está medio contestada: **el modelo ya se extendió**. Falta la capa de servicio que lo llene y la ratificación formal.

⚠️ Es el reverso de la trampa habitual: acá **columna en el schema tampoco significa feature**. Nueve columnas muertas.

### El hallazgo — #68, `prio:alta`

**El onboarding nunca llega a `completed`.** La condición exige cuatro checkpoints y **dos no los escribe nadie**: `financialProfileCompleted` y `minDocThresholdMet` se inicializan en `false` y la app nunca los envía — los únicos `true` están en la respuesta del modo mock y en un test. `allDone` es siempre `false`, `completed_at` siempre `null`.

**La app funciona igual porque no usa ese estado**: rutea con `resumeSurface`, que las pantallas finales ponen en `"home"` a mano. El cierre real del onboarding lo marca un campo de navegación.

**Y los checkpoints los declara el cliente**: `updateOnboardingStep` escribe los cinco booleanos con lo que venga en el body, sin contrastar nada. `currentStep` y `resumeSurface` son `@IsString()` libres, sin enum.

**No arreglarlo mandando los dos booleanos que faltan** — eso haría alcanzable una condición que el Cliente ya dijo que es la incorrecta.

### `M1-DP-009`, precisada

No es que el backend cierre por checkpoints y el documento por diagnóstico. Es que **no cierra por ninguna de las dos**: la del código es inalcanzable y la del documento no está implementada. `diagnostic_status`, donde viviría el criterio documental, existe y está vacía.

Eso abarata la decisión pendiente: alinear con `M1-DP-009` no requiere migrar nada, requiere empezar a escribir una columna que ya está.

**Recomendación planteada al cliente (no decidida):** adoptar el modelo que ya está en la tabla y tratar los checkpoints booleanos como provisorios.

**#31 bloquea `RM1-17`, `RM1-20` y `RM1-21`** — los tres dependen de la misma respuesta.

---

## 7 septies. Endpoints 12-14 — verificación de correo ✅ revisados

Revisión completa en `KabeliDev/back-walvy#26` (RM1-06), comentario del 2026-08-11. **Con esto los 14 endpoints están revisados.**

**Conforme:** `M1-RN-ACC-013`, `014`, `015`. Falta `012` por el texto literal de la matriz.

### `resend` y `request` son el mismo método → evidencia sumada a #55

Las dos rutas llaman idéntico a `requestEmailVerification` (`auth.controller.ts:152-156` y `:188-192`). De ahí salen **dos** efectos:

1. **El reinicio del contador de intentos** que ya reporta #55: `prepareEmailVerificationOtp` invalida lo anterior y crea un token con `attempts: 0`. No hay lógica de reenvío que preserve intentos porque no hay lógica de reenvío.
2. **El tope real es 6 códigos por hora, no 3.** Cada `@Throttle` cuenta por ruta, así que se agotan los 3 de `resend` y siguen los 3 de `request`. El controlador documenta *"máximo 3 reenvíos por hora"*.

### Las tres superficies del frontend → #69 `prio:baja`

**La viva es `expo/app/(auth)/verify-code.tsx`.** `verify.tsx` y `confirm-account.tsx` montan la misma `AccountConfirmedScreen` y son deep links de un flujo de **enlace mágico** que llama a `GET /auth/email-verification/confirm/<token>` (`endpoints.ts:16`) — **endpoint que el backend no expone**. Y nadie produce el enlace: el correo manda sólo el código.

Es código inalcanzable, no roto en producción, pero **es el origen de la ruta fantasma** que apareció en el inventario del módulo. La rama `status=success|error` de esa pantalla sí es legítima; lo muerto es la rama del `token`.

### El cambio seguro de correo ya está construido → evidencia para #53

`prepareEmailVerificationOtp` rechaza duplicados con `409` (`:38-42`), llama a `setPendingEmail` si el correo difiere (`:66-69`), y al confirmar `setEmailVerified` promueve el pendiente (`:113-116`). **El frontend no lo expone.** `M2-V19` sigue pendiente de formalizar.

### Nota técnica para Jeaninne

`confirmEmailVerification:74-81` usa `where: { userId, usedAt: undefined as any }`. **TypeORM ignora las propiedades `undefined`**, así que no filtra: trae todos los tokens históricos del usuario y descarta en memoria. Se arregla con `IsNull()`. Sin tarjeta — de una línea, que entre con #55.

---

## 8. Los 14 endpoints — tabla de referencia

La lista que entregó Miguel tiene **dos discrepancias con el código real**, verificadas en `auth.controller.ts` de `main`:

- **`GET /auth/email-verification/confirm/:token` no existe.** Sólo hay `POST email-verification/confirm`. Confirmar con el PM si se eliminó o nunca se implementó.
- **`POST /auth/logout-all` existe y no está en la lista.** Está implementado con guard JWT.

Rutas reales, con lo que ya se sabe de cada una:

| # | Ruta | Guard / Throttle | Tarjeta | Contexto ya levantado |
|---|---|---|---|---|
| 2 | `POST /auth/login` | `5/60s` | #22 | `M1-RN-ACC-031` deja intentos y bloqueo **pendientes de definición formal**. Brecha `M1-BC-005`: cuenta restringida con credenciales válidas — el backend la implementa pero el mensaje expone el motivo (issue #56). Frontend: copy y límite de reintentos biométricos **ya resueltos en `main`** (`d73d71d`) |
| 3 | `POST /auth/refresh` | — | #30 ✅ | **Revisado.** Dos hallazgos `prio:alta`: no valida el estado de la cuenta (#63) y la carrera de refresh concurrente mata todas las sesiones (#64). Política de sesión efectiva documentada en #30 → #43 |
| 4 | `POST /auth/logout` | — | #30 ✅ | **Revisado.** Sin guard JWT: revoca por el token del body — correcto. El frontend no lo llama en el logout suave con biometría |
| 5 | `POST /auth/logout-all` | JWT | #30 ✅ | **Revisado.** Bien implementado y **sin un solo consumidor en el frontend**. La UI que falta es la brecha `M2-V44` |
| 6 | `POST /auth/forgot-password` | `5/60s` | #28 ✅ | **Revisado.** No revela por mensaje pero **sí por tiempo** (#65) |
| 7 | `POST /auth/verify-reset-code` | `10/60s` | #28 ✅ | **Revisado.** Valida sin consumir y **el front sí lo usa** antes de `reset-password` (`useVerifyCodeForm.ts:109`). En modo `reset` el reenvío va por `forgot-password` |
| 8 | `POST /auth/reset-password` | **ninguno (#65)** | #28 ✅ | **Revisado.** Revoca todos los refresh tokens. **Sin throttle**, a diferencia de su gemelo de sólo lectura (#65), y **sin registro ni notificación** del evento (#66) |
| 9 | `PATCH /auth/biometric` | JWT | #29 ✅ | **Revisado.** `route-map.md` es el documento desactualizado, no `M1-RN-ACC-026`. La preferencia se activa por dos caminos y sólo uno avisa al backend (#67); desactivarla no está conectado. Tope de 3 intentos **sólo cliente** |
| 10 | `GET /auth/onboarding` | JWT | #31 ✅ | **Revisado.** Devuelve sólo el modelo viejo de checkpoints; las nueve columnas de puertas/suficiencia/diagnóstico existen y no se exponen |
| 11 | `PATCH /auth/onboarding/step` | JWT | #31 ✅ | **Revisado.** No cierra por ninguna de las dos condiciones: la del código es **inalcanzable** y la de `M1-DP-009` no está implementada (#68). Los checkpoints los declara el cliente |
| 12 | `POST /auth/email-verification/request` | JWT · `3/hora` | #26 ✅ | **Revisado.** Contiene el **cambio seguro de correo** completo, sin exponer (#53) |
| 13 | `POST /auth/email-verification/confirm` | JWT · `5/60s` | #26 ✅ | **Revisado.** `MAX_ATTEMPTS = 5` por token; al agotarlos lo invalida. `M1-RN-ACC-015` Conforme |
| 14 | `POST /auth/email-verification/resend` | JWT · `3/hora` | #26 ✅ | **Revisado.** Es **el mismo método** que `request` → reinicia `attempts` (#55) y el tope real es **6/hora**, no 3 |

### Baseline OTP de `AX-M1-001` — aplica a los endpoints 12–14

| Parámetro | Baseline | Backend | Frontend (`main`) | |
|---|---|---|---|---|
| Longitud | 6 dígitos | 6 | 6 | coincide |
| `verification_otp_ttl` | **10 min** | `EMAIL_VERIFICATION_EXPIRES_MINUTES` default **15** | no lo muestra | difiere |
| `verification_resend_cooldown` | **60 s** | throttle `3/hora` | `RESEND_COOLDOWN_SECONDS = 5 × 60` → **300 s** | **tres valores distintos** |
| `verification_max_attempts` | **5 acumulados** | 5 por token | — | difiere en el alcance |
| Reenvío no reinicia intentos | exigido | reinicia | — | contradice |

El cooldown es el caso más claro: baseline 60 s, contador visible 300 s, y el control que de verdad bloquea es un throttle de 3/hora que ninguno de los dos refleja. `M1-DP-010` dice que vigencia y temporizador son controles distintos, pero no autoriza tres números sin relación. Levantarlo como una sola divergencia sobre los tres frentes, no como tres hallazgos sueltos.

`main` ya corrige *cómo* se cuenta ese cooldown (reloj de pared, resincroniza al volver de background) pero **no cambió el valor** — sigue en 300 s.

---

## 9. Decisiones cerradas que aplican transversalmente

Las 13 `M1-DP-*` están **todas resueltas**. Las que tocan Auth:

- **`M1-DP-001`** — Registro con un único campo de contraseña; el mostrar/ocultar sustituye la confirmación.
- **`M1-DP-010`** — OTP: vigencia y temporizador de reenvío son **controles distintos**. El contador visible sólo habilita pedir código nuevo. Baseline en `AX-M1-001`.
- **`M1-DP-011`** — Sin acceso al correo: `soporte@walvy.cl`, sin recuperación automática en MVP. El contacto no acredita identidad. Al recuperar: renovar credenciales, invalidar sesiones, **registrar y notificar el evento**.
- **`M1-DP-009`** — El onboarding se cumple al poder mostrar el diagnóstico, no por checkpoints.

---

## 10. Lo que sigue abierto

De los 10 pendientes de §3.3 quedan **cinco** (detalle en #43 y #44):

1. Regla técnica de RUT y tratamiento de correo ya registrado
2. Política completa de contraseña — reutilización, expiración, contraseñas comunes
3. Credenciales incorrectas: bloqueo temporal y copy de seguridad — `M1-RN-ACC-031` lo declara pendiente
4. Enrolamiento y desactivación de biometría
5. Duración de sesión, refresh y revocación

Y una capa de contrato que **no existe en el código**: `M01-RGL-001` … `M01-RGL-015`, `M01-DOCSEC-003`, `MatrizAdmisionDS`, `MatrizCompletitudDS`, `MatrizIndicadoresDS`, `MatrizPresionesCTA`, `MatrizContinuidadM01`. Mapearla es parte de #44.

---

## 11. Cosas que no hay que volver a hacer

- **La base de datos no tiene datos.** No proponer migraciones de datos, backfill ni criterios sobre "cuentas ya creadas". Ya se descartó una migración SQL completa por esto.
- **No usar `#NN` en commits que van a walvy-org.** Sólo la regla de negocio.
- **No dar por hecho que algo falta sin leer el componente compartido.** Pasó con el toggle de contraseña.
- **Los scripts de creación de issues no son idempotentes.** Están en esta carpeta; correrlos de nuevo duplica todo.
- **Verificar el estado de la rama al empezar.** back-walvy quedó una vez en HEAD desacoplado y front-walvy tiene una rama local `walvy-main` que trackea `walvy/main`, no `origin/main`.
- **El baseline se mueve mientras revisamos.** El PR de walvy-org #61 se mergeó el mismo día en que se revisaban los dos primeros endpoints, y cambió el frontend bajo los pies del informe. Antes de escribir cualquier veredicto: `git fetch walvy` y anotar el SHA real, no el de la sesión anterior. Y revisar los PRs abiertos del repo, no sólo `main`.
