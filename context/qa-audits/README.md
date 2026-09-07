# QA Audits — Auditorías Pixel-Perfect contra Figma

Reportes generados por la skill **UI Visual QA Reviewer** (ver `workspace/walvy-workspace/skills/ui-visual-qa-reviewer.md`).

## 📁 Estructura

```
qa-audits/
├── auth/                       # Módulo M1 (Authentication)
│   ├── login.md                # /login firstTime
│   ├── login-saved-user.md     # /login savedUserPassword (Figma 3470:7098)
│   ├── login-saved-user-biometric.md  # /login savedUserBiometric (Figma 3470:7080)
│   ├── login-saved-user-error.md      # /login con error inline (Figma 3677:2914)
│   ├── register.md             # /register
│   ├── verify-code.md          # /(auth)/verify-code
│   ├── biometric-setup.md      # /(auth)/biometric-setup
│   ├── choose-alias.md         # /(auth)/choose-alias
│   └── flujo_mod_1.txt         # Diagrama del flujo completo Parte 1
└── README.md                   # este archivo
```

## 🎯 Cuándo generar nuevas auditorías

Cada vez que:
1. Se implementa una pantalla desde Figma → ejecutar `/walvy-qa-visual` con screenshot Android/iOS
2. Se aplica un fix significativo → re-auditar para verificar score
3. Hay un cambio en el design system → re-auditar todas las pantallas afectadas

## 📊 Formato del reporte

Cada `.md` sigue el formato estándar de la skill:

1. **Header**: Figma node ID, file key, fecha, auditor
2. **📊 Resumen Ejecutivo**:
   - Pixel Perfect Score (0-100)
   - Estado General: Aprobado / Aprobado con observaciones / Rechazado
   - Principales problemas priorizados
   - Recomendaciones por prioridad
3. **📋 Detalle por Fases** (7 fases): Layout, Tipografía, Colores, Componentes, Espaciado, Responsive, Accesibilidad
4. **🏁 Veredicto** + acciones recomendadas
5. **📂 Historial de auditorías** (track de iteraciones)

## 🎨 Estado actual — Módulo Auth (M1)

| Pantalla | Score actual | Última auditoría | Issues Media+ |
|---|---|---|---|
| `/login` (firstTime) | 94/100 | 2026-05-30 | 1 (touch target) |
| `/login` (savedUserPassword) | 93/100 | 2026-05-31 | 1 (firstName bug) |
| `/login` (savedUserBiometric) | 90/100 | 2026-05-31 | 2 (firstName + CTA position) |
| `/login` (savedUser error) | — | 2026-05-31 | — |
| `/register` | 92/100 | 2026-05-30 | 2 (helper RUT + touch targets) |
| `/verify-code` | 95/100 | 2026-05-30 | 2 (KeyboardAvoiding + touch) |
| `/biometric-setup` | 95/100 | 2026-05-30 | 0 |
| `/choose-alias` | 91/100 | 2026-05-30 | 2 (italic + touch target) |

**Score promedio M1:** 92.9/100 ✅

## 🔗 Referencias cruzadas

- **Bugs raíz detectados** → la deuda técnica se sigue por módulo, en `context/moduloNN-*/deuda-tecnica/README.md`
- **ADRs relacionados** → ver [`../decisions.md`](../decisions.md)
- **Spec del módulo** → ver [`../specs/authentication.md`](../specs/authentication.md)
- **Skill que genera estos reportes** → ver [`../../skills/ui-visual-qa-reviewer.md`](../../skills/ui-visual-qa-reviewer.md)
