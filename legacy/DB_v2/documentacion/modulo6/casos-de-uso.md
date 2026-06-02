# Módulo 6 — Casos de Uso

**Módulo:** Presupuesto  
**Fuente de verdad MVP:** `MVP_Walvy_VF_10032026_alineado_estrategia - Alcance MVP.csv` — Módulo 6

---

## CU-01 — Crear presupuesto del mes

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario navega a "Presupuesto" → "Nuevo presupuesto" (o se abre automáticamente al comenzar el mes).
2. La app puede mostrar sugerencia basada en los 3 meses anteriores de gastos
   (ítems con suggested_by_app = true).
3. Usuario revisa y ajusta los límites por categoría.
4. App llama POST /budget (o PUT /budget/{year}/{month}).
5. Backend:
   a. UPSERT en budget_plan para (user_id, period_month).
   b. UPSERT en budget_plan_item por cada categoría.
6. App muestra el presupuesto configurado.
7. gamification_events: goals_set (si es el primer presupuesto del usuario).
```

---

## CU-02 — Ver estado del presupuesto

**Actor principal:** Usuario

### Flujo principal

```
1. Usuario navega a "Presupuesto".
2. App llama GET /budget/{year}/{month}.
3. Backend:
   a. Lee budget_plan + budget_plan_items del mes.
   b. Para cada ítem: SUM(financial_movement.amount_out) WHERE category_id AND mes.
   c. Calcula pct_used = spent / amount_limit.
4. App muestra:
   - Barra de progreso por categoría (verde / amarillo / rojo).
   - Total gastado vs. total presupuestado.
   - Categorías en riesgo (pct_used >= 80%).
```

---

## CU-03 — Copiar presupuesto anterior

**Actor principal:** Usuario

### Flujo principal

```
1. Al crear presupuesto del mes: app muestra botón "Copiar del mes anterior".
2. App llama POST /budget/copy-previous.
3. Backend busca budget_plan del mes anterior.
4. Si existe: copia todos los budget_plan_items al nuevo mes.
5. Usuario puede modificar los límites antes de guardar.
```

### Flujo alternativo — No hay presupuesto anterior

```
→ Backend retorna 404.
→ App muestra el formulario en blanco con sugerencias de la app.
```

---

## Resumen de Casos de Uso

| ID | Caso de uso | Actor | RF relacionado | MVP |
|----|-------------|-------|----------------|-----|
| CU-01 | Crear presupuesto del mes | Usuario | RF-01 | ✅ |
| CU-02 | Ver estado del presupuesto | Usuario | RF-02 | ✅ |
| CU-03 | Copiar presupuesto anterior | Usuario | RF-03 | ✅ |
