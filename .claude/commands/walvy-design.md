---
description: UI pixel-perfect. Figma → React Native con tokens Walvy.
---

Implementá visual contra Figma. No inventes hex.

Tokens: `front-walvy/expo/constants/colors.ts` + `theme.ts`.
Reglas: `context/visual-design-rules.md`.
Después de implementar, la skill `ui-visual-qa` audita; no genera código.

- `useTheme()` · `theme.*` · nunca `'#1B6B73'` en JSX
- Coral = un foco por pantalla
- `theme.spacing.*` / `borderRadius.*` / `fontSize.*`
- Íconos: `lucide-react-native` o SVG propio. No PNG de ícono
- Safe area explícita fuera de `(tabs)`
- Tipografía: `fontFamily.semiBold`, no `fontWeight: "600"`

Si hay duda de un valor, leé el token. No inventes.
