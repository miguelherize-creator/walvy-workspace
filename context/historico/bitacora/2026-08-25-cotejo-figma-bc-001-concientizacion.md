# Cotejo Figma — M1-BC-001 (secuencia de concientización)

**Fecha:** 2026-08-25
**Origen:** Matriz Interna de Impacto M1 — 18 ajustes + 4 brechas (Jose Miguel). Brecha reportada: Kabeli pasa de `M1-V27` (Bienvenida/activación) a `M1-V28` (Foco declarado) sin representar "la secuencia intermedia documentada y construida en Figma".
**Código base:** front-walvy `walvy/main` `857bb3f` · `expo/features/auth/ui/OnboardingScreen.tsx`
**Figma:** archivo `Walvi APP - Edificate Inteligente` (`v45c4HTKnPnU0XABMa5vjY`), nodos entregados por Jose Miguel:
- `3361:2744` — mapa completo del flujo (Registro / Recuperación / Login / Onboarding)
- `6670:13197`, `6670:13103`, `8028:13058`, `8028:13093` — el carrusel de bienvenida, señalado explícitamente como "las del carrusel del onboarding"

## Por qué este documento existe

Al revisar la matriz (`2026-08-25`, ver también `bitacora/2026-08-19-diagramas-g2-g5.md`) BC-001 quedó en "Por validar": no había acceso al Figma cerrado ni a `Walvy_Onboarding_Diagnostico_Fase1_Flujo_Funcional_v1_0.docx` / `Fase2_Matriz_Pantallas_Estados_Acciones_v1_0.docx` citados como fuente, así que no se podía concluir si el carrusel de 3 slides ya visto en código era la secuencia de concientización o sólo la propia bienvenida. Jose Miguel compartió los links de Figma y se hizo el cotejo 1:1.

## Metadata de Figma (nodo 3361:2744)

Dentro de la sección `ONBOARDING` del mapa completo, los 4 nodos entregados aparecen consecutivos, todos nombrados `Onboarding_Welcome`:

| Nodo | x | Nombre interno | Contenido |
|---|---|---|---|
| `6670:13197` | 2904 | Onboarding_Welcome | "Tu mes, en claro." |
| `6670:13103` | 3327 | Onboarding_Welcome | "Claridad al instante." |
| `8028:13058` | 3750 | Onboarding_Welcome | "Tu diagnóstico toma forma." |
| `8028:13093` | 4188 | Onboarding_Welcome | "No te quedes fuera de foco." + botón "Comenzar" |

Justo después de este grupo (x=4908 en adelante) el mapa continúa con los frames `Onboarding_carga de docs` — es decir, en el propio Figma este carrusel es lo que corre entre activación y carga documental, pasando por Foco.

## Comparación texto por texto contra código

| Slide | Copy en Figma | Copy en `OnboardingScreen.tsx` | Resultado |
|---|---|---|---|
| 1 | "Tu mes, en claro." + "Reunimos lo importante de tu mes para que sepas qué atender primero." + footer "En pocos pasos verás lo importante de tu mes en un solo lugar" | Idéntico (líneas 111-141) | ✅ Igual |
| 2 | "Claridad al instante." + "Walvy ordena tus datos para ayudarte a ver mejor qué está pasando en tu mes." | Idéntico (líneas 149-177) | ✅ Igual |
| 3 | "Tu diagnóstico toma forma." + "Al cargar tus documentos, Walvy puede detectar señales de tu mes y sugerirte el siguiente paso." | Idéntico (líneas 178-206) | ✅ Igual |
| 4 | "No te quedes fuera de foco." + "Con tus documentos, Walvy puede construir una lectura más clara y útil de tu situación actual." + botón "Comenzar" | Idéntico (líneas 207-231); el botón hace `router.replace("/(auth)/onboarding-foco")` | ✅ Igual |

Las 4 pantallas están implementadas pixel-perfect y palabra por palabra. El botón "Comenzar" del slide 4 navega exactamente a `onboarding-foco` — confirma que este carrusel es la transición completa entre activación y Foco, sin saltos.

## Conclusión

**BC-001 = Ya implementado.** No falta ninguna pantalla ni código: la "secuencia breve de concientización" que el cliente reporta como ausente es este carrusel de 4 slides, que ya existe y coincide 1:1 con el Figma cerrado.

La brecha real es de **trazabilidad interna**, no de producto: Kabeli nunca nombró este carrusel como su propia variante en la matriz — quedó invisibilizado dentro de la transición `V27 → V28`. Acción pendiente (sólo documental): registrar la secuencia con HU/CA/RN propios y su caso de prueba QA en la próxima versión de la matriz v2.6.

## Resultado en la Matriz Interna de Impacto

| Columna | Valor |
|---|---|
| Impacta código | No |
| Resultado revisión Desarrollo | Solo documental |
| Responsable | QA / Documentación |
| Estado interno | Cerrado |
| Jira / Incidencia | No requiere — registrar variante ya implementada en matriz v2.6 |
