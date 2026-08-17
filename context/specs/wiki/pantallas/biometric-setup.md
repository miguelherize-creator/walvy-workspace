# Biometric-setup — `/(auth)/biometric-setup`

**Componente:** `expo/features/auth/ui/BiometricPromptScreen.tsx`  
**Ruta:** `app/(auth)/biometric-setup.tsx`  
**Tablero:** primer ingreso `M1-V26` · reglas ACC-026 (activar, no reingreso)  
**Figma:** `4911:5511`

Oferta de **activar** biometría: post-verificación (primer ingreso → alias) y post-login cuando el destino sería Home (`?next=home`, V26 / prueba04). El reingreso con huella ya activa es [`login.md`](login.md) V05–V07.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| PATCH | `/auth/biometric` | `setupBiometric` | Acepta (`enabled: true` + `method`) o rechaza (`enabled: false`) |
| PATCH | `/auth/onboarding/step` | `advanceOnboardingStep` | Tras aceptar o rechazar. Front hoy: `{ currentStep: "profile_basic", resumeSurface: "onboarding" }` |

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V26` | — | Primer ingreso o login a Home, device con biometría | Pantalla Walvy Face ID / huella. Login: `next=home`. Sin device, login no entra acá | Pendiente |
| 2 | `M1-V26` | `PATCH /auth/biometric` | Acepta | `enabled: true`, `method: face_id \| fingerprint`. Luego alias, o `/(tabs)` si `next=home` | Pendiente |
| 3 | `M1-V26` | `PATCH /auth/biometric` | “Omitir y continuar” | `enabled: false`. Sigue el flujo (no bloquea). `next=home` → Inicio sin huella para la próxima | Pendiente |
| 4 | `M1-V24` (paso) | `PATCH /auth/onboarding/step` | Acepta o rechaza | Front escribe `currentStep: profile_basic`. Backend puertas espera `currentGate` → 400 / retoma rota | Pendiente |

---

## Qué no va acá

V05–V07 reingreso → login. Toggle M2-V31–V36 → perfil (stub).

**Anterior:** [`verify-code.md`](verify-code.md) · **Siguiente:** [`choose-alias.md`](choose-alias.md)
