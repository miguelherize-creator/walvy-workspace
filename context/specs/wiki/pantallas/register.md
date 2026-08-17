# Register — `/(auth)/register`

**Componente:** `expo/features/auth/ui/RegisterScreen.tsx` + `useRegisterForm`  
**Ruta:** `app/(auth)/register.tsx`  
**Tablero:** [MV-M1-03](https://github.com/KabeliDev/front-walvy/issues/20) V08–V12  
**Figma:** entrada `3470:7249` · válido `3604:3521` · inválido `3604:3621` · T&C `3604:3925`

Entra desde login (`M1-V08`). Un solo endpoint. El OTP lo dispara el backend en el register; esta pantalla no llama verification.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| POST | `/auth/register` | `AuthProvider.register` ← `useRegisterForm` | CTA crear cuenta, validaciones OK |

Body: `{ email, documentNumber, password, acceptTerms, acceptPrivacy }`. El RUT del input se normaliza a `documentNumber`.

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V08` | — | “Crea mi cuenta” en login | Abre este formulario. Sin API | Pendiente |
| 2 | `M1-V10` | — | Email/RUT/clave inválidos o vacíos | Sin POST. Errores inline. CTA no avanza | Pendiente |
| 3 | `M1-V11` | — | Datos OK, T&C sin aceptar | Sin POST. Mensaje “Debes aceptar los términos…” | Pendiente |
| 4 | `M1-V12` | — | Datos OK, privacidad sin aceptar | Sin POST. Mensaje de política | Pendiente |
| 5 | `M1-V09` | `POST /auth/register` | Todo válido + ambos checks | 201 + tokens. Navega a verify-code con `email`. Backend ya envió OTP | Pendiente |
| 6 | `M1-V09` | `POST /auth/register` | Correo ya registrado | 409 `code: email_taken`. Error en el campo correo: “Este correo ya está registrado” | Pendiente |
| 7 | `M1-V09` | `POST /auth/register` | RUT ya registrado | 409 `code: document_taken`. Error en el campo RUT: “Este RUT ya está registrado” | Pendiente |
| 8 | `M1-RN-ACC-008` / `009` | — | Contraseña / RUT | Complejidad (8, mayúscula, número) y tope de bytes. RUT `^\d{7,8}-[\dkK]$` post-normalizar | Pendiente |

---

## Qué no va acá

OTP (V13–V16) → [`verify-code.md`](verify-code.md). Alias (V24) → [`choose-alias.md`](choose-alias.md).

**Anterior:** [`login.md`](login.md) · **Siguiente:** [`verify-code.md`](verify-code.md)
