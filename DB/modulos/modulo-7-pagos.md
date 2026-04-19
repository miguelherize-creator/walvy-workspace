# Módulo 7 — Pagos

> Fuente: `DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`


### Pagos › Organización de pagos mensuales › Ingresar cuentas por pagar (Monto, fecha vencimiento)
**✅ Incluye:**
Panel de cuentas por pagar.
Visualización tipo semáforo de estado.
Organización de pagos mensuales.

**❌ No incluye:**
Webpay o pasarela de pago
Pago automático desde la app.
Débito automático.

**Trazabilidad:**
MR 7, 8.1 | VP 3.2, 3.3, P2, P5 | BOS 4, 9

**Objetivo estratégico:**
Ordenar cuentas por pagar para prevenir atrasos evitables y dar visibilidad operativa del corto plazo.

**Resultado visible para el usuario:**
El usuario ve qué debe pagar, cuándo vence y qué estado tiene cada cuenta.

**Definición funcional detallada:**
Alta manual de cuentas por pagar con monto, fecha de vencimiento, estado y recordatorios configurables. El panel debe servir para controlar obligaciones, no para ejecutar pagos desde la app. La vía base del MVP es manual, pero si ya existen movimientos cargados en la app, el sistema puede sugerir asociación entre un pago real y una cuenta por pagar registrada, y también detectar posibles compromisos recurrentes no registrados por similitud de monto, periodicidad o texto para que el usuario confirme si deben crearse o vincularse. Cualquier exploración futura de API con proveedores puntuales queda fuera de esta definición funcional; el MVP debe diseñarse y validarse completo con este flujo manual más sugerencias basadas en movimientos.

**UX / UI:**
Vista priorizada por vencimiento cercano y estado, con CTA claros para marcar pagado, revisar o vincular un pago detectado/sugerido. Si la app detecta recurrencia probable, debe presentarla como sugerencia clara y confirmable.

**Criterio de aceptación MVP / QA:**
Puede crear una cuenta por pagar, verla en el panel, recibir recordatorios según configuración y, cuando aplique, vincular un movimiento detectado o aceptar la creación sugerida de un compromiso recurrente, sin depender de integraciones externas para que el flujo principal funcione.

**Guardrails de alcance:**
No agregar pasarela, débito automático ni pago desde la app en esta versión; tampoco convertir una posible API futura en supuesto de diseño, dependencia operativa o alcance implícito del MVP.


---


### Ver panel de cuentas por pagar
**Trazabilidad:**
VP P2 | BOS 9 Complementos

**Objetivo estratégico:**
Centralizar visión operativa de obligaciones.

**Resultado visible para el usuario:**
Ve listado ordenado de cuentas pendientes.

**Definición funcional detallada:**
Panel con tarjetas o tabla simple de pagos pendientes, incluyendo cuando corresponda estado de vinculación con movimientos reales o sugerencias pendientes de confirmar.

**UX / UI:**
Primero vencimientos cercanos; estados visibles.

**Criterio de aceptación MVP / QA:**
Panel carga correctamente pagos activos y vencidos/por vencer, y cuando existe detección compatible permite revisar sugerencias sin romper el flujo principal.

**Guardrails de alcance:**
No esconder información crítica tras navegación profunda.


---


### Recordatorios de pago
**Trazabilidad:**
VP P2 | BOS 9 Uso

**Objetivo estratégico:**
Prevenir atrasos evitables.

**Resultado visible para el usuario:**
Recibe recordatorios antes del vencimiento.

**Definición funcional detallada:**
Reglas de recordatorio configurables por fecha cercana y estado, usando los canales aprobados por producto: popup/in-app, push móvil y correo. Los recordatorios de pagos deben convivir con la matriz general de alertas del sistema sin duplicar mensajes innecesarios.

**UX / UI:**
Mensaje breve con monto, fecha e impacto; definir según caso de uso cuándo conviene popup/in-app, cuándo push y cuándo correo.

**Criterio de aceptación MVP / QA:**
Notificación o recordatorio visible según preferencia/configuración permitida y con al menos un canal operativo dentro de la matriz default.

**Guardrails de alcance:**
No depender de SMS ni de canales no aprobados.


---


### Visualizar estados (semáforo)
**Trazabilidad:**
VP P2, P5 | BOS 4 Mensaje / 9 Uso

**Objetivo estratégico:**
Hacer entendible el riesgo financiero del corto plazo.

**Resultado visible para el usuario:**
Ve estado verde/amarillo/rojo por pago o situación.

**Definición funcional detallada:**
Semáforo aplicado a pagos y estado financiero básico.

**UX / UI:**
Colores consistentes y texto explicativo corto.

**Criterio de aceptación MVP / QA:**
Cada cuenta o estado relevante muestra semáforo coherente.

**Guardrails de alcance:**
No convertir el semáforo en gimmick emocional sin criterio claro.


---
