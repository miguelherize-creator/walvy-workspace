# Spec: Perfil de Usuario

**Estado backend:** ✅ Completo (perfil básico) · ⚠️ Deuda técnica (perfil financiero)  
**Estado frontend:** ✅ Completo (`features/profile/`)  
**Módulo NestJS:** `src/users/` + `src/profile/`

---

## Endpoints implementados

```
GET    /users/me                    → perfil del usuario autenticado
PATCH  /users/me                    → actualizar nombre, avatar, username
POST   /users/me/avatar             → subir foto de perfil (multipart → S3)
PATCH  /users/me/password           → cambiar contraseña (requiere actual)
DELETE /users/me                    → soft delete de cuenta propia
GET    /profile/goals               → foco financiero activo del mes
POST   /profile/goals               → definir/sobrescribir el foco del mes
```

### GET/POST /profile/goals — Foco financiero del mes
```
focusId ∈ { bajar_deuda, ahorrar_monto, aumentar_margen,
            evitar_atrasos, cumplir_presupuesto, ordenar_compromisos }
GET  → { focusId, updatedAt } · 404 si no tiene foco
POST → body { focusId } · sobrescribe (máx 1 foco activo) · 400 si inválido/ausente
Persistencia: user_goals (fila is_active=true, goal_type ← focusId)
Validación: @IsIn contra VALID_FOCUS_IDS en SetFocusDto
```

### POST /users/me/avatar
```
multipart/form-data · campo `file` (JPG/PNG/WEBP, máx 5MB)
→ sharp: 400×400 WebP → S3 key avatars/{userId}/{uuid}.webp
→ borra avatar anterior (si era nuestro) → actualiza avatar_url
→ Response 200: usuario completo (shape de GET /users/me)
Errores: 400 (formato/ausente) · 401 · 413 (>5MB)
Infra: S3Service reutilizable en src/storage/ (lo reusará cartola V2)
Env: S3_BUCKET, S3_REGION, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY, CDN_BASE_URL
```

### GET/PUT /profile/financial — Perfil financiero
```
GET  → { userId, monthlyIncomeEstimate, stableExpensesNote,
         estimatedPaymentCapacity, updatedAt } · 404 si nunca se guardó
PUT  → upsert parcial. Body (todos opcionales):
       { monthlyIncomeEstimate, estimatedPaymentCapacity, stableExpensesNote, currency }
Moneda: front envía currency "CLP" (ISO) → se mapea a currency_id interno.
        La respuesta OMITE currencyId (front lo ignora; resuelve símbolo local).
        Default CLP al crear. Moneda inexistente → 400.
Montos: validación > 0 (front bloquea vacío; el 0 se rechaza con 400 — confirmado con front).
```

## Endpoints pendientes (deuda técnica)

```
PATCH  /profile/goals/:id/deactivate → ❌ M2-DT-02 (GET/POST ya implementados)
GET    /profile/alerts              → ❌ M2-DT-03
PUT    /profile/alerts              → ❌ M2-DT-03
```

## Contratos

### GET /users/me
```json
// Response 200
{ "id": "uuid", "email": "user@walvy.cl", "firstName": "Juan", "lastName": "Pérez",
  "rut": "12345678-5", "username": "juanp", "avatarUrl": null,
  "onboardingDone": true, "role": "user", "createdAt": "2026-01-01T00:00:00Z" }
```

### PATCH /users/me
```json
// Request (todos opcionales)
{ "firstName": "Juan", "lastName": "Pérez", "username": "juanp", "avatarUrl": "https://..." }
// Response 200 → usuario actualizado
// Error: 409 username duplicado
```

### PATCH /users/me/password
```json
// Request
{ "currentPassword": "OldPass1!", "newPassword": "NewPass1!", "confirmPassword": "NewPass1!" }
// Response 200 → { "message": "Contraseña actualizada" }
// Error: 401 contraseña actual incorrecta
```

### PUT /profile/financial ✅ implementado
```json
// Request (todos opcionales — upsert parcial)
{ "monthlyIncomeEstimate": 1500000, "estimatedPaymentCapacity": 300000,
  "stableExpensesNote": "Arriendo 400k, servicios 80k", "currency": "CLP" }
// Response 200 (omite currencyId):
{ "userId": "uuid", "monthlyIncomeEstimate": 1500000, "stableExpensesNote": "...",
  "estimatedPaymentCapacity": 300000, "updatedAt": "2026-06-08T00:00:00.000Z" }
```

## Reglas de negocio
- Email no es editable (identificador único)
- RUT no es editable post-registro
- `username` es nullable — handle público opcional
- Soft delete: marca `deleted_at`, no elimina físicamente
- Avatar: upload real vía `POST /users/me/avatar` (multipart → S3, 400×400 WebP). `PATCH /users/me` también acepta `avatarUrl` directa.

## Tablas involucradas
`app_user` · `user_financial_profile` · `user_goals` · `alert_preferences`
