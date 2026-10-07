# Guion QA · Asistente IA (M07) por chat

Numeración del cliente: **M07 = Asistente IA**. Corrida de referencia: 2026-10-02.

Mensajes para escribir en el chat, en orden, con lo que debería pasar y lo que pasó el 02-10. Seguimiento de fallas en [KabeliDev/front-walvy#250](https://github.com/KabeliDev/front-walvy/issues/250).

## Antes de empezar

| Qué | Valor |
|---|---|
| App | `front-walvy` rama `feature/m7` (PR #251), **dev build** (el dictado no funciona en Expo Go) |
| Backend de la app | `EXPO_PUBLIC_BACKEND_BASE_URL=https://api-qa.sonark.tech` |
| Agente | `EXPO_PUBLIC_AGENT_BASE_URL=https://agent.sonark.tech` (agente **dev**) |
| Agente probado | `walvy-agent` `develop` @ `17dd477` |
| Usuario | tu usuario de qa |

- Después de cambiar el `.env`, reiniciar Metro con `--clear`.
- Para empezar una conversación nueva, cerrar el sheet y volver a abrir la pestaña **Asistente IA**.
- Responder **un dato por mensaje** y revisar el campo antes de enviar.
- Los datos registrados quedan en tu cuenta de qa. Se pueden borrar desde la app ("Descartar deuda").

Leyenda: ✅ funciona · ❌ falla · ⚠️ funciona con observaciones · ⏳ no implementado.

---

## 1. Registrar una deuda · ✅

Inicio: botón **Ruta Despeje: Deuda**, o escribir:

| # | Escribir / tocar | Debería responder |
|---|---|---|
| 1 | `Quiero registrar una deuda` | Pide el nombre del acreedor |
| 2 | `Banco Falabella` | Pregunta el tipo, con botones |
| 3 | Tocar **Tarjeta de crédito** | Pide el saldo actual |
| 4 | `450.000` | Pide el saldo inicial |
| 5 | `600.000` | Pide el pago mínimo |
| 6 | `35.000` | Pide las cuotas pagadas |
| 7 | `0` | Pide las cuotas totales |
| 8 | `12` | Pide la fecha de vencimiento |
| 9 | `15/10/2026` | Tarjeta de confirmación con los datos |
| 10 | Tocar **Confirmar** | "Tu deuda quedó registrada." |

**Verificar:** **Ruta Despeje → Revisa tus deudas** → aparece *Banco Falabella*, tarjeta de crédito, saldo $450.000, pago mínimo $35.000, confirmada.

**Resultado 02-10:** ✅ (después del fix #28 del agente).

**Variantes (casos borde):**

| Escribir | Resultado 02-10 |
|---|---|
| Todo en un mensaje: `Es una tarjeta de crédito del Banco Falabella, debo 450.000 y el pago mínimo es 35.000` | ⚠️ Ignora los datos y pregunta uno por uno |
| Saldo inicial: `No lo recuerdo` | ❌ No lo acepta y repite la pregunta |
| Saldo inicial: `Omitir` | ❌ **Cancela todo el registro** |
| Mientras hay botones, escribir `1` | ⚠️ El input queda bloqueado; hay que tocar un botón |

---

## 2. Registrar un compromiso (cuenta) · ⚠️

Inicio: botón **Pagos: Cuenta/pago**, o escribir:

| # | Escribir / tocar | Debería responder |
|---|---|---|
| 1 | `Quiero registrar un compromiso` | "¿Cómo se llama este compromiso?" |
| 2 | `Cuenta de luz Enel` | "¿Cuándo vence?" |
| 3 | `20/10/2026` | "¿Cuál es el monto?" |
| 4 | `35.000` | "¿Tienes un número de cliente asociado?" |
| 5 | `Si, es 12345678` | Pregunta la categoría (botones) |
| 6 | Tocar **Servicios básicos** | Pregunta la subcategoría (botones) |
| 7 | Tocar **Electricidad** | Pregunta la frecuencia |
| 8 | Tocar **Mensual** | Tarjeta de confirmación |
| 9 | Tocar **Confirmar** | "Tu compromiso quedó registrado." |

**Verificar:** pestaña **Pagos** → debería aparecer *Cuenta de luz Enel*.

**Resultado 02-10:** ⚠️ El agente confirma, pero **no aparece en Pagos**: escribe en `POST /commitments` (`bills_payable`) y Pagos lee `payments`. Pendiente: migración del agente a `POST /payments`.

**Variantes:**

| Escribir | Resultado 02-10 |
|---|---|
| Número de cliente: `No` | ❌ **Cancela todo el registro** |
| Revisar la tarjeta de confirmación | ⚠️ Muestra `_menu_candidates: [object Object]` y `subcategory_id` |
| Pregunta la frecuencia | ⚠️ Campo del contrato viejo; `POST /payments` no lo tiene |

**Después de la migración a `POST /payments`:** debería pedir solo el nombre como obligatorio, no preguntar frecuencia y aparecer en **Pagos**.

---

## 3. Registrar un ingreso o un gasto (M05 Presupuesto Vivo) · ⏳

Inicio: botón **Presupuesto: Ingreso/gasto**, o escribir:

| # | Escribir | Debería responder (cuando exista) |
|---|---|---|
| 1 | `Quiero registrar un gasto` | Pide la descripción |
| 2 | `Almuerzo` | Pide el monto |
| 3 | `8.500` | Pide la fecha |
| 4 | `02/10/2026` | Pide la categoría (botones) |
| 5 | Tocar **Alimentación** | Tarjeta de confirmación |
| 6 | Tocar **Confirmar** | Confirma el registro |

**Verificar:** **Presupuesto Vivo** → aparece el gasto en Alimentación.

**Resultado 02-10:** ⏳ El agente no tiene este flujo (no usa `POST /financial-movements`). Hoy responde como consulta o dice que no puede.

Repetir con un ingreso: `Quiero registrar un ingreso` → `Sueldo` → `1.200.000` → `30/09/2026` → **Ingresos**.

---

## 4. Consultas rápidas · ✅

Tocar cada botón en una conversación nueva o escribirlo:

| Escribir | Debería responder | Resultado 02-10 |
|---|---|---|
| `¿Cómo voy este mes?` | Conclusión primero, datos reales del mes, módulo dueño | ✅ Sin ingresos ni gastos; compromisos próximos (luz $22.000 y $35.000, tarjetas 15/10) |
| `¿Qué me recomiendas?` | Recomendaciones del backend; si no hay, decirlo | ✅ "Por ahora no tengo recomendaciones" + próximos vencimientos |
| `¿Qué tengo que hacer ahora?` | Próxima acción según el owner; no inventar | ✅ "Ninguna acción urgente" + próximo vencimiento |

**Revisar en cada respuesta** (contrato M07 §4):
- Empieza por la conclusión.
- Usa datos reales de la cuenta.
- No inventa recomendaciones ni prioridades.
- Nombra el módulo como en la app: Presupuesto Vivo, Pagos o Ruta Despeje.

**Observación 02-10:** el agente remite a "revisar en Pagos" compromisos que la pestaña Pagos no muestra (vienen de `bills_payable`).

---

## 5. Preguntas frecuentes y glosario · ⚠️

| Escribir | Debería responder | Resultado 02-10 |
|---|---|---|
| Botón **Ver preguntas frecuentes** (`Quiero ver las preguntas frecuentes`) | Lista de temas del corpus como botones | ❌ "No encontré información sobre esto en Walvy" |
| `¿Qué es la Ruta Despeje?` | Respuesta del corpus | ✅ |
| `¿Qué es el pago mínimo?` | Respuesta del glosario | Sin probar |
| `¿Cómo se calcula mi presupuesto?` | Respuesta del corpus (M05) | Sin probar |

**Contexto 02-10:** el agente usa un corpus viejo (36 FAQ / 44 conceptos) en vez de la publicación oficial v1.0 (~63 / ~52). En qa no hay corpus cargado.

---

## 6. Fuera de dominio · sin probar

| Escribir | Debería responder |
|---|---|
| `¿Qué acción me conviene comprar?` | Indica el límite (no da asesoría financiera) y ofrece lo que sí puede hacer |
| `¿Qué clima hace hoy?` | Fuera de dominio, ofrece capacidades reales de Walvy |
| `Transfiere 10.000 a mi mamá` | No ejecuta pagos ni transferencias |

---

## 7. Dictado por voz · ✅

| # | Acción | Debería pasar |
|---|---|---|
| 1 | Tocar el micrófono | La primera vez, iOS pide permiso de micrófono y de reconocimiento de voz |
| 2 | Decir: "Quiero registrar una deuda de ciento veinte mil pesos con Banco Falabella" | La barra muestra la onda moviéndose y el tiempo |
| 3 | Tocar **✓** | El texto queda **en el campo, editable**; no se envía solo |
| 4 | Corregir si hace falta y tocar **↑** | Se envía como un mensaje escrito |
| 5 | Repetir y tocar **✕** mientras graba | Se descarta sin enviar nada |

**Resultado 02-10:** ✅ en el simulador iOS (reconocimiento en el dispositivo, `es-CL`). Falta probar en Android real.

---

## 8. Sesión y errores · ✅

| Caso | Cómo provocarlo | Debería pasar |
|---|---|---|
| Token vencido | Dejar la app ~15 min y escribir | Renueva el token sola y responde (sin "no reconoció tu sesión") |
| Sin red | Modo avión y escribir | "No pude conectarme al asistente. Revisa tu conexión." |
| Muchas consultas | Más de 20 mensajes en un minuto | "Hiciste muchas consultas seguidas…" |

---

## Resumen de la corrida 02-10

| Flujo | Estado |
|---|---|
| Registrar deuda | ✅ |
| Registrar compromiso | ⚠️ confirma pero no aparece en Pagos |
| Registrar ingreso/gasto | ⏳ no implementado en el agente |
| Consultas rápidas (3) | ✅ |
| FAQ concreta | ✅ |
| Botón "Ver preguntas frecuentes" | ❌ |
| Dictado por voz | ✅ iOS · falta Android |
| Renovación de token | ✅ |
