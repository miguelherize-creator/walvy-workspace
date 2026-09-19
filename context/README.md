# context/ — mapa de capas

Un hecho vigente tiene **un dueño** y un link desde el índice del módulo.
Si el mismo dato está en tres lados, el sistema falló.

| Capa | Qué entra | Qué no |
|---|---|---|
| **Vigente** (esta raíz + `wiki-codigo/` + `moduloNN-*/` + `cashflow/` + `qa-audits/`) | Cómo funciona hoy, deuda abierta, convenciones | Fotos de un día, Excel del cliente, docs congelados |
| [`contratos/`](contratos/) | Specs, matrices, schema de diseño, alcance MVP | Cómo está el código hoy |
| [`historico/`](historico/) | Bitácora, auditorías viejas, planes ya ejecutados | Nada que se use para decidir |

Ante una discrepancia: **código > índice del módulo > contrato > histórico**.
La fuente del esquema son las entidades TypeORM, no `contratos/db/`.
