# Acessibilidade no HelpUS

As mesmas três camadas do Garapuvu Kanban:

| Camada | Onde | Comando |
| --- | --- | --- |
| Árvore de semântica do Flutter (o que TalkBack, VoiceOver e NVDA recebem) | `test/widget/` | `make test` |
| Navegador: axe-core (WCAG 2.2 AA), árvore ARIA, leitor virtual, teclado | `acessibilidade-web/` | `make e2e-web` |
| Leitor de tela de verdade | aparelho | roteiro abaixo |

## Decisões que valem para um app de emergência

- **Sem tela de abertura:** o app abre direto no botão de ajuda.
- **Botão grande e sempre no mesmo lugar:** 220 × 220, vermelho com texto
  branco (6,5 : 1). É o primeiro controle lido depois do título e do cartão do
  evento.
- **O leitor de tela diz para quem vai:** "Pedir ajuda, botão. Envia sua
  localização pelo WhatsApp para Maria."
- **Cada passo é falado sozinho** numa região viva: "Pegando sua localização…",
  "Abrindo o WhatsApp…", "Mensagem pronta no WhatsApp para Maria. Toque em Enviar."
- **Toque duplo repetido não duplica o pedido.**
- **Trocar de aba leva o foco para a tela nova:** Enter em "Eventos" põe o foco
  no título ("Eventos, cabeçalho") e o próximo Tab entra na tela, não na aba ao
  lado. O título não é parada do Tab.
- **Números falados dígito a dígito** ("4 8 9 9 9…"), e não como "quatro bilhões".
- **QR code com alternativa:** a mesma tela aceita o número digitado.
- **Na avaliação, cada opção diz a qual pergunta pertence:** "Cardápio em
  braille: Não sei".
- **Dados pessoais opcionais** para quem vem ajudar, como "sou surda, prefiro
  mensagem escrita".

## Critério da WCAG → teste

| WCAG 2.2 | Teste |
| --- | --- |
| 1.1.1 Conteúdo não textual (logo decorativo, QR com alternativa) | `wcag_diretrizes_test`, `eventos_e_contatos_test` |
| 1.3.1 / 2.4.6 Cabeçalhos e rótulos | `eventos_e_contatos_test`, `02-arvore` |
| 1.3.2 Ordem de leitura | `pedir_ajuda_test`, `03-leitor-de-tela-virtual` |
| 1.4.3 / 1.4.11 Contraste | `contraste_test`, `textContrastGuideline`, axe |
| 1.4.4 / 1.4.10 Texto a 200% sem estourar | `wcag_diretrizes_test` (todas as telas) |
| 2.1.1 Teclado | `pedir_ajuda_test`, `04-teclado` |
| 2.4.3 Ordem do foco (trocar de aba) | `navegacao_por_abas_test`, `04-teclado` |
| 2.5.8 Tamanho do alvo | `androidTapTargetGuideline`, `iOSTapTargetGuideline` |
| 3.1.1 Idioma | `01-wcag-axe` |
| 3.3.1 / 3.3.3 Erros explicados | `eventos_e_contatos_test`, `avaliacao_page_test` |
| 4.1.2 Nome, papel, valor | `labeledTapTargetGuideline`, `02-arvore` |
| 4.1.3 Mensagens de status | `pedir_ajuda_test`, `avaliacao_page_test`, `02-arvore` |

## Roteiro com leitor de tela real

**TalkBack (Android) / VoiceOver (iPhone):**

1. Abra o app e deslize para a direita. Deve ouvir, nesta ordem: "HelpUS,
   cabeçalho", o cartão do evento e "Pedir ajuda, botão, envia sua localização…".
2. Toque duas vezes. Sem mexer o dedo, deve ouvir "Pegando sua localização" e
   depois "Mensagem pronta no WhatsApp…".
3. No WhatsApp, confira que o link do mapa abre no lugar certo.
4. Em Eventos, o rotor de Cabeçalhos (VoiceOver) pula de evento em evento.
5. Em Contatos, o número do contato é lido dígito a dígito.

**NVDA com `flutter run -d chrome`:** `H` pula entre cabeçalhos, `B` vai para o
próximo botão, `Enter` em "Pedir ajuda" abre o WhatsApp Web. `Enter` na aba
"Eventos" deve falar "Eventos, cabeçalho", e o `Tab` seguinte, "Entrar no evento
pelo QR code".

## O logo

Homem Vitruviano de Leonardo da Vinci, com a figura de acessibilidade
universal, ondas de voz (o leitor de tela) e a letra **H** em braille (pontos
1, 2 e 5). Arquivo: `assets/logo/helpus-logo.svg`; os PNG são gerados com `make icones`.
