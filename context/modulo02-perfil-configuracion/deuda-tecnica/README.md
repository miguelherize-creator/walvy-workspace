# M02 — Deuda técnica

**Verificado contra el código el 2026-09-06**, sobre `origin/qa` (`dd713df`).

> Los IDs `M2-DT-*` nacieron en `context/debt.md`, congelado el 2026-06-11 y retirado el
> 2026-09-06. Cada fila lleva ahora el comando con el que se comprobó.

| ID | Tema | Estado | Cómo se comprobó |
|---|---|---|---|
| M2-DT-01 | Perfil financiero | ✅ **Resuelto** | `GET`/`PUT /profile/financial` en `financial-profile.controller.ts` |
| M2-DT-02 | Metas financieras · Foco del Mes | ⚠️ **Parcial** | `goals.controller.ts` tiene `GET` y `POST`; falta `PATCH /profile/goals/:id/deactivate` |
| M2-DT-03 | Alertas y notificaciones | ✅ **Resuelto en otro módulo** | No existe `/profile/alerts`; está como `notifications`, 7 endpoints + `alert-rules.engine.ts` |
| M2-DT-04 | Worker de notificaciones · FCM/APNs | ❌ **Abierto** | Ninguna dependencia de push en `package.json` |

---

## M2-DT-01 · Resuelto, y desbloqueó M01

`GET /profile/financial` y `PUT /profile/financial` (upsert) están implementados. Importa
más allá de M02: **este item bloqueaba `M1-DT-04`**, el cierre del onboarding, que
también quedó resuelto.

## M2-DT-02 · Falta desactivar una meta

`GET /profile/goals` y `POST /profile/goals` existen. Falta el
`PATCH /profile/goals/:id/deactivate` que la spec declara. No es bloqueante: se puede
crear y listar metas, no retirarlas.

## M2-DT-03 · Se implementó, pero no donde la spec lo buscaba

La spec pedía `GET /profile/alerts` y `PUT /profile/alerts`. **Esos endpoints no existen
y no van a existir con esa forma.** Las alertas viven en el módulo `notifications`:

```
GET   /notifications/preferences/sections
PATCH /notifications/preferences/toggle
POST  /notifications/preferences
POST  /notifications/preferences/defaults
GET   /notifications/pending
GET   /notifications/history
PATCH /notifications/:id/read
```

Y el motor de reglas es `src/notifications/services/alert-rules.engine.ts`.

Quien busque «las alertas de M02» por `profile/alerts` no las encuentra. Queda anotado
acá por eso — y `../../specs/user-profile.md` sigue listando los dos endpoints viejos
como pendientes, que es un desvío a corregir en esa spec.

## M2-DT-04 · No hay transporte de push

Las preferencias y el historial in-app funcionan. **Lo que no existe es el envío**: cero
dependencias de FCM, APNs, Expo Push u OneSignal en `package.json`. Una notificación
configurada hoy no sale del teléfono.

Requerimiento funcional: [`../contexto/req-push-notifications.md`](../contexto/req-push-notifications.md).

---

## Frontend

Los items `M2-FE-*` venían del registro retirado y **no se reverificaron**. Lo medido son
las auditorías de [`../../qa-audits/profile/`](../../qa-audits/profile/).

---

## Cómo verificar este archivo

```bash
cd back-walvy
grep -rn "@Get\|@Put\|@Post\|@Patch" src/profile/controllers/          # M2-DT-01 y 02
grep -rn "@Controller\|@Get\|@Patch\|@Post" src/notifications/controllers/  # M2-DT-03
grep -iE "firebase|fcm|apn|onesignal|expo-server" package.json         # M2-DT-04 · vacío
npx jest src/profile                                                    # 2 suites
```
