# Deuda Técnica — Walvy

**Última actualización:** 2026-06-09

Formato: `ID — Descripción — Estado — Bloqueante`

---

## Módulo 1 — Auth & Onboarding

### M1-DT-01 — Backoffice: gestión de estado de usuario
- **RF:** RF-09
- **Estado:** ❌ Sin implementar — `src/admin/` existe pero vacío
- **Bloqueante:** Sí — requiere M1-DT-02 (RBAC) primero
- **Endpoints pendientes:** `PATCH /admin/users/:id/status` · `DELETE /admin/users/:id`
- **Qué falta:** AdminModule con endpoints protegidos por rol `admin`. Soft delete siempre.

### M1-DT-02 — RBAC: enforcement de permisos
- **RF:** RF-11
- **Estado:** ❌ Sin middleware de enforcement (tablas y seeds existen)
- **Bloqueante:** No — independiente, pero bloquea M1-DT-01
- **Qué falta:** `RbacGuard` + decorador `@RequirePermission('resource:action')`. Cachear permisos por rol (TTL 5min).

### M1-DT-03 — Job: nivel de salud financiera
- **RF:** RF-12
- **Estado:** ❌ Sin job/cron
- **Bloqueante:** Sí — bloqueado por Módulos 3 y 4 (cashflow y deudas deben existir primero)
- **Qué falta:** `@Cron()` en `src/health/` que calcule `current_financial_health_level_id` basado en transacciones + deudas.

### M1-DT-04 — Onboarding: alineación con flujo del cliente
- **RF:** RF-08
- **Estado:** ⚠️ Funciona parcialmente — no cierra nunca
- **Bloqueante:** Sí — bloqueado por M2-DT-01 (perfil financiero) y Módulo 3
- **Problemas concretos:**
  1. Auto-completado roto: exige `financialProfileCompleted = true` pero M2-DT-01 no está hecho → onboarding nunca termina
  2. `minDocThresholdMet` nunca se activa: no hay módulo de importación que lo escriba
  3. `currentStep` acepta strings libres sin validación `@IsIn([...])`
- **Qué falta:** Validar paso final con producto. Revisar si `financialProfileCompleted` sigue siendo condición. Añadir `@IsIn()` al DTO.

### M1-FE-01 — `user.email` vacío en savedUser mode
- **Detectado:** 2026-05-31
- **Estado:** ⚠️ Workaround aplicado, falta investigar backend
- **Síntomas:** `GET /users/me` devuelve user con `email: null` o `email: ""` aunque el usuario tenga sesión activa. Esto rompía `savedUserPassword` mode en LoginScreen (necesita email para enviar al backend al hacer login con password).
- **Workaround actual:** Persistencia local en SecureStore `LAST_USER_EMAIL_KEY` (ver [`decisions.md`](decisions.md) entrada 2026-05-31). `LoginScreen` y `useLoginForm` usan `effectiveEmail = user.email || savedEmail`.
- **Qué falta:** Debug en backend de `/users/me` para verificar por qué `email` no se devuelve. Probable causa: query/serializer omite el campo. Una vez corregido, el workaround puede mantenerse como capa de resiliencia pero el bug principal estará resuelto.
- **Archivos:** `back-walvy/src/users/users.controller.ts` o `users.service.ts` (revisar response shape de `getMe()`)

### M1-FE-02 — `user.firstName` vacío en savedUser mode
- **Detectado:** 2026-05-31
- **Estado:** ⚠️ Workaround aplicado (Patrón C fallback)
- **Síntomas:** Mismo problema que M1-FE-01 pero con `firstName`. El saludo personalizado "¡Hola Juancho!" no aparece (cae al genérico "Te damos la bienvenida").
- **Workaround actual:** Patrón C en LoginScreen — usar parte del email antes del `@` capitalizada como display name cuando `firstName` falta. Función `capitalize(email.split("@")[0])`.
- **Qué falta:** Mismo debug que M1-FE-01 — verificar que `/users/me` devuelve `firstName` completo. Lógica de cascada (Patrón C) puede mantenerse como fallback defensivo.
- **Archivos:** `features/auth/ui/LoginScreen.tsx` (función `displayName`)

### M1-FE-03 — Contrato `/auth/reset-password` no documentado en spec
- **Detectado:** 2026-05-31
- **Estado:** ⚠️ Resuelto en runtime, falta actualizar spec
- **Síntomas:** El frontend enviaba `{ token, newPassword }` pero el backend espera `{ email, code, newPassword }`. Resultaba en errores `property token should not exist`, `El correo es obligatorio`, `El código es obligatorio`, `newPassword must be a string`.
- **Causa raíz:** `context/specs/authentication.md` documenta el endpoint pero no el shape exacto del payload de `/auth/reset-password`. El frontend asumía un opaque `token` cuando en realidad el backend espera el código OTP de 6 dígitos + email para validar.
- **Resolución:**
  - Actualizado `api/types/auth.ts` → `ResetPasswordPayload = { email, code, newPassword }`
  - Actualizado `authRepository.resetPassword(email, code, newPassword)`
  - El URL param `token` (que es el code OTP) se mapea correctamente
- **Qué falta:** Actualizar `context/specs/authentication.md` para documentar el shape exacto del payload de `/auth/reset-password` y evitar que ocurra de nuevo en futuros refactors.
- **Archivos involucrados:** `api/types/auth.ts`, `features/auth/data/authRepository.ts`, `features/auth/hooks/useResetPasswordForm.ts`, `api/mocks/authMock.ts`

### M1-FE-05 — Asset HD del splash con canal alpha
- **Detectado:** 2026-06-03
- **Estado:** ✅ Resuelto 2026-06-03 — Lottie 380×380 vectorial con fondo transparente nativo
- **Síntomas originales:** El asset `Walvy_Splash_animado.webm` inicial era:
  - **150×150 px** → resolución muy baja (upscale 5.7x → pixelado)
  - **`pix_fmt=yuv420p`** → sin canal alpha → se renderizaba como cuadrado opaco negro
- **Resolución:** El Designer entregó `Walvy_Splash_animado.json` (Lottie, LottieFiles toolkit, 380×380, ~320 KB). Vectorial, alpha nativo, sin pixelado en ningún tamaño.
- **Cambios aplicados:**
  - Añadido `lottie-react-native@7.3.8` (`bun add lottie-react-native`)
  - Asset movido a `assets/images/decorative/walvy-splash-animated.json`
  - `SplashScreen.tsx` ahora usa `<LottieView autoPlay loop resizeMode="contain" />` en vez del `<Image>` con GIF / `<VideoView>` con MP4
  - Eliminadas dependencias internas de `expo-video` en el splash (el paquete sigue instalado por si se necesita en otra pantalla)
- **Archivos legacy a limpiar (opcional):**
  - `assets/images/decorative/splash.gif` (376 KB) — ya no se referencia
  - `assets/images/decorative/walvy-splash-animated.mp4` (69 KB) — ya no se referencia

### M1-FE-06 — Mascot del modal "Te ayudamos a recuperar el acceso" pendiente de reemplazo
- **Detectado:** 2026-06-03
- **Estado:** ⚠️ Asset placeholder en uso — esperando nueva versión del Designer
- **Síntomas:** El modal de soporte en `/forgot-password` ("Te ayudamos a recuperar el acceso → escríbenos a soporte@walvy.cl") usa actualmente `assets/images/mascots/walvy-recuperar-acceso.png` (castor con hoodie verde sosteniéndose la cabeza, rodeado de billetes y monedas). El Designer indicó que esta imagen debe reemplazarse, pero aún no entregó la nueva versión.
- **Workaround actual:** Se mantiene el asset existente — funciona y se renderiza correctamente, sólo está pendiente la actualización visual.
- **Qué falta:**
  1. Esperar que el Designer entregue el nuevo asset
  2. Reemplazar `assets/images/mascots/walvy-recuperar-acceso.png` (mantener el mismo nombre para evitar tocar el `require`)
  3. Validar que las dimensiones del nuevo asset funcionen con el layout existente (el actual es ~44 KB, PNG)
  4. Si el nuevo asset viene en formato distinto (WebP, SVG), actualizar la referencia en `features/auth/ui/ForgotPasswordScreen.tsx:177`
- **Archivos involucrados:** `features/auth/ui/ForgotPasswordScreen.tsx`, `assets/images/mascots/walvy-recuperar-acceso.png`

### M1-FE-04 — Touch targets bajo el mínimo recomendado (44px)
- **Detectado:** 2026-05-30 (auditorías QA pixel-perfect)
- **Estado:** ⚠️ Cumple Figma pero falla guidelines de accesibilidad
- **Síntomas:** Botones primarios usan `h-40` (Figma) y links subrayados usan `h-24`. Apple HIG y Material Design recomiendan **mínimo 44px**.
- **Pantallas afectadas:** Login, Register, VerifyCode, BiometricSetup, ChooseAlias, ResetPassword, ForgotPassword (todas las pantallas auth).
- **Workaround disponible:** `hitSlop={{ top: 12, bottom: 12, left: 8, right: 8 }}` en `Pressable` extiende el área táctil SIN modificar el aspecto visual. Ya aplicado parcialmente en algunos links.
- **Qué falta:** Aplicar `hitSlop` a TODOS los links/botones que estén por debajo de 44px. Considerar crear componente `<AuthLink>` y `<AuthButton>` que incluyan `hitSlop` por default.
- **Referencia:** Ver auditorías en `context/qa-audits/auth/` — todas mencionan este issue como Severidad Media.

---

## Módulo 2 — Perfil y Configuración

### M2-DT-01 — Perfil financiero
- **RF:** RF-02
- **Estado:** ✅ RESUELTO — `GET /profile/financial` + `PUT /profile/financial` implementados y alineados con front
- **Implementación:** `FinancialProfileController` + `FinancialProfileService`. PUT upsert parcial. `currency` (ISO string "CLP") se mapea a `currency_id` interno; la respuesta omite `currencyId` (decisión del front). `monthlyIncomeEstimate` y `estimatedPaymentCapacity` validados `> 0` (front bloquea vacío, el `0` se rechaza con 400 — confirmado con front).
- **Nota:** `estimatedPaymentCapacity` hoy es declarado por el usuario (no calculado). Si a futuro se calcula desde cashflow/deudas, será otro requerimiento.

### M2-DT-02 — Metas financieras (foco del mes)
- **RF:** RF-03
- **Estado:** ⚠️ Parcial — `GET /profile/goals` + `POST /profile/goals` ✅ implementados. Falta `PATCH /profile/goals/:id/deactivate`.
- **Decisión tomada:** **un solo foco activo** por usuario (no múltiples). `setFocus` reutiliza/sobrescribe la fila `is_active=true`.
- **Qué falta:** endpoint de desactivación (quitar foco sin reemplazar). `progress_cache` es solo-escritura del backend.

### M2-DT-03 — Alertas y notificaciones
- **RF:** RF-04
- **Estado:** ⚠️ **Endpoints SÍ existen** — en `/notifications/*`, no en `/profile/alerts`. El gap real es de **alineación de contrato** front↔back, no de implementación.
- **Bloqueante:** Sí para efecto real — sin M2-DT-04 (worker) las preferencias se guardan pero no disparan avisos.
- **Endpoints reales en backend** (`NotificationController`):
  - `GET  /notifications/preferences/sections` — catálogo de avisos + estado
  - `PATCH /notifications/preferences/toggle` — `{ alertType, enabled }`
  - `POST /notifications/preferences` — upsert `{ alertType, channel, enabled, intensity }`
  - `POST /notifications/preferences/defaults` — restablecer
  - `GET /notifications/pending` · `GET /notifications/history` · `PATCH /notifications/:id/read`
- **Qué falta:** decidir contrato final. O el front consume `/notifications/*` (recomendado, ya existe), o el back expone un alias `/profile/alerts`. NO hace falta implementar backend nuevo.

### M2-DT-04 — Worker de notificaciones
- **RF:** RF-05
- **Estado:** ❌ Sin implementar
- **Bloqueante:** Sí — requiere definir canales push (FCM/APNs pendiente de scope)
- **Qué falta:** `NotificationQueueService.enqueue()` + worker `@Cron()` que procese `WHERE sent_at IS NULL AND scheduled_for <= now()`. Decidir canales MVP: ¿solo `in_app` + `email`, o también `push`?

### M2-FE-01 — Render de SemiBold con la fuente Aptos
- **Detectado:** 2026-06-03 (auditoría `/profile` vista Datos)
- **Estado:** ⚠️ Funciona pero el peso visual puede no ser el esperado en web/algunos dispositivos
- **Síntomas:** Los inputs filled de la pantalla "Mis Datos" (Alias, Nombre, Apellido) y otros textos que usan `fontWeight: "600"` con la familia Aptos pueden renderizarse con peso normal en lugar de SemiBold. En el screenshot web los valores "jaja", "Usuario", "Demo" se ven semi-light.
- **Causa raíz:** `constants/fonts.ts` mapea `fontFamily.semiBold` a `"Aptos"` (la regular) confiando en que RN aplica un peso sintético con `fontWeight: "600"`. Esto funciona inconsistentemente: depende de si la plataforma tiene un fallback SemiBold real disponible. En web sin Aptos SemiBold registrada, el sistema decide qué hacer.
- **Workaround disponible:** Usar `fontFamily.bold` (Aptos-Bold) en lugar de Regular+weight para los textos que deben verse claramente SemiBold. Visualmente el Bold sería ligeramente más pesado que el SemiBold de Figma pero más consistente que el render actual.
- **Qué falta:**
  1. Validar en dispositivo nativo Android e iOS (no web) si los pesos 600 se ven correctamente — si sí, no hay nada que arreglar para producción real
  2. Si en device también se ve light: registrar una variante `Aptos-SemiBold.ttf` explícita en `app.json` plugins/fonts y actualizar `fontFamily.semiBold` a apuntar a esa familia
  3. Considerar si vale la pena pedir al Designer/font supplier el archivo .ttf de Aptos SemiBold (puede no estar disponible — la familia Aptos de Microsoft viene en sets limitados)
- **Archivos involucrados:** `constants/fonts.ts`, `components/AppInput.tsx` (línea con `inputFigmaFilled`), todos los lugares con `fontWeight: "600"` + `fontFamily: "Aptos"`

### M2-FE-02 — Touch targets bajo 44px en pantalla Mi perfil/Mis Datos
- **Detectado:** 2026-06-03 (auditoría `/profile`)
- **Estado:** ⚠️ Funcional pero falla guidelines de accesibilidad
- **Síntomas:** Mismo problema que M1-FE-04 pero en otra pantalla. Elementos bajo el mínimo recomendado por Apple HIG / Material Design (44px):
  - Botón "Editar foto" en avatar — `slot 40×40 + hitSlop 4` → toque efectivo 48px (justo en el límite)
  - Toggle de Modo oscuro y de seguridad — `track 40×24 + hitSlop 6` → toque efectivo 36×52 vertical (vertical OK, horizontal bajo)
  - Chevron de back ("< Mis datos") — `size 28 + hitSlop 8` → toque efectivo 44px (justo en el límite)
- **Workaround disponible:** Aumentar `hitSlop` a `{top: 12, bottom: 12, left: 12, right: 12}` en cada Pressable afectado.
- **Qué falta:** Aplicar hitSlop ampliado a los 3 elementos identificados. Considerar un wrapper `<TouchTarget>` que garantice 44px mínimo en toda la app.
- **Archivos involucrados:** `features/profile/ui/ProfileScreen.tsx` (avatar Pressable, back chevron Pressable), `DarkModeToggle` interno del mismo file

### M2-FE-05 — Alineación de reglas de password backend vs UI
- **Detectado:** 2026-06-07 (auditoría /change-password)
- **Estado:** ✅ Resuelto 2026-06-07 — backend YA valida las mismas 3 reglas (8 chars + mayúscula + número). Confirmado en `back-walvy/docs/api/auth/register.md:28` y `password-reset.md:62`.
- **Resolución:** Las 3 capas (PasswordHints UI, hook local, mock) y el backend ahora hablan el mismo idioma:
  > "Mínimo 8 caracteres, una mayúscula y un número"
- **Cleanup pendiente (opcional):** En `utils/validation.ts` queda exportada `isStrongPassword` (regex de 5 reglas) que ya no se debería usar. Buscar y reemplazar los callsites por `isPasswordSecure` del `PasswordHints` para deprecar la 5-rule regex. No es bloqueante porque ninguna pantalla activa la usa ahora (verificado 2026-06-07).
- **Archivos involucrados:**
  - Frontend: `features/auth/ui/PasswordHints.tsx` (PASSWORD_REQS array), `features/auth/hooks/useChangePasswordForm.ts`, `api/mocks/mockHelpers.ts`
  - Backend doc: `docs/api/auth/register.md`, `docs/api/auth/password-reset.md` (ambos especifican 3 reglas)
  - Histórico: `utils/validation.ts` aún exporta `isStrongPassword` para deprecación posterior

### M2-FE-04 — Re-crop con offset del pan en ProfilePhotoModal
- **Detectado:** 2026-06-03 (auditoría modal "Mi foto de perfil" cargada)
- **Estado:** ⚠️ Pan visual implementado, persistencia del offset al guardar pendiente
- **Síntomas:** Tras el fix donde se conectó `PanResponder` al preview del modal, el usuario PUEDE arrastrar visualmente la foto cargada dentro del círculo de recorte. Sin embargo, al presionar "Guardar" se persiste el URI tal cual lo devolvió el `ImagePicker.launchImageLibraryAsync` nativo — **el offset visual del pan se descarta**.
- **Causa:** El cropper nativo de iOS/Android (`allowsEditing: true, aspect: [1,1]`) recorta la foto a un cuadrado antes de que la veamos en el modal. Para preservar el reposicionamiento que el usuario hace en el modal, hay que recortar la imagen DE NUEVO usando coordinadas relativas al `panOffset`.
- **Workaround actual:** El usuario puede arrastrar visualmente pero el avatar final usa el centro del crop nativo. En la práctica esto funciona OK porque el cropper nativo ya permite centrar bien la foto antes del modal — el pan del modal es un refinamiento opcional.
- **Qué falta:**
  1. Añadir `expo-image-manipulator` como dependencia (`bun add expo-image-manipulator`)
  2. En `handleSave` de `ProfilePhotoModal`, antes de `onSave(pickedUri)`:
     - Calcular las coordenadas del crop usando `panOffset.x / panOffset.y`, `previewWidth/previewHeight` y las dimensiones reales de la imagen
     - Llamar `ImageManipulator.manipulateAsync(pickedUri, [{ crop: { originX, originY, width, height } }])`
     - Pasar el URI resultante a `onSave`
  3. Considerar también añadir pinch-to-zoom (`react-native-gesture-handler` ya está instalada, pero requiere `react-native-reanimated` para gestos compuestos elegantes — Reanimated NO está instalada)
- **Archivos involucrados:** `features/profile/ui/ProfilePhotoModal.tsx` (función `handleSave`)

### M2-FE-06 — NotificationSettingsScreen: preferencias de avisos sin persistencia
- **Detectado:** 2026-06-09 (revisión conexión Módulo 2 frontend-backend)
- **Estado:** ⚠️ UI-only — **el backend SÍ existe** (`/notifications/*`, ver M2-DT-03), pero el front no lo consume. Falta diseño aprobado + alinear contrato.
- **RF asociado:** RF-04 (ver M2-DT-03 para la deuda backend correspondiente)
- **Corrección 2026-06-10:** el supuesto "sin backend" era incorrecto. El backend expone preferencias en `/notifications/preferences/*`. No hay que implementar backend — hay que alinear ruta/shape y conectar el front.
- **Descripción:** La pantalla `NotificationSettingsScreen` existe y renderiza 4 toggles:
  - `paymentDueReminders` — Recordatorio de vencimiento de pago
  - `budgetThresholdAlerts` — Alerta cuando se supera el umbral de presupuesto
  - `weeklyImportReminder` — Recordatorio semanal de importar movimientos
  - `dailyAiRecommendations` — Recomendaciones diarias del asistente IA
- **Problema:** Los 4 toggles son `useState` local. Las preferencias se pierden al cerrar la app — no se persisten en SecureStore ni en backend.
- **Bloqueantes del lado frontend:**
  1. ~~Backend debe implementar `/profile/alerts`~~ → **Ya existe** en `/notifications/preferences/*`. Solo falta que el front consuma esa ruta (o acordar un alias).
  2. El equipo de Diseño debe revisar y aprobar la pantalla (actualmente es una propuesta — sin Figma definitivo)
  3. El Arquitecto debe confirmar el contrato del payload (campos exactos, tipos, naming)
- **Qué hacer una vez desbloqueado:**
  1. Crear `notificationRepository.ts` con `getAlerts()` y `updateAlerts(payload)`
  2. Crear `useNotificationSettings` hook con `useQuery` + `useMutation` (patrón idéntico a `useFinancialProfile`)
  3. Reemplazar los 4 `useState` por el estado del query
  4. Añadir `ActivityIndicator` de carga y manejo de error
- **Archivos involucrados:** `features/profile/ui/NotificationSettingsScreen.tsx`
- **Prioridad:** Baja — no bloqueante para MVP. No trabajar hasta que diseño apruebe la pantalla y backend confirme M2-DT-03.

### M2-FE-03 — Color exacto del avatar bg en pantalla Mis Datos
- **Detectado:** 2026-06-03 (auditoría `/profile` vista Datos)
- **Estado:** ⚠️ Diferencia sub-perceptual
- **Síntomas:** Implementación usa `#F8F3EC` (cream cálido). El Figma 3395:4528 no expone un token explícito para el bg del avatar — el color exacto se infiere del render. Puede haber 2-4 puntos de diferencia en alguno de los canales RGB.
- **Workaround:** Ninguno — el color actual queda dentro del rango "cream cálido" del design system.
- **Qué falta:** Si el Designer quiere afinar a un color exacto, debe especificarlo como token. Si no, mantener `#F8F3EC` y mover a `theme.tokens.avatarBg` para centralizar.
- **Archivos involucrados:** `features/profile/ui/ProfileScreen.tsx` (estilo inline del avatar `backgroundColor: "#F8F3EC"`)

---

## Módulo 10 — Monetización / Suscripciones

### M10-DT-01 — schema.sql desalineado con la entidad real
- **Estado:** ⚠️ Divergencia conocida — funciona, pero confunde
- **Bloqueante:** No
- **Síntomas:** `DB/schema.sql` define la tabla de referencia `subscription` (singular) con `starts_at` / `ends_at` y campos B2B/gift. La tabla **real en producción** es `subscriptions` (plural), generada por la entidad TypeORM con `DB_SYNC=true`, con columnas `current_period_start` / `current_period_end` / `cancelled_at`. Las dos no coinciden.
- **Qué falta:** Decidir fuente de verdad. Cuando se trabaje M10 a fondo: o se documenta la tabla productiva `subscriptions` en `schema.sql`, o se migra la entidad al diseño de referencia. Por ahora la entidad manda.
- **Archivos:** `back-walvy/DB/schema.sql` (línea ~1055) · `back-walvy/src/subscriptions/entities/subscription.entity.ts`

### M10-DT-02 — Guard de acceso premium no implementado
- **Estado:** ❌ Sin implementar
- **Bloqueante:** No
- **Qué falta:** No existe enforcement que corte el acceso premium al vencer la suscripción. Regla a aplicar: acceso válido mientras `now() < currentPeriodEnd` (borde exclusivo). Relevante tras `cancelSubscription`, que marca `cancelled` pero mantiene acceso hasta fin de período.
- **Archivos:** `back-walvy/src/subscriptions/`

---

## Cadena de bloqueos

```
M1-DT-02 (RBAC)
    └── bloquea M1-DT-01 (admin endpoints)

M2-DT-01 (perfil financiero)
    └── desbloquea M1-DT-04 (onboarding cierra)

Módulo 3 (cashflow) + Módulo 4 (deudas)
    └── desbloquean M1-DT-03 (job salud financiera)

M2-DT-04 (worker notificaciones)
    └── desbloquea M2-DT-03 (alertas con efecto real)
    └── desbloquea Sprint 7 (pagos recurrentes + push)
```

---

## Leyenda

| Símbolo | Significado |
|---------|-------------|
| ❌ | No implementado |
| ⚠️ | Implementado parcialmente |
| ✅ | Cerrado |
| Bloqueante: Sí | Hay otro módulo que depende de este |
