# Onboarding-analyzing — `/(auth)/onboarding-analyzing`

**Componente:** `expo/features/auth/ui/OnboardingAnalyzingScreen.tsx`  
**Ruta:** `app/(auth)/onboarding-analyzing.tsx`  
**Tablero:** [MV-M1-10](https://github.com/KabeliDev/front-walvy/issues/27) V44–V47 · retoma V60  
**Figma:** progreso `6459:8394` · demora `6670:13533`

Acá se sube y se pollea el job.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| POST | `/statement-imports/upload` | `uploadCartola` | Empieza el análisis |
| GET | `/statement-imports/:id/status` | `getImportStatus` | Poll |
| POST | `/statement-imports/:id/retry` | `retryImport` | Reintento |
| GET | `/statement-imports` | `listImports` | Retoma de jobs |
| PATCH | `/auth/onboarding/step` | varios | `document_processing` + `importAttempted: true`; error vuelve a `document_upload`; salir: `home` |

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V38` / `V44` | `POST /statement-imports/upload` | Viene de doc con archivo | 200 + job. UI progreso | Pendiente |
| 2 | `M1-V44` | `GET /statement-imports/:id/status` | Poll | `parsed` → analysis. Otros estados según error | Pendiente |
| 3 | `M1-V44` | `PATCH /auth/onboarding/step` | Upload OK | `document_processing`, `importAttempted: true` | Pendiente |
| 4 | `M1-V45` | `PATCH /auth/onboarding/step` | Demora suave | Modal esperar / salir. Step `home` si sale. No perder job | Pendiente |
| 5 | `M1-V46` | — | Demora extendida | Segundo umbral. “Avisarme / volver después”. UI parcial | Pendiente |
| 6 | `M1-V47` | `PATCH /auth/onboarding/step` | Job failed / cancelled | Vuelve a doc (`document_upload`). Mensaje de error | Pendiente |
| 7 | `M1-V47` | `POST /statement-imports/:id/retry` | Reintentar | Nuevo ciclo de status | Pendiente |
| 8 | `M1-V60` | `PATCH /auth/onboarding/step` | Sale en análisis | `document_processing` + `home`. Retoma el mismo job | Pendiente |
| 9 | `M1-V59` | `GET /statement-imports` | Reabre app / login retoma | Conservar evidencia. Login manda acá si step = document_processing | Pendiente |

**Siguiente:** [`onboarding-analysis.md`](onboarding-analysis.md)
