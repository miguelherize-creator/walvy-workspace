import { test, expect } from "@playwright/test";
import {
  loginViaUI,
  registerViaApi,
  freshApiUser,
  MOCK_USER,
  waitForDashboard,
  isMock,
} from "../helpers/auth";

test.describe("Dashboard (post-login)", () => {
  const apiUser = freshApiUser();
  const creds = isMock
    ? MOCK_USER
    : { username: apiUser.username, password: apiUser.password };

  test.beforeAll(async ({ request }) => {
    if (!isMock) {
      await registerViaApi(request, apiUser);
    }
  });

  test.beforeEach(async ({ page }) => {
    await loginViaUI(page, creds.username, creds.password);
    await waitForDashboard(page);
  });

  test("muestra elementos principales del dashboard", async ({ page }) => {
    await expect(page.getByText("Puntos acumulados")).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText("Ranking Financiero")).toBeVisible();
    await expect(page.getByText("Resumen")).toBeVisible();
    await expect(page.getByText("Último movimiento")).toBeVisible();
  });
});
