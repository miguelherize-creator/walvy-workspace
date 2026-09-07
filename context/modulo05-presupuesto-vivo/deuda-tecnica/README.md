# M05 · Presupuesto Vivo — deuda técnica

**Revisado:** 2026-09-06 contra `documentacion/Módulo05/` (paquete v1.0 + categorías
v2.7) y contra `documentacion/modulo04-update/` (`Walvy_M04_Entrega_Kabeli_v1.0`).

No hay código de M05 todavía. Lo que sigue es deuda **de contrato**, y el primer punto es
bloqueante para M04.

---

## 1 · El paquete de M05 no incluye las entradas que M04 espera de él

**El hallazgo:** los dos paquetes del cliente se contradicen sobre qué debe producir M05.

Lo que la entrega de **M04** le asigna a M05, textual:

| Dónde | Qué dice |
|---|---|
| Documentación Funcional §6 | «M05 / Presupuesto · **Productor upstream** · Ingreso canónico y headroom/capacidad residual para K» |
| `TEC-M4-008` | «M04 consume **headroom/capacidad residual canónica M05**; K2>20%, K1>0%≤20%, K0≤0%» |
| `TEC-M4-007` | «C = servicio mensual normalizado de deuda / **ingreso mensual canónico M05**» |
| `P4-CNT-022` · SUSTAINABILITY-GATE | El **outcome prudencial** de tres estados es owner M05 |
| Hoja `05_Condiciones_y_Limites` | «**Resiliencia 3/6 meses:** M05 calcula meses de resiliencia» |

Lo que el paquete de **M05** dice sobre lo mismo: **nada**. Busqué en los ocho documentos
de la entrega —Fase 1 a 5, Anexo BDD, Consolidado y Leeme— y hay **cero menciones** de
`headroom`, `ingreso canónico`, `capacidad residual`, `outcome prudencial`, `resiliencia`
y `3/6 meses`.

La frontera M05 ↔ M04 que el paquete de M05 **sí** define va en la dirección contraria y
es de otra naturaleza:

> §22 · «**Ruta Despeje / Módulo 4** — Datos prellenados cuando la brecha afecta deuda,
> mora, liquidez crítica o capacidad de pago. No aplicar el plan automáticamente.»
>
> §23 · «**Módulo 4 · Motor de Deudas** — Mora, deuda mala, salida del rojo. M5 **deriva
> casos problemáticos**; no aplica Bola de Nieve.»

O sea: M05 se define como quien **deriva al usuario** hacia Ruta Despeje con datos
prellenados, no como el **productor upstream** de los dos ejes de la presión.

**Por qué importa ahora.** El motor P4 de M04 está completo y cableado, y no concluye por
falta de esas entradas: la presión sale `no_calculable` y la Ruta degrada a
`pendiente_datos` para todos los usuarios. Si M05 entrega su alcance tal como está
documentado, **el motor de M04 sigue sin concluir**, porque lo que le falta no está en el
alcance que M05 reconoce.

**Qué hay que hacer, y no es código.** Llevarlo a Producto y al cliente para que uno de
los dos paquetes se corrija:

1. **O el alcance de M05 incorpora** el ingreso mensual canónico, el headroom del período
   y el outcome prudencial de tres estados como outputs con contrato —lo que M04 ya
   documenta y `pressure-inputs.port.ts` ya tiene tipado.
2. **O la entrega de M04 reasigna** esos owners, y entonces hay que decir de dónde sale
   K, porque el contrato prohíbe explícitamente usar el Disponible de M02 como proxy y
   prohíbe tratar el missing como cero.

**Owner de la decisión: Producto + cliente.** No se resuelve entre M04 y M05.

> Ojo con una salida falsa: M05 sí tiene el concepto de **margen/excedente estimado**
> (`EF-015` del Anexo BDD). **No sirve como K.** Su propio contrato lo define como
> «hipótesis funcional, no causalidad absoluta», y K necesita un headroom reconciliado
> del período. Usar uno por el otro fabrica una banda de capacidad sobre una hipótesis, que
> es justo lo que el gate de calidad de M04 existe para impedir.

## 2 · Los umbrales están cerrados como regla y sin parametrizar

El cliente declara **50 / 80 / 90 / 100 / 110** «cerrados como regla producto inicial,
parametrización técnica pendiente». Los cortes no se discuten; falta decidir dónde viven
—tabla, config o constante— y con qué versión, para que un cambio quede trazable como en
M04 con su `RULE_VERSION`.

## 3 · Dos versiones de la taxonomía conviviendo

`documentacion/Módulo05/Categorias/` tiene la v2.6 y la v2.7. **La vigente es la v2.7**
(20 categorías maestras, 105 subcategorías) y el Leeme lo dice, pero las dos están en la
carpeta sin distintivo en el nombre.

Este contrato tiene consumidores fuera de M05 —`front-walvy` y Kread—, así que conviene
fijar la vigente antes de que alguien implemente contra la v2.6.

## 4 · El modelo BBDD es candidato, no cerrado

El Anexo BDD marca todas sus entidades y campos (`EF-001`…) como **funcionales
candidatos**, «a validar por BBDD, arquitectura o consultora antes de implementación». No
es deuda: es el estado declarado del paquete. Se lista para que nadie los tome por schema
aprobado — y el precedente de M04 vale acá: `context/db/modulo6.md` es documentación de
diseño, y ante discrepancia gana el código.

---

## Cómo verificar este archivo

Un `grep` directo sobre los `.docx` da 0 para todo, porque están comprimidos. Hay que
extraer el texto primero:

```bash
cd documentacion/Módulo05
python3 - <<'EOF'
import zipfile, re, glob, html
texto = ""
for f in glob.glob("*.docx"):
    x = zipfile.ZipFile(f).read('word/document.xml').decode('utf-8')
    texto += html.unescape(re.sub(r'<[^>]+>', ' ', x)).lower()
for t in ["headroom", "canónic", "capacidad residual", "prudencial",
          "resiliencia", "3 meses",
          "margen", "liquidez"]:          # los dos últimos son el control
    print(f"{t:22} {texto.count(t)}")
EOF
```

Los seis primeros deben dar **0** y los dos de control **más de 0** — si el control
también da 0, la extracción falló y el resultado no vale.

```bash
# Lo que M04 espera, en el tipo que ya existe
grep -n "M05" back-walvy/src/debts/ports/pressure-inputs.port.ts
```

Contexto del módulo: [`../contexto/README.md`](../contexto/README.md) ·
Contraparte en M04: [`../../modulo04-motor-deudas/deuda-tecnica/README.md`](../../modulo04-motor-deudas/deuda-tecnica/README.md)
