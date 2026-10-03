enum OrigemContato { digitado, qrCode, evento }

class Contato {
  const Contato({
    required this.id,
    required this.nome,
    required this.telefone,
    this.origem = OrigemContato.digitado,
  });

  factory Contato.fromJson(Map<String, Object?> json) => Contato(
        id: json['id']! as String,
        nome: json['nome']! as String,
        telefone: json['telefone']! as String,
        origem: OrigemContato.values
            .byName((json['origem'] as String?) ?? 'digitado'),
      );

  final String id;
  final String nome;

  /// Normalizado: só dígitos, com 55.
  final String telefone;
  final OrigemContato origem;

  Map<String, Object?> toJson() =>
      {'id': id, 'nome': nome, 'telefone': telefone, 'origem': origem.name};
}

/// O que vai no pedido de ajuda sobre quem pede.
class Perfil {
  const Perfil({this.nome = '', this.informacaoImportante = ''});

  factory Perfil.fromJson(Map<String, Object?> json) => Perfil(
        nome: (json['nome'] as String?) ?? '',
        informacaoImportante: (json['informacaoImportante'] as String?) ?? '',
      );

  final String nome;

  /// Ex.: "Sou cadeirante", "Sou surda, prefiro mensagem escrita".
  final String informacaoImportante;

  Map<String, Object?> toJson() =>
      {'nome': nome, 'informacaoImportante': informacaoImportante};
}
