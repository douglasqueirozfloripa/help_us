// WCAG 2.2 AA com axe-core em cada tela.
const AxeBuilder = require('@axe-core/playwright').default;
const { funcionalidade, cenario, Dado, Quando, Entao, E, expect } = require('../suporte/bdd');
const { semear, abrir, naTela, botaoAjuda, irPara, resumirViolacoes } = require('./ajudantes');

const REGRAS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];

async function auditar({ page, testInfo }, nome) {
  const r = await new AxeBuilder({ page })
    .withTags(REGRAS)
    .exclude('#qa-legenda')
    // Modo legado: roda tudo nesta página, sem abrir uma aba extra (no modo ao vivo ela apareceria).
    .setLegacyMode(true)
    .analyze();
  await testInfo.attach(`axe — ${nome}.json`, { body: JSON.stringify(r.violations, null, 2), contentType: 'application/json' });
  return r.violations;
}

const abrirApp = () =>
  Dado('que abro o HelpUS com dois contatos salvos', async ({ page }) => {
    await semear(page);
    await abrir(page);
  });

const semViolacoes = () =>
  Entao('nenhuma violação é encontrada', async ({ mundo }) => {
    expect(mundo.violacoes, resumirViolacoes(mundo.violacoes)).toEqual([]);
  });

funcionalidade('WCAG 2.2 AA', () => {
  cenario('Tela de ajuda', [
    abrirApp(),
    Quando('analiso a tela com o axe-core nas regras WCAG 2.2 A e AA', async (ctx) => {
      ctx.mundo.violacoes = await auditar(ctx, 'tela de ajuda');
    }),
    semViolacoes(),
  ]);

  cenario('Tela de ajuda depois do pedido', [
    abrirApp(),
    Quando('toco em "Pedir ajuda"', async ({ page }) => {
      // O WhatsApp abre numa aba nova; aqui só interessa a tela do app.
      page.on('popup', (p) => p.close());
      await botaoAjuda(page).click();
    }),
    Entao('a tela confirma que a mensagem está pronta no WhatsApp', async ({ page }) => {
      await expect(naTela(page, /Mensagem pronta no WhatsApp/)).toBeVisible();
    }),
    Quando('analiso a tela com o axe-core', async (ctx) => {
      ctx.mundo.violacoes = await auditar(ctx, 'depois do pedido');
    }),
    semViolacoes(),
  ]);

  cenario('Eventos', [
    abrirApp(),
    Quando('vou para a aba Eventos', async ({ page }) => {
      await irPara(page, 'Eventos');
      await expect(page.getByRole('heading', { name: 'Cidade' })).toBeVisible();
    }),
    E('analiso a tela com o axe-core', async (ctx) => {
      ctx.mundo.violacoes = await auditar(ctx, 'eventos');
    }),
    semViolacoes(),
  ]);

  cenario('Contatos', [
    abrirApp(),
    Quando('vou para a aba Contatos', async ({ page }) => {
      await irPara(page, 'Contatos');
      await expect(page.getByRole('heading', { name: 'Sobre você' })).toBeVisible();
    }),
    E('analiso a tela com o axe-core', async (ctx) => {
      ctx.mundo.violacoes = await auditar(ctx, 'contatos');
    }),
    semViolacoes(),
  ]);

  cenario('Idioma da página é português (WCAG 3.1.1)', [
    abrirApp(),
    Entao('o <html> declara o idioma português', async ({ page }) => {
      await expect(page.locator('html')).toHaveAttribute('lang', /^pt/);
    }),
  ]);
});
