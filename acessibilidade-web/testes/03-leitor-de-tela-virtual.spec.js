// "NVDA simulado": registra e fala cada frase que um leitor de tela falaria.
// As asserções usam as falas originais do leitor virtual; a legenda e a voz
// mostram a versão em português.
const { funcionalidade, cenario, Dado, Quando, Entao, E, expect } = require('../suporte/bdd');
const { semear, abrir } = require('./ajudantes');

const TITULO = /^heading, HelpUS, level \d$/;
const BOTAO_AJUDA = /^button, Pedir ajuda\b/;

const ligarNvda = (texto = 'que abro o HelpUS com o NVDA ligado', dados = {}) =>
  Dado(texto, async ({ page, leitor }) => {
    await semear(page, dados);
    await abrir(page);
    await leitor.ligar();
  });

// Repete um comando de navegação até o leitor parar de encontrar itens novos
// (o leitor virtual dá a volta na página e recomeça do primeiro).
async function percorrer(leitor, comando, limite = 30) {
  const vistos = [];
  for (let i = 0; i < limite; i++) {
    const [frase] = await leitor.comando(comando);
    if (!frase || vistos.includes(frase)) break;
    vistos.push(frase);
  }
  return vistos;
}

funcionalidade('Leitura da tela com leitor de tela (NVDA simulado)', () => {
  cenario('Ler a tela de ajuda com a seta para baixo', [
    ligarNvda(),
    Quando('leio com a seta para baixo até o botão "Pedir ajuda"', async ({ leitor, mundo }) => {
      mundo.botao = await leitor.lerAte(BOTAO_AJUDA);
    }),
    Entao('o NVDA lê o título "HelpUS" antes do botão', async ({ leitor, mundo }) => {
      const falas = leitor.falasOriginais();
      const posTitulo = falas.findIndex((f) => TITULO.test(f));
      expect(posTitulo, 'o título "HelpUS" não foi lido').toBeGreaterThanOrEqual(0);
      expect(falas.indexOf(mundo.botao), 'o botão precisa vir logo depois do título').toBeGreaterThan(posTitulo);
    }),
    E('o botão diz para quem vai a localização', async ({ mundo }) => {
      expect(mundo.botao).toContain('Envia sua localização pelo WhatsApp para Maria');
    }),
    Quando('continuo lendo até o fim da tela', async ({ leitor }) => {
      await leitor.lerAte('end of document');
    }),
    Entao('os números de emergência são lidos com o nome do serviço', async ({ leitor }) => {
      for (const nome of ['192 SAMU', '193 Bombeiros', '190 Polícia']) {
        expect(leitor.falasOriginais()).toContain(`button, ${nome}`);
      }
    }),
    E('as abas dizem qual está selecionada e quantas são', async ({ leitor }) => {
      expect(leitor.falasOriginais()).toContain('tab, Ajuda, selected, position 1, set size 3');
    }),
    E('nenhum botão, aba ou imagem é lido sem nome', async ({ leitor }) => {
      // "group" sozinho não entra: é a área de rolagem que o Flutter web põe em
      // volta da tela inteira. É só um contêiner; o que tem dentro tem nome.
      expect(leitor.falasOriginais().filter((f) => /^(button|tab|link|img|image)$/.test(f.trim()))).toEqual([]);
    }),
  ]);

  cenario('Navegar pelos títulos com a tecla H', [
    ligarNvda(),
    Quando('percorro a tela inteira com a tecla H', async ({ leitor, mundo }) => {
      mundo.titulos = await percorrer(leitor, 'moveToNextHeading');
    }),
    Entao('o primeiro título é o nome do app, "HelpUS"', async ({ mundo }) => {
      expect(mundo.titulos[0]).toMatch(TITULO);
    }),
    E('a seção "Ligar para emergência" também é um título', async ({ mundo }) => {
      expect(mundo.titulos.some((f) => /^heading, Ligar para emergência, level \d$/.test(f))).toBe(true);
    }),
  ]);

  cenario('Pedir ajuda pelo teclado e ouvir a confirmação', [
    ligarNvda(),
    Quando('aperto Tab até o botão "Pedir ajuda"', async ({ leitor, mundo }) => {
      mundo.botao = await leitor.teclaAte('Tab', BOTAO_AJUDA);
    }),
    Entao('o NVDA anuncia o botão e para quem vai a localização', async ({ mundo }) => {
      expect(mundo.botao).toBe('button, Pedir ajuda, Envia sua localização pelo WhatsApp para Maria.');
    }),
    Quando('aperto Enter', async ({ page, leitor, mundo }) => {
      const [whatsapp] = await Promise.all([page.waitForEvent('popup'), leitor.tecla('Enter')]);
      mundo.url = decodeURIComponent(whatsapp.url());
      await whatsapp.close();
    }),
    Entao('o WhatsApp abre na conversa da Maria', async ({ mundo }) => {
      expect(mundo.url).toContain('wa.me/5548988887777');
    }),
    E('o NVDA avisa que está pegando a localização', async ({ leitor }) => {
      await leitor.esperarFala('polite: Pegando sua localização…');
    }),
    E('anuncia sozinho, uma vez só, que a mensagem está pronta', async ({ leitor }) => {
      await leitor.esperarFala('polite: Mensagem pronta no WhatsApp para Maria. Toque em Enviar.');
      expect(leitor.falasOriginais().filter((f) => f.includes('Mensagem pronta'))).toHaveLength(1);
    }),
    Quando('aperto Tab de novo', async ({ leitor, mundo }) => {
      mundo.falas = await leitor.tecla('Tab');
    }),
    Entao('o foco vai para o outro contato, João, e não volta para o topo', async ({ mundo }) => {
      expect(mundo.falas).toContain('button, João');
    }),
  ]);

  cenario('Sem contatos, o NVDA explica o que fazer', [
    ligarNvda('que abro o HelpUS sem contatos, com o NVDA ligado', { contatos: [] }),
    Quando('leio com a seta para baixo até o botão "Pedir ajuda"', async ({ leitor, mundo }) => {
      mundo.botao = await leitor.lerAte(BOTAO_AJUDA);
    }),
    Entao('o botão avisa que ainda não há contato', async ({ mundo }) => {
      expect(mundo.botao).toBe('button, Pedir ajuda, Nenhum contato cadastrado ainda.');
    }),
    Quando('aciono o botão com Enter', async ({ leitor }) => {
      await leitor.acionar();
    }),
    Entao('o NVDA diz o que fazer e lembra os números de emergência', async ({ leitor }) => {
      await leitor.esperarFala(/^polite: Ninguém para avisar ainda\. Cadastre um contato .*ligue 192 ou 193\.$/);
    }),
  ]);
});
