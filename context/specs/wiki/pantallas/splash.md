# Splash — `/`

**Componente:** `expo/features/splash/ui/SplashScreen.tsx`  
**Ruta:** `app/index.tsx` → `SplashScreen`  
**Tablero:** [MV-M1-01](https://github.com/KabeliDev/front-walvy/issues/18) (V01, V04) · reglas `M1-RN-ACC-001`, `M1-RN-ACC-025`  
**Figma:** `3689:3266` (marca) — la cara de login que sigue es V01 `3470:6974` / V04 `3470:7098`

La splash **no pega a la API**. Espera a `AuthProvider.isLoading === false` (mín. 3 s, tope 5,5 s) y **siempre** hace `router.replace("/login")`. No va a Home ni a onboarding.

El arranque paralelo en `_layout` / `AuthProvider` sí llama API. Esos hits cuentan acá porque definen **con qué cara** abre el login.

---



## Endpoints (indirectos)


| Método  | Path            | Quién                                          | Cuándo                                             |
| ------- | --------------- | ---------------------------------------------- | -------------------------------------------------- |
| ++GET++ | `/health`       | `api/config.ts` ++++`probeBackendReachability` | ++Al montar++ `AuthProvider`++. Mock vs API real++ |
| ++GET++ | `/users/me`     | `AuthProvider` ++restore++                     | ++Solo si hay access token en SecureStore++        |
| POST    | `/auth/refresh` | interceptor Axios                              | Solo si `GET /users/me` responde 401 y hay refresh |


---



## Control: variante × endpoint


| #   | ID variante                | Endpoint              | Disparador                          | Esperado (matriz + este front)                                                                               | Estado    |
| --- | -------------------------- | --------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------ | --------- |
| 1   | `M1-V01`                   | `GET /health`         | Cold start, sin token               | Probe corre antes de salir de splash. Si falla y no hay force, mock. Login firstTime (correo + clave)        | Pendiente |
| 2   | `M1-V01`                   | —                     | Cold start, sin token               | Splash no llama `/users/me`. Destino único: `/login` modo firstTime                                          | Pendiente |
| 3   | `M1-V04`                   | `GET /users/me`       | Token persistido válido             | Restore OK. Splash **igual** va a `/login`, cara savedUser (saludo + clave o biometría). No salta a tabs     | Pendiente |
| 4   | `M1-V04` · `M1-RN-ACC-025` | `GET /users/me` → 401 | Token inválido / cuenta sin sesión  | AuthProvider borra tokens. Login firstTime, no saludo de usuario guardado                                    | Pendiente |
| 5   | `M1-V04` · `M1-RN-ACC-025` | `POST /auth/refresh`  | 401 en `/users/me` con refresh vivo | Rota tokens y reintenta `/users/me`. Si refresh falla, mismo resultado que fila 4                            | Pendiente |
| 6   | `M1-V01` / `M1-V04`        | —                     | Animación vs probe                  | No navegar antes de `isLoading=false` (salvo tope 5,5 s). Evita que el modo mock/API cambie debajo del login | Pendiente |


---



## Qué no va en esta pantalla


| ID                        | Por qué                                                                     |
| ------------------------- | --------------------------------------------------------------------------- |
| `M1-V02`                  | Submit de credenciales válidas → `[login.md](login.md)`                     |
| `M1-V03`                  | Error de login → login                                                      |
| `M1-V05`…`V07`            | Biometría en la cara del login, no en splash                                |
| Destino Home / onboarding | Lo decide login **después** de confirmar identidad (`GET /auth/onboarding`) |


---



## Notas para el caso

- `frontend-routes-graph.md` todavía dibuja splash → tabs si hay sesión. **Obsoleto.** Código: siempre `/login` (PR #76, M1-V01/V04/ACC-025).
- `GET /users/me` ahora puede traer `onboarding` anidado. Splash no lo lee; solo espera a que el restore termine.
- Si el probe de `/health` es lento, el tope de 5,5 s puede dejar splash antes de que `isLoading` baje: riesgo de firstTime vs savedUser mal pintado. Caso 6.

**Siguiente pantalla:** `[login.md](login.md)`