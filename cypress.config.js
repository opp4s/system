import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    // URL da instância Chatwoot com o plugin instalado
    baseUrl: process.env.CYPRESS_BASE_URL || 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.{js,ts}',
    supportFile: 'cypress/support/e2e.js',
    viewportWidth:  1440,
    viewportHeight: 900,
    video: false,
    screenshotOnRunFailure: true,
    defaultCommandTimeout: 10000,
    retries: { runMode: 1, openMode: 0 },
  },
  env: {
    // Override via CYPRESS_* env vars or cypress.env.json
    ACCOUNT_ID:    2,
    ADMIN_EMAIL:   'admin@example.com',
    ADMIN_PASSWORD: 'Password123!',
  },
});
