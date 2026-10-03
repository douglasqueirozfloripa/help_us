// Num aparelho de verdade: make e2e
// Com TalkBack/VoiceOver ligado, use como roteiro do que deve ser ouvido.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/app.dart';
import 'package:helpus/src/app/dependencias.dart';
import 'package:helpus/src/data/armazenamento.dart';
import 'package:helpus/src/data/fonte_de_eventos.dart';
import 'package:helpus/src/servicos/localizacao.dart';
import 'package:helpus/src/servicos/mensageiro.dart';
import 'package:integration_test/integration_test.dart';

class _MensageiroQueAnota implements Mensageiro {
  final textos = <String>[];

  @override
  Future<bool> abrirWhatsApp(String telefone, String texto) async {
    textos.add(texto);
    return true;
  }

  @override
  Future<bool> abrirSms(String telefone, String texto) async => false;

  @override
  Future<bool> ligar(String numero) async => true;
}

class _GpsFixo implements ServicoLocalizacao {
  @override
  Future<ResultadoLocalizacao> posicaoAtual() async => ResultadoLocalizacao(
        posicao: Posicao(
            latitude: -27.5855,
            longitude: -48.6147,
            precisaoMetros: 10,
            obtidaEm: DateTime.now()),
      );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Dado que entrei na Feira pela lista de eventos, quando toco em Pedir ajuda, '
      'então a central recebe minha localização e depois consigo avaliar o evento',
      (tester) async {
    final semantica = tester.ensureSemantics();
    final mensageiro = _MensageiroQueAnota();
    final dependencias = Dependencias(
      armazenamento: ArmazenamentoEmMemoria(),
      fonteDeEventos: const EventosDoArquivo(),
      localizacao: _GpsFixo(),
      mensageiro: mensageiro,
    );
    await tester.pumpWidget(HelpUSApp(dependencias: dependencias));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eventos'));
    await tester.pumpAndSettle();
    final participar =
        find.text('Participar do evento Feira Inclusiva de São José');
    await tester.scrollUntilVisible(participar, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(participar);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajuda'));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.tap(find.text('Pedir ajuda'));
    await tester.pumpAndSettle();
    expect(mensageiro.textos.single,
        contains('https://www.google.com/maps?q=-27.585500,-48.614700'));
    expect(
        find.textContaining('a central do evento Feira Inclusiva de São José'),
        findsOneWidget);

    final avaliar = find.text('Avaliar a acessibilidade do evento');
    await tester.scrollUntilVisible(avaliar, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(avaliar);
    await tester.pumpAndSettle();
    expect(find.text('Tinha intérprete de Libras?'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsWidgets);
    semantica.dispose();
  });
}
