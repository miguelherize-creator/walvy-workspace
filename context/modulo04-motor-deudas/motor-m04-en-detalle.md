# El motor de M04 · del documento a la Ruta

Contraparte backend de [integracion-modulos.md](../wiki-codigo/integracion-modulos.md). Ese muestra cómo se conectan los módulos; este sigue **una deuda** desde que entra a la base hasta que sale como decisión.

Levantado del código en `origin/qa`

> 🟡 **En amarillo, todo lo provisional** — lo que existe así porque M05 y M06  todavía no entregan.

---

## 1 · Cómo entra una deuda

Dos caminos. Ambos crean la fila `unconfirmed`: nada entra al motor sin que el usuario la mire.

```mermaid
flowchart TB
    INS[("deuda guardada<br/>todavía sin confirmar")]

    subgraph AUTO["Automático · vía M01"]
        direction TB
        DOC[Usuario sube cartola/CMF] --> KR["Kread extrae"]
        KR --> MAP["kread-debt.mapper<br/>candidatos"]
        MAP --> DEDUP{"¿misma deuda<br/>ya sin confirmar?"}
        DEDUP -->|"acreedor + tipo + saldo"| SKIP(["no duplica"])
    end
    DEDUP -->|nueva| INS

    subgraph MAN["Manual · vía M04"]
        direction TB
        FORM["POST /debts"] --> META["metadata.source = manual_entry"]
    end
    META --> INS

    INS --> REV{"El usuario revisa"}
    REV -->|"POST /debts/:id/confirm"| OK["confirmed"]:::ok
    REV -->|"POST /debts/:id/dismiss"| NO["dismissed"]:::gris
    REV -->|"PATCH /debts/:id"| INS

    OK --> MOTOR(["entra al motor"])
    NO --> FUERA(["no entra al plan<br/>pero se conserva"])

    GUARD{{"confirm rechaza si faltan<br/>minimumPayment o nextDueDate"}}:::dec
    GUARD -.-> OK

    classDef ok fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    classDef gris fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    classDef dec fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    class DOC,KR,MAP,FORM,META m1
    classDef m1 fill:#EAF4F4,stroke:#1B6B73,color:#103F43
    class INS db
    classDef db fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    class DEDUP,REV dec
    class SKIP,FUERA,MOTOR salto
    classDef salto fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    style AUTO fill:#FFFDFD,stroke:#E6DED2
    style MAN fill:#FFFDFD,stroke:#E6DED2
```




|            | Automático                                        | Manual                 |
| ---------- | ------------------------------------------------- | ---------------------- |
| Lo escribe | `statement-import.service`                        | `debts.service.create` |
| `metadata` | `importId` · `kreadJobId`                         | `source: manual_entry` |
| Dedupe     | acreedor + tipo + saldo, sólo entre `unconfirmed` | ninguno                |
| Nace       | `unconfirmed`                                     | `unconfirmed`          |


---



## 2 · El pipeline · una pasada, nueve decisiones

`GET /debts/route/current` corre esto **entero en cada llamada**. Sin caché: la lectura
nunca viene de un estado viejo.

```mermaid
flowchart TB
    IN["deudas del usuario"] --> Q["1 · Gate de calidad<br/><i>¿con qué datos contamos?</i>"]
    PORT["🟡 PressureInputsPort<br/>hoy null"]:::prov --> P4

    Q --> R["2 · Revisión del lote<br/><i>¿cuáles confirmó? ¿duplicados?</i>"]
    R --> C["3 · Completitud<br/><i>¿qué falta por deuda?</i>"]
    C --> P4

    subgraph P4["4 · Motor P4"]
        direction TB
        EJES["C · carga mensual<br/>K · capacidad residual<br/>D · deterioro"] --> MAT["matriz de 27 celdas"]
        MAT --> FLO["floors causales<br/>RGL-020 · 021 · 022"]
    end

    P4 --> AGP["5 · Agregación de presión"]
    P4 --> SAL["6 · Salud de deuda<br/>presión + aging"]
    AGP --> EL["7 · Elegibilidad de Ruta"]
    EL --> AGR["agregación de Ruta"]
    AGR --> PL["8 · Plan bola de nieve"]
    AGR --> SIT["9 · Situaciones F1–F7"]

    AGP --> OUT
    SAL --> OUT
    PL --> OUT
    SIT --> OUT
    OUT["respuesta + escritura"]:::ok

    classDef prov fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13,stroke-width:3px
    classDef ok fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    class Q,R,C,AGP,SAL,EL,AGR,PL,SIT paso
    classDef paso fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    class EJES,MAT,FLO motor
    classDef motor fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    class IN entrada
    classDef entrada fill:#EAF4F4,stroke:#1B6B73,color:#103F43
    style P4 fill:#FFFDFD,stroke:#E6DED2
```



El orden no es casual: la **calidad va antes** que C×K×D —sin saber con qué datos se cuenta no se concluye nada— y la **elegibilidad va después** de la presión, porque el gate necesita su resultado.

---



## 3 · Los endpoints, uno tras otro

```mermaid
flowchart LR
    A["POST /debts<br/><i>o import de M01</i>"] --> B["GET /debts<br/>lista"]
    B --> C["PATCH /debts/:id<br/>completar"]
    C --> D["POST /debts/:id/confirm"]
    B --> E["POST /debts/:id/dismiss"]
    D --> F["GET /debts/summary<br/><i>¿puede ver resultado?</i>"]
    F --> G["GET /debts/route/current<br/><b>recalcula todo</b>"]
    G --> H["POST /debts/route/apply<br/><i>«Seguir plan»</i>"]
    H --> I["POST /debts/route/close-debt"]
    I --> G
    J["POST /debts/:id/payments"] -.->|"no recalcula:<br/>lo ve la llamada siguiente"| G

    classDef cap fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    classDef rut fill:#EAF4F4,stroke:#1B6B73,color:#103F43
    class A,B,C,D,E,F,J cap
    class G,H,I rut
```




| Endpoint                       | Qué hace de verdad                                                                  |
| ------------------------------ | ----------------------------------------------------------------------------------- |
| `GET /debts/route/current`     | **Recalcula el pipeline entero** y publica presión, salud, gate, plan y situaciones |
| `POST /debts/route/apply`      | Lo mismo, más el evento `seguir_plan_rd02`. **El único que activa**                 |
| `POST /debts/route/close-debt` | Confirma un cierre que ya alcanzó la condición previa, y recalcula                  |
| `GET /debts/summary`           | Sólo cuenta confirmadas y pendientes. No evalúa                                     |
| `POST /debts/:id/payments`     | Inserta el abono y baja el saldo. **No recalcula** y **no mueve D**                 |


**Ver el plan, navegarlo o simular no activan.** §7.2: «no usar un CTA visible como
sustituto del evento». Un segundo «Seguir plan» tampoco reactiva.

**El pago se registra, pero no entra al motor.** `POST /debts/:id/payments` escribe
`debt_payments` y descuenta `current_balance` en transacción; devuelve el pago, no
el estado. Como `route/current` no cachea, la llamada siguiente ve el saldo nuevo
—pero el eje **D** no se mueve: la presión y la Salud se alimentan sólo del
`PressureInputsPort`, y `debt_payments` no lo alimenta. Eso llega con M06.

---



## 4 · 🟡 Lo provisional · por qué falta M05 y M06

```mermaid
flowchart LR
    M5["MÓDULO 05 <br/>ingreso canónico · headroom"] -.-> PORT
    M6["MÓDULO 06 <br/>hecho de pago · aging"] -.-> PORT

    PORT{{"PressureInputsPort"}}:::prov
    PORT --> NULO["🟡 NullPressureInputsAdapter<br/>devuelve todo en null"]:::prov

    NULO --> R1["C sin ingreso → banda null"]
    NULO --> R2["K sin headroom → banda null"]
    NULO --> R3["D sin hecho de pago → banda null"]

    R1 & R2 & R3 --> RES["🟡 presión = no_calculable<br/>🟡 salud = sin_datos_suficientes<br/>🟡 Ruta = pendiente_datos"]:::prov

    RES --> UI["🟡 card neutra en el paso 3<br/>«Aún no podemos concluir»"]:::prov

    classDef prov fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13,stroke-width:3px
    class M5,M6 ext
    classDef ext fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    class R1,R2,R3 paso
    classDef paso fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
```



**Esto es lo correcto, no una falla.** La alternativa sería afirmarle al usuario algo que nadie calculó — que es justo lo que el contrato prohíbe.


| 🟡 Provisional                    | Se cae solo cuando…                                                        |
| --------------------------------- | -------------------------------------------------------------------------- |
| `NullPressureInputsAdapter`       | se escribe el adaptador real. **Cambia una clase, el pipeline no se toca** |
| Card neutra del paso 3            | haya presión que mostrar, y frames para Atención y Riesgo-sin-gate         |
| `sustainability-gate` sin cablear | M05 entregue el outcome prudencial                                         |
| `selected-plan` sin cablear       | exista la pantalla de simulación                                           |
| Escenarios irreproducibles en QA  | exista un adaptador de fixtures tras un flag                               |


---



## 5 · El guardrail que aparece en todas partes

Si el equipo se lleva una sola idea, que sea esta.

```mermaid
flowchart LR
    F["Falta un dato"] --> PREG{"¿hacia dónde<br/>se degrada?"}
    PREG -->|"lo favorable"| MAL["❌ prohibido"]:::mal
    PREG -->|"lo adverso"| BIEN["✅ siempre"]:::bien

    BIEN --> E1["C sin ingreso → null<br/><i>nunca C1 por defecto</i>"]
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



**La asimetría es deliberada.** Riesgo y Atención ganan con **una** deuda que los sostenga. En Control exige que **todas** hayan concluido: un solo `null` degrada a `no_calculable`. Igual con `sana` en Salud.

---



## 6 · De la presión a la pantalla

Lo que el paso 3 pinta. Dos preguntas encadenadas, no una.

```mermaid
flowchart LR
    PR{"1 · ¿cuánta presión?"} -->|en_control| A1(["seguimiento · CTA M06"])
    PR -->|atencion| A2(["revisión preventiva<br/>SIN Ruta"])
    PR -->|riesgo| G{"2 · ¿gate completo?<br/>confirmada + datos mínimos"}
    PR -->|"🟡 no calculable"| A0["🟡 card neutra<br/>«Aún no podemos concluir»"]:::prov
    G -->|no| A3(["confirmar / completar<br/>SIN Ruta"])
    G -->|sí| A4["ofrecer Ruta"]:::ok --> EV{"¿«Seguir plan»?"}
    EV -->|no| A5(["elegible, no activa"])
    EV -->|sí| A6["activa"]:::ok

    classDef dec fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    classDef ok fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    classDef prov fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13,stroke-width:3px
    class PR,G,EV dec
    class A1,A2,A3,A5 salto
    classDef salto fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
```



**Riesgo con el gate incompleto no abre Ruta.** Manda a confirmar o completar. Es la distinción que el Figma todavía no refleja — ver [req-resultado-onboarding-semaforo.md](req-resultado-onboarding-semaforo.md).

---



## 7 · Las cuatro capas


| Capa           | Qué vive ahí                      | Regla                                            |
| -------------- | --------------------------------- | ------------------------------------------------ |
| `rules/`       | 16 funciones **puras**            | Sin BD, sin Nest. Reciben el `now` por parámetro |
| `services/`    | pipeline · route.service · writer | El orden y la respuesta                          |
| `persistence/` | proyección regla → columnas       | Una regla no sabe de tablas                      |
| `ports/`       | 🟡 `PressureInputs`               | Lo que M04 **no** calcula                        |


Cada regla lleva su `RULE_VERSION`, que se persiste con el resultado: se puede saber con qué versión de la lógica se evaluó una deuda.

---



## 8 · Cómo verificarlo

```bash
cd back-walvy && npx jest src/debts
```

**438 tests en 27 suites.** Para entender una regla, leer su `.spec.ts` antes que su implementación: los nombres de los tests son la especificación en prosa.

Contrato vivo: `back-walvy/docs/api/debts/route.md` ·
Deuda abierta: [deuda-tecnica/README.md](deuda-tecnica/README.md)

---



## Glosario

- `unknownMinimumPayment` — booleano en `debt.metadata`. `true` = no se confirma (sigue `unconfirmed`). `false` = se puede `confirm`.
- `PressureInputsPort` — [`back-walvy/src/debts/ports/pressure-inputs.port.ts`](../../../../back-walvy/src/debts/ports/pressure-inputs.port.ts). La puerta por la que M04 pide lo que no calcula: ingreso y headroom (M05), hecho de pago y atraso (M06). Hoy está el `NullPressureInputsAdapter`: devuelve todo `null`. Por eso presión = `no_calculable` y la card del paso 3 es neutra. No es un bug. Se cambia el adaptador cuando M05/M06 entreguen; el pipeline no se toca.

