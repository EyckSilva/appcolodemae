/// Formata uma data como dd/MM/aaaa, no padrão brasileiro usado pelo app.
String formatDateBr(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
