# Arquitectura AWS — Walvy

> Versión: 2026-04-26 | Entorno: producción

## Diagrama general

```mermaid
graph TB
    classDef client   fill:#00BCD4,stroke:#0097A7,color:#fff,font-weight:bold
    classDef edge     fill:#FF9900,stroke:#c47200,color:#fff
    classDef core     fill:#3F51B5,stroke:#283593,color:#fff,font-weight:bold
    classDef data     fill:#4CAF50,stroke:#2E7D32,color:#fff
    classDef integ    fill:#E91E63,stroke:#880E4F,color:#fff,font-weight:bold
    classDef observe  fill:#9C27B0,stroke:#4A148C,color:#fff
    classDef security fill:#607D8B,stroke:#37474F,color:#fff
    classDef external fill:#795548,stroke:#4E342E,color:#fff

    subgraph CLIENTS["Clientes"]
        MOBILE["Walvy Mobile\nReact Native / Expo"]
        WEB["Walvy Web\nExpo Router (SPA)"]
    end

    subgraph AWS["AWS — us-east-1 (VPC privada)"]

        subgraph EDGE["Edge / Distribución"]
            WAF["WAF\n(OWASP rules, rate limit)"]
            CF["CloudFront CDN\n(HTTPS, cache)"]
            S3["S3\n(static web build)"]
            ALB["Application Load Balancer\n(HTTPS :443)"]
        end

        subgraph CORE["Core — ECS Fargate (auto-scaling)"]
            API["NestJS API\nauth · cashflow · users\nsubscriptions · mail"]
        end

        subgraph DATA["Datos (subnets privadas)"]
            RDS[("RDS PostgreSQL 16\nwalvy_db\n(Multi-AZ)")]
            CACHE["ElastiCache Redis\n(sesiones / rate-limit)"]
        end

        subgraph INTEGRATION["Capa de Integración Bancaria — AISLADA"]
            APIGW["API Gateway\n(webhooks entrantes)"]
            SQS["SQS FIFO\nbank-sync-queue"]
            DLQ["SQS DLQ\nfailed-bank-ops"]
            LF["Lambda\nFlow Payments"]
            LB["Lambda\nBank Sync\n(cartolas / saldos)"]
        end

        subgraph OBS["Observabilidad"]
            CW["CloudWatch\nLogs · Alarms · Metrics"]
            SNS["SNS\nAlertas a ops"]
        end

        subgraph SEC["Seguridad / Configuración"]
            SM["Secrets Manager\n(DB, JWT, Flow keys)"]
        end

    end

    subgraph EXT["Externos"]
        FLOW_CL["Flow.cl\nPasarela de pagos"]
        BANKS["APIs Bancarias\n(Fintoc / SFTP)"]
    end

    %% Flujo cliente → core
    MOBILE  -->|HTTPS| WAF
    WEB     -->|HTTPS| CF
    CF      -->|origin GET /| S3
    CF      -->|origin /api/*| ALB
    WAF     --> ALB
    ALB     --> API

    %% Core ↔ datos
    API <-->|read/write| RDS
    API <-->|caché| CACHE
    API <-->|secretos| SM

    %% Core → integración (desacoplado, async)
    API -->|"enqueue { userId, type: sync }"| SQS

    %% Webhooks de pago entrantes
    APIGW -->|confirm_url| LF

    %% Lambdas consumen cola
    SQS --> LF
    SQS --> LB

    %% Fallos → DLQ
    LF -->|"NACK (retries agotados)"| DLQ
    LB -->|"NACK (retries agotados)"| DLQ

    %% Lambdas actualizan DB
    LF <-->|actualiza estado pago| RDS
    LB <-->|persiste movimientos| RDS

    %% Lambdas ↔ externos
    LF <-->|HTTP REST| FLOW_CL
    LB <-->|HTTP / SFTP| BANKS

    %% Observabilidad
    API --> CW
    LF  --> CW
    LB  --> CW
    DLQ --> CW
    CW  --> SNS

    %% Estilos
    class MOBILE,WEB client
    class WAF,CF,S3,ALB edge
    class API core
    class RDS,CACHE data
    class APIGW,SQS,DLQ,LF,LB integ
    class CW,SNS observe
    class SM security
    class FLOW_CL,BANKS external
```

---

## Descripción de componentes

### Edge
| Componente | Rol |
|---|---|
| CloudFront | CDN global, termina HTTPS, cachea el SPA de S3 |
| S3 | Sirve el bundle estático generado por `expo export --platform web` |
| ALB | Balanceo hacia ECS; gestiona certificados TLS de la API |
| WAF | Filtra tráfico malicioso (rate limit, reglas OWASP Top 10) |

### Core API (ECS Fargate)
NestJS desplegado en contenedores sin gestión de servidores. Auto-scaling basado en CPU/memory. Contiene los módulos: `auth`, `cashflow`, `users`, `subscriptions`, `mail`.

### Datos
| Componente | Rol |
|---|---|
| RDS PostgreSQL | Fuente de verdad. Multi-AZ para alta disponibilidad |
| ElastiCache Redis | Caché de sesiones y datos de corta vida |
| Secrets Manager | Credenciales, JWT secret, API keys de Flow — nunca en variables de entorno hardcodeadas |

### Capa de Integración Bancaria (aislada)
La capa de integración **no es parte del Core API**. Comunicación interna exclusivamente mediante mensajes (SQS FIFO), garantizando que una falla o latencia bancaria **nunca bloquea** el core.

| Componente | Rol |
|---|---|
| SQS FIFO `bank-sync-queue` | Buffer async entre Core y Lambdas |
| Lambda Flow Payments | Procesa pagos con Flow.cl (cargo, confirma, refund) |
| Lambda Bank Sync | Obtiene cartolas/saldos desde APIs bancarias |
| SQS DLQ `failed-bank-ops` | Captura mensajes fallidos tras N reintentos |
| API Gateway | Recibe webhooks entrantes de Flow (`confirm_url`, `return_url`) |

### Observabilidad
- **CloudWatch Logs**: todos los servicios loguean aquí (structured JSON)
- **CloudWatch Alarms**: alertas en `DLQ.ApproximateNumberOfMessagesVisible > 0`, errores 5xx, latencia p99
- **SNS**: notifica al equipo de ops cuando se dispara una alarma

---

## Notas de red
- ECS, RDS y ElastiCache viven en **subnets privadas** (sin IP pública)
- Las Lambdas están en la misma VPC para acceder a RDS sin internet
- Solo ALB y CloudFront tienen IPs/endpoints públicos
