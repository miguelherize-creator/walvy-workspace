# Módulo 8 — Asistente IA y soporte

> Fuente: `DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`


### Asistente IA y soporte › Asistente IA › Captura de Voz dentro del chat de la IA
**✅ Incluye:**
Recomendaciones automáticas basadas en reglas simples.
Chat conversacional por texto.
Captura de voz (speech-to-text) para convertir voz en texto dentro del chat.
Respuesta en formato texto.
Respuestas contextualizadas en base a:
Datos financieros del usuario dentro de la app.
Reglas de negocio predefinidas.
Está limitado al contexto de la aplicación.
Preguntas frecuentes (FAQ) (entrega de preguntas frecuentes)

Las funcionalidades automáticas incluidas en el MVP corresponden a reglas de negocio predefinidas y/o uso acotado de modelo de lenguaje externo.
No se contempla desarrollo de modelos de machine learning propios ni inteligencia artificial predictiva entrenada con datos históricos de usuarios.

**❌ No incluye:**
Diseño de personalidad, tono o comportamiento de asistente virtual.
Asistente virtual por video.
Avatar animado o guía interactiva.
Emoticons personalizados dentro de la experiencia financiera.
Reacciones emocionales automáticas según comportamiento financiero.
El asistente entrega información de carácter orientativo y no constituye asesoría financiera profesional certificada

Nota: La experiencia se limita a indicadores visuales tipo semáforo (verde, amarillo, rojo).

**Trazabilidad:**
MR 5.4, 6.1, 9 | VP 3.2, 4.3, 5.1, P3, P5 | BOS 4, 6, 9

**Objetivo estratégico:**
Usar la IA como apoyo de captura y orientación práctica dentro de límites claros.

**Resultado visible para el usuario:**
El usuario puede registrar por voz o texto y obtener ayuda simple sobre deuda, pagos o presupuesto.

**Definición funcional detallada:**
Chat de texto con entrada de voz a texto, respuestas apoyadas en reglas de negocio, FAQ y contexto financiero disponible del usuario. La funcionalidad esperada es orientación concreta y accionable dentro del dominio del producto; si el equipo técnico utiliza un motor externo maduro de lenguaje configurado por producto (por ejemplo OpenAI u otro equivalente aprobado), eso debe leerse como decisión de implementación y no como una capacidad adicional del alcance. Puede enriquecerse con material curado o cargado por producto (por ejemplo libros o guías de finanzas personales) para responder mejor dentro del dominio definido. Debe analizar el contexto financiero disponible del usuario y entregar orientación concreta y accionable, explicando la razón de la sugerencia cuando corresponda y apoyándose en las reglas/casos de uso definidos por negocio. No sustituye asesoría profesional ni entrena un modelo propio.

**UX / UI:**
Interfaz sobria, tono práctico y respuestas cortas. Siempre debe quedar claro que la recomendación es orientativa; cuando sea útil, mostrar “por qué te lo sugiero” en una línea ligada al contexto, a la regla aplicada o a la meta afectada.

**Criterio de aceptación MVP / QA:**
La consulta funciona dentro de los límites definidos, usando contexto interno disponible y reglas/fuentes cargadas por producto, sin bloquear el flujo principal ni improvisar respuestas fuera del dominio.

**Guardrails de alcance:**
No agregar avatar, personalidad compleja, video, consejo financiero certificado ni prometer que el modelo “sabe todo” fuera del dominio del producto. La tecnología elegida para responder no cambia el alcance funcional aprobado.


---


### Consultar al asistente IA por texto
**Trazabilidad:**
VP P5 | BOS 9 Uso

**Objetivo estratégico:**
Dar un canal simple para pedir ayuda contextual.

**Resultado visible para el usuario:**
Puede preguntar por texto y recibir orientación útil.

**Definición funcional detallada:**
Input de chat con intents o FAQ sugeridas; respuesta textual contextual.

**UX / UI:**
Caja de texto visible, sugerencias de preguntas y respuestas cortas.

**Criterio de aceptación MVP / QA:**
Consulta por texto funciona y devuelve orientación basada en reglas/contexto.

**Guardrails de alcance:**
No responder fuera del dominio de la app ni improvisar asesoría compleja.


---


### Recomendaciones inteligentes básicas por pantalla
**Trazabilidad:**
MR 7.1 | VP P5 | BOS 6 Elevar utilidad

**Objetivo estratégico:**
Llevar recomendaciones contextuales a los momentos donde el usuario necesita una acción simple.

**Resultado visible para el usuario:**
Ve sugerencias útiles en home, presupuesto, deuda y pagos según su situación actual, incluyendo cuándo conviene activar o revisar Bola de Nieve para potenciar capacidad de ahorro.

**Definición funcional detallada:**
Motor de reglas por pantalla disparado por metas de categoría, umbrales, semáforo, vencimientos, estado del plan y, cuando aplique, avance de metas globales simples. La función es orientar una siguiente acción concreta dentro del MVP. También debe poder activar recomendaciones proactivas cuando detecte señales de presión financiera, por ejemplo pagos atrasados repetidos, obligaciones que consumen gran parte de la capacidad de pago, baja capacidad de ahorro frente a la meta declarada o movimientos que sugieren deuda no incorporada al plan.

**UX / UI:**
Integrar sugerencias en el layout normal de cada pantalla; deben verse como ayuda contextual y no como banners invasivos. Cuando recomiende Bola de Nieve, debe explicar brevemente qué señal la disparó y cómo eso ayuda a potenciar capacidad de ahorro.

**Criterio de aceptación MVP / QA:**
Las recomendaciones cambian según el contexto básico del usuario y remiten a una acción entendible, indicando cuando corresponde qué meta, categoría o señal de presión financiera está siendo afectada.

**Guardrails de alcance:**
No convertirlo en un feed genérico de consejos, contenido editorial o venta cruzada.


---


### Soporte - FAQ › Resolver dudas frecuentes
**Trazabilidad:**
VP P5 | BOS 9 Mantenimiento

**Objetivo estratégico:**
Reducir soporte humano repetitivo y dudas de uso.

**Resultado visible para el usuario:**
Encuentra respuestas rápidas a preguntas frecuentes.

**Definición funcional detallada:**
Base FAQ estática o semiestática dentro de la app.

**UX / UI:**
Listado searchable o acordeón simple.

**Criterio de aceptación MVP / QA:**
Las FAQs cubren dudas core de uso y límites del producto.

**Guardrails de alcance:**
No sustituye soporte humano para incidentes críticos.


---
