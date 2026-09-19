# Reset-password — `/(auth)/reset-password`

**Componente:** `expo/features/auth/ui/ResetPasswordScreen.tsx` + `useResetPasswordForm`  
**Ruta:** `app/(auth)/reset-password.tsx`  
**Tablero:** V22–V23 · `M1-RN-ACC-023` / `024`  
**Figma:** coincide `3655:2970` · no coincide `3655:3058`

Llega de verify-code modo reset con `email` + `code` (el OTP **aún no** se consumió).

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| POST | `/auth/reset-password` | `useResetPasswordForm` | CTA guardar. Body `{ email, code, newPassword }` |

El backend consume el OTP, cambia la clave y **revoca todos los refresh**.

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V23` | — | Nueva ≠ confirmación | Sin POST. Error, CTA off | Pendiente |
| 2 | `M1-V22` | — | Complejidad no cumple | Sin POST. Mismas reglas que register | Pendiente |
| 3 | `M1-V22` | `POST /auth/reset-password` | Nueva = confirmación y reglas OK | 200. Navega a login. Sesiones previas muertas | Pendiente |
| 4 | `M1-V21` (eco) | `POST /auth/reset-password` | Code ya usado / inválido | Error. No deja la clave a medias | Pendiente |

---

**Anterior:** [`verify-code.md`](verify-code.md) · **Siguiente:** [`login.md`](login.md)
