# Cruce del inventario de Walvy contra el esquema real

**Fecha:** 2026-08-20
**Fuentes:** `Walvy_Clasificacion_y_Requisitos_Proteccion_Datos_para_Implementacion_v1_0.xlsx`
(233 IDs, hoja `01_CLASIFICACION`) contra `back-walvy` `origin/main` `04a9cdd`.
**Método:** 51 tablas con clave foránea a `app_user`, 701 columnas con `COMMENT ON COLUMN`,
cruzadas por concepto contra los 233 IDs. Derivado del esquema, no leído a mano.

El tercer documento del paquete **no tiene columnas de respuesta**: sus 28 columnas están
completas por Walvy y es material de referencia. Así que el trabajo útil sobre él no es
llenarlo, es preguntarle algo que nadie le había preguntado: **¿hay dato personal en nuestro
esquema que el inventario no clasifica?** Bajo la Ley 21.719 no se puede aplicar un perfil de
protección a un dato que nunca se clasificó.

## A · Vivo y sin clasificar

**La foto de perfil.** Existe `POST /users/me/avatar`, que reescala la imagen a 400×400 WebP,
la sube a S3 y actualiza `app_user.avatar_url`. Es una imagen de una persona, procesada y
almacenada hoy, y **ningún ID de los 233 la cubre**: la búsqueda por avatar, foto e imagen
devuelve cero.

Sin ID no tiene perfil de protección asignado, y por lo tanto no tiene regla definida de
acceso, de logging, de lifecycle ni de supresión.

Vale notar cómo se resolvió de hecho: la supresión de cuenta **sí** elimina el avatar, porque al
implementarla se recogió `avatar_url` junto con los originales de cartola. O sea que el
tratamiento correcto ocurrió por criterio de ingeniería y no porque una clasificación lo
exigiera — que es exactamente el riesgo de un dato sin clasificar: salió bien por atención, y
nada garantiza que el próximo caso corra con la misma suerte.

## B · Declarado en el esquema, sin clasificar, hoy sin uso

Estas tablas existen en las migraciones y están vinculadas a `app_user`, pero ningún ID las
cubre. No hay servicio que las escriba, así que no hay tratamiento activo — pero el esquema
declara una superficie de tratamiento que el inventario no contempla, y eso conviene resolverlo
antes de que alguien la cablee.

| Superficie | Qué guardaría | IDs en el inventario |
|---|---|---|
| `company_eligible_employee` | **Correo y número de documento** de empleados, creados desde el backoffice | 0 |
| `gamification_events`, `user_gamification_stats`, `user_score_history` | Eventos, puntaje e historial de comportamiento del usuario | 0 |
| `payment_method` | `card_brand`, `card_last4`, mes y año de expiración de la tarjeta con que se paga Walvy | 0 |
| `report_snapshots` | Snapshots de reportes por usuario | 0 |
| `cashflow_node` | Nodos de flujo | 0 |

Dos merecen atención especial.

**`company_eligible_employee` guarda datos de identidad** —correo y documento— de personas que
todavía no son usuarias. El inventario cubre M01, M02, M04, M05 y M06; el alcance B2B no
aparece en ninguno. Es el hueco de mayor superficie legal de la lista.

**`payment_method` no es lo mismo que «Instrumentos detectados».** El inventario tiene siete IDs
sobre tarjetas e instrumentos, pero todos refieren a instrumentos **detectados en documentos**
del usuario (`M01-DAT-032`, `M02-DAT-005`, los `M04-TC-*`). El medio de pago con que el usuario
paga la suscripción a Walvy es otra cosa y no está clasificado. `PP-10` sí contempla que la
forma enmascarada de una tarjeta pueda ser Confidencial, así que el criterio existe: lo que
falta es el ID.

## C · Ceros que NO son huecos

Conviene decirlo porque un cero mecánico invita a reportar de más.

**M07 · asistente y conversación: 0 IDs, y está bien.** La hoja `00_LEER_PRIMERO` declara que
los 233 IDs son de M01, M02, M04, M05 y M06. M07 queda fuera del inventario por diseño y se
gobierna por los transversales `TR-STT-01` y `TR-M07-02`. No es un hueco de clasificación.

## Qué hacer con esto

Ninguno de los huecos es un incumplimiento nuestro: la clasificación es responsabilidad de
Walvy · Producto/Privacidad, tal como fija la hoja `05_RESPONSABILIDADES`. Lo que corresponde a
Kabeli es exactamente esto: señalar el dato que procesa y que no encuentra clasificado, en vez
de asignarle un nivel por cuenta propia — el propio documento advierte que Kabeli «no debe
asumir una base jurídica ni cambiar la clasificación para acomodar una limitación técnica».

Orden sugerido para plantearlo:

1. **La foto de perfil**, porque está viva. Necesita ID, categoría, condición legal, nivel y
   perfil. Nuestra recomendación técnica: es dato personal ordinario, y `PP-01` alcanza — pero
   la decisión es de Walvy.
2. **El alcance B2B**, porque guarda datos de identidad de terceros y hoy no está contemplado
   en ningún módulo del inventario.
3. **El medio de pago de la suscripción**, distinguiéndolo de los instrumentos detectados en
   documentos.
4. **Gamificación, reportes y nodos de flujo**, que pueden esperar mientras sigan sin uso, pero
   deberían clasificarse antes de cablearse.
