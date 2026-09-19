# G0 — Activación

**Pantalla UX:** A · Bienvenida  
**Fuentes:** `Walvy_Especificacion_UX_Onboarding_App.docx §4.1` · `Walvy_Onboarding_Diagnostico_Fase3_Reglas_Contextuales §9 G0`

---

## Propósito

Llevar al usuario desde su primer ingreso a la app hasta que comprende la propuesta de valor y decide comenzar el flujo de diagnóstico. No es un tutorial de funcionalidades. Es el momento de abrir con el problema del mes y la promesa de valor.

---

## Condiciones

| | Descripción |
|---|---|
| **Entrada** | Usuario llega a la pantalla de bienvenida por primera vez (o retoma sin ningún avance guardado) |
| **Avance** | Usuario comprende el valor y presiona "Comenzar" |
| **Bloqueo** | Ninguno — no existe bloqueo fuerte en G0 |
| **Salida hacia** | G1 (Foco del Mes) |

---

## Evento que declara esta puerta

```
advanceOnboardingStep({ currentGate: 'G0_activacion' })
```
Se dispara al entrar a la pantalla, no al salir.

---

## Contenido obligatorio de la pantalla

La pantalla debe comunicar tres cosas antes de pedir acción:

1. El problema que Walvy resuelve (el mes sin claridad)
2. La promesa de valor visible (diagnóstico, prioridad, próxima acción)
3. El esfuerzo mínimo requerido (no reconstruir toda la vida financiera — basta con cargar evidencia mínima)

**Secuencia de slides recomendada por la spec:**
- Slide 1: Problema del mes + promesa central
- Slide 2–3: Beneficios concretos que obtendrá al avanzar
- Slide 4: Anticipo del flujo + CTA dominante

---

## CTAs

| CTA | Tipo | Acción |
|---|---|---|
| Comenzar | Dominante — aparece en el último slide | Avanza a G1 |
| _(ninguno de salida)_ | — | La spec permite postergar, pero no define CTA explícita de salida en G0 |

---

## Postergación

**¿Puede pausarse?** Sí, sin castigo.

- Si el usuario cierra la app antes de presionar "Comenzar", no se pierde nada.
- La app no debe marcar el onboarding como fallido.
- Al volver, el usuario retoma desde G0 (Bienvenida) o desde la primera superficie que lo invite al flujo.
- El `current_gate` queda en `G0_activacion`.

---

## Variantes

| Caso | Tratamiento |
|---|---|
| Primera vez, sin ningún dato | Mostrar los slides completos |
| Retoma desde G0 (salió antes de Comenzar) | Mostrar slides completos desde el inicio — no existe avance que recuperar |

---

## Guardrails

- No abrir con listado de funcionalidades ni tour de menús
- No usar claims de IA mágica ni lenguaje bancario
- No pedir información al usuario en esta pantalla
- No mostrar formularios, tutoriales ni explicaciones técnicas
- No marcar el onboarding como fallido si el usuario sale antes de "Comenzar"

---

## UX Writing

| Elemento | Pauta |
|---|---|
| Tono | Claro, sereno, no punitivo |
| Foco | El problema del mes y qué ganará el usuario en minutos |
| Verbos | Empezar, comenzar, ver, rescatar, ordenar — nunca "completar perfil" ni "configurar" |
| Qué evitar | Jerga financiera, promesas abstractas, etiquetas técnicas |
