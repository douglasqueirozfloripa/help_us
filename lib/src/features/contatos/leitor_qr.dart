import 'dart:convert';

import '../../core/utils/telefone.dart';

/// O que um QR code lido pode ser.
sealed class ResultadoQr {
  const ResultadoQr();
}

/// Número de WhatsApp de uma pessoa (link wa.me, api.whatsapp.com ou número puro).
class QrContato extends ResultadoQr {
  const QrContato(this.telefone);
  final String telefone;
}

/// QR oficial de um evento: liga o participante à organização.
///
/// Formato: {"helpus":"evento","id":"...","nome":"...","cidade":"...","whatsapp":"55..."}
class QrEvento extends ResultadoQr {
  const QrEvento(
      {required this.id,
      required this.nome,
      required this.whatsapp,
      this.cidade = ''});
  final String id;
  final String nome;
  final String whatsapp;
  final String cidade;
}

class QrInvalido extends ResultadoQr {
  const QrInvalido(this.motivo);
  final String motivo;
}

ResultadoQr interpretarQr(String? conteudo) {
  final texto = (conteudo ?? '').trim();
  if (texto.isEmpty) return const QrInvalido('O QR code está vazio.');

  if (texto.startsWith('{')) return _evento(texto);

  final uri = Uri.tryParse(texto);
  if (uri != null && uri.hasScheme) {
    final host = uri.host.toLowerCase();
    String? numero;
    if (host == 'wa.me' && uri.pathSegments.isNotEmpty) {
      numero = uri.pathSegments.first;
    }
    if (host.endsWith('whatsapp.com')) numero = uri.queryParameters['phone'];
    if (uri.scheme == 'tel') numero = uri.path;
    final telefone = normalizarTelefone(numero);
    return telefone == null
        ? const QrInvalido('Este QR code não é de um número de WhatsApp.')
        : QrContato(telefone);
  }

  final telefone = normalizarTelefone(texto);
  return telefone == null
      ? const QrInvalido('Não reconhecemos este QR code.')
      : QrContato(telefone);
}

ResultadoQr _evento(String texto) {
  try {
    final json =
        (jsonDecode(texto) as Map<dynamic, dynamic>).cast<String, Object?>();
    final telefone = normalizarTelefone(json['whatsapp'] as String?);
    final id = json['id'] as String?;
    final nome = json['nome'] as String?;
    if (json['helpus'] != 'evento' ||
        id == null ||
        nome == null ||
        telefone == null) {
      return const QrInvalido('O QR code do evento está incompleto.');
    }
    return QrEvento(
        id: id,
        nome: nome,
        whatsapp: telefone,
        cidade: (json['cidade'] as String?) ?? '');
  } on FormatException {
    return const QrInvalido('Não reconhecemos este QR code.');
  } on TypeError {
    return const QrInvalido('O QR code do evento está incompleto.');
  }
}
