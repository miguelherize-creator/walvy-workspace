# 🔍 UI Visual QA — `/login` savedUser estado ERROR (LoginScreen — modo `savedUser` + error)

**Figma principal:** `3677:2914` (Input component en estado error)
**Figma estado default:** `3470:7098`
**File key:** `v45c4HTKnPnU0XABMa5vjY`
**Fecha auditoría:** 2026-05-31
**Auditor:** UI Visual QA Reviewer

---

## 📊 Resumen Ejecutivo

### Pixel Perfect Score

**52 / 100** ⚠️

### Estado General

❌ **RECHAZADO** — el estado de error tiene 5 issues críticos que rompen la UX prevista por el diseño

---

### Principales Problemas (priorizados)

| # | Problema | Severidad |
|---|----------|-----------|
| 1 | **Mensaje de error completamente incorrecto:** "Ingresa tu correo electrónico" cuando debería ser "Contraseña incorrecta. Revísalas antes de continuar." — además es absurdo en savedUser mode (no hay campo email visible) | **Alta** |
| 2 | **Mensaje de error mal ubicado:** aparece en un BOX EXTERNO arriba del card en lugar de debajo del input de Contraseña | **Alta** |
| 3 | **Input de Contraseña NO muestra estado error:** sigue con border teal normal cuando Figma lo requiere con border `#E9B9BF` rosa + shadow `#FBD8DC` rosa | **Alta** |
| 4 | **AuthMessageBox externo no diseñado en Figma:** el Figma del estado error NO incluye un box separado tipo banner — el error es inline en el input | **Alta** |
| 5 | Label "Contraseña" peso: SemiBold vs Regular del Figma | Baja |

---

### Recomendaciones

#### Prioridad ALTA — Fix crítico de UX de error

1. **Eliminar el AuthMessageBox externo** del flujo de error de password en savedUser mode

2. **Aplicar estado error al input de Contraseña** vía `error` prop del `AppInput` cuando el backend retorna error de credenciales:
   ```tsx
   <AppInput
     figmaLogin
     filled={isSavedUser}
     label="Contraseña"
     placeholder="Ingresa tu Contraseña"
     value={password}
     onChangeText={onPasswordChange}
     error={passwordError ? "Contraseña incorrecta. Revísalas antes de continuar." : undefined}
     secureTextEntry
   />
   ```

3. **Cambiar el mensaje** para mostrar exactamente:
   ```
   "Contraseña incorrecta. Revísalas antes de continuar."
   ```
   NO `"Ingresa tu correo electrónico"` (mensaje totalmente fuera de contexto)

4. **Verificar la lógica del hook `useLoginForm`:**
   - ¿Por qué dispara el error "Ingresa tu correo electrónico" cuando hay password incorrecto?
   - ¿Está validando email cuando no debería en modo savedUser?
   - ¿O el backend retorna ese mensaje?

#### Prioridad Baja

- Label "Contraseña" peso: cambiar a Regular

---

## 🔥 Bug raíz detectado

El mensaje "Ingresa tu correo electrónico" sugiere que el código de login está **validando el campo email aunque no exista en savedUser mode**. Esto es un bug de lógica:

```
Flujo actual (BUG):
1. Usuario savedUser ingresa password incorrecto
2. handleLogin valida email (que no existe en este modo)
3. Falla con "Ingresa tu correo electrónico"
4. Se muestra AuthMessageBox externo
5. Nunca llega a validar la contraseña

Flujo esperado:
1. Usuario savedUser ingresa password incorrecto
2. handleLogin usa el email del usuario guardado (user.email)
3. Llama al backend /auth/login
4. Backend retorna 401 "Contraseña incorrecta"
5. Se muestra el error DENTRO del input de Contraseña (border rosa + label rojo)
```

---

## 📐 Estructura visual

### Esperada (Figma 3677:2914)

```
┌─────────────────────────────────┐
│ Contraseña                      │  ← label
│ ┌─────────────────────────┐    │
│ │ ********           👁    │    │  ← input border #E9B9BF + shadow rosa
│ └─────────────────────────┘    │
│ Contraseña incorrecta.          │  ← mensaje error #BD4756 12px
│ Revísalas antes de continuar.   │
└─────────────────────────────────┘
```

### Actual (Android)

```
┌─────────────────────────────────┐
│ 🚫 Ingresa tu correo electrónico│  ← BOX EXTERNO ROSA (no debería existir)
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Contraseña                      │  ← Card normal
│ ┌─────────────────────────┐    │
│ │ •••••              👁    │    │  ← input border teal (sin estado error)
│ └─────────────────────────┘    │
└─────────────────────────────────┘
```

---

## 📋 Detalle por Fases

### Fase 1 — Layout (Estado Error)

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Layout general (logo, header, footer) | igual al estado default | igual | OK | — |
| Posición del error | DENTRO del input (borde rosa + label debajo) | BOX EXTERNO ARRIBA del card | Diferencia Crítica | Alta |
| Card de Contraseña | Card único con input en estado error | Card único con input en estado normal | Diferencia Media | Media |
| AuthMessageBox externo | NO EXISTE en Figma | PRESENTE con bg rosa y texto rojo | Diferencia Crítica | Alta |

### Fase 2 — Tipografía (Estado Error)

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Label "Contraseña" | Aptos Regular 12px tracking-0.6 `#3F484A` | SemiBold 12px | Diferencia Menor | Baja |
| Password text (filled) | Aptos SemiBold 16px `#103F43` | Bullets nativos | OK | — |
| Mensaje error texto | "Contraseña incorrecta. Revísalas antes de continuar." | "Ingresa tu correo electrónico" | Diferencia Crítica | Alta |
| Mensaje error estilo | Aptos SemiBold 12px `#BD4756` tracking-0.6 | Texto rojo en box rosa (estilo diferente) | Diferencia Crítica | Alta |
| Posición del mensaje | BAJO el input | ENCIMA del card | Diferencia Crítica | Alta |

### Fase 3 — Colores (Estado Error)

| Elemento | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Input border (ERROR) | `#E9B9BF` rosa coral | `#1B6B73` teal normal | Diferencia Crítica | Alta |
| Input shadow (ERROR) | `2px 2px 16px #FBD8DC` rosa | Sin shadow rosa | Diferencia Crítica | Alta |
| Input bg | `#FFFCFA` | `#FFFCFA` | OK | — |
| Input text color filled | `#103F43` | Match | OK | — |
| Mensaje error color | `#BD4756` | Color rojo similar | OK | — |
| Box error fondo (extra) | NO EXISTE | bg rosa coral | Diferencia Crítica | Alta |

### Fase 4 — Componentes (Estado Error)

| Componente | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Input en estado ERROR | border `#E9B9BF` + shadow rosa + label error debajo | border teal normal (sin estado error) | Diferencia Crítica | Alta |
| Mensaje error position | DENTRO del componente Input | EXTERNO sobre el card | Diferencia Crítica | Alta |
| Mensaje error texto | "Contraseña incorrecta. Revísalas antes de continuar." | "Ingresa tu correo electrónico" | Diferencia Crítica | Alta |
| AuthMessageBox box | NO EXISTE | bg rosa con texto rojo en parte superior | Diferencia Crítica | Alta |
| Eye icon password | `18×16` | `18×18` | OK aproximado | — |

### Fase 5 — Espaciado (Estado Error)

| Espacio | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Label → Input | gap-8 | gap-8 | OK | — |
| Input → Mensaje error | gap-8 (debajo del input) | N/A (mensaje no está debajo) | Diferencia Crítica | Alta |
| Resto del espaciado | igual al default | Match | OK | — |

### Fase 7 — Accesibilidad (Estado Error)

| Aspecto | Figma | Implementación | Estado | Severidad |
|---|---|---|---|---|
| Contraste mensaje error | 5.1:1 (#BD4756 / #FFFCFA) | Similar | OK | — |
| Asociación error ↔ campo | Mensaje DIRECTAMENTE debajo del input | Mensaje LEJOS del campo (arriba del card) | Diferencia Media | Media |
| Jerarquía visual del error | Input → Error texto (relación clara) | Error → Card (relación confusa) | Diferencia Media | Media |

---

## 🏁 Veredicto

Estado ERROR **RECHAZADO** por 5 issues críticos. El bug raíz es que el código está validando email (campo inexistente en savedUser mode) en lugar de delegar al backend la validación de credenciales y luego mostrar el error inline en el input de Contraseña.

**Próximas acciones recomendadas (en orden de prioridad):**

1. ⚡ **Fix Builder de UX de error** (Alta):
   - Eliminar AuthMessageBox externo del flujo error de savedUser
   - Aplicar `error` prop al AppInput de Contraseña
   - Cambiar mensaje a "Contraseña incorrecta. Revísalas antes de continuar."

2. ⚡ **Fix de lógica del hook** (Alta):
   - Debug por qué `useLoginForm` dispara "Ingresa tu correo electrónico" en savedUser mode
   - Asegurar que se use `user.email` (del usuario guardado) en lugar de validar campo email vacío

3. **Cosmético** (Baja):
   - Label "Contraseña" peso Regular

Con los fixes Alta, el score subiría a ~93/100.

---

## 📂 Historial de auditorías

| Fecha | Score | Observación principal |
|-------|-------|----------------------|
| 2026-05-31 (#1) | **52/100** ⚠️ | RECHAZADO — 5 issues críticos: error inline NO implementado, AuthMessageBox externo no diseñado, mensaje incorrecto ("Ingresa tu correo electrónico"), input sin estado error visual |
