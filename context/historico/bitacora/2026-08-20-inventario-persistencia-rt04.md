# Inventario de persistencia de aplicación con dato de usuario (RT-04.1)

**Fecha:** 2026-08-20  
**Baseline:** `back-walvy` `9bb604e` (`KabeliDev/main`)

Derivado del esquema, no redactado a mano: se extraen las claves foráneas hacia `app_user` y el `COMMENT ON TABLE` de cada tabla. Responde `RT-04.1` —«inventario por ambiente con owner, propósito y relación con lifecycle funcional»— y es insumo de `RT-04.4` y `RT-04.5`.

**55 tablas** tienen vínculo directo a `app_user`: 41 en cascada, 8 con desvinculación, **6 sin acción declarada**. 54 de 55 documentan su propósito en el esquema.


## `ON DELETE CASCADE` — 41 tablas

Se borra con el usuario. Es dato del usuario y no tiene vida propia sin él.

| Tabla | Columna | Soft delete | Propósito según el esquema |
|---|---|---|---|
| `ai_conversations` | `user_id` | — | L16 · Sesiones de conversación con el asistente IA. Una sesión agrupa todos los mensajes de un hilo. |
| `alert_preferences` | `user_id` | — | L6 · Sobreescrituras de preferencias de alerta del usuario. Solo se inserta una fila cuando el usuario cambia el default. Los defaults globales viven en app_config. Un worker lee esta tabla  |
| `ant_expense_rules` | `user_id` | — | L7 · Reglas de detección de gastos hormiga configuradas por usuario. Un movimiento es "hormiga" si su monto es ≤ max_amount y pertenece a la categoría indicada (o cualquiera si category_id e |
| `bills_payable` | `user_id` | — | Cuentas por pagar detectadas o registradas por el usuario. Propia del backend: el modelo entregado las resuelve con user_payment. Se conserva hasta acordar su destino. |
| `biometric_preferences` | `user_id` | — | L4 · Preferencias biométricas del usuario. Relación 1:1 con app_user. Se crea en el paso de setup biométrico del onboarding. |
| `budget_plan` | `user_id` | — | L10 · Plan de presupuesto mensual. Un plan por usuario por mes (UNIQUE user_id + period_month). El histórico se preserva indefinidamente. |
| `cashflow_node` | `owner_user_id` | — | L7 · Nodo semántico de origen o destino del dinero. Permite modelar transferencias entre cuentas propias, pagos a terceros, ingresos, etc. |
| `category` | `owner_user_id` | — | L7 · Categorías de movimientos con jerarquía recursiva. Reemplaza las tablas separadas categories + subcategories. parent_category_id NULL = categoría raíz. |
| `debt` | `user_id` | sí | L11 · Deuda del usuario. Motor bola de nieve: snowball_priority define el orden de pago. released_cashflow_amount es el flujo libre que se recupera al cerrar esta deuda. Soft-delete. |
| `debt_attachments` | `user_id` | — | L11 · Documentos adjuntos a una deuda (contratos, estados de cuenta, etc.). parsed_summary guarda el resultado del parsing automático por IA. |
| `debt_payoff_simulation` | `user_id` | — | L11 · Simulación de estrategia de pago bola de nieve. El usuario puede tener múltiples simulaciones (draft, active, archived). extra_monthly_payment es el abono extra mensual sobre el mínimo |
| `debt_projection` | `user_id` | — | Proyección condicionada de salida de deuda según M4 BDD T36/T37. |
| `email_verification_tokens` | `user_id` | — | L4 · OTPs de 6 dígitos para verificación de email. TTL 15 minutos, máximo 5 intentos. |
| `file_upload` | `user_id` | — | L8 · Registro de archivos subidos por el usuario (cartolas PDF, CSV, etc.). Ciclo de vida: uploaded → processing → processed | failed. El constraint chk_file_upload_counts garantiza que tota |
| `financial_health_snapshots` | `user_id` | — | Foto periódica del nivel de salud financiera de una cuenta. Propia del backend: permite ver la evolución del nivel en el tiempo, que financial_health_level por sí sola no guarda. |
| `financial_movement` | `user_id` | sí | L9 · Fuente de verdad transaccional. Cada movimiento de dinero del usuario vive aquí. Soft-delete (deleted_at). source_fingerprint con índice UNIQUE evita doble importación de la misma trans |
| `gamification_events` | `user_id` | — | L14 · Log inmutable de puntos otorgados a usuarios. Cada evento genera una fila. Nunca se modifica. |
| `message_event` | `user_id` | — | L15 · Instancia de un mensaje para un usuario específico. Un message_rule puede generar múltiples message_event a lo largo del tiempo. suppressed_until controla frecuencia para no mostrar el |
| `movement_classification_suggestions` | `user_id` | — | L8 · Sugerencias automáticas de clasificación generadas por la IA o reglas. El usuario siempre debe confirmar; nunca se aplican solas. |
| `movement_review_queue` | `user_id` | — | L9 · Cola de movimientos que requieren atención del usuario (sin categorizar, posible duplicado, conflicto de instrumento, etc.). priority_level 1 = más urgente. |
| `notification_queue` | `user_id` | — | L6 · Cola polimórfica de despacho de notificaciones. Cualquier módulo deposita notificaciones aquí; un worker las consume (WHERE sent_at IS NULL). No hay acoplamiento entre módulos y canales |
| `password_reset_tokens` | `user_id` | — | L4 · OTPs de 6 dígitos para reset de contraseña. TTL 15 minutos, un solo uso. |
| `payment_method` | `user_id` | — | L13 · Métodos de pago tokenizados del usuario o empresa. Sin datos PCI: solo tokens del gateway (Stripe, MercadoPago, Flow). SIN INICIAR en v1. |
| `payment_order` | `user_id` | — | L13 · Orden de pago al gateway. commerce_order es UNIQUE para garantizar idempotencia ante webhooks duplicados. IMPLEMENTADO en v1. |
| `recommendation_events` | `user_id` | — | Registro de recomendaciones mostradas al usuario y qué hizo con ellas. Propia del backend: antecede al bloque de señales y recomendaciones del modelo entregado. |
| `recurring_payment_suggestions` | `user_id` | — | L12 · Sugerencias de pagos recurrentes detectados por patrones en los movimientos del usuario. El usuario decide si los agrega a su agenda. |
| `refresh_tokens` | `user_id` | — | L4 · Tokens de refresh JWT. Almacenados como hash SHA-256. Rotación en cada uso. TTL 30 días. |
| `statement_imports` | `user_id` | — | Cargas de cartola del usuario y su procesamiento. Propia del backend: el modelo entregado la resuelve con file_upload. Ambas conviven hasta que se decida cuál queda; import_line_items apunta |
| `subscription` | `user_id` | — | L13 · Suscripción del usuario a un plan. Soporta B2B (company_id) y B2C. billed_amount es snapshot inmutable del precio cobrado. gift_token es UNIQUE cuando no es NULL. IMPLEMENTADO en v1. |
| `user_financial_instrument` | `user_id` | — | L7 · Cuentas y tarjetas del usuario vinculadas a una institución financiera. Es el origen o destino de los movimientos financieros. |
| `user_financial_profile` | `user_id` | — | L6 · Perfil financiero base declarado por el usuario. Relación 1:1 con app_user. Lo completa en el onboarding y puede actualizarlo. Alimenta el motor de deudas (campo estimated_payment_capac |
| `user_gamification_stats` | `user_id` | — | L14 · Caché de estadísticas de gamificación por usuario. Relación 1:1. Se actualiza de forma incremental (no recalcula desde 0). Permite mostrar el nivel y puntos sin agregar todos los event |
| `user_goals` | `user_id` | — | L6 · Metas financieras de largo plazo declaradas por el usuario. N metas por usuario. No tienen período mensual. |
| `user_message_interaction` | `user_id` | — | L15 · Registro de cómo el usuario interactuó con un mensaje. Afina el motor para personalizar qué mensajes mostrar. Inmutable. |
| `user_month_debt_priority_summary` | `user_id` | — | L18 CQRS · Ranking de deudas por prioridad bola de nieve, pre-computado por job batch. Alimenta la pantalla de Deudas. PK compuesta (user_id, month, debt_id). |
| `user_month_diagnosis_summary` | `user_id` | — | L18 CQRS · Diagnóstico financiero mensual pre-computado por job batch. Alimenta la pantalla Home: semáforo de salud, capacidad de ahorro, calidad del dato, próxima acción sugerida. No se esc |
| `user_month_leaks_summary` | `user_id` | — | L18 CQRS · Resumen de fugas del mes (gastos hormiga y patrones de fuga), pre-computado por job batch. Alimenta la pantalla Home con el widget de fugas. |
| `user_onboarding_state` | `user_id` | — | L4 · Estado del onboarding. Relación 1:1 con app_user. Permite retomar el flujo desde cualquier pantalla si el usuario abandona. |
| `user_payment` | `user_id` | — | L12 · Pago agendado del usuario (vencimiento de deuda, servicio, etc.). traffic_light_state indica proximidad del vencimiento. Puede generarse automáticamente desde debt (source=system). |
| `user_score_history` | `user_id` | — | L14 · Historial de puntos del usuario por período. Permite mostrar gráficos de evolución de puntos en el tiempo. |
| `user_upcoming_payments_summary` | `user_id` | — | L18 CQRS · Próximos pagos del usuario en una ventana de tiempo, pre-computados por job batch. Alimenta Home y la pantalla de Pagos. |

## `ON DELETE SET NULL` — 8 tablas

Sobrevive al usuario perdiendo el vínculo. Son registros que deben persistir sin identidad.

| Tabla | Columna | Soft delete | Propósito según el esquema |
|---|---|---|---|
| `?` | `generated_by_user_id` | sí | — |
| `app_config` | `updated_by_user_id` | — | L3 · Configuración global de la app, clave-valor tipado. Ajustable desde backoffice sin deploy. Los defaults de alertas viven aquí y son leídos cuando el usuario no tiene fila en alert_prefe |
| `audit_log` | `user_id` | — | L17 · Log de acciones de usuarios finales (no administradores). Para compliance y debugging de comportamientos inesperados. |
| `gamification_rules` | `updated_by_user_id` | — | L14 · Reglas de puntos por tipo de evento. Las reglas son datos (no código): agregar una regla = INSERT. Modificable desde backoffice sin deploy. |
| `legal_document_version` | `published_by_user_id` | — | Versiones publicadas de los documentos legales: Términos y Condiciones y Política de Privacidad. Una versión publicada es inmutable; cualquier cambio de contenido exige publicar una versión  |
| `movement_classification_history` | `changed_by` | — | L9 · Log inmutable de reclasificaciones de movimientos. Sirve para auditoría y para entrenar/mejorar el motor de clasificación automática. |
| `report_snapshots` | `generated_by_user_id` | — | L17 · Reportes pre-computados para el backoffice (MRR, churn, usuarios activos, etc.). Se generan por job periódico o bajo demanda. Evitan queries pesados en tiempo real. |
| `user_legal_acceptance` | `user_id` | — | Historial de solo inserción de la interacción de cada usuario con cada versión de un documento legal. Una fila por acción: presentada, aceptada o rechazada. Fuente histórica de la aceptación |

## `ON DELETE NO ACTION` — 6 tablas

BLOQUEA el borrado. Hoy impide que la supresión pueda ejecutarse.

| Tabla | Columna | Soft delete | Propósito según el esquema |
|---|---|---|---|
| `budget_recommendation` | `user_id` | — | Recomendaciones presupuestarias de Módulo 5. |
| `budget_signal` | `user_id` | — | Señales presupuestarias según M5 BDD T8/T12/T13. |
| `classification_learning_rule` | `user_id` | — | Reglas candidatas de aprendizaje controlado para clasificación de movimientos. Fuente: M5 BDD T9/T12 y guardrail T15R4. |
| `company_eligible_employee` | `activated_user_id` | — | L5 · Lista blanca de empleados elegibles para el beneficio. Se crea desde el backoffice antes de enviar invitaciones. |
| `intermodule_derivation` | `user_id` | — | Derivación controlada entre módulos según M5 BDD BDD-027/BDD-028 y Onboarding reglas modulares. |
| `movement_user_validation` | `user_id` | — | Validación de categorización de movimientos según M5 BDD T9/T12. |

## Lo que el inventario deja a la vista

El esquema documenta **dos modelos de eliminación incompatibles** y hoy no soporta ninguno completo.

- La migración 004 declara sobre `app_user.deleted_at`: *«Soft delete. Nunca se ejecuta DELETE físico en esta tabla.»*
- La migración 017 declara `ON DELETE SET NULL` en `user_legal_acceptance.user_id`, y lo justifica así: *«La eliminación de la cuenta pone user_id en NULL y conserva la fila con user_pseudonym… conserva la evidencia y permite suprimir la identidad.»*

El mecanismo de 017 **sólo dispara con un DELETE físico**, que 004 prohíbe. Las consecuencias son concretas:

1. **Con sólo soft delete**, las 41 cascadas quedan dormidas: marcar `deleted_at` en `app_user` no suprime nada aguas abajo. Los datos financieros del usuario siguen íntegros y atribuibles, y la seudonimización de la evidencia legal nunca se activa. No satisface `RT-04.5`.
2. **Con DELETE físico**, seis claves foráneas sin `ON DELETE` declarado lo hacen **fallar**: en PostgreSQL la ausencia equivale a `NO ACTION`.

O sea que la supresión que exige `TR-RET-01` no es hoy ejecutable por ninguna de las dos vías. No es una limitación técnica nuestra: es una contradicción interna del esquema, y resolverla es responsabilidad de Kabeli según `TR-DB-01` («modelo, esquema, migraciones, lifecycle y lógica de persistencia/supresión»).

### Las seis que bloquean, y qué dice su propio propósito

Cinco son dato derivado del usuario y no tienen sentido sin él: `budget_recommendation`, `budget_signal`, `classification_learning_rule`, `intermodule_derivation` y `movement_user_validation`. Su propósito documentado las ubica como salidas de M5 atribuibles al usuario, así que corresponden a cascada.

La sexta es distinta. `company_eligible_employee.activated_user_id` es, según el esquema, *«L5 · Lista blanca de empleados elegibles para el beneficio. Se crea desde el backoffice»*: es un registro de la empresa, no del usuario, y debe sobrevivir a su supresión perdiendo el vínculo. Corresponde a desvinculación, no a cascada — pero por tener carácter B2B y contractual conviene confirmarlo antes de migrar.
