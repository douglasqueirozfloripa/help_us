import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/app.dart';
import 'package:helpus/src/app/dependencias.dart';
import 'package:helpus/src/data/armazenamento.dart';
import 'package:helpus/src/data/fonte_de_eventos.dart';
import 'package:helpus/src/features/eventos/evento.dart';
import 'package:helpus/src/servicos/localizacao.dart';
import 'package:helpus/src/servicos/mensageiro.dart';

final agora = DateTime(2026, 10, 17, 14, 30);

final posicaoNoShopping = Posicao(
  latitude: -27.585531,
  longitude: -48.614722,
  precisaoMetros: 12,
  obtidaEm: DateTime(2026, 10, 17, 14, 29),
);

/// Na Beira-Mar Norte, a uns 7 km do Continente Shopping.
final posicaoLongeDaFeira = Posicao(
  latitude: -27.5845,
  longitude: -48.545,
  precisaoMetros: 12,
  obtidaEm: DateTime(2026, 10, 17, 14, 29),
);

class GpsFalso implements ServicoLocalizacao {
  GpsFalso([ResultadoLocalizacao? resultado])
      : resultado =
            resultado ?? ResultadoLocalizacao(posicao: posicaoNoShopping);
  ResultadoLocalizacao resultado;
  var chamadas = 0;

  @override
  Future<ResultadoLocalizacao> posicaoAtual() async {
    chamadas++;
    return resultado;
  }
}

class Aberto {
  const Aberto(this.canal, this.destino, this.texto);
  final String canal;
  final String destino;
  final String texto;
}

class MensageiroFalso implements Mensageiro {
  MensageiroFalso({this.whatsAppFunciona = true, this.smsFunciona = true});
  bool whatsAppFunciona;
  bool smsFunciona;
  final abertos = <Aberto>[];

  @override
  Future<bool> abrirWhatsApp(String telefone, String texto) async {
    if (whatsAppFunciona) abertos.add(Aberto('whatsapp', telefone, texto));
    return whatsAppFunciona;
  }

  @override
  Future<bool> abrirSms(String telefone, String texto) async {
    if (smsFunciona) abertos.add(Aberto('sms', telefone, texto));
    return smsFunciona;
  }

  @override
  Future<bool> ligar(String numero) async {
    abertos.add(Aberto('ligacao', numero, ''));
    return true;
  }
}

const feira = Evento(
  id: 'feira',
  nome: 'Feira Inclusiva',
  cidade: 'São José',
  local: 'Continente Shopping',
  parceiro: 'Continente Shopping',
  whatsappCentral: '5548999990001',
  latitude: -27.585531,
  longitude: -48.614722,
  raioMetros: 400,
  administradores: [
    Administrador(
        nome: 'Cleiton', funcao: 'organização', whatsapp: '5548999990002')
  ],
);

const corrida = Evento(
  id: 'corrida',
  nome: 'Corrida Garapuvu',
  cidade: 'Florianópolis',
  whatsappCentral: '5548999990010',
);

class Cenario {
  Cenario({
    List<Evento> eventos = const [feira, corrida],
    Map<String, String>? salvo,
    GpsFalso? gps,
    MensageiroFalso? mensageiro,
    this.qrLido,
  })  : gps = gps ?? GpsFalso(),
        mensageiro = mensageiro ?? MensageiroFalso(),
        armazenamento = ArmazenamentoEmMemoria(salvo) {
    dependencias = Dependencias(
      armazenamento: armazenamento,
      fonteDeEventos: EventosEmMemoria(eventos),
      localizacao: this.gps,
      mensageiro: this.mensageiro,
      relogio: () => agora,
      camera: (aoLer) => Center(
        child: TextButton(
            onPressed: () => aoLer(qrLido ?? ''),
            child: const Text('Simular leitura')),
      ),
    );
  }

  final GpsFalso gps;
  final MensageiroFalso mensageiro;
  final ArmazenamentoEmMemoria armazenamento;
  late final Dependencias dependencias;

  /// Conteúdo que a "câmera" vai ler quando tocar em "Simular leitura".
  String? qrLido;

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(HelpUSApp(dependencias: dependencias));
    await tester.pumpAndSettle();
  }
}

const contatoSalvo =
    '[{"id":"1","nome":"Maria","telefone":"5548988887777","origem":"digitado"},'
    '{"id":"2","nome":"João","telefone":"5548977776666","origem":"qrCode"}]';

void usarCelular(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Future<int> tabAte(WidgetTester tester, bool Function(BuildContext foco) alvo,
    {int maximo = 40}) async {
  for (var i = 1; i <= maximo; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final contexto = FocusManager.instance.primaryFocus?.context;
    if (contexto != null && alvo(contexto)) return i;
  }
  return -1;
}

/// Rola a lista até [alvo] existir e aparecer. Só `ensureVisible` não basta:
/// o ListView constrói apenas o que está perto da tela.
Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(alvo, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}
