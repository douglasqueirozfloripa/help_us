# Acessibilidade HelpUS: testes no navegador com Playwright

Testes do HelpUS (Flutter web) no mesmo modelo da suíte do site do Projeto Garapuvu: cenários em
BDD, vídeo legendado de cada cenário e NVDA simulado com voz.

| Arquivo | O que verifica |
|---|---|
| `01-wcag-axe` | axe-core (WCAG 2.2 A e AA) na tela de ajuda, depois do pedido, em Eventos e em Contatos |
| `02-arvore-acessibilidade` | a regra principal: um toque abre o WhatsApp com o link do Google Maps; nomes dos botões |
| `03-leitor-de-tela-virtual` | NVDA simulado: leitura com a seta, tecla H, pedido pelo teclado com a confirmação falada, tela sem contatos |
| `04-teclado` | Tab e Enter até o WhatsApp; Enter numa aba leva o foco para a tela nova (só no computador) |

## Como rodar

```bash
npm install
npx playwright install chromium   # só na primeira vez

npm test                 # suíte completa, celular e computador (gera o build do Flutter se precisar)
npm run test:nvda        # só o NVDA simulado (com voz no vídeo)
npm run test:ao-vivo     # celular, navegador visível, ritmo de pessoa e tudo narrado nos alto-falantes
npm run test:ci          # sem voz e sem pausas
npm run relatorio        # abre o relatório HTML
```

## Os vídeos

Cada cenário gera **`videos/<projeto>/<arquivo>/<cenário>.mp4`** (`celular` ou `computador`).
Cenários que falham ganham o prefixo `[FALHOU]`. Sobre a tela do app aparecem:

- a **funcionalidade**, o **cenário** e os passos **Dado / Quando / Então / E**: ▶ o passo atual,
  ✓ os concluídos, ✗ o que falhou (com a mensagem de erro) e ○ os que ainda vêm;
- o **Visualizador de fala**, com as últimas frases do NVDA simulado, e o cursor do leitor
  (tracejado) sobre o item lido;
- o painel **Navegação pelos componentes**, com cada parada do Tab e cada toque ou Enter num componente.

A caixa fica acima da barra de abas (Ajuda, Eventos, Contatos), é `aria-hidden` e não recebe
toques, então não muda nada para o Flutter nem para o axe.

Nos cenários do NVDA, o vídeo tem **áudio**: cada frase é falada pela voz do macOS (`say`, voz
Luciana) no instante em que foi dita, e o teste espera a frase terminar antes de seguir. O roteiro
das falas (original → português) fica anexado ao relatório como `falas do NVDA simulado.txt`.

### Modo ao vivo (`npm run test:ao-vivo`)

Roda no celular, um cenário por vez, com o navegador aberto:

- **`SLOW_MO=1500`:** o Playwright espera 1,5 s antes de cada toque, tecla e navegação, como uma
  pessoa usando o app;
- **`FALAR=1`:** toca as vozes nos alto-falantes, uma de cada vez, com três vozes:

| Voz | Papel | Exemplo |
|---|---|---|
| **Eddy** | narrador dos passos do BDD | "Quando toco em Pedir ajuda", "Cenário aprovado." |
| **Flo** | locutor da navegação pelos componentes | "Toque: botão, Pedir ajuda", "Tab: aba, Eventos", "Enter: aba, Eventos", "Foco: título nível 2, Eventos" |
| **Luciana** | NVDA simulado | "botão, Pedir ajuda, Envia sua localização pelo WhatsApp para Maria." |

O locutor da navegação percebe os toques, cliques, Tab, Shift+Tab e Enter dentro da própria página
(`suporte/locutor.js`), então vale para qualquer spec sem mudar o teste. No computador ele diz
"Clique" em vez de "Toque". Nos cenários do NVDA simulado ele fica calado, porque o NVDA já fala
cada componente. Cada passo só ganha o ✓ depois que o locutor termina de anunciar.

No modo ao vivo, o relatório também anexa o `roteiro do áudio.txt`: quem falou o quê, e em que
segundo do vídeo.

| Variável | Efeito |
|---|---|
| `BASE_URL` | app a testar (padrão: `build/web` servido em `http://127.0.0.1:8091`) |
| `SLOW_MO` | espera, em ms, antes de cada ação do Playwright (padrão: 0) |
| `AUDIO=0` | desliga a voz |
| `FALAR=1` | toca as vozes ao vivo e narra tudo |
| `VOZ` / `VOZ_NARRADOR` / `VOZ_NAVEGACAO` | vozes do NVDA, dos passos e da navegação (padrão: Luciana / Eddy / Flo; veja `say -v '?'`) |
| `VELOCIDADE` | palavras por minuto das vozes (padrão: 210) |
| `PASSO_MS` | pausa entre passos, para o vídeo ficar legível (padrão: 600; use 0 em CI) |

## Como funciona o "NVDA simulado"

O [Virtual Screen Reader da Guidepup](https://github.com/guidepup/virtual-screen-reader) percorre a
árvore de acessibilidade que o Flutter web monta (`<flt-semantics>` com role e nome), a mesma que o
Chromium entrega ao NVDA. Os comandos imitam o NVDA (seta para baixo, H, Enter), e Tab e Enter são
teclas de verdade na página. A região viva do Flutter ("Mensagem pronta no WhatsApp…") também é
ouvida.

As asserções usam as frases originais do leitor virtual. A legenda e a voz mostram uma tradução
no estilo do NVDA ("título nível 2, HelpUS", "aba, Ajuda, selecionado, 1 de 3"), que é **uma
aproximação**, não o texto exato do NVDA. Esta suíte não substitui o teste com o NVDA, o TalkBack
e o VoiceOver de verdade (roteiro em [`../docs/ACESSIBILIDADE.md`](../docs/ACESSIBILIDADE.md)).
