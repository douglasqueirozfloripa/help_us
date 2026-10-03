import '../../core/theme/tokens.dart';
import '../../core/utils/datas.dart';
import '../../core/utils/distancia.dart';
import '../../servicos/localizacao.dart';
import '../eventos/evento.dart';

/// Texto do pedido de ajuda. Tudo que importa vai escrito na própria
/// mensagem, inclusive o link do mapa: quem recebe não precisa do HelpUS,
/// e a informação continua lá mesmo se o celular de quem pediu desligar.
String montarMensagemSos({
  required DateTime agora,
  ResultadoLocalizacao? localizacao,
  String nome = '',
  String informacaoImportante = '',
  Evento? evento,
}) {
  final posicao = localizacao?.posicao;
  final foraDoEvento =
      posicao == null ? null : evento?.distanciaSeEstiverFora(posicao);
  final linhas = <String>[
    '🆘 PEDIDO DE AJUDA (${NomeDoApp.valor})',
    // Logo no começo e em negrito (*...* no WhatsApp): quem está na central
    // não pode sair procurando a pessoa dentro do evento.
    if (evento != null && foraDoEvento != null) ...[
      '⚠️ *ATENÇÃO: A PESSOA NÃO ESTÁ NO LOCAL DO EVENTO.*',
      '*Está em outro lugar, a cerca de ${distanciaLegivel(foraDoEvento)} '
          'do local do evento${evento.local.trim().isEmpty ? '' : ' (${evento.local.trim()})'}. '
          'Vá pelo link de localização abaixo, não pelo endereço do evento.*',
    ],
    if (nome.trim().isNotEmpty) 'Quem pede: ${nome.trim()}',
    if (informacaoImportante.trim().isNotEmpty)
      'Importante: ${informacaoImportante.trim()}',
    if (evento != null && evento.nome.trim().isNotEmpty)
      'Evento: ${evento.nome.trim()}',
    if (posicao != null) ...[
      'Localização: ${posicao.linkGoogleMaps}',
      'Coordenadas: ${posicao.latitude.toStringAsFixed(6)}, ${posicao.longitude.toStringAsFixed(6)}',
      posicao.aproximada
          ? 'Precisão: aproximada (última posição conhecida, às ${hora(posicao.obtidaEm)})'
          : 'Precisão: cerca de ${posicao.precisaoMetros.round()} m',
    ] else
      'Localização: não foi possível obter o GPS. ${localizacao?.problema?.explicacao ?? ''}'
          .trim(),
    'Enviado em ${data(agora)} às ${hora(agora)}',
  ];
  return linhas.join('\n');
}
