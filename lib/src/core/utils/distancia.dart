import 'dart:math';

const _raioDaTerraMetros = 6371000.0;

/// Distância em linha reta entre dois pontos do mapa (fórmula de haversine).
double distanciaEmMetros(
    double latitude1, double longitude1, double latitude2, double longitude2) {
  double radianos(double graus) => graus * pi / 180;
  final dLat = radianos(latitude2 - latitude1);
  final dLng = radianos(longitude2 - longitude1);
  final a = pow(sin(dLat / 2), 2) +
      cos(radianos(latitude1)) *
          cos(radianos(latitude2)) *
          pow(sin(dLng / 2), 2);
  return 2 * _raioDaTerraMetros * asin(sqrt(a));
}

/// "850 m" ou "6,8 km"
String distanciaLegivel(double metros) => metros.round() < 1000
    ? '${metros.round()} m'
    : '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
