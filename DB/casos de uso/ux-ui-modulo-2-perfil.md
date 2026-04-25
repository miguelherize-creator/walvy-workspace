# Requerimientos UX/UI — Módulo 2: Perfil Financiero

> Documento de ideación para el diseño de pantallas. Complementa `uc-modulo-2-perfil.md`.
> Paleta y tokens: `ai/rules.md → UI y UX` y `expo/constants/colors.ts`.

---

## Índice de pantallas

| # | Pantalla | Acceso |
|---|----------|--------|
| P1 | **Perfil principal** (hub) | Tab "Perfil" |
| P2 | **Datos financieros** (ingreso, gastos fijos, día de corte) | Desde P1 |
| P3 | **Metas financieras** (lista + creación/edición) | Desde P1 |
| P4 | **Preferencias de alertas** | Desde P1 |
| P5 | **Seguridad** (email, contraseña) | Desde P1 |

---

## P1 — Pantalla: Perfil Principal (Hub)

### Propósito
Punto de entrada central del módulo. El usuario ve un resumen de su situación y navega a las sub-secciones.

### Estructura visual propuesta

```
┌─────────────────────────────────────┐
│  Header: "Mi Perfil"                │
│  (fondo deepTeal o bg sand claro)   │
├─────────────────────────────────────┤
│                                     │
│   [Avatar / Iniciales]              │
│   Nombre completo                   │
│   carlos@email.com                  │
│                                     │
├─────────────────────────────────────┤
│  TARJETA: Resumen Financiero        │
│  ┌───────────────────────────────┐  │
│  │  Ingreso mensual   $X.XXX     │  │
│  │  Gastos fijos      $X.XXX     │  │
│  │  ─────────────────────────    │  │
│  │  Capacidad de pago $X.XXX ✓   │  │
│  └───────────────────────────────┘  │
│                                     │
│  SECCIÓN: Metas activas             │
│  ┌───────────────────────────────┐  │
│  │  🎯 Reducir deuda  [▓▓▓░░] 60%│  │
│  │  💰 Ahorrar $500k  [▓░░░░] 20%│  │
│  └───────────────────────────────┘  │
│                                     │
│  MENÚ DE NAVEGACIÓN                 │
│  ≡ Datos financieros        >       │
│  ≡ Metas                    >       │
│  ≡ Alertas y notificaciones >       │
│  ≡ Seguridad                >       │
│  ≡ Cerrar sesión           [rojo]   │
│                                     │
└─────────────────────────────────────┘
```

### Requerimientos detallados

**Avatar / Identidad:**
- Círculo con iniciales del nombre en `oceanTeal` si no hay foto.
- Fondo del avatar en `mintSoft`.
- Nombre en `textPrimary` (bold), email en `textSecondary` (regular).
- Opcionalmente: toque en el área de avatar podría permitir cargar foto (fuera del MVP, marcar como v2).

**Tarjeta resumen financiero:**
- Fondo `card` (blanco), borde sutil `border` (`mintSoft`), borderRadius `md`.
- Tres filas: Ingreso / Gastos fijos / Capacidad de pago.
- Capacidad de pago resaltada con color `green` si es positiva, `red` si es ≤ 0.
- Si la capacidad es negativa: mostrar ícono de advertencia (⚠️) y texto corto "Tus gastos superan tu ingreso".
- Si el perfil no está completado: reemplazar la tarjeta con un CTA prominente en `coral` → "Completa tu perfil financiero".

**Mini-resumen de metas:**
- Máximo 2 metas en vista previa (las más recientes o las de mayor urgencia).
- Barra de progreso delgada (height 4–6px), relleno en `oceanTeal` o `green` según avance.
- Texto de porcentaje al lado derecho.
- Link "Ver todas" al final si hay más metas.

**Menú de navegación:**
- Filas tipo "list item": ícono a la izquierda, label en `textPrimary`, chevron `›` en `textSecondary`.
- Separador sutil entre filas (1px, color `border`).
- "Cerrar sesión" en `red` (sin chevron, sin ícono de navegación).
- Espaciado vertical generoso entre secciones (usar `spacing.lg` entre tarjeta y menú).

**Estado de onboarding incompleto:**
- Si `financial_profile_completed = false`: banner sutil en la parte superior con fondo `coral` semitransparente + texto "Completa tu perfil para acceder a todas las funciones".
- El ítem "Datos financieros" puede tener un badge de punto naranja/coral indicando acción pendiente.

---

## P2 — Pantalla: Datos Financieros

### Propósito
Formulario para ingresar/editar ingreso mensual, gastos fijos y día de corte del período.

### Estructura visual propuesta

```
┌─────────────────────────────────────┐
│  ← Datos financieros                │
├─────────────────────────────────────┤
│                                     │
│  SECCIÓN: Tu situación mensual      │
│                                     │
│  Ingreso mensual neto               │
│  ┌───────────────────────────────┐  │
│  │  $  [      1.200.000       ]  │  │
│  └───────────────────────────────┘  │
│  Hint: "Lo que recibes después      │
│  de impuestos y descuentos"         │
│                                     │
│  Gastos fijos mensuales             │
│  ┌───────────────────────────────┐  │
│  │  $  [       450.000        ]  │  │
│  └───────────────────────────────┘  │
│  Hint: "Arriendo, servicios,        │
│  suscripciones, etc."               │
│                                     │
│  Día de corte del período           │
│  ┌───────────────────────────────┐  │
│  │  [  1  ] [ 5 ] [10] [15]     │  │
│  │  [20 ] [25] [28] [30]        │  │
│  └───────────────────────────────┘  │
│  Hint: "El día en que empieza       │
│  tu período de presupuesto"         │
│                                     │
│  ──────────────────────────────     │
│  VISTA PREVIA: Capacidad de pago    │
│  ┌───────────────────────────────┐  │
│  │  Puedes destinar              │  │
│  │       $750.000/mes            │  │
│  │  a deudas y metas 🎯          │  │
│  └───────────────────────────────┘  │
│                                     │
│  [ Guardar cambios ]  (oceanTeal)   │
│                                     │
└─────────────────────────────────────┘
```

### Requerimientos detallados

**Campos numéricos:**
- Input con formato de moneda local (separador de miles con punto, sin decimales para CLP).
- Teclado numérico al enfocar (`keyboardType="numeric"`).
- Prefijo "$" fijo a la izquierda del campo, en `textSecondary`.
- Fondo `inputBg` (blanco), borde `border` en reposo; borde `oceanTeal` al enfocar.
- Validación en tiempo real (no bloquear, solo mostrar estado visual).

**Validaciones visuales:**
- Si `gastos_fijos >= ingreso_mensual`: borde del campo en `red`, mensaje de error debajo "Los gastos superan el ingreso mensual".
- Si algún campo está vacío al intentar guardar: shake animation sutil + borde `red`.
- Checkmark `green` al lado del campo cuando el valor es válido.

**Selector de día de corte:**
- Grid de chips/botones (no un picker clásico): `[ 1 ][ 5 ][10][15][20][25][28][Último]`.
- Chip seleccionado: fondo `oceanTeal`, texto blanco.
- Chip no seleccionado: fondo `card`, texto `textPrimary`, borde `border`.
- `borderRadius` pill en los chips.

**Vista previa de capacidad de pago:**
- Caja de resultado que se actualiza en tiempo real conforme el usuario escribe.
- Si capacidad > 0: fondo suave `green` semitransparente, texto en `green` oscuro, ícono ✓.
- Si capacidad ≤ 0: fondo suave `red` semitransparente, texto en `red`, ícono ⚠️ + "Tus gastos fijos superan tu ingreso".
- Transición suave al cambiar el valor (no saltar bruscamente).

**Botón guardar:**
- Ancho completo, fondo `oceanTeal`, texto blanco, `borderRadius md`.
- Estado `loading` con spinner mientras el request está en curso.
- Estado `disabled` si no hay cambios o hay errores de validación.
- Toast de confirmación al guardar exitosamente: "Perfil actualizado ✓" (bottom toast, 2s).

**Flujo de onboarding (primera vez):**
- Título diferente: "Cuéntanos sobre tus finanzas" en lugar de "Datos financieros".
- Subtítulo motivacional: "Esta información nos permite darte sugerencias personalizadas".
- Botón dice "Continuar" en lugar de "Guardar cambios".
- Después de guardar, redirigir al paso siguiente del onboarding (metas).

---

## P3 — Pantalla: Metas Financieras

### Propósito
Lista de metas activas con progreso, creación de nuevas metas y edición de existentes.

### Estructura visual propuesta — Vista lista

```
┌─────────────────────────────────────┐
│  ← Mis metas                  [+]   │
├─────────────────────────────────────┤
│                                     │
│  METAS ACTIVAS (3)                  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  🎯 Reducir mis deudas        │  │
│  │  "Sin deudas al 2026"         │  │
│  │  [▓▓▓▓▓░░░░░] 52%             │  │
│  │  $1.200.000 reducidos         │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  💰 Ahorrar para emergencias  │  │
│  │  Meta: $500.000               │  │
│  │  [▓▓░░░░░░░░] 24%             │  │
│  │  Fecha límite: Jun 2026       │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📅 No atrasar pagos          │  │
│  │  3 meses consecutivos ✓       │  │
│  │  [▓▓▓░░░░░░░] 30%             │  │
│  └───────────────────────────────┘  │
│                                     │
│  METAS COMPLETADAS (1)  [ver >]     │
│                                     │
│  [ + Agregar nueva meta ]           │
│    (botón outline, oceanTeal)       │
│                                     │
└─────────────────────────────────────┘
```

### Estructura visual propuesta — Crear/editar meta

```
┌─────────────────────────────────────┐
│  ← Nueva meta                       │
├─────────────────────────────────────┤
│                                     │
│  ¿Cuál es tu objetivo?              │
│                                     │
│  ┌─────────┐ ┌─────────┐            │
│  │ 🎯      │ │ 💰      │            │
│  │ Reducir │ │ Ahorrar │            │
│  │ deudas  │ │ dinero  │            │
│  └─────────┘ └─────────┘            │
│  ┌─────────┐ ┌─────────┐            │
│  │ 📈      │ │ 📅      │            │
│  │ Mejorar │ │ No      │            │
│  │ capacid.│ │ atrasar │            │
│  └─────────┘ └─────────┘            │
│  ┌─────────┐ ┌─────────┐            │
│  │ 📊      │ │ ✏️      │            │
│  │ Cumplir │ │ Otra    │            │
│  │ presup. │ │ meta    │            │
│  └─────────┘ └─────────┘            │
│                                     │
│  Descripción (opcional)             │
│  ┌───────────────────────────────┐  │
│  │ "Sin deudas para diciembre"   │  │
│  └───────────────────────────────┘  │
│                                     │
│  Monto objetivo (si aplica)         │
│  ┌───────────────────────────────┐  │
│  │  $  [        500.000       ]  │  │
│  └───────────────────────────────┘  │
│                                     │
│  Fecha límite (opcional)            │
│  ┌───────────────────────────────┐  │
│  │  📅 Seleccionar fecha          │  │
│  └───────────────────────────────┘  │
│                                     │
│  [ Crear meta ]  (oceanTeal)        │
│                                     │
└─────────────────────────────────────┘
```

### Requerimientos detallados

**Tarjetas de meta:**
- Fondo `card`, borde izquierdo de 3px en color según tipo:
  - `reduce_debt` → `red` / coral
  - `save_amount` → `green`
  - `improve_savings_capacity` → `oceanTeal`
  - `avoid_late_payments` → `yellow`
  - `meet_budget` → `deepTeal`
  - `other` → `textSecondary`
- Ícono emoji o SVG representativo del tipo de meta.
- Barra de progreso: gruesa (8px), bordes redondeados, color del acento izquierdo.
- Porcentaje de progreso al lado derecho de la barra (texto `sm`, `textSecondary`).
- Swipe-to-archive (o botón de tres puntos `⋮`) para archivar/eliminar meta.

**Selector de tipo de meta:**
- Grid de tarjetas 2×3, cada una con ícono grande + label corto.
- Tarjeta seleccionada: borde `oceanTeal` (2px), fondo tenue `mintSoft`.
- Tarjeta no seleccionada: fondo `card`, borde `border`.
- Al seleccionar "Otra meta": aparece campo de texto libre para descripción personalizada.

**Campos condicionales:**
- "Monto objetivo" solo visible si el tipo es `save_amount` o `reduce_debt`.
- "Número de meses" visible para `avoid_late_payments` y `meet_budget`.
- Animación de expand/collapse suave al cambiar el tipo.

**Estado vacío (sin metas):**
- Ilustración simple centrada (icono de bandera o estrella en `mintSoft`).
- Texto: "Aún no tienes metas definidas".
- Subtexto: "Define lo que quieres lograr con tus finanzas".
- CTA coral: "Crear primera meta".

**Metas completadas:**
- Sección colapsada por defecto con label "Completadas (N) →".
- Al expandir: tarjetas en escala de grises (opacidad 60%) con badge "✓ Completada".

---

## P4 — Pantalla: Preferencias de Alertas

### Propósito
Configurar qué notificaciones recibe el usuario, por qué canal y con qué frecuencia.

### Estructura visual propuesta

```
┌─────────────────────────────────────┐
│  ← Alertas y notificaciones         │
├─────────────────────────────────────┤
│                                     │
│  Controla cuándo y cómo te          │
│  avisamos sobre tu situación.       │
│                                     │
│  PRESUPUESTO                        │
│  ┌───────────────────────────────┐  │
│  │  📊 Umbral de presupuesto     │  │
│  │  Al superar el 80% de una     │  │
│  │  categoría                    │  │
│  │  In-app          [  ●  ON  ]  │  │
│  └───────────────────────────────┘  │
│                                     │
│  PAGOS Y VENCIMIENTOS               │
│  ┌───────────────────────────────┐  │
│  │  📅 Recordatorio de pago      │  │
│  │  7, 3 y 1 día antes           │  │
│  │  Push            [  ●  ON  ]  │  │
│  │  Email           [  ●  ON  ]  │  │
│  └───────────────────────────────┘  │
│                                     │
│  IMPORTACIÓN DE CARTOLA             │
│  ┌───────────────────────────────┐  │
│  │  📄 Recordatorio de importar  │  │
│  │  Si no has importado en:      │  │
│  │  [ 7 días ] [14 días] [30d]   │  │
│  │  Push            [  ●  ON  ]  │  │
│  └───────────────────────────────┘  │
│                                     │
│  RESÚMENES                          │
│  ┌───────────────────────────────┐  │
│  │  📈 Semáforo financiero       │  │
│  │  Cuando tu estado cambia      │  │
│  │  In-app          [  ●  ON  ]  │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  📧 Resumen semanal           │  │
│  │  Todos los domingos           │  │
│  │  Email           [  ●  ON  ]  │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### Requerimientos detallados

**Switches:**
- Switch nativo de la plataforma o custom con estética Walvy.
- Encendido: fondo `oceanTeal`.
- Apagado: fondo gris claro (`textSecondary` tenue).
- Actualización optimista: cambia visualmente al instante, revierte si el request falla con toast de error.

**Agrupación por categoría:**
- Header de sección en texto `sm` uppercase, color `textSecondary` (ej: "PAGOS Y VENCIMIENTOS").
- Separador sutil entre grupos.
- Cada grupo en una tarjeta card con borde o sin borde, según el diseño.

**Selector de cadencia (frecuencia):**
- Para alertas con `cadence_days`: chips horizontales seleccionables (`7 días`, `14 días`, `30 días`).
- Chip activo: fondo `oceanTeal`, texto blanco.
- Chip inactivo: fondo `card`, texto `textPrimary`, borde `border`.
- Solo visible cuando el switch de esa alerta está encendido.

**Canal de notificación:**
- Separar claramente Push vs. Email vs. In-app cuando un mismo tipo tiene múltiples canales.
- Ícono de canal pequeño a la izquierda del switch (🔔 push / 📧 email / 📲 in-app).

**Feedback de permisos del sistema:**
- Si el usuario tiene Push desactivado a nivel del sistema: mostrar banner informativo amarillo (no bloqueante) con link a configuración del dispositivo.
- Texto: "Las notificaciones push están desactivadas en tu dispositivo".

---

## P5 — Pantalla: Seguridad (Email y Contraseña)

### Propósito
Cambiar email o contraseña de acceso. Flujo de confirmación con contraseña actual.

### Estructura visual propuesta

```
┌─────────────────────────────────────┐
│  ← Seguridad                        │
├─────────────────────────────────────┤
│                                     │
│  CUENTA                             │
│  ┌───────────────────────────────┐  │
│  │  Email actual                 │  │
│  │  carlos@email.com             │  │
│  │  [Cambiar email  >]           │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Contraseña                   │  │
│  │  Última actualización: —      │  │
│  │  [Cambiar contraseña  >]      │  │
│  └───────────────────────────────┘  │
│                                     │
│  SESIONES ACTIVAS                   │
│  ┌───────────────────────────────┐  │
│  │  Dispositivo actual           │  │
│  │  iPhone 14 · Activo ahora     │  │
│  └───────────────────────────────┘  │
│                                     │
│  [ Cerrar todas las sesiones ]      │
│    (outline, color red)             │
│                                     │
└─────────────────────────────────────┘
```

### Sub-pantalla: Cambiar contraseña

```
┌─────────────────────────────────────┐
│  ← Cambiar contraseña               │
├─────────────────────────────────────┤
│                                     │
│  Contraseña actual                  │
│  ┌───────────────────────────────┐  │
│  │  ●●●●●●●●          [👁 ver]   │  │
│  └───────────────────────────────┘  │
│                                     │
│  Nueva contraseña                   │
│  ┌───────────────────────────────┐  │
│  │  ●●●●●●●●          [👁 ver]   │  │
│  └───────────────────────────────┘  │
│                                     │
│  Indicador de fortaleza:            │
│  [▓▓▓░░] Media                      │
│  ✓ 8+ caracteres                    │
│  ✓ Mayúscula y minúscula            │
│  ✓ Un número                        │
│  ✗ Carácter especial (pendiente)    │
│                                     │
│  Confirmar nueva contraseña         │
│  ┌───────────────────────────────┐  │
│  │  ●●●●●●●●          [👁 ver]   │  │
│  └───────────────────────────────┘  │
│                                     │
│  [ Actualizar contraseña ]          │
│    (oceanTeal, disabled si inválido)│
│                                     │
└─────────────────────────────────────┘
```

### Requerimientos detallados

**Inputs de contraseña:**
- Toggle de visibilidad (ojo) en el lado derecho del input.
- `secureTextEntry` por defecto.
- Fondo `inputBg`, borde `oceanTeal` al enfocar.

**Indicador de fortaleza de contraseña:**
- Barra segmentada en 5 niveles: Muy débil / Débil / Media / Fuerte / Muy fuerte.
- Colores progresivos: `red` → `yellow` → `green`.
- Checklist de requisitos debajo de la barra (los de la regla de validación del backend):
  - Mínimo 8 caracteres
  - Al menos una mayúscula
  - Al menos una minúscula
  - Al menos un número
  - Al menos un carácter especial
- Cada ítem: ✓ verde cuando cumple, ✗ gris/rojo cuando no.

**Flujo de éxito al cambiar contraseña:**
- Modal o full-screen de confirmación: "Contraseña actualizada" + ícono ✓ en `green`.
- Mensaje: "Por seguridad, deberás iniciar sesión nuevamente".
- Botón "Aceptar" → cierra sesión y lleva a `/login`.
- No usar navegación `back` en este estado (para evitar inconsistencias de sesión).

**Cambio de email:**
- Campo de nuevo email + campo de contraseña actual (confirmación).
- Validación de formato de email en tiempo real.
- Si el email ya está en uso: error inline "Este correo ya está registrado".
- Al guardar exitosamente: banner informativo "Revisa tu nuevo correo para verificarlo".

---

## Consideraciones transversales de UX

### Navegación

- Todas las sub-pantallas usan navegación `push` (Stack), con header con flecha `←` de regreso.
- El título del header es conciso (máx. 25 caracteres).
- El tab de "Perfil" en la barra inferior usa ícono de persona/usuario.

### Manejo de errores

| Escenario | Comportamiento |
|-----------|---------------|
| Sin conexión al guardar | Toast: "Sin conexión. Los cambios se guardarán cuando vuelvas a conectarte." (si hay modo offline eventual) o "Revisa tu conexión e intenta de nuevo." |
| Error 400 de validación | Error inline bajo el campo específico, en `red`, texto `sm`. |
| Error 409 (email en uso) | Error inline en campo de email. |
| Error 500 | Toast genérico: "Algo salió mal. Intenta de nuevo en unos segundos." |
| Token expirado | Interceptor redirige a login automáticamente. |

### Estados de carga

- Botones de acción muestran spinner + texto "Guardando…" durante el request.
- Pantalla principal (P1) con skeleton loader mientras carga el perfil.
- No bloquear toda la pantalla con un full-screen loader; preferir indicadores locales.

### Feedback al usuario

- Toast de éxito siempre al fondo de la pantalla, duración 2–3 segundos, fondo `deepTeal` + texto blanco.
- Toast de error: fondo `red` (suave), texto `red` oscuro.
- Cambios de estado de alertas: actualizados optimistamente (sin esperar respuesta del servidor).

### Accesibilidad básica

- Todos los controles interactivos con tamaño de toque mínimo de 44×44px.
- Labels descriptivos en inputs (`accessibilityLabel`).
- Colores nunca son el único diferenciador de estado (acompañar con ícono o texto).
- Contraste mínimo AA para texto sobre fondos de la paleta Walvy.

### Dark mode

- Usar siempre tokens `theme.*` vía `useTheme()`, nunca hex directos en JSX.
- En tarjetas con fondo `theme.card`, usar `theme.cardTextPrimary` y `theme.cardTextSecondary` para garantizar contraste en dark mode.
- Switches y chips: adaptar fondo al modo (fondos de chips claros en light, oscuros en dark).

---

## Mapa de flujos principales

```
TAB "Perfil"
    │
    ├─► P1 Hub
    │     ├─► P2 Datos Financieros ──► [Guardar] ──► P1 (actualizada)
    │     ├─► P3 Metas
    │     │     ├─► Lista de metas
    │     │     └─► [+] Crear meta ──► [Guardar] ──► Lista (actualizada)
    │     ├─► P4 Alertas ──► [Toggle/cadencia] ──► actualización optimista
    │     └─► P5 Seguridad
    │           ├─► Cambiar contraseña ──► [Éxito] ──► Logout ──► /login
    │           └─► Cambiar email ──► [Éxito] ──► P5 (mensaje verificación)
    │
ONBOARDING (primer acceso)
    │
    └─► P2 Datos Financieros → P3 Crear primera meta → Home dashboard
```

---

## Relación con otros módulos (datos que alimentan)

| Dato del perfil | Dónde se consume en la app |
|-----------------|---------------------------|
| `estimated_payment_capacity` | Home: "Puedes destinar $X a deudas" |
| `estimated_payment_capacity` | M4 Bola de Nieve: pago extra sugerido |
| `estimated_payment_capacity` | M6 Presupuesto: sugerencia inicial de montos |
| `pay_day` | M6 Presupuesto: define inicio/fin del período |
| Metas activas + progreso | Home: mini-cards de metas |
| `alert_preferences` | Sistema de notificaciones (push/email) |
