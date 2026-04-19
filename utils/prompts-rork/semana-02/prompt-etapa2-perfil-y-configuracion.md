# Walvy — Etapa 2: Perfil y configuración (prompt para Rork.ai)

Usa este documento como **brief único** para implementar la **Etapa 2** del MVP en la app móvil **Walvy** (React Native / Expo, TypeScript), conectada al backend existente (NestJS / API REST) cuando aplique.

**Alcance de esta etapa:** perfil de usuario, preferencias de notificaciones y alertas (matriz por defecto, sin motor libre), perfil financiero básico con capacidad estimada de pagos y presupuesto sugerido, y definición de **meta financiera global** (distinta de metas por categoría del presupuesto).

---

## Contexto técnico (asumir)

- Proyecto Expo con TypeScript, navegación por archivos (`expo-router`) o equivalente acordado en el repo.
- Estado de auth y tema ya existentes; **extender** sin romper flujos de login / dashboard.
- Reutilizar tokens de diseño Walvy (`constants/colors`, `constants/theme`) y patrones de pantalla ya usados (cards, spacing, tipografía).

---

## 1. Perfil de usuario y ajustes generales

### Acción

Ajustes de perfil: **nombre**, **correo**, **cambio de contraseña**, y acceso a bloques de **notificaciones / alertas** (ver sección 2).

### Trazabilidad

MR 7.1, 8.1, 8.2 | VP 3.2, 6.1, P2, P4, P5 | BOS 4, 9

### Objetivo estratégico

Permitir que el usuario revise **metas y alertas** derivadas del presupuesto sugerido, sin convertir la app en un centro complejo de settings.

### Resultado visible para el usuario

El usuario entiende **qué alertas recibirá**, sobre **qué meta** operan y puede dejar activadas las relevantes sin perderse en configuración avanzada.

### Definición funcional detallada

- Configuración de perfil y preferencias de aviso sobre una **matriz default definida por producto**.
- Por defecto la app deja activos los **avisos mínimos** para que funcione como se espera sin diseño manual del usuario:
  - pagos próximos;
  - alertas de presupuesto por categoría;
  - recordatorio semanal para importar últimos movimientos;
  - señales del semáforo.
- El usuario puede ajustar **intensidad**, **frecuencia/cadencia** y **canal** dentro de **opciones acotadas**.

### UX/UI

Pantalla simple por **bloques**: pagos, presupuesto y actualización de datos. Debe mostrar **qué viene activo por defecto**, **por qué sirve** y **qué puede ajustar** el usuario sin confusión.

### Criterio de aceptación (MVP / QA)

El usuario puede ver la configuración por defecto, **mantenerla** o **ajustar canal/cadencia** sin romper la lógica base del sistema.

### Guardrails

No ofrecer motor libre de reglas, porcentajes ni flujos completamente custom por usuario; **la lógica base la define producto**.

---

## 2. Activar / desactivar notificaciones y alertas

### Objetivo estratégico

Activar ayuda oportuna **sin ruido** y sin pedir al usuario diseñar reglas.

### Resultado visible para el usuario

Recibe alertas útiles desde el inicio sobre vencimientos, gasto y presupuesto, **aun si no entra a configurar nada**.

### Trazabilidad

VP P2, P5 | BOS 9 Uso

### Definición funcional detallada

- **Toggles** por tipo de alerta y canal: pagos, recordatorios de actualización, alertas de presupuesto por categoría y señales del semáforo.
- La app debe **venir operativa por defecto**, por ejemplo:
  - popup/in-app al cruzar umbrales de presupuesto;
  - push móvil para vencimientos próximos;
  - recordatorio semanal para importar últimos movimientos;
  - correo para resúmenes o avisos críticos según producto.
- En presupuesto, el sistema usa una **escalera fija de umbrales** sobre la meta mensual por categoría (por defecto al menos **50 %, 80 % y 100 %** o más; niveles adicionales los define producto).
- El usuario puede bajar o subir intensidad, cadencia o canal dentro de opciones acotadas; **no** diseña un motor libre de porcentajes.

### UX/UI

Configuración clara por bloques y **canales aprobados**: popups/in-app para acciones contextuales, push móvil para avisos oportunos y correo para recordatorios o resúmenes. Debe verse **qué viene activo por defecto** y permitir ajuste simple.

### Criterio de aceptación (MVP / QA)

Las alertas base quedan operativas **sin** configuración manual y el usuario puede mantener defaults o ajustar canal/cadencia dentro de las opciones permitidas.

### Guardrails

No abrir constructor libre de reglas/canales ni depender de SMS u otros canales no aprobados para que la lógica principal funcione.

---

## 3. Configurar perfil financiero básico (capacidad estimada de pagos)

### Trazabilidad

MR 7.1 | VP 3.1, 3.3, P1, P4 | BOS 4, 9

### Objetivo estratégico

Estimar la carga financiera base y construir un **presupuesto sugerido** que alimente semáforo, metas y **capacidad estimada de pago**.

### Resultado visible para el usuario

Primera lectura simple del **margen del mes**, **capacidad estimada de pago** y **presupuesto sugerido por categorías**, sin inventarlo desde cero.

### Definición funcional detallada

- Perfil financiero básico alimentado por **datos fijos** (renta, gastos relativamente estables, antecedentes mínimos) y, idealmente, por **cartolas o últimos movimientos** importados si quiere diagnóstico inmediato.
- Durante onboarding (o primer acceso), explicar que si el usuario quiere saber **cómo está hoy** y no después de un mes de uso, conviene subir movimientos recientes para armar desde el inicio: presupuesto sugerido, metas por categoría, semáforo, alertas y primeras recomendaciones.
- Si el usuario omite ese paso, la herramienta debe partir con **supuestos básicos** y valores guía del producto, dejando claro que la **precisión mejora** al importar registros.
- Setup guiado y liviano, con **CTA visible** para importar cartolas/movimientos y beneficio explícito: *esto acelera tu diagnóstico, presupuesto y recomendaciones desde hoy*.

### Criterio de aceptación (MVP / QA)

Guarda el perfil financiero básico, deja operativo el cálculo de **capacidad estimada de pago**, el **presupuesto sugerido por categoría**, **metas editables**, **semáforo** y lógica de **alertas/umbrales**, y comunica el beneficio de importar cartolas para mejorar el diagnóstico inicial.

### Guardrails

No presentarlo como scoring bancario, análisis patrimonial, asesoría certificada ni como presupuesto 100 % manual desde una hoja en blanco.

---

## 4. Definir objetivo financiero (metas globales)

### Acción

Definir **objetivo financiero (metas)** a nivel global.

### Trazabilidad

VP 3.1, 4.5, P4 | BOS 9 Salida/continuidad

### Objetivo estratégico

Conectar orden financiero con una meta entendible.

### Resultado visible para el usuario

Declara una **meta global** que refuerza el sentido de progreso y **complementa** las metas mensuales por categoría del presupuesto.

### Definición funcional detallada

- Metas globales simples: bajar deuda, ahorrar un monto, potenciar capacidad de ahorro, evitar atraso o cumplir presupuesto.
- Seguimiento matemático básico con indicadores del MVP: deuda restante, monto ahorrado, capacidad de ahorro recuperada/disponible, pagos al día, grado de cumplimiento del presupuesto.
- Estas metas globales **no reemplazan** las metas por categoría que alimentan alertas y umbrales; las **complementan** y pueden disparar recomendaciones proactivas (ej. revisar o activar Bola de Nieve si la capacidad de ahorro queda muy por debajo del objetivo declarado).

### UX/UI

Selección guiada con **opciones predefinidas** y edición mínima, mostrando en una línea cómo se medirá el avance y qué módulo puede ayudar a lograrla.

### Criterio de aceptación (MVP / QA)

Meta creada y **visible en home o perfil**, con señal básica de avance o cumplimiento según el indicador definido, **sin confundirla** con las metas por categoría.

### Guardrails

No convertir metas en simulador patrimonial complejo ni confundir esta meta global con las metas mensuales por categoría del presupuesto.

---

## Entregables esperados (para Rork)

1. **Pantalla(s) de perfil / ajustes** con edición de nombre y correo, enlace o inclusión de cambio de contraseña si aplica al flujo actual, y navegación a sub-secciones de notificaciones/alertas.
2. **UI + estado local o persistido** (según backend disponible) para toggles y canales de alertas respetando guardrails (sin motor libre).
3. **Flujo de perfil financiero básico** (formulario guiado + opción de importar movimientos si el MVP ya lo contempla; si no, dejar placeholders y contratos de API claros).
4. **Flujo de meta global** con opciones predefinidas y vista de progreso simple en home o perfil.
5. **Criterios de aceptación** verificables manualmente (checklist QA) alineados a las secciones anteriores.

---

## Notas para el modelo

- Priorizar **claridad funcional** y **límites de alcance** sobre features extra.
- Si el backend aún no expone endpoints, definir **interfaces TypeScript** y **mocks** con el mismo contrato que consumirá la app después.
- Mantener coherencia visual con el design system Walvy y con pantallas ya implementadas (login, dashboard).
