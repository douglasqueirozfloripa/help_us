import 'dart:math' as math;
import 'dart:ui';

/// Luminância relativa segundo a WCAG 2.2 (0 = preto, 1 = branco).
double luminanciaRelativa(Color cor) {
  double linear(double canal) => canal <= 0.04045
      ? canal / 12.92
      : math.pow((canal + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * linear(cor.r) +
      0.7152 * linear(cor.g) +
      0.0722 * linear(cor.b);
}

/// Razão de contraste entre duas cores, de 1 (iguais) a 21 (preto e branco).
double razaoDeContraste(Color a, Color b) {
  final la = luminanciaRelativa(a);
  final lb = luminanciaRelativa(b);
  final clara = math.max(la, lb);
  final escura = math.min(la, lb);
  return (clara + 0.05) / (escura + 0.05);
}

/// "12,4 : 1" — do jeito que se lê no Brasil.
String formatarRazao(double razao) =>
    '${razao.toStringAsFixed(1).replaceAll('.', ',')} : 1';
