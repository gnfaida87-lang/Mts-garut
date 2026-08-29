import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TentangPage extends StatelessWidget {
  const TentangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.school, size: 64, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sistem Informasi MTs Persis Garut',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Yayasan Pendidikan MTs Persis Garut',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _card('Versi Aplikasi', '1.0.0', Icons.tag_outlined),
        const SizedBox(height: 12),
        _card('Platform', 'Flutter Multi-platform (Web, Android, iOS, Desktop)', Icons.devices_outlined),
        const SizedBox(height: 12),
        _card('Backend', 'Cloudflare Workers + D1 Database', Icons.cloud_outlined),
        const SizedBox(height: 12),
        _card('Framework', 'Flutter 3.x + Material Design 3', Icons.code_outlined),
        const SizedBox(height: 32),
        Center(
          child: Text(
            '© 2024 - 2026 MTs Persis Garut. All rights reserved.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Dibangun dengan ❤️ untuk pendidikan',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _card(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}