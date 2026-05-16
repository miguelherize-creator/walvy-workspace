# Plan de Evolución: Módulo 2 — Perfil de Usuario

> **Módulo:** `users` / `profile`
> **Sprint asociado:** M2 (Módulo 2)
> **Última revisión:** 2026-05-14

---

## Estado actual

- `GET /users/me`, `PATCH /users/me`, `PATCH /users/profile`, `PATCH /users/me/password`: implementados y funcionales
- Perfil financiero (`/profile/financial`): entidad en DB lista, sin endpoints ni pantalla
- Metas financieras (`/profile/goals`): entidad en DB en borrador, sin endpoints
- Alertas (`/profile/alerts`): entidad en DB, sin endpoints ni worker de notificaciones
- Worker de notificaciones (FCM/APNs): no implementado

---

## M2-DT-01: Perfil financiero

### Descripción

El perfil financiero almacena estimaciones del usuario sobre su situación económica. Es el contexto que Walvy usa para personalizar recomendaciones y calcular la capacidad de ahorro.

### Entidad en DB (ya existe)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `userId` | UUID | Relación con usuario |
| `monthlyIncomeEstimate` | Decimal | Estimación de ingresos mensuales en CLP |
| `stableExpensesNote` | Text | Nota libre sobre gastos fijos del usuario |
| `estimatedPaymentCapacity` | Decimal | Capacidad estimada de pago mensual en CLP |
| `createdAt` | Timestamp | Creación del registro |
| `updatedAt` | Timestamp | Última actualización |

### Endpoints a implementar

- `GET /profile/financial` — Retorna el perfil financiero del usuario
- `PUT /profile/financial` — Crea o actualiza el perfil financiero (upsert)

### Prerequisitos

- Diseño UX de la pantalla de perfil financiero aprobado por el cliente
- El paso del onboarding que activa `financialProfileCompleted` debe definirse

### Dependencias

- **Bloquea:** `financialProfileCompleted` en onboarding (M1-DT-04)
- **Bloquea:** M2-DT-02, M2-DT-03 (necesitan perfil financiero para personalizar)
- **Bloquea parcialmente:** Motor de recomendaciones (futuro)

---

## M2-DT-02: Metas financieras

### Descripción

Los usuarios pueden definir metas de ahorro o pago (ej: "ahorrar $500.000 para vacaciones", "pagar deuda en 6 meses"). Walvy puede hacer seguimiento y mostrar el progreso.

### Entidad en DB (borrador)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `userId` | UUID | Relación con usuario |
| `goalType` | Enum | `savings`, `debt_payoff`, `emergency_fund`, `custom` |
| `targetValue` | Decimal | Monto objetivo en CLP |
| `currentValue` | Decimal | Progreso actual |
| `deadline` | Date | Fecha límite (opcional) |
| `active` | Boolean | Si la meta está activa |

### Endpoints a implementar

- `GET /profile/goals` — Lista metas activas del usuario
- `POST /profile/goals` — Crea una nueva meta
- `PATCH /profile/goals/:id` — Actualiza una meta
- `PATCH /profile/goals/:id/deactivate` — Desactiva (soft delete) una meta

### Prerequisitos

- Diseño UX en borrador, pendiente de aprobación
- Reglas de negocio pendientes: ¿cuántas metas simultáneas? ¿se pueden tener múltiples del mismo tipo?
- Lógica de actualización automática de `currentValue` (¿quién la actualiza? ¿cashflow? ¿job?)

### Dependencias

- **Requiere:** M2-DT-01 (contexto financiero para metas relevantes)
- **Requiere:** Cashflow (Sprint 4) para actualizar progreso automáticamente

---

## M2-DT-03: Alertas y preferencias de notificación

### Descripción

Los usuarios pueden configurar qué tipos de alertas quieren recibir y por qué canal. Ej: alerta cuando el gasto en una categoría supera el 80% del presupuesto, notificación de suscripción próxima a vencer, etc.

### Entidad en DB (ya existe)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `userId` | UUID | Relación con usuario |
| `alertType` | Enum | `budget_threshold`, `debt_reminder`, `subscription_renewal`, `custom` |
| `channel` | Enum | `in_app`, `push`, `email` |
| `threshold` | Decimal | Umbral que activa la alerta (ej: 80% del presupuesto) |
| `active` | Boolean | Si la alerta está activa |

### Endpoints a implementar

- `GET /profile/alerts` — Lista configuración de alertas del usuario
- `PUT /profile/alerts` — Actualiza preferencias de alertas

### Prerequisitos

- M2-DT-04 (worker de notificaciones) para que las alertas tengan efecto real
- Definición de tipos de alertas MVP con el cliente

### Dependencias

- **Requiere:** M2-DT-04 para funcionar end-to-end
- **Requiere:** Presupuesto (Sprint 5) para alertas de umbral de categoría

---

## M2-DT-04: Worker de notificaciones

### Descripción

Servicio que procesa y envía notificaciones a los canales configurados:
- **Push:** Firebase Cloud Messaging (FCM) para Android, Apple Push Notification Service (APNs) para iOS
- **In-app:** Almacenadas en DB, recuperadas por la app en cada sesión
- **Email:** Integración con el servicio de email existente (MailService)

### Estado

Actualmente no existe worker de notificaciones. FCM y APNs requieren credenciales y configuración de dispositivos.

### Prerequisitos

- Obtener credenciales FCM (Firebase) y APNs (Apple Developer)
- Definir los canales MVP con el cliente (¿push en MVP o solo in-app + email?)
- Decidir si usar bull/BullMQ para jobs asíncronos o procesamiento síncrono

### Dependencias

- **Bloquea:** M2-DT-03 (alertas sin worker no tienen efecto)
- **Requiere:** Firebase project configurado
- **Requiere:** Apple Developer account con APNs configurado

---

## Orden de implementación recomendado

```
M2-DT-04 (worker básico in-app + email, sin push)
    └─ M2-DT-01 (perfil financiero, con diseño UX)
           └─ M2-DT-02 (metas financieras, con diseño UX)
                └─ M2-DT-03 (alertas, configuradas sobre M2-DT-04)
```

> Push (FCM/APNs) puede agregarse a M2-DT-04 cuando las credenciales estén disponibles, sin bloquear el resto.

---

## Dependencias externas

| Item | Bloqueado por | Estado |
|------|--------------|--------|
| M2-DT-01 | Diseño UX aprobado | Pendiente |
| M2-DT-02 | Diseño UX + reglas de negocio | Pendiente |
| M2-DT-04 (push) | Credenciales FCM + APNs | Pendiente |
| M2-DT-03 | M2-DT-04 funcional | Bloqueado |
