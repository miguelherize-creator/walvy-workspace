# Resetear un usuario al welcome del onboarding

Deja la cuenta viva —mismo correo, mismo perfil, misma sesión— y la devuelve a la **bienvenida** (`G0_activacion`, `/(auth)/onboarding`). Sirve para re-probar el flujo completo sin borrar el usuario ni quemar un correo.

**Tablas:** `user_onboarding_state` · `statement_imports` (+ `import_line_items` en cascada) · `movement_classification_suggestions` · `user_month_diagnosis_summary` · `user_goals`
**Cuándo:** ambiente local / RDS dev de prueba
**No usar:** producción

---

## 0. Antes de correr SQL: ¿hay endpoint?

Si el backend corre con `DEV_TOOLS_ENABLED=true`, esto ya existe:

```
POST /dev/reset-user   { "email": "correo@de-prueba.cl" }
```

Hace el reset a `G0_activacion`, borra cartolas y líneas, purga las entradas de **DynamoDB** (dedup + tokens) y conserva el correo verificado.

Usa el endpoint cuando puedas: es lo único que limpia DynamoDB. Esta receta es para cuando no está habilitado, y además cubre **tres cosas que el endpoint no toca**:

| No lo hace el endpoint | Consecuencia si no se limpia |
|---|---|
| `user_month_diagnosis_summary` | El diagnóstico del mes anterior sobrevive. La escribe `DiagnosisSummaryWriterService` al recibir `user-financial-data.changed`, que el import emite |
| `pending_best_action` y `sufficiency_status` de `user_onboarding_state` | Las escribe `syncOnboardingPressure`; quedan con el veredicto viejo |
| `user_goals` | El foco del mes sigue activo: `goals_set` queda en `false` pero `GET /profile/goals` devuelve el foco anterior |

También conviene saber que su `DELETE FROM transactions` no hace nada: **esa tabla no existe** en el baseline —la entidad `Transaction` no tiene migración— y el borrado va protegido por `to_regclass`, así que se omite en silencio.

---

## 1. Inspeccionar antes

```sql
SELECT u.user_id,
       u.email,
       u.first_name,
       u.username,
       u.email_verified_at IS NOT NULL AS correo_verificado,
       s.onboarding_status,
       s.current_gate,
       s.last_completed_gate,
       s.resume_state,
       s.goals_set,
       s.import_attempted,
       s.min_doc_threshold_met,
       s.financial_profile_completed,
       s.completed_at,
       (SELECT count(*) FROM public.statement_imports i WHERE i.user_id = u.user_id)            AS cartolas,
       (SELECT count(*) FROM public.user_goals g       WHERE g.user_id = u.user_id)             AS metas,
       (SELECT count(*) FROM public.user_month_diagnosis_summary d WHERE d.user_id = u.user_id) AS diagnosticos
FROM public.app_user u
LEFT JOIN public.user_onboarding_state s ON s.user_id = u.user_id
WHERE u.email = 'correo@de-prueba.cl';
```

---

## 2. El reset

`current_gate = 'G0_activacion'` es la parte que importa. Con `current_gate = NULL` el login **no** manda a la bienvenida: si el perfil ya tiene nombre y alias, `routeForPendingOnboardingGate` no devuelve ruta y el usuario cae en Home.

```sql
BEGIN;

UPDATE public.user_onboarding_state s
SET onboarding_status            = 'in_progress',
    current_gate                 = 'G0_activacion',
    last_completed_gate          = NULL,
    resume_state                 = 'none',
    resume_context               = NULL,
    -- Checkpoints de cierre
    financial_profile_completed  = FALSE,
    goals_set                    = FALSE,
    import_attempted             = FALSE,
    min_doc_threshold_met        = FALSE,
    biometric_prompted           = FALSE,
    completed_at                 = NULL,
    -- Salidas del motor de diagnóstico/suficiencia
    pending_best_action          = NULL,
    sufficiency_status           = NULL,
    diagnostic_status            = NULL,
    general_traffic_light_status = NULL,
    dominant_pressure_code       = NULL,
    dominant_cta_code            = NULL,
    last_checkpoint_at           = NOW()
FROM public.app_user u
WHERE s.user_id = u.user_id
  AND u.email = 'correo@de-prueba.cl';

COMMIT;
```

Dominios que valida el `CHECK` (migración `018`), por si querés dejarlo en otra puerta: `onboarding_status` sólo acepta `not_started`, `in_progress` y `completed`; `current_gate` y `last_completed_gate` aceptan `G0_activacion` … `G6_retoma`.

**Sobre `biometric_prompted = FALSE`:** es lo que hace el endpoint, y significa que el login va a **volver a ofrecer** la biometría antes de llegar a la bienvenida. Si no querés ese paso extra, saca esa línea del `UPDATE`.

---

## 3. Borrar lo que produjo el onboarding

```sql
BEGIN;

-- 3.1 Cartolas. import_line_items se va en cascada (FK ON DELETE CASCADE).
DELETE FROM public.statement_imports
WHERE user_id = (SELECT user_id FROM public.app_user WHERE email = 'correo@de-prueba.cl');

-- 3.2 Sugerencias de clasificación: no tienen FK a las líneas, hay que borrarlas aparte.
DELETE FROM public.movement_classification_suggestions
WHERE user_id = (SELECT user_id FROM public.app_user WHERE email = 'correo@de-prueba.cl');

-- 3.3 Diagnóstico del mes.
DELETE FROM public.user_month_diagnosis_summary
WHERE user_id = (SELECT user_id FROM public.app_user WHERE email = 'correo@de-prueba.cl');

-- 3.4 Foco del mes. Las filas con goal_scope nulo son focos mensuales viejos:
--     GoalsService las trata así (`goal_scope = 'monthly_focus' OR goal_scope IS NULL`).
DELETE FROM public.user_goals
WHERE user_id = (SELECT user_id FROM public.app_user WHERE email = 'correo@de-prueba.cl')
  AND (goal_scope = 'monthly_focus' OR goal_scope IS NULL);

COMMIT;
```

Si el usuario venía de probar el módulo de deudas y también querés resetear eso, agregá `DELETE FROM public.debts WHERE user_id = …` — cascada a cronogramas y abonos — y limpiá las cuatro columnas `debt_onboarding_*` de `user_onboarding_state`. Es otro flujo (M4): el reset del onboarding de M1 no lo necesita.

---

## 4. Verificar

Volvé a correr el `SELECT` del punto 1. Tiene que quedar:

| Campo | Valor esperado |
|---|---|
| `onboarding_status` | `in_progress` |
| `current_gate` | `G0_activacion` |
| `last_completed_gate`, `resume_state` | `NULL`, `none` |
| `goals_set`, `import_attempted`, `min_doc_threshold_met`, `financial_profile_completed` | `false` |
| `completed_at` | `NULL` |
| `cartolas`, `metas`, `diagnosticos` | `0` |
| `correo_verificado` | `true` |

Si `correo_verificado` viene en `false`, el login se va a la pantalla de código y no a la bienvenida. Se arregla sin re-verificar:

```sql
UPDATE public.app_user
SET email_verified_at = COALESCE(email_verified_at, NOW())
WHERE email = 'correo@de-prueba.cl';
```

---

## 5. Lo que esta receta no puede limpiar

- **DynamoDB (dedup y tokens de Kread).** SQL no llega. Si no se purga, al re-subir la misma cartola el backend encuentra la huella marcada como `processed`, no halla el import en Postgres —porque lo borramos— y **sigue el upload normal** dejando una advertencia en el log. O sea: funciona, pero con una entrada huérfana por cada archivo. Para purgarlo de verdad: `POST /dev/reset-user`, o el purge por usuario que expone el módulo dev.
- **El archivo en S3.** Se borra solo al procesar OK o al cancelar, y en el peor caso lo barre el lifecycle de 30 días del bucket.
- **La sesión del dispositivo.** Los tokens siguen válidos y la app puede quedar en Home con estado viejo en memoria. Cerrá sesión en la app —o forzá un reinicio— después del reset.
- **Nada de identidad.** Correo, RUT, nombre, alias, contraseña, aceptaciones legales y preferencias biométricas quedan intactos: es justamente la diferencia con [`borrar-usuario.md`](borrar-usuario.md).

---

## 6. ¿Quedó algo colgando?

Esta consulta **genera** los `SELECT` de conteo para todas las tablas que tienen `user_id`. Reemplazá el UUID, corré esto, y ejecutá el resultado unido con `UNION ALL`.

```sql
SELECT format(
         'SELECT %L AS tabla, count(*) AS filas FROM public.%I WHERE user_id = %L',
         c.table_name, c.table_name, '00000000-0000-0000-0000-000000000000'
       ) AS consulta
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
WHERE c.table_schema = 'public'
  AND c.column_name  = 'user_id'
  AND t.table_type   = 'BASE TABLE'
ORDER BY c.table_name;
```

Lo que debe seguir con filas: `user_onboarding_state` (1, la del reset), `biometric_preferences`, `subscription`, aceptaciones legales y auditoría. Cualquier otra cosa con datos financieros es residuo del flujo anterior.

---

**Índice:** [`README.md`](README.md)
