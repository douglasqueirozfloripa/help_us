import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/armazenamento.dart';
import 'contato.dart';

class ContatosController extends ChangeNotifier {
  ContatosController(
      {required Armazenamento armazenamento, DateTime Function()? relogio})
      : _armazenamento = armazenamento,
        _relogio = relogio ?? DateTime.now;

  static const chaveContatos = 'helpus.contatos.v1';
  static const chavePerfil = 'helpus.perfil.v1';

  final Armazenamento _armazenamento;
  final DateTime Function() _relogio;
  final List<Contato> _contatos = [];
  var _perfil = const Perfil();
  var _contador = 0;

  /// O primeiro da lista é o principal: recebe o pedido de ajuda quando a
  /// pessoa não está em nenhum evento.
  List<Contato> get contatos => List.unmodifiable(_contatos);
  Contato? get principal => _contatos.firstOrNull;
  Perfil get perfil => _perfil;

  Future<void> carregar() async {
    final contatos = await _armazenamento.ler(chaveContatos);
    if (contatos != null) {
      _contatos
        ..clear()
        ..addAll([
          for (final c in jsonDecode(contatos) as List<dynamic>)
            Contato.fromJson(
                (c as Map<dynamic, dynamic>).cast<String, Object?>()),
        ]);
    }
    final perfil = await _armazenamento.ler(chavePerfil);
    if (perfil != null) {
      _perfil = Perfil.fromJson((jsonDecode(perfil) as Map<dynamic, dynamic>)
          .cast<String, Object?>());
    }
    notifyListeners();
  }

  /// Devolve false se o número já estava na lista.
  Future<bool> adicionar(
      {required String nome,
      required String telefone,
      OrigemContato origem = OrigemContato.digitado}) async {
    if (_contatos.any((c) => c.telefone == telefone)) return false;
    _contatos.add(Contato(
      id: '${_relogio().microsecondsSinceEpoch}-${_contador++}',
      nome: nome.trim(),
      telefone: telefone,
      origem: origem,
    ));
    notifyListeners();
    await _salvar();
    return true;
  }

  Future<void> remover(String id) async {
    _contatos.removeWhere((c) => c.id == id);
    notifyListeners();
    await _salvar();
  }

  Future<void> tornarPrincipal(String id) async {
    final i = _contatos.indexWhere((c) => c.id == id);
    if (i <= 0) return;
    _contatos.insert(0, _contatos.removeAt(i));
    notifyListeners();
    await _salvar();
  }

  Future<void> salvarPerfil(Perfil perfil) async {
    _perfil = perfil;
    notifyListeners();
    await _armazenamento.gravar(chavePerfil, jsonEncode(perfil.toJson()));
  }

  Future<void> _salvar() => _armazenamento.gravar(
      chaveContatos, jsonEncode([for (final c in _contatos) c.toJson()]));
}
