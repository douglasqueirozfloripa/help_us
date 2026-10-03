// Trocar de aba pelo teclado leva o foco para a tela nova (WCAG 2.4.3):
// o leitor de tela anuncia o título e o próximo Tab entra no conteúdo,
// em vez de ir para a aba ao lado.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes.dart';

/// O título na barra do app, que é o cabeçalho da tela.
Finder titulo(String texto) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(texto));

void main() {
  testWidgets('Enter na aba Eventos: foco no título e o Tab entra na tela',
      (tester) async {
    final semantica = tester.ensureSemantics();
    usarCelular(tester);
    final c = Cenario();
    await c.abrir(tester);

    final tabs = await tabAte(
        tester,
        (foco) =>
            foco
                .findAncestorWidgetOfExactType<NavigationDestination>()
                ?.label ==
            'Eventos');
    expect(tabs, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // "Eventos, cabeçalho": é o que o NVDA fala quando o foco chega.
    expect(
      tester.getSemantics(titulo('Eventos')),
      isSemantics(
          label: 'Eventos', isHeader: true, isFocusable: true, isFocused: true),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester.getSemantics(find.text('Entrar no evento pelo QR code')),
      isSemantics(isButton: true, isFocused: true),
    );
    semantica.dispose();
  });

  testWidgets('o título não é parada do Tab: só recebe o foco ao trocar de aba',
      (tester) async {
    usarCelular(tester);
    final c = Cenario();
    await c.abrir(tester);

    final tabs = await tabAte(
        tester,
        (foco) =>
            foco.findAncestorWidgetOfExactType<AppBar>() != null &&
            foco.findAncestorWidgetOfExactType<NavigationDestination>() ==
                null);
    expect(tabs, -1);
  });

  testWidgets('"Ver eventos" pelo teclado também leva o foco ao título',
      (tester) async {
    final semantica = tester.ensureSemantics();
    usarCelular(tester);
    final c = Cenario();
    await c.abrir(tester);

    final tabs = await tabAte(
        tester,
        (foco) =>
            (foco.findAncestorWidgetOfExactType<OutlinedButton>()?.child
                    as Text?)
                ?.data ==
            'Ver eventos');
    expect(tabs, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(tester.getSemantics(titulo('Eventos')),
        isSemantics(label: 'Eventos', isHeader: true, isFocused: true));
    semantica.dispose();
  });
}
