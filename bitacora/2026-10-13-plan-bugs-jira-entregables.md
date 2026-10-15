# Plan de bugs Jira — proyecto BUG (Entregables_Walvy-MVP)

Fecha: 2026-10-13 · Base: `origin/qa` (back `5ce8be7`, front `0f56f9e`, ambos del 09-10)

## Alcance

- Proyecto Jira `BUG` (kabeli.atlassian.net). Numeración de módulos = la del cliente.
- Abiertos: 54 «Reportado (Walvy)» + BUG-11 «en curso». Además 4 en «En revisión Kabeli» (10, 16, 19, 52) y 2 en «En corrección» (45, 46).
- Se ignoran BUG-1 (plantilla) y BUG-14 (duplicado de BUG-13, pedir cierre).
- `WBUG` (Walvy_BUG - Equipo Desarrollo) es otro tablero: 23 abiertos, casi todos M07 (WBUG-56..68). Fuera de este plan.

## Flujo

- Rama desde `origin/qa`: `fix/bug-NN-slug` (o `fix/bug-NN-MM-slug` si es un cluster). PR → `qa` en KabeliDev.
- Commit con la regla del cliente que trae el ticket (`M1-V16`, `M5-V13`, `RW-M05-029`…), no el `BUG-NN`. El `BUG-NN` va en el cuerpo del PR.
- Jira: Reportado (Walvy) → «Por hacer (Kabeli)» (estado `en curso`) → En corrección (Kabeli) → En revisión Kabeli (listo para QA; el código puede estar en origin/main).
- Regla de negocio que cambia → su test en el mismo PR.

## Fase 0 — Ya parece resuelto en qa: verificar y devolver (1 día)

Verificado por código en `origin/qa`. Falta evidencia en build y pasar a re-revisión.

| Bug | Qué hay en qa | Falta |
|---|---|---|
| BUG-12 OTP 15 vs 10 min | `email-verification.service.ts:215` TTL 10 por defecto; plantilla usa `expiresMinutes` | Confirmar que `EMAIL_VERIFICATION_EXPIRES_MINUTES` no pisa a 15 en el env de qa. Los COMMENT de la migración baseline aún dicen 15 |
| BUG-59 importe partido | `ingresoAmount` 23 px + `adjustsFontSizeToFit`; `alertCard` `minHeight: 68` | Captura en dispositivo |
| BUG-63 tipografía (puntos 1–3) | Igual que BUG-59; `hubSubtitle` lineHeight 22 | Revisar puntos 4–6 (Foco, Actualizar contraseña, tab bar) |
| BUG-41 SEC-AND-003 logs | 0 `console.log` en el front | Prueba logcat 401/500 |
| BUG-47 SEC-AND-012 caché | `services/documentCache.ts` | Confirmar que los 3 pickers lo usan en éxito/error/cancel/logout |
| BUG-35 PD-CTRL-37 | `presented_at` persistido | Revisar que no se resuelva contra la versión activa si falta el ID |
| BUG-66 textos Presupuesto Vivo | Mismo título que WBUG-18, ya cerrado | Confirmar si es duplicado |

### Resultado de la verificación (2026-10-13)

Jira: Fase 0 → «En corrección (Kabeli)»; Fase 1 → «en curso» (columna «Por hacer (Kabeli)»); Fase 2 sigue en «Reportado (Walvy)». BUG-11 aparece «Bloqueado» (no lo moví yo).

| Bug | Veredicto |
|---|---|
| BUG-12 | ~~No resuelto, causa en infra~~ → **corregido:** infra `develop` ya tiene `'10'` desde el 14-09 (ver «Cierre de Fase 0»). Quedan COMMENT desactualizados («TTL 15 minutos») en la migración `1786000004000-BaselineIdentidadAcceso` |
| BUG-35 | Back completo (409 si falta el ID y hay más de una versión; `presented_at`, `channel`, `app_version`). **El front no enviaba la fecha** → corregido en `fix/bug-35-fecha-presentacion-legal` (front, `e0ce36e`, sin push) |
| BUG-41 | Resuelto: `utils/logger.ts` es el único `console`; en release no escribe y en dev sanea |
| BUG-47 | Resuelto: `services/documentCache.ts` borra la copia al subir, al fallar, al quitar el documento y al cerrar sesión. Solo `wrong_password` la conserva a propósito, y se limpia al hacer logout |
| BUG-59 | Resuelto: 23 px + `adjustsFontSizeToFit`; `minHeight: 68` |
| BUG-63 | Puntos 1–3 resueltos. Los 4–6 son ajustes condicionales que se deciden mirando el dispositivo |
| BUG-66 | Duplicado de WBUG-18 (creados juntos, IDs 26408/26409), cerrado por Sergio el 03-10 |

## Fase 1 — Sin código o solo documentación (respuesta a Walvy)

| Bug | Tipo de respuesta |
|---|---|
| BUG-73 M04-07 | Walvy adopta el runtime. Solo confirmar semántica |
| BUG-74 M04-08 | Informar regla y payload actual del KPI «Monto total de deudas» |
| BUG-75 M04-09 | Es Figma. Nada en código |
| BUG-76 M04-10 | Observación; se eleva solo con oráculo visual |
| BUG-100 OBS-M05-07 | Entregar IDs de las 2 subcategorías extra y del rótulo «Transferencias» |
| BUG-101 OBS-M05-09 | Documentar qué hace «Mantener categoría sugerida» y proponer unificar |
| BUG-102 GAP-UX-M05-01 | Propuesta UX, no bug. Estimar como feature |
| BUG-17 M01-TECH-001 | Documentar controles PRE-Kread, dedupe, CSV/XLSX soportados (alimenta Cluster A) |
| BUG-62 M02-14 | Abrir ticket de integración M05→M02 (Top recurrentes) |
| BUG-84 SEC-RBAC-001 | Decisión: implementar guard de permisos o declarar fuera de MVP |
| BUG-82 ARCH-002 | Documentar dueño y dirección Imports↔Health |
| BUG-36 ARCH-001 | Mejora baja; diferir |
| BUG-40 SEC-AND-002 | Depende del threat model; decisión, no fix |
| BUG-44 SEC-AND-006 | Gate de release contra mock |
| BUG-28 PD-CTRL-21/22 | Diseño compartido con infra (arquitecta) |
| BUG-3 TC-M01-002 | Preparar cuenta restringida para escenario B; corregir copy de Login (chico) |

## Fase 2 — Código, agrupado por causa raíz

### Cluster A · Taxonomía de error de ingesta (back + front) — prioridad alta
«No procesable / formato no soportado» se informa como «problema temporal».
BUG-18, BUG-87, BUG-92, BUG-98, BUG-94 (+ doc de BUG-17).
Un solo catálogo de formatos y un mapeo de error por documento compartido por M01/M02/M04/M05. BUG-94 (mismo Excel, distinto resultado según ruta) es el más profundo: reconciliar por job.

### Cluster B · Estado residual entre ingestas — prioridad alta
Una carga nueva arrastra documentos o movimientos de la anterior, o pierde los propios.
BUG-11 (en curso), BUG-68, BUG-91, BUG-96.

### Cluster C · M04 Ruta Despeje (Miguel)
- Alta: BUG-67 (CTA «Comenzar diagnóstico» de más), BUG-69 + BUG-70 (procesamiento en segundo plano: modal sobre otra pantalla y retorno automático), BUG-72 («Es la misma deuda» deja dos obligaciones sumables, back), BUG-71 (feedback de «Dejar pendiente»).
- UX: BUG-77, BUG-78.

### Cluster D · M05 Presupuesto Vivo (Sergio)
BUG-93 (estado vacío transitorio), BUG-97 (total viejo durante el recálculo), BUG-95 (lápiz para editar un movimiento clasificado), BUG-99 (jerarquía de avisos), BUG-90 (nitidez de iconos).

### Cluster E · M02 Perfil
BUG-85 (Mis Datos guarda sin Guardar), BUG-86 (render stale al entrar a Mi Perfil), BUG-57 (retomar onboarding desde Perfil Financiero), BUG-58 (precisión y regla financiera), BUG-61 (instrumentar tiempos antes de optimizar).

### Cluster F · Auth y sesión (M01)
BUG-79 (pegado de OTP llena 5 de 6), BUG-81 (biometría intermitente tras lockout), BUG-48 (postcondición de logout remoto), BUG-80 (primera carga de ilustración).

### Cluster G · Backend robustez
BUG-22 PAY-001 (recuperación idempotente del callback de Flow; ver la memoria de que Flow no firma), BUG-83 (harness y fixtures de evidencia vs esquema actual: `debts`, `financial_nature` NOT NULL, `password_hash`).

## Orden sugerido

1. Fase 0 completa y respuestas de Fase 1 que no piden código (descomprime el tablero rápido).
2. En paralelo: Cluster A + B (riesgo alto, cruzan módulos), Cluster C (Miguel), Cluster D (Sergio).
3. Después: E, F, G.

### Avance 2026-10-13 (tarde)

- BUG-35: PR https://github.com/KabeliDev/front-walvy/pull/291 → `qa`. Sigue «En corrección» hasta el merge.
- BUG-41, 47, 59 y 66 → «En revisión Kabeli», cada uno con un comentario de qué hay en qa y cómo revalidarlo.
- Siguen «En corrección»: BUG-12 (cambio de infra pendiente, Laura), BUG-35 (PR) y BUG-63 (puntos 4–6, revisión visual).

### Revalidación y pendientes (2026-10-13, noche)

- BUG-59 / BUG-63: el importe del ticket pasa. Con el texto del sistema al máximo, toda la app partía palabras → PR front#296 (`ScaledText`: hasta 1,5× sin pasar de 22pt; navbar sin escalar; regla ESLint). Evidencia en `evidencias/escala-texto/` y `evidencias/BUG-59/`. Falta Android.
- BUG-41: logs de un login real (iOS dev) sin secretos + 6/6 tests del logger. Falta logcat en el APK de release.
- BUG-47: caché `DocumentPicker` verificada al agregar, quitar y subir con error. Logout cubierto por código, no ejecutado.
- **Pendiente (mejora, sin ticket):** `ProfilePhotoModal` deja los recortes de la foto de perfil en `Library/Caches/ImageManipulator` (y `ImagePicker`), y no se limpian ni en el logout. Arreglo: vaciar también esas carpetas en `clearDocumentPickerCache` / el logout de `AuthProvider`. Mencionado en el comentario de BUG-47.

### Cierre de Fase 0 (2026-10-13)

- **Corrección BUG-12:** no dependía de infra pendiente. Laura ya había fijado el SSM en `'10'` el 14-09 (walvy-platform-infra PR #38, `develop`), desplegado a `dev`, que es el único ambiente provisionado. El `'15'` que vi estaba en la rama local vieja `feat/kread-v2-from-s3`. La rama `qa` de infra sigue en `'15'`, pero el workflow ya no la despliega. → «En revisión Kabeli» con los pasos de revalidación.
- BUG-35: front#291 mergeado en `qa` → «En revisión Kabeli».
- Quedan en «En corrección»: BUG-63 (PR front#296 + puntos 4–5 de revisión visual).

### BUG-12 vuelve a «En corrección» (2026-10-13, noche)

JM (07-10) pidió evidencia técnica sobre el ambiente desplegado: TTL efectivo de 10 min, uso único e invalidación tras reenvío. El código o el correo por sí solos no le alcanzan. Prueba local PASA 4/4 (`evidencias/BUG-12/`). **Falta correr `prueba-ttl-otp.mjs` contra `api-qa.sonark.tech`** con una cuenta nueva sin verificar; eso lo hace Miguel. Después se adjunta el `.log` y el script, y vuelve a revisión. El comentario 34778 se editó con este estado.

### 2026-10-14 · Cambio de plan y épica Seguridad

Ahora se trabaja épica por épica (Seguridad → M04 → M01 → M02). Estado y pendientes en KabeliDev/back-walvy#374.
- PR back#375 (BUG-83, 44, 46) y front#297 (BUG-48, 46) abiertos y comentados en Jira. BUG-40: propuesta en Jira, Miguel la lleva al PMO.
- Siguiente: BUG-22.
- E2e del back: Postgres 16 efímero (el directorio del cluster está en el scratchpad de la sesión, que puede no persistir). Para recrearlo:
  `initdb -D <dir> -U postgres --auth=trust --locale=C` → `pg_ctl -D <dir> -o "-k /tmp/claude-501/pge2e -p 55461 -c listen_addresses=localhost" start` → `createdb -h localhost -p 55461 -U postgres walvy_e2e` → `pnpm run migration:run`, con PATH en postgresql@16 y LC_ALL=C.
