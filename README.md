# HelpUS

Pedido de ajuda em **um toque** para pessoas com deficiência em eventos. O toque
abre o WhatsApp de quem vai ajudar com a mensagem pronta, incluindo o **link do
Google Maps com a posição do GPS**. Durante um evento, o pedido vai para a
central da organização; no fim, a pessoa avalia a acessibilidade do evento.

Os dados ficam no aparelho. Não há conta nem servidor nesta versão.

## Começando

```bash
cd HelpUS
make bootstrap   # cria android/ ios/ web/ com permissões de GPS e câmera
make check       # formato + analisador + testes
make run
```

`make ajuda` lista todos os comandos. Os testes de acessibilidade no navegador
rodam com `make e2e-web`, e o fluxo completo num aparelho com `make e2e`.
Dentro de `acessibilidade-web/` também dá para rodar direto (`npm test`, ou
`npm run test:ao-vivo` para ver o navegador). Se `build/web` não existe ou é
mais velho que o código, o build é gerado sozinho antes dos testes.

## Onde está cada coisa

```
lib/src/
  app/            dependências e atalho "Pedir ajuda" no ícone
  core/           tema, cores com contraste conferido, telefone, datas, logo
  data/           armazenamento no aparelho, lista de eventos
  servicos/       GPS (geolocator) e WhatsApp/SMS/ligação (url_launcher)
  features/
    sos/          botão Pedir ajuda e montagem da mensagem
    eventos/      eventos por cidade, participação, contatos da organização
    contatos/     contatos, seus dados, leitura de QR code
    avaliacao/    formulário de acessibilidade do fim do evento
    inicio/       navegação entre Ajuda, Eventos e Contatos
test/unit/        regras puras (mensagem, telefone, QR, avaliação, contraste)
test/widget/      telas, leitor de tela, teclado e diretrizes da WCAG
integration_test/ fluxo ponta a ponta num aparelho
acessibilidade-web/  Playwright: axe-core, árvore ARIA, NVDA simulado, teclado
assets/dados/eventos.json  eventos de exemplo (Grande Florianópolis)
docs/qr/          QR codes de exemplo para testar com o celular
```

- [`docs/REGRAS-DE-NEGOCIO.md`](docs/REGRAS-DE-NEGOCIO.md): cada regra combinada e onde ela está no código e nos testes.
- [`docs/ACESSIBILIDADE.md`](docs/ACESSIBILIDADE.md): critérios da WCAG, testes e roteiro com NVDA, VoiceOver e TalkBack.
