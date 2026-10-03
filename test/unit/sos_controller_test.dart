import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/src/features/sos/sos_controller.dart';
import 'package:helpus/src/servicos/localizacao.dart';

import '../ajudantes.dart';

void main() {
  Future<Cenario> preparar(
      {Map<String, String>? salvo,
      MensageiroFalso? mensageiro,
      GpsFalso? gps}) async {
    final c = Cenario(salvo: salvo, mensageiro: mensageiro, gps: gps);
    await c.dependencias.carregar();
    return c;
  }

  test('sem contato e sem evento, explica o que fazer e não abre nada',
      () async {
    final c = await preparar();
    await c.dependencias.sos.pedirAjuda();
    expect(c.dependencias.sos.fase, FaseSos.semDestino);
    expect(c.dependencias.sos.status, contains('Cadastre um contato'));
    expect(c.mensageiro.abertos, isEmpty);
    expect(c.gps.chamadas, 0);
  });

  test(
      'fora de evento, um toque abre o WhatsApp do contato principal com a localização',
      () async {
    final c = await preparar(salvo: {'helpus.contatos.v1': contatoSalvo});
    await c.dependencias.sos.pedirAjuda();

    final aberto = c.mensageiro.abertos.single;
    expect(aberto.canal, 'whatsapp');
    expect(aberto.destino, '5548988887777');
    expect(aberto.texto, contains('google.com/maps?q=-27.585531,-48.614722'));
    expect(c.dependencias.sos.fase, FaseSos.pronta);
    expect(c.dependencias.sos.status,
        'Mensagem pronta no WhatsApp para Maria. Toque em Enviar.');
  });

  test('durante o evento, vai para a central do evento', () async {
    final c = await preparar(salvo: {'helpus.contatos.v1': contatoSalvo});
    await c.dependencias.eventos.participar(feira);
    await c.dependencias.sos.pedirAjuda();

    expect(c.mensageiro.abertos.single.destino, feira.whatsappCentral);
    expect(
        c.mensageiro.abertos.single.texto, contains('Evento: Feira Inclusiva'));
  });

  test('inscrita no evento mas longe dele, a mensagem e a tela avisam',
      () async {
    final c = await preparar(
      salvo: {'helpus.contatos.v1': contatoSalvo},
      gps: GpsFalso(ResultadoLocalizacao(posicao: posicaoLongeDaFeira)),
    );
    await c.dependencias.eventos.participar(feira);
    await c.dependencias.sos.pedirAjuda();

    expect(c.mensageiro.abertos.single.destino, feira.whatsappCentral);
    expect(c.mensageiro.abertos.single.texto,
        contains('*ATENÇÃO: A PESSOA NÃO ESTÁ NO LOCAL DO EVENTO.*'));
    expect(c.dependencias.sos.status,
        endsWith('A mensagem avisa que você não está no local do evento.'));
  });

  test('no local do evento, o aviso de fora não aparece', () async {
    final c = await preparar(salvo: {'helpus.contatos.v1': contatoSalvo});
    await c.dependencias.eventos.participar(feira);
    await c.dependencias.sos.pedirAjuda();

    expect(c.mensageiro.abertos.single.texto, isNot(contains('NÃO ESTÁ')));
    expect(c.dependencias.sos.status, endsWith('Toque em Enviar.'));
  });

  test('participação guardada antes das coordenadas pega as da lista',
      () async {
    final c = await preparar(salvo: {
      'helpus.participacao.v1':
          '{"id":"feira","nome":"Feira Inclusiva","whatsappCentral":"5548999990001"}'
    });
    expect(c.dependencias.eventos.participando?.latitude, feira.latitude);
  });

  test('depois do pedido, oferece mandar para os outros contatos', () async {
    final c = await preparar(salvo: {'helpus.contatos.v1': contatoSalvo});
    final sos = c.dependencias.sos;
    await sos.pedirAjuda();
    expect(sos.outrosContatos.map((x) => x.nome), ['João']);

    await sos.enviarTambemPara(sos.outrosContatos.single);
    expect(c.mensageiro.abertos.last.destino, '5548977776666');
    expect(c.mensageiro.abertos.last.texto, c.mensageiro.abertos.first.texto);
  });

  test('sem WhatsApp, cai para o SMS', () async {
    final c = await preparar(
      salvo: {'helpus.contatos.v1': contatoSalvo},
      mensageiro: MensageiroFalso(whatsAppFunciona: false),
    );
    await c.dependencias.sos.pedirAjuda();
    expect(c.mensageiro.abertos.single.canal, 'sms');
    expect(c.dependencias.sos.status, startsWith('WhatsApp indisponível.'));
  });

  test('sem WhatsApp nem SMS, manda ligar para 192 ou 193', () async {
    final c = await preparar(
      salvo: {'helpus.contatos.v1': contatoSalvo},
      mensageiro: MensageiroFalso(whatsAppFunciona: false, smsFunciona: false),
    );
    await c.dependencias.sos.pedirAjuda();
    expect(c.dependencias.sos.fase, FaseSos.falhou);
    expect(c.dependencias.sos.status, contains('192'));
  });

  test('sem GPS, o pedido sai assim mesmo e o aviso diz isso', () async {
    final c = await preparar(
      salvo: {'helpus.contatos.v1': contatoSalvo},
      gps: GpsFalso(const ResultadoLocalizacao(
          problema: ProblemaLocalizacao.semPermissao)),
    );
    await c.dependencias.sos.pedirAjuda();
    expect(c.mensageiro.abertos, hasLength(1));
    expect(c.dependencias.sos.status, contains('vai sem localização'));
  });

  test('dois toques seguidos não abrem duas mensagens', () async {
    final c = await preparar(salvo: {'helpus.contatos.v1': contatoSalvo});
    await Future.wait(
        [c.dependencias.sos.pedirAjuda(), c.dependencias.sos.pedirAjuda()]);
    expect(c.mensageiro.abertos, hasLength(1));
  });

  test('participação no evento fica guardada no aparelho', () async {
    final c = await preparar();
    await c.dependencias.eventos.participar(feira);

    final outro = Cenario(salvo: c.armazenamento.dados);
    await outro.dependencias.carregar();
    expect(outro.dependencias.eventos.participando?.nome, 'Feira Inclusiva');
  });

  test('contatos: número repetido não entra duas vezes e principal pode mudar',
      () async {
    final c = await preparar(salvo: {'helpus.contatos.v1': contatoSalvo});
    final contatos = c.dependencias.contatos;
    expect(
        await contatos.adicionar(
            nome: 'Maria de novo', telefone: '5548988887777'),
        isFalse);
    await contatos.tornarPrincipal('2');
    expect(contatos.principal?.nome, 'João');
  });

  test('eventos filtram por cidade', () async {
    final c = await preparar();
    final eventos = c.dependencias.eventos;
    expect(eventos.cidades, ['Florianópolis', 'São José']);
    eventos.escolherCidade('São José');
    expect(eventos.eventosDaCidade.single.nome, 'Feira Inclusiva');
  });
}
