import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class Posicao {
  const Posicao({
    required this.latitude,
    required this.longitude,
    required this.precisaoMetros,
    required this.obtidaEm,
    this.aproximada = false,
  });

  final double latitude;
  final double longitude;
  final double precisaoMetros;
  final DateTime obtidaEm;

  /// true quando o GPS não respondeu e usamos a última posição conhecida.
  final bool aproximada;

  /// Link que abre no Google Maps (app ou navegador). É texto puro dentro da
  /// mensagem: continua valendo mesmo com o HelpUS fechado ou o celular sem bateria.
  String get linkGoogleMaps =>
      'https://www.google.com/maps?q=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
}

enum ProblemaLocalizacao {
  gpsDesligado('O GPS do celular está desligado.'),
  semPermissao('O HelpUS não tem permissão para ver sua localização.'),
  semSinal('O GPS não respondeu a tempo.');

  const ProblemaLocalizacao(this.explicacao);
  final String explicacao;
}

class ResultadoLocalizacao {
  const ResultadoLocalizacao({this.posicao, this.problema});
  final Posicao? posicao;
  final ProblemaLocalizacao? problema;
}

abstract interface class ServicoLocalizacao {
  Future<ResultadoLocalizacao> posicaoAtual();
}

class LocalizacaoPorGps implements ServicoLocalizacao {
  LocalizacaoPorGps({this.limite = const Duration(seconds: 10)});

  /// Num pedido de ajuda não dá para esperar o GPS para sempre.
  final Duration limite;

  @override
  Future<ResultadoLocalizacao> posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return _ultimaConhecida(ProblemaLocalizacao.gpsDesligado);
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      return const ResultadoLocalizacao(
          problema: ProblemaLocalizacao.semPermissao);
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: limite),
      );
      return ResultadoLocalizacao(posicao: _converter(p, aproximada: false));
    } on Exception {
      return _ultimaConhecida(ProblemaLocalizacao.semSinal);
    }
  }

  Future<ResultadoLocalizacao> _ultimaConhecida(
      ProblemaLocalizacao problema) async {
    if (kIsWeb) return ResultadoLocalizacao(problema: problema);
    try {
      final p = await Geolocator.getLastKnownPosition();
      if (p != null) {
        return ResultadoLocalizacao(
            posicao: _converter(p, aproximada: true), problema: problema);
      }
    } on Exception {
      // segue sem posição
    }
    return ResultadoLocalizacao(problema: problema);
  }

  Posicao _converter(Position p, {required bool aproximada}) => Posicao(
        latitude: p.latitude,
        longitude: p.longitude,
        precisaoMetros: p.accuracy,
        obtidaEm: p.timestamp,
        aproximada: aproximada,
      );
}
