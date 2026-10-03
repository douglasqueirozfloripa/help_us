/**
 * BDD em português sobre o Playwright Test.
 *
 *   funcionalidade('Pedir ajuda com um clique', () => {
 *     cenario('Um clique abre o WhatsApp do contato', [
 *       Dado('que abro o HelpUS com dois contatos salvos', async ({ page }) => { ... }),
 *       Quando('toco em "Pedir ajuda"', async ({ page, mundo }) => { ... }),
 *       Entao('o WhatsApp abre na conversa da Maria', async ({ mundo }) => { ... }),
 *     ]);
 *   });
 *
 * Cada passo vira um test.step (aparece no relatório HTML) e atualiza a
 * legenda do vídeo: o passo em execução fica em destaque, os concluídos
 * ganham ✓ e o que falhar fica em vermelho com a mensagem de erro.
 *
 * Os passos recebem um único objeto de contexto: as fixtures (page, leitor,
 * legenda, narrador...) e `mundo`, um objeto vazio para passar dados de um
 * passo para o outro.
 *
 * No modo ao vivo (FALAR=1), cada passo espera o locutor de navegação terminar
 * de anunciar os componentes em que mexeu, antes de ganhar o ✓.
 *
 * PASSO_MS (padrão 600) é a pausa entre passos, para o vídeo ficar legível.
 * Em CI, use PASSO_MS=0.
 */
const { test: base, expect } = require('@playwright/test');
const { Legenda } = require('./legenda');
const { LeitorNvda, traduzirFala } = require('./leitor-nvda');
const { Narrador } = require('./narrador');
const { LocutorNavegacao } = require('./locutor');
const fs = require('node:fs');
const path = require('node:path');
const { juntarAudioNoVideo, converterParaMp4 } = require('./video');

// Pasta com os vídeos organizados: videos/<projeto>/<arquivo de teste>/<cenário>.mp4
const PASTA_VIDEOS = path.join(__dirname, '..', 'videos');

function caminhoDoVideo(testInfo) {
  // titlePath[0] é o arquivo de teste (o testInfo.file seria este bdd.js, onde o test() é declarado).
  const pasta = path.join(PASTA_VIDEOS, testInfo.project.name, path.basename(testInfo.titlePath[0], '.spec.js'));
  const cenario = testInfo.title
    .replace(/^Cenário: /, '')
    .replace(/"/g, "'")
    .replace(/[\\/:*?<>|]/g, '-')
    .slice(0, 150);
  const prefixo = testInfo.status === 'passed' ? '' : '[FALHOU] ';
  fs.mkdirSync(pasta, { recursive: true });
  return path.join(pasta, `${prefixo}${cenario}.mp4`);
}

const PASSO_MS = Number(process.env.PASSO_MS ?? 600);

const test = base.extend({
  narrador: async ({}, use, testInfo) => {
    await use(new Narrador(testInfo));
  },

  // Anuncia cada componente tocado, clicado ou alcançado com Tab / Enter (voz Flo).
  locutor: async ({ page, narrador, isMobile }, use) => {
    const locutor = new LocutorNavegacao(page, narrador, { toque: isMobile ? 'Toque' : 'Clique' });
    await locutor.instalar();
    await use(locutor);
  },

  legenda: async ({ page, locutor }, use) => {
    const legenda = new Legenda(page, locutor);
    await legenda.instalar();
    await use(legenda);
  },

  leitor: async ({ page, legenda, narrador, locutor }, use, testInfo) => {
    const leitor = new LeitorNvda(page, legenda, narrador, locutor);
    await use(leitor);
    await leitor.parar();
    // O roteiro do que o leitor falou, frase original → como o NVDA diria.
    const falas = leitor.falasOriginais();
    if (falas.length) {
      const roteiro = falas.map((f) => `${f}\n    → ${traduzirFala(f) ?? '(não falado)'}`).join('\n');
      await testInfo.attach('falas do NVDA simulado.txt', { body: roteiro, contentType: 'text/plain' });
    }
  },

  // Automática: no fim, junta o áudio ao vídeo e guarda em videos/.
  _gravacao: [
    async ({ page, narrador }, use, testInfo) => {
      narrador.zerarRelogio();

      await use();

      const video = page.video();
      await page.close();
      // Um cenário pulado (teclado no celular) não tem o que mostrar.
      if (!video || testInfo.status === 'skipped') return;
      const webm = await video.path();
      const destino = caminhoDoVideo(testInfo);

      if (narrador.falas.length) {
        // Quem falou o quê, e quando: NVDA, passos (modo ao vivo) e navegação (modo ao vivo).
        const roteiro = narrador.falas.map((f) => `${(f.inicioMs / 1000).toFixed(1).padStart(6)} s  [${f.quem}] ${f.frase}`).join('\n');
        await testInfo.attach('roteiro do áudio.txt', { body: roteiro, contentType: 'text/plain' });
        // Cenários de leitor de tela (ou modo ao vivo): vídeo legendado + voz.
        const mp4 = await juntarAudioNoVideo(webm, narrador.falas, destino);
        if (mp4) {
          await testInfo.attach('vídeo com voz', { path: mp4, contentType: 'video/mp4' });
          return;
        }
      }
      // Demais cenários (ou sem áudio): só o vídeo legendado, em .mp4.
      await converterParaMp4(webm, destino);
    },
    { auto: true },
  ],
});

const passo = (palavra) => (texto, fn) => ({ palavra, texto, fn });
const Dado = passo('Dado');
const Quando = passo('Quando');
const Entao = passo('Então');
const E = passo('E');
const Mas = passo('Mas');

function funcionalidade(nome, corpo) {
  test.describe(`Funcionalidade: ${nome}`, corpo);
}

function cenario(nome, passos, detalhes = {}) {
  test(`Cenário: ${nome}`, detalhes, async ({ page, context, legenda, leitor, narrador, locutor, baseURL }, testInfo) => {
    const nomeFuncionalidade = testInfo.titlePath
      .find((t) => t.startsWith('Funcionalidade: '))
      ?.replace('Funcionalidade: ', '') ?? '';

    const contexto = { page, context, legenda, leitor, narrador, locutor, baseURL, testInfo, mundo: {} };

    // A legenda só aparece depois da primeira navegação; até lá a página está em branco.
    await legenda.iniciar(nomeFuncionalidade, nome, passos);
    await narrador.narrar(`Cenário: ${nome}`);

    let sucesso = false;
    try {
      for (const [i, p] of passos.entries()) {
        await test.step(`${p.palavra} ${p.texto}`, async () => {
          await legenda.passo(i, 'executando');
          await narrador.narrar(`${p.palavra} ${p.texto}`);
          try {
            await p.fn(contexto);
            await locutor.sincronizar();
          } catch (erro) {
            const mensagem = String(erro.message || erro).split('\n').slice(0, 4).join('\n');
            await legenda.passo(i, 'falhou', mensagem);
            throw erro;
          }
          await legenda.passo(i, 'ok');
          if (PASSO_MS) await page.waitForTimeout(PASSO_MS);
        });
      }
      sucesso = true;
    } finally {
      await legenda.concluir(sucesso);
      await narrador.narrar(sucesso ? 'Cenário aprovado.' : 'Cenário reprovado.');
      // Segura o quadro final para o resultado aparecer no vídeo.
      await page.waitForTimeout(sucesso ? 800 : 2500).catch(() => {});
    }
  });
}

module.exports = { test, expect, funcionalidade, cenario, Dado, Quando, Entao, E, Mas };
