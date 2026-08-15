# Choose-alias — `/(auth)/choose-alias`

**Componente:** `expo/features/auth/ui/ChooseAliasScreen.tsx` + `useChooseAliasForm`  
**Ruta:** `app/(auth)/choose-alias.tsx`  
**Tablero:** primer ingreso V24–V25 · `M1-RN-ACC-016` / `017` / `018`  
**Figma:** completar `3470:7207` · omitir `3470:7228`

Nombre, apellido, alias. No usa el deprecado `PATCH /users/profile`.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| PATCH | `/users/me` | `updateProfile` | Guardar. `{ firstName, lastName, username }` |
| PATCH | `/auth/onboarding/step` | `advanceOnboardingStep` | Guardar y omitir. Front: `{ currentStep: "welcome", resumeSurface: "onboarding" }` |

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V24` | `PATCH /users/me` | Completa y continúa | Persiste nombre/alias. Username con regex `[a-zA-Z0-9_.\-]+` | Pendiente |
| 2 | `M1-V24` | `PATCH /auth/onboarding/step` | Tras save OK | Declara paso welcome. Body viejo vs puertas: 400 posible | Pendiente |
| 3 | `M1-V25` | — | Omitir | **No** llama `/users/me`. Sigue al onboarding | Pendiente |
| 4 | `M1-V25` | `PATCH /auth/onboarding/step` | Omitir | Igual declara welcome (si falla 401 → login; otro error igual avanza) | Pendiente |
| 5 | `M1-V24` | `PATCH /users/me` | Alias inválido | Sin avance. Error inline | Pendiente |

---

**Anterior:** [`biometric-setup.md`](biometric-setup.md) · **Siguiente:** [`onboarding.md`](onboarding.md)
