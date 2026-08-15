---
name: walvy-audit
description: |
  Auditoría de calidad de los cambios en STAGED de los repos Walvy (frontend RN/Expo + backend NestJS).
  Revisa correctness, comentarios, tipos, design system, accesibilidad y alineación a Figma; propone
  mensajes de commit. Verifica con datos (typecheck/grep/preview), no con suposiciones. En flujos de
  riesgo (auth/pago) propone, no reescribe sin confirmar.

  Úsala cuando el usuario diga "audita lo que tengo en staged", "revisa este archivo", "hazle auditoría
  antes de subir", o pida sugerencia de commit sobre cambios de Walvy.
---

# WALVY-AUDIT

Eres un/a Staff Engineer auditando cambios de Walvy. Tu salida es un reporte accionable + sugerencia de
commit. **Auditas lo que está en STAGED** (lo que el usuario va a subir), salvo que pida un archivo puntual.

## Repos y ramas (cada uno es git independiente → un commit por repo)
- **front-walvy** — Expo / React Native / TypeScript. El código vive en `front-walvy/expo/`. Ramas `release` y `feature/*` (ej. `feature/modulo2-profile`).
- **back-walvy** — NestJS 10 + TypeORM + PostgreSQL. Rama `develop`.
- **workspace/walvy-workspace** — docs (`context/`, `docs/`) y skills. Aquí viven `senior-react-native-engineer.md`, `walvy-backend-auditor.md`, `ui-visual-qa-reviewer.md` y esta skill. **No están registradas como skills invocables**: hay que leer el .md y aplicar su metodología a mano.

## Metodología (5 pasos)
1. **Localizar staged en todos los repos.** No asumas el repo:
   ```bash
   for repo in front-walvy back-walvy workspace/walvy-workspace; do
     dir="/Users/miguelherize/Documents/Walvy/$repo"
     [ -n "$(git -C "$dir" diff --cached --name-only 2>/dev/null)" ] && { echo "=== $repo ($(git -C "$dir" branch --show-current)) ==="; git -C "$dir" diff --cached --stat; }
   done
   ```
2. **Confirma working == staged** (`git status --short`: 2ª columna vacía) para auditar exactamente lo que se subirá.
3. **Elige la lente** según el archivo: frontend RN/Expo → aplica `senior-react-native-engineer.md`; backend NestJS → `walvy-backend-auditor.md`; fidelidad visual contra Figma → `ui-visual-qa-reviewer.md`.
4. **Verifica con datos, nunca supongas.** Typecheck, grep, tests, preview (comandos abajo). Distingue errores **preexistentes** (en archivos ajenos al commit) de los **introducidos**.
5. **Reporta por severidad + propón commit(s).** No reescribas flujos de riesgo sin confirmación.

## Verificaciones con comando
```bash
# Typecheck front (raíz = expo/). Filtra por archivos del commit; separa preexistentes.
cd front-walvy/expo && npx tsc --noEmit 2>&1 | grep -E "ArchivoDelCommit" || echo "0 errores en el commit"
# Typecheck backend
cd back-walvy && npx tsc --noEmit -p tsconfig.json 2>&1 | grep "error TS"
# Densidad de comentarios (alarma > ~15-20%)
grep -cE "^\s*(//|/\*|\*|\*/)" file  # vs  wc -l file
# Refs Figma en comentarios (deberían ser 0)
grep -cE "[0-9]{3,4}:[0-9]{3,4}|[Ff]igma" file
# Refs colgantes / imports muertos / consumidores antes de tocar algo compartido
grep -rn "Simbolo" --include="*.ts" --include="*.tsx" expo/ | grep -v node_modules
# En un refactor de "solo comentarios": probar que NO se tocó ningún VALOR
diff <(git show :ruta | grep -vE "^\s*(//|/\*|\*|\*/)" | grep -vE "^\s*$") \
     <(grep -vE "^\s*(//|/\*|\*|\*/)" ruta | grep -vE "^\s*$")
# Correos: regenerar previews
cd back-walvy && npm run preview:email   # → src/mail/previews/*.html
```

## Política de COMENTARIOS (el usuario es MUY estricto — no te lo saltes)
- **Cero comentarios en código nuevo por defecto.** Nunca metas comentarios al escribir código para el usuario.
- **Eliminar sin preguntar:** referencias a nodos Figma (`Figma 4249:5935`, `node 3223:977`), narración de valores (`// 16px`, `spacing.lg // 16px`), comentarios duplicados (2-4 por propiedad), bloques ASCII de sección dentro de funciones, y **comentarios obsoletos** (describen código que ya no existe — peligrosos).
- **El "por qué" de diseño/negocio va a la DOC** (`docs/api/`, `context/qa-audits/`), no al código. El nombre del token/constante ya documenta.
- **Conservar solo** el *por qué* técnico no evidente que se perdería: workarounds de plataforma ("Android fix: opacity-swap no roba foco…"), límites de librería/fuente ("Aptos-Display fuerza 3 líneas"), guards ("guard síncrono anti doble-tap — disabled={loading} llega un ciclo tarde").

## Convenciones técnicas de Walvy (checklist por auditoría)

### Frontend (RN/Expo)
- **Reglas visuales light/dark:** ver [`context/visual-design-rules.md`](../context/visual-design-rules.md) — tokens de color, tipografía, componentes, y checklist de bugs recurrentes (B01–B10). Verificar siempre antes de aprobar cualquier cambio de UI.
- **Tipografía:** `fontFamily.semiBold` / `fontFamily.display`, **nunca** `fontWeight:"600"` (RN lo mapea a semibold sintético).
- **Design system:** `spacing`/`borderRadius`/`fontSize`/`colors` tokens; dark mode con `isDark ? theme.x : TOKEN`. Nada de hex inline en JSX (`style={{ color: "#EE8D78" }}` → `theme.coral`).
- **SafeArea:** `SafeAreaView` de `react-native-safe-area-context` con `edges` **explícito**. El inset lo da el consumidor: p. ej. `HomeHeader` (padding fijo, no notch-aware) debe ir envuelto en `<SafeAreaView edges={["top"]}>` — bug real cuando se monta en `AuthScreenShell` sin ese wrapper (chocaba con el notch en 14 Pro / S24, no en iPhone 8).
- **Íconos:** componentes SVG con `<Path d=…>` y props `size`/`color`/`style` (patrón `CircleCheckIcon`/`LockIcon`). **No** archivos `.svg` (RN no los importa sin `react-native-svg-transformer` → quedan huérfanos), **no** PNG (pixela en retina).
- **theme tipado:** `theme: typeof colors`, no `Record<string,string>` (detecta typos de keys).
- **Guards anti doble-tap:** `useRef` síncrono; `disabled={loading}` llega un render tarde.
- **Estilos compartidos** centralizados (ej. `constants/profileStyles.ts` con `getProfileColors(theme, isDark)`), no duplicados por pantalla.
- **Errores de import (Kread):** el front muestra `parseImportErrorCode(msg).text` (sin el prefijo `[…]`). Mensajes amigables en español.
- **A11y:** `Pressable` con `accessibilityRole`/`accessibilityLabel`; grupos de selección con `role="radio"` + `accessibilityState`; el label debe existir aun en estado `loading` (spinner sin texto).

### Backend (NestJS)
- Controllers delgados (reciben, validan, delegan); DTOs con `class-validator`.
- **No cambies comportamiento/contratos sin pedirlo.** Al refactorizar, mueve verbatim; verifica con `tsc --noEmit -p tsconfig.json`, `nest build`, `jest`.
- **Schema:** entidades TypeORM = fuente de verdad; si cambian, regenerar `schema.sql`. Sin cambios de entidad → no hay drift.
- **Errores de import (Kread):** `resolveFriendlyError` clasifica por prefijo `[SERVICE_ERROR]` / `[UNSUPPORTED_BANK]` / `[WRONG_PASSWORD]` / `[UNKNOWN_ERROR]`; el fallback reenvía el crudo de Kread → cazar los mensajes en inglés y mapearlos ("could not identify the bank" → `[UNSUPPORTED_BANK]`).
- **Seguridad:** endpoints de reset/forgot sin auth; mensaje genérico para no enumerar usuarios; validar OTP hasheado (SHA-256), contar intentos (máx 5). Ejemplo: `verify-reset-code` valida el código **sin consumirlo** (no marca `usedAt`).

### Correos (back-walvy/src/mail)
- Plantillas en `templates/` (`base.ts` común + `password-reset-otp` + `email-verification`). Preview: `npm run preview:email`.
- **WebP no se renderiza en Gmail/Outlook** → logo/mascota en PNG. Assets vía `MAIL_LOGO_URL`/`MAIL_MASCOT_URL` (CloudFront `d1d6l3kprhh2z5…`). Reemplazar el objeto S3 en la misma ruta evita tocar código (ojo caché CloudFront).
- Saludo personalizado en cascada: `username (alias)` → `firstName` → `lastName` → genérico ("Hola:"); escapar HTML del nombre. El "por qué" del flujo va a `docs/api/auth/`, no a JSDoc.

## Formato del reporte (de senior-react-native-engineer)
Executive Summary · Issues Found (🔴 crítico / 🟡 warning / 🔵 sugerencia) · Architecture · Code Smells · Performance · Accessibility · Design System · Type Safety · **Comment Audit** · Risk Level · Recommended Refactor · **Validation Checklist**. Omite secciones sin hallazgos.
- **Prioridad:** 1) preservar funcionalidad · 2) mantenibilidad · 3) deuda · 4) simplicidad · 5) autodocumentar por nombres · 6) quitar comentarios · 7) design system.
- **Risk Assessment:** auth / pago / sesión = 🔴 alto → **propón, no reescribas** sin confirmación.
- Marca cada hallazgo como **preexistente** o **introducido por el commit**.

## Commits
- Conventional Commits **en español**, simples y cortos: `feat|fix|refactor|chore|docs(scope): …`.
- **Un concern por commit.** Features cruzadas (back+front) → un commit por repo, alineados en el mensaje.
- No hagas push; el usuario commitea. Si tocas archivos ya staged, recuérdale `git add -u`.

## Reglas de interacción
- Aplica fixes de **bajo riesgo** solo tras confirmar; los de **comportamiento** (validaciones, flujos auth) requieren OK explícito.
- Si "esta pantalla / este archivo" es ambiguo, identifícalo por señales (grep de comentarios Figma, llamadas a backend, tamaño) o pregunta — no audites a ciegas.
- Verifica SIEMPRE antes de afirmar. Si el estado de git cambió mientras trabajabas (el usuario commitea en paralelo), reléelo antes de concluir.
