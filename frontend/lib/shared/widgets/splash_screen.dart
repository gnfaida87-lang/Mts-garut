import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
            stops: [0, 0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.school, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sistem Informasi\nMTs Persis Garut',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Jangan auto-login jika ada halaman lain di atas (mis. layar display publik)
      final modal = ModalRoute.of(context);
      if (modal != null && !modal.isCurrent) return;
      context.read<AuthProvider>().tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.authenticated:
        final route = auth.dashboardRoute;
        if (route != null && !_redirected) {
          final modal = ModalRoute.of(context);
          if (modal == null || modal.isCurrent) {
            _redirected = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (ModalRoute.of(context)?.isCurrent != true) return;
              Navigator.of(context).pushReplacementNamed(route);
            });
          }
        }
        return const SplashScreen();
      case AuthStatus.uninitialized:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.loading:
        return const LoginScreen();
    }
  }
}