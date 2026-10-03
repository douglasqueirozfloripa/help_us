import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/src/core/theme/contraste.dart';
import 'package:helpus/src/core/theme/tokens.dart';

void main() {
  group('Cálculo de contraste da WCAG', () {
    test('preto sobre branco é 21 : 1', () {
      expect(razaoDeContraste(const Color(0xFF000000), const Color(0xFFFFFFFF)),
          closeTo(21, 0.01));
    });

    test('uma cor sobre ela mesma é 1 : 1', () {
      expect(razaoDeContraste(Cores.papel, Cores.papel), closeTo(1, 0.001));
    });

    test('a ordem das cores não muda o resultado', () {
      expect(
        razaoDeContraste(Cores.azulAcesso, Cores.branco),
        razaoDeContraste(Cores.branco, Cores.azulAcesso),
      );
    });

    test('cinza #767676 sobre branco fica em 4,5 : 1 (o limite do AA)', () {
      expect(razaoDeContraste(const Color(0xFF767676), const Color(0xFFFFFFFF)),
          closeTo(4.54, 0.01));
    });

    test('formata no jeito brasileiro', () {
      expect(formatarRazao(12.345), '12,3 : 1');
    });
  });

  group('Paleta do HelpUS (WCAG 1.4.3 e 1.4.11)', () {
    for (final par in paresDoTema) {
      test('${par.nome} tem pelo menos ${formatarRazao(par.minimo)}', () {
        final razao = razaoDeContraste(par.frente, par.fundo);
        expect(razao, greaterThanOrEqualTo(par.minimo),
            reason: '${par.nome}: ${formatarRazao(razao)}');
      });
    }
  });
}
