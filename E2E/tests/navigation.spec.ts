import { test, expect } from "@playwright/test";

test.describe("Navegación entre pantallas (sin login)", () => {
  test("login → register → login", async ({ page }) => {
    await page.goto("/login");
    await expect(page.getByText("Te damos la bienvenida")).toBeVisible();

    await page.getByText("crea tu cuenta").click();
    await expect(page).toHaveURL(/register/);
    await expect(page.getByText("Crear Cuenta").first()).toBeVisible();

    await page.getByText("Iniciar Sesión", { exact: true }).click();
    await expect(page).toHaveURL(/login/);
  });

  test("login → forgot-password → login", async ({ page }) => {
    await page.goto("/login");
    await page.getByText("¿No tienes tu contraseña?").click();
    await expect(page).toHaveURL(/forgot-password/);

    await page.getByText("Iniciar Sesión", { exact: true }).click();
    await expect(page).toHaveURL(/login/);
  });
});
