# Módulo 1 — Enrolamiento y onboarding

> Fuente: `DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`


### Enrolamiento y onboarding › Login › Inicio de sesión con mail y contraseña.
> **Responsable:** Responsable
**✅ Incluye:**
Registro de usuario
Login
Recuperación contraseña
Autenticación biométrica o de huella (si dispositivo lo permite)
Onboarding informativo básico (pantallas introductorias)

**❌ No incluye:**
Autenticación multifactor avanzada (OTP SMS externo).
Integración con proveedores externos de identidad (Google, Apple, Facebook).
Validación KYC financiera.
Firma electrónica avanzada.

KYC (Conoce a tu cliente):
Es un proceso formal que utilizan bancos y entidades financieras para:
Verificar la identidad real de una persona
Validar que no esté en listas de fraude o lavado de dinero
Cumplir normativas regulatorias

**Adicionales:**
Evaluar desarrollo
Integración con proveedores externos de identidad (Google, Apple, Facebook).

**Trazabilidad:**
MR 5.4, 8.1 | VP 3.3, 6.1, P3 | BOS 6, 9

**Objetivo estratégico:**
Habilitar acceso simple y seguro al MVP sin agregar complejidad fuera de alcance.

**Resultado visible para el usuario:**
El usuario puede entrar, recuperar acceso y comenzar el setup sin fricción innecesaria.

**Definición funcional detallada:**
Incluye registro, login, recuperación por email y biometría si el dispositivo lo soporta. El objetivo es habilitar uso rápido del MVP, no resolver identidad financiera avanzada.

**UX / UI:**
Flujo corto, lenguaje claro y pasos mínimos. La seguridad debe sentirse seria, pero sin pedir validaciones ajenas al MVP.

**Criterio de aceptación MVP / QA:**
Usuario crea cuenta, inicia sesión, recupera contraseña por email y puede volver a entrar sin soporte manual.

**Guardrails de alcance:**
No agregar MFA externo, login social, KYC, OTP SMS ni validaciones regulatorias no incluidas.

**Actividades Leonardo:**
Biometria, Cambio de contraseña.
Recuperación de contraseña vía email.

**Actividades Miguel:**
Crear base de datos de categorias y endpoint

**Estimación de tiempos:**
Semana 30-03 al 02-04


---


### Autenticación Biometría
> **Responsable:** Leonardo Salas
**Trazabilidad:**
VP P3 | BOS 6

**Objetivo estratégico:**
Acortar el reingreso recurrente.

**Resultado visible para el usuario:**
Entrar rápido sin volver a digitar la clave cada vez.

**Definición funcional detallada:**
Face ID / huella nativa opcional después del primer login exitoso.

**UX / UI:**
Prompt simple post-login o en ajustes; siempre con fallback visible a contraseña.

**Criterio de aceptación MVP / QA:**
Puede activarse y desactivarse; si falla, el usuario entra con credenciales.

**Guardrails de alcance:**
No reemplaza el login base ni agrega identidad externa.


---


### Creación de cuenta de usuario
**Trazabilidad:**
VP 3.3, P3 | BOS 9 Onboarding

**Objetivo estratégico:**
Permitir alta rápida para llegar al primer valor.

**Resultado visible para el usuario:**
Crear cuenta sin pasos innecesarios y avanzar al onboarding.

**Definición funcional detallada:**
Formulario unificado: nombre, apellido, RUT (opcional), correo electrónico, contraseña, confirmación de contraseña, aceptación de términos y aceptación de política de privacidad. Siempre se envía código de verificación al correo inmediatamente tras el registro.

**UX / UI:**
1 pantalla o wizard corto; validaciones simples; no pedir datos financieros aún.

**Criterio de aceptación MVP / QA:**
Cuenta creada y sesión iniciada en un solo flujo.

**Guardrails de alcance:**
No pedir KYC, empleo, renta ni datos patrimoniales en alta inicial.


---


### Cambio de contraseña.
> **Responsable:** Leonardo Salas
**Trazabilidad:**
VP 6.1 | BOS 9 Mantenimiento

**Objetivo estratégico:**
Sostener confianza y autonomía básica de la cuenta.

**Resultado visible para el usuario:**
El usuario puede actualizar su acceso sin fricción operativa.

**Definición funcional detallada:**
Cambiar contraseña desde perfil con validación de clave actual.

**UX / UI:**
Opción visible en perfil; feedback claro de éxito/error.

**Criterio de aceptación MVP / QA:**
Cambio efectivo y próxima sesión respeta nueva clave.

**Guardrails de alcance:**
No mezclar con seguridad avanzada fuera del alcance V1.


---


### Recuperación de contraseña vía email.
> **Responsable:** Leonardo Salas
**Trazabilidad:**
VP 3.3, 6.1 | BOS 9 Mantenimiento

**Objetivo estratégico:**
Evitar abandono por pérdida de acceso.

**Resultado visible para el usuario:**
Recupera su cuenta por email y retoma el flujo.

**Definición funcional detallada:**
Envío de enlace o código vía correo para restablecer contraseña.

**UX / UI:**
Ruta “Olvidé mi contraseña” visible y breve.

**Criterio de aceptación MVP / QA:**
Restablece clave desde email y puede volver a iniciar sesión.

**Guardrails de alcance:**
No usar SMS ni validaciones externas costosas en V1.


---


### Onboarding › Onboarding básico
**Trazabilidad:**
MR 5.4, 8.1 | VP 3.3, 4.5, P3 | BOS 6, 9

**Objetivo estratégico:**
Convertir el onboarding en diagnóstico rápido y puesta en marcha del presupuesto vivo, no en un tutorial largo.

**Resultado visible para el usuario:**
En la primera sesión entiende para qué sirve la app y, si quiere saber cómo está hoy y no esperar un mes, puede cargar cartolas o últimos movimientos para obtener semáforo, primeras recomendaciones y presupuesto sugerido.

**Definición funcional detallada:**
Onboarding breve que explique deuda + pagos + presupuesto vivo. Debe ofrecer desde el inicio la carga opcional de cartolas o últimos movimientos de uno o varios meses recientes para generar diagnóstico rápido. Si el usuario la usa, la app debe proponer un presupuesto inicial por categorías predefinidas, sugerir metas por categoría según los registros y habilitar semáforo, alertas y recomendaciones desde la primera sesión. Si la omite, el flujo puede continuar, pero debe explicarse que esas señales serán más útiles al cargar movimientos o registrar actividad.

**UX / UI:**
Pantallas cortas, texto cotidiano y un CTA claro por paso. Debe existir salida simple a “Continuar” y una opción visible de “Importar cartolas o movimientos” con explicación breve del beneficio: saber hoy cómo está su salud financiera y activar semáforo, presupuesto sugerido y recomendaciones.

**Criterio de aceptación MVP / QA:**
El usuario termina onboarding, entiende por qué conviene importar movimientos, y si carga cartolas puede ver en esa misma primera sesión una lectura inicial del mes, categorías sugeridas y primeras recomendaciones sin quedar bloqueado si decide omitir el paso.

**Guardrails de alcance:**
Evitar tutorial extenso, relato de open banking disponible hoy, pedir que el usuario arme el presupuesto desde cero o prometer extracción perfecta del archivo.


---
