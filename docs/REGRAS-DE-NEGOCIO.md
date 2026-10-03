# Regras de negócio do HelpUS

## 1. Pedir ajuda com um clique (funcionalidade principal)

Um toque no botão vermelho **Pedir ajuda**:

1. pega a posição do GPS (espera no máximo 10 segundos);
2. monta a mensagem com nome, informação importante, evento, link do mapa,
   coordenadas, precisão e horário;
3. abre o WhatsApp de quem vai ajudar com a mensagem pronta.

**Para quem vai:** durante um evento, para a central do evento. Fora de evento,
para o contato principal. Depois do pedido, aparecem botões para mandar a mesma
mensagem aos outros contatos.

**Se algo falhar:**
- Sem WhatsApp, abre o SMS com a mesma mensagem.
- Sem WhatsApp nem SMS, o aviso manda ligar para 192 ou 193.
- Sem GPS, a mensagem sai assim mesmo e diz o motivo. Se houver, usa a última
  posição conhecida e avisa que é aproximada.

Os botões para ligar para 192, 193 e 190 ficam sempre visíveis.

**Fora do local do evento:** se a pessoa participa de um evento mas o GPS
mostra que ela está em outro lugar, a mensagem avisa isso logo depois do
título, em negrito:

```
🆘 PEDIDO DE AJUDA (HelpUS)
⚠️ *ATENÇÃO: A PESSOA NÃO ESTÁ NO LOCAL DO EVENTO.*
*Está em outro lugar, a cerca de 6,9 km do local do evento (Continente Shopping). Vá pelo link de localização abaixo, não pelo endereço do evento.*
```

- Cada evento tem `latitude`, `longitude` e `raioMetros` em `eventos.json`
  (sem raio, vale 500 m). Um shopping pede um raio pequeno; uma corrida na
  Beira-Mar pede um raio grande.
- Só avisa quando a pessoa está fora com certeza: nem descontando a margem de
  erro do GPS ela cai dentro da área. Evento sem coordenadas ou pedido sem GPS
  não geram o aviso.
- A tela também avisa: "A mensagem avisa que você não está no local do evento."

> **Limite do WhatsApp:** nenhum app consegue *enviar* uma mensagem de WhatsApp
> sozinho; o WhatsApp abre com o texto pronto e a pessoa toca em Enviar. Para um
> envio 100% automático é preciso a API oficial do WhatsApp Business num
> servidor da organização. Isso cabe numa próxima etapa.

Código: `features/sos/`, `servicos/`, `Evento.distanciaSeEstiverFora`. Testes: `sos_controller_test`,
`mensagem_sos_test`, `pedir_ajuda_test`, `02-arvore-acessibilidade.spec.js`.

## 2. Conectar pelo QR code e adicionar contatos

A tela **Ler QR code** entende:

| QR code | O que acontece |
| --- | --- |
| QR oficial do evento (JSON `{"helpus":"evento", ...}`) | a pessoa entra no evento; os pedidos passam a ir para a central |
| link `wa.me/...` ou `api.whatsapp.com/send?phone=...` | abre "Novo contato" com o número preenchido |
| número de telefone escrito | idem |

A mesma tela aceita o número **digitado**. Quem não enxerga ou tem tremor pode
não conseguir mirar a câmera, então o número vai impresso embaixo do QR.
`make qr` gera os QR dos eventos em `docs/qr/`.

Código: `features/contatos/`. Testes: `telefone_e_qr_test`, `eventos_e_contatos_test`.

## 3. Coordenadas do GPS dentro da mensagem

A mensagem leva o link `https://www.google.com/maps?q=lat,lng` e as coordenadas
em texto. Tudo fica escrito na própria conversa do WhatsApp. Quem recebe não
precisa do HelpUS. E a informação continua lá mesmo que o app feche ou o
celular de quem pediu desligue.

## 4. Formulário no fim do evento

Com a pessoa participando de um evento, a tela de Ajuda mostra **Avaliar a
acessibilidade do evento**. O formulário pergunta, com Sim, Não ou Não sei:

- rampa ou acesso sem degraus;
- cardápio em braille;
- banheiro adaptado;
- espaço sensorial para crianças com TEA;
- vagas de estacionamento para cadeirantes e PCD;
- intérprete de Libras.

Depois vêm notas de 1 a 5 para o acesso, o evento e o parceiro, e um comentário
livre. A avaliação fica guardada no aparelho e abre o WhatsApp da organização
com as respostas formatadas.
Depois de enviar, o formulário fecha e o app vai para a tela de Eventos,
com o aviso de que a avaliação foi salva. Voltar pela seta sem enviar não
salva nada e volta para a tela de Ajuda.

Código: `features/avaliacao/`. Testes: `avaliacao_test`, `avaliacao_page_test`.

## Premissas

**Celular bloqueado.** Android e iOS não deixam um app comum abrir sem
desbloquear. O que já está feito:

- **Atalho no ícone:** segurar o ícone do HelpUS e tocar em "Pedir ajuda"
  dispara o pedido direto, sem passar por nenhuma tela (`app/atalhos.dart`).
- **Dica na tela de Ajuda,** explicando esse atalho.

O que dá para fazer nas próximas etapas, do mais simples ao mais trabalhoso:

1. Ensinar a pessoa a usar o SOS do próprio sistema, que funciona bloqueado:
   no Android, "SOS de emergência" (5 toques no botão lateral); no iPhone,
   "SOS de emergência" (segurar botão lateral + volume). Os dois mandam a
   localização por SMS aos contatos de emergência.
2. Uma notificação fixa durante o evento, com o botão "Pedir ajuda", que
   aparece na tela de bloqueio (pacote `flutter_local_notifications`).
3. Widget na tela de bloqueio do iOS 16+ e bloco nas Configurações rápidas do
   Android (código nativo).

**Eventos por cidade.** A lista vem de `assets/dados/eventos.json`, com os
contatos dos administradores. A interface `FonteDeEventos` permite trocar por
um servidor (ex.: Firebase) sem mexer nas telas.

## Próximos

**Parceiros premium.** Eles terão divulgação de eventos futuros e passados,
com as avaliações dos participantes e uma pontuação de engajamento. Para isso
é preciso servidor: as avaliações hoje ficam no aparelho e seguem por WhatsApp.
O formato já está pronto em `Avaliacao.toJson()`.
