import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/src/core/utils/distancia.dart';
import 'package:helpus/src/features/sos/mensagem_sos.dart';
import 'package:helpus/src/features/eventos/evento.dart';
import 'package:helpus/src/servicos/localizacao.dart';

import '../ajudantes.dart';

void main() {
  test('leva o link do Google Maps, as coordenadas e a precisão', () {
    final texto = montarMensagemSos(
      agora: agora,
      localizacao: ResultadoLocalizacao(posicao: posicaoNoShopping),
      nome: 'Ana',
      informacaoImportante: 'Sou cadeirante',
      evento: feira,
    );
    expect(
        texto, contains('https://www.google.com/maps?q=-27.585531,-48.614722'));
    expect(texto, contains('Coordenadas: -27.585531, -48.614722'));
    expect(texto, contains('Precisão: cerca de 12 m'));
    expect(texto, contains('Quem pede: Ana'));
    expect(texto, contains('Importante: Sou cadeirante'));
    expect(texto, contains('Evento: Feira Inclusiva'));
    expect(texto, contains('Enviado em 17/10/2026 às 14:30'));
  });

  group('fora do local do evento', () {
    Posicao aoNorteDaFeira(double metros, {double precisao = 12}) => Posicao(
          latitude: feira.latitude! + metros / 111195,
          longitude: feira.longitude!,
          precisaoMetros: precisao,
          obtidaEm: agora,
        );

    String mensagem(Posicao posicao, {Evento evento = feira}) =>
        montarMensagemSos(
            agora: agora,
            localizacao: ResultadoLocalizacao(posicao: posicao),
            evento: evento);

    test('avisa em destaque, logo depois do título', () {
      final linhas = mensagem(posicaoLongeDaFeira).split('\n');
      expect(linhas[1], '⚠️ *ATENÇÃO: A PESSOA NÃO ESTÁ NO LOCAL DO EVENTO.*');
      expect(
          linhas[2],
          '*Está em outro lugar, a cerca de 6,9 km do local do evento '
          '(Continente Shopping). Vá pelo link de localização abaixo, '
          'não pelo endereço do evento.*');
      expect(linhas, contains('Evento: Feira Inclusiva'));
      expect(linhas,
          contains('Localização: ${posicaoLongeDaFeira.linkGoogleMaps}'));
    });

    test('dentro da área do evento, não avisa nada', () {
      expect(mensagem(posicaoNoShopping), isNot(contains('NÃO ESTÁ')));
      expect(mensagem(aoNorteDaFeira(350)), isNot(contains('NÃO ESTÁ')));
    });

    test('logo depois da borda da área, já avisa', () {
      expect(mensagem(aoNorteDaFeira(600)),
          contains('a cerca de 600 m do local do evento'));
    });

    test('perto da borda, a margem de erro do GPS não vira alarme falso', () {
      expect(mensagem(aoNorteDaFeira(450, precisao: 100)),
          isNot(contains('NÃO ESTÁ')));
    });

    test('evento sem coordenadas ou pedido sem GPS não afirmam nada', () {
      expect(mensagem(posicaoLongeDaFeira, evento: corrida),
          isNot(contains('NÃO ESTÁ')));
      expect(
          montarMensagemSos(
              agora: agora,
              localizacao: const ResultadoLocalizacao(
                  problema: ProblemaLocalizacao.semSinal),
              evento: feira),
          isNot(contains('NÃO ESTÁ')));
    });

    test('evento sem local escrito fala só "do local do evento"', () {
      const semLocal = Evento(
          id: 'x',
          nome: 'X',
          cidade: '',
          whatsappCentral: '5548999990001',
          latitude: -27.585531,
          longitude: -48.614722);
      expect(mensagem(posicaoLongeDaFeira, evento: semLocal),
          contains('do local do evento. Vá pelo link'));
    });
  });

  test('distância em metros ou em km com vírgula', () {
    expect(distanciaLegivel(850.4), '850 m');
    expect(distanciaLegivel(999.7), '1,0 km');
    expect(distanciaLegivel(6849), '6,8 km');
    expect(distanciaEmMetros(-27.585531, -48.614722, -27.575531, -48.614722),
        closeTo(1112, 1));
  });

  test('sem GPS, avisa o motivo em vez de mandar um link errado', () {
    final texto = montarMensagemSos(
      agora: agora,
      localizacao: const ResultadoLocalizacao(
          problema: ProblemaLocalizacao.gpsDesligado),
    );
    expect(texto, isNot(contains('google.com/maps')));
    expect(
        texto,
        contains(
            'não foi possível obter o GPS. O GPS do celular está desligado.'));
  });

  test('com a última posição conhecida, deixa claro que é aproximada', () {
    final aproximada = Posicao(
      latitude: 1,
      longitude: 2,
      precisaoMetros: 500,
      obtidaEm: DateTime(2026, 10, 17, 13, 5),
      aproximada: true,
    );
    final texto = montarMensagemSos(
        agora: agora, localizacao: ResultadoLocalizacao(posicao: aproximada));
    expect(texto, contains('aproximada (última posição conhecida, às 13:05)'));
  });

  test('campos vazios não viram linhas vazias', () {
    final texto = montarMensagemSos(
        agora: agora,
        localizacao: ResultadoLocalizacao(posicao: posicaoNoShopping));
    expect(texto, isNot(contains('Quem pede')));
    expect(texto, isNot(contains('\n\n')));
  });
}
