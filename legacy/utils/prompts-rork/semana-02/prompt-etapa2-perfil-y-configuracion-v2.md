# Walvy — Etapa 2: Perfil, configuración, perfil financiero y meta global
**Prompt de ejecución para Rork AI — versión optimizada**

---

## CONTEXTO DEL PROYECTO

**App:** Walvy — finanzas personales (React Native / Expo 54, TypeScript, Expo Router 6).
**Backend:** NestJS 10, TypeORM, PostgreSQL 16. JWT (access + refresh con rotación).
**Paquetes frontend:** Bun. Imports con alias `@/`. Mock mode controlado por `api/config.ts`.

### Estado actual del código (lo que YA existe — no recrear)

**Frontend:**
- Screens: `app/_layout.tsx`, `app/index.tsx`, `app/login.tsx`, `app/register.tsx`, `app/dashboard.tsx`, `app/forgot-password.tsx`, `app/reset-password.tsx`, `app/change-password.tsx`
- Componentes: `components/AppButton.tsx`, `components/AppInput.tsx`, `components/FinanceCard.tsx`
- Auth: `store/AuthProvider.tsx` → hook `useAuth()` expone `{ user, token, isAuthenticated, logout, … }`
- API: `api/client.ts` (Axios + Bearer), `api/config.ts` (probe + mock), `api/authService.ts`, `api/types.ts`, `api/mockService.ts`
- Tokens de diseño: `constants/colors.ts` (paleta Walvy), `constants/theme.ts` (spacing, borderRadius, fontSize)

**Backend (endpoints existentes):**
- `POST /auth/register|login|refresh|logout|forgot-password|reset-password`
- `GET /users/me` → `User`
- `PATCH /users/me` → actualiza `name`, `email`
- `PATCH /users/me/password` → cambia contraseña (autenticado)

**Stack en `app/_layout.tsx`** (registra aquí cada nueva pantalla):
```tsx
<Stack.Screen name="index" />
<Stack.Screen name="login" />
<Stack.Screen name="register" />
<Stack.Screen name="forgot-password" />
<Stack.Screen name="change-password" />
<Stack.Screen name="dashboard" />
```

---

## DISEÑO (fuente de verdad — nunca inventar hex)

```ts
// constants/colors.ts
bg: "#F7F1E8"         // fondo principal (Warm Sand)
card: "#FFFFFF"        // superficies elevadas
border: "#CDECE2"      // bordes suaves
textPrimary: "#1F2A33" // texto principal
textSecondary: "#5A6B73"
deepTeal: "#103F43"    // marca / profundidad
oceanTeal: "#1B6B73"   // botones primarios / links
mintSoft: "#CDECE2"    // divisores / aire
coral: "#EE8D78"       // CTA especial — un solo foco por pantalla
red: "#D94452"         // error
yellow: "#E5A82E"      // aviso
green: "#3DA66D"       // éxito
```

```ts
// constants/theme.ts
spacing: { xs:4, sm:8, md:12, lg:16, xl:20, xxl:24, xxxl:32 }
borderRadius: { sm:8, md:12, lg:16, xl:24, full:999 }
fontSize: { xs:11, sm:12, md:14, lg:16, xl:18, xxl:22, xxxl:28, hero:36 }
```

**Reglas de diseño obligatorias:**
- Importar `colors` desde `@/constants/colors` y `{ spacing, borderRadius, fontSize }` desde `@/constants/theme`; **cero literales hex en JSX**.
- No usar `#b6fc1e` ni paletas externas.
- `coral` se usa como máximo en un único CTA por pantalla.
- Usar `AppButton`, `AppInput` existentes. `FinanceCard` puede reutilizarse para mostrar métricas.
- Fondo de pantallas: `colors.bg`. Fondo de cards/secciones: `colors.card`.

---

## ALCANCE DE ESTA ETAPA

Implementar exactamente los siguientes cuatro bloques. **Nada más.**

| # | Bloque | Pantalla nueva |
|---|--------|---------------|
| 1 | Perfil y ajustes generales | `app/profile.tsx` |
| 2 | Configuración de notificaciones y alertas | `app/notification-settings.tsx` |
| 3 | Perfil financiero básico | `app/financial-profile.tsx` |
| 4 | Meta financiera global | `app/financial-goal.tsx` |

---

## BLOQUE 1 — Pantalla de perfil (`app/profile.tsx`)

### Función
Editar nombre y correo; acceder a cambio de contraseña (ya existe), configuración de alertas y perfil financiero.

### UI: secciones con separador `colors.border`

```
[ Header: "Mi perfil" + botón Guardar ]
─────────────────────────────────────
Sección: Datos personales
  AppInput label="Nombre" value=user.name
  AppInput label="Correo" value=user.email (keyboardType="email-address")
─────────────────────────────────────
Sección: Cuenta
  → "Cambiar contraseña"     (router.push('/change-password'))
  → "Alertas y notificaciones" (router.push('/notification-settings'))
  → "Perfil financiero"       (router.push('/financial-profile'))
  → "Mi meta financiera"      (router.push('/financial-goal'))
─────────────────────────────────────
Sección: Sesión
  AppButton variant="outline" label="Cerrar sesión" onPress=logout
```

### API (ya existe — solo conectar)
```ts
// api/profileService.ts  ← CREAR este archivo
import { apiClient } from './client'
import { isMockMode } from './config'
import type { User } from './types'

export async function updateProfile(payload: { name?: string; email?: string }): Promise<User>
// REAL: PATCH /users/me   MOCK: devuelve user modificado en memoria
```

### Comportamiento
- Al tocar "Guardar": llama `updateProfile`, actualiza `user` en `AuthProvider` con `setUser(updatedUser)` (si no existe ese setter, añadirlo al context).
- Muestra `ActivityIndicator` durante la mutación (usa `useMutation` de React Query).
- En error: mensaje inline bajo el campo, color `colors.red`, no modal.
- Validación local antes de llamar: nombre ≥ 2 chars, email formato válido.

---

## BLOQUE 2 — Notificaciones y alertas (`app/notification-settings.tsx`)

### Función
Mostrar la **matriz de alertas por defecto** del producto. El usuario puede ajustar canal y cadencia dentro de opciones fijas. **No hay motor libre de porcentajes ni reglas custom.**

### Tipos de alerta (hardcoded en producto — no configurable por el usuario)

| clave | label | defecto activo | canales disponibles | cadencias disponibles |
|-------|-------|---------------|--------------------|-----------------------|
| `upcoming_payments` | Pagos próximos | true | `in_app`, `push` | `1d`, `3d`, `7d` antes |
| `budget_threshold` | Alertas de presupuesto | true | `in_app`, `push` | al cruzar umbral |
| `weekly_import_reminder` | Recordatorio semanal de movimientos | true | `in_app`, `push`, `email` | `weekly` |
| `traffic_light` | Señales del semáforo | true | `in_app` | al cambiar estado |

### Umbrales de presupuesto (fijos, no editables por el usuario)
50 % · 80 % · 100 % del límite mensual por categoría.

### TypeScript — definir en `api/types.ts`
```ts
export type AlertChannel = 'in_app' | 'push' | 'email'
export type AlertCadence = '1d' | '3d' | '7d' | 'weekly' | 'on_event'

export interface AlertPreference {
  key: 'upcoming_payments' | 'budget_threshold' | 'weekly_import_reminder' | 'traffic_light'
  enabled: boolean
  channels: AlertChannel[]
  cadence: AlertCadence
}

export type NotificationPreferences = AlertPreference[]
```

### Persistencia
- **AsyncStorage** (key: `walvy_notification_prefs`). No requiere backend en esta etapa.
- Si no hay preferencias guardadas, cargar defaults de la tabla anterior.
- Crear `services/notificationPrefsService.ts`:
```ts
export async function getNotificationPrefs(): Promise<NotificationPreferences>
export async function saveNotificationPrefs(prefs: NotificationPreferences): Promise<void>
```

### UI por alerta (un bloque por fila)
```
[Switch enabled] Pagos próximos
  Texto xs: "Cuándo: 1 día / 3 días / 7 días antes"  ← Picker o botones pill
  Texto xs: "Canal: in-app / push"                     ← Chips seleccionables
  Separador mintSoft
```
- `Switch` usa `trackColor={{ false: colors.border, true: colors.oceanTeal }}`.
- Chips de canal/cadencia: fondo `colors.mintSoft` si no activo, `colors.oceanTeal` + texto blanco si activo.
- Si el tipo de alerta solo soporta un canal (ej. semáforo = solo `in_app`), mostrar el chip deshabilitado sin acción.

### Guardrails
- No mostrar campo de porcentaje de umbral ni input libre.
- No habilitar SMS ni canales no listados.
- No guardar al backend en esta etapa.

---

## BLOQUE 3 — Perfil financiero básico (`app/financial-profile.tsx`)

### Función
Setup guiado para estimar ingresos fijos, gastos fijos y variados. Alimenta el cálculo de margen y presupuesto sugerido. Si el usuario no completa, la app usa supuestos por defecto.

### Backend — CREAR (módulo `users`, no módulo nuevo)

**Entidad** `src/users/entities/user-financial-profile.entity.ts`:
```ts
@Entity('user_financial_profiles')
export class UserFinancialProfile {
  @PrimaryGeneratedColumn('uuid') id: string
  @Column({ unique: true }) userId: string        // FK → users.id
  @Column('decimal', { precision: 19, scale: 2, default: 0 }) monthlyIncome: number
  @Column('decimal', { precision: 19, scale: 2, default: 0 }) fixedExpenses: number
  @Column('decimal', { precision: 19, scale: 2, default: 0 }) variableExpensesEstimate: number
  @Column({ default: false }) hasImportedData: boolean
  @CreateDateColumn() createdAt: Date
  @UpdateDateColumn() updatedAt: Date
}
```

**DTOs** `src/users/dto/`:
```ts
// upsert-financial-profile.dto.ts
export class UpsertFinancialProfileDto {
  @IsNumber() @Min(0) monthlyIncome: number
  @IsNumber() @Min(0) fixedExpenses: number
  @IsNumber() @Min(0) variableExpensesEstimate: number
  @IsBoolean() @IsOptional() hasImportedData?: boolean
}
```

**Endpoints en `UsersController`:**
```
GET  /users/me/financial-profile  → UserFinancialProfile | null
POST /users/me/financial-profile  → UserFinancialProfile (crea o actualiza — upsert por userId)
```

**Computed fields** (calcular en el servicio, NO persistir):
```ts
// UsersService
computeFinancialSummary(profile: UserFinancialProfile) {
  const margin = profile.monthlyIncome - profile.fixedExpenses - profile.variableExpensesEstimate
  const estimatedPaymentCapacity = Math.max(0, margin * 0.3) // 30% del margen disponible
  const suggestedSavings = Math.max(0, margin * 0.2)         // 20% del margen disponible
  return { margin, estimatedPaymentCapacity, suggestedSavings }
}
```
Devolver junto al perfil en la respuesta del GET.

**DB:** Añadir tabla `user_financial_profiles` al `DB/schema.sql`.

### API Frontend — `api/financialProfileService.ts`
```ts
export interface FinancialProfileData {
  monthlyIncome: number
  fixedExpenses: number
  variableExpensesEstimate: number
  hasImportedData: boolean
}
export interface FinancialSummary {
  margin: number
  estimatedPaymentCapacity: number
  suggestedSavings: number
}
export interface FinancialProfileResponse extends FinancialProfileData {
  summary: FinancialSummary
}

export async function getFinancialProfile(): Promise<FinancialProfileResponse | null>
export async function saveFinancialProfile(data: FinancialProfileData): Promise<FinancialProfileResponse>
// MOCK: devuelve datos de ejemplo con summary calculado; usa isMockMode de api/config.ts
```

### UI — formulario guiado en 2 pasos (usar `step: 1 | 2` en useState)

**Paso 1 — Ingresos y gastos**
```
Título: "Cuéntanos sobre tus ingresos"
Subtítulo: "Estimados mensuales. Puedes ajustarlos después."

AppInput label="Ingreso mensual neto" keyboardType="numeric" placeholder="0"
AppInput label="Gastos fijos (arriendo, créditos, etc.)" keyboardType="numeric"
AppInput label="Gastos variables estimados (comida, transporte, etc.)" keyboardType="numeric"

AppButton label="Continuar →" (oceanTeal)
```

**Paso 2 — Resultado y CTA de importación**
```
Card summary (colors.card, borderRadius.lg):
  "Tu margen estimado del mes"  → valor calculado localmente
  "Capacidad estimada de pago"  → margen × 0.30
  "Ahorro potencial"            → margen × 0.20

─────────────────────────
Banner CTA (fondo mintSoft, borde coral):
  "¿Quieres un diagnóstico más preciso desde hoy?"
  "Importa tus últimos movimientos para afinar tu presupuesto,
   metas y recomendaciones."
  AppButton variant="outline" label="Importar movimientos" (coral)  ← placeholder, onPress muestra alert "Próximamente"

─────────────────────────
AppButton label="Guardar perfil financiero" (oceanTeal)
```

### Validación
- Los tres campos numéricos ≥ 0; si están vacíos tratar como 0.
- Si `monthlyIncome === 0`, mostrar warning inline (yellow): "Sin ingreso declarado, los cálculos serán aproximados."
- No bloquear el guardado si hay warning (solo informar).

### Guardrails
- No llamar scoring bancario, asesoría ni análisis patrimonial.
- Tono orientativo: "estimado", "sugerido", "puede mejorar al importar datos".

---

## BLOQUE 4 — Meta financiera global (`app/financial-goal.tsx`)

### Función
El usuario selecciona **una meta principal** de una lista predefinida. Esta meta complementa (no reemplaza) las metas mensuales por categoría que se definirán en la etapa de Presupuestos.

### Backend — CREAR (módulo `users`)

**Entidad** `src/users/entities/user-goal.entity.ts`:
```ts
export enum GoalType {
  REDUCE_DEBT = 'reduce_debt',
  SAVE_AMOUNT = 'save_amount',
  IMPROVE_SAVINGS = 'improve_savings',
  STAY_ON_BUDGET = 'stay_on_budget',
  AVOID_LATE_PAYMENTS = 'avoid_late_payments',
}

@Entity('user_goals')
export class UserGoal {
  @PrimaryGeneratedColumn('uuid') id: string
  @Column() userId: string                          // FK → users.id
  @Column({ type: 'enum', enum: GoalType }) goalType: GoalType
  @Column('decimal', { precision: 19, scale: 2, nullable: true }) targetAmount: number | null
  @Column({ type: 'date', nullable: true }) targetDate: string | null
  @Column({ nullable: true }) notes: string | null
  @Column({ default: true }) isActive: boolean
  @CreateDateColumn() createdAt: Date
  @UpdateDateColumn() updatedAt: Date
}
```

**DTO** `src/users/dto/upsert-goal.dto.ts`:
```ts
export class UpsertGoalDto {
  @IsEnum(GoalType) goalType: GoalType
  @IsNumber() @Min(0) @IsOptional() targetAmount?: number
  @IsDateString() @IsOptional() targetDate?: string
  @IsString() @MaxLength(200) @IsOptional() notes?: string
}
```

**Endpoints en `UsersController`:**
```
GET  /users/me/goal  → UserGoal | null
POST /users/me/goal  → UserGoal (upsert: desactiva la anterior, crea nueva activa)
```

**DB:** Añadir tabla `user_goals` al `DB/schema.sql`.

### API Frontend — `api/goalService.ts`
```ts
export interface UserGoalData {
  goalType: GoalType
  targetAmount?: number
  targetDate?: string
  notes?: string
}
export interface UserGoalResponse extends UserGoalData {
  id: string
  isActive: boolean
  createdAt: string
}

export async function getGoal(): Promise<UserGoalResponse | null>
export async function saveGoal(data: UserGoalData): Promise<UserGoalResponse>
// MOCK: persiste en variable de módulo; usa isMockMode
```

### UI — selección guiada

**Paso 1 — Selección de tipo**
```
Título: "¿Cuál es tu meta principal ahora?"
Subtítulo: "Puedes cambiarla cuando quieras."

Lista de 5 opciones (tarjetas seleccionables, borde oceanTeal cuando activo):

  [🎯] Bajar mi deuda
       "Reducir lo que debo de forma ordenada"
       Indicador: deuda restante

  [💰] Ahorrar un monto
       "Llegar a una meta de ahorro específica"
       Indicador: monto ahorrado vs. objetivo

  [📈] Mejorar mi capacidad de ahorro
       "Recuperar margen mes a mes"
       Indicador: ahorro mensual recuperado

  [✅] Cumplir mi presupuesto
       "Mantenerme dentro de lo planeado"
       Indicador: % de cumplimiento mensual

  [📅] No atrasarme en pagos
       "Mantener mis compromisos al día"
       Indicador: pagos al día
```

**Paso 2 — Detalle (condicional)**
- Solo si `goalType === 'save_amount'` mostrar `AppInput` para monto objetivo y fecha estimada (opcionales).
- Para las demás opciones, saltar directo al guardado.

```
Card de confirmación:
  "Tu meta: [nombre de la meta]"
  "Cómo se mide: [indicador del tipo seleccionado]"
  "El módulo que más te ayuda: [texto orientativo según goalType]"

AppButton label="Guardar meta" (coral — único CTA prominente)
```

### Guardrails
- No permitir múltiples metas activas simultáneas (upsert desactiva la anterior).
- No convertir en simulador patrimonial ni confundir con metas por categoría.
- Tono orientativo: "tu meta", "te ayuda a", no promesas de resultado.

---

## NAVEGACIÓN — cambios en `app/_layout.tsx`

Agregar a `RootLayoutNav`:
```tsx
<Stack.Screen name="profile" />
<Stack.Screen name="notification-settings" />
<Stack.Screen name="financial-profile" />
<Stack.Screen name="financial-goal" />
```

**Acceso desde `app/dashboard.tsx`:**
Añadir en el header del dashboard un `Pressable` con el icono `User` de `lucide-react-native` que navegue a `router.push('/profile')`.

---

## MODO MOCK (`api/mockService.ts`)

Añadir soporte mock para los tres nuevos servicios. Patrón existente a seguir:

```ts
// Variables de módulo para persistencia en memoria durante sesión mock
let mockFinancialProfile: FinancialProfileData | null = null
let mockGoal: UserGoalResponse | null = null

// Implementar:
export async function mockGetFinancialProfile(): Promise<FinancialProfileResponse | null>
export async function mockSaveFinancialProfile(data: FinancialProfileData): Promise<FinancialProfileResponse>
export async function mockGetGoal(): Promise<UserGoalResponse | null>
export async function mockSaveGoal(data: UserGoalData): Promise<UserGoalResponse>
export async function mockUpdateProfile(payload: { name?: string; email?: string }): Promise<User>
```

---

## BASE DE DATOS (`DB/schema.sql`)

Añadir al final del archivo:

```sql
CREATE TABLE user_financial_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  monthly_income DECIMAL(19,2) NOT NULL DEFAULT 0,
  fixed_expenses DECIMAL(19,2) NOT NULL DEFAULT 0,
  variable_expenses_estimate DECIMAL(19,2) NOT NULL DEFAULT 0,
  has_imported_data BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE goal_type AS ENUM (
  'reduce_debt', 'save_amount', 'improve_savings',
  'stay_on_budget', 'avoid_late_payments'
);

CREATE TABLE user_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_type goal_type NOT NULL,
  target_amount DECIMAL(19,2),
  target_date DATE,
  notes VARCHAR(200),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## ARCHIVOS A CREAR / MODIFICAR

### Backend (`Backend/backend/src/`)
| Acción | Archivo |
|--------|---------|
| CREAR | `users/entities/user-financial-profile.entity.ts` |
| CREAR | `users/entities/user-goal.entity.ts` |
| CREAR | `users/dto/upsert-financial-profile.dto.ts` |
| CREAR | `users/dto/upsert-goal.dto.ts` |
| MODIFICAR | `users/users.controller.ts` — agregar 4 endpoints |
| MODIFICAR | `users/users.service.ts` — agregar lógica de upsert + `computeFinancialSummary` |
| MODIFICAR | `users/users.module.ts` — registrar entidades nuevas en TypeORM |
| MODIFICAR | `DB/schema.sql` — añadir tablas |

### Frontend (`Frontend/rork-checkapp/expo/`)
| Acción | Archivo |
|--------|---------|
| CREAR | `app/profile.tsx` |
| CREAR | `app/notification-settings.tsx` |
| CREAR | `app/financial-profile.tsx` |
| CREAR | `app/financial-goal.tsx` |
| CREAR | `api/profileService.ts` |
| CREAR | `api/financialProfileService.ts` |
| CREAR | `api/goalService.ts` |
| CREAR | `services/notificationPrefsService.ts` |
| MODIFICAR | `api/types.ts` — añadir tipos nuevos |
| MODIFICAR | `api/mockService.ts` — añadir mocks nuevos |
| MODIFICAR | `app/_layout.tsx` — registrar 4 pantallas |
| MODIFICAR | `app/dashboard.tsx` — añadir icono de perfil en header |
| MODIFICAR | `store/AuthProvider.tsx` — añadir `setUser` al context si no existe |

---

## CRITERIOS DE ACEPTACIÓN (QA manual)

### Perfil
- [ ] El usuario ve y edita nombre y correo; "Guardar" llama `PATCH /users/me` y actualiza la UI.
- [ ] Si el correo está mal formado, error inline (no llamada a la API).
- [ ] Los cuatro accesos de menú navegan a las pantallas correctas.
- [ ] "Cerrar sesión" llama `logout()` y redirige a `/login`.

### Notificaciones
- [ ] Al abrir por primera vez se muestran los 4 tipos con sus defaults activos.
- [ ] Cada toggle persiste en AsyncStorage; al reabrir la pantalla los valores se restauran.
- [ ] Los chips de canal/cadencia respetan las opciones disponibles por tipo de alerta.
- [ ] El tipo `traffic_light` solo muestra canal `in_app` (no interactivo).
- [ ] No aparece ningún campo de porcentaje ni input libre.

### Perfil financiero
- [ ] El formulario guiado acepta valores decimales positivos.
- [ ] El resumen del Paso 2 muestra los tres valores calculados con los datos ingresados.
- [ ] El banner "Importar movimientos" muestra alert "Próximamente" al presionarlo.
- [ ] "Guardar perfil financiero" llama `POST /users/me/financial-profile` y muestra confirmación.
- [ ] Si `monthlyIncome === 0` aparece el aviso en yellow pero se puede guardar igual.

### Meta financiera
- [ ] Se muestran las 5 opciones con descripción e indicador.
- [ ] Solo `save_amount` activa el campo de monto/fecha en Paso 2.
- [ ] "Guardar meta" llama `POST /users/me/goal` y redirige (o muestra confirmación).
- [ ] La meta guardada es visible en la pantalla de perfil (sección "Mi meta financiera").

---

## FUERA DE ALCANCE (no implementar)

- Motor libre de porcentajes de alertas por el usuario.
- SMS u otros canales de notificación.
- Importación real de cartolas/movimientos (solo placeholder con "Próximamente").
- Múltiples metas activas simultáneas.
- Scoring bancario, análisis patrimonial, asesoría certificada.
- Migración de base de datos (TypeORM `synchronize: true` en desarrollo es suficiente).
- Push notifications reales (solo UI de preferencias).
