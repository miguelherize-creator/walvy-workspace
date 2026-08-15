# Plan de mejora — respuesta al acta de reunión

Fecha: 2026-08-03
Rama: `feature/db-schema-regen-migrations` (14 migraciones, 74 tablas)
Base de la medición: su `DB/model/schema.sql` aplicado a una base limpia, contra
nuestras 14 migraciones aplicadas sobre la base de desarrollo.

## 1. Lo que ya está resuelto

Se puede afirmar en la respuesta, con evidencia reproducible:

| Acuerdo del acta | Evidencia |
|---|---|
| Migraciones incrementales versionadas, no un `schema.sql` consolidado | 14 migraciones con `up`/`down`; cada una verificada con run → drift → revert byte a byte |
| Retirar `identifier_type` | eliminado en `AlignSchemaM2M4` |
| `username` no debe ser único (es alias) | el backend **no** lo tiene único |
| RUT como `document_type` + `document_number` | `uq_app_user_document (country_id, document_type_id, document_number)`, parcial |
| RUT único, no sirve para login, un RUT = una cuenta | login por email; el índice bloquea el segundo registro; `23505` traducido a `ConflictException` |
| `app_user` + roles, sin `admin_users` | `permission` + `role_permission` con 12 permisos y asignación por rol; `admin_users` retirada con guardia contra pérdida de cuentas |
| Auditoría centralizada | `admin_audit_log` absorbida en `audit_log` (+`before_data`/`after_data`) |
| Comentarios por tabla y campo | 294/294 columnas y 14/14 tablas con el texto exacto de `comments.sql`, incluidas las 45 referencias `Fuente: BDD/Rector` |

**Punto a devolverle:** su propio modelo declara `app_user_username_key` —un índice
único sobre `username`— que contradice el acuerdo 8. El backend está correcto; lo
que hay que corregir es el modelo.

## 2. La brecha, medida

Comparación objeto por objeto entre las dos bases:

| | Su modelo | El nuestro | Δ |
|---|---|---|---|
| Tablas | 71 | 75 | — |
| CHECK | 84 | 77 | −7 |
| Comentarios | — | completos | ✅ |
| **Índices** | 87 | 34 | **−53** |
| **Funciones propias** | 11 | 0 | **−11** |
| **Triggers** | 59 | 0 | **−59** |
| **Vistas** | 4 | 0 | **−4** |

Es exactamente el punto 1 del acta: *"la base actualmente visible no contiene todo
lo que se había trabajado previamente a nivel de comentarios, triggers,
procedimientos, índices, checks"*. Los comentarios y la mayoría de los CHECK ya se
cerraron; triggers, funciones, índices y vistas siguen en cero.

## 3. Fases propuestas

### F1 — Esquema cero reproducible (bloquea todo lo demás)

El acta pide *"tomar el estado del código real de walvy-org como esquema cero"*.
Hoy no existe: **la cadena de migraciones no corre sobre una base vacía**. La
primera migración asume las 52 tablas que en desarrollo nacieron de
`synchronize: true`, no de una migración.

```
createdb vacia && migration:run
→ error: relation "user_goals" does not exist
```

Solución: una migración baseline anterior a `AlignSchemaM2M4` que cree esas 52
tablas, con guardia `if (await queryRunner.hasTable('app_user')) return;` para que
en kabelidev se registre como aplicada sin hacer nada y en walvy-org sí construya.

Sin esto no hay entorno nuevo reproducible ni "esquema cero" verificable.

### F2 — Integridad en la base, no solo en el código

`enforce_status_domain()` más un trigger por cada tabla con `*_status_id`. Hoy
nada impide asignar un status del dominio `subscription` a `debt.debt_status_id`:
la base acepta el UPDATE.

Columnas afectadas: `app_user.user_status_id`, `debt.debt_status_id`,
`file_upload.file_status_id`, `financial_movement.movement_status_id`,
`user_financial_profile.current_debt_health_status_id`,
`user_month_diagnosis_summary.debt_health_status_id`,
`user_upcoming_payments_summary.user_payment_status_id`. Siete triggers.

Es el hueco de más valor: es la diferencia entre una regla que vive en el código y
una que la base garantiza.

### F3 — Índices de consulta

47 índices `idx_*` en su modelo; tenemos 2. De los 45 que faltan, **34 aplican
sobre tablas que ya existen** y 11 esperan tablas de otros bloques.

De los 6 que ella listó en el primer correo como consultas de negocio, solo está
`idx_fin_mov_user_date`. Faltan los de presupuesto (`idx_bp_user`, `idx_bpi_plan`),
deuda (`idx_debt_user_snowball`) y notificaciones (`idx_nq_pending`); los de cola
de revisión y pagos próximos esperan sus tablas.

### F4 — `set_updated_at()` y sus triggers

55 tablas tienen `updated_at`. TypeORM lo mantiene desde la aplicación con
`@UpdateDateColumn`, así que funciona para toda escritura del backend; el trigger
cubre el `UPDATE` directo por SQL, que es el caso de un job batch o una corrección
manual.

Es el más mecánico de los cuatro y el de menor riesgo, pero también el de menor
urgencia: hoy no hay escrituras fuera del backend.

### F5 — Vistas

Las 4 (`v_user_access`, `v_user_current_subscription`,
`v_subscription_effective_state`, `v_user_home_month`) dependen de las tablas de
suscripción, que siguen pendientes. No es priorizable todavía.

## 4. Fuera del alcance de código

Del acta, estos puntos no se resuelven en el repositorio y conviene responderlos
por separado:

- Dump de Sandbox pendiente de envío.
- Evidencia de cómo viaja la información de Módulo 1 (request/response, tablas
  afectadas, datos persistidos).
- Encriptación del RUT: decisión pendiente con José Miguel.
- Versionado del API interno de cartolas (v1 → v2) y sus contratos.
- Trazabilidad entre documentación funcional, casos de prueba y evidencias.
- Migración del trabajo al repositorio de la organización Walvy.

## 5. Orden recomendado

1. **F1** primero, sin excepción: es el "esquema cero" que pide el acta y sin él
   walvy-org no se puede montar.
2. **F2**, porque es integridad real y es el argumento central del punto 1.
3. **F3**, que además habilita las consultas de M4 y M5 cuando se implementen.
4. **F4** cuando lo anterior esté cerrado.
5. **F5** cuando existan las tablas de suscripción.

F1 a F4 son independientes entre sí una vez hecho F1, así que pueden ir en
commits separados y revisarse por partes.
