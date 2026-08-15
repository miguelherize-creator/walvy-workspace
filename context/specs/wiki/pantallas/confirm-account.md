# Confirm-account / Verify (deep link)

**Componente:** `expo/features/auth/ui/AccountConfirmedScreen.tsx`  
**Rutas:** `/confirm-account`, `/verify`  
**Endpoints:** ninguno

UI de resultado de enlace. El front documenta que hoy **nadie las abre**: la verificación es OTP de 6 dígitos ([`verify-code.md`](verify-code.md) V13–V15).

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | — | — | Deep link `status=success\|error` | Muestra éxito o enlace inválido → login | Pendiente |

No hay ID de matriz para esta superficie.
