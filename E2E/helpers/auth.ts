import { type Page, expect } from "@playwright/test";

const MOCK = (process.env.E2E_MODE ?? "mock") === "mock";
const BACKEND_URL = process.env.BACKEND_URL ?? "http://localhost:3000";

/** Credenciales mock predefinidas en mockService.ts */
export const MOCK_USER = {
  username: "demo",
  password: "123456",
};

/** Datos de usuario para tests E2E contra API real. */
export function freshApiUser() {
  const ts = Date.now();
  return {
    username: `e2e_${ts}@test.com`,
    password: "E2eTest1234!",
  };
}

/** Devuelve credenciales correctas según el modo. */
export function getTestCredentials() {
  if (MOCK) return MOCK_USER;
  const u = freshApiUser();
  return { username: u.username, password: u.password };
}

/** Registra un usuario vía API directa (solo modo API). */
export async function registerViaApi(
  request: any,
  user: { username: string; password: string },
) {
  if (MOCK) return;
  const res = await request.post(`${BACKEND_URL}/auth/register`, {
    data: {
      username: user.username,
      password: user.password,
      acceptTerms: true,
    },
  });
  return res;
}

/** Login vía UI: rellena username + password y pulsa el botón. */
export async function loginViaUI(
  page: Page,
  username: string,
  password: string,
) {
  await page.goto("/login");
  await page.getByTestId("login-username").fill(username);
  await page.getByTestId("login-password").fill(password);
  await page.getByTestId("login-button").click();
}

/**
 * Espera la pantalla de inicio autenticada: tabs (URL `/` en web) o legado `/dashboard`.
 */
export async function waitForDashboard(page: Page) {
  await expect(page).toHaveURL(
    (url) => {
      try {
        const { pathname } = new URL(url);
        if (/login|register|forgot-password|reset-password/i.test(pathname)) {
          return false;
        }
        return (
          pathname === "/" ||
          /dashboard/i.test(pathname) ||
          /\(tabs\)/.test(pathname) ||
          /tabs/i.test(pathname)
        );
      } catch {
        return false;
      }
    },
    { timeout: 15_000 },
  );
}

export const isMock = MOCK;
