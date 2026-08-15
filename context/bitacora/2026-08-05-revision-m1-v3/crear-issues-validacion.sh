#!/usr/bin/env bash
#
# Crea en KabeliDev/front-walvy un issue por flujo de las Matrices de Validación
# M1 y M2 (24 issues que cubren 144 variantes), asignados a Leonardo Salas.
#
# Cada issue lleva la tabla completa de sus variantes y un checklist, para que
# ninguna de las 144 se pierda al agrupar por flujo.
#
# Fuente de datos: variantes-validacion.psv (mismo directorio).
#
# Uso
#   DRY_RUN=1 ./crear-issues-validacion.sh     # imprime, no escribe
#   ./crear-issues-validacion.sh               # publica
#
# NO es idempotente: una segunda corrida crea 24 issues duplicados.

set -euo pipefail

REPO="${REPO:-KabeliDev/front-walvy}"
ASSIGNEE="${ASSIGNEE:-leonardosalas-kabeli}"
MILESTONE="${MILESTONE:-Matriz de Validación M1 y M2}"
DATA="${DATA:-$(dirname "$0")/variantes-validacion.psv}"
DRY_RUN="${DRY_RUN:-0}"

CODE_REPO="walvy-org/walvy-app-frontend"
CODE_BRANCH="main"
FIGMA="https://www.figma.com/design/v45c4HTKnPnU0XABMa5vjY/Walvi-APP---Edificate-Inteligente"
DOC="https://docs.google.com/document/d/1gBJzAuobWVK2h2qdNxBuoranpgxdmlLR/edit"
XLS_M1="https://docs.google.com/spreadsheets/d/12eazr53al6LpeoMLvtPxr_kdSnlcsmIq/edit"
XLS_M2="https://docs.google.com/spreadsheets/d/1bSjP-RwUvTtw6reC_scQ6Ey-maOTR3o8/edit"

say() { printf '\033[1;34m▸\033[0m %s\n' "$*"; }

# Flujos cuya validación no se agota en la pantalla: el comportamiento esperado
# depende de una respuesta del backend. Se marca en el issue para poder abrir
# el issue espejo en back-walvy cuando corresponda.
backend_dep() {
  case "$1" in
    "Verificación de cuenta"|"Recuperación de acceso"|"Carga documental"|\
    "Procesamiento"|"Suficiencia"|"Diagnóstico"|"Retoma"|"Perfil Financiero"|\
    "Actualizar contraseña"|"Salud de Deuda"|"Ruta Despeje"|"Suscripción"|"Mis Datos")
      return 0 ;;
    *) return 1 ;;
  esac
}

# Flujos con contradicción declarada o brecha funcional sin dueño.
prio_alta() {
  case "$1" in
    "Registro"|"Verificación de cuenta"|"Recuperación de acceso"|"Suficiencia"|\
    "Diagnóstico"|"Carga documental"|"Mis Datos"|"Salud de Deuda"|"Suscripción"|\
    "Actualizar contraseña"|"CTA / Próxima acción")
      return 0 ;;
    *) return 1 ;;
  esac
}

figma_url() { printf '%s?node-id=%s' "$FIGMA" "${1//:/-}"; }

ensure_label() {
  [[ "$DRY_RUN" == "1" ]] && return 0
  gh label create "$1" --repo "$REPO" --color "$2" --description "$3" 2>/dev/null ||
    gh label edit "$1" --repo "$REPO" --color "$2" --description "$3" >/dev/null
}

setup_labels() {
  say "Etiquetas en $REPO"
  ensure_label "M1"                 "1D76DB" "Módulo 1 — acceso, registro, onboarding y diagnóstico"
  ensure_label "M2"                 "0052CC" "Módulo 2 — perfil, configuración y suscripción"
  ensure_label "matriz-validacion"  "5319E7" "Validación de variantes contra Figma y app"
  ensure_label "area:frontend"      "0E8A16" "walvy-app-frontend"
  ensure_label "dep:backend"        "D93F0B" "El comportamiento esperado depende del backend"
  ensure_label "prio:alta"          "B60205" ""
  ensure_label "prio:media"         "FBCA04" ""
}

ensure_milestone() {
  [[ "$DRY_RUN" == "1" ]] && return 0
  gh api "repos/$REPO/milestones" --jq '.[].title' | grep -qxF "$MILESTONE" && return 0
  gh api "repos/$REPO/milestones" -f title="$MILESTONE" \
    -f description="144 variantes de las matrices M1 y M2, validadas contra Figma y la app." >/dev/null
}

build_body() {
  local mod="$1" flujo="$2" n="$3"
  local xls; [[ "$mod" == "M1" ]] && xls="$XLS_M1" || xls="$XLS_M2"

  printf '> **Matriz de Validación WALVY — Módulo %s** · Flujo **%s** · %s variantes\n' "$mod" "$flujo" "$n"
  printf '> Código: [`%s@%s`](https://github.com/%s/tree/%s) — en local es la rama `walvy-main`\n' \
    "$CODE_REPO" "$CODE_BRANCH" "$CODE_REPO" "$CODE_BRANCH"
  printf '> Fuentes: [Matriz %s](%s) · [Documento formal M1 v3.0](%s) · [Figma](%s)\n\n' "$mod" "$xls" "$DOC" "$FIGMA"

  printf '## Objetivo\n\n'
  printf 'Validar cada variante de este flujo contra la app y el diseño, y dejar registrado el veredicto para el cierre del módulo. Las %s variantes entran hoy como `Pendiente` en la matriz.\n\n' "$n"

  printf '## Variantes\n\n'
  printf '| ID | Escenario | Condición / disparador | Comportamiento esperado | Soporte | Regla asociada |\n'
  printf '|---|---|---|---|---|---|\n'
  awk -F'|' -v m="$mod" -v f="$flujo" \
    '$1==m && $2==f {printf "| `%s` | %s | %s | %s | %s | %s |\n", $3, $4, $5, $6, $7, $8}' "$DATA"

  printf '\n## Checklist\n\n'
  while IFS='|' read -r vmod vflujo vid vesc _ _ _ _ vnodo; do
    [[ "$vmod" == "$mod" && "$vflujo" == "$flujo" ]] || continue
    printf -- '- [ ] `%s` %s — [nodo %s](%s)\n' "$vid" "$vesc" "$vnodo" "$(figma_url "$vnodo")"
  done < "$DATA"

  if backend_dep "$flujo"; then
    printf '\n## Dependencia de backend\n\n'
    printf 'El comportamiento esperado de este flujo no se agota en la pantalla: parte depende de lo que responda el backend. Cuando una variante falle por el lado del servidor, **no la marques como corregible en el front** — deja el hallazgo anotado aquí y se abre el issue espejo en `KabeliDev/back-walvy`.\n'
  fi

  printf '\n## Veredicto por variante\n\n'
  printf 'Para cada una, dejar comentario con uno de estos y su evidencia (captura o `archivo:línea`):\n\n'
  printf '| Veredicto | Cuándo |\n|---|---|\n'
  printf '| `Conforme` | La app se comporta como describe el comportamiento esperado |\n'
  printf '| `Divergente` | Implementado pero distinto → abrir issue de corrección |\n'
  printf '| `No implementado` | La variante no existe en la app |\n'
  printf '| `Bloqueado` | Depende de una decisión de Producto todavía abierta |\n'

  printf '\n## Criterios de aceptación\n\n'
  printf -- '- [ ] Las %s variantes tienen veredicto con evidencia.\n' "$n"
  printf -- '- [ ] Cada `Divergente` y cada `No implementado` tiene issue de corrección abierto.\n'
  printf -- '- [ ] Las variantes marcadas como pendientes de formalizar regla quedan listadas para el PO.\n'
  printf -- '- [ ] El resultado está reflejado en la columna Validación Cliente de la matriz.\n'
}

main() {
  [[ -f "$DATA" ]] || { echo "No encuentro $DATA" >&2; exit 1; }
  [[ "$DRY_RUN" == "1" ]] && say "DRY_RUN — no se escribe nada"
  say "Repo: $REPO · Asignado: $ASSIGNEE"
  setup_labels
  ensure_milestone

  local i_m1=0 i_m2=0 total=0
  # Orden de aparición en cada matriz, sin reordenar.
  while IFS='|' read -r mod flujo; do
    local n; n="$(awk -F'|' -v m="$mod" -v f="$flujo" '$1==m && $2==f {c++} END {print c+0}' "$DATA")"
    local idx
    if [[ "$mod" == "M1" ]]; then i_m1=$((i_m1+1)); idx="$(printf '%02d' "$i_m1")"
    else i_m2=$((i_m2+1)); idx="$(printf '%02d' "$i_m2")"; fi

    local id="MV-$mod-$idx"
    local title="$id · $flujo — validar $n variantes"
    local labels="$mod,matriz-validacion,area:frontend"
    prio_alta "$flujo" && labels="$labels,prio:alta" || labels="$labels,prio:media"
    backend_dep "$flujo" && labels="$labels,dep:backend"

    total=$((total+1))
    if [[ "$DRY_RUN" == "1" ]]; then
      printf '\n\033[1;32m── %s ──\033[0m %s\n  labels: %s\n' "$id" "$title" "$labels"
      continue
    fi

    local url
    url="$(build_body "$mod" "$flujo" "$n" | gh issue create \
      --repo "$REPO" --title "$title" --label "$labels" \
      --assignee "$ASSIGNEE" --milestone "$MILESTONE" --body-file -)"
    say "$id → $url"
  done < <(awk -F'|' '{print $1"|"$2}' "$DATA" | awk '!seen[$0]++')

  say "Listo — $total issues"
}

main "$@"
