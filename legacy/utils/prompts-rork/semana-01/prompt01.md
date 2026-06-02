## Walvy

Quiero que construyas un proyecto de una **app móvil de finanzas personales usando React Native (Android y iOS)**, conectada a un backend existente en **NestJS (API REST)**.

El resultado debe ser **código funcional, estructurado y listo para escalar**, no solo UI.

---

## Objetivo del Proyecto

Implementar un flujo completo de autenticación con:

- Registro
- Login
- Persistencia de sesión
- Dashboard inicial
- Logout

---

## Stack obligatorio

- React Native (preferible con Expo)
- TypeScript
- Manejo de estado simple (Context API o Zustand)
- Navegación: React Navigation
- HTTP client: Axios (configurado centralmente)
- Almacenamiento seguro: SecureStore / AsyncStorage

---

## RESTRICCIÓN CRÍTICA (OBLIGATORIO)

Esta aplicación DEBE cumplir lo siguiente:

- Usar **React Native con Expo**
- Generar un proyecto **cross-platform (Android + iOS)**
- Código ejecutable con `npx expo start`
- Incluir `package.json` y estructura Node válida
- NO usar código nativo (Swift, Kotlin, Java, Objective-C)

## Arquitectura requerida

Estructura clara y escalable:

```
/src
  /api          -> configuración axios + endpoints
  /auth         -> lógica de autenticación
  /components   -> componentes reutilizables (Button, Input, Card)
  /screens      -> Register, Login, Dashboard
  /navigation   -> navegación protegida (auth vs app)
  /store        -> estado global (auth)
  /theme        -> colores, spacing, tipografía
  /utils        -> helpers
```

---

## Diseño (CRÍTICO)

Inspirado en app fintech moderna en **modo oscuro**.

### Principios:

- UI limpia, minimalista
- Tarjetas (cards)
- Bordes redondeados
- Espaciado consistente
- Alto contraste

### Tokens de diseño (OBLIGATORIO)

Implementa este diseño desde Figma y de la Imagen adjuntada:
@https://www.figma.com/design/v45c4HTKnPnU0XABMa5vjY/Edificate-Inteligente---App?node-id=272-2152&m=dev

```tsx
colors = {
  bg: "#1c1924",
  card: "#242336",
  modal: "#2f2e47",
  textPrimary: "#e0e0e0",
  textSecondary: "#868686",
  greenSoft: "#a0e058",
  greenNeon: "#b6fc1e",
  red: "#ff205f",
  yellow: "#ffd13f",
  orange: "#ff9d40",
}
```

### Componentes base

**Button (CTA primario):**

- borde verde
- texto verde
- borderRadius: 24
- padding vertical compacto

**Input:**

- label pequeño arriba (~12px)
- fondo consistente con cards
- estilo uniforme en toda la app

---

## Configuración de entorno

Debe soportar **2 modos**:

### 1. Mock (por defecto)

- Datos simulados
- Sin dependencia del backend

### 2. API real

- Usar variable obligatoria:

```
BACKEND_BASE_URL
```

⚠️ REGLAS:

- NO hardcodear URLs
- Centralizar configuración en `/api/client.ts`

---

## Endpoints esperados

```
POST   /auth/register
POST   /auth/login
GET    /users/me
POST   /auth/logout (opcional)
```

---

## Autenticación

- Guardar token en almacenamiento seguro
- Incluir token automáticamente en headers (interceptor Axios)
- Auto-login si existe token válido
- Manejo de expiración de sesión (fallback a logout)

---

## Flujos obligatorios

La aplicación debe soportar los siguientes flujos:

### Flujo 1 (Usuario nuevo)

**Register → Login → Dashboard → Logout**

1. El usuario abre la app y accede al Login
2. Selecciona “Crear cuenta”
3. Completa registro (email + password)
4. Al registrarse correctamente:
    - Se guarda en memoria (modo mock)
    - Se inicia sesión automáticamente
5. Redirección al Dashboard
6. Puede cerrar sesión y volver al Login

---

### Flujo 2 (Usuario existente)

**Login → Dashboard → Logout**

1. El usuario abre la app
2. Ingresa credenciales válidas
3. Accede al Dashboard
4. Puede cerrar sesión y volver al Login

---

## Modo Mock (OBLIGATORIO)

Implementar sistema de autenticación mock con:

- Persistencia en memoria durante la sesión
- Solo usuarios registrados pueden iniciar sesión
- El registro agrega nuevos usuarios al almacenamiento en memoria

### Usuario de prueba (TEST_USER)

Debe existir un usuario predefinido:

- Email: [test@example.com](mailto:test@example.com)
- Password: 123456

---

## Requisitos UI (Login)

En `src/screens/LoginScreen.tsx`:

- Mostrar caja informativa visible solo en modo mock
- Incluir credenciales del usuario de prueba
- Debe ser clara y fácil de copiar

---

## Navegación protegida

- Si hay token → Dashboard
- Si NO hay token → Login
- Implementar AuthGuard o lógica equivalente

---

## Pantallas mínimas

### Register

- email
- password
- confirm password
- botón crear cuenta

### Login

- email
- password
- botón login

### Dashboard

- saludo al usuario
- email o nombre
- 2–3 cards mock (balance, gastos, ingresos)
- botón logout

---

## Estados y UX

Manejar explícitamente:

- loading (spinners)
- errores con mensajes claros
- validaciones básicas
- feedback visual (botones deshabilitados, etc.)

---

## Casos de prueba esperados

### Caso 1: Registro completo

- Usuario se registra
- Se guarda en memoria
- Accede automáticamente al Dashboard
- Puede hacer logout

### Caso 2: Login con usuario de prueba

- Usa TEST_USER
- Accede correctamente al Dashboard
- Puede hacer logout

### Caso 3: Login inválido

- Credenciales incorrectas
- Mostrar error claro (ej: "Credenciales inválidas")

---

## Fuera de alcance

No incluir:

- presupuestos
- deudas
- IA
- gamificación
- funcionalidades sociales

---

## Entregable esperado

### Código

- limpio
- modular
- reutilizable
- tipado con TypeScript

### README (OBLIGATORIO)

Debe incluir:

- instalación
- cómo ejecutar en modo mock
- cómo usar API real
- configuración de `BACKEND_BASE_URL`
- cómo probar:
    - Flujo 1
    - Flujo 2

---

## Reglas importantes

- No sobre-ingeniería
- No agregar features no solicitadas
- Priorizar claridad sobre complejidad
- Código listo para producción básica

---

## BONUS (opcional)

- Dark mode consistente
- Animaciones sutiles (botones / carga)
- Separación clara entre UI y lógica

---

## Resultado esperado

Una app que:

- funcione end-to-end
- tenga apariencia moderna tipo fintech
- se conecte fácilmente a NestJS
- sea base sólida para escalar
- pueda integrarse fácilmente con GitHub (repositorio listo para versionado y colaboración)
- permita despliegue sencillo a App Store y Play Store
- esté completamente desarrollada en React Native (sin uso de Swift ni código nativo)

---