import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/tema.dart';
import 'leitor_qr.dart';

/// Lê o QR code do evento ou de um contato.
///
/// Mirar a câmera é difícil para quem não enxerga ou tem tremor: por isso a
/// mesma tela aceita o número digitado (WCAG 1.1.1 e 2.5.1).
class QrPage extends StatefulWidget {
  const QrPage({super.key, this.camera});

  /// Nos testes a câmera é trocada por um widget falso.
  final Widget Function(ValueChanged<String> aoLer)? camera;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final _digitado = TextEditingController();
  String _erro = '';
  var _terminou = false;

  @override
  void dispose() {
    _digitado.dispose();
    super.dispose();
  }

  void _ler(String conteudo) {
    if (_terminou) return;
    final resultado = interpretarQr(conteudo);
    if (resultado is QrInvalido) {
      setState(() => _erro = resultado.motivo);
      return;
    }
    _terminou = true;
    Navigator.of(context).pop<ResultadoQr>(resultado);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: barraHelpUS('Ler QR code'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Aponte a câmera para o QR code do evento ou do contato.',
                style: textos.bodyLarge),
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label: 'Câmera lendo QR code',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 280,
                  child: widget.camera?.call(_ler) ?? _CameraReal(aoLer: _ler),
                ),
              ),
            ),
            Semantics(
              container: true,
              liveRegion: true,
              child: _erro.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_erro,
                          style: textos.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.error)),
                    ),
            ),
            const SizedBox(height: 24),
            Semantics(
                container: true,
                header: true,
                child: Text('Ou digite o número', style: textos.titleMedium)),
            const SizedBox(height: 8),
            TextField(
              controller: _digitado,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp com DDD',
                helperText: 'O número aparece embaixo do QR code.',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _ler,
            ),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => _ler(_digitado.text),
                child: const Text('Usar este número')),
          ],
        ),
      ),
    );
  }
}

class _CameraReal extends StatefulWidget {
  const _CameraReal({required this.aoLer});
  final ValueChanged<String> aoLer;

  @override
  State<_CameraReal> createState() => _CameraRealState();
}

class _CameraRealState extends State<_CameraReal> {
  final _controle = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controle,
      errorBuilder: (context, erro) => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Não foi possível usar a câmera. Digite o número abaixo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      onDetect: (captura) {
        final valor = captura.barcodes.firstOrNull?.rawValue;
        if (valor != null) widget.aoLer(valor);
      },
    );
  }
}
