# Choose-alias — `/(auth)/choose-alias`

**Componente:** `expo/features/auth/ui/ChooseAliasScreen.tsx` + `useChooseAliasForm`  
**Ruta:** `app/(auth)/choose-alias.tsx`  
**Tablero:** primer ingreso V24–V25 · `M1-RN-ACC-016` / `017` / `018`  
**Figma:** completar `3470:7207` · salir `3470:7228`  
**Revisión código:** 17 ago 2026 · `kabeli-main` (PR Walvy [#86](https://github.com/walvy-org/walvy-app-frontend/pull/86))

Nombre, apellido, alias. No usa el deprecado `PATCH /users/profile`. No llama `PATCH /auth/onboarding/step`: esta pantalla solo persiste perfil y elige destino.

Entra cuando el login o la huella no tienen `currentGate` y el perfil está vacío (`hasNoProfileData`). Dos CTAs, los dos guardan:

- **Guardar y continuar** (V24) → onboarding.
- **Guardar y salir** (V25, ajuste v2.6) → Home (`/(tabs)`). Conserva lo ingresado y **sale del flujo**. No es omisión con avance al siguiente paso.

No hay “Omitir y continuar”.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| PATCH | `/users/me` | `updateProfile` ← `saveProfile` | Ambos CTAs, si hay al menos un dato. `{ firstName?, lastName?, username? }` |

401 en el PATCH → `/(auth)/login`. Otro error → `AuthMessageBox`, se queda acá.

---

## Control: variante × endpoint

Estados = revisión de código, no corrida QA en dispositivo.

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V24` | `PATCH /users/me` | “Guardar y continuar” con al menos un dato | Persiste nombre/apellido/alias. Username: `[a-zA-Z0-9_.\-]+`, ≤ 50, al menos un alfanumérico. Luego `/(auth)/onboarding` | Conforme |
| 2 | `M1-V25` | `PATCH /users/me` | “Guardar y salir” con al menos un dato | Persiste igual que V24. Luego `/(tabs)`, **no** onboarding | Conforme |
| 3 | `M1-V24` / `V25` | — | Formulario vacío | Ambos CTAs deshabilitados. Sin PATCH. Copy: “Ingresa al menos un dato para continuar” | Conforme |
| 4 | `M1-V24` | `PATCH /users/me` | Alias inválido | Sin avance. Error inline | Conforme |
| 5 | — | — | Ya tiene `username` | Continuar no vuelve a PATCH; salir va directo a tabs | Conforme |

La matriz v1 decía V25 = “omitir datos y continuar”. Figma v2.6 y el código son “Guardar y salir”: hay que haber ingresado algo, se persiste, y el destino es Home.

Jest (`choose-alias.test.tsx`): no existe “Omitir y continuar”; vacío no dispara API; salir guarda y va a tabs; continuar guarda y va a onboarding.

---

**Anterior:** [`verify-code.md`](verify-code.md) · **Siguiente:** [`onboarding.md`](onboarding.md)
