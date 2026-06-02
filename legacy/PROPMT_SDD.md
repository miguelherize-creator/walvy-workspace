````txt
Quiero que analices completamente mi workspace actual y me ayudes a convertir este proyecto a una estructura AI-Driven / Spec-Driven Development optimizada para trabajar con Claude Code, Cursor y agentes IA.

# Objetivo

Crear automáticamente una estructura de documentación y contexto permanente para el proyecto, SIN romper el código existente.

Debes:

- analizar backend, frontend y workspace completo
- detectar arquitectura actual
- detectar stack tecnológico
- detectar convenciones existentes
- detectar módulos/features
- detectar decisiones técnicas ya tomadas
- generar documentación base inteligente
- crear estructura de carpetas y archivos
- NO modificar lógica de negocio existente
- NO mover archivos críticos del proyecto
- SOLO agregar estructura documental y de contexto IA

---

# Estructura objetivo

Crear esta estructura en la raíz del workspace:

```txt
/AGENTS.md
/CLAUDE.md
/README.md
/ARCHITECTURE.md

/constitution
    architecture.md
    conventions.md
    stack.md
    testing.md

/decisions
    001-initial-architecture.md

/specs

/.claude
/.cursor/rules
````

---

# Instrucciones importantes

## 1. AGENTS.md

Crear un archivo maestro para IA que incluya:

* descripción del proyecto
* objetivos del sistema
* arquitectura general
* stack completo detectado
* reglas de código
* convenciones
* patrones actuales
* estructura backend/frontend
* cómo deben implementarse nuevas features
* cómo manejar DTOs, services, hooks, components, entities, migrations, etc.
* reglas de naming
* reglas de imports
* principios clean architecture
* reglas de testing
* reglas de seguridad
* reglas para no romper módulos existentes

Debe ser EXTENSO y altamente útil para agentes IA.

---

## 2. CLAUDE.md

Crear como symlink a AGENTS.md.

Si el entorno no soporta symlink:
crear copia exacta.

---

## 3. ARCHITECTURE.md

Generar un mapa navegable de:

* frontend
* backend
* APIs
* auth
* módulos
* flows
* DB
* servicios externos
* storage
* providers
* navegación
* estados
* arquitectura actual

Debe ayudar a entender rápidamente el sistema.

---

## 4. constitution/

### architecture.md

Documentar:

* capas
* módulos
* separación frontend/backend
* patrones arquitectónicos
* flujo de datos
* auth flow
* manejo de estados
* estrategia API
* estructura DB

---

### conventions.md

Detectar y documentar:

* naming conventions
* estructura de carpetas
* estilos de código
* patrones reutilizados
* organización de componentes
* manejo de errores
* validaciones
* DTO patterns
* hooks patterns
* services patterns
* clean code rules

---

### stack.md

Documentar:

* frameworks
* versiones
* librerías
* runtimes
* herramientas
* ORM
* base de datos
* providers
* cloud services
* auth services
* storage services
* testing frameworks

---

### testing.md

Documentar estrategia actual y sugerir:

* unit tests
* integration tests
* e2e
* frontend testing
* backend testing
* TDD strategy
* mocks
* fixtures

---

## 5. decisions/

Crear ADR inicial:

### 001-initial-architecture.md

Documentar:

* decisiones detectadas
* por qué probablemente fueron tomadas
* ventajas
* riesgos
* mejoras futuras

Formato ADR profesional.

---

## 6. specs/

Analizar módulos/features existentes y crear estructura inicial por feature.

Ejemplo:

```txt
/specs/authentication
/specs/email-verification
/specs/user-profile
```

Cada feature debe tener:

```txt
spec.md
plan.md
tasks.md
```

Contenido inicial:

* qué hace
* estado actual
* mejoras pendientes
* deuda técnica detectada
* plan de evolución

---

## 7. Cursor y Claude

Crear configuración base:

```txt
/.cursor/rules
/.claude
```

Agregar reglas útiles para:

* mantener arquitectura
* evitar duplicación
* respetar convenciones
* evitar breaking changes
* mantener tipado
* mantener seguridad
* mantener estructura modular

---

# Restricciones críticas

NO:

* romper código
* mover módulos
* eliminar archivos
* cambiar lógica existente
* alterar configuración sensible

SÍ:

* analizar profundamente
* inferir patrones
* documentar inteligentemente
* generar contexto persistente
* mejorar mantenibilidad
* preparar proyecto para desarrollo IA escalable

---

# Resultado esperado

Quiero terminar con:

* un workspace listo para Claude Code
* contexto persistente profesional
* arquitectura documentada
* specs por feature
* ADRs
* reglas para IA
* documentación navegable
* base para desarrollo escalable

Antes de crear archivos:

1. Analiza todo el proyecto.
2. Resume hallazgos.
3. Propón estructura final.
4. Luego crea los archivos.

```
```
