# Login — `/login`

**Componente:** `expo/features/auth/ui/LoginScreen.tsx` + `useLoginForm` + `useBiometricLogin`  
**Ruta:** `app/(auth)/login.tsx`  
**Tablero:** [MV-M1-01](https://github.com/KabeliDev/front-walvy/issues/18) V01–V04 · [MV-M1-02](https://github.com/KabeliDev/front-walvy/issues/19) V05–V07  
**Figma:** firstTime `3470:6974` · savedUserPassword `3470:7098` · savedUserBiometric `3470:7080` · error `3677:2837`

Llega **siempre** desde splash. Tres caras: firstTime, savedUserPassword, savedUserBiometric. El submit y la huella viven acá; el destino post-éxito lo arma `GET /auth/onboarding`.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| POST | `/auth/login` | `AuthProvider.login` ← `useLoginForm` | CTA Entrar (firstTime y savedUserPassword) |
| GET | `/auth/onboarding` | `useLoginForm` post-login | Credenciales OK, para retoma |
| POST | `/auth/email-verification/request` | `useLoginForm` | Onboarding en `email_verification` (o `nextStep`) |
| GET | `/users/me` | `AuthProvider.loginWithBiometric` | Huella OK (no reenvía password) |
| POST | `/auth/refresh` | interceptor | 401 en onboarding / me, si hay refresh |

---

## Control: variante × endpoint

### Acceso / Login — MV-M1-01

| # | ID variante | Endpoint | Disparador | Esperado (matriz + este front) | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V01` | — | Entra sin usuario guardado | UI correo + contraseña. Link “Crea mi cuenta” y “¿Olvidaste…?” | Pendiente |
| 2 | `M1-V02` | `POST /auth/login` | Correo/clave válidos | 200 + tokens. **No** ir fijo a Home: sigue fila 3 | Pendiente |
| 3 | `M1-V02` · `M1-V06` (ajuste PO) | `GET /auth/onboarding` | Login 200 | Destino según estado: verify-code / biometric / alias / onboarding / doc / analyzing / tabs. Matriz dice “Home”; PO: continuidad por estado funcional | Pendiente |
| 4 | `M1-V03` | `POST /auth/login` | Clave o correo inválidos | 401. Se queda en login. firstTime: error de credenciales; savedUser: error inline en password | Pendiente |
| 5 | `M1-V03` | — | Email vacío / formato | Sin POST. `emailError` inline | Pendiente |
| 6 | `M1-V04` | `POST /auth/login` | Usuario persistido, “Ingresar con clave” | Email de SecureStore (no del input). Body `{ email, password }`. Post-éxito igual que V02 | Pendiente |
| 7 | `M1-V04` · `M1-RN-ACC-025` | — | Cara savedUser | Saludo + solo clave (o biometría). Pedir re-auth; no entrar a tabs por el restore de splash | Pendiente |

### Biometría en esta pantalla — MV-M1-02

No es `/(auth)/biometric-setup`. Es el reingreso.

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 8 | `M1-V05` | — | Saved user + biometría ON | CTA Face ID / huella. No dispara API hasta el éxito | Pendiente |
| 9 | `M1-V06` | `GET /users/me` | Huella/Face OK | No llama `POST /auth/login`. Restaura user. Destino: tabs si onboarding completo; si no, misma retoma que V02 (hoy `useBiometricLogin` va a tabs si hay username — contrastar) | Pendiente |
| 10 | `M1-V07` · `M1-RN-ACC-027` | — | 3 fallos biométricos | Fallback a savedUserPassword. Sin logout-all. `MAX_BIOMETRIC_ATTEMPTS = 3` | Pendiente |

### Salidas de esta pantalla (variante vive en otro flujo)

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 11 | `M1-V08` | — | “Crea mi cuenta” | `/(auth)/register`. Sin API | Pendiente |
| 12 | `M1-V17` | — | “¿Olvidaste tu contraseña?” | `/forgot-password`. Sin API acá | Pendiente |
| 13 | `M1-V13` | `POST /auth/email-verification/request` | Login OK y cuenta `pending_verification` / step `email_verification` | Reenvía OTP y abre verify-code | Pendiente |

### Retoma post-login (`GET /auth/onboarding`)

Casos de la fila 3. El mapa del front `walvy/main` usa `currentStep` (el backend nuevo usa `currentGate` — riesgo de caer a tabs).

| # | ID variante | `currentStep` (front hoy) | Destino | Estado |
|---|---|---|---|---|
| 14 | `M1-V13` | `email_verification` | verify-code + request OTP | Pendiente |
| 15 | `M1-V26` | `biometric_setup` | `/(auth)/biometric-setup` | Pendiente |
| 16 | `M1-V24` | `profile_basic` | `/(auth)/choose-alias` | Pendiente |
| 17 | `M1-V27` | `welcome` | `/(auth)/onboarding` | Pendiente |
| 18 | `M1-V37` / `M1-V58` | `document_upload` | `/(auth)/onboarding-doc` | Pendiente |
| 19 | `M1-V44` / `M1-V60` | `document_processing` | `/(auth)/onboarding-analyzing` | Pendiente |
| 20 | `M1-V02` si `completed` o `resumeSurface: home` | — | `/(tabs)` | Pendiente |

---

## Qué no va en esta pantalla

| ID | Archivo |
|---|---|
| Arranque cold start / probe | [`splash.md`](splash.md) |
| Registro (V09–V12) | `register.md` (pendiente) |
| OTP de cuenta (V14–V16) | `verify-code.md` |
| Recuperación (V18–V23) | forgot / reset |
| Activar biometría primer ingreso (V26 UI) | `biometric-setup.md` |

---

## Notas para el caso

- V02 “dirigir a Home” está **ajustado por PO**: autenticación OK ≠ Home. Cubrir filas 14–20, no solo tabs.
- V09 biométrica: `goToDashboard()` si hay perfil; puede **saltar** onboarding incompleto. Marcar Divergente si se confirma.
- Contrato onboarding: si el GET trae `currentGate` y el front lee `currentStep`, V02/retoma = Divergente hasta alinear puertas.
- `onboardingStatus === completed` casi no ocurre: el backend solo cierra con las cuatro banderas de `UserOnboardingService` (ver wiki § Cierre). Home real hoy es `resumeState: ready_to_resume`, no `completed`.
- Refresh no tiene variante propia; si el login 200 y el GET onboarding 401, el interceptor puede rotar y reintentar.

**Anterior:** [`splash.md`](splash.md) · **Siguiente:** register (pendiente)
