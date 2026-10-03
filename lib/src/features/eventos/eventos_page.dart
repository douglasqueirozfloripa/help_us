import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/datas.dart';
import '../../core/utils/telefone.dart';
import 'evento.dart';
import 'eventos_controller.dart';

/// Eventos por cidade, com os contatos de quem organiza.
class EventosPage extends StatelessWidget {
  const EventosPage({
    super.key,
    required this.eventos,
    required this.aoLerQr,
    required this.falarCom,
  });

  final EventosController eventos;
  final VoidCallback aoLerQr;
  final void Function(Administrador administrador) falarCom;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: eventos,
      builder: (context, _) {
        if (eventos.carregando) {
          return const Center(
              child: CircularProgressIndicator(
                  semanticsLabel: 'Carregando eventos'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            OutlinedButton.icon(
              onPressed: aoLerQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Entrar no evento pelo QR code'),
            ),
            const SizedBox(height: 16),
            Semantics(
                container: true,
                header: true,
                child: Text('Cidade', style: textos.titleMedium)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: eventos.cidadeSelecionada == null,
                  onSelected: (_) => eventos.escolherCidade(null),
                ),
                for (final cidade in eventos.cidades)
                  ChoiceChip(
                    label: Text(cidade),
                    selected: eventos.cidadeSelecionada == cidade,
                    onSelected: (_) => eventos.escolherCidade(cidade),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (eventos.falhouAoCarregar)
              Text(
                  'Não foi possível carregar a lista de eventos. Use o QR code do evento.',
                  style: textos.bodyLarge),
            if (!eventos.falhouAoCarregar && eventos.eventosDaCidade.isEmpty)
              Text('Nenhum evento nesta cidade por enquanto.',
                  style: textos.bodyLarge),
            for (final evento in eventos.eventosDaCidade)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CartaoEvento(
                  evento: evento,
                  participando: eventos.participando?.id == evento.id,
                  aoParticipar: () => eventos.participar(evento),
                  aoSair: eventos.sair,
                  falarCom: falarCom,
                ),
              ),
          ],
        );
      },
    );
  }
}

class CartaoEvento extends StatelessWidget {
  const CartaoEvento({
    super.key,
    required this.evento,
    required this.participando,
    required this.aoParticipar,
    required this.aoSair,
    required this.falarCom,
  });

  final Evento evento;
  final bool participando;
  final VoidCallback aoParticipar;
  final VoidCallback aoSair;
  final void Function(Administrador) falarCom;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final quando = evento.inicio != null && evento.fim != null
        ? periodo(evento.inicio!, evento.fim!)
        : '';
    final resumo = [
      evento.nome,
      if (participando) 'Você está participando',
      evento.cidade,
      if (evento.local.isNotEmpty) evento.local,
      if (quando.isNotEmpty) quando,
      if (evento.parceiro.isNotEmpty) 'Parceiro: ${evento.parceiro}',
    ].join('. ');

    return Card(
      color: Cores.branco,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              header: true,
              label: '$resumo.',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(evento.nome, style: textos.titleLarge),
                    if (participando)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Cores.sucesso, size: 20),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text('Você está participando',
                                  style: textos.labelLarge
                                      ?.copyWith(color: Cores.sucesso)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                        [
                          evento.cidade,
                          if (evento.local.isNotEmpty) evento.local
                        ].join(' — '),
                        style: textos.bodyMedium),
                    if (quando.isNotEmpty)
                      Text(quando, style: textos.bodyMedium),
                    if (evento.parceiro.isNotEmpty)
                      Text('Parceiro: ${evento.parceiro}',
                          style: textos.bodyMedium),
                  ],
                ),
              ),
            ),
            if (evento.administradores.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Organização', style: textos.titleSmall),
              for (final adm in evento.administradores)
                TextButton.icon(
                  onPressed: () => falarCom(adm),
                  icon: const Icon(Icons.chat),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  // Troca só o que é falado: papel, ação e foco continuam os
                  // do botão, e o leitor de tela acompanha o Tab até aqui.
                  label: Semantics(
                    label:
                        'Falar no WhatsApp com ${adm.nome}${adm.funcao.isEmpty ? '' : ', ${adm.funcao}'}. '
                        'Número ${telefoneParaFala(adm.whatsapp)}.',
                    excludeSemantics: true,
                    child: Text(
                      '${adm.nome}${adm.funcao.isEmpty ? '' : ' (${adm.funcao})'}: ${formatarTelefone(adm.whatsapp)}',
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            participando
                ? OutlinedButton(
                    onPressed: aoSair,
                    child: Text('Sair do evento ${evento.nome}'))
                : FilledButton(
                    onPressed: aoParticipar,
                    child: Text('Participar do evento ${evento.nome}')),
          ],
        ),
      ),
    );
  }
}
