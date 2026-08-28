import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/guru_service.dart';
part 'nilai_input_page.dart';
part 'nilai_riwayat_analisis.dart';


class NilaiPageGuru extends StatelessWidget {
  const NilaiPageGuru({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C6644), Color(0xFF6F4E37)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.grading_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Penilaian', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Input & kelola nilai santri', style: TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _MenuCard(
                        icon: Icons.edit_note_rounded,
                        iconColor: const Color(0xFF9C6644),
                        title: 'Input Nilai',
                        subtitle: 'Input nilai harian, PTS, PAS/PAT langsung atau dari Excel',
                        onTap: () => Navigator.of(context).push(_route(const _InputNilaiPage())),
                      ),
                      const SizedBox(height: 14),
                      _MenuCard(
                        icon: Icons.history_rounded,
                        iconColor: const Color(0xFF1565C0),
                        title: 'Riwayat Nilai',
                        subtitle: 'Lihat & edit nilai yang sudah diinput',
                        onTap: () => Navigator.of(context).push(_route(const _RiwayatNilaiPage())),
                      ),
                      const SizedBox(height: 14),
                      _MenuCard(
                        icon: Icons.bar_chart_rounded,
                        iconColor: const Color(0xFFE65100),
                        title: 'Analisis Nilai',
                        subtitle: 'Statistik dan rekap nilai per kelas',
                        onTap: () => Navigator.of(context).push(_route(const _AnalisisNilaiPage())),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _route(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [iconColor.withValues(alpha: 0.12), iconColor.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}

Color _nilaiColor(num? n) {
  if (n == null) return Colors.grey[300]!;
  if (n >= 85) return const Color(0xFF9C6644);
  if (n >= 70) return const Color(0xFFE65100);
  return const Color(0xFFC62828);
}

String _jenisLabel(String j) {
  switch (j) {
    case 'harian': return 'Harian';
    case 'pts1': return 'PTS 1';
    case 'pts2': return 'PTS 2';
    case 'pas': return 'PAS';
    case 'pat': return 'PAT';
    default: return j.toUpperCase();
  }
}

void _showNotif(BuildContext context, String msg, {bool isError = false, String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
      ],
    ),
    backgroundColor: isError ? const Color(0xFFC62828) : const Color(0xFF9C6644),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
    action: actionLabel != null && onAction != null
        ? SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onAction)
        : null,
  ));
}
