import { defineConfig, devices } from "@playwright/test";

/**
 * Walvy E2E — Playwright sobre Expo Web.
 *
 * Modos de ejecución:
 *
 *   MOCK (sin backend/DB — por defecto):
 *     cd e2e && npm test
 *
 *   FULL STACK (backend + DB corriendo):
 *     cd e2e && cross-env E2E_MODE=api npm test
 *     (requiere PostgreSQL + backend en :3000)
 *
 * El frontend arranca automáticamente en :8081.
 */

const MOCK = (process.env.E2E_MODE ?? "mock") === "mock";
const FRONTEND_URL = process.env.FRONTEND_URL ?? "http://localhost:8081";
const BACKEND_URL = process.env.BACKEND_URL ?? "http://localhost:3000";
const SLOW_MO = parseInt(process.env.SLOW_MO ?? "0", 10);

const webServers: Array<{
  command: string;
  cwd?: string;
  port: number;
  reuseExistingServer: boolean;
  timeout: number;
  env?: Record<string, string>;
}> = [];

if (!MOCK) {
  webServers.push({
    command: "npm run start:dev",
    cwd: "../Backend/backend",
    port: 3000,
    reuseExistingServer: true,
    timeout: 30_000,
    env: {
      CORS_ORIGIN: "http://localhost:8081,http://127.0.0.1:8081",
    },
  });
}

webServers.push({
    command: "npx expo start --web --port 8081",
  cwd: "../Frontend/rork-checkapp/expo",
  port: 8081,
  reuseExistingServer: true,
  timeout: 60_000,
  env: {
    EXPO_PUBLIC_BACKEND_BASE_URL: BACKEND_URL,
    EXPO_PUBLIC_USE_MOCK_MODE: MOCK ? "true" : "false",
  },
});

export default defineConfig({
  testDir: "./tests",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [["html", { open: "never" }], ["list"]],

  use: {
    baseURL: FRONTEND_URL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    actionTimeout: SLOW_MO ? 60_000 : 10_000,
    navigationTimeout: SLOW_MO ? 120_000 : 30_000,
  },

  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        launchOptions: { slowMo: SLOW_MO },
      },
    },
  ],

  webServer: webServers,
});
