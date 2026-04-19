# Módulo 3 — Home (Seguimiento, visualización y motivación)

> Fuente: `DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`


### Home (Seguimiento, visualización y motivación) › Dashboard › Ver resumen del día/ semanal /Mensual
**✅ Incluye:**
Visualización consolidada de:

Ingresos
Gastos
Balance
Gráficos básicos (línea / barra)
Semáforo financiero
Visualización avance de deudas
Gamificación básica definida como:
Logros simples (ej: “3 días bajo presupuesto”)

**❌ No incluye:**
Proyecciones financieras a más de 12 meses.
Simulaciones complejas de escenarios.
Modelos predictivos con machine learning

Descarga de documentos 
Generación automática de reportes descargables.

**Trazabilidad:**
MR 7, 7.1, 8.1 | VP 3.2, 3.3, 6.1, P1, P2, P4, P5 | BOS 4, 5, 9

**Objetivo estratégico:**
Dar una lectura del mes que permita decidir rápido qué mirar y qué corregir.

**Resultado visible para el usuario:**
Desde el home ve el estado general del mes, próximos riesgos y progreso visible.

**Definición funcional detallada:**
Home resumido con balance, semáforo, avance de deuda, próximos vencimientos y señales básicas de desvío o fuga. Los gráficos apoyan la lectura, pero no reemplazan la acción principal.

**UX / UI:**
Jerarquía visual clara: primero riesgo o acción sugerida, luego estado del presupuesto y finalmente gráficos de apoyo.

**Criterio de aceptación MVP / QA:**
El home muestra al menos un próximo vencimiento o alerta, el estado del mes y el avance de deuda.

**Guardrails de alcance:**
No convertir el home en tablero BI, centro de reportes ni vista cargada de indicadores de bajo valor.


---


### Gráfico por categoría de gastos (Gasto hormiga, ahorro,etc)
**Trazabilidad:**
MR 7.1 | VP P4 | BOS 6 Elevar fugas

**Objetivo estratégico:**
Hacer visible dónde se escapa la liquidez.

**Resultado visible para el usuario:**
Identifica categorías sensibles como gastos hormiga, ahorro y otros drenajes que concentran el deterioro del presupuesto.

**Definición funcional detallada:**
Gráfico por categoría con foco en categorías drenantes, regla de gastos hormiga y una heurística simple de concentración/desbalance o mix presupuestario definida por producto (por ejemplo una regla tipo 50/30/20, 80/20 u otra equivalente adoptada por negocio). Debe ayudar a entender rápido dónde conviene empezar a actuar, no sólo por gasto hormiga sino también por categorías que están lesionando más el presupuesto.

**UX / UI:**
Usar labels claros y pocos colores; destacar categorías que exigen acción y explicar brevemente si el problema viene por fugas pequeñas repetidas, por concentración excesiva o por desviación frente al mix objetivo.

**Criterio de aceptación MVP / QA:**
El usuario puede identificar categoría dominante, drenajes relevantes y desvíos frente al mix esperado que justifican una recomendación o ajuste concreto.

**Guardrails de alcance:**
No saturar con taxonomías complejas ni exceso de categorías en V1.


---


### Grafico de cumpliento de presupuestos
**Trazabilidad:**
VP P4 | BOS 9 Uso

**Objetivo estratégico:**
Mostrar si el presupuesto real del mes va sano o desbordado.

**Resultado visible para el usuario:**
Ve cumplimiento por categoría y estado general sobre metas sugeridas o ajustadas por la app.

**Definición funcional detallada:**
Comparativa entre presupuesto sugerido o ajustado y gasto real por categoría base. Debe mostrar el avance frente a la meta mensual por categoría y disparar umbrales visuales del sistema conforme se consume la meta, con escalera fija definida por producto (por defecto al menos 50%, 80% y 100% o más; cualquier nivel intermedio adicional lo controla producto y no el usuario).

**UX / UI:**
Barras simples; rojo/amarillo/verde; mensaje corto de corrección. El usuario debe entender qué porcentaje de su meta lleva consumido, cuál es el siguiente umbral y por qué recibió la alerta.

**Criterio de aceptación MVP / QA:**
Se observa estado por categoría, porcentaje consumido frente a la meta y al menos una alerta de desvío cuando se cruzan umbrales definidos por producto.

**Guardrails de alcance:**
No convertirlo en analítica avanzada, editor complejo de umbrales ni forecasting largo.


---


### Gráfico de reducción de deudas
**Trazabilidad:**
VP P1 | BOS 4

**Objetivo estratégico:**
Hacer tangible que salir del rojo es posible.

**Resultado visible para el usuario:**
Ve disminución de deuda y cercanía a la fecha de salida.

**Definición funcional detallada:**
Gráfico simple de reducción de deuda y saldo restante.

**UX / UI:**
Destacar saldo inicial, saldo actual y fecha/meta estimada + próxima deuda a saldar con capacidad de ahorro a liberar.

**Criterio de aceptación MVP / QA:**
Visualización responde a cambios en pagos o prioridad.

**Guardrails de alcance:**
No mostrar simulaciones complejas fuera del modelo MVP.


---


### Recomendaciones › Recibir recomendaciones básicas en todas las pantallas
**Trazabilidad:**
VP P5 | BOS 9 Uso

**Objetivo estratégico:**
Convertir datos en guía situacional mínima.

**Resultado visible para el usuario:**
Recibe recomendaciones breves y contextualizadas en cada pantalla.

**Definición funcional detallada:**
Reglas simples por pantalla según deuda, pagos, semáforo y presupuesto.

**UX / UI:**
Cards cortas con verbo de acción: “paga”, “recorta”, “revisa”, “sube”.

**Criterio de aceptación MVP / QA:**
Cada pantalla crítica muestra al menos una recomendación contextual útil.

**Guardrails de alcance:**
No prometer IA mágica ni consejos genéricos desconectados del contexto.


---


### Gamificación › Gamificación básica (puntaje, Perfil/ranking financiero u otro)
**Trazabilidad:**
VP 3.1 emocional | BOS 9 Salida

**Objetivo estratégico:**
Reforzar pequeñas victorias que sostengan uso sin desviar el producto hacia entretenimiento.

**Resultado visible para el usuario:**
El usuario percibe avance o reconocimiento por conductas útiles dentro del MVP.

**Definición funcional detallada:**
Gamificación básica resuelta con puntaje, hitos, perfil o ranking personal simple, siempre ligado a conductas útiles del MVP como registrar, cumplir pagos o mantenerse dentro del presupuesto.

**UX / UI:**
Elemento secundario y discreto. Debe acompañar el flujo funcional, no competir visualmente con deuda, pagos o presupuesto.

**Criterio de aceptación MVP / QA:**
Existe al menos un mecanismo visible de logro o puntaje asociado a una acción útil del usuario.

**Guardrails de alcance:**
No agregar competencia social, rankings públicos ni una capa profunda de gamificación que reemplace el valor funcional.


---


### Visualizar logros del día
**Trazabilidad:**
VP P5 | BOS 9 Continuidad

**Objetivo estratégico:**
Dar señal de progreso inmediato para sostener recurrencia.

**Resultado visible para el usuario:**
Ve un logro del día o una micro-victoria.

**Definición funcional detallada:**
Widget simple con logro reciente o tarea cumplida.

**UX / UI:**
Mensaje positivo, corto y concreto; no infantil.

**Criterio de aceptación MVP / QA:**
El home refleja al menos una victoria visible cuando exista evento.

**Guardrails de alcance:**
No exagerar tono emocional ni usar mecánicas complejas.


---
