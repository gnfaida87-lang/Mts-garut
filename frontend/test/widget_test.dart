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

    // Pump melewati timeout _loadPengaturan (5 detik) agar tidak ada timer
    // yang menggantung saat widget tree dibongkar.
    await tester.pump(const Duration(seconds: 6));

    expect(find.byIcon(Icons.school), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Username / NIS'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
