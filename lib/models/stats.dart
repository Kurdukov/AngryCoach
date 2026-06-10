class Stats {
  const Stats({
    required this.currentStreak,
    required this.bestStreak,
    required this.missedDays,
    required this.trustLevel,
  });

  factory Stats.initial() {
    return const Stats(
      currentStreak: 0,
      bestStreak: 0,
      missedDays: 0,
      trustLevel: 50,
    );
  }

  final int currentStreak;
  final int bestStreak;
  final int missedDays;
  final int trustLevel;

  Stats copyWith({
    int? currentStreak,
    int? bestStreak,
    int? missedDays,
    int? trustLevel,
  }) {
    return Stats(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      missedDays: missedDays ?? this.missedDays,
      trustLevel: trustLevel ?? this.trustLevel,
    );
  }
}
