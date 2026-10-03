// Pedir ajuda sem mouse e sem tela de toque (WCAG 2.1.1).
const { test, funcionalidade, cenario, Dado, Quando, Entao, E, expect } = require('../suporte/bdd');
const { focoAtual } = require('../suporte/teclado');
const { semear, abrir } = require('./ajudantes');

/**
 * Aperta Tab até o foco do navegador chegar num elemento cujo nome começa por `inicio`.
 * Cada parada aparece no painel "Foco do teclado" da legenda.
 */
async function tabAte(page, legenda, inicio, maximo = 20) {
  for (let i = 0; i < maximo; i++) {
    await page.keyboard.press('Tab');
    // O Flutter leva o foco do navegador para o elemento logo depois do Tab.
    const chegou = await page
      .waitForFunction((inicio) => (document.activeElement?.getAttribute('aria-label') || document.activeElement?.textContent || '').startsWith(inicio), inicio, { timeout: 500 })
      .then(() => true, () => false);
    await legenda.foco(`Tab → ${await focoAtual(page)}`);
    if (chegou) return true;
  }
  return false;
}

const abrirApp = () =>
  Dado('que abro o HelpUS com dois contatos salvos', async ({ page }) => {
    await semear(page);
    await abrir(page);
  });

funcionalidade('Teclado', () => {
  test.skip(({ isMobile }) => isMobile, 'teclado físico só no computador');

  cenario('Tab até "Pedir ajuda" e Enter abre o WhatsApp', [
    abrirApp(),
    Quando('aperto Tab até o botão "Pedir ajuda"', async ({ page, legenda }) => {
      expect(await tabAte(page, legenda, 'Pedir ajuda'), 'Tab precisa chegar no botão Pedir ajuda').toBe(true);
    }),
    E('aperto Enter', async ({ page, mundo }) => {
      const [whatsapp] = await Promise.all([page.waitForEvent('popup'), page.keyboard.press('Enter')]);
      mundo.url = decodeURIComponent(whatsapp.url());
      await whatsapp.close();
    }),
    Entao('o WhatsApp abre com o link do Google Maps', async ({ mundo }) => {
      expect(mundo.url).toContain('google.com/maps?q=');
    }),
  ]);
  // Trocar de aba e percorrer a tela nova pelo Tab: 05-navegabilidade.
});
