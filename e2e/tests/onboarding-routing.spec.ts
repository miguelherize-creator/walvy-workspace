/**
 * onboarding-routing.spec.ts
 *
 * Tests E2E para verificar que el login redirige al paso correcto
 * de onboarding según el `currentStep` guardado en backend (mock).
 *
 * REQUISITO: debe correr en mock mode (E2E_MODE=mock, por defecto).
 *   npm test                     ← mock mode automático
 *   cross-env E2E_MODE=api npm test ← NO aplica estos tests
 *
 * Usuarios mock (contraseña: 123456):
 *   demo@walvy.mock          → onboarding completado  → home
 *   demo-biometric@walvy.mock → currentStep biometric_setup → /biometric-setup
 *   demo-profile@walvy.mock  → currentStep profile_basic   → /choose-alias
 */

import { test, expect, type Page } from "@playwright/test";
import { isMock, waitForDashboard } from "../helpers/auth";

const PASS = "123456";

// Credenciales de usuarios mock con sus emails
const USERS = {
  completed:  { email: "demo@walvy.mock",           password: PASS },
  biometric:  { email: "demo-biometric@walvy.mock",  password: PASS },
  alias:      { email: "demo-profile@walvy.mock",    password: PASS },
} as const;

// ─── helpers ────────────────────────────────────────────────────────────────

async function loginWith(page: Page, email: string, password = PASS) {
  await page.goto("/login");
  await page.getByTestId("login-email").waitFor({ state: "visible", timeout: 15_000 });
  await page.getByTestId("login-email").fill(email);
  await page.getByTestId("login-password").fill(password);
  await page.getByTestId("login-button").click();
}

async function waitForURL(page: Page, pattern: RegExp, timeout = 15_000) {
  await expect(page).toHaveURL(pattern, { timeout });
}

// ─── guard: solo corren en mock mode ────────────────────────────────────────

test.beforeAll(async () => {
  if (!isMock) {
    // En modo API real estos tests no tienen sentido — los usuarios mock no existen
    console.warn("[onboarding-routing] tests skipped: require E2E_MODE=mock");
  }
});

// ─── tests ──────────────────────────────────────────────────────────────────

test.describe("Onboarding routing post-login", () => {
  test.skip(!isMock, "Requiere mock mode (E2E_MODE=mock)");

  // ── 1. Onboarding completo → dashboard ──────────────────────────────────
  test("usuario con onboarding completado va al dashboard", async ({ page }) => {
    await loginWith(page, USERS.completed.email);
    await waitForDashboard(page);
    await expect(page).not.toHaveURL(/biometric-setup|choose-alias|onboarding/i);
  });

  // ── 2. biometric_setup → /biometric-setup ───────────────────────────────
  test("usuario en biometric_setup va a /biometric-setup", async ({ page }) => {
    await loginWith(page, USERS.biometric.email);
    await waitForURL(page, /biometric-setup/i);
    await expect(page.getByTestId("biometric-setup-screen")).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText("Acceso rápido")).toBeVisible();
    await expect(page.getByTestId("biometric-skip")).toBeVisible();
  });

  // ── 3. profile_basic → /choose-alias ────────────────────────────────────
  test("usuario en profile_basic va a /choose-alias", async ({ page }) => {
    await loginWith(page, USERS.alias.email);
    await waitForURL(page, /choose-alias/i);
    await expect(page.getByTestId("choose-alias-input")).toBeVisible({ timeout: 10_000 });
  });

  // ── 4. biometric_setup → skip → choose-alias ────────────────────────────
  test("skip de biometría lleva a /choose-alias", async ({ page }) => {
    await loginWith(page, USERS.biometric.email);
    await waitForURL(page, /biometric-setup/i);
    await page.getByTestId("biometric-skip").click();
    await waitForURL(page, /choose-alias/i);
    await expect(page.getByTestId("choose-alias-input")).toBeVisible({ timeout: 10_000 });
  });

  // ── 5. Persistencia: salir de biometric-setup y volver a login ──────────
  test("volver a login desde biometric-setup mantiene el mismo step", async ({ page }) => {
    // Login → biometric-setup
    await loginWith(page, USERS.biometric.email);
    await waitForURL(page, /biometric-setup/i);

    // Simular "salir de la app" → volver a /login
    await page.goto("/login");
    await page.getByTestId("login-email").waitFor({ state: "visible", timeout: 10_000 });

    // Volver a login sin tocar ningún botón de biometric-setup
    await page.getByTestId("login-email").fill(USERS.biometric.email);
    await page.getByTestId("login-password").fill(PASS);
    await page.getByTestId("login-button").click();

    // Debe volver a biometric-setup (estado del mock no cambió)
    await waitForURL(page, /biometric-setup/i);
    await expect(page.getByTestId("biometric-setup-screen")).toBeVisible({ timeout: 10_000 });
  });

  // ── 6. choose-alias → guardar alias → dashboard ─────────────────────────
  test("guardar alias completa el onboarding y va al dashboard", async ({ page }) => {
    await loginWith(page, USERS.alias.email);
    await waitForURL(page, /choose-alias/i);
    await expect(page.getByTestId("choose-alias-input")).toBeVisible({ timeout: 10_000 });
    await page.getByTestId("choose-alias-input").fill("e2etestuser");
    await page.getByTestId("choose-alias-continue").click();
    await waitForDashboard(page);
  });
});

// ─── test de regresión específico ───────────────────────────────────────────

test.describe("Regresión: routing no debe ir a choose-alias con currentStep=biometric_setup", () => {
  test.skip(!isMock, "Requiere mock mode (E2E_MODE=mock)");

  /**
   * BUG: Usuario en biometric_setup era enviado a choose-alias.
   * Causa raíz: mock.getOnboardingStatus() siempre devolvía "completed" sin importar el user.
   * Fix: ahora el mock devuelve el estado real del usuario actual (por userId).
   */
  test("biometric_setup NO debe ir a choose-alias (regresión)", async ({ page }) => {
    await loginWith(page, USERS.biometric.email);

    // Esperar a que la navegación se resuelva
    await page.waitForTimeout(2_000);

    const url = page.url();
    expect(url).toMatch(/biometric-setup/i);
    expect(url).not.toMatch(/choose-alias/i);
  });
});
