# Onboarding G2 → G5 — diagramas del flujo real

Convención: **verde** = implementado y conforme · **naranja** = brecha nuestra · **rojo punteado** = falta decisión de Producto o no existe actor.

---

## 1. Recorrido completo G2 → G5

```mermaid
flowchart TD
    classDef ok fill:#e8f5e9,stroke:#2e7d32,color:#1b3c1e
    classDef gap fill:#fff3e0,stroke:#e65100,color:#4a2600
    classDef dec fill:#fdecea,stroke:#c62828,color:#5a1512,stroke-dasharray: 4 3

    START(["Foco guardado → declara G2_carga"]):::ok

    subgraph G2["G2_carga · onboarding-doc"]
        A1["Picker: PDF · XLSX · CSV<br/>máx 15 · máx 30 MB"]:::ok
        A2["Filtros locales:<br/>duplicado por NOMBRE · vigencia por NOMBRE"]:::gap
        A3{"¿PDF protegido?"}
        A4["Auto-unlock RUT · DP-003<br/>1 RUT sin DV → 2 últimos 4 → 3 primeros 4"]:::ok
        A5["Contraseña manual · reintento libre"]:::ok
        A6["Vault en memoria<br/>nunca en params, logs ni checkpoints"]:::ok
        A7(["CTA Analizar mis documentos"]):::ok
    end

    subgraph G3["G3_analisis · onboarding-analyzing"]
        B0["Declara G3_analisis + importAttempted<br/>al iniciar la cola"]:::ok
        B1["Cola en serie, 1 documento a la vez<br/>ver diagrama 2"]:::ok
        B2{"Resultado por documento"}
        B3["parsed → importId a la lista"]:::ok
        B4["wrong_password → rebote a G2"]:::ok
        B5["failed: non_processable · outdated · transient"]:::ok
        B6["timeout 120 s → sigue en background,<br/>la cola continúa"]:::ok
    end

    subgraph G4["G4_revision · onboarding-analysis"]
        C1["GET resumen combinado por importIds"]:::ok
        C2["5 indicadores con estado, origen y confianza"]:::ok
        C3["evaluateSufficiencyGate<br/>ver diagrama 3"]:::ok
        C4["Checklist Lo que detectamos<br/>sólo Detectado / Por confirmar"]:::gap
        C5{"Salida del gate"}
        C6["Agregar más documentos → recalcula"]:::ok
    end

    subgraph G5["G5_diagnostico · onboarding-first-ready"]
        D1["Semáforo de salud: ratio egreso/ingreso<br/>DP-006 · menor a 0,90 en control · 0,90 a 1,00 atención · 1,00 o más riesgo"]:::ok
        D2["Sin ingreso o mes sin cerrar → no evaluable<br/>Sin diagnóstico, nunca rojo · V56"]:::ok
        D3["Nadie declara G5_diagnostico"]:::dec
        D4["financial_profile_completed y min_doc_threshold_met<br/>sin actor → el onboarding no cierra · issue 68"]:::dec
    end

    HOME(["Home / tabs"]):::ok
    PAUSA(["Postergar: resumeState ready_to_resume<br/>+ resumeContext jobId"]):::ok

    START --> A1 --> A2 --> A3
    A3 -- sí --> A4
    A4 -- abre --> A6
    A4 -- no abre --> A5 --> A6
    A3 -- no --> A7
    A6 --> A7 --> B0 --> B1 --> B2
    B2 --> B3
    B2 --> B4 -.-> A5
    B2 --> B5
    B2 --> B6
    B3 --> C1
    B5 --> C1
    B6 --> C1
    C1 --> C2 --> C3 --> C5
    C3 --> C4
    C5 -- "complete / partial permitido" --> D1
    C5 -- "blocked / partial bloqueado" --> C6
    C6 --> C1
    D1 --> D2
    D1 --> HOME
    D3 -.-> D4
    G2 -.-> PAUSA
    G3 -.-> PAUSA
    G4 -.-> PAUSA
    PAUSA --> HOME
```

---

## 2. Procesamiento de un documento dentro de G3

```mermaid
flowchart TD
    classDef ok fill:#e8f5e9,stroke:#2e7d32,color:#1b3c1e
    classDef gap fill:#fff3e0,stroke:#e65100,color:#4a2600
    classDef dec fill:#fdecea,stroke:#c62828,color:#5a1512,stroke-dasharray: 4 3

    U["POST upload · archivo + pdfPassword opcional"]:::ok
    UN["Desbloqueo del PDF en memoria<br/>la clave no se persiste ni se loguea"]:::ok
    H["sha256 del contenido ya desbloqueado"]:::ok
    D{"Dedup DynamoDB<br/>PK = userId + fileHash"}
    D1["processed → reusa el importId<br/>sin reprocesar"]:::ok
    D1B["No informa al usuario que ya estaba cargado<br/>DP-004 lo pide"]:::gap
    D2["libre → reserva pending, TTL 900 s"]:::ok
    S3["Sube a S3 · SSE-S3, sin acceso público<br/>lifecycle 30 días"]:::ok
    K["Kread: clasifica banco y extrae"]:::ok

    subgraph TIPOS["Tipos de documento que Kread ya soporta"]
        T1["Cartola bancaria<br/>metadata + summary + transactions"]:::ok
        T2["Estado de cuenta TCR<br/>transactions + debts 1"]:::dec
        T3["Informe CMF<br/>sólo debts N"]:::dec
    end

    KR["KreadFileResult que lee el backend:<br/>metadata · account_holder · summary · transactions"]:::gap
    IGN["document_type y debts no existen en el tipo<br/>→ se ignoran en silencio"]:::gap
    L["Líneas normalizadas → import_line_item"]:::ok
    P{"Polling de estado<br/>modal 15 s · 2º modal 60 s · timeout 120 s"}
    PG["Umbrales aprobados 45/90 s sembrados<br/>en rule_parameter, sin consumidor · issue 94"]:::gap
    OK["parsed → confirmProcessed, borra el objeto de S3"]:::ok
    FAIL["failed → releasePending, permite retry<br/>failure_reason: non_processable · outdated · transient"]:::ok
    DET["No se retiene la huella del no procesable<br/>determinista ni la versión del procesador"]:::gap
    TO["timeout → deja de esperar, no falla<br/>el backend sigue procesando"]:::ok
    AV["Ningún aviso al terminar, y la UI lo promete · issue 95"]:::gap

    U --> UN --> H --> D
    D -- ya procesada --> D1 --> D1B
    D -- libre --> D2 --> S3 --> K
    T1 --> K
    T2 --> K
    T3 --> K
    K --> KR --> IGN
    KR --> L --> P
    P -.-> PG
    P --> OK --> AV
    P --> FAIL --> DET
    P --> TO --> AV
```

---

## 3. El gate de suficiencia de G4

```mermaid
flowchart TD
    classDef ok fill:#e8f5e9,stroke:#2e7d32,color:#1b3c1e
    classDef gap fill:#fff3e0,stroke:#e65100,color:#4a2600
    classDef out fill:#e3f2fd,stroke:#1565c0,color:#0d3c61

    L["Líneas normalizadas del batch"]:::ok
    I1["1 · ingreso_principal<br/>líneas de ingreso"]:::ok
    I2["4 · movimientos_recientes<br/>TODAS las líneas, sin ventana temporal"]:::gap
    I3["2 · compromisos_base<br/>gastos flowType fixed"]:::ok
    I4["3 · pagos_recurrentes<br/>MISMO conjunto que compromisos"]:::gap
    I5["5 · instrumentos_pago<br/>cualquier gasto"]:::gap

    E["Estado por indicador desde classificationStatus:<br/>detectado · por_confirmar · manual_asistido · no_detectado<br/>+ dataOrigin + confidence"]:::ok

    Q0{"¿Hay documento usable?"}
    B0["blocked · sin_documento<br/>o documento_no_procesable · V52"]:::out
    Q1{"¿Ingreso y movimientos usables?<br/>siempre requeridos, sin sustituto"}
    B1["blocked · ingreso_faltante<br/>o movimientos_faltantes · V51"]:::out
    Q2{"¿Al menos uno del par<br/>compromisos / pagos recurrentes?"}
    B2["blocked · pagos_compromisos_insuficientes · V51"]:::out
    Q3{"¿Todos plenos y sin<br/>confianza insuficiente?"}
    R1["complete · sufficient<br/>CTA Comenzar diagnóstico · V48"]:::out
    R2["partial permitido · con advertencias<br/>V49"]:::out
    R3["partial bloqueado · V50<br/>el gate no lo emite: sale como blocked"]:::gap

    L --> I1 & I2 & I3 & I4 & I5 --> E
    E --> Q0
    Q0 -- no --> B0
    Q0 -- sí --> Q1
    Q1 -- falta uno --> B1
    Q1 -- ambos --> Q2
    Q2 -- ninguno --> B2
    Q2 -- al menos uno --> Q3
    Q3 -- sí --> R1
    Q3 -- no --> R2
    Q3 -.-> R3
```

**Instrumentos de pago no aparece en ninguna decisión**: es importante pero nunca crítico, sólo suma advertencia. Y el par «basta uno» hoy es degenerado, porque sus dos indicadores salen del mismo conjunto de líneas.

---

## 4. Lo que estos diagramas dejan a la vista

| Punto | Diagrama | Estado |
|---|---|---|
| Contraseñas fuera de params y logs (`DP-003`) | 1 | Cerrado |
| Dedup por huella de contenido por usuario (`DP-004`) | 2 | Cerrado, salvo avisar al usuario y el retén del determinista |
| Umbrales 45/90 s configurables (`ONB-013`) | 2 | Brecha · #94 |
| Aviso al terminar el análisis | 2 | Brecha · #95 |
| `document_type` y `debts` de Kread | 2 | Brecha de contrato: el tipo del backend no los lee |
| Estado, origen y confianza por indicador (`RGL-013`) | 3 | Backend cerrado; la UI muestra 2 de 6 estados |
| Par compromisos / pagos recurrentes separable | 3 | Brecha: sin esto `V49` vs `V50` no es validable |
| `partial_bloqueado` como etiqueta | 3 | Brecha de vocabulario, no de comportamiento |
| Cierre del onboarding | 1 | Sin actor · #68 |
