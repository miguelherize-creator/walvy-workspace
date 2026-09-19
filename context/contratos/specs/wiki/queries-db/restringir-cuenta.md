# Restringir una cuenta (QA · M1-BC-005)

Deja la cuenta viva —mismo correo, misma clave— y le corta el acceso. El login con credenciales correctas responde **403** (`Tu cuenta no está disponible. Contacta soporte.`) y la app abre el modal Acceso restringido.

No hay un código `restricted` en `status`. El backend lo proyecta así:

| `status.code` (catálogo) | `accountStatus` (API / QA) | Login |
|---|---|---|
| `active` | `active` | 200 |
| `pending_verification` | `pending_verification` | 200 + `nextStep: email_verification` |
| `suspended` | `suspended` | 403 (ventana de recuperación, TR-RET-01) |
| `inactive`, `deleted`, u otro | **`restricted`** | 403 |

Para QA de acceso restringido usar **`inactive`**, no `deleted` ni `suspended`.

**Tabla:** `public.app_user` (+ `refresh_tokens` si hay que cerrar sesión)  
**Cuándo:** ambiente local / RDS dev de prueba  
**No usar:** producción

---

## 1. Ver el status (pgAdmin)

Sustituye el email. La columna `account_status` es la que importa: `active`, `pending_verification`, `suspended` o `restricted`.

```sql
SELECT
  u.user_id,
  u.email,
  s.code AS catalog_status,
  s.name AS catalog_name,
  CASE
    WHEN s.code = 'active' THEN 'active'
    WHEN s.code = 'pending_verification' THEN 'pending_verification'
    WHEN s.code = 'suspended' THEN 'suspended'
    ELSE 'restricted'
  END AS account_status,
  u.email_verified_at IS NOT NULL AS email_verified,
  u.deleted_at,
  u.updated_at,
  (SELECT count(*) FROM public.refresh_tokens rt
    WHERE rt.user_id = u.user_id AND rt.revoked_at IS NULL) AS refresh_vivos
FROM public.app_user u
JOIN public.status s ON s.status_id = u.user_status_id
WHERE lower(u.email) = lower('u37206812+1787412880290@gmail.com');
```

---

## 2. Bloquear → restricted

```sql
BEGIN;

UPDATE public.app_user u
SET user_status_id = (
      SELECT s.status_id
      FROM public.status s
      JOIN public.status_domain sd USING (status_domain_id)
      WHERE sd.code = 'user'
        AND s.code = 'inactive'
    )
WHERE lower(u.email) = lower('u37206812+1787412880290@gmail.com')
RETURNING u.user_id, u.email, u.user_status_id, u.updated_at;

UPDATE public.refresh_tokens rt
SET revoked_at = now()
WHERE rt.revoked_at IS NULL
  AND rt.user_id = (
    SELECT user_id FROM public.app_user
    WHERE lower(email) = lower('u37206812+1787412880290@gmail.com')
  );

COMMIT;
```

Volvé a correr el `SELECT` del punto 1. Tiene que quedar:

| Campo | Valor esperado |
|---|---|
| `catalog_status` | `inactive` |
| `account_status` | `restricted` |
| `refresh_vivos` | `0` |

---

## 3. Reactivar → active

```sql
UPDATE public.app_user u
SET user_status_id = (
      SELECT s.status_id
      FROM public.status s
      JOIN public.status_domain sd USING (status_domain_id)
      WHERE sd.code = 'user'
        AND s.code = 'active'
    )
WHERE lower(u.email) = lower('u37206812+1787412880290@gmail.com');
```

El `SELECT` del punto 1 tiene que decir `account_status = active`. La app necesita iniciar sesión de nuevo: los refresh ya estaban revocados.

---

**Índice:** [`README.md`](README.md)
