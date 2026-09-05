# M04 · Preguntas abiertas para Producto

Lo que el paso 1 de Ruta Despeje no puede cerrar sin una decisión. Cada punto
dice qué se ve hoy, qué dice cada fuente y qué se hizo mientras tanto, para que
la conversación empiece del hecho y no de la interpretación.

Levantado del código en `qa` y de los paquetes documentales en
`documentacion/modulo04-ini` y `modulo04-update`, contrastado contra Figma.

Va a Producto y a Diseño: los puntos 2 y 6 necesitan una decisión de producto;
los 3, 4 y 5 necesitan frames o definición de diseño. El punto 1 quedó resuelto
y se conserva porque la documentación sigue sin cubrirlo. Este documento
reemplaza el correo que se iba a enviar por separado.

---

## 1 · La pestaña de Ruta Despeje no está en la documentación

**Resuelto por el prototipo de Figma.** Se deja escrito porque la documentación
sigue sin cubrirlo y el próximo que la lea va a tropezar igual.

**Lo que hay.** La barra inferior tiene una pestaña fija de Ruta despeje. Un
usuario puede tocarla en cualquier momento, incluso sin haber cargado nada.

**Lo que dice la doc.** Fase 2 define **dos entradas** al módulo, Perfil
Financiero y Home, y aclara que *"no son pantallas propias del Módulo 4"*. La
pestaña fija no aparece en ningún documento. Con esas dos entradas, mandar a
capturar tenía sentido: el usuario ya venía derivado desde otra pantalla.

**Lo que dibujó diseño.** El frame `10145:24229` es esta pantalla completa e
**incluye la barra inferior con "Ruta despeje" marcada**. El cable del prototipo
va de su botón *Cargar documentos* a `5897:11646`, la Carga. O sea que el
recorrido previsto es:

```
pestaña Ruta despeje → RD-01 estado vacío → "Cargar documentos" → OD-01 Carga
```

**Conclusión.** La documentación no está equivocada: está incompleta respecto de
la app que existe. La pestaña permanente es posterior y crea una entrada sin
contexto que el frame resuelve. El cambio está en back-walvy#239.

**Lo que queda por decidir.** Con esto ninguna rama de la regla de entrada
devuelve ya "ir a capturar". Si Producto quiere conservar ese empujón directo
para algún caso, hace falta un disparador distinto de "no tiene deudas".

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

## 3 · Lo que falta dibujar

**Resultado** está construida contra ningún diseño. Se hizo partiendo de la
pantalla equivalente del onboarding, así que es coherente con el resto de la
app, pero nadie de diseño la ha visto.

En **Revisión** el caso es más fino: los frames `5897:13762` y `5897:12967`
dibujan cada deuda como una fila **cerrada** con un chevron. No hay frame de lo
que aparece al abrirla, y es justo donde están Confirmar, Completar datos,
editar y descartar. Sin eso la pantalla no tiene ninguna acción posible, así que
se resolvió a criterio del equipo.

Dentro de eso, dos detalles: la **fila ya confirmada** no tiene estado dibujado
—hoy usa el verde de "verificado" del módulo— y falta decidir si **"Dejar
pendiente y salir"** es la única forma de posponer o si falta un gesto por deuda.

*(Analizando ya tiene su frame: `6670:13533`. Ver el punto 4.)*

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

## Decisiones que tomamos para no detener el módulo

Tres cosas se resolvieron a criterio del equipo porque bloqueaban el avance.
Siguen el criterio del propio diseño, pero conviene confirmarlas.

**Se sacó "Confirmar después" de Revisión.** No estaba en los frames nuevos y no
hacía nada. Hoy la forma de posponer es un único "Dejar pendiente y salir" al pie
de la pantalla, no un gesto por deuda. Si el gesto por deuda estaba pensado, hay
que reponerlo.

**"Dejar pendiente y salir" lleva a Inicio**, no a Ruta Despeje. Volviendo a Ruta
Despeje la app rebota a Revisión otra vez, así que habría sido un botón que no
sale de ninguna parte.

**La fila ya confirmada usa el verde de "verificado"** del módulo, para no
inventar un color que el diseño no definió.

---

## Un dato que el backend manda y no usamos

Cuando el diagnóstico propone confirmar una deuda, el backend nombra **cuál**
(`refId`). Hoy se ignora: no hay pantalla de una deuda sola a la que llevar al
usuario, así que se abre la lista completa. Si esa pantalla va a existir, el dato
ya está disponible.

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
