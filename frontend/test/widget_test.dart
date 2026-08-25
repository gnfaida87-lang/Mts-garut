import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mts_garut/features/auth/providers/auth_provider.dart';
import 'package:mts_garut/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen mobile layout should show school icon and form', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.byIcon(Icons.school), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Username / NIS'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
