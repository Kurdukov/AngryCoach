enum TrustStage {
  noTrust,
  trial,
  almostHuman,
  suspiciouslyDisciplined;

  static TrustStage fromLevel(int trustLevel) {
    if (trustLevel >= 80) {
      return TrustStage.suspiciouslyDisciplined;
    }
    if (trustLevel >= 55) {
      return TrustStage.almostHuman;
    }
    if (trustLevel >= 25) {
      return TrustStage.trial;
    }
    return TrustStage.noTrust;
  }

  String get label {
    return switch (this) {
      TrustStage.noTrust => 'Не верю тебе',
      TrustStage.trial => 'На испытательном',
      TrustStage.almostHuman => 'Почти человек',
      TrustStage.suspiciouslyDisciplined =>
        'Подозрительно дисциплинирован',
    };
  }

  String get summary {
    return switch (this) {
      TrustStage.noTrust => 'Тренер ждёт подвох и проверяет каждый шаг.',
      TrustStage.trial => 'Шанс есть, но уважение пока на тонкой нитке.',
      TrustStage.almostHuman => 'Уже похоже на дисциплину. Не испорти.',
      TrustStage.suspiciouslyDisciplined =>
        'Слишком ровно. Тренер подозревает чудо или обман.',
    };
  }

  String successTone(String message) {
    return switch (this) {
      TrustStage.noTrust =>
        '$message Один нормальный день ещё не репутация.',
      TrustStage.trial => '$message Испытательный срок продолжается.',
      TrustStage.almostHuman => '$message Вот это уже похоже на человека.',
      TrustStage.suspiciouslyDisciplined =>
        '$message Подозрительно стабильно. Продолжай, пока не разоблачили.',
    };
  }

  String failTone(String message) {
    return switch (this) {
      TrustStage.noTrust => '$message Тренер не удивлён. Вообще.',
      TrustStage.trial => '$message Испытательный срок скрипит.',
      TrustStage.almostHuman =>
        '$message Был почти человек, стал снова подозреваемый.',
      TrustStage.suspiciouslyDisciplined =>
        '$message Легенда дала трещину. Красиво испортил статистику.',
    };
  }
}
