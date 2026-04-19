#!/usr/bin/env node
/**
 * split-csv-por-modulo.js
 *
 * Lee el CSV de alcance MVP de Walvy y genera un archivo Markdown
 * por cada módulo encontrado en la columna "Módulos".
 *
 * Uso:
 *   node utils/scripts/split-csv-por-modulo.js
 *
 * Salida:
 *   DB/requerimientos/output/modulo-<N>-<nombre>.md
 */

const fs = require('fs');
const path = require('path');

// ─────────────────────────────────────────────
// Rutas
// ─────────────────────────────────────────────
const CSV_PATH = path.join(
  __dirname,
  '../../DB/requerimientos',
  'MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv'
);
const OUTPUT_DIR = path.join(__dirname, '../../DB/requerimientos/output');

// ─────────────────────────────────────────────
// Parser CSV RFC 4180 (soporta celdas multilínea)
// ─────────────────────────────────────────────
function parseCSV(raw) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  let i = 0;

  while (i < raw.length) {
    const ch = raw[i];

    if (inQuotes) {
      if (ch === '"') {
        // ¿comilla doble escapada ("") o cierre de campo?
        if (raw[i + 1] === '"') {
          field += '"';
          i += 2;
        } else {
          inQuotes = false;
          i++;
        }
      } else {
        field += ch;
        i++;
      }
    } else {
      if (ch === '"') {
        inQuotes = true;
        i++;
      } else if (ch === ',') {
        row.push(field.trim());
        field = '';
        i++;
      } else if (ch === '\r' && raw[i + 1] === '\n') {
        row.push(field.trim());
        rows.push(row);
        row = [];
        field = '';
        i += 2;
      } else if (ch === '\n') {
        row.push(field.trim());
        rows.push(row);
        row = [];
        field = '';
        i++;
      } else {
        field += ch;
        i++;
      }
    }
  }

  // última celda / fila sin salto de línea final
  if (field !== '' || row.length > 0) {
    row.push(field.trim());
    rows.push(row);
  }

  return rows;
}

// ─────────────────────────────────────────────
// Helpers de presentación
// ─────────────────────────────────────────────
function slug(name) {
  return name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function section(label, value) {
  if (!value) return '';
  return `\n**${label}:**\n${value}\n`;
}

function hr() {
  return '\n---\n';
}

// ─────────────────────────────────────────────
// Genera el bloque Markdown de una fila
// ─────────────────────────────────────────────
function rowToMarkdown(headers, row) {
  const get = (name) => {
    const idx = headers.findIndex(
      (h) => h.toLowerCase().includes(name.toLowerCase())
    );
    return idx !== -1 ? (row[idx] || '') : '';
  };

  const etapa        = get('Etapa');
  const func         = get('Funcionalidad');
  const accion       = get('Acción') || get('Accion');
  const responsable  = row[headers.findIndex(h => h === '')] || '';   // col 4 vacía
  const incluye      = get('Incluye');
  const noIncluye    = get('No incluye');
  const adicionales  = get('Adicionales');
  const trazab       = get('Trazabilidad');
  const objetivo     = get('Objetivo');
  const resultado    = get('Resultado visible');
  const definicion   = get('Definición') || get('Definicion');
  const ux           = get('mostrarse') || get('UX');
  const criterio     = get('Criterio');
  const guardrails   = get('Guardrails');
  const actLeo       = get('Leonardo');
  const actMig       = get('Miguel');
  const estimacion   = get('Estimacion') || get('Estimación');

  const parts = [];

  // Sub-encabezado según lo que tenga datos
  if (etapa || func || accion) {
    const titulo = [etapa, func, accion].filter(Boolean).join(' › ');
    parts.push(`\n### ${titulo}`);
  }
  if (responsable) parts.push(`\n> **Responsable:** ${responsable}`);

  parts.push(section('✅ Incluye', incluye));
  parts.push(section('❌ No incluye', noIncluye));
  parts.push(section('Adicionales', adicionales));
  parts.push(section('Trazabilidad', trazab));
  parts.push(section('Objetivo estratégico', objetivo));
  parts.push(section('Resultado visible para el usuario', resultado));
  parts.push(section('Definición funcional detallada', definicion));
  parts.push(section('UX / UI', ux));
  parts.push(section('Criterio de aceptación MVP / QA', criterio));
  parts.push(section('Guardrails de alcance', guardrails));
  parts.push(section('Actividades Leonardo', actLeo));
  parts.push(section('Actividades Miguel', actMig));
  parts.push(section('Estimación de tiempos', estimacion));

  return parts.filter(Boolean).join('');
}

// ─────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────
function main() {
  // 1. Leer y parsear CSV
  const raw = fs.readFileSync(CSV_PATH, 'utf-8');
  const rows = parseCSV(raw);

  if (rows.length < 2) {
    console.error('CSV vacío o sin datos.');
    process.exit(1);
  }

  // 2. Extraer cabeceras (primera fila)
  const headers = rows[0];
  console.log(`Cabeceras detectadas (${headers.length}):`);
  headers.forEach((h, i) => console.log(`  [${i}] ${h || '(vacío)'}`));

  // 3. Agrupar filas por módulo (forward-fill del número de módulo)
  const modulos = {};          // { "1": { nombre, filas[] }, ... }
  let currentModulo = null;
  let currentNombre = null;

  for (let r = 1; r < rows.length; r++) {
    const row = rows[r];
    if (!row || row.every(c => c === '')) continue;   // fila vacía

    const moduloRaw = row[0];

    if (moduloRaw && /^\d+$/.test(moduloRaw)) {
      // Nueva sección de módulo
      currentModulo = moduloRaw;
      currentNombre = row[1] || `Módulo ${moduloRaw}`;
      if (!modulos[currentModulo]) {
        modulos[currentModulo] = { nombre: currentNombre, filas: [] };
      }
    }

    if (currentModulo) {
      modulos[currentModulo].filas.push(row);
    }
  }

  const moduloKeys = Object.keys(modulos).sort((a, b) => Number(a) - Number(b));
  console.log(`\nMódulos encontrados: ${moduloKeys.join(', ')}`);

  // 4. Crear directorio de salida
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  // 5. Generar un archivo Markdown por módulo
  for (const key of moduloKeys) {
    const { nombre, filas } = modulos[key];
    const filename = `modulo-${key}-${slug(nombre)}.md`;
    const outPath = path.join(OUTPUT_DIR, filename);

    const lines = [];
    lines.push(`# Módulo ${key} — ${nombre}`);
    lines.push('');
    lines.push(`> Fuente: \`DB/requerimientos/MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv\``);
    lines.push('');

    for (const fila of filas) {
      lines.push(rowToMarkdown(headers, fila));
      lines.push(hr());
    }

    fs.writeFileSync(outPath, lines.join('\n'), 'utf-8');
    console.log(`  ✓ ${filename}  (${filas.length} filas)`);
  }

  // 6. Generar índice general
  const indexPath = path.join(OUTPUT_DIR, 'index.md');
  const indexLines = [
    '# Walvy MVP — Índice de módulos',
    '',
    '| Módulo | Nombre | Archivo |',
    '|--------|--------|---------|',
  ];
  for (const key of moduloKeys) {
    const { nombre } = modulos[key];
    const filename = `modulo-${key}-${slug(nombre)}.md`;
    indexLines.push(`| ${key} | ${nombre} | [${filename}](./${filename}) |`);
  }
  fs.writeFileSync(indexPath, indexLines.join('\n') + '\n', 'utf-8');
  console.log(`  ✓ index.md`);

  console.log(`\nSalida generada en: ${OUTPUT_DIR}`);
}

main();
