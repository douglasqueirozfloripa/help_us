import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData temaHelpUS() {
  final esquema = ColorScheme.fromSeed(seedColor: Cores.azulAcesso).copyWith(
    primary: Cores.azulAcesso,
    onPrimary: Cores.branco,
    surface: Cores.papel,
    onSurface: Cores.tinta,
    onSurfaceVariant: Cores.tintaSuave,
    error: Cores.socorroEscuro,
    onError: Cores.branco,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Cores.papel,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );
}

/// AppBar com as cores do app e o título marcado como cabeçalho.
///
/// Com [focoDoTitulo], o título pode receber o foco por código (o Tab não para
/// nele): útil para levar o foco à tela nova quando ela troca sem mudar de rota.
AppBar barraHelpUS(String titulo,
        {Widget? leading, List<Widget>? actions, FocusNode? focoDoTitulo}) =>
    AppBar(
      backgroundColor: Cores.azulAcesso,
      foregroundColor: Cores.branco,
      leading: leading,
      actions: actions,
      title: Semantics(
        container: true,
        header: true,
        child: focoDoTitulo == null
            ? Text(titulo)
            : Focus(focusNode: focoDoTitulo, child: Text(titulo)),
      ),
    );
