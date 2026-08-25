import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mts_garut/features/auth/providers/auth_provider.dart';
import 'package:mts_garut/shared/widgets/dashboard_template.dart';

void main() {
  group('DashboardTemplate', () {
    testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardTemplate(loading: true),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show stats when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardTemplate(
                stats: [
                  StatItem(Icons.home, 'Total', '10', Colors.blue),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('should show features when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardTemplate(
                features: [
                  FeatureItem('Menu1', 'menu1', Icons.star, 'Desc1'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Menu1'), findsOneWidget);
      expect(find.text('Desc1'), findsOneWidget);
    });

    testWidgets('should call onFeatureTap when feature is tapped', (WidgetTester tester) async {
      String? tappedFeature;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: DashboardTemplate(
                features: const [
                  FeatureItem('Menu1', 'menu1', Icons.star, 'Desc1'),
                ],
                onFeatureTap: (f) => tappedFeature = f,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu1'));
      expect(tappedFeature, 'menu1');
    });

    testWidgets('should show greeting header', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardTemplate(),
            ),
          ),
        ),
      );

      // Should show either Selamat Pagi/Siang/Sore/Malam
      final greetingFinder = find.byWidgetPredicate(
        (widget) => widget is Text &&
            (widget.data?.contains('Selamat') ?? false),
      );
      expect(greetingFinder, findsOneWidget);
    });
  });
}
