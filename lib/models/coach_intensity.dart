enum CoachIntensity {
  sarcastic,
  toxic,
  ruthless;

  String get label {
    return switch (this) {
      CoachIntensity.sarcastic => 'Язвительный',
      CoachIntensity.toxic => 'Токсичный',
      CoachIntensity.ruthless => 'Безжалостный',
    };
  }

  String get shortLabel {
    return switch (this) {
      CoachIntensity.sarcastic => 'Мягче',
      CoachIntensity.toxic => 'Норма',
      CoachIntensity.ruthless => 'Жёстче',
    };
  }
}
