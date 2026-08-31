# Agenda — kickoff de septiembre · lunes 31 de agosto

**Duración:** 60 minutos · **Convoca:** Miguel
**Asisten:** Miguel Herize, Leonardo, Sergio Vidal
**Referencia:** [`back-walvy#184`](https://github.com/KabeliDev/back-walvy/issues/184) — plan de coordinación

---

## Objetivo

Salir con **cuatro acuerdos escritos**, con dueño y fecha, para que los tres módulos puedan avanzar en
paralelo sin que nadie quede esperando a otro. No es una reunión de planificación: el plan ya está escrito.
Es una reunión de decisiones.

**Al terminar, cada acuerdo queda publicado como comentario en el #184.** Si algo no se cerró, se anota
quién lo cierra y cuándo — no queda «pendiente de conversar».

---

## Antes de entrar

| Quién | Qué |
|---|---|
| Todos | Leer el #184 completo (10 min) |
| Leonardo | Traer identificadas las dudas sobre el árbol de categorías: qué necesita M6 que hoy no esté |
| Miguel | Traer el borrador del catálogo de acciones sugeridas y la firma propuesta de la interfaz de señales |
| Sergio | Nada. Es su primer día: viene a escuchar |

> **Sobre Sergio:** entra hoy y no tiene contexto todavía. Participa como oyente, no se le pide opinión
> técnica. Lo que sí sale de acá es su encargo de la semana. Antes de esta reunión conviene una bienvenida
> corta y aparte (15 min), no meterlo directo a una discusión de contratos.

---

## Agenda

### 1 · Objetivo y qué NO se decide hoy — 5 min · Miguel

Se cierra el mecanismo de trabajo, no el alcance de los módulos.

**Fuera de esta reunión:** el alcance detallado de cada módulo, el reparto del acompañamiento a Sergio
(es con la PM), y los tres focos que hoy no tienen acción asociada (dependen del catálogo del punto 3).

### 2 · Reparto, fechas y el calendario de septiembre — 10 min · Miguel

Informativo, no se debate.

| Módulo | Responsable | Entrega |
|---|---|---|
| M4 — Motor de Deudas / Ruta Despeje | Miguel | jueves 10 de septiembre |
| M5 — Cashflow | Sergio | miércoles 23 de septiembre |
| M6 — Presupuesto | Leonardo | miércoles 30 de septiembre |

Puntos a dejar dichos:
- Por qué M5 y M6 se intercambiaron.
- **La semana del 14 rinde tres días** por Fiestas Patrias. No planificar nada crítico ahí.
- M6 consume M5, así que un corrimiento de Sergio se propaga a Leonardo.

### 3 · Contrato del árbol de categorías — 15 min · dueño Sergio, decide Leonardo

**Es el punto más importante de la reunión.** Es lo que permite que Leonardo construya todo M6 sin esperar
la entrega del 23.

- El árbol **ya existe y está sembrado**. No se rediseña.
- Tiene **tres consumidores**: M6, la aplicación móvil y el servicio de extracción documental.
- Leonardo plantea qué necesita M6; se resuelve si sale de lo que ya hay o si falta algo.

**Decisión a tomar:** Sergio documenta el contrato tal como está en el código y lo **congela el viernes 4**.
Leonardo programa contra eso desde el martes, con stub.

### 4 · Catálogo de acciones sugeridas — 10 min · Miguel

Hoy es una lista cerrada validada contra la base de datos, y los tres módulos quieren agregar tipos.

**Decisión a tomar:** se define el catálogo **completo** en esta reunión —incluidos los tres focos hoy sin
acción— y entra en **una sola migración**, esta semana, a cargo de Miguel. Después de hoy nadie agrega
tipos sueltos.

### 5 · Interfaz de señales al diagnóstico y dueños de archivos — 10 min · Miguel

Los tres módulos tienen que alimentar la misma función, y ahí es donde chocarían.

**Decisión a tomar:** cada módulo entrega un servicio con una firma acordada hoy. El archivo del motor de
diagnóstico tiene **un solo dueño: Miguel**, y nadie más lo edita en septiembre.

Mismo criterio para los otros dos archivos compartidos: el catálogo de acciones y el layout de pestañas de
la aplicación son de Miguel. Sergio y Leonardo reemplazan el contenido de **su** pantalla, que ya está
declarada.

### 6 · Rangos de migración — 5 min · Miguel

Hoy el número se asigna a mano y correlativo: tres personas en paralelo colisionan, y el orden de ejecución
cambiaría según quién integre primero.

| Módulo | Rango |
|---|---|
| M4 | `1786000034000` – `1786000039000` |
| M5 | `1786000040000` – `1786000049000` |
| M6 | `1786000050000` – `1786000059000` |

**Decisión a tomar:** el número se toma **antes** de crear el archivo, avisando en el canal del equipo.

### 7 · Compromisos de la semana y cierre — 5 min

| Quién | Esta semana | Entrega |
|---|---|---|
| Miguel | Ruta Despeje publica su estado agregado + la migración del catálogo | viernes 4 |
| Sergio | Onboarding, inventario de M5 y contrato de categorías documentado | viernes 4 |
| Leonardo | Módulo de presupuesto desde cero, contra el contrato | viernes 4 |

---

## Salidas obligatorias de la reunión

1. Los cuatro acuerdos publicados como comentario en el **#184**.
2. El catálogo de acciones sugeridas, escrito y completo.
3. La firma de la interfaz de señales, escrita.
4. Fecha de congelamiento del contrato de categorías: **viernes 4**.

Si a los 60 minutos falta cerrar alguno, se anota dueño y fecha y se sigue por escrito. No se extiende la
reunión: los tres tienen que empezar a trabajar hoy.

---

## Después de la reunión, el mismo lunes

Aparte y solo con Sergio, dentro de su día 1 —está en el plan de onboarding—:

- Los **dos remotes** de cada repositorio, que es el error más caro posible.
- Cómo se citan las reglas de la matriz en los commits.
- PRs contra `main`, nunca apilados.
- La regla explícita: **trabado más de 45 minutos, preguntá.**
