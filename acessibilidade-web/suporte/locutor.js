/**
 * Locutor de navegação: anuncia cada componente em que o teste mexe, com uma
 * voz própria (Flo), diferente da voz dos passos do BDD (Eddy) e da voz do
 * NVDA simulado (Luciana).
 *
 *   "Toque: botão, Pedir ajuda"        toque no celular (clique no computador)
 *   "Tab: aba, Eventos"                Tab ou Shift+Tab até um componente
 *   "Enter: aba, Eventos"              Enter ou Espaço no componente com foco
 *   "Foco: título nível 2, Eventos"    o app levou o foco sozinho
 *
 * Os eventos são percebidos DENTRO da página (click, focusin, keydown), então
 * valem para qualquer spec, sem mudar os testes. A voz só toca no modo ao vivo
 * (FALAR=1); toques e Enter também entram no painel de navegação da legenda.
 *
 * Nos cenários do NVDA simulado o locutor fica calado: o NVDA já fala cada
 * componente que recebe o foco, e duas vozes dizendo a mesma coisa confundem.
 */
const { PAPEIS } = require('./leitor-nvda');
const { AO_VIVO } = require('./narrador');

// Roda dentro do navegador, em toda página carregada (addInitScript).
function observarNavegacao() {
  const COMPONENTE = '[role], a[href], button, input, select, textarea, h1, h2, h3, h4, h5, h6';
  // Contêineres, e não componentes: o Flutter web põe um "group" em volta da tela inteira.
  const CONTEINER = /^(group|generic|presentation|none|document|application|text)$/;
  let tecla = { nome: '', shift: false, t: -1e9 };
  let toque = { el: null, t: -1e9 };
  window.__qaNavEmitidos = 0;

  function componente(alvo) {
    const el = alvo?.closest?.(COMPONENTE);
    if (!el || el.closest('#qa-legenda')) return null;
    const papel = el.getAttribute('role') || el.tagName.toLowerCase();
    if (CONTEINER.test(papel)) return null;
    const nome = (el.getAttribute('aria-label') || el.getAttribute('title') || el.innerText || el.textContent || '')
      .trim()
      .replace(/\s+/g, ' ');
    return nome ? { el, papel, nome: nome.slice(0, 90) } : null;
  }

  function avisar(tipo, c) {
    if (!c || typeof window.__qaNavegacao !== 'function') return;
    window.__qaNavEmitidos++;
    window.__qaNavegacao({ tipo, papel: c.papel, nome: c.nome }).catch(() => {});
  }

  // No `window` e na captura: o Flutter trata o teclado no window e interrompe
  // a propagação, então o evento nunca chegaria ao document. Este script roda
  // antes do Flutter, então ouve primeiro.
  window.addEventListener('keydown', (e) => {
    tecla = { nome: e.key, shift: e.shiftKey, t: performance.now() };
    if (e.key === 'Enter' || e.key === ' ') avisar(e.key === 'Enter' ? 'enter' : 'espaco', componente(document.activeElement));
  }, true);

  // O foco de um toque chega antes do clique: guarda o alvo já no pointerdown.
  window.addEventListener('pointerdown', (e) => {
    toque = { el: componente(e.target)?.el ?? null, t: performance.now() };
  }, true);

  window.addEventListener('click', (e) => {
    // Enter ou Espaço num botão pode gerar um clique logo depois: já foi anunciado.
    if ((tecla.nome === 'Enter' || tecla.nome === ' ') && performance.now() - tecla.t < 500) return;
    avisar('toque', componente(e.target));
  }, true);

  window.addEventListener('focusin', (e) => {
    const c = componente(e.target);
    if (!c) return;
    const agora = performance.now();
    if (toque.el === c.el && agora - toque.t < 1000) return; // o toque já anuncia
    const tab = tecla.nome === 'Tab' && agora - tecla.t < 1000;
    avisar(tab ? (tecla.shift ? 'shift-tab' : 'tab') : 'foco', c);
  }, true);
}

const TAGS = { a: 'link', button: 'botão', input: 'caixa de edição', textarea: 'caixa de edição', select: 'caixa de combinação' };

function papelFalado(papel) {
  if (/^h[1-6]$/.test(papel)) return `título nível ${papel[1]}`;
  return PAPEIS[papel] ?? TAGS[papel] ?? papel;
}

class LocutorNavegacao {
  /** @param {{ toque?: string }} opcoes  "Toque" no celular, "Clique" no computador */
  constructor(page, narrador, { toque = 'Toque' } = {}) {
    this.page = page;
    this.narrador = narrador;
    this.acoes = { toque, tab: 'Tab', 'shift-tab': 'Shift Tab', enter: 'Enter', espaco: 'Espaço', foco: 'Foco' };
    this.recebidos = 0;
    this.calado = false;
    // A legenda se inscreve aqui para mostrar toques e Enter no painel de navegação.
    this.aoAcionar = null;
  }

  async instalar() {
    await this.page.exposeBinding('__qaNavegacao', (_origem, evento) => this.receber(evento));
    await this.page.addInitScript(observarNavegacao);
  }

  receber(evento) {
    this.recebidos++;
    const acao = this.acoes[evento.tipo];
    // Tab e foco já aparecem no painel pelos próprios testes (legenda.foco).
    if (!['tab', 'shift-tab', 'foco'].includes(evento.tipo)) this.aoAcionar?.(`${acao} → ${evento.papel}: ${evento.nome}`);
    if (this.calado) return;
    this.narrador
      .locutar(`${acao}: ${papelFalado(evento.papel)}, ${evento.nome}`)
      .catch((erro) => console.warn(`Locutor de navegação: ${erro.message}`));
  }

  // O NVDA simulado ligou: ele passa a falar cada componente.
  calar() {
    this.calado = true;
  }

  /**
   * Espera o locutor anunciar tudo o que já aconteceu na página, antes de o
   * teste seguir (fim de passo, próxima parada do Tab). Assim a voz acompanha a
   * tela, em vez de ficar para trás.
   */
  async sincronizar() {
    if (!AO_VIVO || this.calado) return;
    const emitidos = await this.page.evaluate(() => window.__qaNavEmitidos ?? 0).catch(() => this.recebidos);
    const limite = Date.now() + 1000;
    while (this.recebidos < emitidos && Date.now() < limite) await new Promise((r) => setTimeout(r, 20));
    await this.narrador.aguardar();
  }
}

module.exports = { LocutorNavegacao };
