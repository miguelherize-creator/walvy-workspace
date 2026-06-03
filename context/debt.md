# Deuda Técnica — Walvy

**Última actualización:** 2026-05-14

Formato: `ID — Descripción — Estado — Bloqueante`

---

## Módulo 1 — Auth & Onboarding

### M1-DT-01 — Backoffice: gestión de estado de usuario
- **RF:** RF-09
- **Estado:** ❌ Sin implementar — `src/admin/` existe pero vacío
- **Bloqueante:** Sí — requiere M1-DT-02 (RBAC) primero
- **Endpoints pendientes:** `PATCH /admin/users/:id/status` · `DELETE /admin/users/:id`
- **Qué falta:** AdminModule con endpoints protegidos por rol `admin`. Soft delete siempre.

### M1-DT-02 — RBAC: enforcement de permisos
- **RF:** RF-11
- **Estado:** ❌ Sin middleware de enforcement (tablas y seeds existen)
- **Bloqueante:** No — independiente, pero bloquea M1-DT-01
- **Qué falta:** `RbacGuard` + decorador `@RequirePermission('resource:action')`. Cachear permisos por rol (TTL 5min).

### M1-DT-03 — Job: nivel de salud financiera
- **RF:** RF-12
- **Estado:** ❌ Sin job/cron
- **Bloqueante:** Sí — bloqueado por Módulos 3 y 4 (cashflow y deudas deben existir primero)
- **Qué falta:** `@Cron()` en `src/health/` que calcule `current_financial_health_level_id` basado en transacciones + deudas.

### M1-DT-04 — Onboarding: alineación con flujo del cliente
- **RF:** RF-08
- **Estado:** ⚠️ Funciona parcialmente — no cierra nunca
- **Bloqueante:** Sí — bloqueado por M2-DT-01 (perfil financiero) y Módulo 3
- **Problemas concretos:**
  1. Auto-completado roto: exige `financialProfileCompleted = true` pero M2-DT-01 no está hecho → onboarding nunca termina
  2. `minDocThresholdMet` nunca se activa: no hay módulo de importación que lo escriba
  3. `currentStep` acepta strings libres sin validación `@IsIn([...])`
- **Qué falta:** Validar paso final con producto. Revisar si `financialProfileCompleted` sigue siendo condición. Añadir `@IsIn()` al DTO.

---

## Módulo 2 — Perfil y Configuración

### M2-DT-01 — Perfil financiero
- **RF:** RF-02
- **Estado:** ❌ Sin endpoints (entidad y tabla existen)
- **Bloqueante:** No — independiente, pero lo bloquea M1-DT-04
- **Endpoints pendientes:** `GET /profile/financial` + `PUT /profile/financial`
- **Qué falta:** `ProfileModule` con service + controller. DTO: `monthlyIncomeEstimate`, `stableExpensesNote`, `currencyId?`. Definir cómo se calcula `estimatedPaymentCapacity`.

### M2-DT-02 — Metas financieras
- **RF:** RF-03
- **Estado:** ❌ Sin endpoints (tabla `user_goals` existe)
- **Bloqueante:** No — independiente, diseño en borrador
- **Endpoints pendientes:** `GET /profile/goals` + `POST /profile/goals` + `PATCH /profile/goals/:id/deactivate`
- **Qué falta:** Definir si son múltiples focos activos simultáneos o solo uno. `progress_cache` es solo-escritura del backend.

### M2-DT-03 — Alertas y notificaciones
- **RF:** RF-04
- **Estado:** ❌ Sin endpoints (tabla `alert_preferences` existe)
- **Bloqueante:** Sí — sin M2-DT-04 (worker) las preferencias no tienen efecto real
- **Endpoints pendientes:** `GET /profile/alerts` + `PUT /profile/alerts`

### M2-DT-04 — Worker de notificaciones
- **RF:** RF-05
- **Estado:** ❌ Sin implementar
- **Bloqueante:** Sí — requiere definir canales push (FCM/APNs pendiente de scope)
- **Qué falta:** `NotificationQueueService.enqueue()` + worker `@Cron()` que procese `WHERE sent_at IS NULL AND scheduled_for <= now()`. Decidir canales MVP: ¿solo `in_app` + `email`, o también `push`?

---

## Cadena de bloqueos

```
M1-DT-02 (RBAC)
    └── bloquea M1-DT-01 (admin endpoints)

M2-DT-01 (perfil financiero)
    └── desbloquea M1-DT-04 (onboarding cierra)

Módulo 3 (cashflow) + Módulo 4 (deudas)
    └── desbloquean M1-DT-03 (job salud financiera)

M2-DT-04 (worker notificaciones)
    └── desbloquea M2-DT-03 (alertas con efecto real)
    └── desbloquea Sprint 7 (pagos recurrentes + push)
```

---

## Leyenda

| Símbolo | Significado |
|---------|-------------|
| ❌ | No implementado |
| ⚠️ | Implementado parcialmente |
| ✅ | Cerrado |
| Bloqueante: Sí | Hay otro módulo que depende de este |
