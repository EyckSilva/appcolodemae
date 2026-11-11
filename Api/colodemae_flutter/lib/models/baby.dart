/// Fase de desenvolvimento do bebê, calculada a partir da data de nascimento.
enum BabyPhase { newborn, firstMonth, growing }

class BabyPhaseInfo {
  const BabyPhaseInfo(
      {required this.label, required this.emoji, required this.message});

  final String label;
  final String emoji;
  final String message;
}

const Map<BabyPhase, BabyPhaseInfo> babyPhaseInfo = {
  BabyPhase.newborn: BabyPhaseInfo(
    label: 'Primeiros dias',
    emoji: '🌸',
    message: 'Que começo especial!',
  ),
  BabyPhase.firstMonth: BabyPhaseInfo(
    label: 'Primeiro mês',
    emoji: '🌷',
    message: 'Vocês estão se conhecendo',
  ),
  BabyPhase.growing: BabyPhaseInfo(
    label: 'Crescendo juntos',
    emoji: '💪',
    message: 'Que dupla incrível!',
  ),
};

class Baby {
  const Baby({required this.name, required this.birthDate});

  final String name;
  final DateTime birthDate;

  int get daysSinceBirth {
    final now = DateTime.now();
    final diff = DateTime.utc(now.year, now.month, now.day).difference(
        DateTime.utc(birthDate.year, birthDate.month, birthDate.day));
    return diff.inDays < 0 ? 0 : diff.inDays;
  }

  BabyPhase get phase {
    final days = daysSinceBirth;
    if (days <= 7) return BabyPhase.newborn;
    if (days <= 30) return BabyPhase.firstMonth;
    return BabyPhase.growing;
  }

  Baby copyWith({String? name, DateTime? birthDate}) {
    return Baby(
        name: name ?? this.name, birthDate: birthDate ?? this.birthDate);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'birthDate': birthDate.toIso8601String(),
      };

  factory Baby.fromJson(Map<String, dynamic> json) => Baby(
        name: json['name'] as String,
        birthDate: DateTime.parse(json['birthDate'] as String),
      );
}
