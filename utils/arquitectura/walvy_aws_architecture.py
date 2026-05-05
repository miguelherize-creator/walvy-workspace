#!/usr/bin/env python3
"""
Walvy — AWS Cloud Architecture Diagram
=======================================
Genera un PNG del diagrama completo de arquitectura en AWS.

Instalación rápida:
    pip install -r requirements.txt

    # Graphviz (necesario para renderizar):
    #   macOS:   brew install graphviz
    #   Ubuntu:  sudo apt-get install graphviz
    #   Windows: https://graphviz.org/download/  → agregar al PATH

Uso:
    python walvy_aws_architecture.py
    → Genera: walvy_aws_architecture.png en este directorio
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS, Lambda
from diagrams.aws.database import RDS, ElastiCache
from diagrams.aws.network import CloudFront, APIGateway, ELB
from diagrams.aws.storage import S3
from diagrams.aws.integration import SQS, SNS
from diagrams.aws.management import Cloudwatch
from diagrams.aws.security import SecretsManager, WAF
from diagrams.onprem.client import Users
from diagrams.onprem.container import Docker

# ── Atributos visuales globales ──────────────────────────────────────────────
GRAPH = {
    "fontsize": "15",
    "bgcolor": "#F9F9F9",
    "pad": "0.75",
    "splines": "ortho",
    "nodesep": "0.9",
    "ranksep": "1.4",
    "fontname": "Helvetica",
}

EDGE_SYNC  = {"color": "#FF6D00", "style": "bold",   "label": "async / SQS"}
EDGE_FAIL  = {"color": "#D32F2F", "style": "dashed", "label": "NACK → DLQ"}
EDGE_LOG   = {"color": "#7B1FA2", "style": "dotted"}
EDGE_HTTP  = {"color": "#1976D2", "style": "bold"}
EDGE_SECRET = {"color": "#455A64", "style": "dashed", "label": "secretos"}

with Diagram(
    "Walvy — AWS Architecture",
    filename="walvy_aws_architecture",
    outformat="png",
    show=False,
    graph_attr=GRAPH,
    direction="TB",
):

    # ── 1. Clientes ──────────────────────────────────────────────────────────
    with Cluster("Clientes"):
        mobile  = Users("Walvy Mobile\nReact Native")
        browser = Users("Walvy Web\nExpo Router (SPA)")

    # ── 2. Edge / Distribución ───────────────────────────────────────────────
    with Cluster("Edge"):
        waf = WAF("WAF\nOWASP · rate-limit")
        cf  = CloudFront("CloudFront CDN\nHTTPS · cache")
        s3  = S3("S3\nStatic Web Build\n(expo export --platform web)")
        alb = ELB("Application\nLoad Balancer")

    # ── 3. Core API (ECS Fargate) ────────────────────────────────────────────
    with Cluster("Core API — ECS Fargate  (auto-scaling)"):
        docker = Docker("Docker Container")
        api    = ECS(
            "NestJS API\n"
            "auth · cashflow\n"
            "users · subscriptions · mail"
        )
        docker - api  # co-location visual

    # ── 4. Datos (subnets privadas) ──────────────────────────────────────────
    with Cluster("Datos  (subnets privadas)"):
        rds   = RDS("RDS PostgreSQL 16\nMulti-AZ")
        cache = ElastiCache("ElastiCache Redis\nsesiones · rate-limit")
        sm    = SecretsManager("Secrets Manager\nDB · JWT · Flow API keys")

    # ── 5. Capa de Integración Bancaria (AISLADA) ────────────────────────────
    with Cluster("Capa Integración Bancaria — AISLADA  ⚠️"):

        apigw = APIGateway("API Gateway\nwebhooks entrantes\n(Flow confirm_url)")

        with Cluster("Cola de tareas"):
            sqs = SQS("SQS FIFO\nbank-sync-queue")
            dlq = SQS("SQS DLQ\nfailed-bank-ops")

        with Cluster("Lambdas"):
            lf = Lambda("Lambda\nFlow Payments")
            lb = Lambda("Lambda\nBank Sync\ncartolas · saldos")

    # ── 6. Observabilidad ────────────────────────────────────────────────────
    with Cluster("Observabilidad"):
        cw  = Cloudwatch("CloudWatch\nLogs · Alarms · Metrics")
        sns = SNS("SNS\nAlertas a ops")

    # ── 7. Servicios externos ────────────────────────────────────────────────
    with Cluster("Externos  (fuera de VPC)"):
        flow_ext = Users("Flow.cl\nPasarela de pago")
        bank_ext = Users("APIs Bancarias\nFintoc · SFTP")

    # ═══════════════════════════════════════════════════════════════════════
    # Conexiones
    # ═══════════════════════════════════════════════════════════════════════

    # Clientes → Edge
    mobile  >> Edge(**EDGE_HTTP, label="HTTPS") >> waf
    browser >> Edge(**EDGE_HTTP, label="HTTPS") >> cf
    cf      >> Edge(label="origin /",    style="dashed") >> s3
    cf      >> Edge(label="origin /api/*") >> alb
    waf     >> alb

    # Edge → Core
    alb >> api

    # Core ↔ Datos
    api >> Edge(label="read / write") >> rds
    api >> Edge(label="caché")        >> cache
    api >> Edge(**EDGE_SECRET)        >> sm

    # Core → Integración (async, desacoplado — el core nunca llama al banco)
    api >> Edge(**EDGE_SYNC) >> sqs

    # Webhooks entrantes de Flow
    apigw >> Edge(label="webhook POST") >> lf

    # Cola → Lambdas
    sqs >> lf
    sqs >> lb

    # Fallos → DLQ
    lf >> Edge(**EDGE_FAIL) >> dlq
    lb >> Edge(**EDGE_FAIL) >> dlq

    # Lambdas actualizan la DB
    lf >> Edge(label="UPDATE pago")        >> rds
    lb >> Edge(label="INSERT movimientos") >> rds

    # Lambdas ↔ Externos
    lf >> Edge(label="HTTP REST") >> flow_ext
    lb >> Edge(label="HTTP/SFTP") >> bank_ext

    # Observabilidad (logs de todos los servicios)
    api >> Edge(**EDGE_LOG) >> cw
    lf  >> Edge(**EDGE_LOG) >> cw
    lb  >> Edge(**EDGE_LOG) >> cw
    dlq >> Edge(color="#D32F2F", style="dotted", label="alarm") >> cw
    cw  >> sns


print("✅ Diagrama generado: walvy_aws_architecture.png")
