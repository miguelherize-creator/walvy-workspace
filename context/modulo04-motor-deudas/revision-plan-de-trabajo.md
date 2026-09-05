# M04 · Revisión (paso 2) · plan de trabajo

Lo que separa la pantalla de Revisión de sus frames, ordenado por prioridad.
Levantado contra los 13 frames de los escenarios A y B, y contra el código en
`qa`.

**Escenario A** — deudas detectadas, sólo falta confirmar.
**Escenario B** — deudas detectadas a las que además les faltan datos.

Los dos escenarios son la misma pantalla: lo que cambia es la fila.

---

## Lo que el diseño resolvió, y estaba abierto

**"Ver resultado" no tenía tres reglas: le faltaba un botón.** El frame
`5897:13872` tiene **dos**:

- `Ver resultado` — deshabilitado mientras quede algo por confirmar. Es
  exactamente lo que responde el backend en `canViewResult`.
- `Ver resultado con datos parciales` — habilitado con al menos una confirmada.

Las tres fuentes que parecían incompatibles describían dos acciones distintas.
**Queda cerrado el punto 2 de las preguntas abiertas.**

**La fila expandida sí tenía frame** (`5897:14114` y `5897:13324`). Lo que hoy
está implementado —iconos de editar y descartar— se resolvió a criterio cuando
creíamos que no existía diseño. **Queda cerrado el punto 3.**

**"Dejar pendiente" por deuda existe**, como enlace de la fila con datos
faltantes. Era la duda de si la salida global era el único gesto para posponer.

---

## P1 · La pantalla no coincide con el diseño

Sin esto, lo demás no encaja.

**1.1 · Dos cards, no una.** Hoy hay una sola card con todas las deudas y un
chip de estado por fila. El diseño separa en dos: chip naranja
`Deudas por confirmar: N` arriba, chip verde `Deudas confirmadas: N` abajo, cada
uno con su lista. El chip verde es el contador de la segunda card, no una
etiqueta de fila.

**1.2 · La fila expandida, en sus dos variantes.**

| | Datos completos (A) | Faltan datos (B) |
|---|---|---|
| Chip en la cabecera | — | `Faltan datos` amarillo |
| Datos | saldo actual · pago mínimo/cuota base · estado | sólo los que hay |
| Botón | `Confirmar deuda` | `Completar datos` |
| Enlaces | `Descartar deuda` · `Ver detalles` | `Descartar deuda` · `Dejar pendiente` |

**1.3 · Los dos botones del pie.** `Ver resultado` sólo con todas confirmadas;
`Ver resultado con datos parciales` con al menos una. Hoy hay uno solo, que se
habilita con una confirmada — o sea que hace lo del segundo con el nombre del
primero.

---

## P2 · Las tres superficies que faltan

**2.1 · Sheet "Completar datos"** (`5946:6824` · `5944:5675` · `5946:6918`).
Formulario con saldo actual*, saldo inicial, pago mínimo/cuota base*, última
cuota pagada, cuotas totales y próximo vencimiento*. `Guardar` deshabilitado
hasta los tres obligatorios; `Cancelar` al lado.

Dos reglas que vienen de las notas de diseño:

- **Guardar con los datos mínimos confirma automáticamente** y la deuda pasa a
  la card de confirmadas.
- **Cancelar sin completar** la devuelve a pendientes.

**2.2 · Sheet de detalle** (`5897:14355`), desde `Ver detalles`. Ocho campos:
saldo actual, saldo inicial, pago mínimo/cuota base, próximo vencimiento, último
pago realizado, monto, cuota (11 de 24) y estado. Al pie `Confirmar` y
`Descartar deuda`.

**2.3 · Modal de descartar** (`5897:14526`). Hoy dice *"¿La deuda no
corresponde?"* con botón *"No corresponde"*. El diseño dice **"¿Quieres
descartar la deuda?"**, cuerpo *"Al descartar la deuda no será considerada en tu
lectura ni afectará tu Salud de Deuda"*, y botones `Volver` · `Descartar`.

---

## P3 · Detalles

**3.1 · Toast "Deuda confirmada con éxito."** (`5897:13190`), verde, con cierre.

**3.2 · Copy de la sección.** El subtítulo cambia entre escenarios y ya está
implementado; conviene verificar que A y B usen el suyo.

---

## Lo que depende del backend

**Todos los datos existen**, pero repartidos entre dos respuestas:

| Dato | Dónde está | Falta |
|---|---|---|
| `principalInitial` · `paidInstallments` | ya vienen en la lista | el tipo `Debt` del front no los declara |
| `paymentState` (`al_dia` / `atrasado`) | sólo en `GET /debts/:id` | la **fila expandida** lo muestra como "Estado" |
| `lastPayment { paidAt, amount }` | sólo en `GET /debts/:id` | el sheet de detalle lo necesita |

La fila expandida obliga a decidir: o se llama al detalle al expandir cada
deuda, o se pide que `paymentState` viaje también en la lista. **Lo segundo es
una línea en el backend y evita una llamada por fila.**

**"Última cuota pagada"** aparece en el formulario de completar datos, y el
modelo guarda *cuotas restantes*. Es el issue KabeliDev/back-walvy#234, y este
frame confirma que el dato que Producto quiere es el pagado, no el restante.

---

## Orden sugerido

1. **P1 completo** en un PR: la pantalla queda fiel y se puede probar el flujo A
   de punta a punta.
2. **`paymentState` en la lista** — desbloquea el "Estado" de la fila.
3. **P2.1 y P2.3** — con eso el escenario B queda completo.
4. **P2.2** — el detalle es el único que necesita `GET /debts/:id`.
5. **P3**.

El escenario A queda usable al terminar el 1; el B, al terminar el 3.
