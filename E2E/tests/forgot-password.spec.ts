import { test, expect } from "@playwright/test";

test.describe("Forgot Password", () => {
  test("muestra pantalla de recuperación", async ({ page }) => {
    await page.goto("/forgot-password");
    await expect(page.getByText("Recuperar contraseña")).toBeVisible();
    await expect(page.getByTestId("forgot-password-email")).toBeVisible();
    await expect(page.getByTestId("forgot-password-submit")).toBeVisible();
  });

  test("error con correo vacío", async ({ page }) => {
    await page.goto("/forgot-password");
    await page.getByTestId("forgot-password-submit").click();
    await expect(page.getByText("Ingresa tu correo", { exact: true })).toBeVisible();
  });

  test("error con correo inválido", async ({ page }) => {
    await page.goto("/forgot-password");
    await page.getByTestId("forgot-password-email").fill("badmail");
    await page.getByTestId("forgot-password-submit").click();
    await expect(page.getByText("Ingresa un correo válido")).toBeVisible();
  });

  test("envío con correo válido muestra confirmación", async ({ page }) => {
    await page.goto("/forgot-password");
    await page.getByTestId("forgot-password-email").fill("any@example.com");
    await page.getByTestId("forgot-password-submit").click();
    await expect(
      page.getByText(/enviaremos|instrucciones|restablecer/i),
    ).toBeVisible({ timeout: 10_000 });
  });

  test("enlace 'Iniciar Sesión' navega a login", async ({ page }) => {
    await page.goto("/forgot-password");
    await page.getByText("Iniciar Sesión", { exact: true }).click();
    await expect(page).toHaveURL(/login/);
  });
});
