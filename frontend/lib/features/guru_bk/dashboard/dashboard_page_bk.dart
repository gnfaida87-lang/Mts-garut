import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_template.dart';
import '../services/guru_bk_service.dart';

class DashboardPageBK extends StatefulWidget {
  final void Function(String feature) onFeatureTap;
  const DashboardPageBK({super.key, required this.onFeatureTap});

  @override
  State<DashboardPageBK> createState() => _DashboardPageBKState();
}

class _DashboardPageBKState extends State<DashboardPageBK> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _stats = await GuruBKService.getStatistik();
    } catch (_) { debugPrint('[dashboard_page_bk.dart] error caught'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTemplate(
      loading: _loading,
      stats: [
        StatItem(Icons.list_alt, 'Total Pengaduan', '${_stats?['total_pengaduan'] ?? 0}', Colors.blue),
        StatItem(Icons.engineering, 'Aktif Diproses', '${_stats?['aktif_diproses'] ?? 0}', Colors.orange),
        StatItem(Icons.check_circle, 'Selesai', '${_stats?['selesai'] ?? 0}', const Color(0xFF9C6644)),
        StatItem(Icons.support_agent, 'Total Konseling', '${_stats?['total_konseling'] ?? 0}', Colors.indigo),
      ],
      features: const [
        FeatureItem('Pengaduan', 'pengaduan', Icons.report_outlined, 'Kelola pengaduan siswa'),
        FeatureItem('Konseling', 'konseling', Icons.support_agent_outlined, 'Jadwal & catatan konseling'),
        FeatureItem('Bakat & Minat', 'bakat-minat', Icons.psychology_outlined, 'Tes & analisis bakat'),
        FeatureItem('Monitoring', 'monitoring', Icons.trending_up_outlined, 'Pantau perkembangan siswa'),
        FeatureItem('Laporan', 'laporan', Icons.description_outlined, 'Generate laporan BK', isSecondary: true),
      ],
      onFeatureTap: widget.onFeatureTap,
    );
  }
}