# M1 — Identidad, Autenticación y Acceso

**Layers:** 0 (Catálogos ISO) · 1 (Status centralizado) · 2 (RBAC) · 3 (Config) · 4 (Auth)  
**Estado:** ✅ Producción  
**Docs completos:** `Backend/MVP-CheckApp/DB/modulo1/`

---

## Dependencias

```
country ──── currency ──── document_type
     └──────────────────────────────────► app_user
status_domain ──► status ───────────────►     │──► refresh_tokens
role ──► permission ──► role_permission ──►   │──► password_reset_tokens
financial_health_level ─────────────────►     │──► email_verification_tokens
app_config                                    │──► biometric_preferences
                                              └──► user_onboarding_state
```

---

## Tablas clave

### Catálogos ISO (Layer 0)
| Tabla | PK | Notas |
|-------|----|-------|
| `country` | BIGSERIAL | ISO-3166. Seeds: CL, CO, AR, PE, MX |
| `currency` | BIGSERIAL | ISO-4217. `minor_units`: CLP=0, USD=2. Seeds: CLP, COP, ARS, PEN, MXN, USD |
| `country_currency` | (country_id, currency_id) | `is_primary` UNIQUE per country |
| `document_type` | BIGSERIAL | RUT/DNI/PASSPORT por país. `subject_scope`: person/company/both |

### Status centralizado (Layer 1)
| Tabla | Notas |
|-------|-------|
| `status_domain` | Dominios: `user`, `debt`, `subscription`, `user_payment`, `movement`, `review_queue`, `message_event`, `file_upload`, `payment_method` |
| `status` | UNIQUE `(domain_id, code)`. `enforce_status_domain()` valida FKs en triggers |

### RBAC (Layer 2)
| Tabla | Notas |
|-------|-------|
| `role` | Seeds: `admin`, `support`, `user` |
| `permission` | `code` ej: `movements.read`. `path_pattern`, `http_methods` |
| `role_permission` | pivot. admin=todo, support=solo lectura, user=sus recursos |

### Config (Layer 3)
| Tabla | Notas |
|-------|-------|
| `financial_health_level` | 3 niveles: `overwhelmed`, `transitioning`, `in_control` |
| `app_config` | JSONB key-value. `trial_days_default=14`, `feature_ai_enabled=true`, `max_login_attempts=5` |

### app_user (Layer 4)
```
user_id          UUID PK
email            VARCHAR(320) UNIQUE NULL
password_hash    TEXT NULL
username         VARCHAR(80) UNIQUE NULL   ← handle opcional
full_name        VARCHAR(200) NULL
country_id       BIGINT FK → country
default_currency_id BIGINT FK → currency
role_id          BIGINT FK → role
user_status_id   BIGINT FK → status (domain: user)
trial_started_at / trial_ends_at  TIMESTAMPTZ NULL (ambos NULL o ambos NOT NULL)
current_financial_health_level_id BIGINT NULL FK
email_verified_at / accepted_terms_at / accepted_privacy_at  TIMESTAMPTZ NULL
deleted_at       TIMESTAMPTZ NULL          ← soft delete
```

### Tokens y sesión
| Tabla | Campo clave | Notas |
|-------|-------------|-------|
| `refresh_tokens` | `token_hash TEXT UNIQUE` | SHA-256. `revoked_at` al rotar |
| `password_reset_tokens` | `token_hash TEXT UNIQUE` | `used_at` al consumir |
| `email_verification_tokens` | `token_hash UNIQUE`, `attempts SMALLINT` | Expira 15min. 5 intentos max |
| `biometric_preferences` | PK=`user_id` (1:1) | `method`: face_id/touch_id/fingerprint, `device_id` |
| `user_onboarding_state` | PK=`user_id` | `current_step`, flags: `financial_profile_completed`, `goals_set`, `min_doc_threshold_met` |

---

## Funciones globales (definidas en este módulo, usadas en todo el schema)

```sql
-- Auto-actualiza updated_at en cada UPDATE
set_updated_at() → usado por todos los triggers trg_*_updated_at

-- Valida que status_id pertenezca al dominio correcto (SQLSTATE 23514 si falla)
enforce_status_domain(expected_domain_code text, p_status_id bigint)
```

---

## Relaciones salientes
Todos los módulos referencian `app_user.user_id`, `country`, `currency`, `status`.
