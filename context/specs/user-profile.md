# Spec: Perfil de Usuario

**Estado backend:** ✅ Completo (perfil básico) · ⚠️ Deuda técnica (perfil financiero)  
**Estado frontend:** ✅ Completo (`features/profile/`)  
**Módulo NestJS:** `src/users/` + `src/profile/` (pendiente)

---

## Endpoints implementados

```
GET    /users/me                    → perfil del usuario autenticado
PATCH  /users/me                    → actualizar nombre, avatar, username
PATCH  /users/me/password           → cambiar contraseña (requiere actual)
DELETE /users/me                    → soft delete de cuenta propia
```

## Endpoints pendientes (deuda técnica)

```
GET    /profile/financial           → ❌ M2-DT-01
PUT    /profile/financial           → ❌ M2-DT-01
GET    /profile/goals               → ❌ M2-DT-02
POST   /profile/goals               → ❌ M2-DT-02
PATCH  /profile/goals/:id/deactivate → ❌ M2-DT-02
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

### PUT /profile/financial (pendiente M2-DT-01)
```json
// Request propuesto
{ "monthlyIncomeEstimate": 1500000, "stableExpensesNote": "Arriendo 400k, servicios 80k",
  "currencyId": "CLP" }
// Response 200 → perfil financiero + estimatedPaymentCapacity calculado
```

## Reglas de negocio
- Email no es editable (identificador único)
- RUT no es editable post-registro
- `username` es nullable — handle público opcional
- Soft delete: marca `deleted_at`, no elimina físicamente
- Avatar: URL pública (sin upload en MVP — el cliente manda URL directa)

## Tablas involucradas
`app_user` · `user_financial_profile` · `user_goals` · `alert_preferences`
