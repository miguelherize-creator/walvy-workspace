# Register — `/(auth)/register`

**Componente:** `expo/features/auth/ui/RegisterScreen.tsx` + `useRegisterForm`  
**Ruta:** `app/(auth)/register.tsx`  
**Tablero:** [MV-M1-03](https://github.com/KabeliDev/front-walvy/issues/20) V08–V12  
**Figma:** entrada `3470:7249` · válido `3604:3521` · inválido `3604:3621` · T&C `3604:3925` · privacidad `3361:2744`

Entra desde login (`M1-V08`). Dos endpoints: los documentos legales al abrir y el registro al enviar. El OTP lo dispara el backend en el register; esta pantalla no llama verification.

---

## Endpoints

| Método | Path | Quién | Cuándo |
|---|---|---|---|
| GET | `/legal/documents` | `useLegalDocuments` | Al montar la pantalla, y al reintentar desde el checkbox |
| POST | `/auth/register` | `AuthProvider.register` ← `useRegisterForm` | CTA crear cuenta, con el formulario válido y ambas aceptaciones |

Body del register: `{ email, documentNumber, password, acceptTerms, acceptPrivacy, acceptedTermsVersionId, acceptedPrivacyVersionId }`. El RUT del input se normaliza a `documentNumber`. Los dos `versionId` salen de `GET /legal/documents`: sin ellos no se puede registrar qué texto aceptó el usuario.

---

## Control: variante × endpoint

| # | ID variante | Endpoint | Disparador | Esperado | Estado |
|---|---|---|---|---|---|
| 1 | `M1-V08` | — | “Crea mi cuenta” en login | Abre este formulario. Sin API | Pendiente |
| 2 | `M1-V10` | — | Email/RUT/clave inválidos o vacíos | Sin POST. **CTA deshabilitado** + error inline en el campo | Pendiente |
| 3 | `M1-V11` | — | Datos OK, T&C sin aceptar | Sin POST. **CTA deshabilitado**. No hay banner | Pendiente |
| 4 | `M1-V12` | — | Datos OK, privacidad sin aceptar | Sin POST. **CTA deshabilitado**. No hay banner | Pendiente |
| 5 | `M1-V09` | `POST /auth/register` | Todo válido + ambas aceptaciones registradas | 201 + tokens. Navega a verify-code con `email`. Backend ya envió OTP | Pendiente |
| 6 | `M1-V09` | `POST /auth/register` | Correo ya registrado | 409 `code: email_taken`. Error en el campo correo: “Este correo ya está registrado” | Pendiente |
| 7 | `M1-V09` | `POST /auth/register` | RUT ya registrado | 409 `code: document_taken`. Error en el campo RUT: “Este RUT ya está registrado” | Pendiente |
| 8 | `M1-V09` v2.6 / `M01-RGL-002` | `POST /auth/register` | La versión aceptada dejó de regir | 409 `code: legal_version_stale`. Banner + desmarca ambos checks + recarga documentos | Pendiente |
| 9 | `M1-RN-ACC-008` | — | RUT | **Módulo-11**, no sólo el patrón `^\d{7,8}-[\dkK]$`. Se valida en cliente y en backend (fail-closed) | Pendiente |
| 10 | `M1-RN-ACC-009` | — | Contraseña | 8 caracteres, mayúscula y número, más el tope de 72 **bytes** UTF-8 | Pendiente |
| 11 | `M1-RN-ACC-011` | `GET /legal/documents` | Los documentos no cargan | Banner. Los checks no se pueden marcar; tocarlos reintenta la consulta | Pendiente |

`M1-RN-ACC-006` (confirmación de correo) es control de captura del cliente: se compara en pantalla y **no viaja al API**. Es correcto que no esté en `RegisterDto`.

---

## Aceptación legal — `M01-RGL-002` (ajuste v2.6)

El texto no vive en el bundle: sale de `GET /legal/documents` con su `version` y su `id`.

1. El check no se puede marcar directo: tocarlo abre el documento.
2. El botón “Acepto” dentro de la hoja nace deshabilitado y se habilita al llegar al final del texto (tolerancia 24px). Sin medir alturas no se da por leído.
3. Aceptar marca el check. Volver a tocarlo revoca la aceptación y reabrir exige recorrer de nuevo.
4. El POST manda el `id` de la versión leída. Si llega una versión nueva mientras el usuario llenaba el formulario, los checks se desmarcan solos.

---

## Errores: banner vs campo

La regla es una: **lo que pertenece a un campo se muestra bajo el campo**; el banner (`AuthMessageBox`) queda para lo que afecta al formulario entero.

| Origen | Respuesta | Dónde se muestra |
|---|---|---|
| Cliente | Correo vacío / inválido | Campo correo |
| Cliente | Correos no coinciden | Campo confirmar correo |
| Cliente | RUT vacío / patrón / módulo-11 | Campo RUT |
| Cliente | Contraseña: complejidad y tope de bytes | Panel de requisitos + campo contraseña |
| Cliente | T&C o privacidad sin aceptar | CTA deshabilitado (sin texto) |
| `POST /auth/register` | 400 RUT inválido | Campo RUT |
| `POST /auth/register` | 400 contraseña | Campo contraseña, con el mensaje del backend |
| `POST /auth/register` | 400 correo | Campo correo |
| `POST /auth/register` | 409 `email_taken` | Campo correo |
| `POST /auth/register` | 409 `document_taken` | Campo RUT |
| `POST /auth/register` | 409 `legal_version_stale` | **Banner** + recarga de documentos |
| `POST /auth/register` | 409 sin `code` reconocido | **Banner**, con el mensaje del API |
| Ambos | 503 documentos legales no disponibles | **Banner** |
| Ambos | 429 | **Banner**: “Demasiados intentos…” |
| Ambos | Red / timeout / 5xx | **Banner** |

Los tres `code` del 409 llegan en el cuerpo. Comparten status, así que sin `code` el cliente no puede saber cuál conflicto ocurrió — ver [`docs/api/auth/register.md`](../../../../../back-walvy/docs/api/auth/register.md).

Dónde está en el código: `parseRegisterConflict` y `parseRegisterValidationError` en `expo/features/auth/utils/registerConflict.ts`; el reparto a campo o banner en `useRegisterForm.ts`.

---

## Qué no va acá

OTP (V13–V16) → [`verify-code.md`](verify-code.md). Alias (V24) → [`choose-alias.md`](choose-alias.md).

**Anterior:** [`login.md`](login.md) · **Siguiente:** [`verify-code.md`](verify-code.md)
