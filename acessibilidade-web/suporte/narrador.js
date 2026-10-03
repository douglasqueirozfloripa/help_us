/**
 * Vozes dos testes, usando o sintetizador nativo do macOS (`say`).
 *
 * São três vozes, uma para cada papel:
 *   NVDA simulado (VOZ, padrão Luciana)   o que o leitor de tela fala; sempre
 *                                         gravado nos vídeos quando há áudio
 *   passos (VOZ_NARRADOR, padrão Eddy)    lê o cenário, cada passo Dado /
 *                                         Quando / Então e o resultado
 *   navegação (VOZ_NAVEGACAO, padrão Flo) anuncia cada componente tocado,
 *                                         clicado ou alcançado com Tab / Enter
 *                                         (veja locutor.js)
 * As vozes dos passos e da navegação só falam no modo ao vivo (FALAR=1).
 *
 * Cada frase vira um arquivo de áudio. O narrador guarda em que momento do
 * vídeo ela foi falada e, no fim do teste, video.js junta tudo no vídeo. Todas
 * as vozes passam por UMA fila: uma frase só começa quando a anterior termina,
 * como uma pessoa ouvindo, e o áudio nunca se sobrepõe.
 *
 * Variáveis de ambiente:
 *   AUDIO=0   desliga a voz (padrão: ligada no macOS, desligada no resto)
 *   FALAR=1   modo ao vivo: toca as vozes nos alto-falantes e narra passos e navegação
 *   VOZ, VOZ_NARRADOR, VOZ_NAVEGACAO   troca cada uma das vozes (veja `say -v '?'`)
 *   VELOCIDADE=...  palavras por minuto (padrão: 210)
 */
const { execFileSync, spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const TEM_SAY = process.platform === 'darwin';
const AUDIO_LIGADO = TEM_SAY && process.env.AUDIO !== '0';
const AO_VIVO = AUDIO_LIGADO && process.env.FALAR === '1';
const VOZ = process.env.VOZ || 'Luciana';
const VOZ_NARRADOR = process.env.VOZ_NARRADOR || 'Eddy (Português (Brasil))';
const VOZ_NAVEGACAO = process.env.VOZ_NAVEGACAO || 'Flo (Português (Brasil))';
const VELOCIDADE = process.env.VELOCIDADE || '210';

// Sem áudio, cada frase ainda fica um instante na legenda, para dar tempo de
// ler no vídeo. Com PASSO_MS=0 (CI), não há pausa nenhuma.
const PAUSA_SEM_AUDIO_MS = process.env.PASSO_MS === '0' ? 0 : 350;

class Narrador {
  constructor(testInfo) {
    this.pasta = testInfo.outputPath('falas');
    this.falas = []; // { arquivo, inicioMs, frase, quem }
    this.t0 = Date.now();
    this.fila = Promise.resolve();
  }

  // Marca o instante zero do vídeo (quando a página foi criada).
  zerarRelogio() {
    this.t0 = Date.now();
  }

  // Fala do leitor de tela simulado (sempre gravada no vídeo, quando há áudio).
  // Entra na fila e resolve quando a frase termina.
  falar(frase, voz = VOZ, quem = 'NVDA') {
    const vez = this.fila.then(() => this.falarAgora(frase, voz, quem));
    this.fila = vez.catch(() => {});
    return vez;
  }

  async falarAgora(frase, voz, quem) {
    if (!AUDIO_LIGADO) {
      await esperar(PAUSA_SEM_AUDIO_MS);
      return;
    }
    fs.mkdirSync(this.pasta, { recursive: true });
    const arquivo = path.join(this.pasta, `fala-${String(this.falas.length).padStart(3, '0')}.aiff`);
    const inicioMs = Date.now() - this.t0;
    execFileSync('say', ['-v', voz, '-r', VELOCIDADE, '-o', arquivo, '--', frase]);
    this.falas.push({ arquivo, inicioMs, frase, quem });

    if (AO_VIVO) spawn('afplay', [arquivo], { stdio: 'ignore' });

    await esperar(duracaoMs(arquivo));
  }

  // Voz dos passos do BDD, só no modo ao vivo (FALAR=1). Fora dele não faz
  // nada, e a suíte normal continua no ritmo dela.
  narrar(texto) {
    if (!AO_VIVO) return Promise.resolve();
    return this.falar(texto, VOZ_NARRADOR, 'passos');
  }

  // Voz da navegação pelos componentes, só no modo ao vivo (FALAR=1).
  locutar(texto) {
    if (!AO_VIVO) return Promise.resolve();
    return this.falar(texto, VOZ_NAVEGACAO, 'navegação');
  }

  // Resolve quando tudo o que está na fila já foi falado.
  aguardar() {
    return this.fila;
  }
}

// `afinfo` (nativo do macOS) informa a duração: "estimated duration: 2.809660 sec".
function duracaoMs(arquivo) {
  try {
    const saida = execFileSync('afinfo', [arquivo], { encoding: 'utf8' });
    const m = saida.match(/estimated duration:\s*([\d.]+)/);
    return m ? Math.round(Number(m[1]) * 1000) + 120 : 1500;
  } catch {
    return 1500;
  }
}

const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

module.exports = { Narrador, AUDIO_LIGADO, AO_VIVO };
