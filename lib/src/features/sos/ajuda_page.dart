import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/datas.dart';
import '../eventos/eventos_controller.dart';
import 'sos_controller.dart';

/// A tela principal: um botão grande, sempre no mesmo lugar.
class AjudaPage extends StatelessWidget {
  const AjudaPage({
    super.key,
    required this.sos,
    required this.eventos,
    required this.irParaEventos,
    required this.aoAvaliar,
  });

  final SosController sos;
  final EventosController eventos;
  final VoidCallback irParaEventos;
  final VoidCallback aoAvaliar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Listenable.merge([sos, eventos]),
      builder: (context, _) {
        final evento = eventos.participando;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _CartaoDoEvento(eventos: eventos, irParaEventos: irParaEventos),
            const SizedBox(height: 24),
            Center(child: BotaoSos(sos: sos)),
            const SizedBox(height: 16),
            _Status(sos: sos),
            if (sos.outrosContatos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Enviar a mesma mensagem também para:',
                  style: textos.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in sos.outrosContatos)
                    OutlinedButton.icon(
                      onPressed: () => sos.enviarTambemPara(c),
                      icon: const Icon(Icons.send),
                      label: Text(c.nome),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Semantics(
                container: true,
                header: true,
                child:
                    Text('Ligar para emergência', style: textos.titleMedium)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (numero, nome) in const [
                  ('192', 'SAMU'),
                  ('193', 'Bombeiros'),
                  ('190', 'Polícia')
                ])
                  OutlinedButton.icon(
                    onPressed: () => sos.ligar(numero),
                    icon: const Icon(Icons.call),
                    label: Text('$numero $nome'),
                  ),
              ],
            ),
            if (evento != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: aoAvaliar,
                icon: const Icon(Icons.rate_review),
                label: const Text('Avaliar a acessibilidade do evento'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Dica: com o celular desbloqueado, segure o ícone do ${NomeDoApp.valor} '
              'e escolha "Pedir ajuda" para não precisar abrir o app.',
              style: textos.bodyMedium?.copyWith(color: Cores.tintaSuave),
            ),
          ],
        );
      },
    );
  }
}

class BotaoSos extends StatelessWidget {
  const BotaoSos({super.key, required this.sos});

  final SosController sos;

  @override
  Widget build(BuildContext context) {
    final destino = sos.destino;
    final explicacao = destino == null
        ? 'Nenhum contato cadastrado ainda.'
        : 'Envia sua localização pelo WhatsApp para ${destino.nome}.';

    // Um nó só: o nome vem do texto "Pedir ajuda" e o resto (botão, ativo,
    // toque e foco do teclado) vem do próprio botão. Sem o foco, o leitor de
    // tela no navegador fica mudo quando o Tab chega aqui.
    return MergeSemantics(
      child: Semantics(
        hint: explicacao,
        child: SizedBox.square(
          dimension: 220,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Cores.socorro,
              foregroundColor: Cores.branco,
              disabledBackgroundColor: Cores.socorroEscuro,
              disabledForegroundColor: Cores.branco,
              shape: const CircleBorder(
                  side: BorderSide(color: Cores.socorroEscuro, width: 4)),
              elevation: 6,
            ),
            onPressed: sos.ocupado ? null : sos.pedirAjuda,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  sos.ocupado
                      ? const SizedBox.square(
                          dimension: 48,
                          child: CircularProgressIndicator(
                              color: Cores.branco, strokeWidth: 5),
                        )
                      : const Icon(Icons.sos, size: 64),
                  const SizedBox(height: 8),
                  const FittedBox(
                    child: Text('Pedir ajuda',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Região viva: o leitor de tela fala sozinho cada passo do pedido.
class _Status extends StatelessWidget {
  const _Status({required this.sos});

  final SosController sos;

  @override
  Widget build(BuildContext context) {
    final (fundo, frente, icone) = switch (sos.fase) {
      FaseSos.pronta => (Cores.sucessoClaro, Cores.sucesso, Icons.check_circle),
      FaseSos.falhou || FaseSos.semDestino => (
          Cores.socorroClaro,
          Cores.socorroEscuro,
          Icons.error
        ),
      _ => (Cores.douradoClaro, Cores.tinta, Icons.hourglass_top),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: sos.status.isEmpty
          ? const SizedBox.shrink()
          : DecoratedBox(
              decoration: BoxDecoration(
                color: fundo,
                border: Border.all(color: frente),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ExcludeSemantics(child: Icon(icone, color: frente)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(sos.status,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: frente)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartaoDoEvento extends StatelessWidget {
  const _CartaoDoEvento({required this.eventos, required this.irParaEventos});

  final EventosController eventos;
  final VoidCallback irParaEventos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final evento = eventos.participando;
    return Card(
      color: Cores.pergaminhoClaro,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: evento == null
              ? [
                  Text('Você não está em nenhum evento.',
                      style: textos.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                      'Escolha o evento para a organização receber seu pedido de ajuda.',
                      style: textos.bodyMedium),
                  const SizedBox(height: 8),
                  OutlinedButton(
                      onPressed: irParaEventos,
                      child: const Text('Ver eventos')),
                ]
              : [
                  Text('Você está no evento', style: textos.labelLarge),
                  Text(evento.nome, style: textos.titleLarge),
                  if (evento.local.isNotEmpty)
                    Text(evento.local, style: textos.bodyMedium),
                  if (evento.inicio != null && evento.fim != null)
                    Text(periodo(evento.inicio!, evento.fim!),
                        style: textos.bodyMedium),
                ],
        ),
      ),
    );
  }
}
