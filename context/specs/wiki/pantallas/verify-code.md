# Verify-code — `/(auth)/verify-code`

**Componente:** `expo/features/auth/ui/VerifyCodeScreen.tsx` + `useVerifyCodeForm`  
**Ruta:** `app/(auth)/verify-code.tsx`  
**Tablero:** [MV-M1-04](https://github.com/KabeliDev/front-walvy/issues/21) V13–V16 · recuperación V20–V21  
**Figma:** inicial `3470:7580` · incorrecto `3470:7723` · correcto `3470:7774` · reenvío `3470:7626`

Dos modos por params: verificación de cuenta (post-register o retoma V13 desde login) y reset (post-forgot).

---

## Endpoints

| Método | Path | Modo | Cuándo |
|---|---|---|---|
| POST | `/auth/email-verification/confirm` | cuenta | CTA con 6 dígitos |
| POST | `/auth/email-verification/resend` | cuenta | Reenviar |
| POST | `/auth/verify-reset-code` | reset | CTA: valida **sin** consumir el OTP |
| POST | `/auth/forgot-password` | reset | Reenviar OTP de reset |

---

## Control: cuenta — V13–V16

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V13` | — | Llega de register o login retoma | UI código 6 dígitos. CTA según completitud | Pendiente |
| 2 | `M1-V14` | `POST /auth/email-verification/confirm` | Código inválido | No activa. Error, permite corregir. Máx. intentos los pone el backend | Pendiente |
| 3 | `M1-V15` | `POST /auth/email-verification/confirm` | Código válido | `emailVerified`. Avanza a primer ingreso (biometric-setup o choose-alias según onboarding) | Pendiente |
| 4 | `M1-V16` | `POST /auth/email-verification/resend` | Timer / “Reenviar” | Nuevo OTP. Cooldown/límite backend. RN de vigencia aún pendiente en matriz | Pendiente |

## Control: reset — V20–V21

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 5 | `M1-V20` | `POST /auth/verify-reset-code` | Código de recovery OK | `valid: true`. **No** cambia la clave. Navega a reset-password con email+code | Pendiente |
| 6 | `M1-V21` | `POST /auth/verify-reset-code` | Código incorrecto | Se queda acá. Reintentar / reenviar | Pendiente |
| 7 | `M1-V16` (reset) | `POST /auth/forgot-password` | Reenviar en modo reset | Nuevo OTP de recovery, no el de verification | Pendiente |

---

## Qué no va acá

Crear cuenta → [`register.md`](register.md). Nueva clave → [`reset-password.md`](reset-password.md). Deep links `/verify` y `/confirm-account` no pegan API.

**Anterior:** [`register.md`](register.md) · **Siguiente:** [`forgot-password.md`](forgot-password.md)
