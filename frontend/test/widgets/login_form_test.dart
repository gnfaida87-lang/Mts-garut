import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/features/auth/widgets/login_form.dart';

Widget createLoginForm({
  bool isLoading = false,
  String? error,
  VoidCallback? onSubmit,
}) {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  return MaterialApp(
    home: Scaffold(
      body: LoginForm(
        formKey: formKey,
        usernameController: usernameController,
        passwordController: passwordController,
        isLoading: isLoading,
        error: error,
        onSubmit: onSubmit ?? () {},
      ),
    ),
  );
}

void main() {
  group('LoginForm widget', () {
    testWidgets('should render username and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginForm());

      expect(find.text('Username / NIS'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show error message when error is provided', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginForm(error: 'Invalid credentials'));

      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show spinner when loading', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginForm(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should call onSubmit when button is tapped with valid input', (WidgetTester tester) async {
      bool submitted = false;
      await tester.pumpWidget(createLoginForm(onSubmit: () => submitted = true));

      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(submitted, isTrue);
    });

    testWidgets('should have validator on username field', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginForm());

      final formField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(formField.validator, isNotNull);
    });

    testWidgets('should have validator on password field', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginForm());

      final formField = tester.widget<TextFormField>(find.byType(TextFormField).last);
      expect(formField.validator, isNotNull);
    });
  });
}
