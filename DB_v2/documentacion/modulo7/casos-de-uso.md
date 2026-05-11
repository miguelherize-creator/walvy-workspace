# Módulo 7 — Casos de Uso

**Módulo:** Pagos y Agenda  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 7

---

## CU-01 — Registrar pago próximo

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario navega a "Pagos" → "Nuevo pago".
2. Ingresa: título, monto, fecha de vencimiento, si es recurrente.
3. Opcionalmente vincula a una deuda (debt_id).
4. App llama POST /payments.
5. Backend crea user_payment con status = pending, source = user.
6. Backend encola notificación de recordatorio en notification_queue.
7. App muestra el pago en la agenda.
```

---

## CU-02 — Marcar pago como realizado

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario toca un pago pendiente en la agenda → "Marcar como pagado".
2. App muestra: ¿Asociar a un movimiento importado? (lista de movimientos recientes).
3. Usuario confirma (con o sin movimiento asociado).
4. App llama PATCH /payments/{id}/pay { paid_at, movement_id? }.
5. Backend:
   a. user_payment_status → paid, paid_at = now().
   b. Si movement_id: vincula el movimiento.
   c. Si debt_id: sugiere registrar abono en la deuda.
   d. Si is_recurring: genera el siguiente user_payment automáticamente.
6. App actualiza la agenda.
```

### Flujo alternativo — El pago es recurrente

```
5d. Backend crea nuevo user_payment:
    - due_date = paid_at + recurrence_interval_days
    - user_payment_status = pending
    - source = system
    - Encola notificación para el nuevo vencimiento.
```

---

## CU-03 — Ver agenda de pagos

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario navega a la pantalla "Pagos".
2. App llama GET /payments?status=pending&sort=due_date_asc.
3. Backend retorna user_payment filtrado por user_id + status pending.
4. App agrupa por: hoy, esta semana, este mes, futuro.
5. Pagos con traffic_light_state = red destacados visualmente.
```

---

## CU-04 — Confirmar sugerencia de recurrencia

**Actor principal:** Usuario

### Flujo principal

```
1. El sistema detecta que el usuario paga Netflix ~$17.990 el día 15 cada mes.
2. Backend crea recurring_payment_suggestions con status = pending_user_confirm.
3. Home/pantalla de pagos muestra: "Detectamos un pago recurrente: Netflix $17.990/mes"
4. Usuario toca "Añadir a mi agenda".
5. App llama POST /payments/suggestions/{id}/accept.
6. Backend:
   a. recurring_payment_suggestions.status → accepted.
   b. Crea user_payment con is_recurring = true, recurrence_interval_days = 30.
```

### Flujo alternativo — Usuario descarta la sugerencia

```
4. Usuario toca "No, gracias".
5. recurring_payment_suggestions.status → dismissed.
→ La sugerencia no vuelve a aparecer.
```

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Registrar pago próximo | Usuario | RF-01 | ✅ |
| CU-02 | Marcar pago como realizado | Usuario | RF-03 | ✅ |
| CU-03 | Ver agenda de pagos | Usuario | RF-02 | ✅ |
| CU-04 | Confirmar sugerencia de recurrencia | Usuario | RF-04 | ✅ |
