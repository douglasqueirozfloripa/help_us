// A funcionalidade principal, do jeito que um leitor de tela vive ela.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/src/features/sos/ajuda_page.dart';

import '../ajudantes.dart';

void main() {
  testWidgets('o botão é lido como "Pedir ajuda" e diz para quem vai',
      (tester) async {
    final semantica = tester.ensureSemantics();
    final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
    await c.abrir(tester);

    expect(
      tester.getSemantics(find.byType(BotaoSos)),
      isSemantics(
        label: 'Pedir ajuda',
        hint: 'Envia sua localização pelo WhatsApp para Maria.',
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantica.dispose();
  });

  testWidgets(
      'é a primeira coisa depois do cartão do evento na ordem de leitura',
      (tester) async {
    final semantica = tester.ensureSemantics();
    usarCelular(tester);
    final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
    await c.abrir(tester);

    final falas = tester.semantics
        .simulatedAccessibilityTraversal()
        // getSemanticsData: o que o leitor de tela recebe, já com os filhos
        // juntados (o botão tira o nome do texto dentro dele).
        .map((n) => n.getSemanticsData())
        .map((d) => d.label.isNotEmpty ? d.label : d.tooltip)
        .where((f) => f.isNotEmpty)
        .toList();
    expect(falas, containsAllInOrder(['HelpUS', 'Ver eventos', 'Pedir ajuda']));
    semantica.dispose();
  });

  testWidgets(
      'um toque: WhatsApp aberto com a localização e aviso falado sozinho',
      (tester) async {
    final semantica = tester.ensureSemantics();
    usarCelular(tester);
    final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
    await c.abrir(tester);

    await tester.tap(find.byType(BotaoSos));
    await tester.pumpAndSettle();

    expect(c.mensageiro.abertos.single.texto,
        contains('https://www.google.com/maps?q=-27.585531,-48.614722'));
    const aviso = 'Mensagem pronta no WhatsApp para Maria. Toque em Enviar.';
    expect(
        tester.getSemantics(find.text(aviso)), isSemantics(isLiveRegion: true));
    expect(find.widgetWithText(OutlinedButton, 'João'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets(
      'o toque também funciona pela ação do leitor de tela (duplo toque)',
      (tester) async {
    final semantica = tester.ensureSemantics();
    final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
    await c.abrir(tester);

    final botao = tester.getSemantics(find.byType(BotaoSos));
    botao.owner!.performAction(botao.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(c.mensageiro.abertos, hasLength(1));
    semantica.dispose();
  });

  testWidgets('com teclado: Tab chega no botão e Enter pede ajuda',
      (tester) async {
    final semantica = tester.ensureSemantics();
    usarCelular(tester);
    final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
    await c.abrir(tester);

    final tabs = await tabAte(tester,
        (foco) => foco.findAncestorWidgetOfExactType<BotaoSos>() != null);
    expect(tabs, greaterThan(0));
    // O leitor de tela precisa saber que o foco chegou: é isso que leva o
    // foco do navegador para o botão e faz o NVDA falar "Pedir ajuda".
    expect(tester.getSemantics(find.byType(BotaoSos)),
        isSemantics(label: 'Pedir ajuda', isFocusable: true, isFocused: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(c.mensageiro.abertos, hasLength(1));
    semantica.dispose();
  });

  testWidgets('sem contato: o aviso diz o que fazer e cita 192 e 193',
      (tester) async {
    final c = Cenario();
    await c.abrir(tester);
    await tester.tap(find.byType(BotaoSos));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cadastre um contato'), findsOneWidget);
    expect(c.mensageiro.abertos, isEmpty);
  });

  testWidgets('botões de ligar para emergência', (tester) async {
    usarCelular(tester);
    final c = Cenario();
    await c.abrir(tester);
    await rolarAte(tester, find.text('193 Bombeiros'));
    await tester.tap(find.text('193 Bombeiros'));
    expect(c.mensageiro.abertos.single.destino, '193');
  });
}
