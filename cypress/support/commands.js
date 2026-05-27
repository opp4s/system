// Custom Cypress commands for Funnels plugin tests

const ACCOUNT_ID    = () => Cypress.env('ACCOUNT_ID')    || 2;
const ADMIN_EMAIL   = () => Cypress.env('ADMIN_EMAIL')   || 'admin@example.com';
const ADMIN_PASSWORD = () => Cypress.env('ADMIN_PASSWORD') || 'Password123!';

/**
 * Login via Chatwoot UI and wait for the dashboard to be ready.
 */
Cypress.Commands.add('loginChatwoot', (
  email    = ADMIN_EMAIL(),
  password = ADMIN_PASSWORD(),
) => {
  cy.session([email, password], () => {
    cy.visit('/app/login');
    cy.get('[data-testid="email-input"], input[type="email"]').type(email);
    cy.get('[data-testid="password-input"], input[type="password"]').type(password);
    cy.get('[data-testid="login-submit"], button[type="submit"]').click();
    cy.url().should('include', '/dashboard');
  });
});

/**
 * Navigate to funnels section for a given account.
 */
Cypress.Commands.add('visitFunnels', (accountId = ACCOUNT_ID()) => {
  cy.visit(`/app/accounts/${accountId}/funnels`);
  cy.url().should('include', '/funnels');
});

/**
 * Create a funnel via UI and return its name.
 */
Cypress.Commands.add('createFunnel', (name) => {
  cy.contains('Novo funil').click();
  cy.get('input[placeholder*="Nome do funil"], input[placeholder*="Funnel name"]')
    .clear().type(name);
  cy.contains('button', /^Criar$|^Create$/).click();
  cy.contains(name).should('be.visible');
});

/**
 * API shortcut: delete all funnels for cleanup via the API.
 */
Cypress.Commands.add('cleanupFunnels', (accountId = ACCOUNT_ID()) => {
  cy.request('GET', `/api/v1/accounts/${accountId}/funnels`).then(({ body }) => {
    (body || []).forEach(f => {
      cy.request('DELETE', `/api/v1/accounts/${accountId}/funnels/${f.id}`);
    });
  });
});
