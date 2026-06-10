import 'package:angry_coach/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows onboarding when no habit exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AngryCoachApp());
    await tester.pumpAndSettle();

    expect(find.text('ANGRY COACH'), findsOneWidget);
    expect(
      find.text('Какое обещание ты собираешься нарушить на этот раз?'),
      findsOneWidget,
    );
    expect(find.text('НАЧАТЬ РАЗОЧАРОВЫВАТЬ ТРЕНЕРА'), findsOneWidget);
  });
}
