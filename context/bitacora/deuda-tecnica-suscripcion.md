# Deuda Técnica — Control de Acceso por Suscripción

**Fecha:** 2026-06-18
**Área:** Frontend · Suscripción
**Audiencia:** Cliente, PM, Frontend
**Estado:** Pendiente de decisión

---

## Qué está hecho hoy

El flujo completo de suscripción funciona en dev:

- ✅ Usuario nuevo → trial de 14 días asignado automáticamente al registrarse
- ✅ Pantalla "Mi suscripción" muestra el estado correcto (días restantes, barra de progreso, colores)
- ✅ Checkout con Flow.cl integrado
- ✅ Backend calcula en tiempo real si el trial está vigente o expirado
- ✅ Cancelación de plan con acceso hasta fin del período

---

## Qué falta — el problema

**Hoy no existe ningún bloqueo real en la app para usuarios con acceso vencido.**

Un usuario cuyo trial expiró (o cuya suscripción venció) puede:
- Ver la pantalla de suscripción correctamente con "0 días · acceso vencido"
- **Pero seguir usando todas las funciones sin restricción**

El backend ya calcula `has_access: false` para estos usuarios. El frontend aún no reacciona a ese dato.

---

## La decisión a tomar

Hay dos enfoques estándar en la industria. Necesitamos decidir cuál va con Walvy.

---

### Opción A — Bloqueo duro en el login (Netflix, Spotify)

**Cómo funciona:** Al entrar a la app, si el acceso está vencido, el usuario es redirigido directamente a la pantalla de planes. No puede pasar al home.

**Ventaja:** Simple de implementar. El usuario entiende de inmediato que necesita pagar.

**Desventaja:** Agresivo. Si el usuario solo quiere revisar su balance o ver una transacción anterior, no puede. Puede generar fricción antes de que decida pagar.

**Cuándo tiene sentido:** Apps donde no hay valor en ver los datos sin pagar (streaming, música). En Walvy el usuario tiene datos propios — transacciones cargadas, historial — que tienen valor independiente de la suscripción.

---

### Opción B — Bloqueo suave por funcionalidad (Notion, Linear)

**Cómo funciona:** El usuario entra al home y puede ver su información existente. Cuando intenta usar una función premium (agregar transacción, importar cartola, IA, Bola de Nieve), aparece una pantalla de "Activa tu plan para continuar".

**Ventaja:** El usuario ve el valor de sus datos. La app "demuestra" lo que perdería al no pagar. Menos fricción, mejor experiencia.

**Desventaja:** Más trabajo de implementación — cada pantalla premium necesita su propio control.

**Cuándo tiene sentido:** Apps fintech y de productividad donde el usuario tiene datos propios. Es el estándar para apps del tipo de Walvy.

---

### Opción recomendada — Híbrido (lo más común en fintech)

Combina lo mejor de ambas opciones:

1. **Al abrir la app con acceso vencido** → aparece un modal que no se puede cerrar con el mensaje: *"Tu período de acceso ha vencido. Elige un plan para continuar."*
   - Botón principal: **"Ver planes"** → lleva a selección de plan
   - Enlace secundario: **"Solo ver mis datos"** → entra al home en modo lectura

2. **En modo lectura (home)** → el usuario puede ver su historial y balance, pero al intentar agregar o interactuar aparece el mismo mensaje de upgrade inline.

Este modelo es el que usan apps como **Copilot Money**, **YNAB** y **Fintual** — exactamente el perfil de Walvy.

---

## Funciones que se bloquearían (cuando se implemente)

| Función | ¿Bloqueada sin acceso? |
|---|---|
| Ver dashboard / balance | ✅ Siempre visible |
| Ver historial de transacciones existentes | ✅ Siempre visible |
| Ver perfil | ✅ Siempre visible |
| Pantalla "Mi suscripción" / Ver planes | ✅ Siempre visible |
| **Agregar nueva transacción** | ❌ Bloqueada |
| **Importar cartola** | ❌ Bloqueada |
| **Asistente financiero IA** | ❌ Bloqueada |
| **Motor de deudas (Bola de Nieve)** | ❌ Bloqueada |
| **Presupuesto avanzado** | ❌ Bloqueada |
| **Generar informes** | ❌ Bloqueada |

---

## Impacto técnico

Sea cual sea la opción elegida, el trabajo en el frontend es pequeño y está bien delimitado:

| Componente | Qué hace |
|---|---|
| `useAccessGate()` | Hook nuevo — combina estado del trial + suscripción y devuelve `hasAccess` |
| `(tabs)/_layout.tsx` | Punto central donde vive el bloqueo — si `!hasAccess` muestra el modal o redirige |
| Pantallas premium (M4-M8) | Cada una verifica `hasAccess` al intentar una acción |

**Estimación:** 1–2 días de desarrollo frontend una vez que se decida el enfoque.

---

## Pregunta para el cliente / PM

> **¿Queremos que un usuario con trial vencido pueda ver sus datos existentes (modo lectura), o preferimos bloquearlo directamente y llevarlo a contratar?**

La respuesta define cuál de las tres opciones implementamos y afecta cómo se percibe el producto en el momento más crítico del funnel de conversión.

---

## Contexto adicional

- Las funciones bloqueadas (M4–M8) aún no están construidas en el frontend. Esto significa que hoy el bloqueo es teórico — no hay nada que bloquear todavía. **La ventana ideal para decidir e implementar es ahora**, antes de que se construyan esas pantallas, para no tener que retrofit el gate sobre código ya existente.
- El backend ya tiene todo lo necesario (`has_access`, `trial_ends_at`, `status`). No hay trabajo pendiente en el servidor.

---

## Deuda 2 — Botón "Actualizar forma de pago" + modelo de cobro recurrente (Flow Cargo Automático)

**Archivo:** `front-walvy/expo/features/subscription/ui/SubscriptionScreen.tsx` → `onUpdatePayment`

**Estado actual:** El botón existe en la vista Mensual y Anual pero navega directo a la pantalla de éxito sin llamar ningún endpoint. Es un placeholder.

**Descubrimiento:** Flow SÍ tiene cobro recurrente — "Cargo Automático" / Suscripciones de pago (https://web.flow.cl/es-cl/suscripciones-de-pago/). Permite almacenar la tarjeta del cliente y cobrar automáticamente según el monto y frecuencia configurados, sin intervención del usuario en cada renovación.

**Implicancia arquitectural — decisión pendiente:**

Hoy el backend trata cada cobro como una transacción independiente (`payment_orders`). Si se adopta Flow Cargo Automático, el modelo cambia:

| Aspecto | Modelo actual (transaccional) | Flow Cargo Automático |
|---|---|---|
| Primera suscripción | Usuario paga en browser → webhook activa | Usuario autoriza → Flow guarda tarjeta |
| Renovación mensual/anual | Requiere nuevo pago manual del usuario | Flow cobra automáticamente, envía webhook |
| "Actualizar forma de pago" | No aplica | Sí aplica — Flow permite actualizar tarjeta guardada |
| Cancelación | `status = cancelled` en nuestra BD | Cancelar también en Flow para detener cobros |
| Botón "Ya pagué" | Necesario como fallback | No necesario — renovación es automática |

**Impacto en deudas existentes:** Adoptar Flow Cargo Automático resuelve simultáneamente Deuda 2 (forma de pago), Deuda 3 (webhook reactivo) y parte de Deuda 4 (flujo de re-suscripción tras cancelar).

**Acción pendiente:** Evaluar con cliente/PM si se adopta Flow Cargo Automático para producción. Requiere investigar la API de suscripciones de Flow y posiblemente rediseñar `subscriptions.service.ts` y las entities de `payment_orders`.

---

## Deuda 3 — Activación de suscripción depende del botón "Ya pagué" (sin webhook reactivo)

**Estado actual:** La activación automática vía webhook de Flow está implementada en el backend (`POST /subscriptions/webhook`), pero Flow no está configurado para enviar el webhook en el ambiente actual. La app resuelve la confirmación de pago a través del botón manual "Ya pagué — verificar" (`POST /subscriptions/verify-payment`), que consulta directamente la API de Flow.

**Consecuencia:** El usuario debe volver a la app y tocar el botón para que su suscripción se active. Si no lo hace, la suscripción queda pendiente aunque el pago ya fue procesado por Flow.

**Solución futura:** Configurar la URL de webhook en el panel de Flow (`FLOW_CONFIRM_URL`) apuntando al servidor de producción. Una vez activo, el backend activará la suscripción en segundos sin intervención del usuario. El botón "Ya pagué" quedaría como fallback, no como ruta principal.

**Impacto hoy:** Bajo — el flujo funciona correctamente con el botón manual. El único riesgo es un usuario que pague y cierre la app sin volver a abrirla, quedando con pago procesado pero suscripción inactiva hasta que reabra y verifique.

---

## Deuda 4 — Vista de suscripción cancelada (sin pantalla dedicada)

**Estado actual:** Cuando un usuario cancela su suscripción, `status` pasa a `"cancelled"` en la BD. El frontend no tiene una vista específica para este estado — `pickVariant()` trata `cancelled` igual que `expired` y muestra el `TrialView` con el copy de prueba ("Tus primeros 365 días · 365 días restantes · Te quedan X días para elegir un plan"), lo cual es confuso para un usuario que canceló una suscripción pagada.

**Lo que debería mostrar:**
- Título: "Suscripción cancelada"
- Mensaje: "Tu acceso continúa hasta DD/MM/YYYY"
- Botón: "Re-suscribirte" → pantalla de planes

**Trabajo necesario:**
1. `pickVariant()` → agregar caso `"cancelled"` separado de `"expired"`
2. Nuevo componente `CancelledView` en `SubscriptionScreen` — mismos tokens de color que `TrialView`, sin progress bar
3. Pasar `onViewPlans` como prop para el botón de re-suscripción

**Pendiente antes de implementar:** Confirmar con cliente/PM el copy exacto y si existe diseño Figma para este estado. El flujo de re-suscripción (¿el usuario cancela y puede volver a contratar inmediatamente? ¿hay periodo de espera?) también necesita definición.
