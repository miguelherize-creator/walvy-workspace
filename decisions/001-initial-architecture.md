# ADR-001 — Feature-First + Module-per-feature Architecture

| Campo | Valor |
|-------|-------|
| **Número** | ADR-001 |
| **Título** | Feature-First + Module-per-feature Architecture |
| **Estado** | Accepted |
| **Fecha** | 2026-05-14 |
| **Autores** | Equipo Walvy |
| **Revisores** | — |

---

## Contexto

Al iniciar el desarrollo de Walvy se debía elegir una arquitectura que cumpliera las siguientes condiciones:

- **MVP con equipo pequeño**: entre 1 y 3 desarrolladores trabajando simultáneamente. La fricción entre feature branches debe ser mínima.
- **Multi-plataforma desde el inicio**: iOS y Android con un único codebase frontend (Expo / React Native). No es viable tener codebases separados por plataforma.
- **Velocidad de desarrollo**: agregar una nueva feature (e.g., cashflow, budget, gamificación) debe requerir solo crear un nuevo módulo/feature sin modificar código existente.
- **Contexto para herramientas AI** (Claude, Cursor): los agentes de código necesitan leer el contexto completo de una feature en un solo directorio, sin tener que recorrer múltiples carpetas globales.
- **Escalabilidad moderada**: el sistema debe poder crecer hasta ~10 módulos de dominio sin necesidad de una refactorización arquitectónica.

Se evaluaron tres enfoques:

1. **Monolito por capas globales** (todos los controllers en `controllers/`, todos los services en `services/`).
2. **Feature-First / Module-per-feature** (cada dominio tiene su propio directorio con todas sus capas internas).
3. **Micro-frontends + micro-servicios** (separación total por dominio, cada uno deployable independientemente).

---

## Decisión

Se adopta **Feature-First en frontend** con **Module-per-feature en backend**.

### Frontend — Feature-First + Clean Architecture por capas

Cada feature de la app vive en `features/<nombre>/` con cuatro capas estrictamente ordenadas:

```
features/<nombre>/
├── index.ts              # contrato público
├── data/<X>Repository.ts # acceso a API
├── hooks/use<X>.ts       # estado y lógica (sin JSX)
└── ui/<X>Screen.tsx      # presentación pura
```

Las dependencias solo fluyen hacia abajo (`ui → hooks → data → api`). No hay dependencias circulares ni imports directos entre features.

El estado compartido entre features (sesión de usuario, tema) vive en `store/` (infraestructura compartida, no feature).

### Backend — Module-per-feature (NestJS)

Cada dominio de negocio es un módulo NestJS independiente bajo `src/<modulo>/`:

```
src/auth/
├── auth.module.ts
├── auth.controller.ts
├── auth.service.ts
├── dto/
└── entities/
```

La lógica de negocio reside **solo en services**. Los controllers son delgados (thin controllers). La comunicación entre módulos se hace mediante proveedores exportados del módulo (`AuthModule` exporta `AuthService` si otro módulo lo necesita).

---

## Consecuencias

### Ventajas

- **Cohesión alta**: todo lo relacionado a una feature (UI, lógica, datos, tests) está en un solo lugar. Es fácil encontrar, modificar o eliminar una feature completa.
- **Baja fricción en PRs paralelos**: dos developers trabajando en features distintas raramente tocan los mismos archivos.
- **Onboarding rápido**: un desarrollador nuevo puede entender una feature completa leyendo solo su directorio.
- **Contexto compacto para AI**: Claude y Cursor pueden leer `features/auth/` o `src/auth/` completos sin necesitar explorar carpetas globales dispersas.
- **Fácil agregar features**: agregar cashflow = crear `src/cashflow/` y `features/cashflow/` sin modificar nada existente.

### Desventajas

- **Riesgo de duplicación de lógica**: si dos features necesitan la misma utilidad y no hay un `common/` bien definido, pueden surgir duplicados.
- **Barrel exports pueden crecer**: el `index.ts` de una feature puede volverse largo si no se disciplina qué se exporta.

### Mitigación de desventajas

- `src/common/` en backend para validators, transformers, filtros y utils reutilizables.
- `src/store/` y `src/api/` en frontend para infraestructura compartida.
- Regla explícita: **prohibido importar entre features directamente**; solo vía `@/store/` o `@/api/`.

---

## Alternativas consideradas

### Opción 1: Monolito por capas globales

```
src/
├── controllers/
│   ├── auth.controller.ts
│   └── users.controller.ts
├── services/
│   ├── auth.service.ts
│   └── users.service.ts
└── entities/
    ├── user.entity.ts
    └── refresh-token.entity.ts
```

**Rechazada porque:**
- A medida que crecen los módulos (8+ dominios), cada carpeta global crece indefinidamente.
- PRs paralelos entre developers generan conflictos frecuentes en carpetas compartidas.
- Dificultad para eliminar un módulo completo (los archivos están dispersos).
- Los agentes AI necesitan leer múltiples directorios para entender una sola feature.

### Opción 2: Micro-frontends + micro-servicios

- Cada dominio es un servicio independiente con su propio deploy.

**Rechazada porque:**
- Complejidad de infraestructura (orquestación, service mesh, múltiples CI/CD) no justificada para un MVP.
- Equipo de 1-3 personas no puede mantener 8+ servicios independientes.
- El overhead de comunicación entre servicios ralentizaría el desarrollo en fase MVP.
- Esta opción puede adoptarse en el futuro si el equipo crece significativamente (>10 developers).

---

## Estado actual de implementación

| Componente | Estado |
|------------|--------|
| `src/auth/` | Completo (M1) |
| `src/users/` | Completo (M1) |
| `src/common/` | Parcial (validators RUT, transformer decimal, filtro global) |
| `src/admin/` | Vacío — deuda técnica M1-DT-01 |
| `features/auth/` | Completo (M1) |
| `features/users/` | Parcial (onboarding en progreso — M1-DT-04) |
| `store/AuthProvider` | Completo |
| `store/ThemeProvider` | Completo |

---

## Mejoras futuras

- Cuando el equipo supere 5 developers, evaluar si es conveniente separar `src/cashflow/` y `src/financialProfile/` como micro-servicios independientes.
- Agregar límites de tamaño en `index.ts` (barrel exports de no más de N exports por feature) para detectar features que se están volviendo demasiado grandes.
- Considerar adoptar `nx` o `turborepo` si el monorepo crece significativamente (actualmente dos repositorios separados: backend y frontend).
