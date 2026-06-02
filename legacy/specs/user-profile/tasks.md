# Tareas: Módulo 2 — Perfil de Usuario

> **Módulo:** `users` / `profile`
> **Sprint asociado:** M2
> **Última revisión:** 2026-05-14

---

## M2-DT-01: Perfil financiero

### [ ] Backend: GET /profile/financial + PUT /profile/financial

**Descripción:** Implementar los endpoints para leer y actualizar el perfil financiero del usuario. La entidad `FinancialProfile` ya existe en la base de datos.

**Prerequisito:** Diseño UX de la pantalla de perfil financiero aprobado por el cliente. No implementar sin diseño aprobado para evitar retrabajos en los contratos de API.

**Pasos:**
1. Crear `ProfileModule` o agregar al `UsersModule` (evaluar qué tiene más sentido según el scope final)
2. Crear `FinancialProfileDto` con validaciones class-validator
3. Implementar `GET /profile/financial` que retorne el perfil o un objeto vacío si no existe aún
4. Implementar `PUT /profile/financial` como upsert (crear si no existe, actualizar si existe)
5. Al completar el perfil financiero, activar checkpoint `financialProfileCompleted = true` en `UserOnboarding`
6. Retornar valores numéricos usando transformer `decimalToNumber`

**Archivos afectados:**
- `src/profile/profile.module.ts` (nuevo)
- `src/profile/profile.controller.ts` (nuevo)
- `src/profile/profile.service.ts` (nuevo)
- `src/profile/dto/update-financial-profile.dto.ts` (nuevo)
- `src/auth/` (activar checkpoint `financialProfileCompleted`)

**Bloqueante para:** M1-DT-04 (onboarding auto-complete), M2-DT-02, M2-DT-03

---

## M2-DT-02: Metas financieras

### [ ] Backend: GET /profile/goals + POST /profile/goals + PATCH /profile/goals/:id + PATCH /profile/goals/:id/deactivate

**Descripción:** Implementar CRUD de metas financieras del usuario. La entidad está en borrador; validar schema con el cliente antes de implementar.

**Prerequisito:** Diseño UX aprobado + reglas de negocio definidas (¿cuántas metas simultáneas?, ¿tipos exclusivos?, ¿actualización automática de progreso?).

**Pasos:**
1. Confirmar schema de la entidad `Goal` con el cliente
2. Crear `GoalDto`, `CreateGoalDto`, `UpdateGoalDto` con validaciones
3. Implementar endpoints con lógica de negocio según reglas acordadas
4. El endpoint `deactivate` debe hacer soft delete (marcar `active = false`, no eliminar físicamente)
5. `GET /profile/goals` retorna solo metas activas por defecto; query param `?includeInactive=true` para todas

**Archivos afectados:**
- `src/profile/goals/` (nuevos: module, controller, service, DTOs)

**Bloqueante para:** Lógica de progreso automático (requiere cashflow Sprint 4)

---

## M2-DT-03: Alertas y preferencias de notificación

### [ ] Backend: GET /profile/alerts + PUT /profile/alerts

**Descripción:** Endpoints para leer y actualizar la configuración de alertas del usuario.

**Prerequisito:** M2-DT-04 (worker de notificaciones) debe estar funcional para que las alertas tengan efecto real. Sin el worker, los endpoints se pueden implementar pero las alertas no se enviarán.

**Pasos:**
1. Confirmar tipos de alertas MVP con el cliente
2. Crear `AlertPreferencesDto` con validaciones
3. Implementar `GET /profile/alerts` que retorne la configuración actual
4. Implementar `PUT /profile/alerts` como upsert por tipo de alerta
5. Integrar con el worker de notificaciones (M2-DT-04) para disparar alertas

**Archivos afectados:**
- `src/profile/alerts/` (nuevos: module, controller, service, DTOs)
- Integración con `NotificationsModule` (M2-DT-04)

**Bloqueante:** Depende de M2-DT-04

---

## M2-DT-04: Worker de notificaciones

### [ ] Backend: definir canales MVP primero

**Descripción:** Antes de implementar el worker, definir con el cliente qué canales son obligatorios para MVP:
- **In-app:** Almacenadas en DB, app las consulta al cargar
- **Email:** Integración con MailService existente
- **Push (FCM/APNs):** Requiere credenciales externas, puede ir en sprint posterior

**Prerequisitos:**
- Decisión de canales MVP con el cliente
- Credenciales FCM si push es MVP
- Credenciales APNs si push es MVP

**Pasos (una vez definidos los canales):**
1. Crear `NotificationsModule` con servicio de despacho multi-canal
2. Implementar canal `in_app` (tabla `notifications` en DB, endpoint `GET /notifications`)
3. Implementar canal `email` usando `MailService` existente
4. Si push es MVP: integrar Firebase Admin SDK para FCM + configurar APNs
5. Implementar cola de jobs (BullMQ recomendado para reintentos y resiliencia)

**Archivos afectados:**
- `src/notifications/` (nuevo módulo completo)
- `src/profile/alerts/` (integración)

**Bloqueante para:** M2-DT-03, alertas presupuestarias (Sprint 5)

---

## Mejoras adicionales (no comprometidas)

### [ ] Frontend: Pantalla de perfil financiero

**Descripción:** Implementar la pantalla de perfil financiero en Expo una vez que el diseño esté aprobado y los endpoints M2-DT-01 estén implementados.

**Prerequisito:** Diseño UX aprobado + M2-DT-01 backend listo

### [ ] Frontend: Pantalla de metas financieras

**Descripción:** Implementar la pantalla de metas una vez que M2-DT-02 backend esté listo y el diseño aprobado.

**Prerequisito:** Diseño UX aprobado + M2-DT-02 backend listo
