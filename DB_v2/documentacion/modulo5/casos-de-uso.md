# Módulo 5 — Casos de Uso

**Módulo:** Catálogos, Ingesta y Movimientos  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 5

**Actores:**
- **Usuario** — persona que usa la app Walvy
- **Sistema** — job de ingesta/parseo que procesa archivos

---

## CU-01 — Registrar movimiento manual

**Actor principal:** Usuario  
**Precondiciones:** Usuario autenticado.

### Flujo principal

```
1. Usuario navega a "Movimientos" → "Nuevo movimiento".
2. Ingresa: fecha, descripción, dirección (ingreso/egreso), monto, categoría.
3. App llama POST /movements.
4. Backend crea financial_movement con source_type = 'manual', status = active.
5. Si no se seleccionó categoría:
   → Agrega a movement_review_queue con review_reason = uncategorized.
6. App muestra el movimiento en el listado.
```

---

## CU-02 — Importar cartola

**Actor principal:** Usuario  
**Precondiciones:** Usuario autenticado.

### Flujo principal

```
1. Usuario navega a "Importar" → selecciona banco y sube archivo.
2. App llama POST /imports con el archivo.
3. Backend:
   a. Sube el archivo a S3 → storage_path.
   b. Crea file_upload con file_status = pending.
   c. Encola job de parseo con file_upload_id.
4. App muestra: "Procesando tu cartola…"
5. Job de parseo:
   a. Parsea el archivo según el provider.
   b. Crea import_line_items (una por fila) con user_review_status = pending.
   c. Calcula source_fingerprint por ítem para deduplicación.
   d. Genera movement_classification_suggestions por ítem.
   e. Actualiza file_upload.file_status = processed.
6. App notifica al usuario: "Cartola lista para revisión. N movimientos encontrados."
```

### Flujo alternativo — Duplicados detectados

```
5c. Algún source_fingerprint ya existe en financial_movement.
→ El import_line_item se marca como posible_duplicate = true.
→ El usuario ve el ítem con aviso "Posible duplicado" y puede igualmente aceptarlo o rechazarlo.
```

---

## CU-03 — Revisar importación

**Actor principal:** Usuario  
**Precondiciones:** Existe un `file_upload` con `file_status = processed`.

### Flujo principal

```
1. Usuario abre la pantalla de revisión de importación.
2. App muestra lista de import_line_items con status = pending.
   Cada ítem muestra: fecha, descripción, monto y la categoría sugerida.
3. Usuario puede:
   a. Aceptar ítem → user_review_status = accepted.
   b. Rechazar ítem → user_review_status = rejected.
   c. Editar y aceptar → user_review_status = edited.
4. Al aceptar (o aceptar-editado):
   Backend crea financial_movement con:
   - source_type = document
   - category = la sugerida o la editada por el usuario
   - classification_method = 'assisted' (si aceptó sugerencia) o 'manual' (si editó)
5. Usuario toca "Confirmar todos" para aceptar el resto en bloque.
6. gamification_events: statement_imported (al completar la revisión).
```

---

## CU-04 — Categorizar movimiento

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario toca un movimiento sin categoría (o quiere cambiarlo).
2. App muestra el árbol de categorías (raíz → hojas).
3. Usuario selecciona categoría hoja.
4. App llama PATCH /movements/{id} { category_id, category_leaf_id }.
5. Backend:
   a. Actualiza financial_movement.category_id y category_leaf_id.
   b. classification_method = 'manual'.
   c. INSERT en movement_classification_history con old/new category.
   d. Si estaba en movement_review_queue por uncategorized: resolved_at = now().
6. App actualiza el movimiento en pantalla.
```

---

## CU-05 — Revisar movimientos pendientes

**Actor principal:** Usuario

### Flujo principal

```
1. Home o pantalla de movimientos muestra badge "X movimientos por revisar".
2. Usuario abre la cola de revisión.
3. App llama GET /movements/review-queue.
4. Backend retorna movement_review_queue con review_status = pending,
   ordenado por priority_level ASC.
5. Usuario resuelve cada ítem (categoriza, fusiona duplicados, etc.).
6. Backend marca review_status = resolved.
```

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Registrar movimiento manual | Usuario | RF-01 | ✅ |
| CU-02 | Importar cartola | Usuario / Sistema | RF-02 | ✅ |
| CU-03 | Revisar importación | Usuario | RF-03 | ✅ |
| CU-04 | Categorizar movimiento | Usuario | RF-04 | ✅ |
| CU-05 | Revisar movimientos pendientes | Usuario | RF-04 | ✅ |
