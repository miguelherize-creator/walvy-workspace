# Plan de onboarding — desarrollador nuevo (inicia lun 2026-08-31)

**Perfil:** semi-senior, fuerte en backend, algo de frontend, **cero experiencia mobile**.
**Accesos:** ya gestionados (GitHub KabeliDev + walvy-org, Drive M1/M2, Figma, ambiente QA).
**Nombre:** Sergio Vidal.
**Destino confirmado (30-ago):** **Módulo 5 — Cashflow**, con entrega comprometida el **miércoles 23 de septiembre**.
(Miguel: M4 al 10-sep · Leonardo: M6 al 30-sep. Se le asigna M5 justamente porque es el módulo que más
código construido tiene: su trabajo es conectarlo y completarlo, no diseñarlo.)

---

## Duración: 5 días hábiles, no 2

Productivo en tareas acotadas al **día 3**. Autónomo para tomar M5 al **día 5**.

El costo no está en el stack backend — eso lo domina. Está en:

1. **Mobile desde cero** — un día completo solo para tener la app corriendo y entender que `app/` son delegates de 2 líneas y la lógica vive en `features/`.
2. **El dominio** — Walvy no es un CRUD. El semáforo, el foco del mes, las puertas G0→G5, la suficiencia documental: nada de eso se deduce leyendo el código.
3. **Las reglas del cliente** — los commits citan `M2-V65`, no `#179`. Sin entender la matriz de impacto sus PR no son auditables contra la entrega.

---

## Día 1 (lun 31) — Entorno y primer arranque

**Objetivo del día:** los dos stacks corriendo en su máquina y la app en su teléfono.

- **Mañana — back-walvy.** `pnpm` (⚠️ NO npm, aunque `stack.md` diga npm), `docker compose up --build`, `migration:run`, Swagger en `/api`. Cargar `entregas/set-datos-prueba.sql`. Meta: login exitoso desde Swagger.
- **Tarde — front-walvy/expo.** Bun (`bun i`, `bun run start-web` primero, luego dispositivo real). Meta: registrar un usuario desde la app contra su backend local.
- **Riesgo:** toolchain iOS/Android. Sin Mac, se queda en Android + web y no se bloquea.

## Día 2 (mar 1) — El producto antes que el código

- Recorrer el onboarding completo G0→G5 como usuario, con una cartola real de **un mes ya cerrado** (si no, el semáforo no es evaluable).
- Repetir el recorrido mirando la base: `user_onboarding`, `statement_imports`, `import_line_items`, `transactions`.
- **Material:** el issue `KabeliDev/back-walvy#183` (`flujo-g0-a-perfil-financiero`) es el punto de entrada único y autocontenido — el recorrido completo G0 → Perfil Financiero con los diez diagramas, verificado contra `origin/qa`. Después, `front-walvy#70` como guion para recorrerlo a mano contra la base.
- **Entregable:** que explique en 10 minutos, en la daily, qué pasa desde que se sube un PDF hasta que aparece el semáforo. Si no lo puede explicar, no está listo para el día 3.

## Día 3 (mié 2) — Reglas y forma de trabajo

- Matriz de impacto M1 y M2 (Drive) y **cómo se cita**: `M1-RN-*` / `M2-V65` en el título del commit, nunca `#NN`.
- **Dos remotes — el error más caro posible.** `origin` = KabeliDev (ahí van los PR) · `walvy` = walvy-org (espejo del cliente).
- Modelo de ramas real: `feature/*` → PR → `main` → tag. `qa` es la rama de integración hoy en revisión del cliente. `develop`/`release` son residuo.
- `context/conventions.md`, `visual-design-rules.md`, `testing.md`.
- Leer 3 PR ya mergeados en `qa` (#178, #179, #180) como referencia de "así se ve un PR aceptable acá".

## Días 4-5 (jue 3 – vie 4) — Entregable real, sin riesgo

### Encargo: Inventario M5 y congelamiento del contrato de categorías

**M5 no es greenfield**: `src/cashflow/` y `src/imports/` ya existen —se construyeron para sostener el onboarding de M1— pero la documentación miente:

| Dice `db/modulo5.md` | Dice el código |
|---|---|
| `financial_movement` | `transactions` |
| `file_upload` | `statement_imports` |
| `user_financial_instrument` | `funding_sources` |
| `movement_review_queue`, `movement_classification_history` | no existen |

Y hay un detalle que lo hace urgente: **`CashflowModule` existe pero no está wireado en `AppModule`**, así que los endpoints de M5 hoy no corren.

**El encargo, literal:** levantar el inventario real del módulo Cashflow —entidades y tablas efectivas, endpoints que existen hoy en los controllers, cuáles del spec no existen— y, sobre todo, **documentar y congelar el contrato del árbol de categorías**. Entregar un PR de documentación que deje `context/modulo05-cashflow/contexto/` como fuente de verdad.

**Por qué este ejercicio, y por qué el contrato es la mitad urgente:**
- Es 100% backend — su terreno.
- Lo obliga a leer exactamente el código que va a completar en M5.
- No puede romper nada mientras M1 y M2 están en revisión.
- **Leonardo no puede arrancar M6 sin ese contrato**, y sus consumidores son tres: M6, front-walvy y Kread. El contrato no se rediseña, se documenta y se congela.
- Cierra con un PR real: aprende el circuito completo sin exponer la entrega.
- Da señal medible de seniority antes de comprometerlo con el 23 de septiembre.

> **A vigilar desde la semana 2:** la pantalla de movimientos es su primera entrega móvil. Tiene que empezarla en la semana del 7, no en la última. Si llega al 21 sin haberla tocado, la fecha del 23 no se sostiene.

**Opcional viernes tarde:** tests unitarios a un service de `src/cashflow/` que hoy no los tenga. PR chico, ejercita CI.

### Lo que NO se le da la primera semana
- **M4 (Ruta Despeje)** — es de Miguel y `feature/modulo4-v1` está 29 commits atrás.
- **Bugfix en `qa`** — está en revisión del cliente ahora mismo.
- **Cualquier cosa que toque migraciones.**

---

## Deuda de documentación que hay que tapar antes del lunes

Lo que va a chocar en la primera hora:

1. **`CLAUDE.md` y `mvp-scope.md` usan numeración de "Sprints" que NO es la de los módulos.** Dicen "Sprint 5 = Budgets"; en la realidad M5 = Cashflow y M6 = Presupuesto. Un dev nuevo va a creer que su módulo es otro. ← **arreglar antes del lunes**
2. **`stack.md` dice npm y NestJS 10; el repo usa pnpm y NestJS 11.** ← **arreglar antes del lunes**
3. `debt.md` congelado en 2026-06-11 — da por abierto M1-DT-04 (onboarding no cierra), ya resuelto.
4. `release-workflow.md` no menciona `qa` y afirma que no hay migraciones TypeORM — hay 30+ en `src/migrations/`.
5. No existe un README de "primer día" en ninguno de los dos repos.

**Recomendación:** arreglar 1 y 2 antes del lunes (rompen el día 1). Dejar 3, 4 y 5 para que los arregle **él** como parte del onboarding — es la mejor forma de que lea esos documentos y el equipo gana docs vivos.

---

## Ritual

- Daily de 15 min.
- Check-in de 30 min al cierre de los días 1, 2 y 5 (no todos los días: es semi-senior).
- Regla explícita: **trabado más de 45 minutos → pregunta.**
- Sus PR: revisión línea por línea las primeras 3 semanas, con la skill `walvy-audit`.

---

## Contexto que no estaba en la lista original y es imprescindible

- Los **dos remotes** (KabeliDev vs walvy-org).
- Citar **reglas de la matriz** en commits, no números de issue.
- La fuente de verdad del schema son las **entidades TypeORM**, no `db/modulo*.md`.
- **Kread** es servicio externo de extracción de cartolas; necesita `KREAD_BASE_URL` apuntando a una instancia con TCR y CMF, si no medio flujo no se puede probar.
- **Flow.cl** sandbox para suscripciones; sus webhooks **no traen firma** — se confía en `getStatus`.
- **`DEV_TOOLS_ENABLED=true` + `POST /dev/reset-user`** es lo que permite repetir el onboarding N veces. Sin eso se frustra el día 2.
- Tipografía **Manrope**, no Aptos. Que Figma siga en Aptos no es divergencia.
