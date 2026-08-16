# Splash — `/`

**Componente:** `expo/features/splash/ui/SplashScreen.tsx`  
**Ruta:** `app/index.tsx` → `SplashScreen`  
**Tablero:** [MV-M1-01](https://github.com/KabeliDev/front-walvy/issues/18) (V01, V04) · reglas `M1-RN-ACC-001`, `M1-RN-ACC-025`  
**Figma:** marca `3689:3266` — la cara de login que sigue es V01 `3470:6974` / V04 `3470:7098`  
**Revisión código:** 16 ago 2026 · front `SplashScreen` + `AuthProvider` (PR #76 / `M1-V01`/`V04`/`ACC-025`)

Hay **dos** splashes. El nativo de Expo (`expo-splash-screen` en `_layout`) se oculta cuando hidrata el tema. Esta pantalla es la de marca: Lottie + copy, sin CTA.

La splash **no pega a la API**. Espera a `AuthProvider.isLoading === false` (mín. 3 s, tope 5,5 s) y **siempre** hace `router.replace("/login")`. No va a Home ni a onboarding.

El arranque paralelo en `_layout` / `AuthProvider` sí llama API. Esos hits cuentan acá porque definen **con qué cara** abre el login (V01 firstTime vs V04 savedUser).

---

## Endpoints (indirectos)

| Método | Path | Quién | Cuándo |
| --- | --- | --- | --- |
| GET | `/health` | `api/config.ts` `probeBackendReachability` | Al montar `AuthProvider`. Timeout 5 s. 2xx → API real; fallo en `__DEV__` sin force → mock |
| GET | `/users/me` | `AuthProvider` restore | Solo si hay access token en SecureStore. Distingue usuario restaurado vs primer ingreso |
| POST | `/auth/refresh` | interceptor Axios | Solo si `GET /users/me` responde **401** y hay refresh. Un **403** no rota token |

`GET /users/me` puede anidar `onboarding` (`currentGate` / `resumeState`). Splash no lo lee. El destino post-login lo decide `GET /auth/onboarding` en [`login.md`](login.md).

---

## Control: variante × endpoint

Estados = revisión de código, no corrida QA en dispositivo.

| # | ID variante | Endpoint | Disparador | Esperado (matriz + este front) | Estado |
| --- | --- | --- | --- | --- | --- |
| 1 | `M1-V01` · `M1-RN-ACC-001` | `GET /health` | Cold start, sin token ni email en SecureStore | Probe corre antes de `isLoading=false`. Si falla y no hay `EXPO_PUBLIC_USE_MOCK_MODE=false`, mock. Splash no llama `/users/me` | Conforme |
| 2 | `M1-V01` | — | Cold start, sin usuario recordado | Destino único: `/login` modo firstTime (correo + clave). No tabs, no onboarding | Conforme |
| 3 | `M1-V04` · `M1-RN-ACC-025` | `GET /users/me` | Token persistido válido | Restore OK (`user` + `isAuthenticated`). Splash **igual** va a `/login`, cara savedUser (saludo + clave o biometría). No salta a tabs | Conforme |
| 4 | `M1-V04` · `M1-RN-ACC-025` | `GET /users/me` → error | Token inválido / cuenta que no sostiene sesión | AuthProvider borra **tokens**. Conserva `walvy_last_user_email` / nombre. Login cara **savedUser**, no firstTime. FirstTime solo tras logout completo o “Cambiar de usuario” | Conforme |
| 5 | `M1-V04` · `M1-RN-ACC-025` | `POST /auth/refresh` | 401 en `/users/me` con refresh vivo | Interceptor rota tokens y reintenta `/users/me`. Si refresh falla, mismo resultado que fila 4 (tokens fuera, email queda) | Conforme |
| 6 | `M1-V01` / `M1-V04` | — | Animación vs probe | No navegar antes de `isLoading=false`, salvo tope 5,5 s. `PROBE_TIMEOUT_MS` = 5 s: el modo mock/API debería estar decidido. Si el tope pega **durante** el probe, `LoginScreen` fija el modo en el primer render y no lo actualiza cuando llega `savedEmail` | Conforme con riesgo |

---

## Qué no va en esta pantalla

| ID | Por qué |
| --- | --- |
| `M1-V02` | Submit de credenciales válidas → [`login.md`](login.md) |
| `M1-V03` | Error de login → login |
| `M1-V05`…`V07` | Biometría en la cara del login, no en splash |
| Destino Home / onboarding | Lo decide login **después** de confirmar identidad (`GET /auth/onboarding`) |

---

## Notas para el caso

- `frontend-routes-graph.md` todavía dibuja splash → tabs / retoma de paso si hay sesión. **Obsoleto.** Código: siempre `/login` (PR #76).
- Cara V01 vs V04 no depende de `isAuthenticated`. Depende de `savedEmail` / `user.email` (y biometría + token para la cara huella). Por eso la fila 4 no vuelve a firstTime al perder el access token.
- `GET /health` es liveness (`{ ok: true }`), no readiness. El probe no espera a la base.
- Cuenta restringida: si el backend responde **401** en `/users/me`, el interceptor intenta refresh (parece sesión vencida). Un **403** no. Eso no cambia el destino de splash; sí el ruido de red. Ver [`login.md`](login.md) para el mensaje en pantalla.
- Caso 6: margen probe 5 s vs tope splash 5,5 s. Suficiente para el health; corto si después corre `GET /users/me` lento. En V01 (sin token) el restore vuelve enseguida tras el probe.

**Siguiente pantalla:** [`login.md`](login.md)
