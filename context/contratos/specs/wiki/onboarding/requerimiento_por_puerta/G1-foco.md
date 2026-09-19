# G1 — Foco del Mes

**Pantalla UX:** Entre A (Bienvenida) y B (Carga documental)  
**Fuentes:** `Walvy_Regla_Priorizacion_CTA_por_Foco_Mes_v1_0.docx` · `Walvy_Onboarding_Diagnostico_Fase3_Reglas_Contextuales §9 G1`

---

## Propósito

Capturar la prioridad mensual declarada por el usuario antes de que cargue documentos. El foco no es una meta decorativa: se conecta con indicadores reales del Perfil Financiero y determina la priorización de CTAs en Home, Perfil Financiero, Mi Foco del Mes, recomendaciones y alertas a lo largo de toda la app.

---

## Condiciones

| | Descripción |
|---|---|
| **Entrada** | Viene desde G0 (usuario presionó "Comenzar") |
| **Avance** | Foco seleccionado → guarda foco → avanza a G2 |
| **Bloqueo** | Sin bloqueo fuerte. La spec permite "decisión de continuar" sin foco como segunda salida hacia G2 |
| **Salida hacia** | G2 (con foco guardado) · Home/tabs (si el usuario sale con "Continuar más tarde") |

---

## Evento que declara esta puerta

```
advanceOnboardingStep({ currentGate: 'G1_foco' })
```
Se dispara al entrar a la pantalla.

Al confirmar foco y avanzar:
```
advanceOnboardingStep({ currentGate: 'G2_carga', goalsSet: true })
```

---

## Catálogo de focos (6 — todos obligatorios funcionalmente)

| ID | Label visible | Indicadores asociados |
|---|---|---|
| `bajar_deuda` | Bajar deuda | Salud de Deuda, Ruta Despeje, compromisos de deuda, disponible |
| `ordenar_compromisos` | Ordenar compromisos | Compromisos base, vencimientos, disponible |
| `ahorrar_monto` | Ahorrar un monto | Disponible, ingreso, compromisos, deuda sana |
| `aumentar_margen` | Aumentar margen | Top recurrentes, disponible, pagos variables |
| `evitar_atrasos` | Evitar atrasos | Vencimientos, compromisos, deuda, alertas |
| `cumplir_presupuesto` | Cumplir presupuesto | Disponible, compromisos, recurrentes, regla financiera activa |

> **Nota de disambiguación:** `ordenar_compromisos` se activa por necesidad de claridad estructural del mes. `evitar_atrasos` se activa por riesgo temporal o vencimiento. Pueden coexistir pero no son lo mismo.

Si la UI necesita mostrar menos de 6 focos por espacio, se puede mostrar un subconjunto visible; la regla de negocio debe conservar la trazabilidad completa de los seis.

---

## CTAs

| CTA | Tipo | Condición |
|---|---|---|
| Guardar mi foco | Dominante — deshabilitado hasta seleccionar | Requiere foco seleccionado |
| Continuar más tarde | Secundario (link textual, menor peso visual) | Abre modal de confirmación → sale al home con `resumeState: ready_to_resume` |

---

## Postergación

**¿Puede pausarse?** Sí, sin bloqueo fuerte.

- "Continuar más tarde" → modal de aviso → `resumeState: ready_to_resume` → home
- El onboarding queda en retoma; al volver, puede retomar desde G1 o desde G2 si el producto decide avanzar sin foco
- Sin foco declarado, Walvy puede sugerir uno basado en los indicadores del Perfil Financiero al retomar

---

## Regla de negocio central

```
RB-FM-001: Si el usuario tiene un Objetivo Foco del Mes activo,
Walvy debe priorizar los CTAs asociados a ese foco en Home,
Perfil Financiero, Mi Foco del Mes, recomendaciones y pantallas
relacionadas, SALVO que exista una señal financiera crítica de
mayor prioridad.
```

### Jerarquía de priorización (aplica en toda la app desde G1 en adelante)

```
Señales críticas  >  Foco declarado  >  Foco sugerido por Walvy
```

**Señales críticas que prevalecen sobre el foco:**
- Deuda presionada / mora / recargo
- Vencimiento crítico próximo
- Disponible negativo o margen muy bajo
- Dato crítico faltante que impide evaluar deuda, disponible o compromisos
- Atraso o riesgo de multa/recargo

### Reglas complementarias

| ID | Regla |
|---|---|
| RB-FM-002 | Una señal crítica siempre prevalece sobre el foco declarado |
| RB-FM-003 | Si no hay señales críticas, el CTA dominante debe alinearse con el foco activo |
| RB-FM-004 | Si el usuario no tiene foco activo, Walvy puede sugerir uno según Perfil Financiero |
| RB-FM-005 | El foco no puede ocultar deuda presionada, mora, atrasos, vencimientos críticos ni disponible insuficiente |
| RB-FM-006 | Cada foco debe estar trazado a uno o más indicadores del Perfil Financiero |
| RB-FM-007 | No deben mostrarse dos CTAs con el mismo peso visual — siempre una acción dominante |
| RB-FM-008 | Si la calidad del dato es insuficiente para sostener el foco, priorizar completar o confirmar información |
| RB-FM-010 | El usuario puede cambiar su foco, pero Walvy debe advertir si existe una señal crítica más prioritaria |

---

## Entidad de datos

**`onboarding_focus`** — pertenece a `onboarding_session`

| Campo | Uso |
|---|---|
| `focus_id` | Identificador del foco seleccionado (enum del catálogo de 6) |
| `declared_at` | Momento de declaración |
| `source` | `user_declared` / `walvy_suggested` |

---

## Guardrails

- No usar el foco como formulario largo ni como meta aislada
- No prometer ahorro garantizado ni resultados financieros automáticos
- No transformar el foco en un formulario de edición completo aquí
- No ocultar señales críticas detrás del foco
- No crear dos CTAs con el mismo peso visual
