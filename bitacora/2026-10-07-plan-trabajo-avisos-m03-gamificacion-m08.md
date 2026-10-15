# Plan de trabajo: Avisos + M03 + Gamificación + M08

Fecha: 2026-10-07. Issue: KabeliDev/back-walvy#351.
Base: contratos de la Entrega Kabeli 2.0 (numeración del cliente) contrastados con `origin/main` (6cc6339) y `origin/qa` (50becb5). En ambas ramas M03, Avisos, Gamificación y M08 no existen. Es un borrador para discutir: los tamaños son relativos (S/M/L), no estimaciones en días.

## 0. Decisiones previas (bloquean el arranque)

| # | Decisión | Opciones | Recomendación |
|---|---|---|---|
| D1 | Rama base de los PRs | `qa` (379 commits sin pasar a `main`) o `main` (80 commits que `qa` no tiene) | `qa`: el índice del workspace la fija como código de referencia y es el flujo de serie `qa → cliente`. Confirmar con el equipo |
| D2 | Entrega de eventos entre módulos | `EventEmitter2` en memoria (hoy) u outbox transaccional | Outbox: el contrato exige idempotencia por `event_id`, reintentos y que una caída no pierda un completion |
| D3 | Identidad de ciclo de vida | Definir `lifecycle_instance_id` por objeto reabrible | Definirlo por dueño antes de emitir (ver §2) |
| D4 | Tablas legacy | Reutilizar o crear nuevas para M03 y Gamificación | Nuevas, y deprecar `notification_queue`, `alert_preferences` y las 4 tablas de gamificación. Verificar antes si hay datos |
| D5 | `reporting_timezone` | Config de plataforma versionada | Una sola fuente, no `America/Santiago` hardcodeado |

Preguntas a Walvy (no bloquean D1-D5, pero sí el diseño fino):
1. La llave oficial del catálogo es `owner_module + family_id + material_variant_code`, porque `communication_catalog_id` se repite en dos pares de variantes.
2. Faltan §17 y §18 en la guía de M03.
3. Dedupe cross-rule de M04 en Gamificación, que solo está definido para M05 y M06.
4. Versión y fecha de la guía M03 (18-sep frente a 21-sep en el LEEME).
5. Rutas reales para los destinos lógicos (`debt_route`, `payments_commitments`, etc.).
6. Transición que cierra el onboarding (M01-001), el dato crítico de deuda (M04-002) y la contradicción de pago (M06-006). Hoy no existen en el código.
7. Valores de Salud 60/90 de M04, marcados "pendiente de definición de producto".

## 1. Orden y dependencias

```
Fase 0 decisiones
   │
   ├─► Fase 1 Fundaciones transversales (outbox, lifecycle ids, timezone)
   │        │
   │        ├─► Fase 2 M08 núcleo (roles, config versionada, auditoría)  ──┐
   │        │                                                              │ config
   │        ├─► Fase 3 Motor de Gamificación  ◄────────────────────────────┘
   │        │        └─► 3b Emisión desde M01/M02/M04/M05/M06
   │        │
   │        └─► Fase 4 M03 (envelopes, catálogo, acción principal, Campana)
   │                 └─► 4b Adaptadores por dueño
   │                          └─► Fase 5 Delivery externo (M02)
   │
   └─► Fase 6 M08 dashboard y Service Desk (necesita datos de las fases 3 y 4)
```

Las fases 2, 3 y 4 pueden avanzar en paralelo una vez cerrada la fase 1, salvo que 3 necesita la lectura de configuración de la 2 (puede mockearse al inicio).

## 2. Fase 1: fundaciones transversales (M)

| Tarea | Detalle | Tamaño |
|---|---|---|
| Outbox y bus de eventos durable | Tabla de eventos con `event_id`, `occurred_at` UTC, versión, `correlation_id`; procesamiento idempotente y recuperable | M |
| `lifecycle_instance_id` por objeto | Estrategia por tipo (ver tabla) y persistencia | M |
| `reporting_timezone` | Config de plataforma versionada, IANA | S |
| Convenciones | Nombres de campos del contrato (`situation_id`, `lifecycle_instance_id`, `owner_module`) y tipos compartidos | S |

Casos de `lifecycle_instance_id` que hay que resolver (hallazgo del contraste):
- **Reabribles:** patrón de fuga que se recalcula (M05), plan de recuperación reinsertado (M05), pago con `undoPaid` (M06), deuda con posible cierre (M04).
- **M05 Mis Avisos:** el unique de `mis_avisos_situation` incluye `period_month`, así que un mes nuevo es una situación nueva. Hay que decidir si eso es un lifecycle nuevo o una continuación.
- **Únicos por usuario:** onboarding inicial y habilitar notificaciones, con tope de un award de por vida.

## 3. Fase 2: M08 núcleo (L)

| Tarea | Detalle | Tamaño |
|---|---|---|
| Roles y autorización | Roles Directivo/Producto y Service Desk, `RolesGuard` y `@Roles`, autorización efectiva en backend. Hoy no hay guard y los roles actuales son `super_admin`, `operator` y `user` | M |
| Auditoría | Servicio común y entidad completa: actor, rol, acción, antes y después, versiones, `correlation_id`. Hoy solo hay SQL crudo en la supresión de cuenta, y la FK es `SET NULL` | M |
| Config versionada inmutable | `config_id`, `owner_module`, `owner_rule_ref`, `status` EDITABLE/PROTECTED/CONDITIONAL, `version`, `effective_from`, `changed_by`, `reason`, `previous_version`, `audit_ref`. Hoy `rule_parameter` se modifica por `UPDATE` | L |
| Invariantes de grupos | 10 grupos del contrato (M04, M05, M06, Gamificación) con guardado atómico y `against_version` | M |
| Publicación a dueños | Evento de versión nueva y consumo en M04, M05 y M06 con recálculo solo de su estado vigente | M |
| Gamificación en M08 | `global_enabled`, `points_per_task`, `monthly_goal` publicados al motor | S |
| Alinear valores | M05 hoy 80/100 en `app_config`, el contrato pide 50/80/90/100/110. Migración sin pisar cambios del admin (el seed usa `ON CONFLICT DO UPDATE`) | S |

Fuera de esta fase: Break Glass y MFA (condicionados por el contrato).

## 4. Fase 3: motor de Gamificación (L)

| Tarea | Detalle | Tamaño |
|---|---|---|
| Modelo nuevo | Allowlist/catálogo versionado de 16 reglas, `owner_action_event` procesados (idempotencia por `event_id`), `AwardLedger` append-only con `award_key` único, config versionada, `ProgressSnapshot` | L |
| Procesamiento | COMPLETED y REVERSED según el pseudocontrato: allowlist, config y período por `occurred_at`, OFF sin backfill, compensación en el período original | M |
| Anti-stacking | Precedencias M05 (F2 sobre F1) y M06 (Pagado > baja confianza > genérico); dedupe cross-rule de M04 pendiente de Walvy | M |
| Snapshot y freshness | `source_watermark`, FRESH/STALE/NO_EVALUABLE, endpoint de lectura para M03 | M |
| Seguridad y PD | Aislamiento por usuario, minimización, retención y supresión (alcanza ledger, snapshots y colas) | M |
| Tablas legacy | Decidir y ejecutar migrar/ignorar/borrar (D4) | S |
| Evidencia | 20 BDD y 15 controles `GAM-TEC`, hoja `03_Evidencia_Kabeli` | L |

### 3b. Emisión desde los dueños (un PR por módulo)

| Módulo | Reglas | Estado del código | Trabajo |
|---|---|---|---|
| M01 | 001 | No existe la transición de cierre | Definir y construir el cierre del onboarding (ver pregunta 6), luego emitir |
| M02 | 001, 002, 004 | Upsert de perfil sin marca de completado; sin método de Disponible; no distingue habilitar de cambiar preferencia | Definir el work item F1 y F2, detectar permiso efectivo del SO, emitir |
| M04 | 001A, 002, 006, 008 | 001A, 006 y 008 tienen punto claro; 002 no tiene transición | Emitir en `debts.service.ts:418`, `route.service.ts:64` y `:68`; definir 002 |
| M05 | 001, 002, 006, 008 | 002, 006 y 008 tienen punto; 001 no | Cuidar el patrón recalculable y el plan reinsertado; definir 001 |
| M06 | 002, 005, 006, 007 | 002, 005 y 007 tienen punto y reversión; 006 no | Emitir con REVERSED en `undoPaid` y `reverseSettlement`; definir 006 |

## 5. Fase 4: M03 y Avisos (L)

| Tarea | Detalle | Tamaño |
|---|---|---|
| Modelo nuevo | `situation` (envelope normalizado), proyecciones por superficie, estado de Campana (`read_state`, `critical_active`, `first_exposed_at`, `display_state_group`, `topic_key`), History con `history_expires_at` | L |
| Ingesta idempotente | Misma identidad + versión + payload = no-op; payload distinto = `VERSION_CONFLICT`; evento viejo no reabre | M |
| Catálogo Maestro | Carga de las 57 fichas desde el XLSX (`13_Comm_Registry`), lookup por terna owner/family/variante, validación automática contra el docx | M |
| Acción principal | 7 etapas, M04 > M06 > M05, desempate por deadline, 0 o 1 `HOME_PRIMARY`, determinista | L |
| Superficies y dedupe | 9 `surface_key`, `home_density` y `home_alert_state`, supresión de réplicas de mismo propósito | M |
| Endpoints | Home, Campana (current, otros, history, marcar leído) y widgets con `ZERO_REAL` / `MISSING` / `NOT_EVALUABLE` | M |
| Gamificación en M03 | Solo lee `ProgressSnapshot`; falla cerrado solo esa proyección | S |
| Tablas legacy | Deprecar la cola y las preferencias actuales; `evaluateAndEnqueue` es código muerto | S |

### 4b. Adaptadores por dueño al envelope

| Módulo | Fuente actual | Trabajo |
|---|---|---|
| M04 | `debt_situation` (F1-F7) | Mapear `familia`/`estado`, agregar `version`, `lifecycle_instance_id` y `material_variant_code`; REENGAGEMENT_DUE para F4 |
| M05 | `mis_avisos_situation` (F1-F3) más F4/F5 en otras tablas | Varias fuentes; resolver el problema de `period_month`; variantes U03-U06b |
| M06 | `payment-tracking` | Falta productor completo de F1-F7; estados `OVERDUE` y `OVERDUE_CRITICAL` |
| M02 | Preferencias y perfil | Familias F1-F5 y las guías de contexto (Foco, mensual a anual, configuración) |
| M01 | Onboarding | Solo eventos operacionales `OP_READY` y `OP_FAIL` |

## 6. Fase 5: delivery externo (L)

| Tarea | Detalle | Tamaño |
|---|---|---|
| Registro de dispositivos | Tokens y proveedor de push; hoy no existe | M |
| `external_delivery_candidate` | Emisión desde M03 con elegibilidad por variante | S |
| Ciclo de comunicación | M02 crea `communication_cycle_id` opaco; un solo canal principal por ciclo | M |
| Gates de M02 | Preferencia, consentimiento y permiso, cadencia, cooldown, dedupe | L |
| Email de comunicaciones | Plantillas distintas del email transaccional de auth; 11 fichas con Email condicionado | M |
| Reachability | `in_app_reached_current_version` con interacción rastreable | M |

## 7. Fase 6: M08 dashboard y Service Desk (L)

| Tarea | Detalle | Tamaño |
|---|---|---|
| Dashboard | 14 KPIs con temporalidad propia, numerador, denominador y `source_refs`; sin fuente igual a N/D | L |
| Service Desk | `restore_access` y `escalate`, con `support_disposition` y `access_state` desde Identidad | M |
| Administradores | `grant_role` / `change_role` / `revoke_role`, idempotentes, con rechazo de autogestión peligrosa | M |

Depende de datos de las fases 3 y 4 (adopción, activación de Ruta) y de billing (suscripciones, ingresos, LTV).

## 8. Riesgos transversales
- **Sin outbox, el contrato de idempotencia no se puede garantizar.** Es la decisión D2.
- **Las transiciones que hoy no existen** (M01-001, M04-002, M06-006) bloquean 3 de las 16 reglas. Probablemente también M02-002 y M05-001.
- **Divergencia `main` frente a `qa`.** Construir sobre una hereda un conjunto de commits que la otra no tiene.
- **Evidencia obligatoria.** Para Gamificación y M08, Kabeli devuelve build, ambiente, fixtures y evidencia por control. El contrato no considera cumplido lo que no esté evidenciado.
- **M08 figura como "candidato, no enviado".** Puede cambiar antes de la entrega formal.

## 9. Lo que no se revisó
Anexos BDD de M03 y M08, hojas `BDD_Interfaces_*`, matrices de Protección de Datos, `HANDOFF_RESPUESTA_MATRICES`, el catálogo data-ready de M03 y las matrices de trazabilidad. Ahí están los payloads exactos, las clasificaciones de datos y los casos de prueba, y condicionan el diseño fino de cada fase.
