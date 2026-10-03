const CONTATOS = [
  { id: '1', nome: 'Maria', telefone: '5548988887777', origem: 'digitado' },
  { id: '2', nome: 'João', telefone: '5548977776666', origem: 'qrCode' },
];

/** O shared_preferences da web guarda "flutter.<chave>" com o valor em JSON. */
async function semear(page, { contatos = CONTATOS, perfil } = {}) {
  await page.addInitScript(({ contatos, perfil }) => {
    localStorage.setItem('flutter.helpus.contatos.v1', JSON.stringify(JSON.stringify(contatos)));
    if (perfil) localStorage.setItem('flutter.helpus.perfil.v1', JSON.stringify(JSON.stringify(perfil)));
  }, { contatos, perfil });
}

async function abrir(page) {
  // O wa.me de verdade redireciona para api.whatsapp.com e depende da internet.
  // O teste só precisa do endereço que o app abriu, então o WhatsApp é simulado.
  await page.context().route(/^https:\/\/(wa\.me|api\.whatsapp\.com)\//, (rota) =>
    rota.fulfill({ contentType: 'text/html', body: '<title>WhatsApp simulado</title>' }),
  );
  // O Flutter web deixa a frase na região viva só 300 ms e depois apaga.
  // Guardamos tudo que passa por ela para conferir o que foi falado.
  await page.addInitScript(() => {
    window.anunciado = [];
    new MutationObserver((mudancas) => {
      for (const m of mudancas) {
        const alvo = m.target.nodeType === Node.TEXT_NODE ? m.target.parentElement : m.target;
        const texto = alvo?.closest?.('[aria-live]')?.textContent?.trim();
        if (texto) window.anunciado.push(texto);
      }
    // document, não documentElement: o <html> ainda não existe quando este script roda.
    }).observe(document, { subtree: true, childList: true, characterData: true });
  });
  await page.goto('/');
  await botaoAjuda(page).waitFor({ timeout: 45_000 });
}

/** Frases que o leitor de tela recebeu pela região viva até agora. */
const anunciado = (page) => page.evaluate(() => window.anunciado);

/**
 * Texto na tela. O Flutter web repete o texto de uma região viva num
 * <flt-announcement-host> escondido, para o leitor de tela falar; aqui
 * procuramos só o que aparece na tela.
 */
const naTela = (page, texto) => page.locator('flt-semantics-host').getByText(texto);

/** O nome acessível começa por "Pedir ajuda"; a dica pode vir junto. */
const botaoAjuda = (page) => page.getByRole('button', { name: /^Pedir ajuda/ });

async function irPara(page, aba) {
  await page.getByRole('tab', { name: aba }).or(page.getByRole('button', { name: aba, exact: true })).first().click();
}

function resumirViolacoes(violacoes) {
  return violacoes
    .map((v) => `• [${v.impact}] ${v.id}: ${v.help}\n    ${v.nodes.map((n) => n.target.join(' ')).join('\n    ')}`)
    .join('\n');
}

module.exports = { semear, abrir, anunciado, naTela, botaoAjuda, irPara, resumirViolacoes };
