import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taleemplus_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('basic app flow test', (WidgetTester tester) async {
    // Start the app
    await app.main();
    await tester.pumpAndSettle();

    // The splash screen navigates away after a fixed delay with no
    // animation running right before it fires, so pumpAndSettle alone can
    // report "settled" before that navigation happens. Pump past it explicitly.
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Splash screen auto-navigates to the login screen, which shows the
    // "TaleemPlus" wordmark (rendered without a space).
    expect(find.text('TaleemPlus'), findsOneWidget);
  });
}
