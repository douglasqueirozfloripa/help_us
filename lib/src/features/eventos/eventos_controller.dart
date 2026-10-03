import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/armazenamento.dart';
import '../../data/fonte_de_eventos.dart';
import 'evento.dart';

class EventosController extends ChangeNotifier {
  EventosController(
      {required FonteDeEventos fonte, required Armazenamento armazenamento})
      : _fonte = fonte,
        _armazenamento = armazenamento;

  static const chaveParticipacao = 'helpus.participacao.v1';

  final FonteDeEventos _fonte;
  final Armazenamento _armazenamento;
  List<Evento> _eventos = const [];
  Evento? _participando;
  String? _cidade;
  var _carregando = true;
  var _falhouAoCarregar = false;

  bool get carregando => _carregando;
  bool get falhouAoCarregar => _falhouAoCarregar;
  Evento? get participando => _participando;
  String? get cidadeSelecionada => _cidade;

  List<String> get cidades =>
      ({for (final e in _eventos) e.cidade}.toList()..sort());

  List<Evento> get eventosDaCidade => [
        for (final e in _eventos)
          if (_cidade == null || e.cidade == _cidade) e
      ];

  Future<void> carregar() async {
    try {
      _eventos = await _fonte.carregar();
    } on Exception {
      _falhouAoCarregar = true;
    }
    final salvo = await _armazenamento.ler(chaveParticipacao);
    if (salvo != null && salvo.isNotEmpty) {
      final guardado = Evento.fromJson(
          (jsonDecode(salvo) as Map<dynamic, dynamic>).cast<String, Object?>());
      // A lista é mais nova que a cópia guardada (ex.: ganhou coordenadas).
      _participando = porId(guardado.id) ?? guardado;
    }
    _carregando = false;
    notifyListeners();
  }

  void escolherCidade(String? cidade) {
    _cidade = cidade;
    notifyListeners();
  }

  Future<void> participar(Evento evento) async {
    _participando = evento;
    notifyListeners();
    await _armazenamento.gravar(chaveParticipacao, jsonEncode(evento.toJson()));
  }

  Future<void> sair() async {
    _participando = null;
    notifyListeners();
    await _armazenamento.gravar(chaveParticipacao, '');
  }

  Evento? porId(String id) => _eventos.where((e) => e.id == id).firstOrNull;
}
