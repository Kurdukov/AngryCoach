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
    await tester.pumpAndSettle();

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
