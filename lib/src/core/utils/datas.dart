String _dois(int n) => n.toString().padLeft(2, '0');

/// 30/09/2026
String data(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

/// 20:17
String hora(DateTime d) => '${_dois(d.hour)}:${_dois(d.minute)}';

/// "30/09/2026, das 14:00 às 18:00" ou "30/09 14:00 até 01/10 02:00"
String periodo(DateTime inicio, DateTime fim) {
  final mesmoDia = inicio.year == fim.year &&
      inicio.month == fim.month &&
      inicio.day == fim.day;
  return mesmoDia
      ? '${data(inicio)}, das ${hora(inicio)} às ${hora(fim)}'
      : '${data(inicio)} às ${hora(inicio)} até ${data(fim)} às ${hora(fim)}';
}
