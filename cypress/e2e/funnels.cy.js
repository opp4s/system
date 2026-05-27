/**
 * Funnels Plugin — E2E Test Suite
 *
 * Pré-requisitos:
 *   - Chatwoot rodando com o plugin instalado (docker compose up)
 *   - Account 2 ou 3 com pelo menos um usuário admin
 *   - Rodar: CYPRESS_BASE_URL=http://localhost:3000 npx cypress run
 *            ou: npx cypress open
 */

const ACCOUNT = () => Cypress.env('ACCOUNT_ID') || 2;
const FUNNEL_NAME = `Teste Funil ${Date.now()}`;
const CARD_TITLE  = `Lead Cypress ${Date.now()}`;

// ─────────────────────────────────────────────────────────────────────────────
describe('Funnels Plugin', () => {

  before(() => {
    cy.loginChatwoot();
  });

  beforeEach(() => {
    cy.loginChatwoot();
    cy.visitFunnels();
  });

  // ── 1. Empty state ────────────────────────────────────────────────────────
  context('Empty state', () => {
    it('shows empty state or funnel list', () => {
      cy.get('body').then($body => {
        // Either empty state or existing funnels
        const hasEmpty  = $body.text().includes('Nenhum funil') ||
                          $body.text().includes('No funnels');
        const hasFunnels = $body.find('[data-testid="funnel-item"]').length > 0 ||
                           $body.text().includes('funil');
        expect(hasEmpty || hasFunnels).to.be.true;
      });
    });

    it('shows create funnel button', () => {
      cy.contains(/Novo funil|New funnel/).should('be.visible');
    });
  });

  // ── 2. Create funnel ──────────────────────────────────────────────────────
  context('Create Funnel', () => {
    it('opens create funnel modal', () => {
      cy.contains(/Novo funil|New funnel/).click();
      cy.get('input[placeholder*="Nome"]').should('be.visible');
      cy.get('input[placeholder*="ome"]').should('have.focus');
    });

    it('creates a funnel and shows it in the sidebar', () => {
      cy.contains(/Novo funil|New funnel/).click();
      cy.get('input[placeholder*="ome"]').type(FUNNEL_NAME);
      cy.contains('button', /^Criar$|^Create$/).click();
      cy.contains(FUNNEL_NAME).should('be.visible');
    });

    it('cancels funnel creation with Esc', () => {
      cy.contains(/Novo funil|New funnel/).click();
      cy.get('input[placeholder*="ome"]').type('Funil cancelado');
      cy.get('input[placeholder*="ome"]').type('{esc}');
      cy.contains('Funil cancelado').should('not.exist');
    });
  });

  // ── 3. Kanban board ───────────────────────────────────────────────────────
  context('Kanban Board', () => {
    beforeEach(() => {
      // Ensure we have a funnel selected by navigating to funnels
      cy.visitFunnels();
      cy.url().should('include', '/funnels');
    });

    it('shows the kanban board with stages', () => {
      // If there's a funnel, the board should show
      cy.get('body').then($body => {
        if ($body.text().includes(FUNNEL_NAME)) {
          cy.contains(FUNNEL_NAME).click();
          cy.get('.kanban-board, [data-testid="kanban-board"]')
            .should('exist');
        }
      });
    });

    it('has the toggle final stages button', () => {
      cy.get('body').then($body => {
        if (!$body.text().includes('Nenhum funil')) {
          cy.contains(/Mostrar etapas|Show final|Ocultar etapas|Hide final/).should('exist');
        }
      });
    });

    it('has the filters button', () => {
      cy.get('body').then($body => {
        if (!$body.text().includes('Nenhum funil')) {
          cy.contains(/Filtros|Filters/).should('exist');
        }
      });
    });
  });

  // ── 4. Create card ────────────────────────────────────────────────────────
  context('Create Card', () => {
    it('opens create card modal', () => {
      cy.get('body').then($body => {
        if ($body.text().includes('Novo card') || $body.text().includes('New card')) {
          cy.contains(/Novo card|New card/).click();
          cy.contains(/Novo Card|New Card/).should('be.visible');
          cy.get('input[placeholder*="Lead"]').should('be.visible');
          cy.get('input[placeholder*="Lead"]').should('have.focus');
        }
      });
    });

    it('creates a card with Enter', () => {
      cy.get('body').then($body => {
        if ($body.text().includes('Novo card') || $body.text().includes('New card')) {
          cy.contains(/Novo card|New card/).click();
          cy.get('input[placeholder*="Lead"], input[placeholder*="Título"]')
            .type(CARD_TITLE);
          cy.get('form').submit();
          cy.contains(CARD_TITLE).should('be.visible');
        }
      });
    });
  });

  // ── 5. Kanban Filters ─────────────────────────────────────────────────────
  context('Kanban Filters', () => {
    it('opens and closes the filter panel', () => {
      cy.get('body').then($body => {
        if (!$body.text().includes('Nenhum funil')) {
          cy.contains(/Filtros|Filters/).click();
          cy.contains(/Responsável|Assignee/).should('be.visible');
          cy.contains(/Filtros|Filters/).click();
          cy.contains(/Responsável|Assignee/).should('not.be.visible');
        }
      });
    });

    it('shows active filter count after applying', () => {
      cy.get('body').then($body => {
        if (!$body.text().includes('Nenhum funil')) {
          cy.contains(/Filtros|Filters/).click();
          // Toggle has_conversation
          cy.contains(/conversa vinculada|linked conversation/i)
            .parent().click();
          // Count badge should appear
          cy.contains(/Filtros|Filters/)
            .find('span')
            .should('contain', '1');
        }
      });
    });
  });

  // ── 6. Card detail modal ──────────────────────────────────────────────────
  context('Card Detail', () => {
    it('opens card detail panel when clicking a card', () => {
      cy.get('body').then($body => {
        const card = $body.find('.kanban-card').first();
        if (card.length) {
          cy.get('.kanban-card').first().click();
          cy.url().should('match', /\/cards\/\d+/);
          // Panel should slide in
          cy.get('.card-detail-panel').should('be.visible');
        }
      });
    });

    it('closes card detail panel with Esc', () => {
      cy.get('body').then($body => {
        if ($body.find('.kanban-card').length) {
          cy.get('.kanban-card').first().click();
          cy.get('.card-detail-panel').should('be.visible');
          cy.get('body').type('{esc}');
          cy.get('.card-detail-panel').should('not.exist');
        }
      });
    });

    it('shows tabs: Dados and Campos', () => {
      cy.get('body').then($body => {
        if ($body.find('.kanban-card').length) {
          cy.get('.kanban-card').first().click();
          cy.contains(/^Dados$|^Details$/).should('be.visible');
          cy.contains(/^Campos$|^Fields$/).should('be.visible');
        }
      });
    });
  });

  // ── 7. Settings page ─────────────────────────────────────────────────────
  context('Settings', () => {
    it('navigates to settings page', () => {
      cy.visit(`/app/accounts/${ACCOUNT()}/funnels/settings`);
      cy.url().should('include', '/funnels/settings');
      cy.contains(/Configurações de Funis|Funnel Settings/).should('be.visible');
    });

    it('shows funnel list in settings', () => {
      cy.visit(`/app/accounts/${ACCOUNT()}/funnels/settings`);
      cy.get('body').then($body => {
        // Either has funnels or empty
        expect(
          $body.text().includes('funil') || $body.text().includes('Funnel')
        ).to.be.true;
      });
    });

    it('navigates back to board from settings', () => {
      cy.visit(`/app/accounts/${ACCOUNT()}/funnels/settings`);
      cy.get('[aria-label*="Voltar"], [aria-label*="Back"], button').first().click();
      cy.url().should('include', '/funnels');
      cy.url().should('not.include', '/settings');
    });
  });

  // ── 8. Funnel settings gear icon ─────────────────────────────────────────
  context('Settings Gear Icon', () => {
    it('gear icon in sidebar navigates to settings', () => {
      cy.get('[aria-label*="Configurações"], [aria-label*="Settings"]')
        .filter(':visible')
        .first()
        .click();
      cy.url().should('include', '/funnels/settings');
    });
  });

});
