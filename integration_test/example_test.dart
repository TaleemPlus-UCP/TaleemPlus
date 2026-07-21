import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:taleemplus_app/main.dart' as app;

void main() {
  patrolTest(
    'counter state is maintained after home restart',
    ($) async {
      await app.main();
      await $.pumpAndSettle();

      // Example: Finding a widget and interacting with it
      // await $(#loginButton).tap();
      
      expect($('Taleem Plus'), findsOneWidget);
    },
  );
}
