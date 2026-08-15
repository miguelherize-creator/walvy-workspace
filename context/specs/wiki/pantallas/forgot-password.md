# Forgot-password — `/forgot-password`

**Componente:** `expo/features/auth/ui/ForgotPasswordScreen.tsx` + `useForgotPasswordForm`  
**Ruta:** `app/(auth)/forgot-password.tsx`  
**Tablero:** recuperación V17–V19 · regla `M1-RN-ACC-019` / `020`  
**Figma:** `3470:7010` · sin acceso al correo `3470:7029`

Entra desde login (`M1-V17`).

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| POST | `/auth/forgot-password` | `useForgotPasswordForm` | CTA con email válido |

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V17` | — | “¿Olvidaste tu contraseña?” | Abre Recupera tu acceso. Sin API | Pendiente |
| 2 | `M1-V18` | `POST /auth/forgot-password` | Correo válido | Envía OTP. Navega a verify-code modo reset | Pendiente |
| 3 | `M1-V18` | — | Correo vacío / inválido | Sin POST. Error inline | Pendiente |
| 4 | `M1-V19` | — | Usuario sin acceso al correo | Matriz: derivar a soporte (`soporte@walvy.cl`). Confirmar si el CTA está en esta UI | Pendiente |

---

**Anterior:** [`login.md`](login.md) · **Siguiente:** [`verify-code.md`](verify-code.md) (modo reset) → [`reset-password.md`](reset-password.md)
