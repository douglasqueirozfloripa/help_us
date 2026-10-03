import '../../core/utils/datas.dart';

enum ItemAcessibilidade {
  rampa('Tinha rampa ou acesso sem degraus?', 'Rampa ou acesso sem degraus'),
  cardapioBraille('Tinha cardápio em braille?', 'Cardápio em braille'),
  banheiroAdaptado('Tinha banheiro adaptado?', 'Banheiro adaptado'),
  espacoSensorial('Tinha espaço sensorial para crianças com TEA?',
      'Espaço sensorial (TEA)'),
  vagasPcd('Tinha vagas de estacionamento para cadeirantes e PCD?',
      'Vagas para cadeirantes e PCD'),
  interpreteLibras('Tinha intérprete de Libras?', 'Intérprete de Libras');

  const ItemAcessibilidade(this.pergunta, this.nomeCurto);
  final String pergunta;
  final String nomeCurto;
}

enum Resposta {
  sim('Sim'),
  nao('Não'),
  naoSei('Não sei');

  const Resposta(this.rotulo);
  final String rotulo;
}

class Avaliacao {
  const Avaliacao({
    required this.idEvento,
    required this.nomeEvento,
    required this.respostas,
    required this.notaAcesso,
    required this.notaEvento,
    required this.notaParceiro,
    required this.feitaEm,
    this.parceiro = '',
    this.comentario = '',
  });

  final String idEvento;
  final String nomeEvento;
  final String parceiro;
  final Map<ItemAcessibilidade, Resposta> respostas;
  final int notaAcesso;
  final int notaEvento;
  final int notaParceiro;
  final String comentario;
  final DateTime feitaEm;

  Map<String, Object?> toJson() => {
        'idEvento': idEvento,
        'nomeEvento': nomeEvento,
        'parceiro': parceiro,
        'respostas': {
          for (final e in respostas.entries) e.key.name: e.value.name
        },
        'notaAcesso': notaAcesso,
        'notaEvento': notaEvento,
        'notaParceiro': notaParceiro,
        'comentario': comentario,
        'feitaEm': feitaEm.toIso8601String(),
      };

  /// Vai para a organização pelo WhatsApp, legível sem nenhum app.
  String textoParaOrganizacao() => [
        '📝 Avaliação de acessibilidade — $nomeEvento',
        for (final item in ItemAcessibilidade.values)
          '• ${item.nomeCurto}: ${respostas[item]?.rotulo ?? '—'}',
        'Nota do acesso ao evento: $notaAcesso de 5',
        'Nota da experiência no evento: $notaEvento de 5',
        if (parceiro.isNotEmpty)
          'Nota do parceiro ($parceiro): $notaParceiro de 5'
        else
          'Nota do parceiro: $notaParceiro de 5',
        if (comentario.trim().isNotEmpty) 'Comentário: ${comentario.trim()}',
        'Respondido em ${data(feitaEm)} às ${hora(feitaEm)}',
      ].join('\n');
}
