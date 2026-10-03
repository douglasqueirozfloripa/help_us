import 'package:quick_actions/quick_actions.dart';

import 'dependencias.dart';

/// Premissa: o sistema não deixa abrir apps com o celular bloqueado.
/// O que dá para fazer no app: segurar o ícone na tela inicial e tocar em
/// "Pedir ajuda" dispara o pedido direto, sem passar por nenhuma tela.
/// (Botão na tela de bloqueio fica para a próxima etapa; veja docs/ACESSIBILIDADE.md.)
void configurarAtalhos(Dependencias dependencias) {
  const acoes = QuickActions();
  acoes.initialize((tipo) async {
    if (tipo != 'pedir_ajuda') return;
    await dependencias.carregar();
    await dependencias.sos.pedirAjuda();
  });
  acoes.setShortcutItems(
      const [ShortcutItem(type: 'pedir_ajuda', localizedTitle: 'Pedir ajuda')]);
}
