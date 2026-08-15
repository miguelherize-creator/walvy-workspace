# Plan de revisión — Módulo 1 v3.0 (doc ↔ backend ↔ frontend ↔ Figma)

**Fecha:** 2026-08-05
**Documento fuente:** [Walvy — Documentación Formal Consolidada Módulo 1 v3.0](https://docs.google.com/document/d/1gBJzAuobWVK2h2qdNxBuoranpgxdmlLR/edit) — estado *Borrador consolidado*
**Objetivo:** determinar, regla por regla, si lo que el documento declara está implementado en backend, en frontend y diseñado en Figma; y convertir cada divergencia en trabajo accionable.

---

## 1. Por qué este plan

El documento v3.0 declara **48 reglas de negocio** (30 de acceso `M1-RN-ACC-*`, 18 de onboarding `M1-RN-ONB-*`), **29 historias de usuario** y **37 casos de prueba**. Los casos de acceso figuran como *Passed*; los 20 de onboarding están **todos pendientes**. Además el propio documento deja **10 decisiones abiertas** en §3.3.

Ese documento nunca se contrastó contra el código. Un sondeo inicial ya muestra tres asimetrías estructurales:

| # | Asimetría observada | Evidencia |
|---|---|---|
| 1 | El documento modela el onboarding como **puertas G1–G5 + suficiencia + diagnóstico**; el backend lo modela como **checkpoints booleanos** | `back-walvy/src/auth/entities/onboarding-state.entity.ts` (`goals_set`, `import_attempted`, `min_doc_threshold_met`, `biometric_prompted`) |
| 2 | No existe en backend el vocabulario del diagnóstico: sin `dominant_pressure_code`, sin semáforo de onboarding, sin `rule_version`/`evaluated_at`. El único motor de severidad es el de deuda (S0–S4), que **RN-ONB-009 prohíbe reutilizar** | `back-walvy/src/debts/rules/debt-severity.rule.ts` |
| 3 | El **frontend va por delante** del backend en onboarding: ya existen pantallas de foco, carga, análisis y resultado | `front-walvy/expo/app/(auth)/onboarding-foco.tsx`, `onboarding-doc.tsx`, `onboarding-analyzing.tsx`, `onboarding-analysis.tsx` |

La revisión no es un trámite documental: es el insumo para decidir qué se corrige en el código y qué se corrige en el documento antes de firmarlo.

---

## 2. Método

Cada tarjeta cubre un bloque funcional y produce **filas de una matriz de conformidad**. Una fila por regla, con este veredicto cerrado:

| Veredicto | Significado |
|---|---|
| `Conforme` | Las cuatro fuentes dicen lo mismo |
| `Divergente` | Implementado, pero distinto de lo que declara el documento → genera issue de remediación |
| `No implementado` | El documento lo declara y no existe en código |
| `No aplica` | Regla puramente de UI sin contraparte en backend, o viceversa |
| `Bloqueado por decisión` | Depende de un pendiente de §3.3 sin resolver |

Cada veredicto exige **evidencia citable**: `archivo:línea`, endpoint, o `node-id` de Figma. Sin evidencia, la fila no se cierra.

**Regla de oro del plan:** una divergencia nunca se resuelve dentro de la tarjeta de revisión. Se registra, se clasifica (`corregir código` / `corregir documento` / `decisión de producto`) y se abre un issue hijo. La tarjeta de revisión sólo cierra cuando todas sus filas tienen veredicto.

---

## 3. Estructura del tablero

- **1 epic** (`RM1-00`) con la lista de las 26 tarjetas.
- **26 tarjetas** de actividad, todas asignadas a @miguelherize-creator.
- **Milestone:** `M1 — Revisión de conformidad v3.0`.
- **Project v2:** `Walvy — Revisión M1`, columnas `Todo → In Progress → In Review → Blocked → Done`.

### Etiquetas

`M1` · `revision-conformidad` · `area:{backend,frontend,figma,producto,qa,db}` · `bloque:{acceso,onboarding,transversal}` · `tipo:{epic,setup,revision,decision,informe}` · `prio:{alta,media,baja}`

---

## 4. Catálogo de tarjetas

| ID | Tarjeta | Bloque | Reglas cubiertas | Prio |
|----|---------|--------|------------------|------|
| RM1-01 | Inventario de fuentes y matriz base de conformidad | transversal | — (habilitador) | alta |
| RM1-02 | Pantalla de acceso y login | acceso | ACC-001..005 | alta |
| RM1-03 | Registro — contrato de datos y validación de RUT | acceso | ACC-006..008 | alta |
| RM1-04 | Política de contraseña | acceso | ACC-009 | media |
| RM1-05 | Términos y Condiciones / Política de Privacidad | acceso | ACC-010, 011 | alta |
| RM1-06 | Verificación de cuenta (OTP) | acceso | ACC-012..015 | alta |
| RM1-07 | Primer ingreso — completar u omitir | acceso | ACC-016..018 | media |
| RM1-08 | Recuperación de acceso | acceso | ACC-019..024 | alta |
| RM1-09 | Usuario guardado y biometría | acceso | ACC-025..027 | alta |
| RM1-10 | Persistencia de sesión y estado | acceso | ACC-028 | media |
| RM1-11 | Continuidad a Onboarding Welcome y modelo de estado | acceso/onboarding | ACC-029, 030 | alta |
| RM1-12 | Activación del onboarding y Foco del Mes | onboarding | ONB-001, 012 | media |
| RM1-13 | Carga documental y ruta preferente (Kread) | onboarding | ONB-002, 003 | alta |
| RM1-14 | Estados de procesamiento y umbrales de demora | onboarding | ONB-013 | media |
| RM1-15 | Documento no procesable y carga insuficiente | onboarding | ONB-006, 007 | alta |
| RM1-16 | Revisión de indicadores y trazabilidad del dato | onboarding | ONB-008, 015 | alta |
| RM1-17 | Suficiencia y modos de diagnóstico | onboarding | ONB-004, 005, 006 | alta |
| RM1-18 | Semáforo general del onboarding | onboarding | ONB-009, 010, 017 | alta |
| RM1-19 | Presión principal única y CTA dominante | onboarding | ONB-011, 012 | alta |
| RM1-20 | Retoma sin reinicio y cierre con valor | onboarding | ONB-014, 016 | media |
| RM1-21 | Versionamiento de evaluaciones | onboarding | ONB-018 | media |
| RM1-22 | Frontera M1 ↔ M2 — salida a Perfil Financiero | transversal | ONB-016 | media |
| RM1-23 | Decisión — pendientes de acceso y seguridad | transversal | §3.3 (6 ítems) | alta |
| RM1-24 | Decisión — pendientes de onboarding y reglas financieras | transversal | §3.3 (4 ítems) | alta |
| RM1-25 | QA — reconciliar trazabilidad §5 con evidencia real | transversal | CP-M1-* | media |
| RM1-26 | Informe consolidado y backlog de remediación | transversal | cierre | alta |

### Orden sugerido

`RM1-01` primero (habilita a todas). Luego el bloque de acceso (`02`–`11`) en paralelo con las dos tarjetas de decisión (`23`, `24`), porque varias reglas de acceso quedan `Bloqueado por decisión` hasta que §3.3 se cierre. El bloque de onboarding (`12`–`22`) depende de `24`. `25` y `26` cierran.

---

## 5. Cómo se publican las tarjetas

**Repositorio destino:** `KabeliDev/back-walvy` (decidido 2026-08-05). El grueso de los hallazgos es de backend y modelo de datos, y ahí ya vive `DB/migrations`. El tablero Projects v2 es de organización, así que puede mostrar issues de `front-walvy` cuando la remediación los genere.

`crear-issues.sh` es la fuente única de los cuerpos de los issues. No edites los issues a mano sin reflejar el cambio aquí.

```bash
# 1. Autenticación (una vez, requiere credenciales del usuario)
gh auth login --scopes "repo,project,read:org"

# 2. Ensayo — no escribe nada
DRY_RUN=1 ./crear-issues.sh

# 3. Publicación real
./crear-issues.sh

# 4. Opcional: además crea el Project v2 y agrega los 27 items
WITH_PROJECT=1 ./crear-issues.sh
```

> El script es idempotente en etiquetas y milestone, **no** en issues. Ejecutarlo dos veces crea 27 duplicados.

---

## 6. Estado

| Paso | Estado |
|---|---|
| Documento v3.0 leído y desglosado | Hecho |
| Catálogo de 26 tarjetas redactado | Hecho |
| Script de publicación | Hecho — sintaxis validada, dry-run correcto |
| `gh` CLI instalado y autenticado | Hecho — v2.97.0, cuenta `miguelherize-creator` |
| Repositorio destino | Hecho — `KabeliDev/back-walvy` |
| Issues creados en GitHub | **Hecho — 2026-08-05, issues #20 a #46** |
| Project v2 en `KabeliDev` | **Bloqueado** — la organización no permite a los miembros crear proyectos |
| Project v2 personal (demo) | **Hecho** — [users/miguelherize-creator/projects/1](https://github.com/users/miguelherize-creator/projects/1), privado |

### Issues publicados

Epic **[#20](https://github.com/KabeliDev/back-walvy/issues/20)**. Tarjetas `RM1-01`…`RM1-26` → issues **#21 a #46**, correlativos con el ID de la tarjeta (`RM1-NN` = issue `#20+NN`). Todos con milestone `M1 — Revisión de conformidad v3.0` y asignados a `miguelherize-creator`.

> **No vuelvas a ejecutar `crear-issues.sh` contra este repo.** El script no es idempotente en issues: una segunda corrida crearía 27 duplicados.

### El tablero

`crear-tablero.sh` construye el Projects v2 completo: columnas, campos propios, los 27 issues enganchados y sus valores poblados.

```bash
./crear-tablero.sh                    # bajo la cuenta personal (hecho)
OWNER=KabeliDev ./crear-tablero.sh    # bajo la organización (pendiente de permiso)
```

Un Project v2 **referencia** issues, no los copia. Por eso el tablero personal ya muestra los issues que viven en `KabeliDev/back-walvy`, y por eso correr el script contra la organización mañana no duplica ni migra nada: se crea un segundo tablero sobre los mismos issues y el personal se puede borrar.

| Elemento | Valor |
|---|---|
| Columnas (`Status`) | `Todo` · `In Progress` · `In Review` · `Blocked` · `Done` |
| Campos propios | `Bloque` (acceso/onboarding/transversal), `Prioridad` (alta/media/baja), `Reglas cubiertas` (texto) |
| Reparto por bloque | acceso 9 · onboarding 11 · transversal 7 |
| Reparto por prioridad | alta 18 · media 9 |

`Blocked` no es decorativa: el diccionario de veredictos de §2 tiene `Bloqueado por decisión`, y varias tarjetas de onboarding caen ahí hasta que `RM1-24` cierre los umbrales cuantitativos.

### Bloqueo en la organización

`gh project create --owner KabeliDev` devuelve:

```
GraphQL: miguelherize-creator does not have permission to create projects
on ownerId O_kgDOCGVLWA. (createProjectV2)
```

El token tiene el scope `project`; la restricción es de la organización — hoy `KabeliDev` no tiene ningún Projects v2. Dos salidas, y la primera es mejor porque es de una sola vez:

1. Un *owner* habilita **Settings → Member privileges → Allow members to create projects**. Después basta `OWNER=KabeliDev ./crear-tablero.sh`.
2. El *owner* crea el tablero él mismo y **además** da acceso `Write` a `miguelherize-creator` en **Project → Settings → Manage access**. Sin ese segundo paso el tablero nace inutilizable.
