#!/usr/bin/env bash
#
# Crea el tablero Projects v2 de la revisión M1 y le engancha los 27 issues
# que ya viven en KabeliDev/back-walvy (#20 a #46).
#
# Los issues NO se tocan: un Project v2 sólo los referencia. Por eso este script
# se puede correr contra el usuario personal hoy y contra la organización mañana,
# sin duplicar ni migrar nada. Los dos tableros pueden coexistir.
#
# Uso
#   ./crear-tablero.sh                      # tablero bajo la cuenta personal
#   OWNER=KabeliDev ./crear-tablero.sh      # tablero bajo la organización
#
# Requiere scope 'project'. Si la organización no permite crear proyectos a sus
# miembros, falla con:
#   GraphQL: <usuario> does not have permission to create projects on ownerId ...
# Lo habilita un owner en Settings → Member privileges → Allow members to create projects.

set -euo pipefail

OWNER="${OWNER:-miguelherize-creator}"
TITLE="${TITLE:-Walvy — Revisión M1}"
REPO="${REPO:-KabeliDev/back-walvy}"
FIRST_ISSUE="${FIRST_ISSUE:-20}"
LAST_ISSUE="${LAST_ISSUE:-46}"

say() { printf '\033[1;34m▸\033[0m %s\n' "$*"; }

# issue|bloque|prioridad|reglas cubiertas
CARDS="
20|transversal|alta|epic — 48 reglas
21|transversal|alta|habilitador
22|acceso|alta|ACC-001..005
23|acceso|alta|ACC-006, 007, 008
24|acceso|media|ACC-009
25|acceso|alta|ACC-010, 011
26|acceso|alta|ACC-012..015
27|acceso|media|ACC-016..018
28|acceso|alta|ACC-019..024
29|acceso|alta|ACC-025..027
30|acceso|media|ACC-028
31|onboarding|alta|ACC-029, 030
32|onboarding|media|ONB-001, 012
33|onboarding|alta|ONB-002, 003
34|onboarding|media|ONB-013
35|onboarding|alta|ONB-006, 007
36|onboarding|alta|ONB-008, 015
37|onboarding|alta|ONB-004, 005, 006
38|onboarding|alta|ONB-009, 010, 017
39|onboarding|alta|ONB-011, 012
40|onboarding|media|ONB-014, 016
41|onboarding|media|ONB-018
42|transversal|media|ONB-016
43|transversal|alta|§3.3 acceso (6 pendientes)
44|transversal|alta|§3.3 onboarding (4 pendientes)
45|transversal|media|CP-M1-ACC/ONB
46|transversal|alta|cierre del epic
"

say "Creando tablero «$TITLE» bajo $OWNER"
PROJECT_JSON="$(gh project create --owner "$OWNER" --title "$TITLE" --format json)"
NUM="$(jq -r '.number' <<<"$PROJECT_JSON")"
PID="$(jq -r '.id'     <<<"$PROJECT_JSON")"
URL="$(jq -r '.url'    <<<"$PROJECT_JSON")"
say "Proyecto #$NUM — $URL"

# ── Status: las cinco columnas del método de revisión ────────────────────────
# 'Blocked' no es decorativa: el diccionario de veredictos tiene
# «Bloqueado por decisión», y varias tarjetas de onboarding caen ahí hasta
# que RM1-24 cierre los umbrales cuantitativos.
F_STATUS="$(gh project field-list "$NUM" --owner "$OWNER" --format json \
  --jq '.fields[] | select(.name=="Status") | .id')"

gh api graphql -f fieldId="$F_STATUS" -f query='
mutation($fieldId: ID!) {
  updateProjectV2Field(input: {
    fieldId: $fieldId
    singleSelectOptions: [
      {name: "Todo",        color: GRAY,   description: "Sin empezar"}
      {name: "In Progress", color: YELLOW, description: "Revisión en curso"}
      {name: "In Review",   color: BLUE,   description: "Veredictos listos, en validación"}
      {name: "Blocked",     color: RED,    description: "Bloqueado por decisión de §3.3"}
      {name: "Done",        color: GREEN,  description: "Reglas con veredicto y evidencia"}
    ]
  }) { projectV2Field { ... on ProjectV2SingleSelectField { id } } }
}' >/dev/null
say "Status: Todo · In Progress · In Review · Blocked · Done"

# ── Campos propios ───────────────────────────────────────────────────────────
gh project field-create "$NUM" --owner "$OWNER" --name "Bloque" --data-type SINGLE_SELECT \
  --single-select-options "acceso,onboarding,transversal" >/dev/null
gh project field-create "$NUM" --owner "$OWNER" --name "Prioridad" --data-type SINGLE_SELECT \
  --single-select-options "alta,media,baja" >/dev/null
gh project field-create "$NUM" --owner "$OWNER" --name "Reglas cubiertas" --data-type TEXT >/dev/null
say "Campos: Bloque · Prioridad · Reglas cubiertas"

# ── Enganchar los issues ─────────────────────────────────────────────────────
for n in $(seq "$FIRST_ISSUE" "$LAST_ISSUE"); do
  gh project item-add "$NUM" --owner "$OWNER" --url "https://github.com/$REPO/issues/$n" >/dev/null
  printf '.'
done
echo
say "$((LAST_ISSUE - FIRST_ISSUE + 1)) issues enganchados desde $REPO"

# ── Poblar campos ────────────────────────────────────────────────────────────
FIELDS="$(gh project field-list "$NUM" --owner "$OWNER" --format json)"
fid()  { jq -r --arg n "$1" '.fields[]|select(.name==$n)|.id' <<<"$FIELDS"; }
oid()  { jq -r --arg n "$1" --arg o "$2" \
           '.fields[]|select(.name==$n)|.options[]|select(.name==$o)|.id' <<<"$FIELDS"; }

F_STATUS="$(fid Status)"; F_BLOQUE="$(fid Bloque)"
F_PRIO="$(fid Prioridad)"; F_REGLAS="$(fid "Reglas cubiertas")"
O_TODO="$(oid Status Todo)"

MAP="$(gh project item-list "$NUM" --owner "$OWNER" --limit 100 --format json \
        --jq '.items[] | "\(.content.number) \(.id)"')"

while IFS='|' read -r num bloque prio reglas; do
  [ -z "${num// }" ] && continue
  iid="$(awk -v n="$num" '$1==n{print $2}' <<<"$MAP")"
  [ -z "$iid" ] && { echo "  ! sin item para #$num" >&2; continue; }
  gh project item-edit --id "$iid" --project-id "$PID" --field-id "$F_STATUS" --single-select-option-id "$O_TODO" >/dev/null
  gh project item-edit --id "$iid" --project-id "$PID" --field-id "$F_BLOQUE" --single-select-option-id "$(oid Bloque "$bloque")" >/dev/null
  gh project item-edit --id "$iid" --project-id "$PID" --field-id "$F_PRIO"   --single-select-option-id "$(oid Prioridad "$prio")" >/dev/null
  gh project item-edit --id "$iid" --project-id "$PID" --field-id "$F_REGLAS" --text "$reglas" >/dev/null
  printf '%s ' "#$num"
done <<< "$CARDS"
echo

say "Listo — $URL"
