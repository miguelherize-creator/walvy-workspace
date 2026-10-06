# Corpus FAQ + Glosario M07 v1.0 · términos internos visibles al usuario

**Fuente revisada:** `PUBLICACION_INTERNA_FAQ_M07_v1.0.xlsx` y `PUBLICACION_INTERNA_GLOSARIO_M07_v1.0.xlsx`
(04_BASE_CONOCIMIENTO). 107 filas activas: 60 FAQ + 47 glosario, sin las 8 Backlog.

**Por qué importa:** desde KabeliDev/back-walvy#347 la app muestra estos textos tal cual
en «Ver preguntas frecuentes», sin pasar por el agente. Lo que está escrito en el
corpus es lo que lee el usuario.

**Qué se pide:** corregir el texto en una v1.1 del corpus. No hay cambio de código; la
versión nueva entra con su propia migración y su `corpus_version`.

---

## A. Jerga técnica: el usuario no la entiende (prioridad alta)

| ID | Término | Texto actual (fragmento) |
|---|---|---|
| M01-FAQ-01 | gate de suficiencia, insumo material | «…los datos que el gate de suficiencia marque como necesarios… Si falta un insumo material…» |
| M02-FAQ-N03 | backend, valores estáticos de diseño, lifecycle | «Los días restantes y el vencimiento deben provenir del backend, no de valores estáticos de diseño… seguir el lifecycle de suscripción vigente.» |
| TR-FAQ-06 | fallback, módulos dueños | «…solo la información mínima habilitada por los módulos dueños… aplicar un fallback seguro» |
| M02-FAQ-N01 | snapshot, elegibles, Headroom | «…utilizable en el snapshot del Perfil… instrumentos elegibles… Margen y Headroom» |
| M02-G-N01 | Headroom | «No es ingreso, deuda, Margen ni Headroom.» |
| M01-G-N01 | lectura canónica | «Lectura mensual canónica que M01 produce…» |
| M06-G-N02 | canónicos, consolidados | «Cantidad de compromisos canónicos consolidados…» |
| M04-G-04 | contrato M04 | «…la mayor severidad dentro del contrato M04.» |
| M04-FAQ-07 / M04-FAQ-10 | faltante material, dato material | «Un faltante material no debe convertirse en “En control”.» |
| M05-FAQ-N05 / M05-G-N04 | score único / monolítico | «…sin crear un score único.» · «…sin score monolítico.» |
| M07-FAQ-04 | recomendaciones gobernadas | «…recomendaciones gobernadas por los módulos de Walvy» |
| M04-FAQ-11 / M07-FAQ-01 | dominio | «Una deuda pertenece al dominio M04…» |

## B. Códigos de módulo en vez del nombre (prioridad alta)

El usuario conoce «Ruta Despeje», «Presupuesto Vivo» y «Pagos», no «M04», «M05» ni «M06».

M04-FAQ-02 · M04-FAQ-03 · M04-FAQ-07 · M04-FAQ-08 · M04-FAQ-09 · M04-FAQ-N01 · M04-FAQ-11 ·
M01-G-N01 · M02-G-N01 · M04-G-04 · M04-G-05 · M04-G-07 · M04-G-N02

Ejemplo, M04-FAQ-09: «La activación requiere una acción válida del usuario dentro de M04»
→ «…dentro de Ruta Despeje».

## C. Voz de especificación en vez de respuesta (prioridad media)

Están escritas como requisito para el equipo («Walvy debe…», «el asistente debe…») y
no como respuesta al usuario. Leídas en la app suenan a promesa incumplida o a documento
interno.

TR-FAQ-02 · TR-FAQ-03 · TR-FAQ-06 · M01-FAQ-01 · M01-FAQ-02 · M01-FAQ-03 · M02-FAQ-03 ·
M04-FAQ-05 · M04-FAQ-10 · M05-FAQ-01 · M05-FAQ-N01 · M05-FAQ-N03 · M05-FAQ-05 ·
M06-FAQ-N01 · M06-FAQ-04 · M07-FAQ-02 · M07-FAQ-03 · TR-G-02 · M02-G-N02 · M02-G-N03

Ejemplo, M04-FAQ-05: «…Walvy debe recalcularlo» → «…Walvy lo recalcula».

## D. Vocabulario de producto a confirmar (prioridad baja)

Son términos del modelo funcional que aparecen en muchas respuestas. Pueden quedarse
si el cliente los considera vocabulario de la app; en ese caso conviene que estén
definidos en el glosario.

| Término | Dónde aparece | ¿Está en el glosario? |
|---|---|---|
| suficiencia / base suficiente | 20 filas, ej. M01-FAQ-N01, M04-FAQ-03 | No |
| evidencia | 11 filas, ej. M01-FAQ-04, M06-FAQ-06 | No |
| candidata / candidato | M04-FAQ-01, M04-FAQ-10, M06-FAQ-07, M06-G-N04 | No |
| consolidar | TR-FAQ-04, TR-G-01, M02-G-02, M06-G-N04 | No |
| elegible / elegibilidad | M04-FAQ-01, M04-FAQ-03, M04-FAQ-06, M04-G-04, M04-G-N02 | Sí, «Ruta elegible» (M04-G-05) |

---

Revisión hecha sobre el texto publicado, sin cambiar el sentido de ninguna respuesta.
Los reemplazos de ejemplo son sugerencias de redacción; el contenido lo aprueba el cliente.
