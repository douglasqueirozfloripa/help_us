// O que o navegador entrega ao NVDA (Windows) e ao VoiceOver (macOS).
// Aqui mora a regra de negócio principal: um clique → WhatsApp com o GPS.
const { funcionalidade, cenario, Dado, Quando, Entao, E, expect } = require('../suporte/bdd');
const { semear, abrir, anunciado, naTela, botaoAjuda, irPara } = require('./ajudantes');

const abrirApp = () =>
  Dado('que abro o HelpUS com dois contatos salvos', async ({ page }) => {
    await semear(page);
    await abrir(page);
  });

// Toca no botão e guarda o endereço que o app abriu no WhatsApp.
const pedirAjuda = () =>
  Quando('toco em "Pedir ajuda"', async ({ page, mundo }) => {
    const [whatsapp] = await Promise.all([page.waitForEvent('popup'), botaoAjuda(page).click()]);
    mundo.url = decodeURIComponent(whatsapp.url());
    await whatsapp.close();
  });

funcionalidade('Pedir ajuda com um clique', () => {
  cenario('O botão existe, tem nome e é o primeiro controle depois do evento', [
    abrirApp(),
    Entao('o botão "Pedir ajuda" está na tela', async ({ page }) => {
      await expect(botaoAjuda(page)).toBeVisible();
    }),
    E('o título "HelpUS" também', async ({ page }) => {
      await expect(page.getByRole('heading', { name: 'HelpUS' })).toBeVisible();
    }),
  ]);

  cenario('Um clique abre o WhatsApp do contato com o link do Google Maps', [
    abrirApp(),
    pedirAjuda(),
    Entao('o WhatsApp abre na conversa da Maria', async ({ mundo }) => {
      expect(mundo.url).toContain('wa.me/5548988887777');
    }),
    E('a mensagem leva o link do Google Maps com a posição do GPS', async ({ mundo }) => {
      expect(mundo.url).toContain('https://www.google.com/maps?q=-27.585531,-48.614722');
    }),
    E('a tela confirma que a mensagem está pronta', async ({ page }) => {
      await expect(naTela(page, 'Mensagem pronta no WhatsApp para Maria. Toque em Enviar.')).toBeVisible();
    }),
    E('o leitor de tela fala a confirmação sozinho, uma vez só', async ({ page }) => {
      await expect
        .poll(async () => (await anunciado(page)).filter((f) => f.startsWith('Mensagem pronta')))
        .toEqual(['Mensagem pronta no WhatsApp para Maria. Toque em Enviar.']);
    }),
  ]);

  cenario('Dentro de um evento, o pedido vai para a central do evento', [
    abrirApp(),
    Quando('participo da Feira Inclusiva de São José na aba Eventos', async ({ page }) => {
      await irPara(page, 'Eventos');
      await page.getByRole('button', { name: 'Participar do evento Feira Inclusiva de São José' }).click();
    }),
    E('volto para a aba Ajuda', async ({ page }) => {
      await irPara(page, 'Ajuda');
    }),
    pedirAjuda(),
    Entao('o WhatsApp abre na conversa da central do evento', async ({ mundo }) => {
      expect(mundo.url).toContain('wa.me/5548999990001');
    }),
    E('a mensagem diz de qual evento é o pedido', async ({ mundo }) => {
      expect(mundo.url).toContain('Evento: Feira Inclusiva de São José');
    }),
  ]);

  cenario('Sem contatos, o app explica o que fazer', [
    Dado('que abro o HelpUS sem nenhum contato salvo', async ({ page }) => {
      await semear(page, { contatos: [] });
      await abrir(page);
    }),
    Quando('toco em "Pedir ajuda"', async ({ page }) => {
      await botaoAjuda(page).click();
    }),
    Entao('a tela pede para cadastrar um contato', async ({ page }) => {
      await expect(naTela(page, /Cadastre um contato/)).toBeVisible();
    }),
  ]);

  cenario('Botões de emergência têm nome', [
    abrirApp(),
    Entao('SAMU, Bombeiros e Polícia aparecem com o número e o nome do serviço', async ({ page }) => {
      for (const nome of ['192 SAMU', '193 Bombeiros', '190 Polícia']) {
        await expect(page.getByRole('button', { name: nome })).toHaveCount(1);
      }
    }),
  ]);
});
