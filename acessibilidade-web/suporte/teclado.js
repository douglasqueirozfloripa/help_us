/**
 * Ajudantes de navegação por teclado (Tab / Shift+Tab).
 *
 * No Flutter web, o foco vai para os nós <flt-semantics> da árvore de
 * acessibilidade, que têm role (button, tab...) em vez de uma tag própria. E o
 * Flutter leva o foco do navegador para o controle um instante DEPOIS da tecla,
 * por isso cada parada espera um pouco antes de ler o foco.
 */

// Descreve o elemento com foco: "papel: nome acessível".
async function focoAtual(page) {
  return page.evaluate(() => {
    const a = document.activeElement;
    if (!a || a === document.body || a === document.documentElement) return 'body';
    const papel = a.getAttribute('role') || a.tagName.toLowerCase();
    const nome = a.getAttribute('aria-label') || a.getAttribute('title') || (a.innerText || a.textContent || '').trim().replace(/\s+/g, ' ');
    return `${papel}: ${nome.slice(0, 90)}`;
  });
}

/**
 * Aperta `tecla` repetidamente e devolve as paradas do foco (sem repetições
 * seguidas). Para quando `parar(foco)` for verdadeiro ou no `limite`.
 * Cada parada nova aparece no painel "Foco do teclado" da legenda.
 */
async function navegar(page, legenda, tecla, parar, limite = 30) {
  const paradas = [];
  const simbolo = tecla === 'Shift+Tab' ? '⇧Tab ←' : `${tecla} →`;
  for (let i = 0; i < limite; i++) {
    await page.keyboard.press(tecla);
    await page.waitForTimeout(250);
    const foco = await focoAtual(page);
    if (foco === paradas.at(-1)) continue;
    paradas.push(foco);
    if (legenda) await legenda.foco(`${simbolo} ${foco}`);
    if (parar && parar(foco)) break;
  }
  return paradas;
}

// Uma tecla só, registrando a parada na legenda.
async function apertar(page, legenda, tecla) {
  await page.keyboard.press(tecla);
  await page.waitForTimeout(250);
  const foco = await focoAtual(page);
  if (legenda) await legenda.foco(`${tecla === 'Shift+Tab' ? '⇧Tab ←' : tecla + ' →'} ${foco}`);
  return foco;
}

module.exports = { focoAtual, navegar, apertar };
