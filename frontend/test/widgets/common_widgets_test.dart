import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/widgets/common_widgets.dart';

void main() {
  group('AppInputDecoration', () {
    testWidgets('should render standard login decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: AppInputDecoration.standard(
                'Test Label',
                Icons.person,
                style: InputDecorationStyle.login,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should render standard decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: AppInputDecoration.standard(
                'Field Label',
                Icons.email,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Field Label'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });
  });
}
