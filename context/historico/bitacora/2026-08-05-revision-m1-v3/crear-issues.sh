#!/usr/bin/env bash
#
# Publica en GitHub el backlog de revisión de conformidad del Módulo 1 v3.0.
#
# Crea: etiquetas, milestone, 1 epic y 26 tarjetas de actividad, todas asignadas
# a $ASSIGNEE. Opcionalmente crea el Project v2 y agrega los issues al tablero.
#
# Requisitos
#   brew install gh
#   gh auth login --scopes "repo,project,read:org"
#
# Uso
#   DRY_RUN=1 ./crear-issues.sh                 # imprime lo que haría, no escribe nada
#   REPO=KabeliDev/back-walvy ./crear-issues.sh # publica
#   WITH_PROJECT=1 ./crear-issues.sh            # además crea el Project v2 y agrega los items
#
# El script es idempotente en etiquetas y milestone, pero NO en issues:
# ejecutarlo dos veces crea 27 issues duplicados. Verifica con DRY_RUN primero.

set -euo pipefail

REPO="${REPO:-KabeliDev/back-walvy}"
ORG="${ORG:-KabeliDev}"
ASSIGNEE="${ASSIGNEE:-miguelherize-creator}"
MILESTONE="${MILESTONE:-M1 — Revisión de conformidad v3.0}"
PROJECT_TITLE="${PROJECT_TITLE:-Walvy — Revisión M1}"
DOC_URL="https://docs.google.com/document/d/1gBJzAuobWVK2h2qdNxBuoranpgxdmlLR/edit"
DRY_RUN="${DRY_RUN:-0}"
WITH_PROJECT="${WITH_PROJECT:-0}"

EPIC_NUMBER=""
CREATED=()

say() { printf '\033[1;34m▸\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }

require_gh() {
  command -v gh >/dev/null 2>&1 || {
    warn "gh no está instalado. brew install gh && gh auth login --scopes 'repo,project,read:org'"
    exit 1
  }
  gh auth status >/dev/null 2>&1 || { warn "gh no está autenticado."; exit 1; }
}

ensure_label() {
  local name="$1" color="$2" desc="$3"
  [[ "$DRY_RUN" == "1" ]] && { echo "  label: $name"; return; }
  gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" 2>/dev/null ||
    gh label edit "$name" --repo "$REPO" --color "$color" --description "$desc" >/dev/null
}

ensure_milestone() {
  [[ "$DRY_RUN" == "1" ]] && { echo "  milestone: $MILESTONE"; return; }
  gh api "repos/$REPO/milestones" --jq '.[].title' | grep -qxF "$MILESTONE" && return 0
  gh api "repos/$REPO/milestones" -f title="$MILESTONE" \
    -f description="Contraste regla por regla del documento M1 v3.0 contra backend, frontend y Figma." \
    >/dev/null
}

# card <id> <título> <labels-csv> ; cuerpo por stdin
card() {
  local id="$1" title="$2" labels="$3" body
  body="$(cat)"
  body="${body//__EPIC__/${EPIC_NUMBER:-RM1-00}}"
  body="${body//__DOC__/$DOC_URL}"

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '\n\033[1;32m── %s ── %s\033[0m\n  labels: %s\n' "$id" "$title" "$labels"
    return
  fi

  local url
  url="$(printf '%s' "$body" | gh issue create \
    --repo "$REPO" \
    --title "$id · $title" \
    --label "$labels" \
    --assignee "$ASSIGNEE" \
    --milestone "$MILESTONE" \
    --body-file -)"
  say "$id → $url"
  CREATED+=("$url")
}

# ─────────────────────────────────────────────────────────────────────────────
# Etiquetas
# ─────────────────────────────────────────────────────────────────────────────
setup_labels() {
  say "Etiquetas"
  ensure_label "M1"                     "1D76DB" "Módulo 1 — acceso, registro, onboarding y diagnóstico inicial"
  ensure_label "revision-conformidad"   "5319E7" "Contraste documento ↔ implementación"
  ensure_label "area:backend"           "0E8A16" "back-walvy"
  ensure_label "area:frontend"          "0E8A16" "front-walvy"
  ensure_label "area:figma"             "0E8A16" "Diseño"
  ensure_label "area:producto"          "0E8A16" "Decisión de producto"
  ensure_label "area:qa"                "0E8A16" "QA y evidencias"
  ensure_label "area:db"                "0E8A16" "Modelo de datos y migraciones"
  ensure_label "bloque:acceso"          "FBCA04" "Acceso, registro, recuperación, primer ingreso"
  ensure_label "bloque:onboarding"      "FBCA04" "Onboarding y diagnóstico inicial"
  ensure_label "bloque:transversal"     "FBCA04" "Transversal al módulo"
  ensure_label "tipo:epic"              "B60205" "Epic"
  ensure_label "tipo:setup"             "C5DEF5" "Habilitador"
  ensure_label "tipo:revision"          "C5DEF5" "Actividad de revisión"
  ensure_label "tipo:decision"          "D93F0B" "Requiere decisión formal"
  ensure_label "tipo:informe"           "C5DEF5" "Entregable documental"
  ensure_label "prio:alta"              "B60205" ""
  ensure_label "prio:media"             "FBCA04" ""
  ensure_label "prio:baja"              "0E8A16" ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Epic
# ─────────────────────────────────────────────────────────────────────────────
create_epic() {
  say "Epic"
  local body
  body="$(cat <<'EOF'
> **Documento fuente:** [Walvy — Documentación Formal Consolidada Módulo 1 v3.0](__DOC__) — estado *Borrador consolidado para revisión y entrega formal*.

## Objetivo

Determinar, regla por regla, si lo que el documento M1 v3.0 declara está implementado en **backend**, en **frontend** y diseñado en **Figma**; y convertir cada divergencia en trabajo accionable antes de que el documento se firme.

## Alcance

- **48 reglas de negocio** — 30 de acceso (`M1-RN-ACC-001..030`, §3.1) y 18 de onboarding (`M1-RN-ONB-001..018`, §3.2).
- **29 historias de usuario** con sus criterios de aceptación (§2).
- **10 decisiones abiertas** declaradas por el propio documento (§3.3).
- **37 casos de prueba** y su trazabilidad (§5).

## Asimetrías ya detectadas en el sondeo inicial

Estas tres no son hipótesis, están verificadas en el código. Definen buena parte del trabajo:

1. **Modelos de onboarding incompatibles.** El documento modela puertas `G1–G5` + suficiencia + diagnóstico. El backend modela checkpoints booleanos: `user_onboarding_state` tiene `financial_profile_completed`, `goals_set`, `import_attempted`, `biometric_prompted`, `min_doc_threshold_met`. No son el mismo modelo ni se mapean uno a uno.
   → `back-walvy/src/auth/entities/onboarding-state.entity.ts`

2. **El vocabulario del diagnóstico no existe en backend.** Sin `dominant_pressure_code` (RN-ONB-011), sin semáforo de onboarding (RN-ONB-009), sin `rule_version`/`evaluated_at` (RN-ONB-018). El único motor de severidad es el de deuda S0–S4 — que **RN-ONB-009 prohíbe explícitamente reutilizar**.
   → `back-walvy/src/debts/rules/debt-severity.rule.ts`

3. **El frontend va por delante del backend.** Ya existen `onboarding-foco`, `onboarding-doc`, `onboarding-analyzing`, `onboarding-analysis`, `onboarding-first-ready`. Hay que establecer contra qué contrato están construidas.
   → `front-walvy/expo/app/(auth)/`

## Método

Cada tarjeta produce filas de una matriz de conformidad. Una fila por regla, veredicto cerrado:

| Veredicto | Significado |
|---|---|
| `Conforme` | Las cuatro fuentes dicen lo mismo |
| `Divergente` | Implementado, pero distinto de lo declarado → issue de remediación |
| `No implementado` | Declarado en el documento, ausente en código |
| `No aplica` | Regla de UI pura sin contraparte en backend, o viceversa |
| `Bloqueado por decisión` | Depende de un pendiente de §3.3 |

Todo veredicto exige evidencia citable: `archivo:línea`, endpoint, o `node-id` de Figma. Sin evidencia, la fila no cierra.

**Una divergencia nunca se arregla dentro de la tarjeta de revisión.** Se registra, se clasifica (`corregir código` / `corregir documento` / `decisión de producto`) y se abre un issue hijo.

## Tarjetas

- [ ] RM1-01 · Inventario de fuentes y matriz base de conformidad
- [ ] RM1-02 · Pantalla de acceso y login
- [ ] RM1-03 · Registro — contrato de datos y validación de RUT
- [ ] RM1-04 · Política de contraseña
- [ ] RM1-05 · Términos y Condiciones / Política de Privacidad
- [ ] RM1-06 · Verificación de cuenta (OTP)
- [ ] RM1-07 · Primer ingreso — completar u omitir
- [ ] RM1-08 · Recuperación de acceso
- [ ] RM1-09 · Usuario guardado y biometría
- [ ] RM1-10 · Persistencia de sesión y estado
- [ ] RM1-11 · Continuidad a Onboarding Welcome y modelo de estado
- [ ] RM1-12 · Activación del onboarding y Foco del Mes
- [ ] RM1-13 · Carga documental y ruta preferente (Kread)
- [ ] RM1-14 · Estados de procesamiento y umbrales de demora
- [ ] RM1-15 · Documento no procesable y carga insuficiente
- [ ] RM1-16 · Revisión de indicadores y trazabilidad del dato
- [ ] RM1-17 · Suficiencia y modos de diagnóstico
- [ ] RM1-18 · Semáforo general del onboarding
- [ ] RM1-19 · Presión principal única y CTA dominante
- [ ] RM1-20 · Retoma sin reinicio y cierre con valor
- [ ] RM1-21 · Versionamiento de evaluaciones
- [ ] RM1-22 · Frontera M1 ↔ M2 — salida a Perfil Financiero
- [ ] RM1-23 · Decisión — pendientes de acceso y seguridad
- [ ] RM1-24 · Decisión — pendientes de onboarding y reglas financieras
- [ ] RM1-25 · QA — reconciliar trazabilidad §5 con evidencia real
- [ ] RM1-26 · Informe consolidado y backlog de remediación

## Definición de terminado del epic

- [ ] Las 48 reglas tienen veredicto con evidencia.
- [ ] Los 10 pendientes de §3.3 están resueltos o formalmente clasificados como dependencia, backlog o solicitud de cambio.
- [ ] Cada divergencia tiene un issue de remediación abierto y clasificado.
- [ ] Existe un informe consolidado y una adenda al documento v3.0 con las correcciones que le corresponden.
EOF
)"
  body="${body//__DOC__/$DOC_URL}"

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '\n\033[1;32m── RM1-00 (EPIC) ── Revisión de conformidad M1 v3.0\033[0m\n'
    return
  fi

  local url
  url="$(printf '%s' "$body" | gh issue create \
    --repo "$REPO" \
    --title "RM1-00 · [EPIC] Revisión de conformidad Módulo 1 v3.0 — doc ↔ backend ↔ frontend ↔ Figma" \
    --label "M1,revision-conformidad,bloque:transversal,tipo:epic,prio:alta" \
    --assignee "$ASSIGNEE" \
    --milestone "$MILESTONE" \
    --body-file -)"
  EPIC_NUMBER="#${url##*/}"
  say "RM1-00 → $url"
  CREATED+=("$url")
}

# ─────────────────────────────────────────────────────────────────────────────
# Tarjetas
# ─────────────────────────────────────────────────────────────────────────────
create_cards() {
say "Tarjetas"

card RM1-01 "Inventario de fuentes y matriz base de conformidad" \
  "M1,revision-conformidad,bloque:transversal,tipo:setup,area:qa,prio:alta" <<'EOF'
> Epic __EPIC__ · Habilitador de todas las demás tarjetas · [Doc M1 v3.0](__DOC__)

## Objetivo

Congelar las cuatro fuentes que se van a contrastar y dejar la matriz de conformidad creada y vacía, con las 48 reglas ya cargadas. Sin esto, cada tarjeta posterior compara contra un blanco móvil.

## Actividades

- [ ] Exportar el documento v3.0 a `workspace/walvy-workspace/context/modulo01-identidad-autenticacion/contexto/` y anotar su fecha de descarga. El documento vive en Drive y puede cambiar bajo nuestros pies.
- [ ] Fijar el commit SHA de `back-walvy` y de `front-walvy` contra los que se revisa. Anotarlos en la cabecera de la matriz.
- [ ] Listar los frames de Figma de M1 con su `node-id`, agrupados por bloque funcional (A–S del §1.1). Marcar los bloques sin diseño.
- [ ] Crear `matriz-conformidad-m1.md` con una fila por regla: `ID | Regla (resumen) | Doc § | Backend | Frontend | Figma | Veredicto | Evidencia | Clasificación`.
- [ ] Precargar las 48 filas (30 ACC + 18 ONB) con veredicto `Sin revisar`.
- [ ] Documentar el diccionario de veredictos y la regla de evidencia citable.

## Criterios de aceptación

- [ ] La matriz existe, versionada, con 48 filas y cabecera que identifica las cuatro fuentes por identificador inmutable (SHA, `node-id`, fecha de export).
- [ ] Cualquier persona del equipo puede tomar una tarjeta y saber exactamente contra qué versión compara.
- [ ] Los bloques funcionales sin frame de Figma están explícitamente listados como tales.

## Entregable

`workspace/walvy-workspace/context/modulo01-identidad-autenticacion/contexto/matriz-conformidad-m1.md`
EOF

card RM1-02 "Pantalla de acceso y login" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,area:figma,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloques A, B, C · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-001` a `M1-RN-ACC-005` | `M1-HU-001` a `M1-HU-004` | `CP-M1-ACC-001` a `CP-M1-ACC-004` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | §3.1 RN-ACC-001..005; §2.1 HU-001..004 |
| Backend | `POST /auth/login` — `src/auth/auth.controller.ts:90`, `src/auth/dto/login.dto.ts`, throttle `5/60s` |
| Frontend | `expo/app/(auth)/login.tsx`, `expo/app/index.tsx` (splash decide la ruta), `LoginScreen`, `useLoginForm` |
| Figma | _pendiente: pegar `node-id` de Login 01/02_ |

## Actividades

- [ ] Verificar RN-ACC-001/003/005 contra el frame de Figma y la pantalla real: logo, bienvenida, correo, contraseña, control mostrar/ocultar, `Entrar`, y los links `Crear mi cuenta` y `¿Olvidaste tu contraseña?`.
- [ ] RN-ACC-002 (botón deshabilitado) es de frontend puro → veredicto contra `login.tsx`, `No aplica` en backend.
- [ ] RN-ACC-004: confirmar que un login válido efectivamente aterriza en Home y no en una pantalla intermedia. El `route-map.md` describe un splash con tres ramas — contrastar con lo que dice el documento.
- [ ] Registrar como **gap del documento** el manejo de credenciales incorrectas: el documento lo lista en §3.3 como pendiente, pero el backend ya tiene throttle de 5 intentos/minuto. Hay una decisión tomada en código que el documento no recoge → alimenta RM1-23.

## Criterios de aceptación

- [ ] Las 5 reglas del alcance tienen veredicto con evidencia citable.
- [ ] Toda divergencia queda como issue hijo clasificado.
EOF

card RM1-03 "Registro — contrato de datos y validación de RUT" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloque D · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-006`, `007`, `008` | `M1-HU-005` | `CP-M1-ACC-005` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | §3.1 RN-ACC-006 (correo + confirmación + RUT + contraseña), RN-ACC-007 (correos coinciden), RN-ACC-008 (RUT válido, *"regla completa debe confirmarse técnicamente"*) |
| Backend | `src/auth/dto/register.dto.ts`, `POST /auth/register` |
| Frontend | `expo/app/(auth)/register.tsx`, `rut.utils.ts` |
| Figma | _pendiente: `node-id` del formulario de registro_ |

## Hallazgos previos a verificar

Tres divergencias aparentes, detectadas leyendo `register.dto.ts`. Confirmar y clasificar cada una:

1. **No existe confirmación de correo en el contrato.** RN-ACC-006 la exige; el DTO tiene `email`, `documentNumber`, `password`, `acceptTerms`, `acceptPrivacy` y nada más. ¿Es validación sólo de frontend por diseño, o falta en el contrato?
2. **`documentNumber` vs `rut`.** El DTO usa `documentNumber` con `@MaxLength(50)` y **ningún** patrón de RUT. Pero `context/conventions.md` documenta el DTO con un campo `rut` y `@Matches(/^\d{7,8}-[\dkK]$/)`. Convención y código no coinciden; el documento habla de RUT. Tres nombres para el mismo dato.
3. **Dígito verificador.** Ni el DTO ni la convención validan módulo 11 — sólo forma. Determinar dónde debe vivir esa validación y si el frontend la hace.

## Actividades

- [ ] Confirmar los tres puntos anteriores contra el código actual y anotar `archivo:línea`.
- [ ] Verificar el tratamiento de correo ya registrado: el controlador documenta `409`, pero §3.3 lo declara pendiente. Otra decisión tomada en código y ausente del documento → alimenta RM1-23.
- [ ] Decidir y dejar escrito el nombre canónico del campo (`rut` o `documentNumber`) y propagarlo a documento, convención, backend y frontend.

## Criterios de aceptación

- [ ] Las 3 reglas del alcance tienen veredicto con evidencia.
- [ ] Existe un issue de remediación por cada uno de los tres hallazgos confirmados.
- [ ] El nombre canónico del identificador queda decidido y registrado en `conventions.md`.
EOF

card RM1-04 "Política de contraseña" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,area:figma,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloque D · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Pendiente relacionado |
|---|---|---|
| `M1-RN-ACC-009` | `M1-HU-005` CA2, `M1-HU-012` CA1 | §3.3 — *"política completa de complejidad, reutilización y expiración"* |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ACC-009: *"al menos ocho caracteres, una mayúscula y un número"*, marcada como **evidencia visual** — o sea, inferida de un pantallazo, no especificada |
| Backend | `register.dto.ts`: `@MinLength(8)` + `@Matches(/^(?=.*[A-Z])(?=.*\d)/)`; `reset-password.dto.ts`; `users/dto/change-password.dto.ts` |
| Frontend | Copy de requisitos en `register.tsx` y `reset-password.tsx` |
| Figma | _pendiente: `node-id` del campo contraseña con sus helper texts_ |

## Actividades

- [ ] Verificar que las **tres** rutas de contraseña (registro, reset, cambio) apliquen exactamente la misma regla. Divergencias entre ellas son el fallo típico aquí.
- [ ] Contrastar el copy literal de requisitos: documento, Figma y frontend deben decir lo mismo, palabra por palabra. Un texto que promete algo que el backend no valida es un defecto.
- [ ] Levantar a RM1-23 lo que §3.3 deja abierto: reutilización, expiración, longitud máxima, y si se rechazan contraseñas comunes.

## Criterios de aceptación

- [ ] La regla efectiva está documentada una sola vez, con evidencia de las tres rutas backend.
- [ ] El copy visible coincide con la validación real en las tres superficies.
EOF

card RM1-05 "Términos y Condiciones / Política de Privacidad" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,area:producto,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloque D · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-010`, `M1-RN-ACC-011` | `M1-HU-006` | `CP-M1-ACC-006` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ACC-010 (aceptación condiciona la creación), RN-ACC-011 (textos disponibles vía links) |
| Backend | `register.dto.ts`: `acceptTerms` y `acceptPrivacy` son `@IsBoolean()` |
| Frontend | Checkboxes y links legales en `register.tsx` |
| Figma | _pendiente: `node-id` del bloque legal y del modal de T&C_ |

## Hallazgo previo a verificar

`@IsBoolean()` acepta `false` como valor válido. Si el `AuthService` no rechaza explícitamente `acceptTerms: false`, **se puede crear una cuenta sin aceptar los términos llamando la API directamente**, aunque el frontend lo impida. RN-ACC-010 dice que la aceptación condiciona la creación. Verificar `src/auth/auth.service.ts` y, si el rechazo no existe, es un defecto de cumplimiento legal, no cosmético.

## Actividades

- [ ] Verificar el rechazo efectivo de `false` en el servicio, con evidencia.
- [ ] Confirmar que los links legales resuelven a documentos reales y versionados.
- [ ] **Pregunta a producto/legal, fuera del alcance del documento:** ¿se persiste la aceptación con fecha y versión del texto legal aceptado? El documento no lo pide y el modelo actual no parece guardarlo. Sin eso no hay forma de probar qué aceptó un usuario y cuándo. Si se confirma la ausencia, abrir issue propio.

## Criterios de aceptación

- [ ] Las 2 reglas tienen veredicto con evidencia.
- [ ] La pregunta de persistencia de la aceptación tiene respuesta formal de producto, registrada.
EOF

card RM1-06 "Verificación de cuenta (OTP)" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloque E · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-012` a `M1-RN-ACC-015` | `M1-HU-007` | `CP-M1-ACC-007` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ACC-012..015 + §3.3 *"vigencia, longitud y número máximo de reintentos del código: pendiente"* |
| Backend | `POST /auth/email-verification/{request,confirm,resend}` — `auth.controller.ts:141-193`, `src/auth/services/email-verification.service.ts`, `email-verification-token.entity.ts` |
| Frontend | `expo/app/(auth)/verify-code.tsx`, `expo/app/confirm-account.tsx`, `expo/app/verify.tsx` |
| Figma | _pendiente: `node-id` de la pantalla de código_ |

## Inversión de la carga aquí

Este es el caso más claro del módulo: **el documento declara pendiente algo que el backend ya decidió e implementó**. El controlador documenta código de 6 dígitos, máximo 5 intentos antes de invalidar, y máximo 3 reenvíos por hora. La tarjeta no es "definir la política" sino "verificar la política implementada y subirla al documento, o corregirla si producto no está de acuerdo".

## Actividades

- [ ] Extraer del código los parámetros reales: longitud, vigencia (TTL de `email-verification-token`), intentos máximos, ventana de reenvío. Anotar `archivo:línea` de cada uno.
- [ ] Verificar RN-ACC-013 (campos vacíos al iniciar) contra el frontend.
- [ ] Verificar RN-ACC-015: un código incorrecto no confirma la cuenta **y** el mensaje al usuario no filtra si el correo existe.
- [ ] Aclarar la duplicidad de superficies del frontend: hay `verify-code.tsx`, `confirm-account.tsx` y `verify.tsx`. Determinar cuál está viva y si las otras son residuo.
- [ ] Redactar el texto de adenda al documento con la política real → insumo de RM1-23.

## Criterios de aceptación

- [ ] Las 4 reglas tienen veredicto con evidencia.
- [ ] Los parámetros reales de OTP están documentados con su origen en código.
- [ ] Está resuelto qué pantalla de verificación es la vigente.
EOF

card RM1-07 "Primer ingreso — completar u omitir" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloque F · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-016` a `M1-RN-ACC-018` | `M1-HU-008`, `M1-HU-009` | `CP-M1-ACC-008`, `CP-M1-ACC-009` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ACC-016 (alternativas Completar / Omitir), 017 (nombre + apellido + alias habilitan Guardar), 018 (continuidad a Onboarding Welcome) |
| Backend | `src/users/dto/update-display-name.dto.ts`, `update-profile.dto.ts`, `src/users/users.controller.ts` |
| Frontend | `expo/app/(auth)/choose-alias.tsx`; `route-map.md` describe la rama `fresh` → sin `username` → `/(auth)/choose-alias` |
| Figma | _pendiente: `node-id` de primer ingreso_ |

## Punto de atención

El documento habla de **nombre, apellido y alias** como tres datos. El `route-map.md` decide la ruta sólo por ausencia de `username`. Verificar si el modelo real es `fullName` + `username` (dos campos) contra los tres del documento, y si "alias" y "username" son el mismo concepto con dos nombres.

## Actividades

- [ ] Mapear los campos del documento a los del modelo real y anotar la correspondencia.
- [ ] Verificar RN-ACC-016: que `Omitir y continuar` exista y no borre el estado de activación ya alcanzado (HU-009 CA3).
- [ ] Verificar que ambas ramas —completar y omitir— aterricen donde el documento dice.

## Criterios de aceptación

- [ ] Las 3 reglas tienen veredicto con evidencia.
- [ ] La correspondencia nombre/apellido/alias ↔ modelo real está escrita.
EOF

card RM1-08 "Recuperación de acceso" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloque G · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-019` a `M1-RN-ACC-024` | `M1-HU-010` a `M1-HU-012` | `CP-M1-ACC-010` a `CP-M1-ACC-012` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ACC-019..024 |
| Backend | `POST /auth/forgot-password` (throttle 5/60s), `POST /auth/verify-reset-code` (10/60s, valida sin consumir), `POST /auth/reset-password` — `auth.controller.ts:117-139`, `src/auth/services/password-management.service.ts`, `password-reset-token.entity.ts` |
| Frontend | `expo/app/(auth)/forgot-password.tsx`, `reset-password.tsx` |
| Figma | _pendiente: `node-id` del flujo de recuperación_ |

## Actividades

- [ ] Verificar el flujo completo de las seis reglas contra los tres endpoints.
- [ ] RN-ACC-021 pide validar el código **antes** de dejar crear la contraseña. El backend tiene `verify-reset-code` justamente para eso: confirmar que el frontend lo usa y no salta directo a `reset-password`.
- [ ] RN-ACC-022/023 (Guardar deshabilitado, error si no coinciden) son de frontend → veredicto ahí; verificar además que el backend valide la política de contraseña en el reset igual que en el registro (cruza con RM1-04).
- [ ] Verificar que `forgot-password` no revele si un correo está registrado.
- [ ] Anotar TTL e intentos del token de reset, que §3.3 no cierra.

## Criterios de aceptación

- [ ] Las 6 reglas tienen veredicto con evidencia.
- [ ] Está verificado que el frontend usa `verify-reset-code` en el paso intermedio.
EOF

card RM1-09 "Usuario guardado y biometría" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloques H, I · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-025` a `M1-RN-ACC-027` | `M1-HU-013` a `M1-HU-015` | `CP-M1-ACC-013` a `CP-M1-ACC-015` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ACC-025 (usuario guardado, cambiar usuario o ingresar con clave), 026 (biometría exitosa → Home), 027 (3 fallos → credenciales) |
| Backend | `PATCH /auth/biometric` — `auth.controller.ts:195`, `src/auth/entities/biometric-preferences.entity.ts`, `src/auth/dto/update-biometric.dto.ts` |
| Frontend | `expo/app/(auth)/biometric-setup.tsx`, modo `savedUser` de `login.tsx` |
| Figma | _pendiente: `node-id` de usuario guardado y biometría_ |

## Divergencia aparente a verificar

`route-map.md` documenta que en la rama `loginSource = 'restored'` la app fuerza **re-autenticación obligatoria con contraseña** (*"app fintech"*), mostrando `¡Hola nombre!` + sólo contraseña. RN-ACC-026 dice que una validación biométrica exitosa da acceso al Home. Si la re-auth por contraseña es obligatoria, la biometría no cumple la función que el documento describe — o cumple sólo en otro punto del flujo. Determinar cuál de los dos está desactualizado.

## Actividades

- [ ] Resolver la divergencia anterior con evidencia de ambos lados.
- [ ] RN-ACC-027 (3 intentos) es de dispositivo/frontend: verificar dónde se cuenta y que el fallback no deje al usuario encerrado.
- [ ] Verificar el almacenamiento del usuario guardado. La memoria del proyecto registra un fix de seguridad de `secureStorage` — confirmar que está aplicado en la rama revisada.
- [ ] Levantar a RM1-23 el pendiente de §3.3: enrolamiento y desactivación de biometría.

## Criterios de aceptación

- [ ] Las 3 reglas tienen veredicto con evidencia.
- [ ] La divergencia re-auth obligatoria ↔ RN-ACC-026 está resuelta, con decisión de qué fuente se corrige.
- [ ] Está verificado el uso de almacenamiento seguro para el usuario guardado.
EOF

card RM1-10 "Persistencia de sesión y estado" \
  "M1,revision-conformidad,bloque:acceso,tipo:revision,area:backend,area:frontend,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §3.1 · Bloque J · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-028` | `M1-HU-016` | `CP-M1-ACC-016` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ACC-028 (minimizar y retomar no reinicia el ingreso) + §3.3 *"duración de sesión, refresh token, cierre de sesión y revocación: pendiente"* |
| Backend | `POST /auth/refresh`, `/logout`, `/logout-all` — `auth.controller.ts:97-115`; `src/auth/entities/refresh-token.entity.ts`; `expiresIn: '15m'` en el ejemplo de Swagger |
| Frontend | `AuthProvider`, restauración de sesión vía `GET /users/me` según `route-map.md` |

## Actividades

- [ ] Verificar RN-ACC-028 en Android e iOS: minimizar durante el ingreso y retomar sin perder datos ya escritos.
- [ ] Extraer del código los parámetros reales de sesión: TTL del access token, TTL y rotación del refresh token, revocación en `logout-all`. Nuevamente, §3.3 los declara pendientes pero el código ya decidió.
- [ ] Verificar que la migración `030` de índices únicos sobre `refresh_tokens.token_hash` esté alineada con lo que hace el servicio.
- [ ] Alimentar RM1-23 con la política de sesión efectiva.

## Criterios de aceptación

- [ ] La regla tiene veredicto con evidencia en ambas plataformas.
- [ ] La política de sesión real está documentada con origen en código.
EOF

card RM1-11 "Continuidad a Onboarding Welcome y modelo de estado" \
  "M1,revision-conformidad,bloque:acceso,bloque:onboarding,tipo:revision,area:backend,area:db,area:frontend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.1 y §3.2 · Bloque K · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ACC-029`, `M1-RN-ACC-030` | `M1-HU-017` | `CP-M1-ACC-017`, `CP-M1-ONB-016` |

## Esta es la tarjeta bisagra del epic

Aquí se decide si el modelo de estado del onboarding sirve para lo que el documento pide. **Ya se verificó que no coinciden:**

| Documento | Backend (`user_onboarding_state`) |
|---|---|
| Puertas `G1`–`G5` (CP-M1-ONB-016) | `onboarding_status`, `current_step` (varchar libre) |
| *"Última puerta completada"* (RN-ONB-014) | `last_checkpoint_at` (timestamp, no puerta) |
| *"Siguiente mejor acción"* (RN-ONB-014) | `resume_surface` + `resume_context` (jsonb) |
| Suficiencia / diagnóstico / semáforo | **no existe** |
| — | `financial_profile_completed`, `goals_set`, `import_attempted`, `biometric_prompted`, `min_doc_threshold_met` |

El backend avanza a `completed` cuando *todos los checkpoints están en `true`* (documentado en `auth.controller.ts:219-227`). El documento dice que el onboarding se cumple **al mostrar diagnóstico inicial y próxima acción** (RN-ONB-016). Son dos condiciones de cierre distintas.

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Backend | `GET /auth/onboarding`, `PATCH /auth/onboarding/step`, `src/auth/entities/onboarding-state.entity.ts`, `src/auth/services/user-onboarding.service.ts` |
| Frontend | `expo/app/(auth)/onboarding.tsx` y siguientes |
| DB | `DB/migrations/` — buscar el origen de `user_onboarding_state` |

## Actividades

- [ ] Confirmar la tabla comparativa anterior con evidencia línea a línea.
- [ ] Decidir formalmente: ¿se extiende el modelo de checkpoints para soportar puertas + suficiencia + diagnóstico, o se corrige el documento para adoptar el modelo de checkpoints? Es una decisión de arquitectura, no de redacción.
- [ ] Mapear cada checkpoint del backend a la puerta del documento que le correspondería, o marcarlo como concepto sin equivalencia.
- [ ] Verificar `resume_surface` / `resume_context` como soporte de "siguiente mejor acción" (cruza con RM1-20).

## Criterios de aceptación

- [ ] Las 2 reglas tienen veredicto con evidencia.
- [ ] Existe una decisión escrita y aprobada sobre el modelo de estado objetivo.
- [ ] Existe el mapeo checkpoint ↔ puerta, o la constancia de que no es mapeable.
- [ ] Está resuelta la contradicción en la condición de cierre del onboarding.

## Bloquea a

RM1-17, RM1-20, RM1-21.
EOF

card RM1-12 "Activación del onboarding y Foco del Mes" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:frontend,area:backend,area:figma,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloque L · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-001`, `M1-RN-ONB-012` | `M1-HU-018`, `M1-HU-019` | `CP-M1-ONB-001`, `CP-M1-ONB-002` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ONB-001 (activación, no tutorial), RN-ONB-012 (CTA dominante); HU-019 (foco declarado / no declarado / inferido) |
| Backend | ¿Existe persistencia del Foco del Mes? Verificar en `src/profile`, `src/users` y el modelo de datos. **Hipótesis: no existe** |
| Frontend | `expo/app/(auth)/onboarding.tsx`, `onboarding-foco.tsx` — la pantalla **sí existe** |
| Figma | _pendiente: `node-id` de bienvenida y foco_ |

## Punto de atención

El frontend ya tiene `onboarding-foco.tsx`. Si el backend no persiste el foco, la pantalla está capturando un dato que se pierde, o lo guarda en algún lugar no previsto. HU-019 exige tres estados (`declarado`, `no declarado`, `inferido`) y RN-ONB-012 usa el foco para desempatar el CTA — sin persistencia, ninguna de las dos cosas es posible.

## Actividades

- [ ] Determinar si el Foco del Mes se persiste y dónde. Si no, es `No implementado` con issue de remediación.
- [ ] Verificar RN-ONB-001: la pantalla de bienvenida es activación centrada en valor, no un tour de menús. Contrastar el copy real contra el criterio del documento (HU-018 CA2 lo prohíbe explícitamente).
- [ ] Verificar HU-018 CA3: postergar deja el flujo `pendiente`, no `fallido`. Contrastar contra los valores reales de `onboarding_status`.
- [ ] Verificar HU-019 CA2: la falta de foco no bloquea la carga documental.

## Criterios de aceptación

- [ ] Las 2 reglas tienen veredicto con evidencia.
- [ ] El estado de persistencia del Foco del Mes está determinado y, si falta, tiene issue.
EOF

card RM1-13 "Carga documental y ruta preferente (Kread)" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:frontend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloque M · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-002`, `M1-RN-ONB-003` | `M1-HU-020` | `CP-M1-ONB-003` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ONB-002 (carga documental es la fuente principal), RN-ONB-003 (sin sustituto manual) + §3.3 *"catálogo definitivo de documentos y periodos: pendiente"* |
| Backend | `src/imports/` (incluye `kread/`), `src/imports/services/statement-import.service.ts`, `src/storage/` |
| Frontend | `expo/app/(auth)/onboarding-doc.tsx` |
| Contexto | `context/modulo01-identidad-autenticacion/contexto/contrato-walvy-kread-auth.md`, `deuda-tecnica/KREAD-INTEGRATION.md`, `bitacora/propuesta-kread-multi-documento.md` |

## Actividades

- [ ] Levantar el catálogo **real** de documentos y formatos que hoy acepta el pipeline, y contrastarlo con lo que el documento promete (cartolas, estados de cuenta, últimos movimientos). Insumo directo para RM1-24.
- [ ] Verificar RN-ONB-003: que no exista una ruta manual que sustituya la carga. HU-020 CA3 lo prohíbe. Revisar si alguna pantalla ofrece captura manual como alternativa equivalente.
- [ ] Verificar HU-020 CA1: antes de cargar se explica qué documentos sirven y qué valor se desbloquea.
- [ ] Confirmar que `propuesta-kread-multi-documento.md` sigue vigente o quedó superada, y reflejarlo.
- [ ] Verificar validación de periodo y detección de duplicados (§4.2, paso 2 del flujo).

## Criterios de aceptación

- [ ] Las 2 reglas tienen veredicto con evidencia.
- [ ] Existe el catálogo real de documentos soportados, con formatos y periodos, listo para cerrar el pendiente de §3.3.
EOF

card RM1-14 "Estados de procesamiento y umbrales de demora" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:frontend,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloque N · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-013` | `M1-HU-021` | `CP-M1-ONB-004`, `CP-M1-ONB-005`, `CP-M1-ONB-006` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ONB-013, estado **"requiere validación técnica"**: umbrales configurables y versionados; la fuente propone **45 / 90 segundos** |
| Backend | `src/imports/services/statement-import.service.ts` — estados reales del import y dónde viven los timeouts |
| Frontend | `expo/app/(auth)/onboarding-analyzing.tsx` |

## Actividades

- [ ] Enumerar los estados reales del procesamiento y contrastarlos con los siete que exige HU-021 CA1: `listo`, `subiendo`, `procesando`, `demora suave`, `demora prolongada`, `completado`, `fallido`.
- [ ] Determinar si los umbrales de demora existen, y si son **parámetros versionados** o constantes en código. RN-ONB-013 exige lo primero.
- [ ] Validar técnicamente si 45/90 s son realistas contra la latencia observada del pipeline. Este es el dato que §3.3 pide y que sólo se obtiene midiendo.
- [ ] Verificar HU-021 CA2: salir durante el procesamiento sin perder avance (cruza con RM1-20).

## Criterios de aceptación

- [ ] La regla tiene veredicto con evidencia.
- [ ] Existe una recomendación de umbrales respaldada por medición, no por supuesto.
- [ ] Está determinado si los umbrales son configurables y versionados.
EOF

card RM1-15 "Documento no procesable y carga insuficiente" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:frontend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloque N · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-006`, `M1-RN-ONB-007` | `M1-HU-022`, `M1-HU-023` | `CP-M1-ONB-007`, `CP-M1-ONB-008`, `CP-M1-ONB-019` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ONB-006 (bloqueo por insuficiencia), RN-ONB-007 (*"carga insuficiente no es error"*) |
| Backend | Manejo de errores en `src/imports/`, registro del motivo de rechazo |
| Frontend | `onboarding-doc.tsx`, `onboarding-analysis.tsx` — estados de error y de avance parcial |
| Figma | _pendiente: `node-id` de los estados de error y de avance_ |

## Actividades

- [ ] Verificar que un documento no procesable **no** habilite diagnóstico (HU-022 CA1) y que el motivo de rechazo quede registrado (HU-022 CA3).
- [ ] `CP-M1-ONB-019` exige trazabilidad del motivo **sin exponer datos sensibles en logs**. Revisar qué se escribe efectivamente al log cuando falla un import: nombres de archivo, contenido, datos del titular. Es una revisión de seguridad, no sólo de conformidad.
- [ ] Verificar RN-ONB-007 en el copy real: una carga útil pero insuficiente debe comunicarse como **avance**, no como error. Contrastar los textos concretos del frontend contra este criterio.
- [ ] Verificar que el CTA dominante en el caso insuficiente pida completar, no reintentar a ciegas (HU-023 CA3).

## Criterios de aceptación

- [ ] Las 2 reglas tienen veredicto con evidencia.
- [ ] Existe constancia de qué se registra en logs ante un rechazo y de que no incluye datos sensibles.
- [ ] Los copys de insuficiencia están revisados contra el criterio "avance, no error".
EOF

card RM1-16 "Revisión de indicadores y trazabilidad del dato" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:db,area:frontend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloque O · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-008`, `M1-RN-ONB-015` | `M1-HU-024` | `CP-M1-ONB-009`, `CP-M1-ONB-010` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ONB-008: *"cada indicador registra origen, estado, confianza, evidencia y confirmación"*; RN-ONB-015: lo manual/asistido mantiene **menor confianza**; §1.3 define 9 indicadores con criticidad y estados |
| Backend | `src/cashflow/`, `src/profile/`, `src/imports/entities/` |
| DB | `DB/migrations/013_profile_quality_and_debt_health.up.sql` — punto de partida más probable |
| Frontend | `expo/app/(auth)/onboarding-analysis.tsx` |

## Lo que hay que responder

§1.3 del documento define nueve indicadores (`Ingreso principal`, `Compromisos base`, `Pagos recurrentes`, `Movimientos recientes`, `Instrumentos de pago`, `Fugas`, `Calidad del dato`, `Foco del Mes`) cada uno con **criticidad** y **estados** propios (`detectado` / `por confirmar` / `no detectado`). La pregunta central: ¿existe en el modelo de datos una estructura que soporte por-indicador el quinteto origen + estado + confianza + evidencia + confirmación? Si no existe, RN-ONB-008 es `No implementado` y arrastra a RM1-17, RM1-18 y RM1-19.

## Actividades

- [ ] Auditar el modelo de datos contra los nueve indicadores de §1.3 y su quinteto de metadatos.
- [ ] Verificar RN-ONB-015: que un dato corregido a mano quede marcado con origen manual/asistido y menor confianza.
- [ ] Verificar HU-024 CA2: se puede corregir sin convertir la pantalla en un formulario largo. Contrastar contra el diseño real.
- [ ] Documentar el gap entre indicadores esperados y campos existentes.

## Criterios de aceptación

- [ ] Las 2 reglas tienen veredicto con evidencia.
- [ ] Existe el mapa indicador → campo/tabla real, con los faltantes marcados.
EOF

card RM1-17 "Suficiencia y modos de diagnóstico" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:producto,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloques P, Q · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-004`, `M1-RN-ONB-005`, `M1-RN-ONB-006` | `M1-HU-025` a `M1-HU-027` | `CP-M1-ONB-011` a `CP-M1-ONB-014` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ONB-004 (base suficiente = documento usable + ingreso + movimientos + compromisos o recurrentes), RN-ONB-005 (parcial: base usable, ≤1 crítico faltante no bloqueante, advertencia de precisión), RN-ONB-006 (bloqueo) |
| Backend | **Hipótesis: no existe motor de suficiencia.** Verificar. El único motor de reglas es `src/debts/rules/` |
| Frontend | `onboarding-analysis.tsx`, `onboarding-first-ready.tsx` |

## Contexto

Los tres modos —`complete`, `partial`, `blocked`— son el corazón del diagnóstico y no aparecen en el vocabulario del backend. Esta tarjeta determina el tamaño real del trabajo pendiente del módulo.

Además §3.3 declara pendientes los **umbrales cuantitativos de suficiencia**: la regla dice *"al menos compromisos o pagos recurrentes disponibles"* sin decir cuántos ni de qué antigüedad. Sin eso, la regla no es implementable.

## Actividades

- [ ] Verificar si existe evaluación de suficiencia en algún punto del backend. Si no, las 3 reglas son `No implementado`.
- [ ] Determinar qué hace hoy el frontend en `onboarding-analysis.tsx`: si computa algo localmente, es una regla de negocio viviendo en el cliente y hay que registrarlo como riesgo.
- [ ] Verificar HU-026 CA3 y `CP-M1-ONB-013`: que las inferencias no se presenten como certeza.
- [ ] Redactar la especificación cuantitativa faltante (umbrales concretos) como insumo de RM1-24.

## Criterios de aceptación

- [ ] Las 3 reglas tienen veredicto con evidencia.
- [ ] Está determinado dónde vive hoy la lógica de suficiencia, si es que vive en algún lado.
- [ ] Existe una propuesta de umbrales cuantitativos lista para aprobación.

## Depende de

RM1-11, RM1-16.
EOF

card RM1-18 "Semáforo general del onboarding" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:figma,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloque Q · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-009`, `M1-RN-ONB-010`, `M1-RN-ONB-017` | `M1-HU-025`, `M1-HU-027` | `CP-M1-ONB-011`, `CP-M1-ONB-014` |

## Prohibición explícita a verificar

RN-ONB-009 dice, literalmente, que el semáforo del onboarding usa `En control` / `Atención` / `Riesgo` / `Sin diagnóstico` y **no copia S0–S4 de deuda**. El backend tiene exactamente ese motor prohibido: `src/debts/rules/debt-severity.rule.ts`. Verificar que no se esté reutilizando ni se planee reutilizar.

RN-ONB-010 añade la otra mitad: la falta de datos produce `Sin diagnóstico`, **nunca** rojo. Un semáforo en rojo por ausencia de evidencia es un defecto de producto, no un estado válido.

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Backend | `src/debts/rules/debt-severity.rule.ts` (lo que **no** debe usarse); buscar cualquier enum de semáforo de onboarding |
| Frontend | `onboarding-analysis.tsx` — ¿de dónde sale el color que pinta? |
| Figma | _pendiente: `node-id` de los cuatro estados del semáforo_ |
| DB | Enums y `CHECK` constraints — ver `DB/migrations/016_enforce_status_domain.up.sql`, `025_adopt_model_check_constraints.up.sql` |

## Actividades

- [ ] Verificar la existencia (o ausencia) de un enum propio de semáforo de onboarding.
- [ ] Confirmar que S0–S4 no se reutiliza en ninguna superficie de onboarding.
- [ ] Verificar RN-ONB-017: la deuda puede alimentar el semáforo cuando hay dato, pero no lo gobierna por defecto.
- [ ] Confirmar que existen los cuatro estados en Figma, incluido `Sin diagnóstico`, que es el que suele faltar en el diseño.

## Criterios de aceptación

- [ ] Las 3 reglas tienen veredicto con evidencia.
- [ ] Hay constancia explícita de que S0–S4 no contamina el onboarding.
- [ ] El estado `Sin diagnóstico` tiene diseño y comportamiento definidos.
EOF

card RM1-19 "Presión principal única y CTA dominante" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:db,area:figma,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloque Q · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-011`, `M1-RN-ONB-012` | `M1-HU-028` | `CP-M1-ONB-015` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | HU-028 CA1: *"cada evaluación tiene un único `dominant_pressure_code`"*; CA2: los CTA secundarios tienen menor peso visual; CA3: la explicación dice qué pasa, por qué importa y qué hacer ahora |
| Backend | **`dominant_pressure_code` no aparece en el código ni en el modelo.** Confirmar |
| Frontend | `onboarding-analysis.tsx`, `onboarding-first-ready.tsx` |
| Figma | _pendiente: `node-id` de la jerarquía CTA primario/secundario_ |

## Actividades

- [ ] Confirmar la ausencia de `dominant_pressure_code` y del catálogo de códigos de presión. Si falta, definir el catálogo es trabajo de producto → RM1-24.
- [ ] Verificar la unicidad: `CP-M1-ONB-015` obliga a que con varias señales simultáneas domine una sola. Sin un campo único, la unicidad no es garantizable, sólo aspiracional.
- [ ] Verificar en Figma y en el frontend la jerarquía visual: un CTA primario, secundarios subordinados.
- [ ] Verificar la estructura de la explicación en tres partes (qué pasa / por qué importa / qué hacer).

## Criterios de aceptación

- [ ] Las 2 reglas tienen veredicto con evidencia.
- [ ] Está determinado si existe el campo y el catálogo de códigos de presión.
- [ ] La jerarquía de CTA está verificada en diseño y en implementación.
EOF

card RM1-20 "Retoma sin reinicio y cierre con valor" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:frontend,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · Bloque R · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-014`, `M1-RN-ONB-016` | `M1-HU-029` | `CP-M1-ONB-005`, `CP-M1-ONB-016`, `CP-M1-ONB-017` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ONB-014 (persistir avance, retornar al punto de mayor valor pendiente), RN-ONB-016 (el onboarding se cumple al mostrar diagnóstico + próxima acción) |
| Backend | `resume_surface`, `resume_context` (jsonb), `last_checkpoint_at`, `completed_at` en `user_onboarding_state`; `PATCH /auth/onboarding/step` |
| Frontend | Lógica de retoma en el grupo `(auth)` |

## Contradicción a resolver

El backend marca `completed` cuando **todos los checkpoints son `true`**. RN-ONB-016 dice que se cumple **al mostrar el diagnóstico inicial y la próxima acción**. Un usuario podría tener todos los checkpoints en `true` sin haber visto nunca un diagnóstico —porque el diagnóstico no existe en backend—, y quedar marcado como completado. Verificar y resolver. Cruza con RM1-11.

## Actividades

- [ ] `CP-M1-ONB-016` pide interrumpir en **cada** puerta `G1`–`G5` y retomar. Como las puertas no existen en el modelo, primero hay que establecer el equivalente real y luego probar la interrupción en cada punto.
- [ ] Verificar que `resume_surface`/`resume_context` sean suficientes para expresar "siguiente mejor acción", o si sólo guardan la última pantalla.
- [ ] Verificar HU-029 CA2: al retomar se omiten los pasos ya resueltos, sin repetición.
- [ ] Resolver la contradicción de la condición de cierre.

## Criterios de aceptación

- [ ] Las 2 reglas tienen veredicto con evidencia.
- [ ] La condición de cierre del onboarding es una sola y está escrita.
- [ ] La retoma está probada en todos los puntos de interrupción reales.

## Depende de

RM1-11.
EOF

card RM1-21 "Versionamiento de evaluaciones (rule_version / evaluated_at)" \
  "M1,revision-conformidad,bloque:onboarding,tipo:revision,area:backend,area:db,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §3.2 · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-018` | transversal a HU-025..027 | `CP-M1-ONB-018` |

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | RN-ONB-018: *"`rule_version` y `evaluated_at` son **obligatorios** para auditoría y recálculo"*; `CP-M1-ONB-018` exige recalcular con nueva versión de reglas conservando versión y fecha de cada evaluación |
| Backend | **Ninguno de los dos campos aparece.** Confirmar |
| DB | `DB/migrations/` — buscar cualquier tabla de evaluaciones |

## Por qué importa más de lo que parece

Sin `rule_version` no se puede responder *"¿por qué esta cuenta vio ese diagnóstico en julio?"* después de cambiar las reglas. Para un producto financiero que da lecturas sobre la plata de alguien, eso es un requisito de auditabilidad, no una comodidad de desarrollo. Y el recálculo masivo tras un cambio de reglas es imposible de validar sin poder distinguir qué se evaluó con qué versión.

## Actividades

- [ ] Confirmar la ausencia de ambos campos y de la tabla de evaluaciones que los contendría.
- [ ] Definir el modelo mínimo: una fila por evaluación con `rule_version`, `evaluated_at`, entradas usadas y resultado.
- [ ] Verificar si el histórico se conserva o se sobrescribe. RN-ONB-018 implica histórico.
- [ ] Estimar el trabajo de migración y dejarlo como issue de remediación.

## Criterios de aceptación

- [ ] La regla tiene veredicto con evidencia.
- [ ] Existe una propuesta de modelo de persistencia de evaluaciones.
- [ ] El impacto en DB está estimado.
EOF

card RM1-22 "Frontera M1 ↔ M2 — salida a Perfil Financiero" \
  "M1,revision-conformidad,bloque:transversal,tipo:revision,area:producto,area:frontend,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §1.2, §3.2 · Bloque S · [Doc M1 v3.0](__DOC__)

## Alcance

| Reglas | HU | Casos de prueba |
|---|---|---|
| `M1-RN-ONB-016` | `M1-HU-029` CA3 | `CP-M1-ONB-017` |

## Contexto

§1.4 pone el Perfil Financiero **fuera de alcance** de M1, pero §1.2 lo declara *"superficie de destino que consume el resultado del onboarding"* y el flujo de §4.3 termina ahí. Es una frontera, y las fronteras entre módulos son donde se pierden los contratos.

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | §1.2 (Perfil Financiero pertenece a M2), §1.4 (fuera de alcance), §4.2 paso 7, RN-ONB-016 |
| Contexto M2 | `context/modulo02-perfil-configuracion/`; rama `feature/modulo2-profile` de front-walvy |
| Backend | `src/profile/` |
| Frontend | Ruta de salida real tras `onboarding-first-ready.tsx` |

## Actividades

- [ ] Definir el contrato de lo que M1 entrega a M2: qué campos, con qué garantías de completitud, y qué pasa si el diagnóstico quedó `blocked`.
- [ ] Verificar `CP-M1-ONB-017`: volver al módulo no reinicia el onboarding.
- [ ] Contrastar con el estado de la rama `feature/modulo2-profile` para no diseñar contra una versión muerta.
- [ ] Determinar qué ve el Perfil Financiero de un usuario que **nunca** completó el onboarding.

## Criterios de aceptación

- [ ] La regla tiene veredicto con evidencia.
- [ ] El contrato M1 → M2 está escrito y acordado con quien lleva M2.
- [ ] El caso "diagnóstico bloqueado" tiene comportamiento definido en la superficie de destino.
EOF

card RM1-23 "Decisión — pendientes de acceso y seguridad (§3.3)" \
  "M1,revision-conformidad,bloque:transversal,tipo:decision,area:producto,area:backend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.3 y §6.2 · [Doc M1 v3.0](__DOC__)

## Objetivo

Cerrar los seis pendientes de acceso y seguridad que el documento §3.3 deja abiertos. **No es un ejercicio en blanco:** en casi todos, el backend ya tomó una decisión al implementar. El trabajo es hacerla explícita, validarla con producto y seguridad, y subirla al documento — o corregir el código si producto no está de acuerdo.

## Los seis pendientes

| # | Pendiente §3.3 | Estado observado en backend | Aporta |
|---|---|---|---|
| 1 | Vigencia, longitud y reintentos del código de verificación | 6 dígitos, máx. 5 intentos, 3 reenvíos/hora | RM1-06 |
| 2 | Regla técnica completa de RUT y tratamiento de correo ya registrado | Sin validación de RUT en el DTO; `409` para correo duplicado | RM1-03 |
| 3 | Política completa de complejidad, reutilización y expiración de contraseña | 8 caracteres + mayúscula + número; sin reutilización ni expiración | RM1-04 |
| 4 | Credenciales incorrectas, bloqueo temporal y mensajes de seguridad | Throttle 5/60 s en login; sin bloqueo de cuenta | RM1-02 |
| 5 | Enrolamiento/desactivación de biometría y almacenamiento seguro del usuario | `PATCH /auth/biometric` + `biometric_preferences` | RM1-09 |
| 6 | Duración de sesión, refresh token, cierre de sesión y revocación | Access `15m`; `refresh_tokens` con hash único; `logout-all` | RM1-10 |

## Actividades

- [ ] Recoger de RM1-02, 03, 04, 06, 09 y 10 la política **efectiva** con evidencia en código.
- [ ] Sesión de decisión con Producto, Arquitectura y Seguridad sobre los seis puntos.
- [ ] Marcar cada uno como `ratificado` (el código queda), `a corregir` (gana la decisión nueva) o `diferido` (backlog explícito, con dueño y fecha).
- [ ] Redactar la adenda al documento v3.0 que reemplaza las seis filas de §3.3 por política cerrada.

## Criterios de aceptación

- [ ] Los seis pendientes tienen resolución escrita, con responsable y fecha.
- [ ] Existe adenda lista para incorporarse al documento formal.
- [ ] Cada `a corregir` tiene issue de implementación abierto.

## Bloquea a

RM1-26.
EOF

card RM1-24 "Decisión — pendientes de onboarding y reglas financieras (§3.3)" \
  "M1,revision-conformidad,bloque:transversal,tipo:decision,area:producto,area:backend,prio:alta" <<'EOF'
> Epic __EPIC__ · Doc §3.3 y §6.2 · [Doc M1 v3.0](__DOC__)

## Objetivo

Cerrar los cuatro pendientes de onboarding. A diferencia de RM1-23, aquí el backend **no** decidió nada: el motor de diagnóstico no existe. Estas decisiones son requisito previo para poder construirlo, no una formalización posterior.

## Los cuatro pendientes

| # | Pendiente §3.3 | Situación | Aporta |
|---|---|---|---|
| 1 | Catálogo definitivo de documentos y periodos soportados | Existe pipeline Kread; falta el catálogo formal | RM1-13 |
| 2 | Umbrales cuantitativos del semáforo y de la suficiencia | Sin definir y sin implementar. Bloquea RN-ONB-004, 005, 009 | RM1-17, RM1-18 |
| 3 | Validación técnica de los umbrales de demora 45/90 s | Propuestos por la fuente, nunca medidos | RM1-14 |
| 4 | Contratos definitivos de datos, persistencia y recálculo | Sin modelo de evaluaciones ni `rule_version` | RM1-16, RM1-21 |

## Actividades

- [ ] Consolidar los insumos de RM1-13, 14, 16, 17, 18 y 21.
- [ ] Definir con Producto los umbrales cuantitativos: qué cuenta como ingreso detectado, cuántos movimientos y de qué antigüedad, cuántos compromisos hacen base suficiente, y dónde caen los cortes del semáforo. Sin números, RN-ONB-004 y RN-ONB-009 no son implementables.
- [ ] Definir el catálogo de códigos de presión (`dominant_pressure_code`) — insumo de RM1-19.
- [ ] Aprobar con Arquitectura el contrato de persistencia y recálculo de evaluaciones.
- [ ] Redactar la adenda al documento v3.0.

## Criterios de aceptación

- [ ] Los cuatro pendientes tienen resolución escrita, con responsable y fecha.
- [ ] Existen umbrales numéricos concretos, aprobados, suficientes para implementar sin volver a preguntar.
- [ ] Existe el catálogo de códigos de presión.
- [ ] Existe adenda lista para incorporarse al documento formal.

## Bloquea a

RM1-17, RM1-18, RM1-19, RM1-26.
EOF

card RM1-25 "QA — reconciliar trazabilidad §5 con evidencia real" \
  "M1,revision-conformidad,bloque:transversal,tipo:revision,area:qa,prio:media" <<'EOF'
> Epic __EPIC__ · Doc §5 y §6.1 · [Doc M1 v3.0](__DOC__)

## Objetivo

La §5 del documento afirma que los 17 casos de acceso están *Passed* y que los 20 de onboarding están *Pendiente*. Ninguna de las dos afirmaciones está anclada a una versión de aplicación, ambiente ni fecha. Esta tarjeta convierte esa tabla en evidencia verificable.

## Lo que el propio documento exige (§6.1)

> Las evidencias de QA incluyen **plataforma, versión de aplicación, ambiente, fecha, resultado y defecto asociado** cuando corresponda.

La tabla actual de §5.1 sólo tiene plataforma y resultado. Faltan cuatro de las seis columnas obligatorias.

## Fuentes a contrastar

| Frente | Referencia |
|---|---|
| Documento | §5.1 (17 CP de acceso, *Passed*), §5.3 y §5.4 (20 CP de onboarding, todos *Pendiente*) |
| Repo | `workspace/walvy-workspace/e2e/tests/`, `context/qa-audits/` |

## Actividades

- [ ] Para cada `CP-M1-ACC-001..017`: localizar la evidencia real y completar versión, ambiente y fecha. Los que no tengan evidencia localizable pasan a `Sin evidencia`, no siguen como *Passed*.
- [ ] Cruzar los 17 casos con la suite E2E existente y marcar cuáles están automatizados y cuáles fueron manuales.
- [ ] Para los 20 `CP-M1-ONB-*`: confirmar que siguen pendientes y determinar cuáles son ejecutables **hoy** y cuáles están bloqueados porque la funcionalidad no existe. Son cosas distintas y la tabla no las distingue.
- [ ] Detectar reglas sin ningún caso de prueba asociado.

## Criterios de aceptación

- [ ] La tabla de trazabilidad tiene las seis columnas que §6.1 exige.
- [ ] Ningún caso figura como *Passed* sin evidencia localizable.
- [ ] Los casos de onboarding están separados entre `ejecutable` y `bloqueado por funcionalidad inexistente`.
- [ ] Las reglas sin cobertura de prueba están listadas.
EOF

card RM1-26 "Informe consolidado y backlog de remediación" \
  "M1,revision-conformidad,bloque:transversal,tipo:informe,area:producto,prio:alta" <<'EOF'
> Epic __EPIC__ · Cierra el epic · [Doc M1 v3.0](__DOC__)

## Objetivo

Convertir las 48 filas de la matriz en una decisión ejecutable: qué se corrige en código, qué se corrige en el documento, y qué se difiere con dueño y fecha.

## Entradas

Las 25 tarjetas anteriores. Esta no empieza hasta que RM1-23 y RM1-24 estén resueltas: sin las decisiones de §3.3, buena parte de la matriz queda en `Bloqueado por decisión` y el informe no concluye nada.

## Actividades

- [ ] Consolidar la matriz completa y publicar el recuento por veredicto: cuántas conformes, divergentes, no implementadas, no aplican.
- [ ] Clasificar cada divergencia en `corregir código` / `corregir documento` / `decisión de producto`, y verificar que cada una tenga issue abierto con dueño.
- [ ] Redactar la adenda consolidada al documento v3.0, incorporando las de RM1-23 y RM1-24.
- [ ] Emitir una recomendación explícita sobre la aprobación del documento: **aprobable como está**, **aprobable con adenda**, o **no aprobable hasta cerrar X**. El documento está en estado *Borrador consolidado para revisión y entrega formal* y §7 tiene cinco aprobaciones pendientes; esta recomendación es lo que las desbloquea.
- [ ] Estimar el esfuerzo del backlog de remediación y proponer orden.

## Criterios de aceptación

- [ ] La matriz está completa: 48 reglas, 48 veredictos, todos con evidencia.
- [ ] Cada divergencia tiene issue con dueño y clasificación.
- [ ] La adenda al documento está redactada y revisada.
- [ ] Hay una recomendación formal de aprobación, con su justificación.
- [ ] El backlog de remediación está estimado y priorizado.

## Depende de

RM1-01 a RM1-25.
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Project v2 (opcional)
# ─────────────────────────────────────────────────────────────────────────────
setup_project() {
  [[ "$WITH_PROJECT" == "1" ]] || return 0
  say "Project v2 · $PROJECT_TITLE"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  crearía el proyecto y agregaría ${#CREATED[@]} items"
    return
  fi
  local num
  num="$(gh project create --owner "$ORG" --title "$PROJECT_TITLE" --format json --jq '.number')"
  say "Proyecto #$num — https://github.com/orgs/$ORG/projects/$num"
  local url
  for url in "${CREATED[@]}"; do
    gh project item-add "$num" --owner "$ORG" --url "$url" >/dev/null
  done
  say "${#CREATED[@]} items agregados"
  warn "Los estados Todo/In Progress/In Review/Blocked/Done se configuran una vez en la UI del proyecto."
}

# ─────────────────────────────────────────────────────────────────────────────
main() {
  if [[ "$DRY_RUN" == "1" ]]; then
    warn "DRY_RUN — no se escribe nada en GitHub"
  else
    require_gh
  fi
  say "Repo: $REPO · Asignado: $ASSIGNEE"
  setup_labels
  ensure_milestone
  create_epic
  create_cards
  setup_project
  say "Listo — 1 epic + 26 tarjetas"
}

main "$@"
