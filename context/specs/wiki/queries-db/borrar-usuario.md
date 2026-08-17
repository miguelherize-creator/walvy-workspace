# Borrar un usuario

Para re-probar registro, OTP o Mailpit con el **mismo correo**. El unique `uq_app_user_email` no es parcial: un soft delete (`deleted_at`) **no** libera el email.

**Tabla:** `public.app_user`  
**Cuándo:** ambiente local / RDS dev de prueba  
**No usar:** producción. Tampoco `TRUNCATE app_user CASCADE` (vacía catálogos y documentos legales).

---

## 1. Listar

```sql
SELECT user_id, email, username, email_verified_at, created_at, deleted_at
FROM public.app_user
ORDER BY created_at DESC;
```

---

## 2. Borrar uno por correo

Sustituye el email. Las tablas con `ON DELETE CASCADE` (tokens, onboarding, cartolas, movimientos, etc.) se van solas. Las de `ON DELETE SET NULL` (auditoría, aceptaciones legales) quedan, sin `user_id`.

```sql
DELETE FROM public.app_user
WHERE email = 'el-correo@que-quieres-borrar.com';
```

Comprueba:

```sql
SELECT user_id, email
FROM public.app_user
WHERE email = 'el-correo@que-quieres-borrar.com';
```

Cero filas = listo para registrar de nuevo.

---

## 3. Si Postgres se niega (FK sin cascade)

El caso más frecuente al registrar es `subscription`: tiene una FK extra **sin** `ON DELETE CASCADE`. Borra primero la suscripción y después el usuario.

```sql
DELETE FROM public.subscription
WHERE user_id = (
  SELECT user_id FROM public.app_user
  WHERE email = 'el-correo@que-quieres-borrar.com'
);

DELETE FROM public.app_user
WHERE email = 'el-correo@que-quieres-borrar.com';
```

Si sigue fallando, el error nombra la tabla. O lista las FK que **no** hacen cascade / set null:

```sql
SELECT conrelid::regclass AS tabla,
       conname,
       pg_get_constraintdef(oid) AS definicion
FROM pg_constraint
WHERE confrelid = 'public.app_user'::regclass
  AND contype = 'f'
  AND pg_get_constraintdef(oid) NOT LIKE '%ON DELETE CASCADE%'
  AND pg_get_constraintdef(oid) NOT LIKE '%ON DELETE SET NULL%'
ORDER BY tabla::text;
```

Borra (o nulifica) esas filas del `user_id` y reintenta el `DELETE` de `app_user`.

---

## Qué no va acá

Reset de onboarding **sin** borrar la cuenta → `POST /dev/reset-user` (requiere `DEV_TOOLS_ENABLED=true`). Eso no libera el correo.

**Índice:** [`README.md`](README.md)
