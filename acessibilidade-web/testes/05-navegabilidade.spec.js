// Trocar de aba pelo teclado e percorrer a tela nova sem cair no menu (WCAG 2.4.3).
const { test, funcionalidade, cenario, Dado, Quando, Entao, E, expect } = require('../suporte/bdd');
const { focoAtual, navegar } = require('../suporte/teclado');
const { semear, abrir } = require('./ajudantes');
// Os mesmos eventos que o app lista.
const EVENTOS = require('../../assets/dados/eventos.json');

const ehAba = (foco) => foco.startsWith('tab: ');

/**
 * Aperta Tab e devolve a nova parada do foco do navegador. O Flutter move o
 * foco um instante depois da tecla; se ele não sair de `anterior`, a parada se
 * repete (e o NVDA não fala nada naquele Tab).
 */
async function tab(page, legenda, anterior) {
  await page.keyboard.press('Tab');
  let foco = anterior;
  for (let t = 0; t < 20 && foco === anterior; t++) {
    await page.waitForTimeout(100);
    foco = await focoAtual(page);
  }
  await legenda.foco(`Tab → ${foco}`);
  return foco;
}

funcionalidade('Navegabilidade', () => {
  test.skip(({ isMobile }) => isMobile, 'teclado físico só no computador');

  cenario('Enter na aba Eventos e o Tab percorre a tela, sem pular para o menu', [
    Dado('que abro o HelpUS com dois contatos salvos', async ({ page }) => {
      await semear(page);
      await abrir(page);
    }),
    E('aperto Tab até a aba "Eventos"', async ({ page, legenda }) => {
      const paradas = await navegar(page, legenda, 'Tab', (f) => f.startsWith('tab: Eventos'));
      expect(paradas.at(-1), 'Tab precisa chegar na aba Eventos').toMatch(/^tab: Eventos/);
    }),
    Quando('aperto Enter', async ({ page }) => {
      await page.keyboard.press('Enter');
    }),
    Entao('o foco vai para o título da tela, "Eventos"', async ({ page, legenda, mundo }) => {
      // O NVDA fala "título nível 2, Eventos".
      await expect.poll(() => focoAtual(page)).toMatch(/^h[1-6]: Eventos$/);
      mundo.titulo = await focoAtual(page);
      await legenda.foco(`Enter → ${mundo.titulo}`);
    }),
    Quando('continuo apertando Tab até voltar ao menu de abas', async ({ page, legenda, mundo }) => {
      mundo.paradas = [];
      let foco = mundo.titulo;
      for (let i = 0; i < 40 && !ehAba(foco); i++) {
        foco = await tab(page, legenda, foco);
        mundo.paradas.push(foco);
      }
    }),
    Entao('o primeiro Tab entra na tela, em "Entrar no evento pelo QR code"', async ({ mundo }) => {
      expect(mundo.paradas[0]).toMatch(/^button: Entrar no evento pelo QR code/);
    }),
    E('cada Tab leva o foco a um controle novo, que o leitor de tela anuncia', async ({ mundo }) => {
      const repetidas = mundo.paradas.filter((f, i) => f === (mundo.paradas[i - 1] ?? mundo.titulo));
      expect(repetidas, 'um Tab que não move o foco do navegador fica mudo no NVDA').toEqual([]);
    }),
    E('o Tab passa por todos os eventos e contatos da organização antes do menu', async ({ mundo }) => {
      const conteudo = mundo.paradas.filter((f) => !ehAba(f));
      for (const evento of EVENTOS) {
        for (const adm of evento.administradores ?? []) {
          expect(conteudo).toContainEqual(expect.stringContaining(`Falar no WhatsApp com ${adm.nome}`));
        }
        expect(conteudo).toContainEqual(expect.stringContaining(`Participar do evento ${evento.nome}`));
      }
    }),
    E('no fim da tela o foco vai para a primeira aba, "Ajuda", e não para "Contatos"', async ({ mundo }) => {
      expect(mundo.paradas.at(-1)).toMatch(/^tab: Ajuda/);
    }),
  ]);
});
