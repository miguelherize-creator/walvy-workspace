# Cómo se comunican los módulos: Avisos + M03 + Gamificación + M08

Fuente: contratos funcionales y guías Backend de la Entrega Kabeli 2.0 (M03, Mis Avisos, Gamificación, M08). Numeración del cliente. Issue: KabeliDev/back-walvy#351. Son contratos lógicos, no describen el código actual de `back-walvy`.

## 1. Mapa lógico

```mermaid
flowchart LR
  subgraph OWN["Módulos dueños (calculan y deciden)"]
    M01["M01 Identidad y onboarding<br/>diagnóstico, eventos operacionales"]
    M02["M02 Perfil y Foco<br/>Disponible, suscripción, preferencias"]
    M04["M04 Ruta Despeje<br/>Presión, Salud, Ruta"]
    M05["M05 Presupuesto Vivo"]
    M06["M06 Pagos y compromisos"]
  end

  subgraph ORQ["Orquestación y presentación"]
    M03["M03 Home / Mis Avisos<br/>prioridad, superficies, elegibilidad de canal"]
    M07["M07 Asistente IA<br/>solo explica, no decide"]
  end

  subgraph TRANS["Capacidad transversal"]
    GAM["Motor de Gamificación<br/>16 reglas, AwardLedger, ProgressSnapshot"]
  end

  subgraph ADM["Administración"]
    M08["M08 Backoffice<br/>config versionada, dashboard, roles, soporte"]
  end

  DEL["M02 Delivery<br/>preferencias, permiso, cadencia, cooldown"]
  EXT["Device / Email"]
  UI["Home y Campana<br/>Principal, Importante, Revisa y confirma, Tus avisos"]

  M01 -- "situaciones / eventos operacionales" --> M03
  M02 -- "5 familias" --> M03
  M04 -- "7 familias" --> M03
  M05 -- "6 familias" --> M03
  M06 -- "7 familias" --> M03

  M03 -- "proyecciones" --> UI
  M03 -- "external_delivery_candidate" --> DEL
  DEL --> EXT

  M01 -. "COMPLETED / REVERSED" .-> GAM
  M02 -. "COMPLETED / REVERSED" .-> GAM
  M04 -. "COMPLETED / REVERSED" .-> GAM
  M05 -. "COMPLETED / REVERSED" .-> GAM
  M06 -. "COMPLETED / REVERSED" .-> GAM
  GAM -- "ProgressSnapshot (solo lectura)" --> M03

  M08 == "ConfigVersion M04/M05/M06" ==> M04
  M08 == "ConfigVersion" ==> M05
  M08 == "ConfigVersion" ==> M06
  M08 == "global_enabled, points_per_task, monthly_goal" ==> GAM
  M08 -. "disponibilidad de recomendaciones" .-> M02

  M03 -. "contexto para explicar" .-> M07
  M01 -. "identidad, access_state, support_disposition" .-> M08
  M04 -. "outputs / eventos para dashboard" .-> M08
  M05 -.-> M08
  M06 -.-> M08
  M02 -. "billing / entitlement" .-> M08
```

## 2. Avisos: de la situación a Home, Campana y canal externo

```mermaid
sequenceDiagram
  autonumber
  participant OW as Módulo dueño (M02/M04/M05/M06)
  participant M03 as M03 Orquestación
  participant CAT as Catálogo Maestro (communication_catalog_id)
  participant UI as Home y Campana
  participant M02 as M02 Delivery
  participant CH as Device / Email

  OW->>M03: Envelope (situation_id + lifecycle_instance_id, version, owner_status, actionability, local_priority, CTA/destino)
  M03->>M03: Idempotencia: misma versión y payload = no-op, payload distinto = VERSION_CONFLICT
  M03->>M03: Gates: vigente, evaluable, carril, primary-capable
  M03->>M03: Competencia global M04 > M06 > M05 y desempate por deadline
  M03->>CAT: Lookup por owner_module + family_id + material_variant_code
  CAT-->>M03: copy, CTA, destino, superficies, política Device/Email
  M03->>UI: HOME_PRIMARY (0/1), HOME_IMPORTANT, HOME_REVIEW, Campana Current/Otros
  UI-->>M03: READ / entrada efectiva al CTA (in_app_reached_current_version)
  opt Comunicación con elegibilidad externa positiva
    M03->>M02: external_delivery_candidate (identidad, versión, elegibilidad, copy_key, CTA mínimo)
    M02->>M02: Preferencia, consentimiento/permiso, cadencia, cooldown, dedupe
    M02->>M02: Crea communication_cycle_id (un solo canal principal)
    M02->>CH: Device primero, Email solo en ciclo posterior si persiste
  end
  OW->>M03: OWNER_RESOLVED
  M03->>UI: Retira Current y recalcula la acción principal
  M03->>M03: History se conserva 2 meses calendario
```

## 3. Gamificación: award, reversión y progreso

```mermaid
sequenceDiagram
  autonumber
  participant OW as Módulo dueño
  participant GM as Motor de Gamificación
  participant CFG as Config versionada (M08)
  participant LED as AwardLedger
  participant SNAP as ProgressSnapshot
  participant M03 as M03 Home

  OW->>OW: Persiste la acción financiera (no depende del Motor)
  OW->>GM: OwnerActionEvent COMPLETED (event_id, rule_id, objeto, lifecycle, occurred_at UTC)
  GM->>GM: Valida owner y rule_id en la allowlist de 16
  GM->>CFG: Config efectiva según occurred_at
  GM->>GM: period_id con reporting_timezone versionada
  GM->>GM: award_key = user_ref + rule_id + objeto + lifecycle
  alt Ya existe award neto o event_id repetido
    GM-->>OW: Mismo outcome previo (sin duplicar)
  else global_enabled = OFF
    GM-->>OW: Sin award y sin backfill
  else Elegible
    GM->>LED: Append award con original_points
    GM->>SNAP: Recalcula snapshot del período
  end
  OW->>GM: OwnerActionEvent REVERSED
  GM->>LED: Compensación -original_points (período original, se procesa aun con OFF)
  GM->>SNAP: Recalcula snapshot afectado
  M03->>SNAP: Consulta ProgressSnapshot
  alt FRESH
    SNAP-->>M03: monthly_points, monthly_goal, goal_status
  else STALE o NO_EVALUABLE
    SNAP-->>M03: No evaluable (nunca 0)
  end
  Note over M03,GM: Click, READ, apertura o delivery de M03 nunca son completion
```

## 4. M08: publicación de configuración

```mermaid
sequenceDiagram
  autonumber
  actor ADM as Directivo / Producto
  participant M08 as M08 Backoffice
  participant AUD as Auditoría
  participant OW as Dueño (M04/M05/M06)
  participant GM as Motor de Gamificación
  participant SNAPS as Snapshots históricos

  ADM->>M08: publish_config_version (config_id, valores, against_version, reason)
  M08->>M08: Valida rol en backend, config EDITABLE (no PROTECTED/CONDITIONAL)
  M08->>M08: Valida tipo, unidad e invariantes del grupo completo
  M08->>M08: against_version vs versión vigente (evita overwrite silencioso)
  alt Versión desactualizada o grupo inválido
    M08-->>ADM: Rechazo: refrescar y reconfirmar
  else Válido
    M08->>M08: Nueva versión inmutable, effective_from = guardado
    M08->>AUD: AuditEvent (actor, rol, before/after, versiones)
    alt Parámetros M04 / M05 / M06
      M08->>OW: ConfigVersion publicada
      OW->>OW: Recalcula solo su estado vigente
      OW-->>SNAPS: Snapshots históricos conservan su versión
    else Gamificación
      M08->>GM: global_enabled, points_per_task, monthly_goal
      GM->>GM: Aplica hacia adelante según occurred_at
    end
    M08-->>ADM: Versión vigente confirmada
  end
  Note over M08,OW: M08 nunca calcula fórmulas del dueño. Rollback = nueva versión
```

## Reglas que los diagramas no muestran
- M07 solo explica lo que M03 ya decidió, no cambia prioridad, comunicación ni canal.
- M03 no envía nada. Un solo canal externo principal por ciclo, Device y Email nunca simultáneos.
- READ no resuelve una situación. Click, READ, apertura o delivery nunca son completion de Gamificación.
- Una falla de Gamificación o de M08 no revierte la acción financiera del dueño.
- El `communication_catalog_id` no es único: el lookup de política es `owner_module + family_id + material_variant_code`.
