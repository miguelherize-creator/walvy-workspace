# Login — `/login`

**Componente:** `expo/features/auth/ui/LoginScreen.tsx` + `useLoginForm` + `useBiometricLogin`  
**Ruta:** `app/(auth)/login.tsx`  
**Tablero:** [MV-M1-01](https://github.com/KabeliDev/front-walvy/issues/18) V01–V04 · [MV-M1-02](https://github.com/KabeliDev/front-walvy/issues/19) V05–V07  
**Figma:** firstTime `3470:6974` · savedUserPassword `3470:7098` · savedUserBiometric `3470:7080` · error `3677:2837`  
**Revisión código:** 16 ago 2026 · login y huella retoman `currentGate`; `resumeState` no salta el mapa

Llega **siempre** desde splash. Tres caras: firstTime, savedUserPassword, savedUserBiometric. El submit y la huella viven acá. El destino post-clave y post-huella lo arma `GET /auth/onboarding`.

---

## Endpoints

| Método | Path | Quién | Cuándo |
| --- | --- | --- | --- |
| POST | `/auth/login` | `AuthProvider.login` ← `useLoginForm` | CTA Entrar (firstTime y savedUserPassword) |
| GET | `/auth/onboarding` | `useLoginForm` y `useBiometricLogin` post-auth | Credenciales o huella OK y `nextStep` no es `email_verification` |
| POST | `/auth/email-verification/request` | `useLoginForm` (+ el backend ya reenvía en el login) | `nextStep === "email_verification"` |
| GET | `/users/me` | `AuthProvider.loginWithBiometric` | Huella/Face OK. No llama `POST /auth/login` |
| POST | `/auth/refresh` | interceptor | 401 en onboarding / me, si hay refresh |

---

## Control: variante × endpoint

Estados = revisión de código, no corrida QA en dispositivo.

### Acceso / Login — MV-M1-01

| # | ID variante | Endpoint | Disparador | Esperado (matriz + este front) | Estado |
| --- | --- | --- | --- | --- | --- |
| 1 | `M1-V01` · `M1-RN-ACC-001` | — | Entra sin usuario guardado | Título “Te damos la bienvenida”. Inputs correo + clave. Links “Crea tu cuenta” y “¿Olvidaste tu contraseña?”. Copy Figma: “Crea mi cuenta” | Conforme |
| 2 | `M1-V02` · `M1-RN-ACC-004` | `POST /auth/login` | Correo/clave válidos | 200 + tokens en SecureStore. **No** ir fijo a Home: sigue fila 3 | Conforme |
| 3 | `M1-V02` (ajuste PO) | `GET /auth/onboarding` | Login 200 | Destino por `currentGate` / `resumeState` (filas 14–20). Matriz dice “Home”; PO: continuidad por estado | Conforme |
| 4 | `M1-V03` | `POST /auth/login` | Clave o correo inválidos | 401. Se queda. `passwordError` inline “Correo o contraseña incorrectos” (firstTime y savedUser). 403 cuenta restringida va al banner, no al password | Conforme |
| 5 | `M1-V03` | — | Email / clave vacíos | CTA deshabilitado; sin POST. Formato inválido de correo: sí entra a `handleLogin` y pone `emailError` | Conforme |
| 6 | `M1-V04` | `POST /auth/login` | Usuario persistido, “Entrar a mi cuenta” | Email de `user.email` \|\| `savedEmail`, no del input. Body `{ email, password }`. Post-éxito igual que V02 | Conforme |
| 7 | `M1-V04` · `M1-RN-ACC-025` | — | Cara savedUser | Saludo “¡Hola {nombre}!” + solo clave (o biometría). “Cambiar de usuario” hace logout completo. Splash no entra a tabs | Conforme |

### Biometría en esta pantalla — MV-M1-02

No es `/(auth)/biometric-setup`. Es el reingreso.

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
| --- | --- | --- | --- | --- | --- |
| 8 | `M1-V05` · `M1-RN-ACC-026` | — | Saved user + biometría ON + token en store | Cara `savedUserBiometric`. CTA “Entrar”. Link “Ingresar con clave”. No dispara API hasta el éxito | Conforme |
| 9 | `M1-V06` | `GET /users/me` + `GET /auth/onboarding` | Huella/Face OK | No llama `POST /auth/login`. Tras `me`, consulta onboarding y retoma `currentGate` igual que el login con clave. Perfil vacío y sin puerta → choose-alias | Conforme |
| 10 | `M1-V07` · `M1-RN-ACC-027` | — | 3 fallos (`loginWithBiometric` → `null`) | `MAX_BIOMETRIC_ATTEMPTS = 3` → `savedUserPassword`. Sin `logout-all`. Fallo de huella no muestra mensaje; solo cuenta el intento | Conforme |

### Salidas de esta pantalla (variante vive en otro flujo)

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
| --- | --- | --- | --- | --- | --- |
| 11 | `M1-V08` · `M1-RN-ACC-005` | — | “Crea tu cuenta” | `router.push("/register")`. Sin API | Conforme |
| 12 | `M1-V17` · `M1-RN-ACC-019` | — | “¿Olvidaste tu contraseña?” / “¿Necesitas recuperar…?” | `router.push("/forgot-password")`. Sin API acá | Conforme |
| 13 | `M1-V13` | `POST /auth/email-verification/request` | Login 200 con `nextStep: email_verification` | Abre verify-code. El backend **ya** reenvía el OTP en el login; el front vuelve a pedir. Si el POST del front falla, igual navega | Conforme |

### Retoma post-login (`GET /auth/onboarding`)

El login con clave y la huella rutean igual tras `GET /auth/onboarding`:

1. `onboardingStatus === "completed"` → si el device puede biometría y aún no está activa, `/(auth)/biometric-setup?next=home`; si no, tabs.
2. `currentGate` con ruta en `ONBOARDING_GATE_ROUTE` → esa pantalla. **Incluye** `resumeState: ready_to_resume`: la pausa no salta la puerta. **No** ofrece biometría (prueba03 va a carga).
3. Sin puerta y perfil vacío → choose-alias.
4. Si el GET falla y perfil vacío → choose-alias; si no → tabs / biometric-setup.

| # | ID variante | Señal (front hoy) | Destino | Estado |
| --- | --- | --- | --- | --- |
| 14 | `M1-V13` | `nextStep: email_verification` (respuesta de login, no el GET) | verify-code + request OTP | Conforme |
| 15 | `M1-V26` | — | Destino Home + device con biometría y aún no activa → `/(auth)/biometric-setup?next=home` (pantalla Walvy). “Omitir y continuar” / “Activar acceso rápido” → `/(tabs)`. No es el `Alert` | Conforme |
| 16 | `M1-V24` | sin `currentGate` + `hasNoProfileData` | `/(auth)/choose-alias` | Conforme |
| 17 | `M1-V27` | `G0_activacion` | `/(auth)/onboarding` | Conforme |
| 18 | `M1-V28` / `M1-V58` | `G1_foco` | `/(auth)/onboarding-foco` | Conforme |
| 19 | `M1-V37` / `M1-V59` | `G2_carga` | `/(auth)/onboarding-doc` | Conforme |
| 20 | `M1-V44` / `M1-V60` | `G3_analisis` | `/(auth)/onboarding-analyzing` | Conforme |
| 21 | — | `G4_revision` | `/(auth)/onboarding-analysis` | Conforme |
| 22 | — | `G5_diagnostico` | `/(auth)/onboarding-first-ready` | Conforme |
| 23 | `M1-V02` Home | `completed` · o `G6_retoma` (sin ruta) | `/(tabs)` | Conforme |
| 23b | `M1-V02` / `V58` | `in_progress` · `G2_carga` · `resumeState: ready_to_resume` | `/(auth)/onboarding-doc` — no tabs | Conforme |

`G6_retoma` no está en `ONBOARDING_GATE_ROUTE`: cae a tabs, que es el sentido de esa puerta.

---

## Qué no va en esta pantalla

| ID | Archivo |
| --- | --- |
| Arranque cold start / probe | [`splash.md`](splash.md) |
| Registro (V09–V12) | [`register.md`](register.md) |
| OTP de cuenta (V14–V16) | [`verify-code.md`](verify-code.md) |
| Recuperación (V18–V23) | forgot / reset |
| Activar biometría primer ingreso (UI de setup) | [`biometric-setup.md`](biometric-setup.md) |

---

## Notas para el caso

- V02 “dirigir a Home” está **ajustado por PO**: autenticación OK ≠ Home. Cubrir filas 14–23, no solo tabs.
- Jest (`login.test.tsx`) cubre firstTime, CTA deshabilitado, login → tabs si `completed`, login → cartola si `G2_carga` + pausa, y los dos links. Huella y savedUser no están en el suite.
- V06 (huella) retoma por `GET /auth/onboarding`, igual que el camino con clave.
- `onboardingStatus === completed` casi no ocurre en el flujo real (`allDone` vs `M1-DP-009`). “Salir por ahora” deja `resumeState: ready_to_resume` con onboarding `in_progress`; el login siguiente sigue la puerta. Ver wiki § Cierre en [`frontend-pantallas-endpoints.md`](../frontend-pantallas-endpoints.md).
- Cuenta restringida: `POST /auth/login` → **403** (`M1-BC-005`). El interceptor de refresh no aplica (no es 401). El usuario se queda en login con el mensaje de soporte.
- Refresh no tiene variante propia; si el login 200 y el GET onboarding 401, el interceptor puede rotar y reintentar.

**Anterior:** [`splash.md`](splash.md) · **Siguiente:** [`register.md`](register.md)
