# Recorrido de pantallas · M01 → M02 → M04

Por dónde pasa el usuario y **quién decide** cada salto: qué pantalla, qué ruta
de `expo-router` y qué regla la eligió.

Es la vista de navegación. La de datos —qué tabla escribe cada módulo, qué motor
consume qué— está en [integracion-modulos.md](integracion-modulos.md). Se leen
juntas: ahí está el *qué* se calcula, acá el *dónde aparece*.

Levantado del código de `front-walvy` en `qa`, no del diseño.

## El recorrido

```mermaid
flowchart LR
    LOGIN(["Login · biometría"]) --> GATE{"GET /auth/onboarding<br/>routeForPendingOnboardingGate"}

    subgraph M1["MÓDULO 01 · Onboarding"]
        G0["G0 activación<br/>/onboarding"] --> G1["G1 foco<br/>/onboarding-foco"]
        G1 --> G2["G2 carga<br/>/onboarding-doc"]
        G2 --> G3["G3 análisis<br/>/onboarding-analyzing"]
        G3 --> G4["G4 revisión<br/>/onboarding-analysis"]
        G4 --> G5["G5 diagnóstico<br/>/onboarding-first-ready"]
    end

    GATE -->|"currentGate G0…G5"| G0
    GATE -->|"completed · G6<br/>sin ruta que devolver"| SINRUTA{"lo decide<br/>el llamador"}
    SINRUTA -->|"biometría: sin nombre ni alias<br/>clave: además sin gate"| ALIAS(["/(auth)/choose-alias"])
    SINRUTA -->|resto| HOME

    G5 --> VAR{"¿Qué diagnóstico salió?<br/>light + dominantPressureCode<br/>→ 8 variantes"}

    VAR -->|"no_diagnosis"| G2
    VAR -->|"in_control<br/>attention_data_to_confirm"| PERFIL
    VAR -->|"risk_overload<br/>risk_high_commitments"| ENTRY
    VAR -->|"attention_pending_movements · attention_leaks_detected<br/>attention_adjusted_margin<br/>sin destino propio"| CTA

    CTA{"¿el tipo de CTA<br/>tiene pantalla?<br/>ROUTE_BY_CTA"}
    CTA -->|"ninguna: M03 y M05<br/>son placeholders"| PERFIL

    HOME["Inicio · /"] --> TABS{"Barra inferior<br/>5 pestañas"}
    TABS -->|"Ruta despeje"| ENTRY
    TABS -->|"Presupuesto vivo → M05<br/>Pagos → M06<br/>Asistente IA → M07"| OTROS(["placeholders<br/>Próximamente"])

    subgraph M2["MÓDULO 02 · Perfil"]
        PERFIL["Perfil Financiero<br/>/financial-profile"] --> CTAP{"routeForOnboardingCta"}
        CTAP -.->|"onboarding abierto"| G0
        CTAP -.->|"completed · G6"| NADA["el botón no navega"]
    end

    subgraph M4["MÓDULO 04 · Ruta Despeje"]
        ENTRY{"GET /debts/route/current<br/>resolveDebtEntryPoint"}
        ENTRY -->|"activa · elegible"| RUTA["/debt-route"]
        ENTRY -->|"sin deudas vivas"| CARGA["/debts-upload"]
        ENTRY -->|"por revisar o completar"| REV["/debts-review"]
        CARGA --> ANAL["/debts-analyzing"] --> REV
        CARGA -->|"solo manuales"| REV
        REV --> RESULT["/debts-result"]
        RUTA --> ETAPA2(["Plan · Avance<br/>etapa 2"])
        RUTA -.->|"0 confirmadas"| VACIO["Estado vacío<br/>ninguna rama llega"]
    end

    classDef m1 fill:#EAF4F4,stroke:#1B6B73,color:#103F43
    classDef m2 fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    classDef m4 fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    classDef decision fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    classDef roto fill:#FDECEA,stroke:#AB3737,color:#7A1F1F
    classDef salto fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C

    class G0,G1,G2,G3,G4,G5 m1
    class PERFIL m2
    class RUTA,CARGA,ANAL,REV,RESULT m4
    class GATE,VAR,CTA,CTAP,ENTRY,TABS,SINRUTA decision
    class VACIO,NADA roto
    class LOGIN,HOME,ETAPA2,OTROS,ALIAS salto

    style M1 fill:#FFFDFD,stroke:#E6DED2
    style M2 fill:#FFFDFD,stroke:#E6DED2
    style M4 fill:#FFFDFD,stroke:#E6DED2
```

## Las tres decisiones

Todo salto entre módulos pasa por una de estas tres. Si el usuario aparece
donde no esperabas, es una de ellas.

### 1 · Post-login: `routeForPendingOnboardingGate`

`front-walvy/expo/features/auth/utils/onboardingGates.ts`

Lee `GET /auth/onboarding` y traduce `currentGate` a pantalla.

| `currentGate` | Ruta |
|---|---|
| `G0_activacion` | `/(auth)/onboarding` |
| `G1_foco` | `/(auth)/onboarding-foco` |
| `G2_carga` | `/(auth)/onboarding-doc` |
| `G3_analisis` | `/(auth)/onboarding-analyzing` |
| `G4_revision` | `/(auth)/onboarding-analysis` |
| `G5_diagnostico` | `/(auth)/onboarding-first-ready` |

**Fuera de esa tabla la función devuelve `undefined`**, y ahí no hay regla: la
decisión pasa al llamador. Dos casos caen ahí, y no por el mismo motivo —
`onboardingStatus: completed` sale por su propia guarda, y `G6_retoma` porque
`ONBOARDING_GATE_ROUTE` sólo mapea G0…G5. Comparten el hueco, no la razón.

`resumeState` **no** entra en la decisión: "Salir por ahora" va a Home en esa
sesión (RGL-007) y el próximo login retoma `currentGate` (V02, V58).

**G6 no tiene pantalla a propósito.** El backend lo dice en
`user-onboarding.service.ts`: *no es una etapa que se atraviese, es dónde quedó
el usuario al pausar*. Queda fuera de `ORDEN_DE_PUERTAS`, así que no avanza ni
cuenta para `lastCompletedGate`. Y hoy la rama es puramente defensiva: el valor
está en el enum de la migración 018, en el DTO y en los tipos del front, pero
**ningún código lo escribe**.

#### Los tres llamadores no hacen lo mismo

| Llamador | Con `undefined` |
|---|---|
| `useLoginForm` | `choose-alias` si **no** está completed, **no** hay gate y el usuario no tiene nombre ni alias. Si no, Home |
| `useBiometricLogin` | `choose-alias` si el usuario no tiene nombre ni alias — **sin mirar gate ni estado**. Si no, Home |
| `FinancialProfileScreen` | `if (route) router.push(...)`: **no navega**. El botón no responde |

Las dos primeras condiciones no son la misma. Un usuario sin `username`,
`firstName` ni `lastName` y con el onboarding **cerrado** va a `choose-alias`
entrando con huella, y a Home entrando con clave. Mismo estado, dos destinos
según cómo firmó.

La tercera es deliberada —`routeForOnboardingCta` devuelve `undefined` para
completed y G6 con el comentario *"no reinician el flujo"*— pero para quien lo
toca es un botón muerto.

### 2 · Fin del onboarding: la variante del diagnóstico

`front-walvy/expo/features/auth/utils/onboardingDiagnosisVariant.ts`

G5 muestra el diagnóstico y **un** botón. El texto lo elige `dominantCta.type`;
el destino, **no**.

Quien decide el destino es la `diagnosis_variant` (§6.4 del Anexo BDD), que el
backend no emite como campo propio: se deriva en el front desde `light` +
`dominantPressureCode`.

**Por qué no basta el tipo de CTA.** El mismo código de CTA aparece en casos de
producto distintos: `adjust_budget` sale tanto en `attention_adjusted_margin`
(D5) como en `risk_overload` (D1), y `review_category` en
`attention_pending_movements` (D3) y `attention_leaks_detected` (D4). Cuatro
situaciones, dos códigos. Ramificar por el tipo de CTA daría el destino
equivocado en la mitad.

| `diagnosis_variant` | Prioridad | Destino |
|---|---|---|
| `no_diagnosis` | P0 | `/(auth)/onboarding-doc` — G2 |
| `in_control` | D6/D8 | `/financial-profile` |
| `attention_data_to_confirm` | D5 | `/financial-profile` |
| `risk_overload` | D1 | `/(tabs)/debt-route` |
| `risk_high_commitments` | D2 | `/(tabs)/debt-route` |
| `attention_pending_movements` | D3 | sin destino propio → segunda etapa |
| `attention_leaks_detected` | D4 | sin destino propio → segunda etapa |
| `attention_adjusted_margin` | D5 | sin destino propio → segunda etapa |

**La segunda etapa.** Cuando la variante no tiene destino, el tipo de CTA vuelve
a decidir por `ROUTE_BY_CTA`:

```ts
return byVariant ?? resolveCtaDestination(cta);
```

No es redundancia: las tres variantes sin destino son de M03 y M05, y el día que
esas pantallas existan basta agregarlas a `ROUTE_BY_CTA` para que las tres las
tomen solas.

Hoy ninguna de las tres tiene entrada ahí, así que caen al **fallback: Perfil
Financiero, no Inicio**. Fase 3 §16/§19 lo fija como destino preferente de salida
del onboarding y prohíbe Home como salida principal, y §12 del Anexo deja
`ver_perfil` como secundario de todo diagnóstico.

Las dos variantes de riesgo apuntan a la **puerta** de M04, no a una pantalla
concreta: la superficie la decide la regla 3. Apuntar directo a Revisión sería
una segunda fuente de verdad para la misma decisión.

`dominantCta.refId` —la deuda concreta que el backend nombra— no se usa: no hay
pantalla de una deuda sola.

Cinco de las ocho variantes no tienen maqueta; su copy sale de `CTA_COPY`, que el
propio archivo marca como borrador de Producto.

### 3 · Entrada a M04: `resolveDebtEntryPoint`

`back-walvy/src/debts/rules/debt-completeness.rule.ts` · el front sólo traduce
la superficie a ruta en `features/debts/entryPoint.ts`.

Cinco ramas, en orden; gana la primera que se cumple.

| # | Condición | Superficie | `reasonCode` | Ruta |
|---|---|---|---|---|
| 1 | elegibilidad `activa` | `ruta` | `entry_route_active_preserved` | se queda en `/debt-route` |
| 2 | ninguna deuda viva | `carga` | `entry_no_debts` | `/debts-upload` |
| 3 | quedan por revisar | `revision` | `entry_review_pending` | `/debts-review` |
| 4 | elegibilidad `elegible` | `ruta` | `entry_route_available` | `/debt-route` |
| 5 | todo lo demás | `revision` | `entry_completeness_pending` | `/debts-review` |

El caso 5 recoge `pendiente_datos`, `pendiente_confirmacion`, `no_elegible`,
`cerrada` y "sin evaluar". El comentario de la regla lo dice: *nunca a una Ruta
que no está disponible*.

Dos casos los decide el front: sin `entry` en la respuesta el usuario se queda
donde está —lo conservador—, y si la llamada falla sale la pantalla de error con
Reintentar, nunca el vacío: un 401 no es "no tienes deudas".

## Lo que no cierra

**El estado vacío de Ruta Despeje es inalcanzable.** Vive dentro de
`/debt-route` y se muestra con **cero deudas confirmadas**; llegar a
`/debt-route` exige elegibilidad `activa` o `elegible`, que no se alcanza sin
deudas confirmadas. Las dos condiciones se excluyen. El frame existe
(`10145:24232`) y ninguna rama llega. O sobra el frame, o sobra esa rama.

**Cinco de las ocho variantes del diagnóstico no tienen maqueta.** Su copy sale
de `CTA_COPY`, que el propio archivo marca como borrador: Producto no cerró el
catálogo. Tres de ellas además no tienen pantalla de destino —son de M03 y
M05— y aterrizan en Perfil Financiero por fallback.

**Los dos logins discrepan.** `useLoginForm` exige que no haya gate y que el
onboarding no esté cerrado antes de mandar a `choose-alias`; `useBiometricLogin`
sólo mira si el usuario tiene nombre. Un mismo usuario aterriza en pantallas
distintas según haya entrado con clave o con huella. Ninguna de las dos condiciones
está escrita como regla en ningún lado: viven en el `if` de cada hook.

**"Preparar mi perfil" puede no hacer nada.** Con el onboarding cerrado o en G6,
`routeForOnboardingCta` devuelve `undefined` y la pantalla no navega. Es
deliberado —no se reinicia un flujo terminado— pero el botón sigue ahí y no
responde.

**"Ver resultado" en Revisión tiene tres reglas.** La pantalla habilita con una
deuda confirmada, el backend expone `canViewResult` sólo cuando no queda ninguna
por confirmar, y el aviso de la propia pantalla promete que las pendientes
quedan guardadas. Sin definir.

## Cómo verificarlo

El front deja rastro en `__DEV__` en las tres decisiones:

```
[Login] Onboarding status: in_progress G3_analisis ready_to_resume
[ruta-resumen] entrada del backend → surface=revision · reason=entry_review_pending · ruleVersion=v1_mvp
[deudas-carga] Continuar → 2 documento(s) legible(s), 1 pendiente(s), 0 deuda(s) manual(es)
```

El detalle del paso 1 de M04 —cada rama de carga, análisis y revisión, con sus
node-id de Figma y lo que falta de diseño— está en
[modulo04-motor-deudas](../modulo04-motor-deudas/).
