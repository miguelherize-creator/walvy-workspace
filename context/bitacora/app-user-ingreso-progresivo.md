# `app_user` e ingreso progresivo de datos

**Fecha:** 2026-08-10
**Para:** punto 4 de la revisión de BD
**Medido sobre:** `main` con #66, #67 y #68 mergeados

---

## 1. Qué exige el registro inicial

`POST /auth/register` — [`register.dto.ts`](../../../../back-walvy/src/auth/dto/register.dto.ts)
y [`auth.service.ts:45`](../../../../back-walvy/src/auth/auth.service.ts)

| Campo | Validación | Dónde se aplica |
|---|---|---|
| `email` | formato válido y no vacío | DTO |
| `documentNumber` | no vacío, máx. 50, **RUT válido y normalizado** | DTO + `auth.service.ts:70` |
| `password` | 8+ caracteres, una mayúscula, un dígito, máx. 72 **bytes** | DTO |
| `acceptTerms` | debe ser `true` | `auth.service.ts:46` |
| `acceptPrivacy` | debe ser `true` | `auth.service.ts:51` |

El DTO declara los dos consentimientos como booleanos, así que `false` pasa la
validación de forma; el rechazo lo hace el servicio con un mensaje explícito.

Rechazos por unicidad: correo repetido → 409; documento repetido para el mismo
país y tipo → 409. El documento se normaliza antes de guardar, para que
`12.345.678-5` y `12345678-5` colisionen bajo el índice único en vez de entrar
como dos personas.

## 2. Qué escribe el registro sin pedirlo al cliente

`app_user` tiene **27 columnas y solo 4 de negocio son NOT NULL**:
`country_id`, `default_currency_id`, `role_id` y `user_status_id`. Las cuatro
las resuelve el backend desde los catálogos sembrados, nunca llegan del cliente.
El usuario nace en `pending_verification`.

Todo lo demás acepta null, incluidos `email` y `password_hash`. Es el diseño de
captura progresiva que la revisión describe.

## 3. Qué se completa después

| Etapa | Campos |
|---|---|
| Verificación de correo | `email_verified_at`, y el estado pasa a `active` |
| Perfil | `first_name`, `last_name`, `username`, `avatar_url` |
| Notificaciones | `notification_email`, `notification_email_verified_at` |
| Suscripción | `trial_started_at`, `trial_ends_at` |
| Diagnóstico | `current_financial_health_level_id`, `financial_health_updated_at` |

Ninguno es obligatorio para que la cuenta exista.

## 4. Qué exige el login local en el MVP

[`auth.service.ts:108`](../../../../back-walvy/src/auth/auth.service.ts): correo
registrado **y `password_hash` no nulo**. Si el hash es null —el caso que
tendría una cuenta creada por un proveedor externo— el login local devuelve
credenciales inválidas, sin filtrar que la cuenta existe.

Una cuenta en `pending_verification` **sí** recibe tokens al iniciar sesión,
pero con `nextStep: 'email_verification'`. Es deliberado: sin token no podría
llamar a `/auth/email-verification/resend` y quedaría encerrada.

## 5. Cuándo se considera completo el onboarding

[`user-onboarding.service.ts:52`](../../../../back-walvy/src/auth/services/user-onboarding.service.ts):

```ts
const allDone =
  state.financialProfileCompleted &&
  state.importAttempted &&
  state.biometricPrompted &&
  state.minDocThresholdMet;
```

Cuando los cuatro están en `true`, el backend pone `onboarding_status =
'completed'`, sella `completed_at` y deja `resume_surface = 'home'`.

**`goalsSet` está excluido de esa condición a propósito**, con este comentario
en el código: *«goals_set excluido hasta que tenga pantalla asignada en el flujo
UI»*. O sea que hoy una cuenta puede completar el onboarding sin haber fijado
ninguna meta.

---

## 6. Qué validación impide avanzar si falta información

**Ninguna, y esto es lo que conviene decidir.**

Los cuatro checkpoints son booleanos que el cliente envía por
`PATCH /auth/onboarding/step` y que el backend guarda tal cual. Verificado: no
hay una sola consulta que contraste el checkpoint contra el dato que dice
representar.

| Checkpoint | Lo que afirma | Lo que el backend verifica |
|---|---|---|
| `financialProfileCompleted` | hay perfil financiero | nada |
| `goalsSet` | hay metas declaradas | nada |
| `importAttempted` | hubo carga de cartola | nada |
| `minDocThresholdMet` | se alcanzó el umbral documental | nada |

`profile` e `imports` tampoco tocan el estado de onboarding: no hay ruta por la
que el backend marque un checkpoint por su cuenta. Los únicos que los escriben
son la inicialización, que los deja en `false`, y este PATCH.

**Consecuencia:** un cliente puede enviar los cuatro en `true` y la cuenta queda
`completed` sin una fila en `user_financial_profile`, sin `user_goals`, sin
`statement_imports` y sin ningún documento. El estado dice que el usuario
recorrió el onboarding y las tablas dicen que no.

Esto se observó en la práctica: el fixture de datos de prueba declaraba
`goals_set = true` para tres cuentas con `user_goals` vacía. No era un error del
fixture, reproducía lo que la API permite.

Y `minDocThresholdMet` no tiene umbral detrás: el valor que lo definiría es
`max_critical_indicators_missing_for_partial`, sembrado en `rule_parameter` bajo
`onboarding_diagnosis_v1_0`, y hasta el PR en curso ninguna línea de código lo
leía.

### Opciones

1. **Verificar en el servidor.** El PATCH deja de aceptar el booleano y el
   backend lo deriva: `financialProfileCompleted` mira `user_financial_profile`,
   `goalsSet` mira `user_goals`, `importAttempted` mira `statement_imports`,
   `minDocThresholdMet` compara contra el parámetro de regla. Es lo que impide
   estados inconsistentes, y es trabajo de endpoints.
2. **Dejarlo declarativo y documentarlo.** El checkpoint pasa a ser lo que el
   cliente afirma haber mostrado, no lo que ocurrió. Barato, pero entonces
   `onboarding_status = 'completed'` no es evidencia de nada.

La opción 1 es la que corresponde si el criterio es que no haya usuarios en
estados inconsistentes. Requiere decisión porque cambia el contrato del endpoint
con el front.

Punto aparte para producto: si `goalsSet` sigue fuera de la condición de
completitud, hay que decidir si el Foco del Mes es opcional en el MVP o si falta
la pantalla que lo haría obligatorio.
