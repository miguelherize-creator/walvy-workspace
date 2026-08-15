# Onboarding-doc — `/(auth)/onboarding-doc`

**Componente:** `expo/features/auth/ui/OnboardingDocScreen.tsx`  
**Ruta:** `app/(auth)/onboarding-doc.tsx`  
**Tablero:** carga V37–V43  
**Figma:** vacío `6670:13168` · password `6672:7841`

Selecciona PDF(s). El upload real es en analyzing. Auth: solo step.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| PATCH | `/auth/onboarding/step` | al montar / al salir a home | `currentStep: "document_upload"` |
| POST | `/statement-imports/check-password` | `OnboardingDocScreen` | PDF protegido |
| POST | `/statement-imports/unlock-preview` | `OnboardingDocScreen` | Preview con clave |

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V37` | `PATCH /auth/onboarding/step` | Entra sin archivo | UI lista para cargar. Declara document_upload (body viejo vs G2_carga) | Pendiente |
| 2 | `M1-V38` | — | Selecciona archivo | Lista local. **No** upload todavía. CTA sigue a analyzing | Pendiente |
| 3 | `M1-V41` | `POST /statement-imports/check-password` | PDF con password | `needsPassword`. Pide clave | Pendiente |
| 4 | `M1-V41` | `POST /statement-imports/unlock-preview` | Clave correcta | Preview OK. Puede continuar | Pendiente |
| 5 | `M1-V40` | — | Archivo no usable | Tratamiento en analyzing/error. Acá validar tipo/nombre | Pendiente |
| 6 | `M1-V42` / `V43` | — | Desactualizado / duplicado | Matriz documental. Confirmar si esta UI los detecta o Kread después | Pendiente |
| 7 | `M1-V52` / `V58` | `PATCH /auth/onboarding/step` | Salir / omitir carga | `resumeSurface: home` + context pendingStep. No diagnóstico | Pendiente |

Upload → [`onboarding-analyzing.md`](onboarding-analyzing.md).

**Anterior:** [`onboarding-foco.md`](onboarding-foco.md)
