import { test, expect } from "@playwright/test";
import {
  loginViaUI,
  registerViaApi,
  freshApiUser,
  MOCK_USER,
  waitForDashboard,
  isMock,
} from "../helpers/auth";

test.describe("Login", () => {
  const apiUser = freshApiUser();
  // En mock mode usamos el email real del usuario demo para pasar isValidEmail()
  const creds = isMock
    ? { username: MOCK_USER.username, email: "demo@walvy.mock", password: MOCK_USER.password }
    : { username: apiUser.username, email: apiUser.username, password: apiUser.password };

  test.beforeAll(async ({ request }) => {
    if (!isMock) {
      await registerViaApi(request, apiUser);
    }
  });

  test("muestra pantalla de login", async ({ page }) => {
    await page.goto("/login");
    await expect(page.getByText("Te damos la bienvenida")).toBeVisible();
    await expect(page.getByTestId("login-email")).toBeVisible();
    await expect(page.getByTestId("login-password")).toBeVisible();
    await expect(page.getByTestId("login-button")).toBeVisible();
  });

  test("error con email vacío", async ({ page }) => {
    await page.goto("/login");
    await page.getByTestId("login-button").click();
    await expect(
      page.getByText("Ingresa tu correo electrónico"),
    ).toBeVisible();
  });

  test("error con contraseña vacía", async ({ page }) => {
    await page.goto("/login");
    await page.getByTestId("login-email").fill("demo@walvy.mock");
    await page.getByTestId("login-button").click();
    await expect(page.getByText("Ingresa tu contraseña")).toBeVisible();
  });

  test("login exitoso lleva al dashboard", async ({ page }) => {
    await loginViaUI(page, creds.email, creds.password);
    await waitForDashboard(page);
  });

  test("login con credenciales incorrectas muestra error", async ({
    page,
  }) => {
    await loginViaUI(page, creds.email, "WrongPass999!");
    await expect(
      page.getByText(/no se pudo|credenciales|incorrecta|inválido/i),
    ).toBeVisible({ timeout: 10_000 });
  });
});
