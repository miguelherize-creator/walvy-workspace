# Módulo 4 — Casos de Uso

**Módulo:** Motor de Deudas (Bola de Nieve)  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 4

**Actores:**
- **Usuario** — persona que usa la app Walvy
- **Sistema** — job de cálculo que actualiza read models y simulaciones

---

## CU-01 — Registrar deuda

**Actor principal:** Usuario  
**Precondiciones:** Usuario autenticado.

### Flujo principal

```
1. Usuario navega a "Deudas" → "Nueva deuda".
2. Ingresa: nombre, tipo, saldo actual, tasa, pago mínimo, día de vencimiento.
3. App llama POST /debts.
4. Backend crea debt con status = active y snowball_priority al final de la cola.
5. Si installments_total y due_day indicados: backend pre-genera debt_schedules.
6. Backend dispara evento de gamificación: event_type = debt_registered.
7. App muestra la deuda en el listado con el cronograma.
```

### Flujo alternativo — Deuda sin cuotas conocidas

```
4. Usuario solo conoce el saldo actual y la tasa.
→ Se crea debt sin installments_total.
→ No se generan debt_schedules.
→ La simulación de payoff puede calcularse igualmente con el saldo y la tasa.
```

---

## CU-02 — Registrar abono

**Actor principal:** Usuario  
**Precondiciones:** Existe al menos una `debt` activa.

### Flujo principal

```
1. Usuario abre una deuda → toca "Registrar abono".
2. Ingresa monto y fecha. Opcionalmente selecciona un movimiento financiero importado.
3. App llama POST /debts/{id}/payments.
4. Backend crea debt_payments (inmutable).
5. Backend actualiza debt.current_balance -= amount.
6. Backend evalúa: si current_balance <= 0 → sugiere marcar como 'settled'.
7. Backend dispara gamification_events: event_type = debt_payment_registered.
8. App actualiza el saldo visible en pantalla.
```

### Flujo alternativo — El abono liquida la deuda

```
5. current_balance llega a 0.
→ Backend devuelve flag: suggest_settled = true.
→ App muestra modal: "¡Deuda liquidada! ¿Marcar como saldada?"
→ Si usuario confirma: PATCH /debts/{id} { debt_status: 'settled' }
```

---

## CU-03 — Ver cronograma de cuotas

**Actor principal:** Usuario  
**Precondiciones:** Existe una `debt` con `debt_schedules` generados.

### Flujo principal

```
1. Usuario abre una deuda → tab "Cuotas".
2. App llama GET /debts/{id}/schedules.
3. Backend retorna debt_schedules ordenados por installment_no.
4. App muestra tabla: Nº cuota · fecha · capital · interés.
```

### Flujo alternativo — Sin cronograma

```
→ La deuda no tiene debt_schedules.
→ App muestra: "No hay cronograma disponible para esta deuda."
→ CTA: "Agregar detalles de la deuda" para que el usuario ingrese installments.
```

---

## CU-04 — Crear simulación Bola de Nieve

**Actor principal:** Usuario  
**Precondiciones:** Tiene al menos una `debt` activa.

### Flujo principal

```
1. Usuario navega a "Simulador de payoff".
2. App carga deudas activas con sus saldos y tasas.
3. Usuario ingresa:
   - extra_monthly_payment: cuánto puede abonar extra cada mes.
   - initial_lump_sum: si tiene un pago único inicial.
   - start_date.
4. App llama POST /debts/simulations.
5. Backend:
   a. Si existe simulation active → cambia su status a 'archived'.
   b. Crea debt_payoff_simulation con status = active.
   c. Aplica algoritmo Bola de Nieve: ordena deudas por saldo menor primero.
   d. Calcula meses de liquidación y fecha estimada por deuda.
   e. Crea debt_payoff_schedule (una fila por deuda activa).
6. App muestra el plan: lista ordenada con fechas estimadas de cierre.
```

### Flujo alternativo — Ajustar parámetros

```
3. Usuario modifica extra_monthly_payment.
→ Repite el flujo desde el paso 4 (nueva simulación).
→ La anterior queda archivada y es visible como "Simulaciones anteriores".
```

---

## CU-05 — Adjuntar documento a deuda

**Actor principal:** Usuario  
**Precondiciones:** Existe una `debt`.

### Flujo principal

```
1. Usuario abre una deuda → tab "Documentos" → "Subir archivo".
2. Selecciona un PDF o imagen (cartola, contrato).
3. App llama POST /debts/{id}/attachments con el archivo.
4. Backend:
   a. Sube el archivo a S3, obtiene storage_key.
   b. Crea debt_attachments con debt_id, storage_key, mime_type.
   c. Encola OCR si el mime_type es PDF/imagen soportada.
5. App muestra el archivo en la lista de documentos.
6. [Asíncrono] Job de OCR procesa el archivo y actualiza parsed_summary.
```

---

## CU-06 — Ver historial de abonos

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario abre una deuda → tab "Historial".
2. App llama GET /debts/{id}/payments.
3. Backend retorna debt_payments ordenados por paid_at DESC.
4. App muestra: fecha · monto · notas · movimiento asociado (si aplica).
```

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Registrar deuda | Usuario | RF-01 | ✅ |
| CU-02 | Registrar abono | Usuario | RF-03 | ✅ |
| CU-03 | Ver cronograma de cuotas | Usuario | RF-04 | ✅ |
| CU-04 | Crear simulación Bola de Nieve | Usuario | RF-05 | ✅ |
| CU-05 | Adjuntar documento | Usuario | RF-06 | ✅ |
| CU-06 | Ver historial de abonos | Usuario | RF-03 | ✅ |
