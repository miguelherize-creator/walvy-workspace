# -*- coding: utf-8 -*-
import copy, shutil
import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from ajustes import AJUSTES, TRAZA

SRC = 'base.xlsx'
OUT = 'Walvy_M1_Matriz_Validacion_Tecnica_v1.1.xlsx'
shutil.copy(SRC, OUT)

wb = openpyxl.load_workbook(OUT)
ws = wb['01 Validación Técnica']
HDR = 4
COL = {ws.cell(HDR, c).value: c for c in range(1, ws.max_column + 1) if ws.cell(HDR, c).value}

# Guardia: las columnas que se van a escribir y las que NO se tocan.
EDITABLES = ['Control a validar', 'Subcriterios incluidos', 'Origen',
             'Relación funcional M1', 'Acción / complemento requerido']
INTOCABLES = ['ETAPA 1 · Validación alcance Walvy', 'Comentario alcance Walvy',
              'ETAPA 2 · Validación cumplimiento Walvy', 'Comentario cumplimiento Walvy',
              'Estado de cierre', '¿Requiere volver a Producto?', 'Aplicabilidad']
for k in EDITABLES + INTOCABLES:
    assert k in COL, f'columna ausente: {k}'
K = {'C': COL['Control a validar'], 'D': COL['Subcriterios incluidos'], 'E': COL['Origen'],
     'F': COL['Relación funcional M1'], 'P': COL['Acción / complemento requerido']}

filas = {ws.cell(r, 1).value: r for r in range(HDR + 1, ws.max_row + 1) if ws.cell(r, 1).value}
antes = {tid: {k: ws.cell(filas[tid], c).value for k, c in K.items()} for tid in AJUSTES}
intocables_antes = {tid: {k: ws.cell(filas[tid], COL[k]).value for k in INTOCABLES} for tid in filas}

tocadas = 0
for tid, campos in AJUSTES.items():
    r = filas[tid]
    for letra, valor in campos.items():
        ws.cell(r, K[letra]).value = valor   # .value preserva el estilo existente
        tocadas += 1

# La hoja 02 duplica Control técnico y Relación funcional como literales: se sincroniza.
ws2 = wb['02 Relación Producto']
H2 = 4
C2 = {ws2.cell(H2, c).value: c for c in range(1, ws2.max_column + 1) if ws2.cell(H2, c).value}
filas2 = {ws2.cell(r, 1).value: r for r in range(H2 + 1, ws2.max_row + 1) if ws2.cell(r, 1).value}
sinc = 0
for tid, campos in AJUSTES.items():
    r = filas2[tid]
    ws2.cell(r, C2['Control técnico']).value = campos['C']
    ws2.cell(r, C2['Relación funcional M1']).value = campos['F']
    sinc += 2

# Hoja nueva con la traza comentario -> ajuste, para que la revisión final sea acotada.
if '05 Ajustes v1.1' in wb.sheetnames:
    del wb['05 Ajustes v1.1']
ws5 = wb.create_sheet('05 Ajustes v1.1')
plantilla = ws['C7']                      # celda de referencia para copiar convenciones
FUENTE = plantilla.font.name or 'Carlito'
TAM = plantilla.font.sz or 11

ws5['A1'] = 'Trazabilidad de los 7 ajustes incorporados en v1.1'
ws5['A1'].font = Font(name=FUENTE, sz=TAM + 2, bold=True)
ws5['A2'] = ('Un renglón por control marcado «Ajustar control» en la revisión de alcance de Walvy. '
             'Sólo se editaron las columnas C, D, E, F y P de la hoja 01 (y su espejo en la hoja 02). '
             'No se tocaron las columnas de validación ni comentario de Walvy, ni «Estado de cierre», '
             'que es una fórmula derivada de la columna I y se actualizará sola al aceptarse el alcance.')
ws5['A2'].font = Font(name=FUENTE, sz=TAM, italic=True)
ws5['A2'].alignment = Alignment(wrap_text=True, vertical='top')
ws5.merge_cells('A2:E2')
ws5.row_dimensions[2].height = 46

CABS = ['ID Técnico', 'Comentario de alcance Walvy (resumen)', 'Qué se ajustó en v1.1',
        'Estado en código', 'Referencia']
gris = PatternFill('solid', fgColor='D9D9D9')
borde = Border(*[Side(style='thin', color='BFBFBF')] * 4)
for i, t in enumerate(CABS, start=1):
    c = ws5.cell(4, i, t)
    c.font = Font(name=FUENTE, sz=TAM, bold=True)
    c.alignment = Alignment(wrap_text=True, vertical='top')
    c.fill = gris
    c.border = borde

REF = {
 'TEC-M1-003': 'RT-08 · TR-CONS-01 · M01-PRV-001/002/003',
 'TEC-M1-007': 'RT-04.1 · M1-DP-009 · PP-07',
 'TEC-M1-013': 'AX-M1-003 · M01-RGL-012/013 · PR #101, PR #103',
 'TEC-M1-014': 'AX-M1-004 · M1-DP-006 · M01-RGL-015',
 'TEC-M1-016': 'TR-SEC-01 · TR-MOB-01 · TR-AWS-01 · TR-DB-01 · RT-01, RT-05',
 'TEC-M1-021': 'TR-RET-01 · TR-DOC-01 · RT-04 · Anexo 10',
 'TEC-M1-023': 'TR-CIS-01 · Solicitud técnica Walvy',
}
for i, tid in enumerate(sorted(AJUSTES), start=5):
    resumen, ajuste, estado = TRAZA[tid]
    for j, val in enumerate([tid, resumen, ajuste, estado, REF[tid]], start=1):
        c = ws5.cell(i, j, val)
        c.font = Font(name=FUENTE, sz=TAM, bold=(j == 1))
        c.alignment = Alignment(wrap_text=True, vertical='top')
        c.border = borde
    ws5.row_dimensions[i].height = 120

for col, w in zip('ABCDE', [14, 62, 62, 62, 40]):
    ws5.column_dimensions[col].width = w
ws5.freeze_panes = 'A5'
ws5.sheet_view.showGridLines = False

# Versión en la portada y el título de la hoja 01
for hoja, celda in [('00 Cómo usar', 'A1'), ('01 Validación Técnica', 'A1')]:
    h = wb[hoja]; v = h[celda].value
    if isinstance(v, str) and 'v1.0' in v:
        h[celda] = v.replace('v1.0', 'v1.1')
        print(f'  portada {hoja}!{celda}: {h[celda].value}')

wb.save(OUT)
print(f'\nceldas escritas hoja 01: {tocadas} | sincronizadas hoja 02: {sinc}')

# ---- Verificación sobre el archivo guardado ----
print('\n=== verificación ===')
v = openpyxl.load_workbook(OUT)
vs, vs2 = v['01 Validación Técnica'], v['02 Relación Producto']
print('hojas:', v.sheetnames)

ok = True
for tid in AJUSTES:
    r = filas[tid]
    for k in INTOCABLES:
        if vs.cell(r, COL[k]).value != intocables_antes[tid][k]:
            print(f'  ALTERADO {tid} {k}'); ok = False
for tid, r in filas.items():
    for k in INTOCABLES:
        if vs.cell(r, COL[k]).value != intocables_antes[tid][k]:
            print(f'  ALTERADO (no editado) {tid} {k}'); ok = False
print('columnas de Walvy y Estado de cierre intactos en las 23 filas:', ok)

form = sum(1 for row in vs.iter_rows() for c in row
           if isinstance(c.value, str) and c.value.startswith('='))
print(f'fórmulas conservadas en hoja 01: {form} (esperado 23)')

cambiadas = sum(1 for tid in AJUSTES for k in K
                if vs.cell(filas[tid], K[k]).value != antes[tid][k])
print(f'celdas efectivamente distintas del original: {cambiadas}')

for tid in ['TEC-M1-013', 'TEC-M1-021']:
    r = filas[tid]
    print(f'\n  {tid} F -> {vs.cell(r, K["F"]).value}')
    print(f'  {tid} hoja02 C -> {vs2.cell(filas2[tid], C2["Relación funcional M1"]).value}')
    print(f'  {tid} estado de cierre (fórmula intacta): {str(vs.cell(r, COL["Estado de cierre"]).value)[:60]}...')
