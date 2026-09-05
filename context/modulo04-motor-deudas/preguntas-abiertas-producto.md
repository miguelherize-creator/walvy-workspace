# M04 · Preguntas abiertas para Producto

Lo que el paso 1 de Ruta Despeje no puede cerrar sin una decisión. Cada punto
dice qué se ve hoy, qué dice cada fuente y qué se hizo mientras tanto, para que
la conversación empiece del hecho y no de la interpretación.

Levantado del código en `qa` y de los paquetes documentales en
`documentacion/modulo04-ini` y `modulo04-update`, contrastado contra Figma.

---

## 1 · La pestaña de Ruta Despeje no está en la documentación

**Lo que hay.** La barra inferior tiene una pestaña fija de Ruta despeje. Un
usuario puede tocarla en cualquier momento, incluso sin haber cargado nada.

**Lo que dice la doc.** Fase 2 define **dos entradas** al módulo, Perfil
Financiero y Home, y aclara que *"no son pantallas propias del Módulo 4"*. La
pestaña fija no aparece en ningún documento.

**Por qué importa.** Esa tercera entrada permite llegar al módulo sin datos, y
la doc no modela ese caso. Hoy el backend resuelve mandarlo directo a la carga
de documentos, así que el usuario toca "Ruta despeje" y aterriza en un
formulario con un stepper, sin que nada le explique qué es Ruta Despeje.

**Lo que dibujó diseño.** El frame `10145:24232` es el estado vacío de RD-01:
*"Todavía no hay deudas confirmadas"*, con **Cargar documentos** y **Continuar
más tarde**. Ese frame sólo tiene sentido si un usuario sin datos llega a RD-01.

**La contradicción.** Fase 2 describe RD-01 como *"mostrar situación, señal
principal, deuda prioritaria"* —supone que hay datos— y OD-01 como *"elegir cómo
agregar, subir o confirmar deuda"* —la pantalla de quien no tiene nada—. Figma y
Fase 2 responden a escenarios distintos porque la pestaña fija no existía cuando
se escribió la doc.

**Qué necesitamos.** Si la pestaña se queda, RD-01 necesita su estado vacío y hay
que cambiar la regla de entrada. Si no, sobra el frame. El cambio está listo y en
borrador: back-walvy#239.

---

## 2 · "Ver resultado" tiene tres reglas incompatibles

En la pantalla de Revisión, tres fuentes dicen cosas distintas sobre cuándo se
puede avanzar:

| Fuente | Regla |
|---|---|
| La pantalla | habilita con **al menos una deuda confirmada** |
| El backend | permite ver el resultado sólo cuando **no queda ninguna por confirmar** |
| El aviso de la propia pantalla | *"las deudas pendientes quedarán guardadas"* |

**En la práctica.** Con 3 deudas confirmo 1, veo el resultado y salgo. Al volver,
la app me devuelve a Revisión porque quedan pendientes. No hay forma de terminar
sin resolver las tres, aunque la pantalla prometa lo contrario.

**Qué necesitamos.** Cuál de las tres manda. No cambiamos ninguna hasta que se
defina.

---

## 3 · Tres pantallas sin frame

**Analizando** y **Resultado** están construidas contra ningún diseño. Se
hicieron partiendo de las pantallas equivalentes del onboarding, así que son
coherentes con el resto de la app, pero nadie de diseño las ha visto.

En **Revisión** el caso es más fino: los frames `5897:13762` y `5897:12967`
dibujan cada deuda como una fila **cerrada** con un chevron. No hay frame de lo
que aparece al abrirla, y es justo donde están Confirmar, Completar datos,
editar y descartar. Sin eso la pantalla no tiene ninguna acción posible, así que
se resolvió a criterio del equipo.

Dentro de eso, dos detalles: la **fila ya confirmada** no tiene estado dibujado
—hoy usa el verde de "verificado" del módulo— y falta decidir si **"Dejar
pendiente y salir"** es la única forma de posponer o si falta un gesto por deuda.

---

## 4 · Los estados por documento contradicen su propio frame

La nota de revisión pide "Subiendo documento", "Procesando documento",
"Documento leído", "No pudimos leer este documento": estados **de cada
documento**.

El frame de Analizando (`6670:13533`) dibuja otra cosa: **cinco pasos del proceso
completo** —"Archivos recibidos", "Leyendo movimientos", "Ubicando ingresos y
compromisos", "Detectando señales recurrentes", "Preparando tu primera
lectura"— con sus estados Completado / En progreso / Pendiente.

Los dos modelos no caben en la misma pantalla. Hoy está implementado el del
frame. **Qué necesitamos:** cuál gana, y si los estados por documento van en otra
superficie.

---

## 5 · Cuatro cosas menores sin definir

- **"Actualización de datos"**: la nota pide este CTA en Resultado, Resumen y
  Avance. No aparece en ninguno de los frames que tenemos.
- **Repositorio de pendientes**: la nota lo menciona como no diseñado. Si va a
  existir, cambia el texto del aviso de los documentos que quedan fuera.
- **Dos corales distintos**: Analizando usa `#EE8D78`, Revisión y Resultado
  `#EF9682`. Probablemente uno de los dos es el bueno.
- **Umbral del aviso de demora**: en el onboarding el modal sale a los 45s, un
  valor que aprobó Producto. En Ruta Despeje sale a los 15s, el valor por defecto
  del código. Misma operación, mismo backend, dos tiempos según por dónde entró.
  ¿Aplica el valor aprobado también acá?

---

## 6 · Un campo del formulario sin dónde guardarse

**"Última cuota pagada"** está en el frame de deuda manual (`5946:6498`) y quedó
fuera del formulario. El sistema guarda *cuotas que faltan* y el frame pide
*cuotas ya pagadas*: es el dato inverso. Con total 10 y última pagada 5 coinciden
por casualidad, pero son cosas distintas.

O el modelo gana un campo, o el formulario cambia a "Cuotas restantes". Abierto
con backend en KabeliDev/back-walvy#234.

---

## Lo que sí quedó cerrado

Para que la lista de arriba no parezca todo el módulo:

- Llegaron los frames de Revisión y la pantalla se rehízo contra ellos.
- El formulario de deuda manual guarda el saldo inicial.
- Descartar todas las deudas ya no deja al usuario encerrado sin salida.
- El análisis ya no pierde documentos si el usuario sale mientras procesa.
- El diagnóstico del onboarding ya lleva a Ruta Despeje cuando corresponde;
  antes dejaba al usuario en Inicio con un botón que decía "Confirmar deuda
  detectada".
