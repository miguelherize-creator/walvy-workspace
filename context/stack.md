# Stack Tecnológico — Walvy

## Backend
- **Framework:** NestJS 10 + TypeScript strict
- **DB:** PostgreSQL 15 + TypeORM 0.3.28
- **Auth:** JWT (15min access / 7d refresh rotado + hasheado) + Passport JWT + bcrypt
- **Validación:** class-validator (solo en DTOs, en el boundary)
- **Email:** Nodemailer (OTP, password reset)
- **Pagos:** Flow.cl (HMAC-SHA256 webhooks, sandbox + producción)
- **Rate limiting:** @nestjs/throttler
- **Docs API:** Swagger en `/api`
- **Package manager:** npm

## Frontend
- **Runtime:** Expo SDK 54, React 19.1, React Native 0.81
- **Package manager:** Bun ≥ 1.0 (NUNCA npm en frontend)
- **Routing:** Expo Router 6 (file-based, `app/` son delegates de 2 líneas)
- **Data fetching:** TanStack React Query 5.x + Axios con interceptores JWT
- **Auth storage:** expo-secure-store (NUNCA AsyncStorage para tokens)
- **Biometría:** expo-local-authentication
- **Validación forms:** Zod 4
- **Iconos:** lucide-react-native (no mezclar con otras librerías)
- **Testing:** Jest + React Native Testing Library

## Base de datos
- PostgreSQL 15, sin carpeta migrations aún
- `DB_SYNC=false` en producción, `true` solo en dev temporal
- 55 tablas en 19 capas semánticas
- Status domain pattern (no ENUMs para estados mutables)
- Soft deletes en `app_user`, `financial_movement`, `debt`

## Servicios externos
| Servicio | Estado | Propósito |
|----------|--------|-----------|
| Flow.cl | Activo | Pagos Chile |
| SMTP/Nodemailer | Activo | Email transaccional |
| FCM/APNs | Pendiente | Push notifications (Sprint 7) |
| Open Banking API | Pendiente | Import movimientos (Sprint 4) |

## Comandos de desarrollo

```bash
# Backend
cd Backend/MVP-CheckApp
npm run start:dev        # hot reload
docker compose up --build  # API + PostgreSQL
npm run test:e2e

# Frontend
cd Frontend/rork-checkapp/expo
bun i
bun run start            # Expo Metro
bun run start-web        # Web preview
bun run test
```
