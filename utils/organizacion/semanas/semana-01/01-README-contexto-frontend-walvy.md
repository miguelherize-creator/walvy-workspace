# Walvy Frontend - Contexto del Repositorio

Este documento resume como funciona `rork-checkapp` para acelerar onboarding tecnico y funcional.

## 1) Que es este repo

`rork-checkapp` es el frontend mobile/web de Walvy construido con:

- Expo + React Native + Expo Router
- TypeScript
- React Query para estado de servidor
- SecureStore para token/sesion
- `expo-local-authentication` para biometria

La app tiene branding Walvy y un flujo de autenticacion de Etapa 1 (login, registro, biometria, cambio y recuperacion de contrasena).

## 2) Estructura principal

En `rork-checkapp/expo`:

- `app/`: pantallas (ruteo por archivos de Expo Router)
- `api/`: cliente HTTP, configuracion y servicios de auth
- `store/AuthProvider.tsx`: estado global de autenticacion/sesion
- `services/biometrics.ts`: encapsula Face ID/huella
- `components/`: componentes base (`AppButton`, `AppInput`, `FinanceCard`)
- `constants/`: tokens de diseno (colores, tipografia, spacing)
- `assets/images/walvy/`: logos/isotipo/iconos de marca

## 3) Pantallas activas en Etapa 1

Definidas en `app/_layout.tsx`:

- `index` (boot/loading)
- `login`
- `register`
- `forgot-password`
- `change-password`
- `dashboard`

## 4) Flujo tecnico de sesion

1. `app/index.tsx` consulta `useAuth()`.
2. `AuthProvider` intenta restaurar token desde SecureStore.
3. Si biometria esta activa, pide verificacion antes de restaurar sesion.
4. Si sesion valida: navega a `dashboard`; si no: `login`.

## 5) Modo API vs Modo Mock

Se controla en `api/config.ts`.

- `isMockMode = true` cuando:
  - `EXPO_PUBLIC_USE_MOCK_MODE=true`, o
  - no hay backend configurado.
- `isMockMode = false` cuando hay backend configurado y no se fuerza mock.

Esto permite probar UI/UX y flujos sin backend levantado.

## 6) Configuracion recomendada

Archivo `expo/.env` (local):

```env
EXPO_PUBLIC_BACKEND_BASE_URL=http://<tu-ip-local>:3000
EXPO_PUBLIC_USE_MOCK_MODE=false
```

Para pruebas solo frontend:

```env
EXPO_PUBLIC_USE_MOCK_MODE=true
```

## 7) Como correr el frontend

Desde `rork-checkapp/expo`:

```bash
npx expo start
```

Opcional tunnel:

```bash
npx expo start --tunnel
```

## 8) Notas de integracion backend

- El frontend consume endpoints de auth y users.
- Si backend no esta disponible, el flujo sigue en mock.
- En recuperacion de contrasena, modo mock muestra token de prueba en pantalla para validar UX end-to-end.
