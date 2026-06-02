# Documentación — Arquitectura AWS Walvy

> Versión: 2026-04-26  
> Referencia visual: `walvy_aws_architecture.png` (generado por `walvy_aws_architecture.py`)

---

## Índice

1. [Visión general](#1-visión-general)
2. [Capa de Clientes](#2-capa-de-clientes)
3. [Capa Edge](#3-capa-edge)
4. [Core API — ECS Fargate](#4-core-api--ecs-fargate)
5. [Capa de Datos](#5-capa-de-datos)
6. [Capa de Integración Bancaria](#6-capa-de-integración-bancaria--aislada)
7. [Observabilidad](#7-observabilidad)
8. [Servicios Externos](#8-servicios-externos)
9. [Convención de colores del diagrama](#9-convención-de-colores-del-diagrama)
10. [Principios de diseño](#10-principios-de-diseño)
11. [Variables de entorno por servicio](#11-variables-de-entorno-por-servicio)

---

## 1. Visión general

Walvy es una aplicación de finanzas personales compuesta por un backend NestJS y un frontend React Native / Expo Web. La arquitectura en AWS está dividida en **7 capas funcionales** con un principio central: **las integraciones con bancos y pagos operan completamente aisladas del core**, de modo que una falla externa nunca compromete la disponibilidad de la aplicación.

```
Clientes
   ↓
Edge (WAF · CloudFront · S3 · ALB)
   ↓
Core API (ECS Fargate · NestJS)
   ↓              ↓
Datos         Integración Bancaria (aislada — async)
(RDS · Redis    (SQS · Lambda · DLQ · API Gateway)
 · Secrets)          ↓
                 Externos
              (Flow.cl · Bancos)
   ↓
Observabilidad (CloudWatch · SNS)
```

---

## 2. Capa de Clientes

| Nodo | Descripción |
|---|---|
| **Walvy Mobile** | App React Native compilada con Expo. Se conecta directamente al ALB vía HTTPS. Soporta iOS y Android. |
| **Walvy Web** | SPA construida con Expo Router (`expo export --platform web`). El navegador descarga el bundle desde CloudFront/S3 y las llamadas a la API van hacia el mismo ALB. |

**Flujo de entrada:**
- Mobile → WAF → ALB → Core API
- Web → CloudFront → S3 (assets estáticos) / ALB (llamadas `/api/*`)

---

## 3. Capa Edge

Es la frontera pública de la infraestructura. Todo lo que no pase por aquí no alcanza el core.

### WAF — Web Application Firewall

Protege el ALB antes de que cualquier request llegue al servidor. Configurado con:

- Reglas **OWASP Top 10** (inyección SQL, XSS, etc.)
- **Rate limiting** por IP (previene brute force en `/auth/login` y `/auth/forgot-password`)
- Bloqueo de rangos de IPs maliciosas conocidos (listas gestionadas por AWS)

> El WAF solo aplica al tráfico de la app mobile. El tráfico web pasa primero por CloudFront (que tiene su propia capa de protección).

### CloudFront — CDN

Distribuye el frontend web globalmente con baja latencia. Dos orígenes configurados:

| Patrón de ruta | Origen | Qué sirve |
|---|---|---|
| `/` (y rutas SPA) | S3 Bucket | Bundle estático de Expo Web |
| `/api/*` | ALB | Proxy a la API de NestJS |

CloudFront también termina TLS (HTTPS), cachea assets con headers `Cache-Control: immutable` y comprime respuestas con Gzip/Brotli.

### S3 — Almacenamiento del Web Build

Contiene el output de `npx expo export --platform web` (directorio `dist/`). Es un bucket privado — solo CloudFront tiene acceso mediante Origin Access Control (OAC). No es un sitio web público de S3.

La variable `EXPO_PUBLIC_BACKEND_BASE_URL` se hornea en el bundle en tiempo de build (ver `Dockerfile`).

### ALB — Application Load Balancer

Distribuye tráfico HTTPS hacia las tareas ECS del Core API. Gestiona:

- Certificados TLS (via ACM — AWS Certificate Manager)
- Health checks a `/health` del NestJS
- Routing al target group del servicio ECS

---

## 4. Core API — ECS Fargate

El corazón de la aplicación. Corre como contenedor Docker en **ECS Fargate** (serverless de contenedores — no hay EC2 que administrar).

### NestJS API

Contiene todos los módulos de negocio:

| Módulo | Responsabilidad |
|---|---|
| `auth` | Registro, login, JWT (access + refresh con rotación), reset de contraseña |
| `cashflow` | Transacciones, categorías, subcategorías, fuentes de financiamiento |
| `users` | Perfil de usuario, cambio de contraseña autenticado |
| `subscriptions` | Planes, suscripciones, órdenes de pago (coordina con Flow vía SQS) |
| `mail` | Envío de emails (reset, confirmaciones) via SMTP |
| `health` | `GET /health` → `{ ok: true }` — usado por ALB y por el probe del frontend |

### Docker Container

La imagen de producción es multi-stage (`Dockerfile` del repo):
1. **Stage `deps`** — `npm install`
2. **Stage `builder`** — `npm run build` + `npm prune --omit=dev`
3. **Stage `runner`** — `node:20-bookworm-slim` + `dumb-init` + usuario no-root

### Auto-scaling

ECS escala las tareas automáticamente basado en:
- CPU > 70% → agrega tareas
- Memory > 80% → agrega tareas
- Mínimo: 1 tarea | Máximo: configurable según carga esperada

---

## 5. Capa de Datos

Todos los componentes de datos viven en **subnets privadas** — no tienen IP pública ni son accesibles desde internet.

### RDS PostgreSQL 16 (Multi-AZ)

Base de datos principal. Tablas clave:

| Tabla | Contenido |
|---|---|
| `users` | Identidad: email, first_name, last_name, rut (opcional) |
| `refresh_tokens` | Tokens de refresco hasheados (rotación JWT) |
| `password_reset_tokens` | Tokens de reset con expiración |
| `funding_sources` | Cuentas bancarias / fuentes del usuario |
| `categories` / `subcategories` | Árbol de categorías de gastos |
| `transactions` | Movimientos financieros con categorization_status |
| `subscription_plans` / `subscriptions` | Planes y suscripciones activas |
| `payment_orders` | Órdenes de pago con estado (Flow) |

**Multi-AZ** significa que AWS mantiene una réplica sincrónica en otra zona de disponibilidad. Si la instancia primaria falla, el failover es automático (~30-60 segundos) sin cambiar el endpoint de conexión.

### ElastiCache Redis

Caché en memoria para datos de corta vida:
- **Sesiones** (si se implementa server-side sessions)
- **Rate limiting** distribuido (para throttling de auth)
- **Caché de respuestas** frecuentes (categorías, planes de suscripción)

Evita golpear RDS en cada request para datos que cambian poco.

### Secrets Manager

Almacena todas las credenciales sensibles. El Core API las lee al arrancar mediante `@nestjs/config`. **Nunca se pasan como variables de entorno hardcodeadas en el Dockerfile ni en el docker-compose de producción.**

Secretos gestionados:

| Secret | Valor |
|---|---|
| `DATABASE_URL` | Connection string de RDS |
| `JWT_SECRET` | Clave de firma para tokens |
| `FLOW_API_KEY` | API key de Flow.cl |
| `FLOW_SECRET_KEY` | Secret key de Flow.cl |
| `SMTP_*` | Credenciales de correo |

---

## 6. Capa de Integración Bancaria — AISLADA

Esta capa es la garantía técnica central de la arquitectura: **el Core API nunca llama directamente a bancos ni a Flow**. Toda comunicación es asíncrona a través de SQS.

> **Principio:** una falla bancaria (timeout, 503, mantenimiento) no puede bloquear un request de usuario en el Core API.

### API Gateway — Webhooks entrantes

Recibe notificaciones push desde Flow.cl:
- `confirm_url` → Flow notifica que un pago fue procesado
- `return_url` → usuario vuelve desde el flujo de pago de Flow

Estos webhooks llegan directamente a `Lambda Flow Payments` sin pasar por el Core API, lo que garantiza que Flow siempre puede notificar aunque el core esté bajo carga.

### SQS FIFO — `bank-sync-queue`

Cola de mensajes que actúa como **buffer entre el Core y las Lambdas**. El Core encola una tarea y responde al usuario inmediatamente — no espera al banco.

Características de la cola:
- **FIFO**: garantiza orden de procesamiento por usuario
- **Visibilidad**: mensaje invisible para otros consumidores mientras se procesa
- **Reintentos**: configurable (recomendado: 3 intentos con backoff exponencial)
- **Mensaje de ejemplo:**
  ```json
  {
    "userId": "uuid-del-usuario",
    "bankId": "banco_estado",
    "type": "balance_sync",
    "attempt": 1,
    "enqueuedAt": "2026-04-26T21:00:00Z"
  }
  ```

### SQS DLQ — `failed-bank-ops`

Dead Letter Queue: cuando un mensaje falla los N reintentos configurados en la cola principal, SQS lo mueve aquí automáticamente. Sirve para:

- **Auditoría**: registro de todas las sincronizaciones fallidas
- **Replay manual**: un operador puede mover mensajes de vuelta a la cola principal
- **Alarma**: CloudWatch monitorea `ApproximateNumberOfMessagesVisible > 0` y dispara una alerta a ops

### Lambda — Flow Payments

Función serverless que procesa pagos con Flow.cl:

**Triggers:**
- Mensajes en `bank-sync-queue` con `type: "payment_*"`
- Webhooks entrantes desde API Gateway (`confirm_url`)

**Responsabilidades:**
- Crear órdenes de pago en Flow (`POST /payment/create`)
- Confirmar pagos recibidos (`POST /payment/getStatus`)
- Actualizar `payment_orders` y `subscriptions` en RDS
- En caso de falla → NACK → mensaje va a DLQ + log en CloudWatch

### Lambda — Bank Sync

Función serverless que sincroniza movimientos bancarios:

**Triggers:**
- Mensajes en `bank-sync-queue` con `type: "balance_sync"`
- EventBridge scheduled rule cada 15 minutos (re-encola usuarios con `sync_status: "pending"`)

**Responsabilidades:**
- Obtener cartolas/saldos desde API bancaria (Fintoc) o SFTP
- Insertar transacciones nuevas en RDS
- Actualizar `last_sync_at` y `sync_status` del usuario
- En caso de falla → NACK → mensaje va a DLQ + log en CloudWatch

**Estados de sincronización (`sync_status`):**

| Estado | Significado | UX en App |
|---|---|---|
| `synced` | Datos actualizados | Sin aviso, datos frescos |
| `pending` | En cola o en curso | Banner amarillo: "Actualizando..." |
| `failed` | Reintentos agotados | Banner rojo: "Última actualización: hace X. Sincronización pendiente." |

---

## 7. Observabilidad

### CloudWatch

Centraliza todos los logs, métricas y alarmas de la infraestructura.

**Fuentes de logs:**
- Core API (NestJS) → structured JSON logs
- Lambda Flow Payments → logs de cada ejecución
- Lambda Bank Sync → logs de sincronización
- SQS DLQ → mensajes fallidos (alarm trigger)

**Formato de log estándar (JSON estructurado):**
```json
{
  "level": "ERROR",
  "event": "bank_sync_failed",
  "userId": "uuid",
  "bankId": "banco_estado",
  "attempt": 3,
  "error": "ConnectTimeoutError: 8000ms",
  "timestamp": "2026-04-26T21:00:00Z",
  "service": "lambda-bank-sync"
}
```

**Alarmas configuradas:**

| Alarma | Condición | Acción |
|---|---|---|
| DLQ con mensajes | `DLQ.ApproximateNumberOfMessages > 0` | SNS → alerta ops |
| Errores 5xx Core | `ALB.HTTPCode_Target_5XX_Count > 10/min` | SNS → alerta ops |
| Latencia alta | `ALB.TargetResponseTime p99 > 2s` | SNS → alerta ops |
| Fallas de sync | `bank_sync_failed rate > 10/min` | SNS → posible outage bancario |
| Lambda errores | `Lambda.Errors > 0` (por función) | SNS → alerta ops |

### SNS — Simple Notification Service

Distribuye las alarmas de CloudWatch al equipo de operaciones vía:
- Email
- Slack (mediante suscripción HTTPS a webhook)
- PagerDuty (si se configura on-call)

---

## 8. Servicios Externos

Estos servicios viven **fuera de la VPC** y se acceden exclusivamente desde las Lambdas, nunca desde el Core API directamente.

### Flow.cl

Pasarela de pago chilena. Integración:
- **Lambda → Flow**: crear orden de pago, consultar estado
- **Flow → API Gateway**: webhook `confirm_url` al confirmar un pago

Credenciales almacenadas en Secrets Manager (`FLOW_API_KEY`, `FLOW_SECRET_KEY`).
Ambiente sandbox: `https://sandbox.flow.cl/api`
Ambiente producción: `https://www.flow.cl/api`

### APIs Bancarias (Fintoc / SFTP)

Para obtención de cartolas y saldos:
- **Fintoc**: API REST para bancos chilenos (BancoEstado, BCI, Santander, etc.)
- **SFTP**: descarga directa de archivos de cartola para instituciones que no tienen API REST

Timeout configurado en Lambda: **8 segundos** (consistente con `PROBE_TIMEOUT_MS` del frontend). Si el banco no responde en ese tiempo → falla controlada → DLQ.

---

## 9. Convención de colores del diagrama

| Color | Tipo de flecha | Significado |
|---|---|---|
| Azul (`#1976D2`) sólido | HTTPS | Tráfico de red cliente-servidor |
| Naranja (`#FF6D00`) grueso | async / SQS | Comunicación desacoplada hacia la integración bancaria |
| Rojo (`#D32F2F`) discontinuo | NACK → DLQ | Falla de Lambda, mensaje va a Dead Letter Queue |
| Morado (`#7B1FA2`) punteado | logs | Envío de logs/métricas a CloudWatch |
| Gris (`#455A64`) discontinuo | secretos | Lectura de credenciales desde Secrets Manager |

---

## 10. Principios de diseño

### Desacoplamiento bancario total
El Core API **nunca hace una llamada HTTP directa** a un banco o a Flow. Solo encola mensajes en SQS. Las Lambdas son las únicas que hablan con externos. Esto garantiza:
- El core responde en < 200ms sin importar el estado del banco
- Una Lambda puede fallar y reintentarse sin afectar otros usuarios
- Los fallos quedan auditados en DLQ + CloudWatch

### Subnets privadas para datos
RDS, ElastiCache y Secrets Manager no tienen endpoint público. Solo son accesibles desde dentro de la VPC (ECS y Lambdas en el mismo VPC). Esto elimina una clase entera de vectores de ataque.

### Separación dev / prod
La arquitectura local (docker-compose) replica el stack sin los servicios AWS gestionados:

| Prod (AWS) | Local (Docker) |
|---|---|
| RDS PostgreSQL | PostgreSQL container |
| ECS Fargate | docker-compose `api` service |
| CloudFront + S3 | `npx expo start --web` (dev) / nginx (staging local) |
| SQS + Lambda | Mocks o servicios locales |
| Secrets Manager | Variables en `.env` (nunca commitear) |

### Sin Rork en producción
El frontend usa `withRorkMetro` de `@rork-ai/toolkit-sdk` únicamente en desarrollo (cuando `RORK_DISABLE` no está definido). El `Dockerfile` de producción siempre setea `RORK_DISABLE=true`, por lo que el bundle de S3 **no incluye ningún código de Rork**.

---

## 11. Variables de entorno por servicio

### Core API (ECS / docker-compose)

| Variable | Descripción | Ejemplo |
|---|---|---|
| `DATABASE_URL` | Connection string PostgreSQL | `postgresql://user:pass@host:5432/db` |
| `JWT_SECRET` | Clave de firma JWT (min 32 chars) | string aleatorio |
| `JWT_EXPIRES_IN` | TTL del access token | `15m` |
| `REFRESH_EXPIRES_DAYS` | TTL del refresh token | `7` |
| `CORS_ORIGIN` | Origen permitido (frontend) | `https://app.walvy.cl` |
| `FLOW_API_KEY` | API key de Flow.cl | desde Secrets Manager |
| `FLOW_SECRET_KEY` | Secret key de Flow.cl | desde Secrets Manager |
| `FLOW_API_URL` | URL del API de Flow | `https://www.flow.cl/api` |
| `FLOW_CONFIRM_URL` | URL webhook de confirmación | `https://api.walvy.cl/subscriptions/webhook` |
| `FLOW_RETURN_URL` | URL de retorno post-pago | `https://app.walvy.cl/subscription/result` |
| `SEED_CASHFLOW` | Sembrar categorías al arrancar | `false` |

### Frontend (Expo — baked en build time)

| Variable | Descripción | Ejemplo |
|---|---|---|
| `EXPO_PUBLIC_BACKEND_BASE_URL` | URL base del Core API | `https://api.walvy.cl` |
| `EXPO_PUBLIC_USE_MOCK_MODE` | Forzar modo mock sin backend | `false` |
| `RORK_DISABLE` | Excluir SDK de Rork del bundle | `true` (siempre en Docker) |
