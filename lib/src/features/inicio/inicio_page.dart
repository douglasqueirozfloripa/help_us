import 'package:flutter/material.dart';

import '../../app/dependencias.dart';
import '../../core/theme/tema.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/logo_helpus.dart';
import '../avaliacao/avaliacao_page.dart';
import '../contatos/contato.dart';
import '../contatos/contatos_page.dart';
import '../contatos/leitor_qr.dart';
import '../contatos/novo_contato_page.dart';
import '../contatos/qr_page.dart';
import '../eventos/evento.dart';
import '../eventos/eventos_page.dart';
import '../sos/ajuda_page.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  var _aba = 0;

  /// O Tab não para no título; o foco só vem para ele em [_irPara].
  final _focoDoTitulo =
      FocusNode(debugLabel: 'Título da tela', skipTraversal: true);

  Dependencias get _d => widget.dependencias;

  @override
  void dispose() {
    _focoDoTitulo.dispose();
    super.dispose();
  }

  /// Troca de aba e leva o foco para o título da tela nova. Assim o leitor de
  /// tela anuncia a tela ("Eventos, cabeçalho") e o próximo Tab entra no
  /// conteúdo dela, em vez de ir para a aba ao lado (WCAG 2.4.3).
  void _irPara(int aba) {
    setState(() => _aba = aba);
    _focoDoTitulo.requestFocus();
  }

  void _avisar(String texto) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _lerQr() async {
    final resultado = await Navigator.of(context).push<ResultadoQr>(
      MaterialPageRoute(builder: (_) => QrPage(camera: _d.camera)),
    );
    if (!mounted || resultado == null) return;
    switch (resultado) {
      case QrEvento(:final id, :final nome, :final whatsapp, :final cidade):
        final evento = _d.eventos.porId(id) ??
            Evento(
                id: id, nome: nome, cidade: cidade, whatsappCentral: whatsapp);
        await _d.eventos.participar(evento);
        if (!mounted) return;
        _irPara(0);
        _avisar(
            'Você entrou no evento ${evento.nome}. Seus pedidos de ajuda vão para a organização.');
      case QrContato(:final telefone):
        await _adicionarContato(
            telefoneInicial: telefone, origem: OrigemContato.qrCode);
      case QrInvalido():
        break;
    }
  }

  Future<void> _adicionarContato(
      {String telefoneInicial = '',
      OrigemContato origem = OrigemContato.digitado}) async {
    final novo = await Navigator.of(context).push<NovoContato>(
      MaterialPageRoute(
          builder: (_) => NovoContatoPage(telefoneInicial: telefoneInicial)),
    );
    if (novo == null) return;
    final entrou = await _d.contatos
        .adicionar(nome: novo.nome, telefone: novo.telefone, origem: origem);
    if (!mounted) return;
    _avisar(entrou
        ? '${novo.nome} foi adicionado aos seus contatos.'
        : 'Esse número já está nos seus contatos.');
  }

  Future<void> _avaliar() async {
    final evento = _d.eventos.participando;
    if (evento == null) return;
    final aviso = await Navigator.of(context).push(MaterialPageRoute<String>(
      builder: (_) => AvaliacaoPage(
        evento: evento,
        relogio: _d.relogio,
        enviar: (avaliacao) => _d.enviarAvaliacao(avaliacao, evento),
      ),
    ));
    // Voltar pela seta não envia nada: fica onde estava.
    if (!mounted || aviso == null) return;
    _irPara(1);
    _avisar(aviso);
  }

  Future<void> _falarCom(Administrador adm) => _d.mensageiro.abrirWhatsApp(
        adm.whatsapp,
        'Olá, ${adm.nome}! Estou no evento e uso o ${NomeDoApp.valor}.',
      );

  @override
  Widget build(BuildContext context) {
    final (titulo, corpo) = switch (_aba) {
      1 => (
          'Eventos',
          EventosPage(eventos: _d.eventos, aoLerQr: _lerQr, falarCom: _falarCom)
        ),
      2 => (
          'Contatos',
          ContatosPage(
            contatos: _d.contatos,
            aoAdicionarPorQr: _lerQr,
            aoAdicionarDigitando: _adicionarContato,
          ),
        ),
      _ => (
          NomeDoApp.valor,
          AjudaPage(
            sos: _d.sos,
            eventos: _d.eventos,
            irParaEventos: () => _irPara(1),
            aoAvaliar: _avaliar,
          ),
        ),
    };

    return Scaffold(
      appBar: barraHelpUS(
        titulo,
        leading: const Padding(padding: EdgeInsets.all(8), child: LogoHelpUS()),
        focoDoTitulo: _focoDoTitulo,
      ),
      // Grupo próprio: o Tab percorre a tela inteira antes de ir para as abas.
      // Sem ele, a ordem segue a posição na tela, e os itens da lista logo
      // abaixo da parte visível vêm "depois" da barra de abas.
      body: FocusTraversalGroup(child: SafeArea(child: corpo)),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Cores.pergaminhoClaro,
        selectedIndex: _aba,
        onDestinationSelected: _irPara,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sos), label: 'Ajuda'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Eventos'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Contatos'),
        ],
      ),
    );
  }
}
