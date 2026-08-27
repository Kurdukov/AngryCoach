import 'package:angry_coach/main.dart';
import 'package:angry_coach/theme/theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows onboarding when no habit exists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final themeController = ThemeController();
    await themeController.load();

    await tester.pumpWidget(AngryCoachApp(themeController: themeController));
    // AngryAvatar runs a perpetual idle bob/breathe loop, so
    // pumpAndSettle() would wait forever. Pump a few bounded frames
    // instead, just enough to let the async habit lookup resolve.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Angry Coach'), findsOneWidget);
    expect(
      find.text(
        'Трекер привычек, который не делает вид, что ты молодец просто за установку приложения.',
      ),
      findsOneWidget,
    );
    expect(find.text('Начать'), findsOneWidget);
  });
}
