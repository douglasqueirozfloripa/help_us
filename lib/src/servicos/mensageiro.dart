import 'package:url_launcher/url_launcher.dart';

/// Abre WhatsApp, SMS e ligação. Nada é enviado sem a pessoa ver:
/// o WhatsApp abre com a mensagem pronta e ela só toca em "Enviar".
abstract interface class Mensageiro {
  Future<bool> abrirWhatsApp(String telefone, String texto);
  Future<bool> abrirSms(String telefone, String texto);
  Future<bool> ligar(String numero);
}

class MensageiroDoSistema implements Mensageiro {
  @override
  Future<bool> abrirWhatsApp(String telefone, String texto) => _abrir(
      Uri.parse('https://wa.me/$telefone?text=${Uri.encodeComponent(texto)}'));

  @override
  Future<bool> abrirSms(String telefone, String texto) =>
      _abrir(Uri.parse('sms:+$telefone?body=${Uri.encodeComponent(texto)}'));

  @override
  Future<bool> ligar(String numero) => _abrir(Uri(scheme: 'tel', path: numero));

  Future<bool> _abrir(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
