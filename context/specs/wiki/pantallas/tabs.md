# Tabs / Inicio — `/(tabs)`

**Componentes:** `app/(tabs)/index.tsx` (stub) · menú `features/home` (`useAppHeader`, `UserMenu`) · `app/(tabs)/profile.tsx` stub  
**Tablero:** M2 [MV-M2-02](https://github.com/KabeliDev/front-walvy/issues/32) · logout `M2-V07`  
**Rutas hijas:** movimientos, movimiento, presupuesto, chatbot — stubs, sin API auth/users/profile

Post-login / post-onboarding. En walvy/main el home no consume perfil financiero ni goals.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| POST | `/auth/logout` | `AuthProvider.logout` | “Cerrar sesión” **sin** biometría (`session`) o “Cambiar de usuario” (`device`) |
| POST | `/auth/logout-all` | — | **No** se llama |
| GET/PUT | `/profile/financial` | — | No |
| GET | `/profile/goals` | — | No |
| POST | `/users/me/avatar` | — | No |
| PATCH | `/users/me/password` | — | No |

Con biometría ON, “Cerrar sesión” es suave: **no** llama logout (tokens quedan para V05). Sin biometría revoca tokens y **conserva** correo/nombre: el login abre savedUserPassword. FirstTime solo con “Cambiar de usuario”.

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M2-V05` | — | Avatar / menú | Opciones Mi Perfil y Cerrar sesión | Pendiente |
| 2 | `M2-V06` | — | Mi Perfil | `/(tabs)/profile` “Próximamente”. **No implementado** el hub | Pendiente |
| 3 | `M2-V07` | `POST /auth/logout` | Cerrar sesión, sin biometría | Revoca refresh, borra tokens, conserva email/nombre. `/login` savedUserPassword | Pendiente |
| 4 | `M2-V07` | — | Cerrar sesión, con biometría | No POST. Login savedUser. Política sin RN | Pendiente |
| 5 | `M2-V07` | `POST /auth/logout-all` | Cerrar en todos los dispositivos | **No implementado.** QA por API (`TC-M01-041` C) | Pendiente |
| 6 | `M2-V09`…`V14` | varios | Hub perfil | Blocked M2. Ver wiki huecos financial/avatar/clave | Pendiente |

Otras tabs: sin casos M1 de auth.

**Anterior:** [`onboarding-first-ready.md`](onboarding-first-ready.md)
