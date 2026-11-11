import 'package:geolocator/geolocator.dart';
import '../core/utils/location.dart';
import '../models/milk_bank.dart';

/// Anota a lista municipal inteira, sem filtro de raio e sem persistir a origem.
List<MilkBankResult> withBlhDistances(
    Iterable<MilkBank> banks, AppCoordinates? origin) {
  final validOrigin = origin != null &&
      origin.latitude.isFinite &&
      origin.longitude.isFinite &&
      origin.latitude.abs() <= 90 &&
      origin.longitude.abs() <= 180;
  return banks.map((bank) {
    double? km;
    if (validOrigin && bank.hasVerifiedCoordinates) {
      final meters = Geolocator.distanceBetween(
          origin.latitude, origin.longitude, bank.latitude!, bank.longitude!);
      if (meters.isFinite && meters >= 0) km = meters / 1000;
    }
    return MilkBankResult(bank, distanceKm: km);
  }).toList();
}
