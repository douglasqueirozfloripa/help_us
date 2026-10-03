import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../data/armazenamento.dart';
import '../data/fonte_de_eventos.dart';
import '../features/avaliacao/avaliacao.dart';
import '../features/contatos/contatos_controller.dart';
import '../features/eventos/evento.dart';
import '../features/eventos/eventos_controller.dart';
import '../features/sos/sos_controller.dart';
import '../servicos/localizacao.dart';
import '../servicos/mensageiro.dart';

/// Monta tudo num lugar só. Nos testes, entram versões falsas do GPS,
/// do WhatsApp e da câmera.
class Dependencias {
  Dependencias({
    required this.armazenamento,
    required FonteDeEventos fonteDeEventos,
    required ServicoLocalizacao localizacao,
    required this.mensageiro,
    this.camera,
    DateTime Function()? relogio,
  }) : relogio = relogio ?? DateTime.now {
    contatos =
        ContatosController(armazenamento: armazenamento, relogio: this.relogio);
    eventos =
        EventosController(fonte: fonteDeEventos, armazenamento: armazenamento);
    sos = SosController(
      localizacao: localizacao,
      mensageiro: mensageiro,
      contatos: contatos,
      eventos: eventos,
      relogio: this.relogio,
    );
  }

  static const chaveAvaliacoes = 'helpus.avaliacoes.v1';

  final Armazenamento armazenamento;
  final Mensageiro mensageiro;
  final Widget Function(ValueChanged<String> aoLer)? camera;
  final DateTime Function() relogio;
  late final ContatosController contatos;
  late final EventosController eventos;
  late final SosController sos;

  Future<void>? _carregamento;

  /// Pode ser chamado mais de uma vez: carrega só na primeira.
  Future<void> carregar() =>
      _carregamento ??= Future.wait([contatos.carregar(), eventos.carregar()]);

  /// Guarda a avaliação no aparelho e abre o WhatsApp de quem organiza.
  Future<bool> enviarAvaliacao(Avaliacao avaliacao, Evento evento) async {
    final salvas = await armazenamento.ler(chaveAvaliacoes);
    final lista =
        salvas == null ? <dynamic>[] : jsonDecode(salvas) as List<dynamic>;
    await armazenamento.gravar(
        chaveAvaliacoes, jsonEncode([...lista, avaliacao.toJson()]));
    final telefone =
        evento.administradores.firstOrNull?.whatsapp ?? evento.whatsappCentral;
    return mensageiro.abrirWhatsApp(telefone, avaliacao.textoParaOrganizacao());
  }
}
