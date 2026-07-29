import 'package:flutter_test/flutter_test.dart';

import 'package:ijisho_app/main.dart';

void main() {
  testWidgets('App renders role select screen', (WidgetTester tester) async {
    await tester.pumpWidget(const IjishoApp());

    // Verify the role select screen is shown
    expect(find.text('IJISHO'), findsOneWidget);
    expect(find.text('Select Your Role'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
  });
}
