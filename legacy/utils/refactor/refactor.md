### ✅ Prompt mejorado

> Actúa como un Tech Lead Frontend especializado en React Native.
>
> Tengo una aplicación React Native donde ya completé el módulo 1 y módulo 2. Necesito crear una planificación detallada de trabajo para un desarrollador frontend para la próxima semana (5 días laborales).
>
> El objetivo principal es realizar un refactor y mejora de la arquitectura del proyecto.
>
> Genera un plan estructurado por días (Día 1 a Día 5), donde cada día incluya:
>
> * Objetivo del día
> * Tareas específicas (claras y ejecutables)
> * Resultado esperado (definition of done)
>
> Áreas que quiero cubrir obligatoriamente:
>
> 1. Centralización de recursos:
>
>    * Crear una estrategia para manejar imágenes desde AWS S3 en lugar de assets locales
>    * Definir una ruta/configuración centralizada para estos recursos
> 2. Theming:
>
>    * Implementar soporte para modo light y dark
>    * Controlarlo desde una configuración global (theme provider o similar)
> 3. Arquitectura por features:
>
>    * Reorganizar el proyecto para que sea escalable (feature-based structure)
>    * Separar UI (colores, tipografía, spacing, componentes reutilizables)
> 4. Manejo de endpoints:
>
>    * Centralizar llamadas al backend
>    * Definir una capa de servicios o API client
>    * Manejo de errores y estados (loading, error, success)
> 5. Responsive design:
>
>    * Adaptar la app para Android, iOS y tablets
>    * Manejo de diferentes tamaños de pantalla
> 6. Escalabilidad en tamaños mobile:
>
>    * Definir breakpoints (small, medium, large)
>    * Ajustar tipografías, spacing y layouts
>
> Además:
>
> * Sugiere mejoras adicionales que no haya considerado
> * Propón herramientas o librerías recomendadas si aplica
> * Indica riesgos comunes en este tipo de refactor
> * Prioriza las tareas de mayor impacto primero
>
> El resultado debe ser práctico, directo y aplicable por un desarrollador sin necesidad de interpretación adicional.

---

### 🔥 Ideas extra que deberías incluir (esto es lo que te faltaba)

Te agrego cosas que realmente marcan diferencia en proyectos reales:

**1. Manejo de estado global**

* Zustand o Redux Toolkit
* Separar estado server vs UI

**2. Configuración por entorno**

* `.env` (dev, staging, prod)
* URLs de API y S3 dinámicas

**3. Tipado fuerte**

* TypeScript (si no lo usas ya)
* Tipos para API responses

**4. Sistema de diseño (Design System)**

* Botones, inputs, cards reutilizables
* Tokens (color, spacing, borderRadius)

**5. Performance**

* Memoization (`React.memo`, `useMemo`)
* Lazy loading de pantallas
* Optimización de imágenes (clave si usas S3)

**6. Navegación limpia**

* Separar stacks (auth, app, etc.)
* Tipado de rutas

**7. Testing básico**

* Al menos tests para hooks o utils
* Jest + React Native Testing Library

**8. Logging y debugging**

* Manejo centralizado de logs
* Integración futura con Sentry

---

### ⚠️ Consejo importante (esto te va a ahorrar dolores de cabeza)

No intentes hacer todo en una semana en la vida real.

Si este plan es para alguien ejecutarlo:

* Divide en **“quick wins” (1-2 días)** vs **“refactor profundo”**
* Empieza por:

  1. endpoints + api client
  2. theming
  3. estructura por features

Lo demás puede ir en iteraciones.
