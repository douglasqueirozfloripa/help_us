import '../../core/utils/distancia.dart';
import '../../servicos/localizacao.dart';

class Administrador {
  const Administrador(
      {required this.nome, required this.whatsapp, this.funcao = ''});

  factory Administrador.fromJson(Map<String, Object?> json) => Administrador(
        nome: json['nome']! as String,
        whatsapp: json['whatsapp']! as String,
        funcao: (json['funcao'] as String?) ?? '',
      );

  final String nome;
  final String whatsapp;
  final String funcao;

  Map<String, Object?> toJson() =>
      {'nome': nome, 'whatsapp': whatsapp, 'funcao': funcao};
}

class Evento {
  const Evento({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.whatsappCentral,
    this.local = '',
    this.endereco = '',
    this.parceiro = '',
    this.inicio,
    this.fim,
    this.administradores = const [],
    this.latitude,
    this.longitude,
    this.raioMetros = raioPadraoMetros,
  });

  /// Área que conta como "no evento" quando o evento não diz a sua.
  static const raioPadraoMetros = 500.0;

  factory Evento.fromJson(Map<String, Object?> json) => Evento(
        id: json['id']! as String,
        nome: json['nome']! as String,
        cidade: (json['cidade'] as String?) ?? '',
        whatsappCentral: json['whatsappCentral']! as String,
        local: (json['local'] as String?) ?? '',
        endereco: (json['endereco'] as String?) ?? '',
        parceiro: (json['parceiro'] as String?) ?? '',
        inicio: DateTime.tryParse((json['inicio'] as String?) ?? ''),
        fim: DateTime.tryParse((json['fim'] as String?) ?? ''),
        administradores: [
          for (final a
              in (json['administradores'] as List<dynamic>?) ?? const [])
            Administrador.fromJson(
                (a as Map<dynamic, dynamic>).cast<String, Object?>()),
        ],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        raioMetros:
            (json['raioMetros'] as num?)?.toDouble() ?? raioPadraoMetros,
      );

  final String id;
  final String nome;
  final String cidade;

  /// Número do evento que recebe os pedidos de ajuda.
  final String whatsappCentral;
  final String local;
  final String endereco;
  final String parceiro;
  final DateTime? inicio;
  final DateTime? fim;
  final List<Administrador> administradores;

  /// Centro do local do evento no mapa. Sem ele, não dá para saber se a
  /// pessoa está no evento.
  final double? latitude;
  final double? longitude;

  /// Distância do centro até onde o evento ainda vai (um shopping é pequeno,
  /// uma corrida na Beira-Mar é comprida).
  final double raioMetros;

  bool terminouEm(DateTime agora) => fim != null && agora.isAfter(fim!);

  /// Metros até o local do evento, só quando a pessoa com certeza está fora
  /// dele: nem descontando a margem de erro do GPS ela cai dentro da área.
  /// null quando está dentro, quando não dá para afirmar ou quando o evento
  /// não tem coordenadas.
  double? distanciaSeEstiverFora(Posicao posicao) {
    final lat = latitude, lng = longitude;
    if (lat == null || lng == null) return null;
    final distancia =
        distanciaEmMetros(lat, lng, posicao.latitude, posicao.longitude);
    return distancia - posicao.precisaoMetros > raioMetros ? distancia : null;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'nome': nome,
        'cidade': cidade,
        'whatsappCentral': whatsappCentral,
        'local': local,
        'endereco': endereco,
        'parceiro': parceiro,
        'inicio': inicio?.toIso8601String(),
        'fim': fim?.toIso8601String(),
        'administradores': [for (final a in administradores) a.toJson()],
        'latitude': latitude,
        'longitude': longitude,
        'raioMetros': raioMetros,
      };
}
