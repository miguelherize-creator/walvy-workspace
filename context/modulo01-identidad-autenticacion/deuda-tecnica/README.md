# M01 — Deuda técnica

**Verificado contra el código el 2026-09-06**, sobre `origin/qa` (`dd713df`).

> Los IDs `M1-DT-*` nacieron en `context/debt.md`, congelado el 2026-06-11 y retirado el
> 2026-09-06. Esta tabla ya **no** los hereda a ciegas: cada uno lleva el comando con el
> que se comprobó.

| ID | Tema | Estado | Cómo se comprobó |
|---|---|---|---|
| M1-DT-01 | Backoffice: gestión de estado de usuario | ❌ **Abierto** | `src/admin/` sólo tiene `entities/`, sin controller |
| M1-DT-02 | RBAC: enforcement de permisos | ❌ **Abierto** | Cero apariciones de `RbacGuard` o `RequirePermission` en `src/` |
| M1-DT-03 | Job de nivel de salud financiera | ⚠️ **Cambió de forma** | No hay `@Cron`, y no hace falta — ver abajo |
| M1-DT-04 | Onboarding: alineación con el flujo del cliente | ✅ **Resuelto** | `user-onboarding.service.ts` cierra en `onboardingStatus === 'completed'`, con G0–G5 y sus reglas |

---

## M1-DT-01 · Backoffice

`src/admin/` existe con entidades y sin superficie. Faltan
`PATCH /admin/users/:id/status` y `DELETE /admin/users/:id` —soft delete siempre— en un
`AdminModule` protegido por rol. **Bloqueado por M1-DT-02:** no tiene sentido exponer
endpoints de administración sin enforcement de permisos.

## M1-DT-02 · RBAC

Las tablas y los seeds de roles existen; **el guard no**. Falta `RbacGuard` con un
decorador `@RequirePermission('recurso:accion')`, cacheando permisos por rol. Es el
bloqueante real de M1-DT-01.

## M1-DT-03 · El job de salud financiera ya no aplica

El item pedía un `@Cron()` que calculara `current_financial_health_level_id` a partir de
transacciones y deudas. **Ese modelo se reemplazó.** Hoy `src/health/` es el motor de
diagnóstico del mes: calcula bajo demanda, escribe `user_month_diagnosis_summary` y
publica suficiencia y CTA dominante para que M02 y M03 los lean. Las reglas están en
`src/health/rules/`, cada una con su spec.

No es deuda pendiente: es un item **superado por un diseño distinto**. Se conserva
listado para que nadie salga a buscar el cron.

## M1-DT-04 · El onboarding cierra

Estaba dado por bloqueado por M2-DT-01 —el perfil financiero—, que hoy está
implementado (`GET`/`PUT /profile/financial`). El cierre del onboarding funciona: el
servicio resuelve por estado con las puertas G0 a G5, y la condición de cuatro banderas
que tenía antes quedó reemplazada.

Referencia: [`../../bitacora/2026-08-29-plan-onboarding-dev-nuevo.md`](../../bitacora/2026-08-29-plan-onboarding-dev-nuevo.md),
que ya lo daba por resuelto.

---

## Frontend

Los items `M1-FE-*` venían del mismo registro retirado y **no se reverificaron**. Lo que
sí está medido son las auditorías pixel-perfect de
[`../../qa-audits/auth/`](../../qa-audits/auth/) — ahí está el detalle por pantalla, con
su puntaje y sus desvíos.

## Integración con Kread

[`KREAD-INTEGRATION.md`](KREAD-INTEGRATION.md).

---

## Cómo verificar este archivo

```bash
cd back-walvy
ls src/admin/                                          # M1-DT-01
grep -rn "RbacGuard\|RequirePermission" src/           # M1-DT-02 · debe dar vacío
grep -rn "@Cron" src/ --include="*.ts" | grep -v spec  # M1-DT-03 · debe dar vacío
ls src/health/rules/                                   # M1-DT-03 · el modelo que reemplazó
grep -n "completed" src/auth/services/user-onboarding.service.ts   # M1-DT-04
npx jest src/auth src/users                            # 15 suites
```
