class MilkBank {
  const MilkBank({
    required this.name,
    required this.distance,
    required this.address,
    required this.hours,
    required this.phone,
    required this.tags,
    required this.latitude,
    required this.longitude,
  });

  final String name;

  /// Distância padrão exibida antes de o usuário compartilhar a localização.
  final String distance;
  final String address;
  final String hours;
  final String phone;
  final List<String> tags;

  /// Coordenadas aproximadas do bairro, usadas para calcular a distância real
  /// a partir da localização do usuário (RF08).
  final double latitude;
  final double longitude;
}

const List<MilkBank> milkBanks = [
  MilkBank(
    name: 'BLH Marly Sarney',
    distance: '0.8 km',
    address: 'Rua Mato Grosso — José Conrado de Araújo',
    hours: 'Seg–Sex, 7h–17h',
    phone: '(79) 3226-6301',
    tags: ['Doação', 'Orientação'],
    latitude: -10.9432,
    longitude: -37.0692,
  ),
  MilkBank(
    name: 'Posto de Coleta — Hospital Santa Isabel',
    distance: '1.4 km',
    address: 'Av. Simeão Sobral, 1312 — Dezoito do Forte',
    hours: 'Todos os dias, 8h–12h e 14h–18h',
    phone: '(79) 3212-4900',
    tags: ['Doação', 'Distribuição'],
    latitude: -10.9569,
    longitude: -37.0453,
  ),
  MilkBank(
    name: 'UBS Siqueira Campos',
    distance: '2.1 km',
    address: 'Av. Ivo do Prado — Siqueira Campos',
    hours: 'Seg–Sáb, 6h–18h',
    phone: '(79) 3211-2233',
    tags: ['Orientação'],
    latitude: -10.9270,
    longitude: -37.0561,
  ),
  MilkBank(
    name: 'UBS Atalaia',
    distance: '3.5 km',
    address: 'Av. Melício Machado — Atalaia',
    hours: 'Seg–Sex, 8h–16h',
    phone: '(79) 3243-1188',
    tags: ['Orientação'],
    latitude: -10.9931,
    longitude: -37.0466,
  ),
];
