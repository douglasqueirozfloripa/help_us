import 'package:flutter/material.dart';

import '../../core/theme/tema.dart';
import '../../core/theme/tokens.dart';
import '../eventos/evento.dart';
import 'avaliacao.dart';

/// Formulário do fim do evento: acessibilidade do local e experiência.
/// Depois de salvar, fecha e devolve o aviso de como foi o envio.
class AvaliacaoPage extends StatefulWidget {
  const AvaliacaoPage(
      {super.key,
      required this.evento,
      required this.enviar,
      DateTime Function()? relogio})
      : relogio = relogio ?? DateTime.now;

  final Evento evento;

  /// Guarda no aparelho e abre o WhatsApp da organização. Devolve se abriu.
  final Future<bool> Function(Avaliacao avaliacao) enviar;
  final DateTime Function() relogio;

  @override
  State<AvaliacaoPage> createState() => _AvaliacaoPageState();
}

class _AvaliacaoPageState extends State<AvaliacaoPage> {
  final _respostas = <ItemAcessibilidade, Resposta>{};
  int? _notaAcesso;
  int? _notaEvento;
  int? _notaParceiro;
  final _comentario = TextEditingController();
  String _erro = '';
  var _enviando = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  List<String> get _faltando => [
        for (final item in ItemAcessibilidade.values)
          if (!_respostas.containsKey(item)) item.nomeCurto,
        if (_notaAcesso == null) 'Nota do acesso',
        if (_notaEvento == null) 'Nota do evento',
        if (_notaParceiro == null) 'Nota do parceiro',
      ];

  Future<void> _enviar() async {
    final faltando = _faltando;
    if (faltando.isNotEmpty) {
      setState(() {
        _erro = faltando.length == 1
            ? 'Falta responder: ${faltando.first}.'
            : 'Faltam ${faltando.length} respostas: ${faltando.join(', ')}.';
      });
      return;
    }
    setState(() {
      _erro = '';
      _enviando = true;
    });
    final abriu = await widget.enviar(Avaliacao(
      idEvento: widget.evento.id,
      nomeEvento: widget.evento.nome,
      parceiro: widget.evento.parceiro,
      respostas: Map.of(_respostas),
      notaAcesso: _notaAcesso!,
      notaEvento: _notaEvento!,
      notaParceiro: _notaParceiro!,
      comentario: _comentario.text,
      feitaEm: widget.relogio(),
    ));
    if (!mounted) return;
    Navigator.of(context).pop(abriu
        ? 'Avaliação salva. O WhatsApp da organização abriu com suas respostas: toque em Enviar.'
        : 'Avaliação salva no celular. Não foi possível abrir o WhatsApp da organização.');
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final parceiro =
        widget.evento.parceiro.isEmpty ? 'o parceiro' : widget.evento.parceiro;

    Widget titulo(String texto) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Semantics(
              container: true,
              header: true,
              child: Text(texto, style: textos.titleMedium)),
        );

    Widget notas(String assunto, int? valor, ValueChanged<int> aoEscolher) =>
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var n = 1; n <= 5; n++)
              ChoiceChip(
                label: Text('$n'),
                tooltip: '$assunto: nota $n de 5',
                selected: valor == n,
                onSelected: (_) => aoEscolher(n),
              ),
          ],
        );

    return Scaffold(
      appBar: barraHelpUS('Avaliar o evento'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.evento.nome, style: textos.titleLarge),
            Text(
                'Suas respostas ajudam a organização e os parceiros a melhorar o acesso.',
                style: textos.bodyMedium),
            titulo('Acessibilidade do local'),
            for (final item in ItemAcessibilidade.values) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(item.pergunta, style: textos.bodyLarge),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in Resposta.values)
                    ChoiceChip(
                      label: Text(r.rotulo),
                      tooltip: '${item.nomeCurto}: ${r.rotulo}',
                      selected: _respostas[item] == r,
                      onSelected: (_) => setState(() => _respostas[item] = r),
                    ),
                ],
              ),
            ],
            titulo('Como foi o acesso ao evento?'),
            notas(
                'Acesso', _notaAcesso, (n) => setState(() => _notaAcesso = n)),
            titulo('Como foi sua experiência no evento?'),
            notas(
                'Evento', _notaEvento, (n) => setState(() => _notaEvento = n)),
            titulo('Como foi o atendimento de $parceiro?'),
            notas('Parceiro', _notaParceiro,
                (n) => setState(() => _notaParceiro = n)),
            const SizedBox(height: 20),
            TextField(
              controller: _comentario,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Quer contar mais alguma coisa?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              liveRegion: true,
              child: _erro.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _erro,
                        style: textos.bodyLarge
                            ?.copyWith(color: Cores.socorroEscuro),
                      ),
                    ),
            ),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: const Icon(Icons.send),
              label: const Text('Enviar avaliação'),
            ),
          ],
        ),
      ),
    );
  }
}
