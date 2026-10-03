import 'package:flutter/material.dart';

import '../../core/theme/tema.dart';
import '../../core/utils/telefone.dart';

typedef NovoContato = ({String nome, String telefone});

class NovoContatoPage extends StatefulWidget {
  const NovoContatoPage({super.key, this.telefoneInicial = ''});

  /// Vem preenchido quando o número foi lido de um QR code.
  final String telefoneInicial;

  @override
  State<NovoContatoPage> createState() => _NovoContatoPageState();
}

class _NovoContatoPageState extends State<NovoContatoPage> {
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  late final _telefone = TextEditingController(
    text: widget.telefoneInicial.isEmpty
        ? ''
        : formatarTelefone(widget.telefoneInicial),
  );
  final _focoNome = FocusNode();
  final _focoTelefone = FocusNode();
  var _tentou = false;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _focoNome.dispose();
    _focoTelefone.dispose();
    super.dispose();
  }

  void _salvar() {
    setState(() => _tentou = true);
    if (!_formulario.currentState!.validate()) {
      (_validarNome(_nome.text) != null ? _focoNome : _focoTelefone)
          .requestFocus();
      return;
    }
    Navigator.of(context).pop<NovoContato>((
      nome: _nome.text.trim(),
      telefone: normalizarTelefone(_telefone.text)!
    ));
  }

  static String? _validarNome(String? v) =>
      (v?.trim().length ?? 0) < 2 ? 'Informe o nome do contato.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraHelpUS('Novo contato'),
      body: SafeArea(
        child: Form(
          key: _formulario,
          autovalidateMode: _tentou
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nome,
                focusNode: _focoNome,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Nome (obrigatório)',
                    border: OutlineInputBorder()),
                validator: _validarNome,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefone,
                focusNode: _focoTelefone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'WhatsApp com DDD (obrigatório)',
                  helperText: 'Exemplo: 48 99999-0000',
                  border: OutlineInputBorder(),
                ),
                validator: validarTelefone,
                onFieldSubmitted: (_) => _salvar(),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.check),
                  label: const Text('Salvar contato')),
            ],
          ),
        ),
      ),
    );
  }
}
