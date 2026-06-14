enum FailureReason {
  lazy,
  forgot,
  noTime,
  slipped,
  other;

  String get label {
    return switch (this) {
      FailureReason.lazy => 'Лень',
      FailureReason.forgot => 'Забыл',
      FailureReason.noTime => 'Не было времени',
      FailureReason.slipped => 'Сорвался',
      FailureReason.other => 'Другое',
    };
  }

  String get coachLine {
    return switch (this) {
      FailureReason.lazy => 'Лень записана. Тренер делает вид, что удивлён.',
      FailureReason.forgot => 'Забыл? Удобная легенда, почти классика.',
      FailureReason.noTime =>
        'Времени не было. Конечно, день был всего 24 часа.',
      FailureReason.slipped => 'Срыв принят. Завтра без театра.',
      FailureReason.other => 'Причина мутная. Тренер поставил красный флажок.',
    };
  }
}
