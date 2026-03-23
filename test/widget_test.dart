import 'package:flutter_test/flutter_test.dart';
import 'package:kalmado_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test — just verify the app widget builds
    await tester.pumpWidget(const KalmadoApp());
  });
}
