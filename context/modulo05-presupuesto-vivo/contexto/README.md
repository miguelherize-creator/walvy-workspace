# M05 · Presupuesto Vivo — contexto

Levantado de la entrega del cliente en `documentacion/Módulo05/`, paquete
`Walvy_Modulo5_Presupuesto_Vivo_*_v1_0` (Fase 1 a 5 + Anexo BDD + Consolidado Final) y
`Categorias/Walvy_Modulo5_BBDD_Categorias_MVP_v2.7.xlsx`.

> **Este es el M05 del cliente.** No confundir con [`../../modulo05-cashflow/`](../../modulo05-cashflow/),
> que es Cashflow —movimientos e ingesta— y en la numeración interna de `context/db/` es
> `modulo5.md`. El schema de este módulo es `db/modulo6.md`. El mapa de las dos
> numeraciones está en [`../../../CLAUDE.md`](../../../CLAUDE.md).

**Owner:** Sergio Vidal. **Estado del paquete documental:** «QA documental ejecutado ·
validado post-subida · fuente vigente», sin condición bloqueante para certificar.

---

## 1 · El principio rector

**El presupuesto se construye desde registros reales** —documentos, movimientos,
evidencia disponible—, no preguntando en frío cuánto asignar a una categoría
predefinida. Si no hay datos suficientes, el flujo reconoce la limitación en lugar de
mostrar una planilla vacía.

El usuario es el decisor final: el módulo recomienda y muestra evidencia, y **no
reasigna nada automáticamente**.

## 2 · Las seis decisiones cerradas

| Decisión | Cómo se aplica |
|---|---|
| Presupuesto desde datos reales | No es planilla vacía ni presupuesto manual en frío |
| Categorización por certeza | Alta automatiza · media pide validación · baja queda **sin categorizar** |
| Objetivos por categoría/subcategoría gobernada | El usuario define o ajusta sobre el **consumo detectado** |
| Meta operacional | Un objetivo menor al consumo detectado activa **seguimiento, no castigo** |
| Subejecución y margen | Es **hipótesis funcional**, nunca causalidad absoluta |
| Pagos y M04 separados | Pagos organiza compromisos · M04 gestiona mora y deuda problemática |

## 3 · Estados funcionales

| Estado | Condición | Severidad |
|---|---|---|
| Sin datos suficientes | No hay documentos ni movimientos mínimos | Advertencia |
| Datos parciales | Lectura limitada o confianza insuficiente | Preventiva |
| Requiere validación | Categoría sugerida con certeza media | Preventiva |
| Sin categorizar | Certeza baja | Advertencia |
| Meta operacional activa | Objetivo menor al consumo detectado, confirmado | Preventiva |
| Sobreconsumo | Gasto real supera el objetivo | Alta |
| Subejecución | Gasto real marginal o nulo contra objetivo | Informativa |

La taxonomía de severidad es **informativa · preventiva · advertencia · alta**.

## 4 · Umbrales

**50 / 80 / 90 / 100 / 110** sobre el avance contra objetivo. El cliente los declara
«cerrados como regla producto inicial», con la **parametrización técnica pendiente** — o
sea: los cortes no se discuten, dónde viven sí.

## 5 · Superficies

Pantallas propias `PV-P01` a `PV-P05` (Resumen · Presupuesto por categoría · Detalle de
categoría · Movimientos sin categorizar · Histórico y progreso) y componentes `PV-C01` a
`PV-C06` (cards, banners e insights).

`PV-P03` **no debe forzarse como pantalla** si UX lo resuelve como panel. Los componentes
no son pantallas nuevas por defecto.

Home, Perfil, Alertas y Recomendaciones **consumen señales y no son dueños del módulo**.

## 6 · Categorías · taxonomía v2.7

**20 categorías maestras y 105 subcategorías.** El archivo trae taxonomía, reglas de
clasificación, alcance presupuestario, modelo BBDD, enums, MVP vs backlog, privacidad y
guardrails de prueba, en hojas separadas.

v2.7 robusteció **Ingresos** —bono/aguinaldo/gratificación, ventas ocasionales, arriendos
recibidos, dividendos e intereses, retiro de sociedad— y sumó revisión técnica,
cotizaciones e imposiciones, y accesorios de mascotas.

**Lo que deliberadamente NO es categoría**, y se resuelve con reglas de BBDD y backend:
transferencias recibidas, depósitos en efectivo, Servipag, notas de crédito, reversas y
transferencias entre cuentas propias.

Las reglas que el paquete refuerza, y que son las que más fácil se rompen:

- **No clasificar una transferencia recibida como ingreso.**
- **No asumir un depósito en efectivo como ingreso disponible.**
- Tratar los intermediarios de pago como **canales, no comercios**.
- Evitar doble conteo en pagos de tarjeta, notas de crédito y reversas.
- Separar movimientos personales, inversión, negocio, rendiciones, terceros e internos.
- Clasificar «retiro de sociedad» **sólo** con contexto, patrón validado o confirmación.

> Existe también la v2.6 en la misma carpeta. **La vigente es la v2.7.** Y este contrato
> tiene consumidores fuera de M05 —`front-walvy` y Kread—, así que un cambio se coordina
> antes de moverlo.

## 7 · Fronteras

| Módulo | Qué recibe de M05 | Regla de frontera |
|---|---|---|
| **M04 · Ruta Despeje** | Mora, deuda problemática, «salida del rojo». Datos **prellenados** cuando la brecha afecta deuda, mora, liquidez crítica o capacidad de pago | M05 deriva casos problemáticos; **no aplica Bola de Nieve** y no aplica el plan sin aprobación del usuario |
| **Pagos** | Señales de compromisos, fechas y pagos asociados | Pagos organiza compromisos; M05 analiza impacto |
| **M02 · Foco del Mes** | Sugerencia de actualización cuando un plan de recuperación activo tiene estrategia dominante | M05 **no crea focos nuevos** ni reemplaza el foco actual sin aprobación |
| **M01 · Onboarding** | Consume movimientos y documentos | No repite el onboarding |

## 8 · Fuera de alcance

Forecast futuro, reasignación automática, motor de Pagos, motor de Deudas / Bola de
Nieve, diseño visual final y el modelo técnico final de BBDD.

---

## Lo que hay que resolver antes del 23-sep

**El paquete de M05 no menciona el ingreso canónico ni el headroom que M04 espera de
él.** Es el punto abierto que más importa y está en
[`../deuda-tecnica/README.md`](../deuda-tecnica/README.md).
