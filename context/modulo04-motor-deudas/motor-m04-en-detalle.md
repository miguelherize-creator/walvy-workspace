# El motor de M04 · cómo piensa el backend de deudas

Complemento de `[integracion-modulos.md](../wiki-codigo/integracion-modulos.md)` —que muestra **las pantallas**— y de `[paso-3-resultado-en-detalle.md](paso-3-resultado-en-detalle.md)`
—que hace zoom en una—. Este muestra **el motor**: qué decide el backend, en qué orden y con qué se queda corto.

La idea en una frase: **una sola evaluación determinista, recalculada entera en cada
lectura, que nunca afirma lo favorable sin evidencia.**

---

## 1 · El pipeline · una pasada, nueve decisiones

Cada llamada a `GET /debts/route/current` corre esto de punta a punta. No hay caché ni
snapshot: la lectura nunca viene de un estado viejo.

```mermaid
flowchart TB
    IN["Deudas del usuario<br/>+ insumos de M05 / M06"]:::entrada

    IN --> Q["1 · Gate de calidad<br/><i>¿con qué datos contamos?</i>"]
    Q --> R["2 · Revisión del lote<br/><i>¿cuáles ya confirmó?</i>"]
    R --> C["3 · Completitud<br/><i>¿qué falta por deuda?</i>"]

    C --> P4

    subgraph P4["4 · Motor P4 · la presión"]
        direction TB
        EJES["C · carga mensual<br/>K · capacidad residual<br/>D · deterioro"] --> MAT["Matriz de 27 celdas"]
        MAT --> FLO["Floors causales<br/>RGL-020 · 021 · 022"]
    end

    P4 --> AGP["5 · Agregación de presión<br/><i>N deudas → una lectura</i>"]
    P4 --> SAL["6 · Salud de deuda<br/><i>presión + aging</i>"]

    AGP --> EL["7 · Elegibilidad de Ruta<br/><i>presión + gate</i>"]
    EL --> AGR["Agregación de Ruta"]

    AGR --> PL["8 · Plan bola de nieve<br/><i>orden y capacidad recuperable</i>"]
    AGR --> SIT["9 · Situaciones F1–F7<br/><i>qué mostrarle al usuario</i>"]

    PL --> OUT
    SIT --> OUT
    SAL --> OUT
    AGP --> OUT

    OUT["Respuesta + escritura en BD"]:::salida

    classDef entrada fill:#EAF4F4,stroke:#1B6B73,color:#103F43
    classDef salida fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    class Q,R,C,AGP,SAL,EL,AGR,PL,SIT paso
    classDef paso fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    class EJES,MAT,FLO motor
    classDef motor fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    style P4 fill:#FFFDFD,stroke:#E6DED2
```



**El orden importa y no es casual.** La calidad se evalúa **antes** que C×K×D: sin saber
con qué datos se cuenta no se puede concluir nada. Y la elegibilidad va **después** de la
presión, porque el gate necesita el resultado del motor, no al revés.

---



## 2 · El guardrail que aparece en todas partes

Si el equipo se lleva una sola idea de M04, que sea esta. Está escrita en el contrato y
repetida en el código en cinco lugares distintos:

> «No convertir missing en cero ni fabricar En Control por falta de evidencia.»
> «Evidencia adversa suficientemente sólida puede sostener Atención/Riesgo aunque otros
> datos estén incompletos; **un faltante material bloquea En Control**.» — §10.1

```mermaid
flowchart LR
    F["Falta un dato"] --> PREG{"¿Hacia dónde<br/>se degrada?"}
    PREG -->|"lo favorable<br/>«está al día»"| MAL["❌ prohibido"]:::mal
    PREG -->|"lo adverso<br/>«no podemos concluir»"| BIEN["✅ siempre"]:::bien

    BIEN --> E1["C sin ingreso → banda null<br/><i>nunca C1 por defecto</i>"]
    BIEN --> E2["D inferido → no concluye<br/><i>deducir ≠ confirmar</i>"]
    BIEN --> E3["presión null → no_calculable<br/><i>nunca sin_presion</i>"]
    BIEN --> E4["salud sin aging → sin_datos<br/><i>nunca sana</i>"]
    BIEN --> E5["Ruta sin presión → pendiente<br/><i>nunca elegible</i>"]

    classDef mal fill:#FDECEA,stroke:#AB3737,color:#7A1F1F
    classDef bien fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    class E1,E2,E3,E4,E5 ej
    classDef ej fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    class PREG dec
    classDef dec fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
```



**La asimetría es deliberada.** Riesgo y Atención ganan con **una sola** deuda que los
sostenga, aunque otras no concluyan. Pero En Control exige que **todas** hayan concluido:
un solo `null` degrada a `no_calculable`. Lo mismo con `sana` en Salud.

---



## 3 · Las cuatro capas · dónde vive cada cosa

```mermaid
flowchart TB
    subgraph L1["rules/ · funciones puras"]
        direction LR
        R1["16 reglas<br/>sin BD, sin Nest, sin fechas propias"]
    end
    subgraph L2["services/ · orquestación"]
        direction LR
        R2["pipeline · el orden<br/>route.service · la respuesta<br/>writer · la escritura"]
    end
    subgraph L3["persistence/ · proyección"]
        direction LR
        R3["de la salida de una regla<br/>a columnas de la tabla"]
    end
    subgraph L4["ports/ · lo ajeno"]
        direction LR
        R4["PressureInputs<br/>lo que M04 NO calcula"]
    end

    L4 --> L1 --> L2 --> L3

    classDef c1 fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    classDef c2 fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    classDef c3 fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    classDef c4 fill:#EAF4F4,stroke:#1B6B73,color:#103F43
    class R1 c1
    class R2 c2
    class R3 c3
    class R4 c4
    style L1 fill:#FFFDFD,stroke:#E6DED2
    style L2 fill:#FFFDFD,stroke:#E6DED2
    style L3 fill:#FFFDFD,stroke:#E6DED2
    style L4 fill:#FFFDFD,stroke:#E6DED2
```



Las reglas son **funciones puras**: reciben todo lo que necesitan por parámetro —incluido
el `now`, para que los tests sean deterministas— y no tocan la base. Por eso se pueden
probar sin levantar Nest, y por eso cada una tiene su `.spec.ts` al lado.

Cada regla lleva su `RULE_VERSION`, que se persiste junto al resultado: se puede saber
con qué versión de la lógica se evaluó una deuda.

---



## 4 · Lo que M04 no calcula · el puerto

M04 depende de módulos que todavía no existen. En vez de inventar los datos, los pide por un puerto y **declara el faltante.**

```mermaid
flowchart LR
    M5["M05 · Presupuesto"] -->|"ingreso canónico<br/>headroom"| PORT
    M6["M06 · Pagos"] -->|"hecho de pago<br/>días de atraso"| PORT

    PORT{{"PressureInputs<br/>(puerto)"}}:::dec

    PORT --> IMPL["Hoy: NullPressureInputsAdapter<br/><i>devuelve todo en null</i>"]:::roto
    IMPL --> RES["→ presión no_calculable<br/>→ salud sin_datos_suficientes"]

    classDef roto fill:#FDECEA,stroke:#AB3737,color:#7A1F1F
    classDef dec fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    class M5,M6 ext
    classDef ext fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    class RES ok
    classDef ok fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
```



**El malentendido más común del módulo:** «falta el motor P4». **No falta.** El motor está
completo —las 27 celdas transcritas, los tres floors, sus tests— y corre en cada
evaluación. Lo que falta es **el adaptador que le da de comer**. Es un archivo, no un
módulo, y es lo único que separa a QA de poder reproducir los escenarios.

---



## 5 · Qué está cableado y qué no

De las 16 reglas, **14 corren en cada evaluación**. Dos están escritas, probadas y sin
ningún camino que las llame:


| Regla                 | Estado         | Por qué                                                                          |
| --------------------- | -------------- | -------------------------------------------------------------------------------- |
| `sustainability-gate` | 🔵 sin cablear | Necesita el outcome prudencial de **M05**, y la pantalla de simulación de aporte |
| `selected-plan`       | 🔵 sin cablear | Aceptar simulación y rollback: la superficie no existe todavía                   |


Las dos son **inversión adelantada**: se escribieron con el contrato en la mano para que
enchufarlas sea trivial.

Hubo una tercera, `debt-severity` —un semáforo de deudas por vencimiento—, y **se borró**:
nunca se cableó, y el contrato dejó el aging en manos de Salud de Deuda (owner operativo
M06) sin un color propio. Su única función viva, `hasMoraConfirmada` —el override
`M1-DP-006`/`M1-V55` del semáforo de G5—, se movió a
`src/imports/rules/mora-confirmada.rule.ts`, que es donde vive su consumidor.

---



## 6 · Los endpoints

```mermaid
flowchart LR
    subgraph CAPTURA["Captura y revisión"]
        E1["POST /debts"]
        E2["PATCH /debts/:id"]
        E3["POST /debts/:id/confirm"]
        E4["POST /debts/:id/dismiss"]
        E5["GET /debts · GET /debts/:id"]
        E6["GET /debts/summary"]
    end
    subgraph RUTA["Ruta Despeje"]
        E7["GET /debts/route/current"]
        E8["POST /debts/route/apply"]
        E9["POST /debts/route/close-debt"]
    end
    E10["POST /debts/:id/payments"]

    E7 -.->|"recalcula todo"| PIPE(["el pipeline de §1"])
    E8 -.->|"recalcula + evento"| PIPE
    E9 -.->|"recalcula"| PIPE

    classDef cap fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    classDef rut fill:#EAF4F4,stroke:#1B6B73,color:#103F43
    class E1,E2,E3,E4,E5,E6,E10 cap
    class E7,E8,E9 rut
    class PIPE salto
    classDef salto fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    style CAPTURA fill:#FFFDFD,stroke:#E6DED2
    style RUTA fill:#FFFDFD,stroke:#E6DED2
```



`apply` **es el único que activa.** Ver el plan, navegarlo o simular un aporte **no**
activan la Ruta: §7.2 del contrato prohíbe «usar un CTA visible como sustituto del
evento». Un segundo «Seguir plan» tampoco reactiva — conserva estado y `activatedAt`.

---



## 7 · Dos distinciones que se confunden seguido

**Elegible ≠ activa.** Elegible es «corresponde ofrecerte la Ruta». Activa es «la
empezaste». Entre las dos hay un evento explícito del usuario.

**Presión ≠ elegibilidad.** La presión dice *cuánto aprieta la deuda*; la elegibilidad
dice *si toca ofrecer Ruta*. Riesgo con el gate incompleto **no** abre Ruta: manda a
confirmar o completar. Colapsar las dos fue el bug de
[front-walvy#159](https://github.com/KabeliDev/front-walvy/issues/159).

```mermaid
flowchart LR
    PR{"Presión"} -->|en_control| A1(["seguimiento · CTA M06"])
    PR -->|atencion| A2(["revisión preventiva<br/>SIN Ruta"])
    PR -->|riesgo| G{"¿gate completo?"}
    PR -->|"no calculable"| A0(["no se afirma nada"])
    G -->|no| A3(["confirmar / completar<br/>SIN Ruta"])
    G -->|sí| A4["ofrecer Ruta"] --> EV{"¿«Seguir plan»?"}
    EV -->|no| A5(["elegible, no activa"])
    EV -->|sí| A6["activa"]

    classDef dec fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    class PR,G,EV dec
    class A4,A6 ok
    classDef ok fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    class A0,A1,A2,A3,A5 salto
    classDef salto fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
```



---



## 8 · Cómo verificarlo

```bash
cd back-walvy && npx jest src/debts
```

**451 tests en 28 suites.** Cada regla tiene su spec al lado, con los casos borde del
contrato como casos de prueba nombrados. Para entender una regla, leer su `.spec.ts`
antes que su implementación: los nombres de los tests son la especificación en prosa.

El contrato vivo está en `back-walvy/docs/api/debts/route.md`, con el ejemplo de respuesta
y la tabla de los cinco escenarios de OD-03.