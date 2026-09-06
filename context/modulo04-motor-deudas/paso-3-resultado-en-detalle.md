# El paso 3 en detalle · qué decide el color del Resultado

Zoom sobre el nodo `RESULT` de [`recorrido-de-pantallas.md`](../wiki-codigo/recorrido-de-pantallas.md),
donde el recorrido lo resume como una sola pregunta binaria: *«¿se habilita la Ruta?»*.
No es binaria. Son cinco lecturas, y hoy la app solo sabe pintar dos.

---

## 1 · Lo que pasa hoy (el defecto)

```mermaid
flowchart LR
    REV["Revisión de deudas"] --> API{"GET /debts/route/current<br/>¿qué responde?"}

    API -->|"eligibility:<br/>pendiente_datos"| VERDE
    API -->|"eligibility:<br/>no_elegible"| VERDE
    API -->|"eligibility:<br/>elegible · activa"| AMBAR

    VERDE["🟢 En Control<br/><i>«Tus pagos están al día»</i>"]:::roto
    AMBAR["🟡 Atención<br/><i>«Detectamos un atraso confirmado»</i>"]:::roto

    VERDE --> PAGOS(["Revisar mis pagos<br/>M06 · no existe"])
    AMBAR --> RUTA["Ver Ruta Despeje"]

    REAL{{"En QA real<br/>SIEMPRE cae acá"}}:::nota
    REAL -.-> VERDE

    classDef roto fill:#FDECEA,stroke:#AB3737,color:#7A1F1F
    classDef nota fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    class REV,RUTA m4
    classDef m4 fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    class PAGOS salto
    classDef salto fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    class API decision
    classDef decision fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
```

**El problema:** `pendiente_datos` significa *«el motor no pudo evaluar»*, y la app
lo pinta como *«tus pagos están al día»*. Son cosas opuestas. Y es el único camino
que ocurre hoy, porque faltan los insumos de M05 y M06.

---

## 2 · Lo que dice el contrato (OD-03)

El color no sale de la elegibilidad. Sale de **dos preguntas separadas**.

```mermaid
flowchart LR
    REV["Revisión de deudas"] --> P{"1 · ¿Cuánta presión?<br/>motor P4 · C×K×D"}

    P -->|"no pudo concluir"| N
    P -->|en_control| V
    P -->|atencion| A
    P -->|riesgo| G{"2 · ¿El gate está completo?<br/>confirmada + datos mínimos"}

    G -->|"no"| R1
    G -->|"sí"| R2

    N["⚪️ No calculable<br/><i>no se afirma nada</i>"]:::gris
    V["🟢 En Control"]:::verde
    A["🟡 Atención"]:::ambar
    R1["🔴 Riesgo<br/><i>gate incompleto</i>"]:::rojo
    R2["🔴 Riesgo<br/><i>gate completo</i>"]:::rojo

    N --> CN(["¿…?<br/>sin definir"]):::roto
    V --> CV(["Revisar mis pagos<br/>M06"])
    A --> CA(["Revisión preventiva<br/>SIN Ruta"])
    R1 --> CR1(["Confirmar / completar<br/>SIN Ruta"])
    R2 --> CR2["Ver Ruta Despeje"]

    classDef verde fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    classDef ambar fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    classDef rojo fill:#FDECEA,stroke:#AB3737,color:#7A1F1F
    classDef gris fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    classDef roto fill:#FDECEA,stroke:#AB3737,color:#7A1F1F
    class REV,CR2 m4
    classDef m4 fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    class CV,CA,CR1 salto
    classDef salto fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    class P,G decision
    classDef decision fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
```

**Los dos hallazgos que esto revela:**

1. **El rojo se parte en dos.** Mismo color, distinto CTA. *«Riesgo con gate
   bloqueado ≠ CTA Ruta»* — Anexo BDD §19.5.
2. **Amarillo no abre Ruta.** Figma lo dibujó como si sí. *«No fabricar Ruta desde
   Atención o datos insuficientes.»*

---

## 3 · Dónde estamos parados

```mermaid
flowchart LR
    subgraph HECHO["✅ Fase 1 · PR back#243"]
        B1["El back ya publica<br/>pressure + gate + health"]
    end

    subgraph AHORA["🔨 Fase 2a · lo que sigue"]
        F1["El front deja de pintar<br/>verde sin evidencia"]
    end

    subgraph TRABA["⛔️ Fase 2b · bloqueada"]
        D1["Frames de 🟡, 🔴-gate<br/>y ⚪️ no existen"]
    end

    B1 --> F1
    F1 --> Q{"¿Y qué pinta<br/>en su lugar?"}:::decision
    Q -->|"única con frame"| NADA["No hay diseño<br/>para ⚪️ No calculable"]:::roto
    D1 -.-> Q

    NADA --> O1(["a · Card neutra<br/>copy explícito"])
    NADA --> O2(["b · Ocultar la card"])
    NADA --> O3(["c · Esperar el frame"])

    classDef roto fill:#FDECEA,stroke:#AB3737,color:#7A1F1F
    classDef decision fill:#FFF4E5,stroke:#B98A2E,color:#6B4E13
    class B1 verde
    classDef verde fill:#F1F8F2,stroke:#2E7D4F,color:#14401F
    class F1 m4
    classDef m4 fill:#FFF6F2,stroke:#EE8D78,color:#7A2E1F
    class D1,O1,O2,O3 salto
    classDef salto fill:#F4F1EC,stroke:#A6BFC0,color:#4C555C
    style HECHO fill:#FFFDFD,stroke:#E6DED2
    style AHORA fill:#FFFDFD,stroke:#E6DED2
    style TRABA fill:#FFFDFD,stroke:#E6DED2
```

**La ironía:** de los cinco escenarios, el único que ocurre hoy en la app real
—⚪️ No calculable— es justamente el que **no tiene frame en Figma**. Diseño nunca
lo dibujó porque nadie lo previó: se asumió que siempre habría presión que mostrar.

---

## 4 · Corrección al recorrido

La línea del recorrido general:

> `RESULT -->|"sí: Ver Ruta Despeje"| RUTA`
> `RESULT -->|"no: Revisar mis pagos"| PAGOS`

Queda como histórica. El binario describe el **CTA**, no la pantalla: hay tres
lecturas distintas que llevan a «no Ruta» (🟢 En Control, 🟡 Atención, 🔴 gate
incompleto) y cada una dice algo diferente al usuario.
