# Módulo 9 — Administración

> Fuente: `DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv`


### Administración › Perfil adm › Configuración de gamificaciones y recomendaciones basicas
**✅ Incluye:**
Perfil administrador.
Reportes básicos desde la BD (x definir con cliente)
Graficos basicos con información (x definir con cliente)
Visualización de métricas generales de usuarios.

**❌ No incluye:**
No hay analitica, IA y machine learning
Dashboard BI avanzado.
Exportación masiva automatizada.

**Trazabilidad:**
MR 8.2, 9 | VP 4.5, 6.1 | BOS 10 Adopción

**Objetivo estratégico:**
Dar gobernanza básica al MVP y soporte a la operación interna del proyecto.

**Resultado visible para el usuario:**
El equipo interno puede ajustar parámetros permitidos y revisar métricas generales del uso del MVP.

**Definición funcional detallada:**
Backoffice mínimo para administración operativa: gestión básica de parámetros de gamificación/recomendaciones y visualización de métricas generales acordadas. Debe servir a operación interna del MVP, no a analítica avanzada.

**UX / UI:**
Interfaz sobria, separada del producto de usuario final y con privilegios bien delimitados.

**Criterio de aceptación MVP / QA:**
Un administrador autenticado puede entrar al backoffice, revisar métricas generales y cambiar solo los parámetros permitidos.

**Guardrails de alcance:**
No convertirlo en dashboard ejecutivo completo, portal para sponsor ni centro de BI avanzado.


---


### Crear perfil administrador
**Trazabilidad:**
VP 6.1 | BOS 10 Adopción

**Objetivo estratégico:**
Asegurar gobernanza básica del entorno admin.

**Resultado visible para el usuario:**
Existe acceso diferenciado para operación interna.

**Definición funcional detallada:**
Creación y gestión de usuario administrador.

**UX / UI:**
Pantalla separada y protegida; permisos mínimos.

**Criterio de aceptación MVP / QA:**
Admin puede iniciar sesión en entorno correspondiente con permisos limitados.

**Guardrails de alcance:**
No mezclar cuentas admin con usuario final ni escalar permisos sin diseño.


---


### Reportes
**Trazabilidad:**
MR 8.2, 9 | VP 6.2 | BOS 11 Modelo

**Objetivo estratégico:**
Medir activación, uso y operación del MVP para tomar decisiones de producto y piloto.

**Resultado visible para el usuario:**
El equipo interno ve reportes básicos confiables sobre uso y comportamiento general.

**Definición funcional detallada:**
Reportes simples construidos desde la base de datos con indicadores mínimos acordados con cliente, por ejemplo activación, uso básico y métricas generales del MVP. Su función es seguimiento operativo, no analítica corporativa compleja.

**UX / UI:**
Visualizaciones simples y legibles, con foco en responder preguntas del MVP y del piloto.

**Criterio de aceptación MVP / QA:**
Los reportes muestran datos básicos consistentes y útiles para seguimiento de operación o validación.

**Guardrails de alcance:**
No convertirlo en data warehouse, analítica predictiva ni tablero ejecutivo de alta complejidad.


---
