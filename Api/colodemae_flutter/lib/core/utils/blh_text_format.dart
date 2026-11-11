/// Formatação de apresentação; não modifica o dado nem o telefone do discador.
String formatBlhPhone(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if ((digits.length == 12 || digits.length == 13) && digits.startsWith('55')) {
    digits = digits.substring(2);
  }
  if (digits.length != 10 && digits.length != 11) return value.trim();
  return '(${digits.substring(0, 2)}) ${digits.substring(2, digits.length - 4)}-${digits.substring(digits.length - 4)}';
}

String _readable(String value) {
  final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean != clean.toUpperCase()) return clean;
  const connectors = {'de', 'da', 'do', 'das', 'dos', 'e'};
  return clean.toLowerCase().split(' ').asMap().entries.map((entry) {
    final word = entry.value;
    if (word.isEmpty ||
        word == 's/n' ||
        (entry.key > 0 && connectors.contains(word))) {
      return word;
    }
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}

class BlhAddressText {
  BlhAddressText(String address) {
    final parts = address
        .split(RegExp(r'[,\n]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    for (final part in parts) {
      final match =
          RegExp(r'^(?:CEP\s*:?\s*)?(\d{5})-?(\d{3})$', caseSensitive: false)
              .firstMatch(part);
      if (match != null) {
        postalCode = '${match[1]}-${match[2]}';
      } else if (street.isEmpty) {
        street = _readable(part);
      } else if (RegExp(r'^(?:n[º°.]?\s*)?(?:\d+[a-zA-Z]?(?:[-/]\d+)?|s/n)$',
              caseSensitive: false)
          .hasMatch(part)) {
        number = part.toLowerCase();
      } else {
        neighborhood = _readable(
            part.replaceFirst(RegExp(r'^bairro\s+', caseSensitive: false), ''));
      }
    }
  }
  String street = '', number = '', neighborhood = '', postalCode = '';
  String get summary =>
      [street, neighborhood].where((s) => s.isNotEmpty).join(' — ');
  String details(String locality) => [
        [street, number].where((s) => s.isNotEmpty).join(', '),
        neighborhood,
        '$locality${postalCode.isEmpty ? '' : ' · CEP $postalCode'}',
      ].where((s) => s.isNotEmpty).join('\n');
}
