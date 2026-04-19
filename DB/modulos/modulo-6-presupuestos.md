# Módulo 6 — Presupuestos

> Fuente: `DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`


### Presupuestos › Presupuestos › Ingreso y agregar nueva subcategorías.
**✅ Incluye:**
Creación de presupuesto por categoría.
Definición de monto mínimo  y maxima por categoría.

Visualización:
Semanal
Mensual
Gráfica comparativa presupuesto vs gasto real.

**❌ No incluye:**
Ajuste automático del presupuesto por comportamiento histórico.
Rebalanceo automático de categorías.
IA de recomendación avanzada.
Recomendaciones basadas en machine learning.

**Trazabilidad:**
MR 7.1, 8.1 | VP 3.2, 3.3, P4, P5 | BOS 4, 6, 9

**Objetivo estratégico:**
Transformar el presupuesto en una herramienta viva para hacer rendir mejor el sueldo y potenciar capacidad de ahorro.

**Resultado visible para el usuario:**
El usuario ve cuánto puede gastar, cuánto lleva y dónde se le está yendo liquidez sobre un presupuesto sugerido por la app que puede ajustar por categoría.

**Definición funcional detallada:**
Presupuesto por categoría y subcategoría con comparación contra gasto real. Debe nacer de la estructura base del producto y, cuando exista información suficiente, del setup/importación inicial; el usuario revisa y ajusta metas por categoría para acercarse a su presupuesto ideal y potenciar capacidad de ahorro. Debe apoyar alertas tempranas, lectura de desvíos y detección de fugas o gastos hormiga según la regla de negocio definida para V1.

**UX / UI:**
Priorizar semana y mes, mostrar categorías drenantes con claridad y usar mensajes de corrección concretos. El usuario debe leer con facilidad su meta sugerida, gasto real y desvío.

**Criterio de aceptación MVP / QA:**
Puede revisar el presupuesto sugerido, ajustar metas por categoría, ver gasto real comparado y recibir una señal clara cuando una categoría se desborda.

**Guardrails de alcance:**
No agregar rebalanceo automático, optimización avanzada ni recomendaciones basadas en ML fuera del alcance.


---


### Visualizar categorías (Alimentación, transporte, compras, etc)
**Trazabilidad:**
VP P4 | BOS 9 Uso

**Objetivo estratégico:**
Permitir lectura simple del gasto por rubro.

**Resultado visible para el usuario:**
Ve categorías clave del mes.

**Definición funcional detallada:**
Catálogo inicial de categorías relevantes para Chile/LATAM.

**UX / UI:**
Iconos o nombres cotidianos; no demasiadas opciones visibles a la vez.

**Criterio de aceptación MVP / QA:**
Categorías visibles y seleccionables en presupuesto y movimientos.

**Guardrails de alcance:**
No partir con taxonomía infinita.


---


### Ingreso de categorías (Manual)
**Trazabilidad:**
VP P4, P3 | BOS 9 Mantenimiento

**Objetivo estratégico:**
Dar flexibilidad sin romper simplicidad.

**Resultado visible para el usuario:**
Puede crear subcategorías acotadas cuando lo necesite, sin romper la estructura base del producto.

**Definición funcional detallada:**
Alta manual de subcategoría dentro de una categoría base existente, con nombre y opcionalmente color/icono si producto lo mantiene. La estructura principal de categorías la define el producto para sostener orden y comparabilidad; las subcategorías que agregue el usuario deben ser acotadas y mantenerse dentro de esa estructura.

**UX / UI:**
Flujo corto desde presupuesto o movimiento, dejando claro dentro de qué categoría base quedará la nueva subcategoría.

**Criterio de aceptación MVP / QA:**
Subcategoría creada queda disponible y usable en la app dentro de su categoría base.

**Guardrails de alcance:**
No abrir alta libre de categorías base, árboles largos ni taxonomías caóticas; la estructura principal la define el producto.


---


### Recomendaciones de acuerdo al presupuesto
**Trazabilidad:**
MR 7.1, 8.1 | VP P4, P5 | BOS 6 Elevar utilidad

**Objetivo estratégico:**
Convertir los desvíos del presupuesto en una acción concreta de corrección.

**Resultado visible para el usuario:**
Recibe sugerencias útiles cuando una categoría compromete el mes, se desvía de su meta o reduce capacidad de ahorro.

**Definición funcional detallada:**
Reglas simples vinculadas a umbrales, fugas, gastos hormiga y, cuando aplique, a la distancia entre la meta por categoría y el comportamiento real del mes. Las recomendaciones deben explicar qué categoría se desvió, por qué importa y qué ajuste simple podría evaluar el usuario para acercarse a su presupuesto ideal.

**UX / UI:**
Cards o mensajes breves junto al presupuesto, con verbo de acción y referencia clara a la categoría afectada.

**Criterio de aceptación MVP / QA:**
Cuando existe desvío relevante, la app despliega una recomendación contextual comprensible y vinculada a la categoría o meta afectada.

**Guardrails de alcance:**
No usar mensajes genéricos ni prometer inteligencia avanzada que el MVP no entrega.


---


### Definir presupuesto mensual por categoría
**Trazabilidad:**
VP P4 | BOS 9 Uso

**Objetivo estratégico:**
Instalar la disciplina mínima del mes real sin pedir un presupuesto en hoja en blanco.

**Resultado visible para el usuario:**
Revisa la meta sugerida por categoría y ajusta, si quiere, el valor objetivo con el que la app controlará gasto, alertas y recomendaciones.

**Definición funcional detallada:**
La app precarga montos sugeridos por categoría base a partir del setup/importación o, si falta data, da valores guía del producto (regla de negocio en relación al ingreso del cliente y buenas prácticas). El usuario no parte desde cero: confirma o ajusta la meta mensual por categoría, y esa meta es el valor contra el que se comparan gasto real, umbrales, semáforo, comparativas y recomendaciones de corrección.

**UX / UI:**
Formulario ligero, editable y entendible, mostrando monto sugerido, meta elegida, porcentaje ya consumido y señal simple del siguiente umbral.

**Criterio de aceptación MVP / QA:**
Presupuesto sugerido guardado o ajustado y usado por alertas, comparativas y recomendaciones sobre las categorías definidas.

**Guardrails de alcance:**
No exigir histórico perfecto ni pedir llenar una planilla vacía manualmente en V1.


---


### Visualizar presupuesto por semana/ mes/ año/ meta diaria
**Trazabilidad:**
MR 7.1 | VP P4 | BOS 9 Uso/continuidad

**Objetivo estratégico:**
Permitir lectura corta del mes sin forzar análisis complejo.

**Resultado visible para el usuario:**
Ve semana, mes, año y meta diaria como vistas de apoyo.

**Definición funcional detallada:**
Vistas resumidas del presupuesto con enfoque principal en semana y mes.

**UX / UI:**
Default mensual/semanal; año y meta diaria como secundarias.

**Criterio de aceptación MVP / QA:**
Puede alternar vista sin perder claridad del estado actual.

**Guardrails de alcance:**
No usar estas vistas para agregar complejidad analítica innecesaria.


---
