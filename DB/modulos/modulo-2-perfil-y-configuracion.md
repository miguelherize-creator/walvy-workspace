# Módulo 2 — Perfil y configuración

> Fuente: `DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`


### Perfil y configuración › Perfil de usuario › Ajustes de perfil (Nombre, correo, cambio de contraseña, aletas)
**✅ Incluye:**
Edición nombre y correo
Cambio contraseña
Configuración de notificaciones
Configuración de alertas
Definición de metas

Alertas cuando:
Se supera umbral de gasto.
Se acerca fecha de pago.
Recordatorios configurables.
Semáforo visual por estado financiero.

**❌ No incluye:**
Notificaciones push inteligentes con IA predictiva.
Envío masivo vía SMS (si no se contrata servicio externo).

**Trazabilidad:**
MR 7.1, 8.1, 8.2 | VP 3.2, 6.1, P2, P4, P5 | BOS 4, 9

**Objetivo estratégico:**
Permitir que el usuario revise metas y alertas derivadas del presupuesto sugerido, sin convertir la app en un centro complejo de settings.

**Resultado visible para el usuario:**
El usuario entiende qué alertas recibirá, sobre qué meta operan y puede dejar activadas las relevantes sin perderse en configuración avanzada.

**Definición funcional detallada:**
Configuración de perfil y preferencias de aviso sobre una matriz default definida por producto. Por defecto la app deja activos los avisos mínimos para que funcione como se espera sin diseño manual del usuario: pagos próximos, alertas de presupuesto por categoría, recordatorio semanal para importar últimos movimientos y señales del semáforo. El usuario puede ajustar intensidad, frecuencia/cadencia y canal dentro de opciones acotadas.

**UX / UI:**
Pantalla simple por bloques: pagos, presupuesto y actualización de datos. Debe mostrar qué viene activo por defecto, por qué sirve y qué puede ajustar el usuario sin confusión.

**Criterio de aceptación MVP / QA:**
El usuario puede ver la configuración por defecto, mantenerla o ajustar canal/cadencia sin romper la lógica base del sistema.

**Guardrails de alcance:**
No ofrecer motor libre de reglas, porcentajes ni flujos completamente custom por usuario; la lógica base la define producto.


---


### Activar / desact. Notificaciones y Alertas
**Trazabilidad:**
VP P2, P5 | BOS 9 Uso

**Objetivo estratégico:**
Activar ayuda oportuna sin ruido y sin pedir al usuario diseñar reglas.

**Resultado visible para el usuario:**
Recibe alertas útiles desde el inicio sobre vencimientos, gasto y presupuesto, aun si no entra a configurar nada.

**Definición funcional detallada:**
Toggles por tipo de alerta y canal: pagos, recordatorios de actualización, alertas de presupuesto por categoría y señales del semáforo. La app debe venir operativa por defecto: por ejemplo popup/in-app al cruzar umbrales de presupuesto, push móvil para vencimientos próximos y recordatorio semanal para importar últimos movimientos, y correo para resúmenes o avisos críticos según producto. En presupuesto, el sistema usa una escalera fija de umbrales sobre la meta mensual definida para cada categoría (por defecto al menos 50%, 80% y 100% o más; cualquier nivel adicional lo define producto). El usuario decide si quiere bajar o subir intensidad, cadencia o canal dentro de opciones acotadas; no diseña un motor libre de porcentajes.

**UX / UI:**
Configuración clara por bloques y canales aprobados: popups/in-app para acciones contextuales, push móvil para avisos oportunos y correo para recordatorios o resúmenes. Debe verse qué viene activo por defecto y permitir ajuste simple.

**Criterio de aceptación MVP / QA:**
Las alertas base quedan operativas sin configuración manual y el usuario puede mantener defaults o ajustar canal/cadencia dentro de las opciones permitidas.

**Guardrails de alcance:**
No abrir constructor libre de reglas/canales ni depender de SMS u otros canales no aprobados para que la lógica principal funcione.


---


### Perfil financiero › Configurar perfil financiero básico con cálculo de capacidad estimada de pagos
**Trazabilidad:**
MR 7.1 | VP 3.1, 3.3, P1, P4 | BOS 4, 9

**Objetivo estratégico:**
Estimar la carga financiera base y construir un presupuesto sugerido que alimente semáforo, metas y capacidad estimada de pago.

**Resultado visible para el usuario:**
El usuario ve una primera lectura simple de su margen del mes, capacidad estimada de pago y un presupuesto sugerido por categorías, sin tener que inventarlo desde cero.

**Definición funcional detallada:**
Perfil financiero básico alimentado por datos fijos (por ejemplo renta, gastos relativamente estables y otros antecedentes mínimos) y, idealmente, por cartolas o últimos movimientos importados si quiere diagnóstico inmediato. La app debe explicar durante onboarding que, si el usuario quiere saber cómo está hoy y no después de un mes de uso, conviene subir movimientos recientes para que se armen desde el inicio el presupuesto sugerido, las metas por categoría, el semáforo, las alertas y las primeras recomendaciones. Si el usuario omite ese paso, la herramienta igual debe partir con supuestos básicos y valores guía del producto, pero dejando claro que la precisión mejora al importar registros.

**UX / UI:**
Setup guiado y liviano, con CTA muy visible para importar cartolas/movimientos y explicación directa del beneficio: “esto acelera tu diagnóstico, presupuesto y recomendaciones desde hoy”.

**Criterio de aceptación MVP / QA:**
Guarda el perfil financiero básico, deja operativo el cálculo de capacidad estimada de pago, el presupuesto sugerido por categoría, las metas editables, el semáforo y la lógica de alertas/umbrales, y comunica claramente el beneficio de importar cartolas para mejorar el diagnóstico inicial.

**Guardrails de alcance:**
No presentarlo como scoring bancario, análisis patrimonial, asesoría certificada ni como un presupuesto 100% manual construido desde una hoja en blanco.


---


### Definir objetivo financiero (Metas)
**Trazabilidad:**
VP 3.1, 4.5, P4 | BOS 9 Salida/continuidad

**Objetivo estratégico:**
Conectar orden financiero con una meta entendible.

**Resultado visible para el usuario:**
El usuario declara una meta global que refuerza el sentido de progreso y complementa las metas mensuales por categoría del presupuesto.

**Definición funcional detallada:**
Metas globales simples: bajar deuda, ahorrar un monto, potenciar capacidad de ahorro, evitar atraso o cumplir presupuesto. Deben tener seguimiento matemático básico usando indicadores ya disponibles del MVP, por ejemplo deuda restante, monto ahorrado, capacidad de ahorro recuperada/disponible, pagos al día o grado de cumplimiento del presupuesto. Estas metas globales no reemplazan las metas por categoría que alimentan alertas y umbrales; las complementan y pueden ayudar a disparar recomendaciones proactivas, por ejemplo revisar o activar Bola de Nieve si la capacidad de ahorro queda muy por debajo del objetivo declarado.

**UX / UI:**
Selección guiada con opciones predefinidas y edición mínima, mostrando en una línea cómo se medirá el avance y qué módulo puede ayudar a lograrla.

**Criterio de aceptación MVP / QA:**
Meta creada y visible en home o perfil, con una señal básica de avance o cumplimiento según el indicador definido y sin confundirla con las metas por categoría.

**Guardrails de alcance:**
No convertir metas en simulador patrimonial complejo ni confundir esta meta global con las metas mensuales por categoría del presupuesto.


---
