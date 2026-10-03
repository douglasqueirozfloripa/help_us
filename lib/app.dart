import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/app/dependencias.dart';
import 'src/core/theme/tema.dart';
import 'src/core/theme/tokens.dart';
import 'src/features/inicio/inicio_page.dart';

class HelpUSApp extends StatefulWidget {
  const HelpUSApp({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  State<HelpUSApp> createState() => _HelpUSAppState();
}

class _HelpUSAppState extends State<HelpUSApp> {
  @override
  void initState() {
    super.initState();
    widget.dependencias.carregar();
  }

  @override
  Widget build(BuildContext context) {
    // Sem tela de abertura: num pedido de ajuda cada segundo conta.
    return MaterialApp(
      title: NomeDoApp.valor,
      debugShowCheckedModeBanner: false,
      theme: temaHelpUS(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: InicioPage(dependencias: widget.dependencias),
    );
  }
}
