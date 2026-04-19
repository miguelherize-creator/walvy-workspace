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
  const creds = isMock
    ? MOCK_USER
    : { username: apiUser.username, password: apiUser.password };

  test.beforeAll(async ({ request }) => {
    if (!isMock) {
      await registerViaApi(request, apiUser);
    }
  });

  test("muestra pantalla de login", async ({ page }) => {
    await page.goto("/login");
    await expect(page.getByText("Te damos la bienvenida")).toBeVisible();
    await expect(page.getByTestId("login-username")).toBeVisible();
    await expect(page.getByTestId("login-password")).toBeVisible();
    await expect(page.getByTestId("login-button")).toBeVisible();
  });

  test("error con identificador vacío", async ({ page }) => {
    await page.goto("/login");
    await page.getByTestId("login-button").click();
    await expect(
      page.getByText("Ingresa tu usuario, RUT o correo"),
    ).toBeVisible();
  });

  test("error con contraseña vacía", async ({ page }) => {
    await page.goto("/login");
    await page.getByTestId("login-username").fill("demo");
    await page.getByTestId("login-button").click();
    await expect(page.getByText("Ingresa tu contraseña")).toBeVisible();
  });

  test("login exitoso con nickname lleva al dashboard", async ({ page }) => {
    await loginViaUI(page, creds.username, creds.password);
    await waitForDashboard(page);
    await expect(page.getByText("Puntos acumulados")).toBeVisible({
      timeout: 10_000,
    });
  });

  test("login con credenciales incorrectas muestra error", async ({
    page,
  }) => {
    await loginViaUI(page, creds.username, "WrongPass999!");
    await expect(
      page.getByText(/no se pudo|credenciales|incorrecta|inválido/i),
    ).toBeVisible({ timeout: 10_000 });
  });
});
