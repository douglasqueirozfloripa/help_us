import 'package:shared_preferences/shared_preferences.dart';

/// Tudo fica no aparelho. Cada controller guarda seu JSON numa chave.
abstract interface class Armazenamento {
  Future<String?> ler(String chave);
  Future<void> gravar(String chave, String valor);
}

class ArmazenamentoLocal implements Armazenamento {
  @override
  Future<String?> ler(String chave) async =>
      (await SharedPreferences.getInstance()).getString(chave);

  @override
  Future<void> gravar(String chave, String valor) async {
    await (await SharedPreferences.getInstance()).setString(chave, valor);
  }
}

class ArmazenamentoEmMemoria implements Armazenamento {
  ArmazenamentoEmMemoria([Map<String, String>? inicial])
      : dados = {...?inicial};

  final Map<String, String> dados;

  @override
  Future<String?> ler(String chave) async => dados[chave];

  @override
  Future<void> gravar(String chave, String valor) async => dados[chave] = valor;
}
