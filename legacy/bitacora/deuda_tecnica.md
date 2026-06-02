# Deuda técnica — Backend Walvy MVP

**Última actualización:** 2026-05-14  
**Alcance:** solo deuda técnica del repositorio backend. No incluye pendientes de diseño, frontend ni coordinación de equipos.

---

## Módulo 1 — Auth & Onboarding

### M1-DT-01 — Backoffice: gestión de estado de usuario (`RF-09`)

| Campo | Valor |
|---|---|
| RF | RF-09 |
| Endpoints pendientes | `PATCH /admin/users/:id/status` · `DELETE /admin/users/:id` |
| Tablas | `app_user`, `status` |
| Estado | ❌ Sin endpoints |
| Bloqueante | No — independiente de otros módulos |

**Para qué sirve:** permite a un administrador suspender, reactivar o eliminar (soft-delete) una cuenta de usuario sin tocar la DB directamente. Necesario cuando un usuario reporta fraude, viola términos o pide baja.

**Por qué es deuda técnica:** backoffice no es prioridad para el MVP frontend. La carpeta `src/admin/` existe pero está vacía.

**Qué falta:**
- Endpoints protegidos por rol `admin`
- Suspender: `user_status_id = suspended` + `revokeAllRefreshForUser()`
- Eliminar: `deletedAt = now()` (nunca DELETE físico)

---

### M1-DT-02 — RBAC: enforcement de permisos (`RF-11`)

| Campo | Valor |
|---|---|
| RF | RF-11 |
| Tablas | `role`, `permission`, `role_permission` — sembradas |
| Estado | ❌ Sin middleware de enforcement |
| Bloqueante | No — independiente de otros módulos |

**Para qué sirve:** control granular de acceso por ruta y método HTTP según el rol del usuario (`user`, `admin`, `support`). Hoy todos los endpoints usan solo JWT guard — cualquier usuario autenticado puede llamar a cualquier ruta.

**Por qué es deuda técnica:** en MVP solo hay un rol activo (`user`). No hay rutas que requieran diferenciación hasta que exista backoffice o endpoints de soporte.

**Qué falta:**
- Guard o interceptor que valide `role → role_permission → permission` por ruta + método
- Las tablas y seeds ya existen — es solo la capa de enforcement

---

### M1-DT-03 — Job: nivel de salud financiera (`RF-12`)

| Campo | Valor |
|---|---|
| RF | RF-12 |
| Tablas | `app_user.current_financial_health_level_id`, `financial_health_levels` |
| Estado | ❌ Sin job/cron |
| Bloqueante | Sí — bloqueado por Módulos 3 y 4 (cashflow, deudas) |

**Para qué sirve:** job periódico que analiza transacciones, deudas y presupuesto del usuario y actualiza su "semáforo financiero" (`overwhelmed`, `transitioning`, `in_control`). El frontend muestra un avatar distinto según el nivel.

**Por qué es deuda técnica:** el cálculo depende de datos de cashflow (transacciones, categorías) y deudas que no existen todavía. Implementar antes sería calcular sobre vacío.

**Qué falta:**
- Job `@Cron()` en `src/health/` que calcule el nivel y escriba `current_financial_health_level_id` + `financial_health_updated_at`
- Lógica de cálculo a definir una vez estén implementados los Módulos 3/4

---

### M1-DT-04 — Onboarding: alineación con flujo del cliente (`RF-08`)

| Campo | Valor |
|---|---|
| RF | RF-08 |
| Endpoints | `PATCH /auth/onboarding/step` — existe pero con lógica incompleta |
| Estado | ⚠️ Funciona parcialmente — no alineado al cliente |
| Bloqueante | Sí — bloqueado por M2-DT-01 (perfil financiero) y Módulo 3 (importación) |

**Para qué sirve:** el backend guarda el progreso del onboarding paso a paso para que la app pueda retomar donde quedó si el usuario cierra la app. Al completar todos los checkpoints, el estado avanza a `completed` y el usuario queda en Home.

**Por qué es deuda técnica:** hay 3 problemas concretos que impiden cerrar el onboarding:

1. **La condición de auto-completado está rota:** el backend exige que `financialProfileCompleted = true` para marcar el onboarding como `completed`. Pero la pantalla de perfil financiero es deuda técnica (M2-DT-01) — ese flag nunca se activa. El onboarding **nunca puede auto-completarse** con la lógica actual.

2. **`minDocThresholdMet` no tiene quién lo active:** este flag debería ponerse en `true` cuando el usuario importa suficientes documentos. Hoy no hay ningún módulo de cashflow/importación implementado que lo escriba — queda en `false` para siempre.

3. **Los steps son strings libres sin validación:** `currentStep` acepta cualquier string. Los nombres de los pasos (`biometric_setup`, `profile_basic`, `welcome`, `document_upload`, `document_processing`) no están validados como enum en el DTO — el frontend puede enviar cualquier valor sin que el backend lo rechace.

**Qué falta para cerrarlo:**
- Validar con el cliente cuál es el paso final del onboarding y qué lo dispara como `completed`
- Revisar si `financialProfileCompleted` debe seguir siendo condición de completado o se elimina del check (igual que se hizo con `goalsSet`)
- Agregar `@IsIn([...])` al campo `currentStep` en el DTO una vez definidos los pasos finales
- Definir quién escribe `minDocThresholdMet = true` (¿módulo de importación? ¿manual desde el frontend?)

---

## Módulo 2 — Perfil y configuración

### M2-DT-01 — Perfil financiero (`RF-02`)

| Campo | Valor |
|---|---|
| RF | RF-02 |
| Endpoints pendientes | `GET /profile/financial` + `PUT /profile/financial` |
| Tabla | `user_financial_profile` |
| Estado | ❌ Sin endpoints |
| Bloqueante | No — independiente, pero sin pantalla de diseño aprobada |

**Para qué sirve:** permite al usuario declarar su ingreso mensual estimado y sus gastos fijos para que el backend calcule su capacidad de pago (`estimatedPaymentCapacity`). Base del diagnóstico financiero.

**Por qué es deuda técnica:** la pantalla "Mi perfil financiero" no está aprobada por diseño/producto. La entidad ya está lista con los transformers correctos.

**Qué falta:**
- `ProfileModule` con `profile.service.ts` y `profile.controller.ts`
- DTO `UpsertFinancialProfileDto`: `monthlyIncomeEstimate`, `stableExpensesNote`, `currencyId?`
- Definir cómo se calcula `estimatedPaymentCapacity` (¿% fijo del ingreso o campo numérico separado?)

---

### M2-DT-02 — Metas financieras (`RF-03`)

| Campo | Valor |
|---|---|
| RF | RF-03 |
| Endpoints pendientes | `GET /profile/goals` + `POST /profile/goals` + `PATCH /profile/goals/:id/deactivate` |
| Tabla | `user_goals` |
| Estado | ❌ Sin endpoints |
| Bloqueante | No — independiente, pero diseño en borrador |

**Para qué sirve:** el usuario define su "foco del mes" (reducir deuda, ahorrar X monto, mejorar capacidad de ahorro, etc.). El backend registra el objetivo y un job futuro actualiza el progreso (`progress_cache`).

**Por qué es deuda técnica:** el diseño de la pantalla "Mi foco del mes" está en borrador. La regla de negocio clave (¿uno o varios focos activos simultáneos?) no está validada con producto.

**Qué falta:**
- Endpoints en `ProfileModule`
- DTO `CreateGoalDto`: `goalType` (enum), `targetValue?` (requerido solo para `save_amount` y `reduce_debt`)
- `progress_cache` es solo-escritura del backend (job) — nunca en DTOs de entrada

---

### M2-DT-03 — Alertas y notificaciones (`RF-04`)

| Campo | Valor |
|---|---|
| RF | RF-04 |
| Endpoints pendientes | `GET /profile/alerts` + `PUT /profile/alerts` |
| Tabla | `alert_preferences` |
| Estado | ❌ Sin endpoints |
| Bloqueante | Sí — depende de M2-DT-04 (worker) para que las preferencias tengan efecto real |

**Para qué sirve:** el usuario configura qué avisos quiere recibir y por qué canal (vencimiento de pagos, umbrales de presupuesto, recordatorio semanal). Sin este endpoint, las preferencias no se persisten y el worker no puede respetarlas.

**Por qué es deuda técnica:** sin pantalla de diseño asignada. Además, tiene dependencia con el worker (M2-DT-04) — implementar las preferencias sin el worker que las consume es trabajo a medias.

**Qué falta:**
- `NotificationsModule` con service + controller
- DTO `UpsertAlertPreferencesDto`: `alertType` (enum), `channel` (enum: `in_app|push|email`), `enabled`, `intensity?`
- GET debe devolver defaults de `app_config` para tipos sin entrada propia en `alert_preferences`

---

### M2-DT-04 — Worker de notificaciones (`RF-05`)

| Campo | Valor |
|---|---|
| RF | RF-05 |
| Tipo | Proceso interno — sin endpoint de usuario |
| Tabla | `notification_queue` |
| Estado | ❌ Sin implementar |
| Bloqueante | Sí — bloqueado hasta definir canales push (FCM/APNs) |

**Para qué sirve:** proceso interno que lee la `notification_queue` y envía las notificaciones programadas al canal correspondiente (`in_app`, `email`, `push`). Es la capa de despacho de todos los avisos del sistema.

**Por qué es deuda técnica:** los canales de envío no están definidos para MVP. `push` requiere integración con FCM/APNs (Firebase/Apple) que está fuera de scope actual. Sin definir si `in_app` tiene tabla propia o usa `notification_queue` directamente.

**Qué falta:**
- `NotificationQueueService.enqueue()` — interfaz que otros módulos llaman para encolar alertas
- Worker `@Cron()` que procese `WHERE sent_at IS NULL AND scheduled_for <= now()`
- Decidir canales MVP: ¿solo `in_app` + `email`, o también `push`?

---

## Leyenda

| Estado | Significado |
|---|---|
| ❌ | No implementado |
| Bloqueante: Sí | No se puede implementar hasta que otro módulo esté listo |
| Bloqueante: No | Se puede implementar en cualquier momento cuando haya diseño/prioridad |
