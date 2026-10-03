import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/telefone.dart';
import 'contato.dart';
import 'contatos_controller.dart';

class ContatosPage extends StatefulWidget {
  const ContatosPage({
    super.key,
    required this.contatos,
    required this.aoAdicionarPorQr,
    required this.aoAdicionarDigitando,
  });

  final ContatosController contatos;
  final VoidCallback aoAdicionarPorQr;
  final VoidCallback aoAdicionarDigitando;

  @override
  State<ContatosPage> createState() => _ContatosPageState();
}

class _ContatosPageState extends State<ContatosPage> {
  late final _nome = TextEditingController(text: widget.contatos.perfil.nome);
  late final _informacao =
      TextEditingController(text: widget.contatos.perfil.informacaoImportante);
  String _aviso = '';

  @override
  void dispose() {
    _nome.dispose();
    _informacao.dispose();
    super.dispose();
  }

  Future<void> _salvarPerfil() async {
    await widget.contatos.salvarPerfil(Perfil(
        nome: _nome.text.trim(),
        informacaoImportante: _informacao.text.trim()));
    if (!mounted) return;
    setState(() =>
        _aviso = 'Seus dados foram salvos. Eles vão junto no pedido de ajuda.');
  }

  Future<void> _remover(Contato contato) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover ${contato.nome}?'),
        content: const Text(
            'Essa pessoa não vai mais receber seus pedidos de ajuda.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmou ?? false) {
      await widget.contatos.remover(contato.id);
      if (!mounted) return;
      setState(() => _aviso = '${contato.nome} foi removido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: widget.contatos,
      builder: (context, _) {
        final lista = widget.contatos.contatos;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Semantics(
                container: true,
                liveRegion: true,
                child: _aviso.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_aviso,
                            style: textos.bodyLarge
                                ?.copyWith(color: Cores.sucesso)),
                      )),
            Semantics(
                container: true,
                header: true,
                child: Text('Sobre você', style: textos.titleMedium)),
            const SizedBox(height: 8),
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                  labelText: 'Seu nome', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _informacao,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'O que quem vier ajudar precisa saber',
                helperText:
                    'Ex.: sou cadeirante; sou surda e prefiro mensagem escrita.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                  onPressed: _salvarPerfil,
                  child: const Text('Salvar meus dados')),
            ),
            const SizedBox(height: 24),
            Semantics(
              container: true,
              header: true,
              child: Text('Quem recebe seus pedidos de ajuda',
                  style: textos.titleMedium),
            ),
            const SizedBox(height: 4),
            Text(
              'O primeiro da lista é o principal. Durante um evento, o pedido vai para a central do evento.',
              style: textos.bodyMedium?.copyWith(color: Cores.tintaSuave),
            ),
            const SizedBox(height: 8),
            if (lista.isEmpty)
              Text('Nenhum contato ainda.', style: textos.bodyLarge),
            for (final (i, contato) in lista.indexed)
              Card(
                color: Cores.branco,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          container: true,
                          label:
                              '${contato.nome}${i == 0 ? ', contato principal' : ''}. '
                              'WhatsApp ${telefoneParaFala(contato.telefone)}.',
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(contato.nome, style: textos.titleMedium),
                                if (i == 0)
                                  Text('Principal',
                                      style: textos.labelLarge
                                          ?.copyWith(color: Cores.sucesso)),
                                Text(formatarTelefone(contato.telefone),
                                    style: textos.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (i > 0)
                        IconButton(
                          tooltip: 'Tornar ${contato.nome} o contato principal',
                          icon: const Icon(Icons.star_outline),
                          onPressed: () =>
                              widget.contatos.tornarPrincipal(contato.id),
                        ),
                      IconButton(
                        tooltip: 'Remover ${contato.nome}',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remover(contato),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: widget.aoAdicionarPorQr,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Adicionar pelo QR code'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.aoAdicionarDigitando,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Adicionar digitando'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
