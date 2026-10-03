import 'package:flutter_test/flutter_test.dart';
import 'package:helpus/src/features/avaliacao/avaliacao.dart';

import '../ajudantes.dart';

void main() {
  final avaliacao = Avaliacao(
    idEvento: 'feira',
    nomeEvento: 'Feira Inclusiva',
    parceiro: 'Continente Shopping',
    respostas: {
      for (final item in ItemAcessibilidade.values) item: Resposta.sim
    }
      ..[ItemAcessibilidade.cardapioBraille] = Resposta.nao
      ..[ItemAcessibilidade.interpreteLibras] = Resposta.naoSei,
    notaAcesso: 4,
    notaEvento: 5,
    notaParceiro: 3,
    comentario: 'Faltou sinalização tátil.',
    feitaEm: agora,
  );

  test('pergunta as seis coisas combinadas com o Cleiton', () {
    expect(ItemAcessibilidade.values.map((i) => i.nomeCurto), [
      'Rampa ou acesso sem degraus',
      'Cardápio em braille',
      'Banheiro adaptado',
      'Espaço sensorial (TEA)',
      'Vagas para cadeirantes e PCD',
      'Intérprete de Libras',
    ]);
  });

  test('texto para a organização é legível no WhatsApp', () {
    final texto = avaliacao.textoParaOrganizacao();
    expect(texto, contains('• Cardápio em braille: Não'));
    expect(texto, contains('• Intérprete de Libras: Não sei'));
    expect(texto, contains('Nota do parceiro (Continente Shopping): 3 de 5'));
    expect(texto, contains('Comentário: Faltou sinalização tátil.'));
  });

  test('JSON guarda as respostas pelo nome', () {
    final json = avaliacao.toJson();
    expect((json['respostas']! as Map)['rampa'], 'sim');
    expect(json['notaEvento'], 5);
  });
}
