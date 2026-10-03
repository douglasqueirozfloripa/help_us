import 'dart:convert';

import 'package:flutter/services.dart';

import '../features/eventos/evento.dart';

/// De onde vem a lista de eventos. Hoje: um arquivo dentro do app.
/// Quando houver servidor (Firebase, API), basta outra implementação.
abstract interface class FonteDeEventos {
  Future<List<Evento>> carregar();
}

class EventosDoArquivo implements FonteDeEventos {
  const EventosDoArquivo([this.caminho = 'assets/dados/eventos.json']);

  final String caminho;

  @override
  Future<List<Evento>> carregar() async {
    final lista =
        jsonDecode(await rootBundle.loadString(caminho)) as List<dynamic>;
    return [
      for (final e in lista)
        Evento.fromJson((e as Map<dynamic, dynamic>).cast<String, Object?>())
    ];
  }
}

class EventosEmMemoria implements FonteDeEventos {
  const EventosEmMemoria(this.eventos);
  final List<Evento> eventos;

  @override
  Future<List<Evento>> carregar() async => eventos;
}
