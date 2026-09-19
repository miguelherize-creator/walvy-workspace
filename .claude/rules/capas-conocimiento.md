# Capas de la memoria

Mapa: `context/README.md`. Un hecho vigente tiene un dueño.

| Capa | Dónde | Regla |
|---|---|---|
| Vigente | `wiki-codigo/`, `moduloNN-*/`, `cashflow/`, transversales, `qa-audits/` | Se actualiza con el código. Si no se verifica con un comando, no entra. |
| Contrato | `context/contratos/` | Se versiona. No se reescribe un Excel del cliente. |
| Histórico | `context/historico/` | Append-only. **Nunca es fuente para decidir hoy.** |

Ante discrepancia: código > índice del módulo > contrato > histórico.
El esquema lo ganan las entidades TypeORM, no `contratos/db/`.
Si un documento vigente quedó viejo, es un defecto: márcalo o actualizalo.
