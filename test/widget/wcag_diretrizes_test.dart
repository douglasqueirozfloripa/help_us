// Diretrizes automáticas do Flutter em todas as telas:
//   androidTapTargetGuideline / iOSTapTargetGuideline   WCAG 2.5.8
//   labeledTapTargetGuideline                           WCAG 4.1.2
//   textContrastGuideline                               WCAG 1.4.3
// E texto a 200% sem estourar a tela (WCAG 1.4.4 e 1.4.10).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes.dart';

Future<void> conferir(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

typedef Tela = ({
  String nome,
  Future<void> Function(WidgetTester, Cenario) chegar
});

final telas = <Tela>[
  (nome: 'Ajuda', chegar: (t, c) async {}),
  (
    nome: 'Ajuda depois do pedido',
    chegar: (t, c) async {
      await t.tap(find.text('Pedir ajuda'));
      await t.pumpAndSettle();
    }
  ),
  (
    nome: 'Eventos',
    chegar: (t, c) async {
      await t.tap(find.text('Eventos'));
      await t.pumpAndSettle();
    }
  ),
  (
    nome: 'Contatos',
    chegar: (t, c) async {
      await t.tap(find.text('Contatos'));
      await t.pumpAndSettle();
    }
  ),
  (
    nome: 'Novo contato com erro',
    chegar: (t, c) async {
      await t.tap(find.text('Contatos'));
      await t.pumpAndSettle();
      await rolarAte(t, find.text('Adicionar digitando'));
      await t.tap(find.text('Adicionar digitando'));
      await t.pumpAndSettle();
      await t.tap(find.text('Salvar contato'));
      await t.pumpAndSettle();
    }
  ),
  (
    nome: 'Ler QR code',
    chegar: (t, c) async {
      await t.tap(find.text('Eventos'));
      await t.pumpAndSettle();
      await t.tap(find.text('Entrar no evento pelo QR code'));
      await t.pumpAndSettle();
    }
  ),
  (
    nome: 'Avaliação com erro',
    chegar: (t, c) async {
      await c.dependencias.eventos.participar(feira);
      await t.pumpAndSettle();
      await rolarAte(t, find.text('Avaliar a acessibilidade do evento'));
      await t.tap(find.text('Avaliar a acessibilidade do evento'));
      await t.pumpAndSettle();
      await rolarAte(t, find.text('Enviar avaliação'));
      await t.tap(find.text('Enviar avaliação'));
      await t.pumpAndSettle();
    }
  ),
];

void main() {
  for (final tela in telas) {
    testWidgets('${tela.nome}: toque, nomes e contraste', (tester) async {
      final semantica = tester.ensureSemantics();
      usarCelular(tester);
      final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
      await c.abrir(tester);
      await tela.chegar(tester, c);
      await conferir(tester);
      semantica.dispose();
    });

    testWidgets('${tela.nome}: texto em 200%', (tester) async {
      usarCelular(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
      await c.abrir(tester);
      await tela.chegar(tester, c);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('o logo na barra é decoração e o leitor pula', (tester) async {
    final semantica = tester.ensureSemantics();
    await Cenario().abrir(tester);
    expect(find.bySemanticsLabel(RegExp('Logo do HelpUS')), findsNothing);
    expect(find.byType(MaterialApp), findsOneWidget);
    semantica.dispose();
  });
}
