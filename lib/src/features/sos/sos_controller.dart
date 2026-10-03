import 'package:flutter/foundation.dart';

import '../../servicos/localizacao.dart';
import '../../servicos/mensageiro.dart';
import '../contatos/contato.dart';
import '../contatos/contatos_controller.dart';
import '../eventos/eventos_controller.dart';
import 'mensagem_sos.dart';

enum FaseSos { pronto, localizando, abrindo, pronta, semDestino, falhou }

/// Quem recebe o pedido de ajuda.
class Destino {
  const Destino(this.nome, this.telefone);
  final String nome;
  final String telefone;
}

class SosController extends ChangeNotifier {
  SosController({
    required ServicoLocalizacao localizacao,
    required Mensageiro mensageiro,
    required ContatosController contatos,
    required EventosController eventos,
    DateTime Function()? relogio,
  })  : _localizacao = localizacao,
        _mensageiro = mensageiro,
        _contatos = contatos,
        _eventos = eventos,
        _relogio = relogio ?? DateTime.now;

  final ServicoLocalizacao _localizacao;
  final Mensageiro _mensageiro;
  final ContatosController _contatos;
  final EventosController _eventos;
  final DateTime Function() _relogio;

  var _fase = FaseSos.pronto;
  var _status = '';
  String? _ultimaMensagem;
  Destino? _ultimoDestino;

  FaseSos get fase => _fase;
  bool get ocupado => _fase == FaseSos.localizando || _fase == FaseSos.abrindo;

  /// Frase para a região viva: o leitor de tela fala cada mudança.
  String get status => _status;

  /// Durante um evento, a central do evento. Fora dele, o contato principal.
  Destino? get destino {
    final evento = _eventos.participando;
    if (evento != null) {
      return Destino(
          'a central do evento ${evento.nome}', evento.whatsappCentral);
    }
    final principal = _contatos.principal;
    return principal == null
        ? null
        : Destino(principal.nome, principal.telefone);
  }

  /// Contatos que ainda podem receber a mesma mensagem.
  List<Contato> get outrosContatos => _ultimaMensagem == null
      ? const []
      : [
          for (final c in _contatos.contatos)
            if (c.telefone != _ultimoDestino?.telefone) c
        ];

  /// A funcionalidade principal: um toque.
  Future<void> pedirAjuda() async {
    if (ocupado) return;
    final alvo = destino;
    if (alvo == null) {
      _mudar(FaseSos.semDestino,
          'Ninguém para avisar ainda. Cadastre um contato ou participe de um evento. Em perigo, ligue 192 ou 193.');
      return;
    }

    _mudar(FaseSos.localizando, 'Pegando sua localização…');
    final localizacao = await _localizacao.posicaoAtual();

    final perfil = _contatos.perfil;
    final evento = _eventos.participando;
    final texto = montarMensagemSos(
      agora: _relogio(),
      localizacao: localizacao,
      nome: perfil.nome,
      informacaoImportante: perfil.informacaoImportante,
      evento: evento,
    );
    _ultimaMensagem = texto;
    _ultimoDestino = alvo;

    _mudar(FaseSos.abrindo, 'Abrindo o WhatsApp…');
    final posicao = localizacao.posicao;
    final semLocal = posicao == null
        ? ' Atenção: a mensagem vai sem localização.'
        : evento?.distanciaSeEstiverFora(posicao) != null
            ? ' A mensagem avisa que você não está no local do evento.'
            : '';
    if (await _mensageiro.abrirWhatsApp(alvo.telefone, texto)) {
      _mudar(FaseSos.pronta,
          'Mensagem pronta no WhatsApp para ${alvo.nome}. Toque em Enviar.$semLocal');
    } else if (await _mensageiro.abrirSms(alvo.telefone, texto)) {
      _mudar(FaseSos.pronta,
          'WhatsApp indisponível. Mensagem pronta no SMS para ${alvo.nome}. Toque em Enviar.$semLocal');
    } else {
      _mudar(FaseSos.falhou,
          'Não foi possível abrir o WhatsApp nem o SMS. Ligue 192 (SAMU) ou 193 (Bombeiros).');
    }
  }

  Future<void> enviarTambemPara(Contato contato) async {
    final texto = _ultimaMensagem;
    if (texto == null) return;
    final ok = await _mensageiro.abrirWhatsApp(contato.telefone, texto);
    _mudar(
        _fase,
        ok
            ? 'Mensagem pronta no WhatsApp para ${contato.nome}.'
            : 'Não foi possível abrir o WhatsApp.');
  }

  Future<void> ligar(String numero) => _mensageiro.ligar(numero);

  void _mudar(FaseSos fase, String status) {
    _fase = fase;
    _status = status;
    notifyListeners();
  }
}
