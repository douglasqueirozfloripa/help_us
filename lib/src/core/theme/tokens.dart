import 'dart:ui';

abstract final class NomeDoApp {
  /// Troque aqui se o nome final for outro (ex.: "AcessaAí").
  static const valor = 'HelpUS';
}

abstract final class Cores {
  static const azulAcesso = Color(0xFF14325C);
  static const dourado = Color(0xFFF2C230);
  static const douradoClaro = Color(0xFFFFF4CC);
  static const pergaminho = Color(0xFFE9D8B4);
  static const pergaminhoClaro = Color(0xFFF3EAD6);
  static const papel = Color(0xFFFAF6EC);
  static const tinta = Color(0xFF1C1B1F);
  static const tintaSuave = Color(0xFF4A4458);
  static const branco = Color(0xFFFFFFFF);

  /// Vermelho do botão de ajuda.
  static const socorro = Color(0xFFB3261E);
  static const socorroEscuro = Color(0xFF8C1D18);
  static const socorroClaro = Color(0xFFFCE8E6);

  static const sucesso = Color(0xFF1E5631);
  static const sucessoClaro = Color(0xFFE3F1E6);
}

class ParContraste {
  const ParContraste(this.nome, this.frente, this.fundo, {this.minimo = 4.5});

  final String nome;
  final Color frente;
  final Color fundo;
  final double minimo;
}

const paresDoTema = <ParContraste>[
  ParContraste('Texto principal', Cores.tinta, Cores.papel),
  ParContraste('Texto secundário', Cores.tintaSuave, Cores.papel),
  ParContraste('Texto nos cartões', Cores.tinta, Cores.branco),
  ParContraste('Texto no fundo de seção', Cores.tinta, Cores.pergaminhoClaro),
  ParContraste('Barra do app', Cores.branco, Cores.azulAcesso),
  ParContraste('Botão Pedir ajuda', Cores.branco, Cores.socorro),
  ParContraste('Aviso de erro', Cores.socorroEscuro, Cores.socorroClaro),
  ParContraste('Aviso de sucesso', Cores.sucesso, Cores.sucessoClaro),
  ParContraste('Aviso em andamento', Cores.tinta, Cores.douradoClaro),
  ParContraste('Contorno do botão de ajuda', Cores.socorro, Cores.papel,
      minimo: 3),
  ParContraste('Traço dourado do logo', Cores.dourado, Cores.azulAcesso,
      minimo: 3),
];
