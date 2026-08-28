import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  String _heroTitle = 'Sistem Informasi\nMA Persis Garut';
  String _heroSubtitle = 'Kelola data akademik, absensi, nilai, rapor,\ndan bimbingan konseling dalam satu platform.';
  String _logoUrl = '';
  String _backgroundUrl = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(_fadeIn);
    _animCtrl.forward();
    _loadPengaturan();
  }

  Future<void> _loadPengaturan() async {
    try {
      // Timeout singkat agar tampilan login tidak menggantung menunggu
      // jaringan lambat. Gagal → tetap tampilkan teks default.
      final res = await ApiClient.get('/pengaturan-tampilan')
          .timeout(const Duration(seconds: 5));
      final data = res['data'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          for (final item in data) {
            final m = item as Map<String, dynamic>;
            if (m['key'] == 'hero_title') _heroTitle = m['value'] as String? ?? _heroTitle;
            if (m['key'] == 'hero_subtitle') _heroSubtitle = m['value'] as String? ?? _heroSubtitle;
            if (m['key'] == 'logo_url') _logoUrl = m['value'] as String? ?? '';
            if (m['key'] == 'background_url') _backgroundUrl = m['value'] as String? ?? '';
          }
        });
      }
    } catch (_) { debugPrint('[login_screen.dart] error caught'); }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (mounted && auth.status == AuthStatus.authenticated && auth.dashboardRoute != null) {
      Navigator.of(context).pushReplacementNamed(auth.dashboardRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return _buildSplitScreen(context, auth);
          }
          return _buildMobileLayout(context, auth);
        },
      ),
    );
  }

  Widget _buildSplitScreen(BuildContext context, AuthProvider auth) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              image: _backgroundUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(_backgroundUrl), fit: BoxFit.cover, opacity: 0.12)
                  : null,
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _logoUrl.isNotEmpty
                              ? Image.network(
                                  _logoUrl,
                                  width: 64,
                                  height: 64,
                                  color: Colors.white,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.school, size: 56, color: Colors.white),
                                )
                              : const Icon(Icons.school, size: 56, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _heroTitle,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _heroSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: _buildFormCard(context, auth),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, AuthProvider auth) {
    return Container(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _logoUrl.isNotEmpty
                            ? Image.network(
                                _logoUrl,
                                width: 56,
                                height: 56,
                                color: Colors.white,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.school, size: 52, color: Colors.white),
                              )
                            : const Icon(Icons.school, size: 52, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _heroTitle.replaceAll('\n', ' '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _heroSubtitle.replaceAll('\n', ' '),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: _buildFormCard(context, auth),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, AuthProvider auth) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: LoginForm(
              formKey: _formKey,
              usernameController: _usernameController,
              passwordController: _passwordController,
              isLoading: auth.status == AuthStatus.loading,
              error: auth.error,
              onSubmit: _handleLogin,
            ),
          ),
        ),
      ),
    );
  }
}
