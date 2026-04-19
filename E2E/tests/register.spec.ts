import { test, expect } from "@playwright/test";
import { isMock, waitForDashboard } from "../helpers/auth";

test.describe("Register", () => {
  const unique = Date.now();

  test("muestra formulario de registro (usuario, contraseñas, términos)", async ({
    page,
  }) => {
    await page.goto("/register");
    await expect(page.getByText("Crear Cuenta").first()).toBeVisible();
    await expect(page.getByTestId("register-username")).toBeVisible();
    await expect(page.getByTestId("register-password")).toBeVisible();
    await expect(page.getByTestId("register-confirm-password")).toBeVisible();
    await expect(page.getByTestId("register-accept-terms")).toBeVisible();
    await expect(
      page.getByText("Acepto los términos y condiciones"),
    ).toBeVisible();
  });

  test("error con username vacío", async ({ page }) => {
    await page.goto("/register");
    await page.getByTestId("register-button").click();
    await expect(
      page.getByText("Ingresa correo, RUT o nombre de usuario"),
    ).toBeVisible();
  });

  test("error con correo inválido", async ({ page }) => {
    await page.goto("/register");
    await page.getByTestId("register-username").fill("a@b");
    await page.getByTestId("register-password").fill("Test1234!");
    await page.getByTestId("register-confirm-password").fill("Test1234!");
    await page.getByTestId("register-button").click();
    await expect(page.getByText("Ingresa un correo válido")).toBeVisible();
  });

  test("error si contraseñas no coinciden", async ({ page }) => {
    await page.goto("/register");
    await page.getByTestId("register-username").fill("testuser_e2e");
    await page.getByTestId("register-password").fill("Test1234!");
    await page.getByTestId("register-confirm-password").fill("Otro1234!");
    await page.getByTestId("register-button").click();
    await expect(page.getByText("Las contraseñas no coinciden")).toBeVisible();
  });

  test("registro con usuario (nickname) exitoso", async ({ page }) => {
    await page.goto("/register");
    await page.getByTestId("register-username").fill(`e2e_${unique}`);
    await page.getByTestId("register-password").fill("Test1234!");
    await page.getByTestId("register-confirm-password").fill("Test1234!");
    await page.getByTestId("register-accept-terms").click();
    await page.getByTestId("register-button").click();
    await waitForDashboard(page);
  });

  test("registro con correo y términos aceptados", async ({ page }) => {
    const email = isMock
      ? `mock_reg_${unique}@test.com`
      : `reg_ok_${unique}@test.com`;

    await page.goto("/register");
    await page.getByTestId("register-username").fill(email);
    await page.getByTestId("register-password").fill("Test1234!");
    await page.getByTestId("register-confirm-password").fill("Test1234!");
    await page.getByTestId("register-accept-terms").click();
    await page.getByTestId("register-button").click();
    await waitForDashboard(page);
  });
});
