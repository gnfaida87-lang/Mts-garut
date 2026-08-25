import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/features/auth/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider', () {
    test('initial status should be uninitialized', () {
      final provider = AuthProvider();
      expect(provider.status, AuthStatus.uninitialized);
      expect(provider.user, isNull);
      expect(provider.error, isNull);
    });

    test('dashboardRoute should return null when no user', () {
      final provider = AuthProvider();
      expect(provider.dashboardRoute, isNull);
    });

    test('logout should reset state', () async {
      final provider = AuthProvider();
      try {
        await provider.logout();
      } catch (_) {}
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
    });

    test('login should fail gracefully without backend', () async {
      final provider = AuthProvider();

      expect(provider.status, AuthStatus.uninitialized);

      try {
        await provider.login('admin', 'wrong');
      } catch (_) {}

      expect(provider.status, AuthStatus.unauthenticated);
    });
  });
}