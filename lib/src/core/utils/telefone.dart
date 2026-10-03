/// Telefones no formato que o WhatsApp entende: só dígitos, com o 55 do Brasil.
String? normalizarTelefone(String? bruto) {
  var digitos = (bruto ?? '').replaceAll(RegExp(r'\D'), '');
  if (digitos.startsWith('00')) digitos = digitos.substring(2);
  if (digitos.startsWith('0') &&
      (digitos.length == 11 || digitos.length == 12)) {
    digitos = digitos.substring(1); // 0 48 99999-0000
  }
  if (digitos.length == 10 || digitos.length == 11) digitos = '55$digitos';
  if (digitos.length < 12 || digitos.length > 13) return null;
  return digitos;
}

String? validarTelefone(String? bruto) => normalizarTelefone(bruto) == null
    ? 'Informe o telefone com DDD, por exemplo 48 99999-0000.'
    : null;

/// 5548999990000 → (48) 99999-0000
String formatarTelefone(String normalizado) {
  if (!normalizado.startsWith('55') || normalizado.length < 12) {
    return '+$normalizado';
  }
  final ddd = normalizado.substring(2, 4);
  final numero = normalizado.substring(4);
  final corte = numero.length - 4;
  return '($ddd) ${numero.substring(0, corte)}-${numero.substring(corte)}';
}

/// Para o leitor de tela falar número por número, e não "noventa e nove mil".
String telefoneParaFala(String normalizado) => formatarTelefone(normalizado)
    .replaceAll(RegExp(r'[()\-]'), '')
    .split('')
    .join(' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
