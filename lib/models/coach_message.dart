import 'dart:convert';

class CoachMessage {
  const CoachMessage({
    required this.text,
    required this.date,
    required this.type,
  });

  final String text;
  final DateTime date;
  final String type;

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      text: json['text'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'date': date.toIso8601String(), 'type': type};
  }

  static List<CoachMessage> listFromJson(String encoded) {
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map((item) => CoachMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<CoachMessage> messages) {
    return jsonEncode(messages.map((message) => message.toJson()).toList());
  }
}
