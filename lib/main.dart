import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'src/app/atalhos.dart';
import 'src/app/dependencias.dart';
import 'src/data/armazenamento.dart';
import 'src/data/fonte_de_eventos.dart';
import 'src/servicos/localizacao.dart';
import 'src/servicos/mensageiro.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Na web, gera a árvore ARIA que NVDA, VoiceOver e axe-core leem.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();

  final dependencias = Dependencias(
    armazenamento: ArmazenamentoLocal(),
    fonteDeEventos: const EventosDoArquivo(),
    localizacao: LocalizacaoPorGps(),
    mensageiro: MensageiroDoSistema(),
  );

  runApp(HelpUSApp(dependencias: dependencias));

  if (!kIsWeb) configurarAtalhos(dependencias);
}
