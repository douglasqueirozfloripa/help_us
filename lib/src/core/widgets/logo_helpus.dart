import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// O logo desenhado em código, com a mesma geometria de
/// `assets/logo/garapuvu-logo.svg` (grade de 512 x 512).
///
/// Leonardo da Vinci desenhou o Homem Vitruviano com duas poses sobrepostas
/// dentro de um círculo e de um quadrado. Aqui a figura é também o símbolo
/// de acessibilidade universal: braços abertos, ondas de voz saindo da cabeça
/// (o leitor de tela) e a letra H em braille aos pés.
class LogoHelpUS extends StatelessWidget {
  const LogoHelpUS({super.key, this.tamanho = 40, this.decorativo = true});

  final double tamanho;

  /// Ao lado do nome do app o logo é decoração e o leitor de tela pula.
  /// Sozinho (na abertura) ele ganha descrição.
  final bool decorativo;

  static const descricao = 'Logo do HelpUS: figura humana de braços abertos '
      'dentro de um círculo e de um quadrado, inspirada no Homem Vitruviano, '
      'com ondas de voz e a letra H em braille.';

  @override
  Widget build(BuildContext context) {
    final desenho = CustomPaint(
      size: Size.square(tamanho),
      painter: const _PintorDoLogo(),
    );
    if (decorativo) return ExcludeSemantics(child: desenho);
    return Semantics(
        container: true, image: true, label: descricao, child: desenho);
  }
}

class _PintorDoLogo extends CustomPainter {
  const _PintorDoLogo();

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.shortestSide / 512;
    canvas
      ..save()
      ..translate(
          (size.width - 512 * escala) / 2, (size.height - 512 * escala) / 2)
      ..scale(escala);

    canvas.drawCircle(
        const Offset(256, 256), 246, Paint()..color = Cores.azulAcesso);
    canvas.drawCircle(
      const Offset(256, 256),
      240,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = Cores.pergaminho,
    );

    final dourado = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Cores.dourado;
    canvas
      ..drawRect(const Rect.fromLTWH(106, 132, 300, 300), dourado)
      ..drawCircle(const Offset(256, 262), 170, dourado);

    // Segunda pose, mais clara, como traço de esboço.
    final esboco = Paint()
      ..color = Cores.branco.withValues(alpha: 0.55)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(256, 200), const Offset(117, 164), esboco)
      ..drawLine(const Offset(256, 200), const Offset(395, 164), esboco)
      ..drawLine(const Offset(256, 300), const Offset(171, 409), esboco)
      ..drawLine(const Offset(256, 300), const Offset(341, 409), esboco);

    final traco = Paint()
      ..color = Cores.branco
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(256, 182), const Offset(256, 300), traco)
      ..drawLine(const Offset(112, 200), const Offset(400, 200), traco)
      ..drawLine(const Offset(256, 300), const Offset(232, 428), traco)
      ..drawLine(const Offset(256, 300), const Offset(280, 428), traco)
      ..drawCircle(const Offset(256, 150), 26, Paint()..color = Cores.branco);

    // Ondas de voz.
    final onda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Cores.dourado;
    canvas
      ..drawArc(Rect.fromCircle(center: const Offset(257, 150), radius: 40),
          -0.466, 0.932, false, onda)
      ..drawArc(Rect.fromCircle(center: const Offset(256, 150), radius: 60),
          -0.562, 1.124, false, onda);

    // Letra H em braille: pontos 1, 2 e 5 cheios; 3, 4 e 6 vazios.
    final ponto = Paint()..color = Cores.pergaminho;
    for (final centro in const [
      Offset(247, 452),
      Offset(247, 470),
      Offset(265, 470)
    ]) {
      canvas.drawCircle(centro, 5.5, ponto);
    }
    final vazio = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Cores.pergaminho.withValues(alpha: 0.6);
    for (final centro in const [
      Offset(265, 452),
      Offset(247, 488),
      Offset(265, 488)
    ]) {
      canvas.drawCircle(centro, 4.5, vazio);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorDoLogo oldDelegate) => false;
}
