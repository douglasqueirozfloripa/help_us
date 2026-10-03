import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/src/core/utils/telefone.dart';
import 'package:helpus/src/features/contatos/leitor_qr.dart';

void main() {
  group('Telefone', () {
    test('aceita os jeitos comuns de escrever', () {
      for (final escrito in [
        '(48) 99999-0000',
        '48999990000',
        '+55 48 99999-0000',
        '048 99999-0000',
        '005548999990000'
      ]) {
        expect(normalizarTelefone(escrito), '5548999990000', reason: escrito);
      }
    });

    test('fixo de 8 dígitos também serve', () {
      expect(normalizarTelefone('48 3333-4444'), '554833334444');
    });

    test('recusa número curto e explica o que falta', () {
      expect(normalizarTelefone('99999-0000'), isNull);
      expect(validarTelefone('123'),
          'Informe o telefone com DDD, por exemplo 48 99999-0000.');
    });

    test('mostra e fala o número de um jeito humano', () {
      expect(formatarTelefone('5548999990000'), '(48) 99999-0000');
      expect(telefoneParaFala('5548999990000'), '4 8 9 9 9 9 9 0 0 0 0');
    });
  });

  group('QR code', () {
    test('link wa.me vira contato', () {
      final r = interpretarQr('https://wa.me/5548999990000?text=oi');
      expect(
          r,
          isA<QrContato>()
              .having((q) => q.telefone, 'telefone', '5548999990000'));
    });

    test('link api.whatsapp.com vira contato', () {
      final r =
          interpretarQr('https://api.whatsapp.com/send?phone=5548999990000');
      expect(r, isA<QrContato>());
    });

    test('número puro vira contato', () {
      expect(interpretarQr('48 99999-0000'), isA<QrContato>());
    });

    test('QR do evento liga o participante à organização', () {
      final r = interpretarQr(
        '{"helpus":"evento","id":"feira","nome":"Feira Inclusiva","cidade":"São José","whatsapp":"48 99999-0001"}',
      );
      expect(
        r,
        isA<QrEvento>()
            .having((e) => e.id, 'id', 'feira')
            .having((e) => e.whatsapp, 'whatsapp', '5548999990001')
            .having((e) => e.cidade, 'cidade', 'São José'),
      );
    });

    test('QR de evento sem número é recusado com explicação', () {
      final r = interpretarQr('{"helpus":"evento","id":"x","nome":"X"}');
      expect(
          r,
          isA<QrInvalido>()
              .having((q) => q.motivo, 'motivo', contains('incompleto')));
    });

    test('site qualquer não é aceito', () {
      expect(interpretarQr('https://example.com'), isA<QrInvalido>());
      expect(interpretarQr(''), isA<QrInvalido>());
      expect(interpretarQr('{quebrado'), isA<QrInvalido>());
    });
  });
}
