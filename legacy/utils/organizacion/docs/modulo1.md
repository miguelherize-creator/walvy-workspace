# Modulo 1: Auth y CashFlow (guia tabla por tabla)

## 1) Flujo de Login/Auth

### A) Creacion de cuenta de usuario
- Tabla `users`:
  - Se crea registro con `email`, `password_hash`, `role='user'`.
- Tabla `user_profiles`:
  - Se crea perfil 1:1 con `user_id` (nombre, locale, settings, etc.).
- Tabla `onboarding_state`:
  - Opcionalmente se inicializa el estado del onboarding (`current_step`).

Resultado: usuario creado y listo para iniciar sesion.

### B) Inicio de sesion con mail y contrasena
- Tabla `users`:
  - Busqueda por `email` y validacion de `password_hash`.
- Tabla `refresh_tokens`:
  - Si login correcto, se guarda un refresh token hasheado (`token_hash`, `expires_at`).
- Access token:
  - Normalmente se firma y devuelve al cliente (no necesariamente se persiste en BD).

Resultado: sesion activa con access + refresh token.

### C) Autenticacion biometrica
- En MVP, biometria es local del dispositivo (Face ID/huella), no reemplaza credenciales backend.
- Preferencia en BD:
  - `user_profiles.settings` (por ejemplo `"biometric_enabled": true`).
- Sesion:
  - Backend mantiene el control con `refresh_tokens`.

Resultado: reingreso rapido en app, manteniendo seguridad backend por tokens.

### D) Cambio de contrasena
- Usuario autenticado.
- Se valida la contrasena actual contra `users.password_hash`.
- Se actualiza `users.password_hash`.
- Recomendado:
  - Revocar/borrar `refresh_tokens` del usuario para cerrar sesiones anteriores.

Resultado: nueva contrasena activa y sesiones viejas invalidadas.

### E) Recuperacion de contrasena via email
- Solicitud "olvide mi contrasena":
  - Se crea token en `password_reset_tokens` (`token_hash`, `expires_at`).
- Se envia email con link/token.
- Al confirmar nueva contrasena:
  - Se marca `used_at`,
  - se actualiza `users.password_hash`,
  - opcionalmente se revocan `refresh_tokens`.

Resultado: recuperacion de acceso segura por email.

---

## 2) Donde van CashFlow (atributos y categorias)

### A) Catalogo financiero (estructura)
- Tabla `funding_sources`:
  - Equivale a "origenes" (`cc`, `tc`, `inv_01`, etc.).
- Tabla `categories`:
  - Categorias principales (Hogar, Inversiones, etc.).
- Tabla `subcategories`:
  - Subcategorias (por ejemplo "Compra dolares", "Alimentacion - Supermercado").

### B) Movimiento CashFlow (dato transaccional)
- Tabla `transactions` (nucleo):
  - `movement_type` (income/expense/transfer) -> "movimiento"
  - `flow_type` (fixed/variable) -> "tipo"
  - `funding_source_id` -> origen
  - `category_id` + `subcategory_id` -> clasificacion
  - `amount`, `occurred_on`, `description`
  - `is_ant_expense` -> gasto hormiga
  - `external_ref` -> conciliacion/importacion

### C) Presupuesto sobre categorias
- Tabla `budget_periods`:
  - Define periodo (mes/anio) por usuario.
- Tabla `budget_lines`:
  - Meta por `category_id` o `subcategory_id`,
  - `planned_amount`, `planned_min`, `planned_max`.

Esto conecta presupuesto (planificado) con gasto real (`transactions`).

### D) Importacion de cartolas/movimientos
- Tablas `statement_imports` + `import_line_items`:
  - Guardan archivo y filas parseadas.
- Tabla `movement_classification_suggestions`:
  - Sugerencias para clasificar movimientos,
  - incluyendo sugerencias hacia deuda o cuentas por pagar, con confirmacion del usuario.

---

## Resumen rapido
- Auth: `users` + `refresh_tokens` + `password_reset_tokens` + `user_profiles`.
- CashFlow: `transactions` conectada a `funding_sources`, `categories`, `subcategories`.
- Presupuesto: `budget_periods` + `budget_lines`.
- Importaciones: `statement_imports` + `import_line_items` + `movement_classification_suggestions`.
