import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ajudantes.dart';

Future<void> irPara(WidgetTester tester, String aba) async {
  await tester.tap(find.text(aba));
  await tester.pumpAndSettle();
}

void main() {
  group('Eventos', () {
    testWidgets('lista por cidade e o card do evento é um cabeçalho com resumo',
        (tester) async {
      final semantica = tester.ensureSemantics();
      usarCelular(tester);
      final c = Cenario();
      await c.abrir(tester);
      await irPara(tester, 'Eventos');

      expect(find.text('Feira Inclusiva'), findsOneWidget);
      expect(find.text('Corrida Garapuvu'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Florianópolis'));
      await tester.pumpAndSettle();
      expect(find.text('Feira Inclusiva'), findsNothing);

      expect(
        tester.getSemantics(find
            .bySemanticsLabel(RegExp(r'^Corrida Garapuvu\. Florianópolis'))),
        isSemantics(isHeader: true),
      );
      semantica.dispose();
    });

    testWidgets('participar muda para quem vai o pedido de ajuda',
        (tester) async {
      usarCelular(tester);
      final c = Cenario();
      await c.abrir(tester);
      await irPara(tester, 'Eventos');

      final participar = find.text('Participar do evento Feira Inclusiva');
      await rolarAte(tester, participar);
      await tester.tap(participar);
      await tester.pumpAndSettle();
      expect(find.text('Sair do evento Feira Inclusiva'), findsOneWidget);

      await irPara(tester, 'Ajuda');
      expect(find.text('Você está no evento'), findsOneWidget);
      expect(c.dependencias.sos.destino?.telefone, feira.whatsappCentral);
    });

    testWidgets('contato do administrador: o número é falado dígito a dígito',
        (tester) async {
      final semantica = tester.ensureSemantics();
      usarCelular(tester);
      final c = Cenario();
      await c.abrir(tester);
      await irPara(tester, 'Eventos');

      const fala =
          'Falar no WhatsApp com Cleiton, organização. Número 4 8 9 9 9 9 9 0 0 0 2.';
      expect(find.bySemanticsLabel(fala), findsOneWidget);
      await tester.tap(find.textContaining('Cleiton'));
      expect(c.mensageiro.abertos.single.destino, '5548999990002');
      semantica.dispose();
    });

    testWidgets(
        'QR code do evento: entra no evento e volta para a tela de ajuda',
        (tester) async {
      usarCelular(tester);
      final c = Cenario()
        ..qrLido =
            '{"helpus":"evento","id":"novo","nome":"Show na Praça","cidade":"Biguaçu","whatsapp":"48 99999-0099"}';
      await c.abrir(tester);
      await irPara(tester, 'Eventos');
      await tester.tap(find.text('Entrar no evento pelo QR code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simular leitura'));
      await tester.pumpAndSettle();

      expect(c.dependencias.eventos.participando?.nome, 'Show na Praça');
      expect(find.text('Show na Praça'), findsOneWidget);
      expect(find.textContaining('Você entrou no evento Show na Praça'),
          findsOneWidget);
    });

    testWidgets('QR inválido: erro explicado e dá para digitar o número',
        (tester) async {
      final semantica = tester.ensureSemantics();
      usarCelular(tester);
      final c = Cenario()..qrLido = 'https://example.com';
      await c.abrir(tester);
      await irPara(tester, 'Contatos');
      await rolarAte(tester, find.text('Adicionar pelo QR code'));
      await tester.tap(find.text('Adicionar pelo QR code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simular leitura'));
      await tester.pumpAndSettle();

      const erro = 'Este QR code não é de um número de WhatsApp.';
      expect(tester.getSemantics(find.text(erro)),
          isSemantics(isLiveRegion: true));

      await tester.enterText(
          find.widgetWithText(TextField, 'WhatsApp com DDD'), '48 99999-0055');
      await tester.tap(find.text('Usar este número'));
      await tester.pumpAndSettle();
      expect(find.text('Novo contato'), findsOneWidget);
      expect(find.text('(48) 99999-0055'), findsOneWidget);
      semantica.dispose();
    });
  });

  group('Contatos', () {
    testWidgets('adicionar digitando, com erro explicado antes',
        (tester) async {
      usarCelular(tester);
      final c = Cenario();
      await c.abrir(tester);
      await irPara(tester, 'Contatos');
      await rolarAte(tester, find.text('Adicionar digitando'));
      await tester.tap(find.text('Adicionar digitando'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar contato'));
      await tester.pumpAndSettle();
      expect(find.text('Informe o nome do contato.'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Nome (obrigatório)'), 'Maria');
      await tester.enterText(
          find.widgetWithText(TextField, 'WhatsApp com DDD (obrigatório)'),
          '48 98888-7777');
      await tester.tap(find.text('Salvar contato'));
      await tester.pumpAndSettle();

      expect(c.dependencias.contatos.principal?.telefone, '5548988887777');
      expect(
          find.text('Maria foi adicionado aos seus contatos.'), findsOneWidget);
    });

    testWidgets(
        'cada contato é lido com o número dígito a dígito e se é o principal',
        (tester) async {
      final semantica = tester.ensureSemantics();
      usarCelular(tester);
      final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
      await c.abrir(tester);
      await irPara(tester, 'Contatos');

      expect(
          find.bySemanticsLabel(
              'Maria, contato principal. WhatsApp 4 8 9 8 8 8 8 7 7 7 7.'),
          findsOneWidget);
      expect(find.byTooltip('Tornar João o contato principal'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('remover pede confirmação', (tester) async {
      usarCelular(tester);
      final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
      await c.abrir(tester);
      await irPara(tester, 'Contatos');

      await tester.tap(find.byTooltip('Remover João'));
      await tester.pumpAndSettle();
      expect(find.text('Remover João?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
      await tester.pumpAndSettle();
      expect(c.dependencias.contatos.contatos.map((x) => x.nome), ['Maria']);
    });

    testWidgets('dados pessoais vão junto no pedido de ajuda', (tester) async {
      usarCelular(tester);
      final c = Cenario(salvo: {'helpus.contatos.v1': contatoSalvo});
      await c.abrir(tester);
      await irPara(tester, 'Contatos');

      await tester.enterText(find.widgetWithText(TextField, 'Seu nome'), 'Ana');
      await tester.enterText(
          find.widgetWithText(
              TextField, 'O que quem vier ajudar precisa saber'),
          'Sou cadeirante');
      await tester.tap(find.text('Salvar meus dados'));
      await tester.pumpAndSettle();

      await irPara(tester, 'Ajuda');
      await c.dependencias.sos.pedirAjuda();
      expect(c.mensageiro.abertos.single.texto,
          contains('Importante: Sou cadeirante'));
    });
  });
}
