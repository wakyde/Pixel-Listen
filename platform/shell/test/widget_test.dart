import 'package:flutter_test/flutter_test.dart';
import 'package:shell/app.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ShellApp());
    expect(find.byType(ShellApp), findsOneWidget);
  });
}