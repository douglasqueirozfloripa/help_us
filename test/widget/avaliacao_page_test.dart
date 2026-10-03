import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/src/features/eventos/eventos_page.dart';

import '../ajudantes.dart';

Future<void> abrirAvaliacao(WidgetTester tester, Cenario c) async {
  await c.dependencias.carregar();
  await c.dependencias.eventos.participar(feira);
  await c.abrir(tester);
  final botao = find.text('Avaliar a acessibilidade do evento');
  await rolarAte(tester, botao);
  await tester.tap(botao);
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, String tooltip) async {
  final alvo = find.byTooltip(tooltip);
  await rolarAte(tester, alvo);
  await tester.tap(alvo);
  await tester.pump();
}

Future<void> enviar(WidgetTester tester) async {
  await rolarAte(tester, find.text('Enviar avaliação'));
  await tester.tap(find.text('Enviar avaliação'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('só aparece para quem está num evento', (tester) async {
    final c = Cenario();
    await c.abrir(tester);
    expect(find.text('Avaliar a acessibilidade do evento'), findsNothing);
  });

  testWidgets('traz as seis perguntas de acessibilidade', (tester) async {
    usarCelular(tester);
    final c = Cenario();
    await abrirAvaliacao(tester, c);
    for (final pergunta in [
      'Tinha rampa ou acesso sem degraus?',
      'Tinha cardápio em braille?',
      'Tinha banheiro adaptado?',
      'Tinha espaço sensorial para crianças com TEA?',
      'Tinha vagas de estacionamento para cadeirantes e PCD?',
      'Tinha intérprete de Libras?',
    ]) {
      expect(find.text(pergunta), findsOneWidget, reason: pergunta);
    }
  });

  testWidgets('cada opção diz a qual pergunta pertence', (tester) async {
    final semantica = tester.ensureSemantics();
    usarCelular(tester);
    await abrirAvaliacao(tester, Cenario());
    expect(find.byTooltip('Cardápio em braille: Não sei'), findsOneWidget);
    await rolarAte(tester, find.byTooltip('Parceiro: nota 5 de 5'));
    expect(find.byTooltip('Parceiro: nota 5 de 5'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('enviar incompleto: diz exatamente o que falta, em voz alta',
      (tester) async {
    final semantica = tester.ensureSemantics();
    usarCelular(tester);
    final c = Cenario();
    await abrirAvaliacao(tester, c);

    await enviar(tester);
    final aviso = find.textContaining('Faltam 9 respostas');
    expect(aviso, findsOneWidget);
    expect(tester.getSemantics(aviso), isSemantics(isLiveRegion: true));
    expect(c.mensageiro.abertos, isEmpty);
    semantica.dispose();
  });

  testWidgets(
      'enviar completo: guarda no celular e abre o WhatsApp da organização',
      (tester) async {
    usarCelular(tester);
    final c = Cenario();
    await abrirAvaliacao(tester, c);

    for (final item in [
      'Rampa ou acesso sem degraus',
      'Cardápio em braille',
      'Banheiro adaptado',
      'Espaço sensorial (TEA)',
      'Vagas para cadeirantes e PCD',
    ]) {
      await tocar(tester, '$item: Sim');
    }
    await tocar(tester, 'Intérprete de Libras: Não');
    await tocar(tester, 'Acesso: nota 4 de 5');
    await tocar(tester, 'Evento: nota 5 de 5');
    await tocar(tester, 'Parceiro: nota 3 de 5');
    await enviar(tester);

    final aberto = c.mensageiro.abertos.single;
    expect(aberto.destino, '5548999990002'); // Cleiton, da organização
    expect(aberto.texto, contains('• Intérprete de Libras: Não'));
    expect(c.armazenamento.dados['helpus.avaliacoes.v1'],
        contains('"idEvento":"feira"'));
    expect(find.text('Tinha intérprete de Libras?'), findsNothing);
    expect(find.byType(EventosPage), findsOneWidget);
    expect(find.textContaining('Avaliação salva.'), findsOneWidget);
  });

  testWidgets('voltar pela seta sem enviar fica na tela de Ajuda',
      (tester) async {
    usarCelular(tester);
    final c = Cenario();
    await abrirAvaliacao(tester, c);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.byType(EventosPage), findsNothing);
    expect(find.text('Avaliar a acessibilidade do evento'), findsOneWidget);
    expect(c.mensageiro.abertos, isEmpty);
  });
}
